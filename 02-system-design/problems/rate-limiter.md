# Design: Rate Limiter

## 1. Problem Statement & Scope

**Design a distributed rate limiter that controls how many requests a client can send to an API within a time window, protecting backend services from abuse and overload.**

**Clarifying questions to ask:**
- Client-side or server-side? → Server-side (middleware/gateway)
- Rate limit by what? → User ID, IP address, or API key
- Distributed? → Yes, multiple servers share rate limit state
- What happens when limited? → Return 429 with Retry-After header
- Different limits per endpoint? → Yes (GET cheaper than POST)

💡 **Why this is a common interview problem:** Rate limiting is a cross-cutting concern that appears in every production system. It tests your knowledge of algorithms (token bucket, sliding window), distributed systems (shared state in Redis, race conditions), and failure handling (what if Redis is down?).

## 2. Requirements

**Functional:**
- Limit requests per client per time window (e.g., 100 requests/minute)
- Support different limits per API endpoint
- Return 429 Too Many Requests when exceeded
- Include rate limit headers in all responses (limit, remaining, reset)
- Support multiple rate limit tiers (per-user, per-IP, global)

**Non-functional:**
- Low latency (< 1ms overhead per request — rate limiter must be fast)
- Highly available (rate limiter failure shouldn't block ALL requests)
- Distributed (consistent across multiple app servers)
- Accurate (minimal false positives — don't reject legitimate users)

**Estimation:**
```
10M users, average 10 requests/user/day = 100M requests/day
QPS: ~1,200. Peak: ~3,600.
Rate limit state per user: ~100 bytes (tokens + timestamp)
Total state: 10M × 100 bytes = 1 GB → fits easily in a single Redis instance
```

## 3. High-Level Design

**Where to place the rate limiter:**
```
Option 1: API Gateway (recommended for external APIs)
  Client → API Gateway [rate limit] → App Server

Option 2: Middleware in app server
  Client → LB → App Server [rate limit middleware] → Business Logic

Option 3: Separate service
  Client → LB → App Server → Rate Limit Service (Redis) → proceed or reject
```

💡 **Intuition — API Gateway is usually best:** Cloud providers (AWS API Gateway, Kong, Envoy) have built-in rate limiting. It's the first line of defense — rejects bad traffic before it reaches your app servers. For custom logic (per-user limits based on subscription tier), middleware in the app server is more flexible.

**Algorithms** [🔥 Must Know]:

**Token Bucket** (most common, recommended):

```
Bucket: capacity=10 (burst size), refill_rate=5 tokens/sec

t=0:  tokens=10 (full)
t=0:  7 requests arrive → tokens=3 (burst allowed!)
t=1:  +5 tokens → tokens=8
t=1:  3 requests → tokens=5
t=2:  +5 tokens → tokens=10 (capped at capacity)
...
t=5:  tokens=0, request arrives → REJECT (429)
t=5.2: +1 token → tokens=1, next request allowed
```

| Algorithm | Allows Bursts? | Accuracy | Memory | Complexity | Best For |
|-----------|---------------|----------|--------|------------|----------|
| Token Bucket | Yes (up to capacity) | Good | O(1)/user | Simple | Most use cases ✅ |
| Leaky Bucket | No (smooth output) | Good | O(1)/user | Simple | Smooth rate enforcement |
| Fixed Window | Yes (2x at boundary) | Approximate | O(1)/user | Simplest | Simple, low-stakes |
| Sliding Window Log | No | Exact | O(n)/user | Complex | When exactness matters |
| Sliding Window Counter | Minimal | Good approximation | O(1)/user | Moderate | Good balance ✅ |

⚙️ **Under the Hood — Fixed Window Boundary Problem:**

```
Limit: 100 requests per minute

Minute 1: |....................[100 requests at 0:59]|
Minute 2: |[100 requests at 1:00].....................|

At the boundary: 200 requests in 2 seconds! Both pass the fixed window check.

Sliding Window Counter fixes this:
  At 1:00:15 (15 sec into minute 2):
  count = prev_count × (45/60) + curr_count = 100 × 0.75 + 100 = 175 > 100 → REJECT
```

**Redis implementation (Token Bucket with Lua script):**

```lua
-- Lua script runs atomically on Redis (no race conditions)
local key = KEYS[1]
local rate = tonumber(ARGV[1])      -- tokens per second
local capacity = tonumber(ARGV[2])  -- max burst size
local now = tonumber(ARGV[3])       -- current timestamp (seconds.microseconds)
local requested = tonumber(ARGV[4]) -- tokens needed (usually 1)

-- Get current state
local data = redis.call('hmget', key, 'tokens', 'last_refill')
local tokens = tonumber(data[1]) or capacity  -- default: full bucket
local last_refill = tonumber(data[2]) or now

-- Refill tokens based on elapsed time
local elapsed = now - last_refill
tokens = math.min(capacity, tokens + elapsed * rate)

-- Check and consume
if tokens >= requested then
    tokens = tokens - requested
    redis.call('hmset', key, 'tokens', tokens, 'last_refill', now)
    redis.call('expire', key, math.ceil(capacity / rate) * 2)  -- auto-cleanup
    return 1  -- ALLOWED
else
    redis.call('hmset', key, 'tokens', tokens, 'last_refill', now)
    return 0  -- REJECTED
end
```

💡 **Intuition — Why Lua Script?** Without atomic execution, two requests arriving simultaneously could both read `tokens=1`, both decrement to 0, and both pass — exceeding the limit. Lua scripts execute atomically on Redis (single-threaded), preventing this race condition.

**Response headers** [🔥 Must Know]:
```
HTTP/1.1 200 OK
X-RateLimit-Limit: 100          -- max requests per window
X-RateLimit-Remaining: 45       -- remaining in current window
X-RateLimit-Reset: 1625097600   -- Unix timestamp when window resets

HTTP/1.1 429 Too Many Requests
Retry-After: 30                  -- seconds to wait before retrying
X-RateLimit-Limit: 100
X-RateLimit-Remaining: 0
```

## 4. Deep Dive

**Distributed rate limiting challenges:**

| Challenge | Problem | Solution |
|-----------|---------|---------|
| Shared state | Multiple servers must agree on request count | Redis as central store |
| Race conditions | Two requests check simultaneously | Lua scripts for atomic operations |
| Redis failure | Rate limiter unavailable | Fail open (allow requests) — better to over-serve than block everyone |
| Network latency | Redis round-trip adds latency | Local token cache with periodic sync to Redis |
| Clock skew | Different servers have different timestamps | Use Redis server time (not client time) in Lua script |

**Fail open vs fail closed** [🔥 Must Know]:
- **Fail open:** If Redis is down, allow all requests. Risk: no rate limiting during outage. Benefit: service stays available.
- **Fail closed:** If Redis is down, reject all requests. Risk: service is down. Benefit: guaranteed rate limiting.
- **Recommendation:** Fail open for most services. Fail closed only for critical security endpoints (login, payment).

**Multi-tier rate limiting:**
```
Tier 1 (per-IP):     1000 requests/minute  — catches unauthenticated abuse, DDoS
Tier 2 (per-user):   100 requests/minute   — fair usage per authenticated user
Tier 3 (per-endpoint): POST /api/orders: 10/minute, GET /api/products: 100/minute
Tier 4 (global):     50,000 requests/second — protects backend from total overload

Check all tiers. Reject if ANY tier is exceeded.
```

**Rate limiting by cost:**
```
Not all requests are equal:
  GET /api/products → cost = 1 token
  POST /api/orders → cost = 5 tokens (more expensive, hits DB)
  POST /api/reports → cost = 20 tokens (heavy computation)

Token bucket with variable cost: consume `cost` tokens per request instead of 1.
```

💥 **What Can Go Wrong:**

| Problem | Impact | Solution |
|---------|--------|---------|
| Redis down | No rate limiting | Fail open + local fallback (in-memory rate limiter per server) |
| Race condition | Over-limit requests pass | Lua script for atomic check-and-decrement |
| Clock skew | Inconsistent windows | Use Redis server time, not client time |
| Hot user (API abuser) | One user's key gets millions of hits | Rate limit at IP level too, block at firewall |
| Legitimate burst rejected | Good user gets 429 during spike | Token bucket allows bursts up to capacity |

🎯 **Likely Follow-ups:**
- **Q:** How do you rate limit in a geo-distributed system?
  **A:** Each region has its own Redis for local rate limiting. For global limits, either sync counts across regions (eventual consistency — may slightly over-allow) or use a global Redis (adds cross-region latency).
- **Q:** How do you handle rate limiting for WebSocket connections?
  **A:** Rate limit on connection establishment (per-IP) and on message frequency (per-connection). Use a token bucket per WebSocket connection for message rate.
- **Q:** How do you dynamically adjust rate limits based on server load?
  **A:** Monitor server CPU/memory/queue depth. When load exceeds threshold, reduce rate limits (adaptive rate limiting). Increase back when load drops. This is a form of backpressure.

## 5. Advanced / Follow-ups
- **Geo-distributed:** Per-region rate limiting with eventual sync for global limits
- **Dynamic limits:** Adjust based on server load, time of day, or user tier (free vs premium)
- **Graceful degradation:** Serve cached/stale responses when rate limited (instead of 429)
- **Rate limiting by cost:** Different endpoints consume different token amounts
- **DDoS protection:** Rate limiting is one layer; also need IP blocking, CAPTCHA, CDN-level filtering

## 6. Common Mistakes

| Weak Answer | Strong Answer |
|-------------|---------------|
| "Use a counter in the database" | "Redis with Lua script for atomic, low-latency rate limiting" |
| "Fixed window counter" | "Token bucket (allows bursts) or sliding window counter (accurate). Fixed window has the boundary problem." |
| No failure handling | "Fail open on Redis failure — better to over-serve than block all users" |
| No response headers | "Include X-RateLimit-Limit, Remaining, Reset in every response, Retry-After on 429" |
| Single-tier limiting | "Multi-tier: per-IP, per-user, per-endpoint, global" |

## 7. Interviewer's Evaluation Criteria

| Criteria | What They Look For |
|----------|-------------------|
| Algorithms | Knows token bucket + sliding window, explains trade-offs |
| Distributed | Redis + Lua for atomic operations |
| Failure handling | Fail open vs closed, local fallback |
| Multi-tier | Per-IP, per-user, per-endpoint, global |
| Response headers | X-RateLimit-* headers, Retry-After |
| Race conditions | Understands why atomic operations are needed |

## 7. How I'd Present This in 45 Minutes

```
[0-5 min] Requirements:
"Distributed rate limiter at the API gateway. Per-user and per-IP limits.
Different limits per endpoint. Return 429 with Retry-After header.
< 1ms overhead per request. Must work across multiple app servers."

[5-10 min] Estimation:
"10M users, 100M requests/day. QPS: ~1200, peak ~3600.
Rate limit state per user: ~100 bytes. Total: 1GB. Fits in one Redis."

[10-20 min] High-Level Design:
"Rate limiter as middleware in API gateway. Redis for shared state.
Token bucket algorithm (allows bursts, simple, O(1) per check).
Lua script in Redis for atomic check-and-decrement."

[20-40 min] Deep Dive:
"Token bucket in Redis: key = rate_limit:{user_id}, value = {tokens, last_refill_time}.
Lua script: calculate tokens to add since last refill, check if >= 1, decrement.
Atomic in Redis (Lua runs single-threaded). No race conditions.
Sliding window counter as alternative: weighted count from current + previous window.
If Redis is down: fail open (allow requests) or fail closed (reject). Prefer fail open."

[40-45 min] Wrap-up:
"Monitoring: rate limit hit rate per endpoint, Redis latency, false positive rate.
Failure: if Redis is down, local in-memory rate limiter as fallback (approximate).
Extensions: dynamic rate limits based on subscription tier, global rate limit across all users."
```

## 7b. Common Mistakes to Avoid

| Mistake | Why It's Wrong | What to Do Instead |
|---------|---------------|-------------------|
| In-memory rate limiter only | Doesn't work across multiple app servers | Shared state in Redis. Local limiter only as fallback. |
| Non-atomic check-and-decrement | Race condition: two requests both see tokens=1, both pass | Redis Lua script for atomicity |
| Fixed window without addressing boundary burst | Client can make 2x limit at window boundary | Use sliding window counter or token bucket |
| Failing closed when Redis is down | All requests rejected, total outage | Fail open (allow requests) with local approximate limiter |
| Same limit for all endpoints | GET is cheap, POST is expensive | Different limits per endpoint and HTTP method |

## 8. Revision Checklist

- [ ] Token bucket: capacity (burst) + refill rate, most common, allows bursts
- [ ] Sliding window counter: weighted prev + current, accurate, no boundary problem
- [ ] Fixed window: simple but 2x burst at boundary — mention the problem
- [ ] Redis + Lua script for atomic distributed rate limiting (no race conditions)
- [ ] Fail open on Redis failure (don't block all requests)
- [ ] Response headers: X-RateLimit-Limit, Remaining, Reset, Retry-After (on 429)
- [ ] Multi-tier: per-IP (DDoS), per-user (fair usage), per-endpoint (cost), global (protection)
- [ ] Rate limiting by cost: different endpoints consume different tokens
- [ ] Estimation: 1 GB state for 10M users → single Redis instance

> 🔗 **See Also:** [02-system-design/01-fundamentals.md](../01-fundamentals.md) for rate limiting algorithm details. [06-tech-stack/02-redis-deep-dive.md](../../06-tech-stack/02-redis-deep-dive.md) for Redis Lua scripting and atomic operations. [02-system-design/04-api-design.md](../04-api-design.md) for rate limit response headers.

---

## 9. Interviewer Deep-Dive Questions

1. **"Redis is down. Do you fail open (allow all) or fail closed (block all)?"**
   → Depends on context. API Gateway for external traffic: fail OPEN (don't block legitimate users because of infra failure). Payment API: fail CLOSED (protect against abuse). Make it configurable per endpoint.

2. **"How do you rate limit across multiple API gateway instances?"**
   → Centralized state in Redis. All gateways check the same Redis key. Redis INCR is atomic. For ultra-low-latency: local in-memory counter with periodic sync to Redis (slightly less accurate but faster).

3. **"Clock skew between servers — how does it affect sliding window?"**
   → Fixed window: minimal impact (windows are aligned to wall clock). Sliding window log: each server uses its own clock for timestamps — skew causes inaccurate windows. Solution: use Redis server time (TIME command) instead of local clock. Or accept small inaccuracy.

4. **"How do you handle rate limiting for authenticated vs unauthenticated users?"**
   → Authenticated: rate limit by user_id (fair per-user). Unauthenticated: rate limit by IP (can be gamed with proxies). Layered: global limit (protect infra) + per-user limit (fair usage) + per-IP limit (anti-abuse).

5. **"Token bucket vs sliding window — when would you pick each?"**
   → Token bucket: allows bursts (good for APIs where occasional spikes are OK). Sliding window: strict rate enforcement (good for billing, quotas). Sliding window log: most accurate but memory-heavy. Sliding window counter: good balance.

6. **"How do you communicate rate limits to clients?"**
   → Response headers: `X-RateLimit-Limit: 100`, `X-RateLimit-Remaining: 23`, `X-RateLimit-Reset: 1620000000`. On 429: include `Retry-After: 30` header. Document in API docs.

## 10. Failure Matrix

| Component Down | Impact | Mitigation |
|---|---|---|
| Redis | Can't enforce rate limits | Fail open (configurable). Local in-memory fallback with approximate limits. |
| API Gateway | All traffic blocked | Multiple gateway instances behind DNS/LB. Health checks. |
