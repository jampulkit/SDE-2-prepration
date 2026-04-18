# Design: URL Shortener

## 1. Problem Statement & Scope

**Design a URL shortening service like TinyURL or bit.ly that converts long URLs into short, shareable links and redirects users to the original URL.**

**Clarifying questions to ask:**
- How long should the shortened URL be? → 7 characters (Base62 → 3.5 trillion unique URLs)
- Can users create custom aliases? → Yes, optional
- Do URLs expire? → Optional, default 5 years
- Do we need analytics (click count, referrers)? → Yes, basic click tracking
- Who can create URLs? → Both authenticated and anonymous users (rate-limited)

💡 **Why this is a classic interview problem:** It's simple enough to design in 45 minutes but deep enough to test caching, database choice, encoding algorithms, and analytics pipelines. Every component has meaningful trade-offs.

## 2. Requirements

**Functional:**
- Shorten a long URL → return short URL
- Redirect short URL → original long URL (301/302)
- Custom aliases (optional, user-specified)
- URL expiration (configurable TTL)
- Click analytics (total clicks, clicks over time)

**Non-functional:**
- Low latency redirects (< 50ms p99 for reads)
- High availability (99.99% — redirects must always work)
- Short URLs should not be guessable (no sequential IDs exposed)
- Eventual consistency is acceptable (analytics can be slightly delayed)

**Estimation** [🔥 Must Know]:
```
Write: 100M new URLs/month
Read:Write ratio = 100:1 (most URLs are read many times)

Write QPS: 100M / (30 × 86,400) ≈ 40 QPS. Peak: ~100 QPS.
Read QPS: 40 × 100 = 4,000 QPS. Peak: ~12,000 QPS.

Storage (10 years): 100M/month × 12 × 10 = 12B records × 500 bytes ≈ 6 TB
Cache (80/20 rule): 20% of daily reads × 500 bytes ≈ 35 GB → fits in single Redis
Bandwidth: 12,000 QPS × 500 bytes ≈ 6 MB/s (negligible)
```

**Architecture implications from estimation:**
- Write QPS is low (~40) → single DB handles writes easily
- Read QPS is moderate (~4K, peak 12K) → need caching (Redis handles 100K+ QPS)
- Storage is 6 TB over 10 years → fits on a few DB servers, may need sharding for QPS not storage
- Cache is 35 GB → single Redis instance is sufficient

## 3. High-Level Design

**API:**
```
POST /api/v1/urls
  Headers: Authorization: Bearer <jwt> (optional), X-Idempotency-Key: <uuid>
  Body: { "long_url": "https://example.com/very/long/path", "custom_alias": "my-link", "ttl_hours": 43800 }
  Response: { "short_url": "https://short.ly/abc1234", "long_url": "...", "expires_at": "..." }
  Status: 201 Created

GET /{short_code}
  Response: 301 Moved Permanently (Location: https://example.com/very/long/path)
  — OR 302 Found (if analytics tracking is more important than browser caching)

GET /api/v1/urls/{short_code}/stats
  Response: { "total_clicks": 1234, "created_at": "...", "clicks_by_day": [...] }
  Status: 200 OK
```

⚙️ **Under the Hood — 301 vs 302 Redirect** [🔥 Must Know]:

| Redirect | Browser Caches? | Analytics Impact | Use When |
|----------|----------------|-----------------|----------|
| 301 Moved Permanently | Yes — browser goes directly to long URL next time | Subsequent clicks NOT tracked (browser skips our server) | SEO, permanent redirects |
| 302 Found | No — browser always hits our server first | ALL clicks tracked | Analytics is important |

For a URL shortener with analytics, **302 is usually better** — you see every click. But 301 reduces server load (browser caches the redirect). Trade-off depends on requirements.

**Data Model:**
```sql
urls (
  id          BIGINT PRIMARY KEY AUTO_INCREMENT,
  short_code  VARCHAR(7) UNIQUE INDEX,  -- the short URL identifier
  long_url    VARCHAR(2048) NOT NULL,   -- original URL
  user_id     BIGINT,                   -- nullable for anonymous users
  created_at  TIMESTAMP DEFAULT NOW(),
  expires_at  TIMESTAMP,                -- nullable for no-expiry
  click_count BIGINT DEFAULT 0          -- denormalized for fast reads
)

-- For detailed analytics (separate table or separate store):
click_events (
  id          BIGINT,
  short_code  VARCHAR(7),
  clicked_at  TIMESTAMP,
  referrer    VARCHAR(2048),
  user_agent  VARCHAR(512),
  ip_country  VARCHAR(2)
)
```

**Short Code Generation** [🔥 Must Know]:

| Approach | How | Pros | Cons |
|----------|-----|------|------|
| Hash + truncate | MD5/SHA256(long_url), take first 7 chars in Base62 | Deterministic (same URL → same code), no coordination | Collisions possible, need retry on collision |
| Counter-based | Auto-increment ID → Base62 encode | No collisions, simple | Predictable (sequential), need distributed counter at scale |
| Pre-generated keys | Generate millions of keys offline, assign on demand from a key pool | Fast (no computation), no collision | Need Key Generation Service (KGS), key exhaustion risk |
| Random | Generate random 7-char Base62 string | Simple, not predictable | Collision check needed (but probability is low: 1/62⁷) |

💡 **Intuition — Why Pre-Generated Keys is Often the Best Choice:**
Hash-based has collision issues. Counter-based is predictable (users can guess URLs) and needs a distributed counter. Random needs collision checks. Pre-generated keys solve all these: generate millions of unique keys offline, store them in a database, and hand them out on demand. The Key Generation Service (KGS) is a simple service that maintains a pool of unused keys.

```
Pre-generated Key Service:
  1. Offline: generate 100M random 7-char Base62 strings, store in DB
  2. KGS loads a batch (e.g., 1000 keys) into memory
  3. On URL creation request: KGS hands out next key from memory batch
  4. When batch runs low: load next batch from DB, mark as "used"
  5. Multiple KGS instances: each loads different batches (no overlap)
```

**Base62 encoding:** `[0-9a-zA-Z]` = 62 characters. 7 chars → 62⁷ ≈ 3.5 trillion unique URLs. At 100M/month, this lasts ~2,900 years.

```java
private static final String BASE62 = "0123456789abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ";

public String encode(long id) {
    StringBuilder sb = new StringBuilder();
    while (id > 0) {
        sb.append(BASE62.charAt((int)(id % 62)));
        id /= 62;
    }
    while (sb.length() < 7) sb.append('0'); // pad to 7 chars
    return sb.reverse().toString();
}

public long decode(String shortCode) {
    long id = 0;
    for (char c : shortCode.toCharArray()) {
        id = id * 62 + BASE62.indexOf(c);
    }
    return id;
}
```

**Architecture:**
```
                    ┌─────────┐
                    │   CDN   │ (cache popular redirects)
                    └────┬────┘
                         │
┌────────┐    ┌──────────┴──────────┐
│ Client │───→│   Load Balancer     │
└────────┘    └──────────┬──────────┘
                         │
              ┌──────────┴──────────┐
              │    App Servers      │
              └──┬──────────────┬───┘
                 │              │
          ┌──────┴──────┐  ┌───┴────────────┐
          │ Redis Cache │  │ Key Generation  │
          │ (35 GB)     │  │ Service (KGS)   │
          └──────┬──────┘  └────────────────┘
                 │
          ┌──────┴──────┐
          │  Database   │ (DynamoDB or PostgreSQL)
          └──────┬──────┘
                 │
          ┌──────┴──────┐
          │   Kafka     │ → Click Analytics Consumer → ClickHouse
          └─────────────┘
```

## 4. Deep Dive

**Read path (redirect) — the hot path:**
```
1. Client: GET /abc1234
2. App server: check Redis cache for key "abc1234"
3. Cache HIT (99%+ of requests):
   → Return 302 redirect to long_url
   → Async: publish click event to Kafka
4. Cache MISS:
   → Query database for short_code = "abc1234"
   → If found: populate Redis cache (with TTL = URL expiry), redirect
   → If not found: return 404
   → Async: publish click event to Kafka
```

**Write path (shorten):**
```
1. Client: POST /api/v1/urls { "long_url": "https://..." }
2. Validate long_url (is it a valid URL? not malicious?)
3. Check for custom alias collision (if custom alias provided)
4. Get short code from KGS (or generate via hash/counter)
5. Write to database: INSERT INTO urls (short_code, long_url, ...)
6. Populate Redis cache
7. Return { "short_url": "https://short.ly/abc1234" }
```

**Database choice:**

| Option | Pros | Cons | Verdict |
|--------|------|------|---------|
| DynamoDB | Simple key-value, auto-scaling, managed | No joins (not needed here), cost at scale | ✅ Good choice for simple lookups |
| PostgreSQL | ACID, familiar, read replicas | Needs manual scaling | ✅ Good if you want SQL familiarity |
| Redis (primary) | Fastest reads | Persistence concerns, memory cost for 6 TB | ❌ Too expensive as primary store |

**Caching strategy:** Cache-aside with Redis. TTL matches URL expiry. 35 GB fits in a single Redis instance. Cache hit rate should be >95% (popular URLs are accessed repeatedly).

**Analytics pipeline** [🔥 Must Know]:
Don't update the database on every click (write amplification at 4K QPS). Instead:
```
Click → Kafka topic "click-events" → Consumer aggregates → Batch update to ClickHouse/DB

Benefits:
  - Decouples analytics from redirect path (redirect stays fast)
  - Kafka buffers spikes
  - Consumer can aggregate (count clicks per minute, not per click)
  - ClickHouse is optimized for analytics queries
```

💥 **What Can Go Wrong:**

| Problem | Impact | Solution |
|---------|--------|---------|
| Hash collision | Two URLs get same short code | Retry with salt, or use pre-generated keys |
| Cache stampede | Popular URL expires, thousands of requests hit DB | Lock on cache miss (only one request fetches from DB) |
| KGS single point of failure | Can't create new URLs | Multiple KGS instances, each with pre-loaded key batches |
| Expired URL still in cache | User redirected to expired URL | Set Redis TTL = URL expiry time |
| Malicious URLs | Users create short links to phishing sites | URL scanning service (Google Safe Browsing API), rate limiting |

## 5. Advanced / Follow-ups

- **100x scale (1B reads/day):** Shard database by short_code hash. Multiple Redis clusters (consistent hashing). CDN caches popular redirects at edge.
- **Custom domains:** Map custom domains to short codes. DNS CNAME + SSL cert per domain (Let's Encrypt).
- **Abuse prevention:** Rate limiting per IP/user, URL scanning for malware, CAPTCHA for anonymous users, blacklist known malicious domains.
- **Multi-region:** Replicate DB across regions. Route users to nearest region via GeoDNS. Cache is per-region.
- **URL preview:** Before redirecting, show a preview page with the destination URL (safety feature).

🎯 **Likely Follow-ups:**
- **Q:** How would you handle a URL that goes viral (millions of clicks/second)?
  **A:** CDN caches the redirect at edge servers worldwide. Redis handles the rest. The actual DB is barely touched. For analytics, Kafka absorbs the burst and consumers process at steady rate.
- **Q:** How do you prevent enumeration (guessing short codes)?
  **A:** Use random codes (not sequential). Rate limit redirect requests per IP. Add CAPTCHA after N failed lookups.
- **Q:** How do you handle the same long URL submitted multiple times?
  **A:** Option 1: Create a new short code each time (simpler, each user gets their own). Option 2: Check if long_url already exists and return the existing short code (saves storage, but needs an index on long_url).

## 6. Common Mistakes

| Weak Answer | Strong Answer |
|-------------|---------------|
| "I'll use MD5 to generate the short code" | "I'll use pre-generated keys from a KGS to avoid collisions and coordination overhead. Alternatively, Base62 encoding of a counter works but is predictable." |
| "I'll use 301 redirect" | "I'll use 302 so we can track every click. 301 is cached by the browser, so subsequent clicks bypass our server and aren't tracked." |
| "I'll update click_count in the DB on every redirect" | "I'll publish click events to Kafka and aggregate them asynchronously. This keeps the redirect path fast and decouples analytics." |
| No caching mentioned | "At 4K read QPS, I'll use Redis cache-aside. 35 GB covers 20% of daily reads (80/20 rule), giving >95% cache hit rate." |

## 7. Interviewer's Evaluation Criteria

| Criteria | What They Look For |
|----------|-------------------|
| Requirements | Clear functional + non-functional, reasonable estimation |
| Short code generation | Discusses multiple approaches with trade-offs, picks one with justification |
| Caching | Cache-aside with Redis, estimates cache size, discusses hit rate |
| 301 vs 302 | Understands the trade-off between caching and analytics |
| Analytics | Async pipeline (Kafka), not synchronous DB writes |
| Scalability | Discusses sharding, CDN, multi-region for 100x scale |
| Failure handling | Cache stampede, KGS failure, expired URLs |

## 7. How I'd Present This in 45 Minutes

```
[0-5 min] Requirements:
"I'll design a URL shortener. Functional: shorten URLs, redirect, custom aliases, analytics.
Non-functional: 100M new URLs/month, 10:1 read:write, p99 redirect < 50ms, 99.99% availability."

[5-10 min] Estimation:
"Write QPS: ~40, peak ~100. Read QPS: ~4000, peak ~12000. Storage: 6TB over 10 years.
Cache: 35GB (80/20 rule) fits in one Redis. This is read-heavy, so caching is critical."

[10-20 min] High-Level Design:
"POST /api/urls creates a short URL. GET /{code} redirects with 302.
I'll use a Key Generation Service that pre-generates unique codes from a Base62 counter.
PostgreSQL for URL mapping, Redis for caching hot URLs, 302 redirect for analytics."

[20-40 min] Deep Dive:
"Let me dive into the key generation. Base62 with 7 chars gives 3.5 trillion unique codes.
I'll use a KGS that pre-generates batches of codes and hands them to app servers.
For caching, cache-aside with Redis. On redirect: check Redis first, then DB.
For analytics, log click events to Kafka, process async into a clicks table."

[40-45 min] Wrap-up:
"For monitoring: track redirect latency p99, cache hit rate, error rate.
Failure handling: if KGS is down, fall back to random generation with collision check.
Extension: URL expiration with TTL, abuse detection, geographic analytics."
```

## 7b. Common Mistakes to Avoid

| Mistake | Why It's Wrong | What to Do Instead |
|---------|---------------|-------------------|
| Using auto-increment IDs as short codes | Sequential, predictable, guessable | Use Base62 encoding or pre-generated random codes |
| Using 301 redirect without considering analytics | 301 is cached by browser, subsequent clicks not tracked | Use 302 for analytics, 301 only if tracking not needed |
| Not discussing cache invalidation | URLs rarely change, but expired URLs need removal | TTL on cache entries, delete on URL expiration |
| Ignoring the read:write ratio in design | Leads to over-engineering the write path | Focus optimization on the read path (caching, CDN) |
| Storing the full long URL in the cache value | Wastes cache memory | Cache only the mapping: short_code → long_url |

## 8. Revision Checklist

- [ ] Base62 encoding: 7 chars → 62⁷ ≈ 3.5 trillion unique URLs
- [ ] Three approaches: hash+truncate (collisions), counter+encode (predictable), pre-generated keys (best)
- [ ] 301 (browser caches, less analytics) vs 302 (always hits server, better tracking)
- [ ] Cache-aside with Redis: 35 GB for 20% of daily reads, >95% hit rate
- [ ] Analytics via Kafka → async aggregation → ClickHouse (not synchronous DB writes)
- [ ] Read:write = 100:1, read QPS ~4K peak ~12K, storage ~6 TB for 10 years
- [ ] DB choice: DynamoDB (simple key-value) or PostgreSQL (familiar, ACID)
- [ ] KGS: pre-generate keys offline, hand out on demand, multiple instances for HA

> 🔗 **See Also:** [02-system-design/04-api-design.md](../04-api-design.md) for REST API design patterns. [02-system-design/00-prerequisites.md](../00-prerequisites.md) for consistent hashing (used in sharding at scale). [06-tech-stack/02-redis-deep-dive.md](../../06-tech-stack/02-redis-deep-dive.md) for Redis caching patterns.

---

## 9. Interviewer Deep-Dive Questions

1. **"A short URL goes viral — 10M clicks/sec. What breaks first?"**
   → Redis handles 100K QPS per instance, so you need ~100 Redis nodes or a CDN layer. CDN caches the 302 redirect at edge. DB is never touched. Kafka absorbs the analytics burst.

2. **"What if your hash function produces a collision?"**
   → Detect via DB UNIQUE constraint on short_code. On collision: retry with a salt appended to the input, or fall back to pre-generated keys from KGS. Collision probability with 7-char Base62 is ~1 in 3.5 trillion — negligible, but handle it anyway.

3. **"Same long URL submitted 1M times — do you create 1M short codes?"**
   → Trade-off: (A) Yes, each user gets their own — simpler, enables per-user analytics. (B) Deduplicate — add index on long_url, return existing code. Option A is usually better because different users want different analytics.

4. **"How do you handle link rot (expired URLs still getting traffic)?"**
   → Return 410 Gone (not 404). Optionally show a "this link has expired" page. Cache TTL = URL expiry. Background job cleans expired entries from DB.

5. **"How do you prevent abuse (phishing, malware links)?"**
   → URL scanning on creation (Google Safe Browsing API). Rate limit anonymous users. CAPTCHA after N creations. Blacklist known malicious domains. Report mechanism for users.

6. **"How would you add geo-analytics (clicks by country)?"**
   → GeoIP lookup on the redirect path (MaxMind DB, <1ms). Append country to the Kafka click event. Aggregate in ClickHouse by short_code + country + day.

## 10. Failure Matrix

| Component Down | Impact | Mitigation |
|---|---|---|
| Redis cache | All reads hit DB (~4K QPS) — DB might survive but latency spikes | Redis Cluster with replicas. Circuit breaker: if Redis down, serve from DB with degraded latency. |
| KGS (Key Generation) | Can't create new short URLs | Multiple KGS instances. Fallback: generate random code + collision check. |
| Database | Can't create or look up URLs | DB replicas for reads. For writes: queue in Kafka, process when DB recovers. |
| Kafka | Analytics events lost | Kafka is replicated (acks=all). If truly down: log events to local disk, replay later. |
| CDN | All traffic hits origin | Origin must handle full load. Auto-scale app servers. |
