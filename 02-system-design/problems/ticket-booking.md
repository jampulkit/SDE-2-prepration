# Design: Ticket Booking System

## 1. Problem Statement & Scope

**Design a ticket booking system like BookMyShow, IRCTC, or an airline reservation system that handles seat selection, concurrent bookings, and payment — without double-booking or overselling.**

**Clarifying questions to ask:**
- What are we booking? → Movie tickets / train seats / flights (same core problem)
- Seat selection? → Yes, users pick specific seats
- How many concurrent users? → 10K+ for popular events (IPL, Avengers release)
- Temporary hold? → Yes, hold seat for 10 minutes during payment
- Waitlist? → Out of scope initially

💡 **Why this is critical for Indian company interviews:** IRCTC handles 25M+ bookings/day. BookMyShow handles massive spikes for popular movies. This tests: distributed locking, seat contention, temporary holds, and payment integration under extreme concurrency.

## 2. Requirements

**Functional:**
- Browse events/shows (search, filter by date/city/genre)
- View seat map with real-time availability
- Select seats and temporarily hold them (10-min lock)
- Complete booking with payment
- Cancel booking and release seats
- Booking confirmation (email/SMS)

**Non-functional:**
- No double-booking (two users can't book the same seat)
- Seat hold expires after 10 minutes (release if payment not completed)
- Handle 10K+ concurrent users for popular events
- < 2s for seat selection, < 5s for booking completion
- 99.9% availability

**Estimation:**
```
50M bookings/day (IRCTC scale)
QPS: 50M / 86400 ≈ 580 QPS average. Peak (10 AM Tatkal): ~50K QPS.
  → Need to handle extreme spikes. Redis for seat locking.

Seat map per show: ~300 seats × 100 bytes = 30 KB
Active shows: 100K → 3 GB seat data (fits in Redis)
Booking record: ~1 KB. Storage: 50M × 1 KB × 365 = 18 TB/year
```

## 3. High-Level Design

```
┌──────────┐    ┌───────────┐    ┌─────────────────┐    ┌──────────────┐
│ Client   │───→│ API       │───→│ Booking Service │───→│ Payment      │
│          │    │ Gateway   │    │ (orchestrator)  │    │ Service      │
└──────────┘    │ (rate     │    │                 │    └──────────────┘
                │  limit)   │    │ - Seat locking  │
                └───────────┘    │ - Hold timer    │    ┌──────────────┐
                                 │ - Booking state │───→│ Notification │
                                 └────────┬────────┘    │ Service      │
                                          │             └──────────────┘
                                 ┌────────┴────────┐
                                 │ Redis           │
                                 │ (seat locks,    │
                                 │  hold timers)   │
                                 └────────┬────────┘
                                          │
                                 ┌────────┴────────┐
                                 │ PostgreSQL      │
                                 │ (bookings,      │
                                 │  events, seats) │
                                 └─────────────────┘
```

**API:**
```
GET  /api/v1/events/{id}/shows/{show_id}/seats   → seat map with availability
POST /api/v1/bookings/hold                        → { show_id, seat_ids: ["A1","A2"] }
     Response: { hold_id, expires_at (now + 10 min), status: "HELD" }
POST /api/v1/bookings/confirm                     → { hold_id, payment_details }
     Response: { booking_id, status: "CONFIRMED", seats: [...] }
DELETE /api/v1/bookings/{booking_id}              → cancel and release seats
```

**Data Model:**
```sql
events (id, name, venue_id, date, category)

shows (id, event_id, start_time, end_time)

seats (
    seat_id     VARCHAR(10),       -- "A1", "B12"
    show_id     BIGINT,
    status      VARCHAR(20),       -- AVAILABLE, HELD, BOOKED
    held_by     UUID,              -- hold_id (NULL if available)
    held_until  TIMESTAMP,         -- hold expiry
    booked_by   BIGINT,            -- user_id (NULL if not booked)
    version     INT DEFAULT 0,     -- optimistic locking
    PRIMARY KEY (show_id, seat_id)
)

bookings (
    booking_id      UUID PRIMARY KEY,
    user_id         BIGINT,
    show_id         BIGINT,
    seat_ids        TEXT[],         -- ["A1", "A2"]
    status          VARCHAR(20),    -- HELD, CONFIRMED, CANCELLED, EXPIRED
    total_amount    DECIMAL(10,2),
    payment_id      UUID,
    held_until      TIMESTAMP,
    created_at      TIMESTAMP
)
```

## 4. Deep Dive

### Seat Locking — The Core Problem [🔥 Must Know]

**Two users click "Book" on seat A1 at the same time. Only one should get it.**

```
Option 1: Redis distributed lock (recommended for high concurrency)

  HOLD seat:
    SET seat_lock:{show_id}:{seat_id} {hold_id} NX EX 600
    -- NX: only set if not exists (atomic)
    -- EX 600: auto-expire in 10 minutes
    -- If SET returns OK → seat locked for this user
    -- If SET returns nil → seat already held by someone else

  CONFIRM booking:
    GET seat_lock:{show_id}:{seat_id}
    -- Verify it's still our hold_id (not expired and re-locked by someone else)
    -- If match: update DB (HELD → BOOKED), delete Redis key
    -- If mismatch: hold expired, return error

  RELEASE (cancel or timeout):
    DEL seat_lock:{show_id}:{seat_id}
    -- Redis TTL auto-releases on timeout (no cleanup job needed)

Option 2: DB pessimistic locking (simpler, lower throughput)
  BEGIN;
  SELECT * FROM seats WHERE show_id = ? AND seat_id = 'A1' AND status = 'AVAILABLE' FOR UPDATE;
  UPDATE seats SET status = 'HELD', held_by = ?, held_until = NOW() + INTERVAL '10 min';
  COMMIT;

Option 3: DB optimistic locking (good balance)
  UPDATE seats SET status = 'HELD', held_by = ?, version = version + 1
  WHERE show_id = ? AND seat_id = 'A1' AND status = 'AVAILABLE' AND version = ?;
  -- affected_rows = 0 → someone else got it first → return "seat unavailable"
```

**Why Redis is best for high concurrency:**
- `SET NX EX` is atomic and O(1) — handles 100K+ ops/sec
- Auto-expiry eliminates need for cleanup jobs
- DB pessimistic locking: rows locked during hold period → blocks other queries
- At 50K QPS (Tatkal rush), DB can't handle row-level locks on hot seats

### Booking Flow (Step by Step)

```
1. User selects seats [A1, A2]
2. HOLD phase:
   For each seat: Redis SET seat_lock:{show}:{seat} {hold_id} NX EX 600
   If ANY seat fails: release all already-locked seats → return "some seats unavailable"
   All succeed: create booking record (status=HELD), return hold_id + expiry time

3. User enters payment details (within 10 min)

4. CONFIRM phase:
   Verify all seat locks still belong to this hold_id
   Process payment (call PSP with idempotency key)
   If payment succeeds:
     Update DB: seats → BOOKED, booking → CONFIRMED
     Delete Redis locks (seats are now permanently booked)
     Send confirmation notification
   If payment fails:
     Release all seat locks
     Update booking → PAYMENT_FAILED
     Return seats to AVAILABLE

5. TIMEOUT (10 min, no payment):
   Redis keys auto-expire → seats become available
   Background job: mark booking as EXPIRED in DB
```

### Handling the Tatkal/Flash Rush [🔥 Must Know]

```
Problem: 10 AM Tatkal opening. 100K users hit "book" simultaneously for 500 seats.

Solutions:
1. Virtual waiting room:
   - Queue users before 10 AM
   - At 10 AM, admit in batches (1000 at a time)
   - Each batch gets 30 seconds to select and hold seats
   - Reduces thundering herd from 100K to 1K concurrent

2. Rate limiting at API Gateway:
   - Max 1000 hold requests/sec per show
   - Excess gets 429 with Retry-After header

3. Redis for all seat operations:
   - DB only touched on CONFIRM (after payment)
   - Redis handles the 100K concurrent lock attempts

4. Pre-compute seat availability:
   - Cache seat map in Redis: HSET seats:{show_id} A1 "AVAILABLE" A2 "HELD"
   - Client polls this for real-time updates (or WebSocket push)

5. Separate infrastructure:
   - High-demand events get dedicated Redis + app server instances
   - Don't let Tatkal rush affect normal bookings
```

### Seat Map Real-Time Updates

```
Option 1: Polling (simple)
  Client polls GET /seats every 3 seconds
  Server returns from Redis cache (fast)

Option 2: WebSocket (better UX)
  On seat status change → publish to WebSocket channel for that show
  Client updates seat map in real-time (seat turns red when someone else holds it)

Option 3: SSE (Server-Sent Events)
  One-way push from server. Simpler than WebSocket. Good enough for seat updates.
```

## 5. Interviewer Deep-Dive Questions

1. **"User holds 2 seats, payment fails. How do you release atomically?"**
   → Redis: DEL both keys in a Lua script (atomic). DB: update both seats in one transaction. If Redis DEL fails: keys auto-expire in 10 min anyway (TTL is the safety net).

2. **"What if Redis goes down during the hold phase?"**
   → Fall back to DB optimistic locking (slower but works). Or: Redis Cluster with replicas — if primary fails, replica promotes. Seat locks are short-lived (10 min), so brief Redis downtime is recoverable.

3. **"User opens two browser tabs, holds same seat twice?"**
   → Second hold attempt: Redis SET NX returns nil (key already exists). Return "seat already held by you" if hold_id matches, or "seat unavailable" if different user.

4. **"How do you prevent scalpers from holding all seats and not paying?"**
   → Max seats per user per show (e.g., 6). Short hold timeout (10 min, not 30). CAPTCHA before hold. Rate limit per user_id. Monitor and ban suspicious patterns.

5. **"Show has 300 seats. How do you display real-time availability to 10K users?"**
   → Redis HGETALL for seat map (sub-ms). Cache at CDN with 2-second TTL for the seat map API. WebSocket for real-time updates to users currently on the seat selection page.

6. **"How do you handle partial booking (user wants 4 seats together but only 2 are available)?"**
   → Atomic: either hold ALL requested seats or NONE. Use Redis Lua script to check and lock all seats in one atomic operation. If any seat is unavailable, lock none and return error.

## 6. Failure Matrix

| Component Down | Impact | Mitigation |
|---|---|---|
| Redis | Can't hold seats | Fall back to DB optimistic locking. Slower but functional. |
| PostgreSQL | Can't confirm bookings | Seats held in Redis (still protected). Queue confirmations for when DB recovers. |
| Payment PSP | Can't complete booking | Extend hold by 5 min. Retry payment. If still fails: release seats. |
| API Gateway | No traffic reaches backend | Multiple gateway instances. DNS failover. |

## 7. Revision Checklist

- [ ] Seat locking: Redis `SET NX EX` for atomic lock with auto-expiry
- [ ] Hold timeout: 10 min TTL in Redis, no cleanup job needed
- [ ] Confirm: verify lock ownership → payment → update DB → delete Redis lock
- [ ] Atomicity: hold ALL seats or NONE (Lua script for multi-seat)
- [ ] Flash rush: virtual waiting room, rate limiting, dedicated infra
- [ ] Real-time seat map: Redis HGETALL + WebSocket/SSE push
- [ ] Anti-scalping: max seats per user, CAPTCHA, short hold timeout
- [ ] Fallback: DB optimistic locking if Redis is down
- [ ] Payment failure: release all held seats, return to AVAILABLE
