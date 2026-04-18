# Design: E-Commerce System

## 1. Problem Statement & Scope

**Design an e-commerce platform like Amazon or Flipkart that handles product catalog, shopping cart, checkout, payment processing, and order tracking.**

**Clarifying questions to ask:**
- How many products? → 100M+ SKUs
- How many users? → 500M registered, 50M DAU
- Payment methods? → Credit card, UPI, wallet, COD
- Real-time inventory? → Yes, prevent overselling
- Personalization? → Basic recommendations, out of scope for deep ML

💡 **Why this is the most common SD interview problem:** It touches every major system design concept: read-heavy catalog (caching, search), write-heavy orders (consistency, queues), payment processing (idempotency, state machines), and event-driven architecture (Kafka). Your payments background is a differentiator here.

## 2. Requirements

**Functional:**
- Product catalog: browse, search, filter, sort
- Shopping cart: add/remove items, persist across sessions
- Checkout: address, payment, order placement
- Payment processing: multiple methods, idempotent
- Order tracking: real-time status updates
- Inventory management: prevent overselling

**Non-functional:**
- Product pages: < 200ms p99 latency (read-heavy, cacheable)
- Checkout: < 2s end-to-end (strong consistency for payment + inventory)
- 99.99% availability for catalog, 99.9% for checkout
- Handle flash sales (100x normal traffic spikes)

**Estimation:**
```
50M DAU, 10 page views/user/day = 500M page views/day
Read QPS: 500M / 86400 ≈ 6,000 QPS. Peak (flash sale): ~60,000 QPS.
  → Need heavy caching. Redis handles 100K+ QPS.

Orders: 2M orders/day
Write QPS: 2M / 86400 ≈ 25 QPS. Peak: ~250 QPS.
  → Low write QPS but EVERY write must be correct (payment, inventory).

Product catalog: 100M products × 5KB each = 500GB
  → Fits in a few DB servers. Hot products cached in Redis.

Search: Elasticsearch cluster for full-text search + filters
```

## 3. High-Level Design

```
┌──────────┐     ┌──────────────┐     ┌─────────────────────────────────┐
│  Client   │────→│  API Gateway │────→│  Product Service                │
│ (Web/App) │     │  (auth, rate │     │  (catalog, search, reviews)     │
└──────────┘     │   limit)     │     └──────────┬──────────────────────┘
                  └──────┬───────┘                │
                         │                   ┌────┴────┐
                         │                   │ Elastic  │ (search)
                         │                   │ Search   │
                  ┌──────┴───────┐           └─────────┘
                  │  Cart Service │
                  │  (Redis)      │     ┌─────────────────────────────────┐
                  └──────┬───────┘     │  Order Service                   │
                         │             │  (checkout, state machine)        │
                  ┌──────┴───────┐     └──────────┬──────────────────────┘
                  │  Checkout    │                 │
                  │  Orchestrator│────→ ┌──────────┴──────┐
                  └──────────────┘     │  Payment Service  │──→ PSP (Stripe)
                                       └──────────────────┘
                                       ┌──────────────────┐
                                       │ Inventory Service │
                                       └──────────────────┘
                                              │
                                       ┌──────┴──────┐
                                       │    Kafka     │──→ Notification Service
                                       │  (events)   │──→ Analytics
                                       └─────────────┘
```

## 4. Deep Dive

### Product Catalog (Read Path) [🔥 Must Know]

```
Read path (optimized for speed):
  Client → CDN (static images, CSS) 
  Client → API Gateway → Product Service → Redis Cache (hit? return)
                                         → PostgreSQL (miss? query, populate cache)
  
  Search: Client → API Gateway → Elasticsearch (full-text + filters)

Caching strategy:
  - Product detail pages: cache in Redis, TTL = 5 min
  - Category pages: cache in Redis, TTL = 1 min (more dynamic)
  - Search results: cache in Elasticsearch (built-in)
  - Images: CDN (CloudFront), TTL = 24 hours
  
  Cache invalidation: product update → publish event → invalidate cache key
```

### Shopping Cart

```
Two approaches:

1. Redis (recommended for logged-in users):
   Key: cart:{user_id}
   Value: {items: [{product_id, quantity, price_at_add_time}], updated_at}
   TTL: 7 days
   Pros: fast, persists across sessions, survives server restarts
   
2. Client-side (for guest users):
   Store in localStorage or cookie
   Merge with server cart on login

Cart → Checkout transition:
  1. Lock cart (prevent modifications during checkout)
  2. Validate: are all items still in stock? Are prices still valid?
  3. If price changed: notify user, ask to confirm
  4. If out of stock: remove item, notify user
```

### Checkout Flow (Write Path) [🔥 Must Know]

```
Checkout is a SAGA (distributed transaction across services):

1. Order Service: Create order (status=CREATED)
2. Inventory Service: Reserve stock (decrement available, increment reserved)
3. Payment Service: Process payment (call PSP with idempotency key)
4. Order Service: Update order (status=CONFIRMED)
5. Notification Service: Send confirmation email/push
6. Inventory Service: Convert reserved → sold

Failure handling (compensating transactions):
  Payment fails → Release inventory reservation → Cancel order
  Inventory reservation fails → Cancel order → Notify user "out of stock"
  
Orchestration (recommended over choreography for checkout):
  Checkout Orchestrator manages the saga steps sequentially.
  Easier to debug, monitor, and add new steps.
```

### Inventory Management (Prevent Overselling) [🔥 Must Know]

```sql
-- Approach 1: Pessimistic locking (simple, lower throughput)
BEGIN;
SELECT stock FROM products WHERE id = 123 FOR UPDATE; -- lock row
-- Check: stock >= requested_quantity
UPDATE products SET stock = stock - 1 WHERE id = 123;
COMMIT;

-- Approach 2: Optimistic locking with version (higher throughput)
UPDATE products SET stock = stock - 1, version = version + 1
WHERE id = 123 AND stock >= 1 AND version = 5;
-- If affected_rows = 0 → conflict, retry

-- Approach 3: Redis atomic decrement (for flash sales)
DECR inventory:product:123
-- If result < 0 → out of stock, INCR to restore, reject order
-- Fast (Redis), but need to sync with DB eventually
```

**Flash sale handling:**
```
Normal: 25 QPS orders → PostgreSQL handles fine
Flash sale: 25,000 QPS orders for one product → DB can't handle

Solution: Redis as inventory buffer
  1. Pre-load inventory into Redis: SET inventory:product:123 1000
  2. Each order: DECR inventory:product:123 (atomic, 100K ops/sec)
  3. If result >= 0: order accepted, publish to Kafka
  4. If result < 0: INCR to restore, reject order
  5. Kafka consumer: process orders, update DB, call payment
  
  Redis handles the spike. DB processes orders at its own pace via Kafka.
```

### Payment Processing

(Detailed in [problems/payment-system.md](payment-system.md))

Key points for e-commerce context:
- Idempotency key per checkout attempt (prevent double charges on retry)
- Payment state machine: CREATED → PROCESSING → SUCCESS/FAILED
- Support multiple payment methods via Strategy pattern
- PCI compliance: never store raw card numbers, use tokenization

### Order Tracking

```
Order state machine:
  CREATED → PAYMENT_PENDING → PAID → PROCESSING → SHIPPED → DELIVERED
                ↓                                      ↓
              CANCELLED                            RETURNED

Each state transition:
  1. Update order status in DB
  2. Publish event to Kafka (OrderStatusChanged)
  3. Consumers: notification service (email/push), analytics, seller dashboard

Real-time tracking for user:
  Option 1: SSE (Server-Sent Events) — server pushes status updates
  Option 2: Polling every 30 seconds (simpler)
  Option 3: Push notification (mobile)
```

### Data Model

```sql
products (
    id          BIGINT PRIMARY KEY,
    name        VARCHAR(255),
    description TEXT,
    price       DECIMAL(10,2),
    category_id BIGINT,
    seller_id   BIGINT,
    stock       INTEGER,
    version     INTEGER DEFAULT 0,  -- optimistic locking
    created_at  TIMESTAMP
);
-- Index: (category_id), (seller_id), (name) for search fallback

orders (
    id              BIGINT PRIMARY KEY,
    user_id         BIGINT,
    status          VARCHAR(20),
    total_amount    DECIMAL(10,2),
    shipping_address JSONB,
    idempotency_key VARCHAR(64) UNIQUE,
    created_at      TIMESTAMP,
    updated_at      TIMESTAMP
);

order_items (
    id          BIGINT PRIMARY KEY,
    order_id    BIGINT REFERENCES orders(id),
    product_id  BIGINT,
    quantity    INTEGER,
    unit_price  DECIMAL(10,2)  -- price at time of order (not current price)
);

payments (
    id              BIGINT PRIMARY KEY,
    order_id        BIGINT REFERENCES orders(id),
    amount          DECIMAL(10,2),
    method          VARCHAR(20),
    status          VARCHAR(20),
    psp_reference   VARCHAR(255),
    idempotency_key VARCHAR(64) UNIQUE,
    created_at      TIMESTAMP
);
```

## 5. Bottlenecks & Trade-offs

| Bottleneck | Solution |
|-----------|----------|
| Product catalog read load | Redis cache + CDN for images. Elasticsearch for search. |
| Flash sale inventory | Redis atomic decrement as buffer, Kafka for async DB writes |
| Checkout consistency | Saga pattern with orchestrator. Idempotency keys for payment. |
| Search relevance | Elasticsearch with custom scoring (popularity, recency, relevance) |
| Cart persistence | Redis with TTL. Merge guest cart on login. |
| Order status updates | Kafka events → notification service. SSE or push for real-time. |

## 6. Revision Checklist

- [ ] Read path: CDN (images) → Redis (product cache) → PostgreSQL. Elasticsearch for search.
- [ ] Cart: Redis for logged-in users (TTL 7 days), localStorage for guests, merge on login.
- [ ] Checkout: saga pattern (order → inventory reserve → payment → confirm). Orchestrator preferred.
- [ ] Inventory: optimistic locking for normal traffic. Redis DECR for flash sales.
- [ ] Payment: idempotency key, state machine, never store raw card numbers.
- [ ] Order tracking: state machine, Kafka events for status changes, SSE/push for real-time.
- [ ] Flash sale: Redis as inventory buffer → Kafka → DB. Handles 100K+ ops/sec.
- [ ] Price at order time: store unit_price in order_items, not reference current product price.

> 🔗 **See Also:** [02-system-design/problems/payment-system.md](payment-system.md) for payment deep dive. [02-system-design/problems/notification-system.md](notification-system.md) for notification architecture. [06-tech-stack/01-kafka-deep-dive.md](../../06-tech-stack/01-kafka-deep-dive.md) for Kafka event processing.

---

## 9. Interviewer Deep-Dive Questions

1. **"10K users try to buy the last item simultaneously. Walk me through it."**
   → Redis DECR for inventory (atomic, 100K ops/sec). First user: DECR returns 0 → success, publish order to Kafka. Users 2-10K: DECR returns negative → INCR to restore, return "out of stock". Only ONE user gets the item. DB updated async via Kafka consumer.

2. **"Flash sale: 100x normal traffic. What's your strategy?"**
   → (1) Pre-load inventory into Redis. (2) Rate limit at API Gateway (queue excess requests). (3) Static pages served from CDN (product images, descriptions). (4) Separate flash-sale service with its own infra (don't impact normal shopping). (5) Virtual waiting room (queue users, admit in batches).

3. **"User adds item to cart, price changes before checkout. What happens?"**
   → Store `price_at_add_time` in cart. At checkout: compare with current price. If price increased: notify user, ask to confirm. If price decreased: use new (lower) price (good UX). Never silently charge more than what user saw.

4. **"Payment succeeds but inventory reservation fails (race condition). What do you do?"**
   → Saga compensating transaction: refund the payment automatically. Notify user: "Payment refunded — item went out of stock." This is why checkout should reserve inventory BEFORE payment. Order: reserve → pay → confirm. If reserve fails: don't even attempt payment.

5. **"How do you handle cart abandonment recovery?"**
   → Cart persisted in Redis with 7-day TTL. If user doesn't checkout within 1 hour: trigger "abandoned cart" event. Notification service sends email/push: "You left items in your cart!" Include a deep link back to cart. Track conversion rate of recovery emails.

6. **"How does search work for 100M products?"**
   → Elasticsearch cluster. Index: product name, description, category, attributes. Filters: price range, brand, rating, availability. Ranking: relevance score × popularity × recency. Faceted search: show filter counts (e.g., "Nike (234)"). Autocomplete: separate trie or ES prefix query.

## 10. Failure Matrix

| Component Down | Impact | Mitigation |
|---|---|---|
| Redis (inventory) | Can't process flash sale orders | Fall back to DB pessimistic locking (slower but works). |
| Payment PSP | Can't complete checkout | Queue orders, retry when PSP recovers. Show "payment pending" to user. |
| Elasticsearch | Search broken | Fallback: DB query with LIKE (slow but functional). Show "search degraded" banner. |
| Kafka | Order events not processed | Orders saved to DB directly (synchronous fallback). Process events when Kafka recovers. |
