# System Design — Observability & Monitoring

## 1. Prerequisites
- [01-fundamentals.md](01-fundamentals.md) — monitoring basics, p50/p95/p99

## 2. Core Concepts

### Three Pillars of Observability [🔥 Must Know]

**Observability is the ability to understand a system's internal state from its external outputs. In a microservices architecture with dozens of services, you can't SSH into every box to debug. You need metrics, logs, and traces to understand what's happening.**

💡 **Intuition:** Think of observability like a car dashboard. Metrics are the gauges (speed, RPM, fuel). Logs are the black box recorder (what happened and when). Traces are GPS tracking (the exact route a request took through the system). You need all three to diagnose problems.

**Metrics:** Quantitative measurements over time. QPS, latency percentiles, error rate, CPU/memory, cache hit rate.
- Tools: Prometheus + Grafana, CloudWatch, Datadog
- Types: counters (total requests, only goes up), gauges (current CPU, goes up and down), histograms (latency distribution, bucketed)

⚙️ **Under the Hood, Metric Types:**

```
Counter: monotonically increasing value
  http_requests_total{method="GET", status="200"} = 1,234,567
  Rate: rate(http_requests_total[5m]) = 42 req/sec over last 5 minutes

Gauge: current value that can go up or down
  jvm_memory_used_bytes = 512_000_000
  cpu_usage_percent = 73.5

Histogram: distribution of values in buckets
  http_request_duration_seconds_bucket{le="0.1"} = 900   (90% under 100ms)
  http_request_duration_seconds_bucket{le="0.5"} = 980   (98% under 500ms)
  http_request_duration_seconds_bucket{le="1.0"} = 995   (99.5% under 1s)
  http_request_duration_seconds_bucket{le="+Inf"} = 1000  (100%)
  
  From this: p50 ≈ 50ms, p99 ≈ 800ms, p99.9 ≈ 1.2s
```

**Logging:** Structured event records for debugging. What happened and why.
- Tools: ELK Stack (Elasticsearch + Logstash + Kibana), Splunk, CloudWatch Logs
- Best practices: structured JSON logs, correlation IDs (trace every request across services), log levels (ERROR > WARN > INFO > DEBUG)

⚙️ **Under the Hood, Structured Logging:**

```json
// BAD: unstructured log
"2024-01-15 10:23:45 ERROR Failed to process payment for user 12345"

// GOOD: structured JSON log
{
  "timestamp": "2024-01-15T10:23:45.123Z",
  "level": "ERROR",
  "service": "payment-service",
  "trace_id": "abc-123-def-456",
  "user_id": "12345",
  "order_id": "ORD-789",
  "message": "Payment processing failed",
  "error": "ConnectionTimeout",
  "duration_ms": 5000,
  "payment_provider": "stripe"
}

// Why structured? You can query: "show all ERROR logs for user 12345 in the last hour"
// With unstructured logs, you'd need regex parsing.
```

**Tracing:** Follow a single request across multiple services in a microservices architecture.
- Tools: Jaeger, Zipkin, AWS X-Ray, OpenTelemetry
- Each request gets a unique trace ID. Each service adds a span (start time, duration, metadata).

```
Trace ID: abc-123
├── Span: API Gateway (2ms)
│   └── Tags: method=GET, path=/api/orders/123
├── Span: Auth Service (5ms)
│   └── Tags: user_id=456, auth_method=JWT
├── Span: Order Service (50ms)
│   ├── Span: Redis Cache (0.5ms) — cache miss
│   │   └── Tags: cache_hit=false, key=order:123
│   └── Span: PostgreSQL (15ms)
│       └── Tags: query=SELECT, rows=1, table=orders
└── Span: Notification Service (async, 100ms)
    └── Tags: channel=email, status=queued

Total user-facing latency: 57ms (critical path: gateway + auth + order)
Notification is async, doesn't add to user-facing latency.
```

**How the three pillars work together:**

```
Alert fires: "p99 latency > 500ms for order-service"  ← METRICS tell you WHAT

Check traces: trace abc-123 shows PostgreSQL span took 450ms  ← TRACES tell you WHERE

Check logs: "Slow query: SELECT * FROM orders WHERE status='PENDING' 
            — full table scan, 2.3M rows examined"  ← LOGS tell you WHY

Fix: add index on orders(status). p99 drops to 50ms.
```

### SLIs, SLOs, SLAs [🔥 Must Know]

| Term | What | Who Defines | Example |
|------|------|------------|---------|
| **SLI** (Service Level Indicator) | Metric that measures service quality | Engineering team | p99 latency, error rate, availability |
| **SLO** (Service Level Objective) | Target value for an SLI | Engineering + Product | p99 latency < 200ms, availability > 99.9% |
| **SLA** (Service Level Agreement) | Contract with consequences for missing SLO | Business + Legal | 99.9% availability or customer gets credits |

💡 **Intuition:** SLI is the speedometer reading. SLO is the speed limit. SLA is the speeding ticket.

**Error budget:** If SLO is 99.9% availability (8.76 hours downtime/year), you have an "error budget" of 8.76 hours. Use it for deployments, experiments, maintenance. When budget is exhausted, freeze changes and focus on reliability.

⚙️ **Under the Hood, Error Budget Math:**

```
SLO: 99.9% availability
Total minutes/month: 30 * 24 * 60 = 43,200
Error budget: 0.1% * 43,200 = 43.2 minutes/month

If a bad deployment causes 20 minutes of downtime:
  Remaining budget: 43.2 - 20 = 23.2 minutes
  Team can still deploy, but carefully.

If another incident takes 25 minutes:
  Budget exhausted: 23.2 - 25 = -1.8 minutes
  Action: freeze deployments, focus on reliability, postmortem.

SLO tiers:
  99%    = 7.3 hours/month downtime (internal tools)
  99.9%  = 43 minutes/month (most web services)
  99.99% = 4.3 minutes/month (payment systems, databases)
  99.999% = 26 seconds/month (DNS, core infrastructure)
```

### Key Metrics to Monitor [🔥 Must Know]

**The RED Method (for request-driven services):**

| Metric | What | Alert Threshold |
|--------|------|----------------|
| **R**ate | Requests per second | Sudden drop > 50% |
| **E**rrors | Error rate (5xx / total) | > 1% for 5 minutes |
| **D**uration | Latency percentiles (p50, p95, p99) | p99 > 500ms |

**The USE Method (for resources like CPU, memory, disk):**

| Metric | What | Alert Threshold |
|--------|------|----------------|
| **U**tilization | % of resource in use | > 80% |
| **S**aturation | Queue depth, waiting requests | Growing continuously |
| **E**rrors | Hardware/software errors | Any non-zero |

**Full monitoring dashboard:**

| Category | Metrics | Alert When |
|----------|---------|-----------|
| Availability | Uptime %, health check success rate | < 99.9% |
| Latency | p50, p95, p99 response time | p99 > 500ms |
| Errors | Error rate (5xx), exception count | Error rate > 1% |
| Throughput | QPS, requests/sec | Sudden drop > 50% |
| Saturation | CPU %, memory %, disk I/O, connection pool | > 80% utilization |
| Cache | Hit rate, miss rate, eviction rate | Hit rate < 90% |
| Queue | Depth, consumer lag, processing time | Lag growing continuously |
| Dependencies | Upstream service latency, error rate | Dependency error rate > 5% |

### Alerting Best Practices [🔥 Must Know]

- Alert on **symptoms** (high error rate, slow responses), not causes (high CPU). High CPU is fine if latency is normal.
- Use **multi-window alerts**: alert if error rate > 1% for 5 minutes (not just 1 second). Avoids flapping.
- **Severity levels**: P1 (page on-call, wake them up), P2 (Slack notification, handle during work hours), P3 (ticket, fix this week)
- Avoid **alert fatigue**: too many alerts = people ignore them all. Every alert should be actionable.
- **Runbooks**: every alert should link to a runbook with diagnosis steps and remediation actions.

⚠️ **Common Pitfall:** Alerting on CPU > 80%. CPU can spike during garbage collection, batch jobs, or deployments without affecting users. Alert on user-facing symptoms (latency, errors) instead.

### Distributed Tracing Implementation

```
How trace context propagates across services:

1. API Gateway generates trace_id=abc-123, span_id=span-1
2. Adds headers to request:
   X-Trace-Id: abc-123
   X-Span-Id: span-1
3. Order Service receives request, reads headers
4. Creates child span: trace_id=abc-123, span_id=span-2, parent_span_id=span-1
5. Calls Payment Service with same trace_id, new span_id
6. Each service reports spans to tracing backend (Jaeger)
7. Jaeger assembles spans into a trace tree

OpenTelemetry (standard):
  - Language-agnostic SDK
  - Auto-instruments HTTP clients, DB drivers, message queues
  - Exports to Jaeger, Zipkin, AWS X-Ray, Datadog
```

### Log Aggregation Architecture

```
Service A ──→ Filebeat ──→ Kafka ──→ Logstash ──→ Elasticsearch ──→ Kibana
Service B ──→ Filebeat ──↗                                          (dashboard)
Service C ──→ Filebeat ──↗

Why Kafka in the middle?
  - Buffer: if Elasticsearch is slow, logs queue in Kafka (no data loss)
  - Decoupling: add new consumers (alerting, analytics) without changing services
  - Throughput: Kafka handles 100K+ events/sec easily
```

🎯 **Likely Follow-ups:**
- **Q:** How do you handle high-cardinality metrics (e.g., per-user latency)?
  **A:** Don't create a metric per user. Use histograms with labels for dimensions you need (endpoint, status code, region). For per-user debugging, use traces and logs, not metrics. High-cardinality metrics explode storage costs.
- **Q:** What is the difference between p99 and average latency?
  **A:** Average hides outliers. If 99 requests take 10ms and 1 takes 10 seconds, average is 109ms (looks fine) but p99 is 10 seconds (terrible for that 1% of users). Always use percentiles for latency.
- **Q:** How do you debug a latency spike in a microservices system?
  **A:** (1) Check metrics dashboard: which service's latency increased? (2) Pull a slow trace: which span is the bottleneck? (3) Check that span's logs: what query/operation was slow? (4) Fix: add index, increase cache TTL, scale up, etc.

### How This Shows Up in Interviews

**What to say in system design wrap-up (30 seconds):**
> "For monitoring, I'd track the RED metrics: request rate, error rate, and p99 latency as primary SLIs. SLOs: p99 < 200ms, error rate < 0.1%, availability > 99.9%. I'd use Prometheus for metrics with Grafana dashboards, structured JSON logging with correlation IDs for debugging, and OpenTelemetry for distributed tracing. Alerts fire on symptoms: error rate > 1% sustained for 5 minutes pages on-call. Each alert links to a runbook."

## 3. Revision Checklist
- [ ] Three pillars: metrics (Prometheus), logging (ELK), tracing (Jaeger/OpenTelemetry)
- [ ] Metric types: counter (total, only up), gauge (current, up/down), histogram (distribution)
- [ ] SLI = metric, SLO = target, SLA = contract with consequences
- [ ] Error budget: SLO slack. 99.9% = 43 min/month. Exhausted = freeze deployments.
- [ ] RED method: Rate, Errors, Duration (for services)
- [ ] USE method: Utilization, Saturation, Errors (for resources)
- [ ] Alert on symptoms (latency, errors), not causes (CPU). Multi-window. Link to runbooks.
- [ ] Correlation ID: unique ID per request, propagated via HTTP headers across all services
- [ ] Structured logging: JSON format, queryable fields, not free-text
- [ ] Trace = tree of spans. Each span = one service call with timing and metadata.
- [ ] Log aggregation: services → Filebeat → Kafka → Logstash → Elasticsearch → Kibana

> 🔗 **See Also:** [02-system-design/01-fundamentals.md](01-fundamentals.md) for p50/p95/p99 explanation. [02-system-design/08-resilience-patterns.md](08-resilience-patterns.md) for circuit breakers and failure handling.
