# System Design — Resilience Patterns

## 1. Prerequisites
- [01-fundamentals.md](01-fundamentals.md) — availability, failure handling

## 2. Core Concepts

### Why Resilience Matters [🔥 Must Know]

**In a microservices architecture, failures are not exceptional. They are normal. Networks drop packets, services crash, databases slow down. Resilience patterns ensure that one failing component doesn't bring down the entire system.**

💡 **Intuition:** Think of a ship with watertight compartments. If one compartment floods, the ship doesn't sink because the water is contained. Resilience patterns are the watertight doors of your system. Circuit breakers stop calling a failing service. Bulkheads isolate resource pools. Timeouts prevent indefinite waiting. Together, they contain failures.

**The cascading failure problem:**

```
Without resilience patterns:
  Service A calls Service B (which is slow/down)
  Service A's threads block waiting for B (no timeout)
  Service A's thread pool fills up
  Service A can't handle ANY requests (even those not involving B)
  Service C calls Service A → also blocks → C's threads fill up
  Result: one slow service takes down the entire system

With resilience patterns:
  Service A calls Service B with 2s timeout + circuit breaker
  After 5 failures, circuit opens → A returns fallback immediately (no waiting)
  A's threads are free to handle other requests
  Service C is unaffected
```

### Circuit Breaker [🔥 Must Know]

**Prevents cascading failures by stopping calls to a failing service. Like an electrical circuit breaker — trips when too many failures occur.**

```
States:
  CLOSED (normal) → requests pass through
    If failure rate > threshold → trip to OPEN
  
  OPEN (tripped) → requests immediately fail (fast fail, no waiting)
    After timeout → move to HALF-OPEN
  
  HALF-OPEN (testing) → allow a few test requests
    If test succeeds → back to CLOSED
    If test fails → back to OPEN

Implementation (simplified):
  class CircuitBreaker {
      enum State { CLOSED, OPEN, HALF_OPEN }
      State state = CLOSED;
      int failureCount = 0;
      int threshold = 5;
      long lastFailureTime;
      long timeout = 30_000; // 30 seconds
      
      boolean allowRequest() {
          if (state == CLOSED) return true;
          if (state == OPEN && System.currentTimeMillis() - lastFailureTime > timeout) {
              state = HALF_OPEN;
              return true; // allow test request
          }
          return state != OPEN; // HALF_OPEN allows, OPEN rejects
      }
      
      void recordSuccess() { state = CLOSED; failureCount = 0; }
      void recordFailure() {
          failureCount++;
          lastFailureTime = System.currentTimeMillis();
          if (failureCount >= threshold) state = OPEN;
      }
  }
```

**Libraries:** Resilience4j (Java), Hystrix (deprecated but conceptually important), Spring Cloud Circuit Breaker.

### Retry with Exponential Backoff + Jitter [🔥 Must Know]

```java
// Retry with exponential backoff and jitter
int maxRetries = 3;
long baseDelay = 1000; // 1 second

for (int attempt = 0; attempt <= maxRetries; attempt++) {
    try {
        return callService();
    } catch (TransientException e) {
        if (attempt == maxRetries) throw e;
        long delay = baseDelay * (1L << attempt); // 1s, 2s, 4s
        long jitter = (long)(delay * Math.random() * 0.5); // 0-50% random jitter
        Thread.sleep(delay + jitter);
    }
}
```

**Why jitter?** Without jitter, all clients retry at the same time (thundering herd). Jitter spreads retries over time.

**What to retry:** Transient failures (network timeout, 503). **What NOT to retry:** Permanent failures (400 Bad Request, 404 Not Found, authentication errors).

### Bulkhead Pattern

**Isolate failures by partitioning resources. If one component fails, it doesn't consume all resources and starve others.**

```
Without bulkhead:
  Thread pool (100 threads) shared by all services
  Service A is slow → consumes all 100 threads → Service B and C can't get threads → everything fails

With bulkhead:
  Service A: dedicated pool (30 threads)
  Service B: dedicated pool (30 threads)
  Service C: dedicated pool (30 threads)
  Reserve: 10 threads
  Service A is slow → only its 30 threads are consumed → B and C unaffected
```

### Timeout Pattern

**Always set timeouts on external calls. Without timeouts, a slow service can block your threads indefinitely.**

```java
// Connection timeout: how long to wait for connection establishment
// Read timeout: how long to wait for response after connection
HttpClient client = HttpClient.newBuilder()
    .connectTimeout(Duration.ofSeconds(2))  // 2s to connect
    .build();

HttpRequest request = HttpRequest.newBuilder()
    .uri(URI.create("https://api.example.com/data"))
    .timeout(Duration.ofSeconds(5))  // 5s total
    .build();
```

### Graceful Degradation [🔥 Must Know]

**When a component fails, serve a degraded but functional experience instead of a complete failure.**

| Component Down | Degraded Experience |
|---------------|-------------------|
| Recommendation service | Show popular items instead of personalized |
| Search service | Show cached results or "search unavailable" |
| Payment service | Queue the order, process later |
| Image service | Show placeholder images |
| Analytics service | Skip tracking, don't block user flow |

### Fallback Pattern

```java
public Product getProduct(String id) {
    try {
        return productService.getProduct(id); // primary
    } catch (ServiceUnavailableException e) {
        return cache.getProduct(id); // fallback: serve from cache (might be stale)
    }
}
```

## 3. Advanced Patterns

### Health Checks

```
Liveness probe: "Is the process alive?" → restart if dead
  GET /health/live → 200 OK (process running)

Readiness probe: "Can the process handle requests?" → remove from load balancer if not ready
  GET /health/ready → 200 OK (DB connected, cache warm, dependencies healthy)

Startup probe: "Has the process finished initializing?" → don't check liveness until started
  GET /health/started → 200 OK (initialization complete)

Kubernetes uses all three:
  - Liveness: restart crashed pods
  - Readiness: route traffic only to ready pods
  - Startup: give slow-starting apps time to initialize
```

### Chaos Engineering

**Intentionally inject failures to test resilience. If you don't test failure handling, you don't know if it works.**

| Tool | What It Does |
|------|-------------|
| Chaos Monkey (Netflix) | Randomly kills production instances |
| Toxiproxy | Simulates network latency, timeouts, connection drops |
| Gremlin | Controlled failure injection (CPU, memory, network, disk) |

**Start small:** inject latency in staging, then kill a single instance in production, then simulate an AZ failure.

### Idempotency for Retries [🔥 Must Know]

**If you retry a request, the server must handle duplicates gracefully. An idempotent operation produces the same result whether executed once or multiple times.**

```
Idempotent: GET, PUT, DELETE (same result on retry)
NOT idempotent: POST (creates duplicate resources on retry)

Solution: idempotency key
  Client sends: POST /payments  Headers: Idempotency-Key: uuid-123
  Server: check if uuid-123 was already processed
    Yes → return cached response (don't process again)
    No → process, store result keyed by uuid-123, return response
```

🎯 **Likely Follow-ups:**
- **Q:** How do you decide between circuit breaker and retry?
  **A:** Use both together. Retry handles transient failures (one-off network blip). Circuit breaker handles sustained failures (service is down). Retry first (2-3 attempts with backoff). If retries keep failing, circuit breaker opens and stops retrying entirely.
- **Q:** What happens if the circuit breaker is too aggressive (opens too quickly)?
  **A:** Legitimate requests get rejected even though the downstream service might recover quickly. Tune the threshold: require 5-10 failures in a 60-second window before opening. Use a sliding window, not a simple counter.
- **Q:** How do you test resilience patterns?
  **A:** Chaos engineering. Inject failures in staging: add 5s latency to a dependency, kill a database replica, simulate a network partition. Verify that circuit breakers trip, fallbacks activate, and the system degrades gracefully.
- **Q:** What is the difference between timeout and circuit breaker?
  **A:** Timeout prevents one request from waiting forever. Circuit breaker prevents ALL requests from hitting a known-failing service. Timeout is per-request. Circuit breaker is per-service. Use both: timeout catches individual slow calls, circuit breaker catches systemic failures.

## 4. How This Shows Up in Interviews

**What to say:**
> "I'll add circuit breakers on all external service calls. If the payment service fails 5 times in a row, the circuit opens and we immediately return an error instead of waiting for timeouts. After 30 seconds, we try again (half-open). I'll also use retry with exponential backoff and jitter for transient failures, and bulkhead isolation so a slow service doesn't consume all threads."

## 4. Revision Checklist
- [ ] Circuit breaker: CLOSED → OPEN (on failures) → HALF-OPEN (test) → CLOSED (on success)
- [ ] Retry: exponential backoff (1s, 2s, 4s) + jitter (random spread). Only for transient failures.
- [ ] Bulkhead: isolate thread pools per service. Failure in one doesn't starve others.
- [ ] Timeout: always set connect + read timeouts. No timeout = potential thread leak.
- [ ] Graceful degradation: serve degraded experience instead of complete failure.
- [ ] Fallback: primary fails → serve from cache or default value.
- [ ] Libraries: Resilience4j (Java), Spring Cloud Circuit Breaker.

> 🔗 **See Also:** [02-system-design/01-fundamentals.md](01-fundamentals.md) for availability and failure handling. [02-system-design/06-observability-monitoring.md](06-observability-monitoring.md) for monitoring failures.
