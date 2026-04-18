# System Design — Additional Theory Topics

## 1. CQRS (Command Query Responsibility Segregation) [🔥 Must Know]

**Separate the read model from the write model. Writes go to one store (optimized for writes), reads go to another (optimized for reads).**

```
Traditional (single model):
  Client → Service → PostgreSQL (reads AND writes)
  Problem: read-heavy system (100:1 ratio) — DB optimized for writes struggles with complex reads.

CQRS:
  WRITE: Client → Command Service → PostgreSQL (normalized, ACID)
  READ:  Client → Query Service → Denormalized Read Store (Redis, Elasticsearch, materialized view)
  SYNC:  PostgreSQL → CDC/Kafka → Read Store (eventual consistency)
```

**When to use:**
- Read/write ratio is very skewed (100:1 or more)
- Read and write models have different shapes (normalized for writes, denormalized for reads)
- Need different scaling for reads vs writes

**When NOT to use:**
- Simple CRUD apps (overkill)
- Need strong consistency between read and write (CQRS is eventually consistent)

**Real examples:** News feed (write: insert post, read: pre-computed feed), e-commerce (write: place order, read: product catalog with aggregated reviews).

## 2. Bloom Filters [🔥 Must Know]

**A space-efficient probabilistic data structure that answers "is X in the set?" with either "definitely NO" or "probably YES" (small false positive rate, zero false negatives).**

```
How it works:
  - Bit array of size m, initialized to all 0s
  - k hash functions

  INSERT("hello"):
    hash1("hello") % m = 3  → set bit 3
    hash2("hello") % m = 7  → set bit 7
    hash3("hello") % m = 11 → set bit 11

  LOOKUP("hello"):
    Check bits 3, 7, 11 → all set → "probably yes"

  LOOKUP("world"):
    hash1("world") % m = 3  → set (from "hello")
    hash2("world") % m = 5  → NOT set → "definitely no"

False positive: all k bits happen to be set by OTHER elements → says "yes" but element was never inserted.
False negative: IMPOSSIBLE — if element was inserted, all its bits are set.
```

**Use cases in system design:**
- **Cache**: check bloom filter before querying DB. If "definitely no" → skip DB query (saves 90%+ of negative lookups).
- **Web crawler**: "have I visited this URL?" Bloom filter with billions of URLs in ~1 GB memory.
- **Database**: LSM-tree storage engines (Cassandra, LevelDB) use bloom filters to skip SSTables that don't contain the key.
- **Spam filter**: "is this email address known spam?"

**Trade-offs:** m=10 bits per element, k=7 hash functions → ~1% false positive rate. Increase m for lower false positive rate. Cannot delete elements (use Counting Bloom Filter for that).

## 3. CDN Architecture [🔥 Must Know]

**A CDN (Content Delivery Network) caches content at edge servers close to users, reducing latency and offloading origin servers.**

```
Without CDN:
  User (Mumbai) → Origin (us-east-1): 200ms RTT
  Every request travels across the globe.

With CDN:
  User (Mumbai) → Edge (Mumbai PoP): 5ms RTT (cache hit)
  User (Mumbai) → Edge (Mumbai PoP) → Origin (us-east-1): 200ms (cache miss, first request only)
```

### Push vs Pull CDN

| Type | How | Best For |
|------|-----|----------|
| **Pull (origin pull)** | CDN fetches from origin on first request, caches for TTL | Dynamic content, large catalogs. CloudFront default. |
| **Push (origin push)** | You upload content to CDN proactively | Static assets you control (JS, CSS, images). Known content. |

### Cache Invalidation

```
1. TTL-based: set Cache-Control: max-age=86400 (24 hours). Content auto-expires.
2. Versioned URLs: /app.v2.js — new version = new URL, old cached version ignored.
3. Purge API: CloudFront CreateInvalidation("/*") — force CDN to re-fetch.
4. Stale-while-revalidate: serve stale content while fetching fresh in background.
```

### CDN in System Design Interviews

**Always mention CDN for:**
- Static assets (images, CSS, JS)
- Video streaming (HLS/DASH segments)
- API responses that are cacheable (product pages, public data)
- Geographic distribution (users worldwide)

**Don't use CDN for:**
- Personalized content (user-specific data)
- Real-time data (stock prices, chat messages)
- Write operations

## 4. Load Balancer Algorithms

| Algorithm | How | Best For |
|-----------|-----|----------|
| **Round Robin** | Rotate through servers sequentially | Equal-capacity servers, stateless requests |
| **Weighted Round Robin** | More requests to higher-capacity servers | Mixed server sizes |
| **Least Connections** | Route to server with fewest active connections | Variable request duration (some fast, some slow) |
| **IP Hash** | Hash client IP → always same server | Session affinity (sticky sessions) |
| **Consistent Hashing** | Hash-ring based routing | Cache servers (minimize redistribution on add/remove) |

**Interview default:** "I'd use an ALB with least-connections routing" covers most cases.

## 5. Consistent Hashing Deep-Dive

```
Problem: hash(key) % N servers. If N changes (add/remove server), ALL keys remap.
  With 100M keys and 10 servers: adding 1 server remaps ~90M keys. Cache stampede.

Consistent hashing: only K/N keys remap (K = total keys, N = servers).
  - Servers and keys mapped to a ring (0 to 2^32)
  - Key is assigned to the NEXT server clockwise on the ring
  - Adding a server: only keys between new server and its predecessor remap

Virtual nodes: each physical server gets 100-200 positions on the ring.
  Without virtual nodes: uneven distribution (some servers get more keys).
  With virtual nodes: even distribution (law of large numbers).

Used in: DynamoDB, Cassandra, Memcached, CDN routing, load balancing.
```

## Revision Checklist

- [ ] CQRS: separate read/write models, sync via CDC/Kafka, eventually consistent
- [ ] Bloom filter: "definitely no" or "probably yes", no false negatives, used in caches/crawlers/DBs
- [ ] CDN: pull (on-demand) vs push (proactive), TTL + versioned URLs for invalidation
- [ ] LB algorithms: round robin (default), least connections (variable duration), consistent hashing (caches)
- [ ] Consistent hashing: only K/N keys remap on server change, virtual nodes for even distribution
