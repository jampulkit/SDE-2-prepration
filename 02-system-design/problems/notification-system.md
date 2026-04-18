# Design: Notification System

## 1. Problem Statement & Scope

**Design a scalable notification system that delivers push notifications, SMS, and emails to millions of users with reliability, user preferences, and rate limiting.**

**Clarifying questions to ask:**
- Notification channels? → Push (iOS/Android), SMS, Email
- Real-time or batched? → Soft real-time for push (< 5s), email/SMS can be slightly delayed
- User preferences? → Yes, opt-in/out per channel, quiet hours
- Scheduled notifications? → Yes (e.g., "send at 9 AM user's local time")
- Rate limiting? → Yes, per-user limits to prevent spam
- Template support? → Yes, with variable substitution

## 2. Requirements

**Functional:**
- Send push/SMS/email notifications triggered by events or schedules
- User preferences (opt-in/out per channel, quiet hours, frequency caps)
- Template management (reusable templates with variable substitution)
- Rate limiting per user (max N notifications per channel per hour)
- Scheduled/delayed notifications
- Notification history and analytics (sent/delivered/opened/clicked)

**Non-functional:**
- Soft real-time for push (< 5 seconds from trigger to delivery)
- At-least-once delivery (no lost notifications, duplicates handled)
- High throughput (millions of notifications per day)
- Pluggable providers (swap APNs for FCM, Twilio for another SMS provider)
- Graceful degradation (if SMS provider is down, queue and retry)

**Estimation:**
```
100M users, 5 notifications/user/day = 500M notifications/day
QPS: 500M / 86,400 ≈ 6,000 QPS. Peak: ~18,000 QPS.
  → Kafka handles this easily. Workers scale horizontally.

Breakdown by channel (typical):
  Push: 60% = 300M/day → 3,600 QPS
  Email: 30% = 150M/day → 1,800 QPS
  SMS: 10% = 50M/day → 600 QPS (most expensive, rate-limited)
```

## 3. High-Level Design

```
┌──────────────┐    ┌─────────────────┐    ┌─────────┐    ┌──────────────┐
│ Trigger       │───→│ Notification    │───→│  Kafka  │───→│ Push Workers │──→ APNs/FCM
│ (Service/Cron/│    │ Service         │    │         │    ├──────────────┤
│  Event)       │    │ - Validate      │    │ Topics: │    │ SMS Workers  │──→ Twilio
└──────────────┘    │ - Check prefs   │    │  push   │    ├──────────────┤
                    │ - Apply template│    │  sms    │    │ Email Workers│──→ SES/SendGrid
                    │ - Rate limit    │    │  email  │    └──────────────┘
                    │ - Enqueue       │    └─────────┘           │
                    └────────┬────────┘                    ┌─────┴──────┐
                             │                             │ DLQ        │
                    ┌────────┴────────┐                    │ (failed    │
                    │ User Prefs DB   │                    │  after N   │
                    │ Template Store  │                    │  retries)  │
                    │ Rate Limiter    │                    └────────────┘
                    │ (Redis)         │
                    └─────────────────┘
```

💡 **Intuition — Why Separate Kafka Topics per Channel:** Each channel has different throughput, latency requirements, and failure modes. Push is fast but APNs can throttle. SMS is slow and expensive. Email is high-volume but tolerates delay. Separate topics let you scale workers independently and isolate failures (SMS provider down doesn't affect push delivery).

**Data Model:**
```sql
notifications (
  id            UUID PRIMARY KEY,
  user_id       BIGINT INDEX,
  channel       ENUM('push', 'sms', 'email'),
  template_id   VARCHAR,
  payload       JSON,           -- template variables
  status        ENUM('pending', 'sent', 'delivered', 'failed', 'cancelled'),
  priority      ENUM('high', 'normal', 'low'),
  scheduled_at  TIMESTAMP,      -- null for immediate
  sent_at       TIMESTAMP,
  created_at    TIMESTAMP
)

user_preferences (
  user_id       BIGINT,
  channel       ENUM('push', 'sms', 'email'),
  enabled       BOOLEAN DEFAULT TRUE,
  quiet_start   TIME,           -- e.g., 22:00
  quiet_end     TIME,           -- e.g., 08:00
  timezone      VARCHAR,        -- e.g., 'America/New_York'
  PRIMARY KEY (user_id, channel)
)

templates (
  id            VARCHAR PRIMARY KEY,
  channel       ENUM('push', 'sms', 'email'),
  subject       VARCHAR,        -- for email
  body_template TEXT,           -- "Hello {{name}}, your order {{order_id}} is shipped"
  version       INT
)
```

## 4. Deep Dive

**Notification flow (detailed):**
```
1. Trigger: Order Service publishes "order_shipped" event
2. Notification Service:
   a. Look up user preferences: is push enabled? Is it quiet hours?
   b. Apply rate limit: has user received < 5 push notifications this hour?
   c. Render template: "Hi {{name}}, your order #{{order_id}} has shipped!"
   d. Enqueue to Kafka topic "push" with priority
3. Push Worker:
   a. Consume from Kafka
   b. Look up user's device token (from device registry)
   c. Send to APNs (iOS) or FCM (Android)
   d. On success: update status to "sent", commit Kafka offset
   e. On failure: retry with exponential backoff (1s, 2s, 4s, 8s...)
   f. After 5 retries: move to DLQ, update status to "failed", alert
```

**Reliability** [🔥 Must Know]:
- Kafka ensures messages aren't lost (persistent, replicated)
- Workers ack (commit offset) only after successful send
- Failed → retry with exponential backoff + jitter → DLQ after N retries
- Idempotency key per notification prevents duplicates on retry

**Rate limiting:**
```
Per-user rate limit in Redis:
  Key: ratelimit:{user_id}:{channel}:{hour}
  Value: count of notifications sent this hour
  TTL: 1 hour

  if (redis.incr(key) > limit) → skip notification, log "rate limited"
```

**Priority queues:**
- Separate Kafka topics: `push-high`, `push-normal`, `push-low`
- High-priority workers process `push-high` first
- Or: single topic with priority header, workers process high-priority messages first

**Scheduled notifications:**
- Store in DB with `scheduled_at` timestamp
- Cron job or scheduler service scans for due notifications every minute
- Enqueues them to Kafka for processing
- Alternative: use a delay queue (Redis sorted set with score = scheduled_at)

💥 **What Can Go Wrong:**

| Problem | Impact | Solution |
|---------|--------|---------|
| Provider down (APNs outage) | Push notifications not delivered | Retry with backoff, failover to secondary provider, DLQ |
| Duplicate notifications | User gets same notification twice | Idempotency key, deduplication at worker level |
| Notification storm | User gets 50 notifications in 1 minute | Per-user rate limiting, notification batching/grouping |
| Invalid device token | Push fails permanently | Remove invalid tokens from device registry, don't retry |
| Quiet hours violation | User gets notification at 3 AM | Check timezone + quiet hours before enqueuing |

🎯 **Likely Follow-ups:**
- **Q:** How do you handle notification grouping (e.g., "5 people liked your post")?
  **A:** Buffer notifications for a short window (e.g., 5 minutes). If multiple similar notifications arrive, merge them into one summary notification. Use a Redis sorted set with TTL to track pending notifications per user per event type.
- **Q:** How do you track delivery and open rates?
  **A:** Push: APNs/FCM provide delivery receipts. Email: tracking pixel (1x1 transparent image) for opens, redirect links for clicks. SMS: delivery receipts from provider. Store events in analytics pipeline.
- **Q:** How do you handle multi-device (user has iPhone + iPad)?
  **A:** Device registry stores all device tokens per user. Send push to ALL registered devices. Each device has its own token.

## 5. Advanced / Follow-ups
- **Multi-region delivery:** Route to nearest provider endpoint, handle timezone-aware scheduling
- **A/B testing:** Test different templates, measure open/click rates, auto-select winner
- **Notification center:** In-app notification history (separate from push/SMS/email), stored in DB, paginated
- **Batching:** Group similar notifications ("3 new messages from Alice") to reduce notification fatigue

## 6. Common Mistakes

| Weak Answer | Strong Answer |
|-------------|---------------|
| "Send notifications synchronously" | "Async via Kafka — decouple trigger from delivery, handle failures gracefully" |
| "One worker for all channels" | "Separate workers per channel — different throughput, failure modes, scaling needs" |
| No rate limiting | "Per-user rate limits in Redis to prevent notification spam" |
| No retry/DLQ | "Retry with exponential backoff + jitter, DLQ after 5 failures, alerting" |

## 7. Interviewer's Evaluation Criteria

| Criteria | What They Look For |
|----------|-------------------|
| Architecture | Kafka for reliability, separate workers per channel |
| Reliability | At-least-once delivery, retry + DLQ, idempotency |
| User preferences | Opt-in/out, quiet hours, timezone handling |
| Rate limiting | Per-user limits in Redis |
| Priority | Separate queues or priority headers |
| Pluggable providers | Abstract provider interface, easy to swap |

## 7. How I'd Present This in 45 Minutes

```
[0-5 min] Requirements:
"Multi-channel notification system: push, SMS, email. 100M notifications/day.
Pluggable providers, rate limiting per user, priority levels, retry on failure."

[5-10 min] Estimation:
"QPS: ~1200, peak ~3600. Each notification ~1KB. Storage: 100GB/day for logs.
Need async processing. Kafka for reliability and decoupling."

[10-20 min] High-Level Design:
"API receives notification request → validates → publishes to Kafka (topic per priority).
Workers consume from Kafka → check user preferences → rate limit → send via provider.
DLQ for failed notifications after N retries."

[20-40 min] Deep Dive:
"Rate limiting: max 3 marketing emails/day, unlimited transactional.
Provider abstraction: NotificationProvider interface, swap Twilio/SNS without code changes.
Retry: exponential backoff, max 3 retries, then DLQ. Alert on DLQ depth.
Template engine: notification templates with variable substitution, versioned."

[40-45 min] Wrap-up:
"Monitoring: delivery rate per channel, latency p99, DLQ depth, provider error rates.
Failure: if one provider is down, circuit breaker + fallback to alternate provider.
Extensions: A/B testing notification content, smart delivery timing, batching."
```

## 7b. Common Mistakes to Avoid

| Mistake | Why It's Wrong | What to Do Instead |
|---------|---------------|-------------------|
| Synchronous notification sending | Blocks the caller, can't handle spikes | Async via Kafka. Return 202 Accepted immediately. |
| No rate limiting per user | Users get spammed, unsubscribe, report | Per-user rate limits by channel and category |
| Single provider with no fallback | Provider outage = all notifications fail | Abstract provider interface + circuit breaker + fallback |
| No DLQ for failed notifications | Failed notifications silently lost | DLQ after N retries, alert on depth, manual retry option |
| Treating all notifications equally | Payment confirmation delayed by marketing emails | Priority queues: critical > transactional > marketing |

## 8. Revision Checklist

- [ ] Kafka for reliability and decoupling (separate topics per channel)
- [ ] Separate workers per channel (push/SMS/email) — independent scaling
- [ ] User preferences: opt-in/out, quiet hours, timezone
- [ ] Rate limiting: per-user in Redis (key = user:channel:hour, TTL = 1h)
- [ ] Retry with exponential backoff + jitter → DLQ after N failures
- [ ] Idempotency key per notification to prevent duplicates
- [ ] Priority: separate topics or priority headers
- [ ] Scheduled: DB + cron scanner, or Redis sorted set delay queue
- [ ] Template rendering: variable substitution before enqueuing
- [ ] Analytics: track sent/delivered/opened/clicked rates
- [ ] Estimation: 500M/day, 6K QPS, separate by channel (push 60%, email 30%, SMS 10%)

> 🔗 **See Also:** [02-system-design/03-message-queues-event-driven.md](../03-message-queues-event-driven.md) for Kafka patterns and DLQ. [02-system-design/problems/chat-system.md](chat-system.md) for push notification delivery to online/offline users. [02-system-design/01-fundamentals.md](../01-fundamentals.md) for rate limiting algorithms.

---

## 9. Interviewer Deep-Dive Questions

1. **"100K users need to be notified at once (flash sale). How do you avoid a storm?"**
   → Stagger delivery: spread over 5-10 minutes using random delay per user. Priority queue: critical notifications first. Provider rate limits: APNs/FCM have their own limits — batch requests (FCM supports 500 tokens per multicast).

2. **"How do you ensure exactly-once delivery for push notifications?"**
   → You can't — push is at-least-once by nature (APNs/FCM don't guarantee dedup). Client-side dedup: each notification has a unique ID, client ignores duplicates. Idempotency key prevents duplicate sends from our side.

3. **"User changes timezone. Scheduled notification for 9 AM — which timezone?"**
   → Store user's timezone in profile. Scheduled notifications use user's local time. On timezone change: re-evaluate all pending scheduled notifications. Use a scheduler that resolves timezone at send time, not schedule time.

4. **"How do you handle notification preferences at scale?"**
   → User preferences table: `(user_id, channel, category, enabled)`. Cache in Redis. Check before every send. Categories: transactional (can't opt out), marketing (can opt out), social (configurable). Respect platform rules (CAN-SPAM for email, TCPA for SMS).

5. **"Provider returns 'invalid token'. What do you do?"**
   → Remove the device token from device registry (user uninstalled the app). Don't retry. If ALL tokens for a user are invalid: mark user as unreachable for push. Fall back to email/SMS for critical notifications.
