# System Design — Estimation Math

## 1. Prerequisites
- [01-fundamentals.md](./01-fundamentals.md) — QPS, storage basics
- [00-prerequisites.md](./00-prerequisites.md) — latency numbers

## 2. Core Concepts

**Back-of-the-envelope estimation is the skill of quickly calculating QPS, storage, bandwidth, and server counts to justify architectural decisions. Interviewers don't care about precision — they care that you can reason about scale.**

💡 **Intuition — Why Estimation Matters:** "Design a chat system" is a completely different problem at 1K users vs 1B users. Estimation tells you whether you need 1 server or 1000, whether data fits in memory or needs sharding, whether a single DB handles the load or you need caching. Without estimation, you're designing blind.

### Powers of 2 [🔥 Must Know]

| Power | Value | Approx | Name | Real-World Reference |
|-------|-------|--------|------|---------------------|
| 2¹⁰ | 1,024 | ~1 thousand | 1 KB | A short email |
| 2²⁰ | 1,048,576 | ~1 million | 1 MB | A high-res photo |
| 2³⁰ | ~1.07 billion | ~1 billion | 1 GB | A movie (compressed) |
| 2⁴⁰ | ~1.1 trillion | ~1 trillion | 1 TB | A large database |
| 2⁵⁰ | ~1.1 quadrillion | ~1 quadrillion | 1 PB | Netflix's entire library |

### Time Conversions [🔥 Must Know]

| Period | Seconds | Approximation |
|--------|---------|---------------|
| 1 minute | 60 | ~10² |
| 1 hour | 3,600 | ~3.6 × 10³ |
| 1 day | 86,400 | **≈ 10⁵** (use this!) |
| 1 month | 2.6 × 10⁶ | ~2.5 × 10⁶ |
| 1 year | 3.15 × 10⁷ | **≈ π × 10⁷** (fun mnemonic) |

### QPS Estimation Framework [🔥 Must Know]

```
Daily requests = DAU × actions_per_user_per_day
QPS = daily_requests / 86,400 ≈ daily_requests / 10⁵
Peak QPS = QPS × 2 to 3 (or up to 10 for spiky workloads like flash sales)
```

**Quick mental math cheat sheet:**

| Daily Requests | QPS (÷ 10⁵) | Architecture Implication |
|---------------|-------------|------------------------|
| 1M/day | ~10 QPS | Single server handles this easily |
| 10M/day | ~100 QPS | Single server, maybe add caching |
| 100M/day | ~1,000 QPS | Load balancer + multiple servers + cache |
| 1B/day | ~10,000 QPS | Sharded DB + distributed cache + CDN |
| 10B/day | ~100,000 QPS | Multi-region, custom infrastructure |

**Server capacity reference:**

| Component | Approximate Capacity | Notes |
|-----------|---------------------|-------|
| Single web server | ~1,000-10,000 QPS | Depends on request complexity |
| Single DB (PostgreSQL/MySQL) | ~5,000-10,000 QPS | Simple queries, indexed |
| Single Redis instance | ~100,000 QPS | In-memory, simple operations |
| Single Kafka broker | ~100,000 messages/sec | Depends on message size |
| Single Elasticsearch node | ~5,000-10,000 QPS | Depends on query complexity |

### Storage Estimation Framework

```
Storage per day = daily_writes × size_per_write
Storage for N years = storage_per_day × 365 × N
```

**Common data sizes:**

| Data Type | Size | Notes |
|-----------|------|-------|
| User ID (long) | 8 bytes | 64-bit integer |
| UUID | 16 bytes | 128 bits |
| Timestamp | 8 bytes | Unix epoch (long) |
| Short string (username) | 20-50 bytes | UTF-8 |
| URL | 100-200 bytes | Average URL length ~75 chars |
| Tweet / short message | 200-300 bytes | 280 chars + metadata |
| JSON metadata | 500 bytes - 2 KB | Typical API response |
| Thumbnail image | 10-50 KB | 100×100 pixels |
| Image (compressed JPEG) | 100-500 KB | 1080p photo |
| 1 min video (compressed) | 3-10 MB | 720p H.264 |
| Database row (typical) | 200 bytes - 1 KB | Depends on schema |

### Bandwidth Estimation

```
Bandwidth = QPS × average_response_size

Example: 10,000 QPS × 2 KB response = 20 MB/s = 160 Mbps
```

### Worked Examples

**Example 1: Twitter-like service** [🔥 Must Know]

```
Assumptions:
  - 300M MAU, 50% DAU = 150M DAU
  - Each user: 2 tweets/day (write), 100 feed reads/day (read)
  - Tweet size: 300 bytes (text + metadata)

WRITE QPS:
  150M × 2 / 10⁵ = 3,000 QPS
  Peak: ~10,000 QPS
  → Single DB can handle this (with write-ahead log)

READ QPS:
  150M × 100 / 10⁵ = 150,000 QPS
  Peak: ~450,000 QPS
  → WAY beyond single DB capacity (~5K QPS)
  → Need: Redis cache (100K QPS per instance) + read replicas
  Read:Write ratio ≈ 50:1 → heavily read-heavy

STORAGE (5 years):
  150M × 2 tweets/day × 300 bytes = 90 GB/day
  5 years: 90 GB × 365 × 5 ≈ 164 TB (text only)
  With media (images, videos): 10-100× more → 1.6 PB to 16 PB
  → Need sharding for this volume

CACHE:
  80/20 rule: 20% of tweets get 80% of reads
  Daily read data: 150,000 QPS × 300 bytes × 86,400 = ~3.9 TB/day
  Cache 20%: ~780 GB → need a Redis cluster (multiple nodes)

BANDWIDTH:
  Read: 150,000 QPS × 2 KB (tweet + metadata) = 300 MB/s = 2.4 Gbps
  → Need CDN for media, multiple network links
```

**Example 2: URL Shortener**

```
Assumptions:
  - 100M new URLs/month
  - Read:Write = 100:1
  - URL mapping: 500 bytes (short code + long URL + metadata)

WRITE QPS:
  100M / (30 × 86,400) ≈ 100M / 2.6M ≈ 40 QPS
  Peak: ~100 QPS
  → Single DB handles this easily

READ QPS:
  40 × 100 = 4,000 QPS
  Peak: ~12,000 QPS
  → Single DB might struggle at peak → add Redis cache

STORAGE (10 years):
  100M/month × 12 × 10 = 12B records
  12B × 500 bytes = 6 TB
  → Fits on a few DB servers, but may need sharding for QPS

CACHE (80/20 rule):
  20% of URLs get 80% of traffic
  Daily reads: 4,000 QPS × 86,400 = 345M reads/day
  Unique URLs accessed: ~345M × 0.2 = 69M (20% are hot)
  Cache size: 69M × 500 bytes ≈ 35 GB → fits in a single Redis instance!
```

**Example 3: Chat Application (WhatsApp-like)**

```
Assumptions:
  - 500M DAU
  - Each user sends 40 messages/day
  - Average message: 100 bytes
  - Each user is in 5 group chats with 50 members

WRITE QPS:
  500M × 40 / 10⁵ = 200,000 QPS
  Peak: ~600,000 QPS
  → Very write-heavy! Need Cassandra or sharded DB

STORAGE (5 years):
  500M × 40 × 100 bytes = 2 TB/day
  5 years: 2 TB × 365 × 5 = 3.65 PB
  → Massive storage, need sharding + tiered storage (hot/cold)

CONNECTIONS:
  500M concurrent WebSocket connections
  Each connection: ~10 KB memory
  Total: 500M × 10 KB = 5 TB of memory just for connections
  → Need thousands of servers (each handles ~500K connections)
```

### Estimation Tips for Interviews [🔥 Must Know]

1. **Round aggressively.** 86,400 → 10⁵. 2.6M → 2.5M. Interviewers care about order of magnitude, not precision.
2. **State assumptions clearly.** "I'll assume 100M DAU and 10 actions per user per day."
3. **Use powers of 10.** Everything in millions, billions, KB, MB, GB, TB.
4. **Calculate read:write ratio first.** This drives your architecture (caching, replicas, sharding).
5. **Don't spend more than 5 minutes.** Get ballpark numbers and move on to design.
6. **Connect numbers to decisions.** "At 150K read QPS, a single DB can't handle it, so I'll add a Redis cache."
7. **Know your server capacities.** DB: ~5K QPS. Redis: ~100K QPS. Web server: ~1-10K QPS.

⚙️ **Under the Hood — The 80/20 Rule (Pareto Principle):**
In most systems, 20% of the data accounts for 80% of the traffic. This means:
- Cache the top 20% of data → serve 80% of requests from cache
- Cache size = 20% × daily unique data accessed
- This is why even a small cache has a huge impact on performance

```
Without cache: 100K QPS → all hit DB → DB overloaded
With cache (80% hit rate): 100K QPS → 80K from cache, 20K from DB → DB is fine
Cache hit rate of 80% reduces DB load by 80%!
```

## 3. Comparison Tables

### System Scale Reference

| Scale | DAU | QPS | Storage/year | Architecture |
|-------|-----|-----|-------------|-------------|
| Startup | 10K | ~1 | ~1 GB | Single server, single DB |
| Small | 100K | ~10 | ~10 GB | Single server + DB, maybe cache |
| Medium | 1M | ~100 | ~100 GB | LB + few servers + cache + DB replicas |
| Large | 100M | ~10K | ~10 TB | Sharded DB + Redis cluster + CDN |
| Massive | 1B | ~100K | ~100 TB | Multi-region, custom infra, Kafka |

## 4. How This Shows Up in Interviews

**Interviewer expects you to:**
- Estimate QPS (read and write separately)
- Estimate storage for 5-10 years
- Estimate bandwidth if relevant
- Use these numbers to justify architecture decisions
- Know approximate server capacities

**Example dialogue:**
> "With 100M DAU and 10 reads per user, we're looking at about 10,000 read QPS, peaking at 30,000. A single PostgreSQL instance handles about 5,000 QPS, so we need either read replicas or caching. Redis handles 100K+ QPS, so a single Redis instance can absorb all our read traffic. I'll use cache-aside with a 5-minute TTL."

**Red flags:**
- Can't estimate QPS from DAU
- Doesn't know approximate server capacities
- Doesn't connect numbers to architecture decisions
- Spends too long on estimation (> 5 minutes)

## 5. Deep Dive Questions

1. [🔥 Must Know] **Estimate QPS and storage for a chat app with 50M DAU.** — Messages/day, storage/year, connection count.
2. [🔥 Must Know] **How much cache memory for a URL shortener?** — 80/20 rule, daily unique URLs, cache size.
3. **How many servers for 100K QPS?** — Depends on request complexity, ~10-100 servers.
4. **Estimate bandwidth for a video streaming service.** — Concurrent viewers × bitrate.
5. [🔥 Must Know] **What is the 80/20 rule for caching?** — 20% of data serves 80% of requests.
6. **How many DB shards needed?** — Total QPS / QPS per shard, or total data / data per shard.
7. **Estimate storage for a photo-sharing app (5 years).** — Photos/day × size × 365 × 5.
8. **Throughput vs QPS?** — QPS = requests/sec, throughput = data/sec (QPS × response size).
9. **Peak vs average load?** — Peak = 2-3× average, up to 10× for spiky (flash sales, events).
10. [🔥 Must Know] **Complete estimation for a notification system.** — DAU, notifications/user, QPS, storage, push delivery.

## 6. Revision Checklist

**Time conversions:**
- [ ] 1 day ≈ 10⁵ seconds. 1 month ≈ 2.5 × 10⁶. 1 year ≈ π × 10⁷.

**QPS shortcuts:**
- [ ] 1M/day ≈ 10 QPS. 100M/day ≈ 1,000 QPS. 1B/day ≈ 10,000 QPS.
- [ ] Peak ≈ 2-3× average (up to 10× for spiky workloads).

**Server capacities:**
- [ ] Single DB: ~5,000-10,000 QPS (simple queries). Redis: ~100,000 QPS. Web server: ~1,000-10,000 QPS.

**Storage:**
- [ ] Storage = daily_writes × size × retention_days.
- [ ] Text data: 100-500 bytes/record. Images: 100-500 KB. Video: 3-10 MB/min.

**Caching:**
- [ ] 80/20 rule: cache 20% of data → serve 80% of requests.
- [ ] Cache size = 20% × daily unique data volume.

**Estimation process:**
- [ ] Round aggressively (order of magnitude).
- [ ] State assumptions explicitly.
- [ ] Calculate read:write ratio first → drives architecture.
- [ ] Connect numbers to decisions ("at X QPS, we need Y").
- [ ] Don't spend > 5 minutes.

> 🔗 **See Also:** [02-system-design/00-prerequisites.md](00-prerequisites.md) for latency numbers. [02-system-design/01-fundamentals.md](01-fundamentals.md) for how estimation drives architecture decisions.
