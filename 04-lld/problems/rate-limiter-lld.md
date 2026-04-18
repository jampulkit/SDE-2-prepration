# LLD: Rate Limiter

## 1. Requirements

**Design an object-oriented rate limiter that supports multiple algorithms and is thread-safe.**

- Support multiple algorithms: token bucket, sliding window, fixed window
- Per-client rate limiting (by client ID or API key)
- Thread-safe for concurrent requests
- Configurable limits (requests per second/minute)
- Return whether a request is allowed or rejected

## 2. Entities & Relationships

```
RateLimiter (interface)
  ├── TokenBucketLimiter
  ├── SlidingWindowLimiter
  └── FixedWindowLimiter

RateLimiterFactory → creates appropriate limiter based on config
RateLimiterConfig: maxRequests, windowSize, algorithm
```

## 3. Design Patterns Used

- **Strategy:** Different rate limiting algorithms (token bucket, sliding window, fixed window)
- **Factory:** Create the right limiter based on configuration

## 4. Complete Java Implementation

```java
// --- Configuration ---
enum Algorithm { TOKEN_BUCKET, SLIDING_WINDOW, FIXED_WINDOW }

class RateLimiterConfig {
    private final int maxRequests;
    private final long windowMillis;
    private final Algorithm algorithm;
    
    public RateLimiterConfig(int maxRequests, long windowMillis, Algorithm algorithm) {
        this.maxRequests = maxRequests;
        this.windowMillis = windowMillis;
        this.algorithm = algorithm;
    }
    // getters
}

// --- Strategy Interface ---
interface RateLimiter {
    boolean allowRequest(String clientId);
}

// --- Token Bucket ---
class TokenBucketLimiter implements RateLimiter {
    private final int maxTokens;
    private final double refillRate; // tokens per millisecond
    private final ConcurrentHashMap<String, TokenBucket> buckets = new ConcurrentHashMap<>();
    
    public TokenBucketLimiter(int maxTokens, long windowMillis) {
        this.maxTokens = maxTokens;
        this.refillRate = (double) maxTokens / windowMillis;
    }
    
    public boolean allowRequest(String clientId) {
        TokenBucket bucket = buckets.computeIfAbsent(clientId, k -> new TokenBucket(maxTokens));
        return bucket.tryConsume();
    }
    
    private class TokenBucket {
        private double tokens;
        private long lastRefillTime;
        
        TokenBucket(int maxTokens) {
            this.tokens = maxTokens;
            this.lastRefillTime = System.currentTimeMillis();
        }
        
        synchronized boolean tryConsume() {
            refill();
            if (tokens >= 1) {
                tokens -= 1;
                return true;
            }
            return false;
        }
        
        private void refill() {
            long now = System.currentTimeMillis();
            double newTokens = (now - lastRefillTime) * refillRate;
            tokens = Math.min(maxTokens, tokens + newTokens);
            lastRefillTime = now;
        }
    }
}

// --- Fixed Window ---
class FixedWindowLimiter implements RateLimiter {
    private final int maxRequests;
    private final long windowMillis;
    private final ConcurrentHashMap<String, WindowCounter> counters = new ConcurrentHashMap<>();
    
    public FixedWindowLimiter(int maxRequests, long windowMillis) {
        this.maxRequests = maxRequests;
        this.windowMillis = windowMillis;
    }
    
    public boolean allowRequest(String clientId) {
        WindowCounter counter = counters.computeIfAbsent(clientId, k -> new WindowCounter());
        return counter.tryIncrement();
    }
    
    private class WindowCounter {
        private final AtomicInteger count = new AtomicInteger(0);
        private volatile long windowStart = System.currentTimeMillis();
        
        boolean tryIncrement() {
            long now = System.currentTimeMillis();
            if (now - windowStart >= windowMillis) {
                synchronized (this) {
                    if (now - windowStart >= windowMillis) { // double-check
                        count.set(0);
                        windowStart = now;
                    }
                }
            }
            return count.incrementAndGet() <= maxRequests;
        }
    }
}

// --- Sliding Window Log ---
class SlidingWindowLimiter implements RateLimiter {
    private final int maxRequests;
    private final long windowMillis;
    private final ConcurrentHashMap<String, Deque<Long>> logs = new ConcurrentHashMap<>();
    
    public SlidingWindowLimiter(int maxRequests, long windowMillis) {
        this.maxRequests = maxRequests;
        this.windowMillis = windowMillis;
    }
    
    public boolean allowRequest(String clientId) {
        Deque<Long> timestamps = logs.computeIfAbsent(clientId, k -> new ConcurrentLinkedDeque<>());
        long now = System.currentTimeMillis();
        long windowStart = now - windowMillis;
        
        // Remove expired timestamps
        while (!timestamps.isEmpty() && timestamps.peekFirst() <= windowStart) {
            timestamps.pollFirst();
        }
        
        if (timestamps.size() < maxRequests) {
            timestamps.addLast(now);
            return true;
        }
        return false;
    }
}

// --- Factory ---
class RateLimiterFactory {
    public static RateLimiter create(RateLimiterConfig config) {
        return switch (config.getAlgorithm()) {
            case TOKEN_BUCKET -> new TokenBucketLimiter(config.getMaxRequests(), config.getWindowMillis());
            case FIXED_WINDOW -> new FixedWindowLimiter(config.getMaxRequests(), config.getWindowMillis());
            case SLIDING_WINDOW -> new SlidingWindowLimiter(config.getMaxRequests(), config.getWindowMillis());
        };
    }
}

// --- Usage ---
class ApiGateway {
    private final RateLimiter limiter;
    
    public ApiGateway(RateLimiterConfig config) {
        this.limiter = RateLimiterFactory.create(config);
    }
    
    public Response handleRequest(Request request) {
        String clientId = request.getApiKey();
        if (!limiter.allowRequest(clientId)) {
            return Response.status(429)
                .header("Retry-After", "60")
                .body("Rate limit exceeded");
        }
        return processRequest(request);
    }
}
```

## 5. Algorithm Comparison

| Algorithm | Allows Bursts | Memory per Client | Accuracy | Complexity |
|-----------|-------------|-------------------|----------|-----------|
| Token Bucket | Yes (up to max tokens) | O(1) | Good | Simple |
| Fixed Window | Yes (2x at boundary) | O(1) | Approximate | Simplest |
| Sliding Window Log | No | O(n) per window | Exact | Most complex |

## 6. Follow-ups

🎯 **Likely Follow-ups:**
- **Q:** How would you make this distributed (multiple servers)?
  **A:** Use Redis as the shared state. Token bucket: Redis key with DECR + TTL. Sliding window: Redis sorted set with ZRANGEBYSCORE. Lua script for atomicity.
- **Q:** How would you support different limits per endpoint?
  **A:** Composite key: `clientId:endpoint`. Each combination has its own limiter instance. Configure limits per endpoint in a config map.
- **Q:** What about the fixed window boundary problem?
  **A:** At the boundary of two windows, a client can make 2x the limit (max at end of window 1 + max at start of window 2). Sliding window counter approximation fixes this: `count = prev_window_count * overlap_percentage + current_window_count`.

## 7. Revision Checklist

- [ ] Strategy pattern: RateLimiter interface with TokenBucket, FixedWindow, SlidingWindow implementations
- [ ] Token bucket: refill tokens over time, consume on request. Allows bursts.
- [ ] Fixed window: counter per time window. Simple but 2x burst at boundary.
- [ ] Sliding window log: store timestamps, remove expired. Exact but O(n) memory.
- [ ] Thread safety: synchronized on bucket, AtomicInteger for counter, ConcurrentHashMap for client isolation
- [ ] Factory: create limiter based on config
- [ ] Distributed: Redis for shared state, Lua scripts for atomicity

> 🔗 **See Also:** [02-system-design/problems/rate-limiter.md](../../02-system-design/problems/rate-limiter.md) for system design version. [04-lld/02-design-patterns.md](../02-design-patterns.md) for Strategy pattern.
