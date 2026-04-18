# System Design — Prerequisites

## 1. Prerequisites
- Basic understanding of client-server architecture
- Familiarity with HTTP, REST APIs, databases
- This document builds the vocabulary needed for all subsequent system design docs

💡 **How to use this document:** This is the foundation for everything in the system design section. Every concept here will be referenced in the design problems. Read this first, then revisit specific sections when they come up in problem discussions.

> 🔗 **Dependencies:** This document is self-contained. All other system design docs reference concepts from here.

## 2. Core Concepts

### What Happens When You Type a URL [🔥 Must Know]

**This is the single most common "warm-up" question in system design interviews. It tests whether you understand the full stack from browser to database and back.**

1. **Browser checks caches:** Browser cache → OS cache → router cache → ISP DNS cache
2. **DNS resolution:** Domain name → IP address (recursive lookup through DNS hierarchy: local → root → TLD → authoritative)
3. **TCP handshake:** SYN → SYN-ACK → ACK (three-way handshake establishes reliable connection)
4. **TLS handshake** (if HTTPS): Certificate exchange, key negotiation, symmetric key established
5. **HTTP request** sent to server IP (GET /index.html HTTP/1.1)
6. **Load balancer** routes request to one of many application servers
7. **App server** processes request: authentication, business logic, queries database/cache
8. **Response** travels back through the same path (HTTP response with HTML/JSON)
9. **Browser renders** HTML, fetches CSS/JS/images (each may trigger new requests)

```
Full request flow:

Browser → [DNS] → IP address
       → [TCP 3-way handshake] → Connection established
       → [TLS handshake] → Encrypted channel
       → [HTTP Request] → Load Balancer → App Server → Cache/DB
       ← [HTTP Response] ← App Server ← Cache/DB
       → [Render] → Display page

Each step adds latency:
  DNS:     ~10-50ms (cached: 0ms)
  TCP:     ~1 RTT (0.5ms same DC, 40ms cross-region)
  TLS:     ~1-2 RTT additional
  Server:  ~10-200ms (depends on complexity)
  Total:   ~50-500ms for a typical page load
```

💡 **Intuition — Why this matters for system design:** Every component in this flow is a potential bottleneck and a design decision. DNS → how do you handle failover? Load balancer → how do you distribute traffic? Cache → what do you cache and for how long? Database → SQL or NoSQL? Each system design problem is about optimizing parts of this flow for specific requirements.

🎯 **Likely Follow-ups:**
- **Q:** What happens if the DNS server is down?
  **A:** The browser falls back to cached DNS entries (TTL-based). If no cache, the request fails. This is why DNS has multiple levels of redundancy (multiple authoritative servers, anycast routing).
- **Q:** Why is HTTPS slower than HTTP?
  **A:** The TLS handshake adds 1-2 round trips for key exchange. TLS 1.3 reduced this to 1 RTT (and 0 RTT for resumed connections). The encryption/decryption overhead is negligible on modern hardware.
- **Q:** How does keep-alive affect this?
  **A:** HTTP keep-alive reuses the TCP connection for multiple requests, avoiding the TCP+TLS handshake overhead for subsequent requests. HTTP/2 goes further with multiplexing (multiple requests over one connection).

### Latency Numbers Every Programmer Should Know [🔥 Must Know]

**These numbers are the foundation of back-of-the-envelope estimation. Memorize the orders of magnitude, not exact values.**

| Operation | Latency | Scale | Notes |
|-----------|---------|-------|-------|
| L1 cache reference | 0.5 ns | nanoseconds | CPU register-adjacent |
| L2 cache reference | 7 ns | nanoseconds | On-chip cache |
| Main memory reference | 100 ns | nanoseconds | RAM access |
| SSD random read | 150 μs | microseconds | ~1000x slower than RAM |
| HDD random read | 10 ms | milliseconds | ~100x slower than SSD |
| Send 1 KB over 1 Gbps network | 10 μs | microseconds | Network I/O |
| Round trip within same datacenter | 0.5 ms | milliseconds | Very fast |
| Round trip US East → West | 40 ms | milliseconds | Speed of light limit |
| Round trip US → Europe | 80 ms | milliseconds | Transatlantic |
| Round trip US → Asia | 150 ms | milliseconds | Transpacific |
| Read 1 MB sequentially from memory | 250 μs | microseconds | |
| Read 1 MB sequentially from SSD | 1 ms | milliseconds | |
| Read 1 MB sequentially from HDD | 20 ms | milliseconds | |
| Disk seek | 10 ms | milliseconds | Mechanical movement |

💡 **Intuition — The Memory Hierarchy:**
```
Speed:    CPU registers > L1 > L2 > L3 > RAM > SSD > HDD > Network > Cross-region
Capacity: CPU registers < L1 < L2 < L3 < RAM < SSD < HDD
Cost:     CPU registers > ... > RAM ($5/GB) > SSD ($0.10/GB) > HDD ($0.02/GB)

The fundamental trade-off: faster storage is smaller and more expensive.
Caching exploits this: keep hot data in fast storage, cold data in cheap storage.
```

**Key takeaways for estimation:**
- Memory is ~1000x faster than SSD, SSD is ~100x faster than HDD
- Network within datacenter is fast (0.5ms), cross-region is slow (40-150ms)
- Sequential reads are MUCH faster than random reads (especially on HDD: 20ms vs 10ms per seek)
- Caching is critical — even one cache miss to disk is 10ms (that's 100,000 L1 cache references)
- For n = 10⁵ users, if each request takes 10ms DB time, you need 10⁵ × 10ms = 1000 seconds of DB time per second → you need caching or read replicas

⚙️ **Under the Hood — Why These Numbers Matter in Interviews:**
When an interviewer asks "how would you handle 10,000 requests per second?", you need to know:
- A single DB query takes ~5-10ms → one DB server handles ~100-200 QPS
- A Redis cache lookup takes ~0.1-1ms → one Redis server handles ~100,000 QPS
- So for 10K QPS: you need caching (Redis handles it easily) or ~50-100 DB read replicas (expensive)

🎯 **Likely Follow-ups:**
- **Q:** Why is sequential I/O so much faster than random I/O on HDD?
  **A:** HDD has a mechanical arm that must physically move to the right track (seek time ~10ms). Sequential reads avoid seeking — the arm stays in place and reads consecutive sectors. SSD has no mechanical parts, so the gap is smaller but still exists (due to page-level reads and internal parallelism).
- **Q:** How do these numbers affect database design?
  **A:** B+ trees minimize disk seeks (each level is one seek, 3-4 levels for billions of rows). LSM trees (used in Cassandra, RocksDB) convert random writes to sequential writes. Both exploit the sequential vs random I/O gap.

> 🔗 **See Also:** [02-system-design/05-estimation-math.md](05-estimation-math.md) for how to use these numbers in back-of-the-envelope calculations. [07-cs-fundamentals/03-database-internals.md](../07-cs-fundamentals/03-database-internals.md) for how databases optimize for these latencies.

### Throughput & Bandwidth

**Throughput is how much work gets done per second. Bandwidth is the maximum theoretical capacity. Latency is how long one unit of work takes.**

- **Throughput:** Actual data transferred per second (requests/sec, MB/sec)
- **Bandwidth:** Maximum theoretical capacity of a link
- **Latency:** Time for a single request to complete

💡 **Intuition — The Highway Analogy:**
- **Bandwidth** = number of lanes on the highway (capacity)
- **Throughput** = actual cars passing per hour (utilization)
- **Latency** = time for one car to travel from A to B

A 10-lane highway (high bandwidth) with a traffic jam has low throughput. A single-lane highway with no traffic has low bandwidth but low latency. You can have high throughput + high latency (batch processing: send a truck full of hard drives).

**Key relationships:**
- Throughput ≤ bandwidth (can't exceed capacity)
- Throughput ≠ 1/latency (pipelining allows multiple requests in flight)
- High throughput + high latency is possible (batch processing, pipelining)
- Low latency doesn't guarantee high throughput (if you can only handle one request at a time)

### Availability & Reliability [🔥 Must Know]

**Availability is the percentage of time a system is operational. It's measured in "nines" — each additional nine is 10x harder to achieve.**

**Availability** = uptime / (uptime + downtime)

| Nines | Availability | Downtime/year | Downtime/month | Typical Use |
|-------|-------------|---------------|----------------|-------------|
| 2 nines | 99% | 3.65 days | 7.3 hours | Internal tools |
| 3 nines | 99.9% | 8.76 hours | 43.8 min | Standard web apps |
| 4 nines | 99.99% | 52.6 min | 4.38 min | E-commerce, payments |
| 5 nines | 99.999% | 5.26 min | 26.3 sec | Financial systems, telecom |

**SLA (Service Level Agreement):** Contractual availability guarantee. Most services target 99.9% (three nines) to 99.99% (four nines). Going from 99.9% to 99.99% is 10x harder and more expensive.

⚙️ **Under the Hood — Calculating System Availability:**

**Components in series** (all must work): `A_total = A1 × A2 × A3`
```
Client → Load Balancer (99.99%) → App Server (99.9%) → Database (99.9%)
A_total = 0.9999 × 0.999 × 0.999 = 0.9979 ≈ 99.79%

Each component in the chain REDUCES overall availability.
```

**Components in parallel** (any one works): `A_total = 1 - (1-A1)(1-A2)`
```
Two app servers, each 99.9%:
A_total = 1 - (1-0.999)(1-0.999) = 1 - 0.001² = 1 - 0.000001 = 99.9999%

Redundancy INCREASES availability dramatically.
```

💡 **Intuition:** Series is like a chain — it's only as strong as the weakest link. Parallel is like having backup generators — the system only fails if ALL backups fail simultaneously.

**Reliability vs Availability:**
- **Reliability** = probability of no failure over time (MTBF — Mean Time Between Failures)
- **Availability** = uptime percentage
- A system can be available but not reliable: it crashes every hour but recovers in 1 second (high availability, low reliability)
- A reliable system is usually available, but not always (planned maintenance reduces availability)

🎯 **Likely Follow-ups:**
- **Q:** How do you achieve 99.99% availability?
  **A:** Redundancy at every layer: multiple app servers behind a load balancer, database replication (primary + replicas), multi-AZ deployment, automated failover, health checks, circuit breakers. No single point of failure.
- **Q:** What's the difference between high availability and disaster recovery?
  **A:** HA handles routine failures (server crash, network blip) with automatic failover, typically within the same region. DR handles catastrophic failures (entire datacenter down, natural disaster) with cross-region replication and manual/automated region failover.

### Scalability [🔥 Must Know]

**Scalability is the ability to handle increased load by adding resources. Vertical scaling = bigger machine. Horizontal scaling = more machines.**

**Vertical scaling (scale up):** Bigger machine — more CPU, RAM, disk.
- Pros: Simple, no code changes, no distributed complexity
- Cons: Hardware limits (can't buy a 1TB RAM server easily), single point of failure, expensive at high end
- Example: Upgrading a database server from 32GB to 256GB RAM

**Horizontal scaling (scale out):** More machines.
- Pros: No hardware limit, fault tolerant (one machine dies, others continue), cost-effective (commodity hardware)
- Cons: Complexity (distributed state, consistency, load balancing, network partitions)
- Example: Adding more web servers behind a load balancer

| Aspect | Vertical | Horizontal |
|--------|----------|------------|
| Complexity | Low | High |
| Cost curve | Exponential (high-end hardware) | Linear (commodity hardware) |
| Fault tolerance | None (SPOF) | Built-in (redundancy) |
| Limit | Hardware ceiling | Theoretically unlimited |
| State management | Simple (one machine) | Complex (distributed) |

**When to scale vertically:** Database (initially — sharding is complex), cache server (Redis can handle a lot on one machine), simple apps with low traffic
**When to scale horizontally:** Stateless web servers, microservices, read-heavy workloads (read replicas), any system that needs fault tolerance

💡 **Intuition — The Restaurant Analogy:**
- **Vertical scaling:** Hire a faster chef (limits: even the best chef can only cook so fast)
- **Horizontal scaling:** Hire more chefs (complexity: they need to coordinate, share the kitchen, avoid stepping on each other)

Most real systems use BOTH: scale the database vertically as long as possible (simpler), scale the application tier horizontally from the start (stateless servers are easy to replicate).

### Load Balancing [🔥 Must Know]

**A load balancer distributes incoming traffic across multiple servers, preventing any single server from becoming a bottleneck and providing fault tolerance.**

**Where load balancers sit:**
```
Client → DNS → Load Balancer → Web Servers → App Servers → Database
                                    ↓
                              Cache Layer (Redis)

Multiple LB layers possible:
  External LB (L7): routes client traffic to web servers
  Internal LB (L4): routes between microservices
```

**Algorithms:**

| Algorithm | How It Works | Best For | Drawback |
|-----------|-------------|----------|----------|
| Round Robin | Rotate through servers sequentially | Equal-capacity servers | Ignores server load |
| Weighted Round Robin | More traffic to higher-capacity servers | Mixed-capacity servers | Static weights |
| Least Connections | Route to server with fewest active connections | Variable request duration | Slightly more overhead |
| IP Hash | Hash client IP to determine server | Session affinity (sticky sessions) | Uneven if IP distribution skewed |
| Consistent Hashing | Hash-ring based distribution | Distributed caches | More complex |

**Layer 4 vs Layer 7** [🔥 Must Know]:

| Feature | L4 (Transport) | L7 (Application) |
|---------|----------------|-------------------|
| Routes based on | IP address, port, TCP/UDP | HTTP headers, URL path, cookies, body |
| Speed | Faster (less processing) | Slower (must parse HTTP) |
| Flexibility | Limited | Can route /api to one cluster, /static to another |
| SSL termination | No | Yes (decrypt at LB, forward plain HTTP internally) |
| Examples | AWS NLB, HAProxy (TCP mode) | AWS ALB, Nginx, HAProxy (HTTP mode) |

💡 **Intuition — L4 vs L7:** L4 is like a mail sorter who only reads the address on the envelope (IP/port). L7 is like a mail sorter who opens the envelope and reads the letter (HTTP content) to decide where to route it. L7 is slower but can make smarter decisions.

**Health checks:** Load balancer periodically pings servers (HTTP GET /health). Unhealthy servers are removed from rotation. When they recover, they're added back.

⚙️ **Under the Hood — SSL Termination:**
Decrypting HTTPS is CPU-intensive. SSL termination at the load balancer means the LB handles encryption/decryption, and internal traffic between LB and app servers is plain HTTP. This offloads crypto work from app servers and simplifies certificate management (one cert at the LB instead of one per server).

🎯 **Likely Follow-ups:**
- **Q:** What happens if the load balancer itself goes down?
  **A:** Use redundant load balancers in active-passive or active-active configuration. DNS-based failover or floating IP (VRRP) switches traffic to the backup LB. Cloud providers (AWS ALB/NLB) handle this automatically.
- **Q:** How do you handle sticky sessions?
  **A:** IP hash or cookie-based routing. But sticky sessions reduce the benefit of load balancing (one server gets all requests from one user). Better approach: make servers stateless and store session data in Redis.
- **Q:** What's the difference between AWS ALB and NLB?
  **A:** ALB is L7 (HTTP/HTTPS routing, path-based routing, host-based routing). NLB is L4 (TCP/UDP, ultra-low latency, static IP). Use ALB for web apps, NLB for non-HTTP protocols or extreme performance needs.

### Caching [🔥 Must Know]

**Caching stores frequently accessed data in fast storage (memory) to reduce latency and database load. It's the single most impactful optimization in system design.**

**Why cache:** A Redis cache lookup takes ~0.1ms. A database query takes ~5-10ms. That's 50-100x faster. For read-heavy workloads (which most systems are), caching can reduce DB load by 80-90%.

**Cache levels:**
```
Client → [Browser Cache] → [CDN] → [Load Balancer] → [App Cache (Redis)] → [DB Cache (Buffer Pool)] → [Disk]
         fastest, smallest                                                              slowest, largest
```

1. **Client-side:** Browser cache (HTTP headers: Cache-Control, ETag), mobile app cache
2. **CDN:** Geographically distributed cache for static content
3. **Application-level:** In-memory (local HashMap — fast but not shared), distributed cache (Redis, Memcached — shared across servers)
4. **Database-level:** Query cache (MySQL), buffer pool (InnoDB), materialized views

**Caching strategies** [🔥 Must Know]:

| Strategy | How It Works | Consistency | Best For |
|----------|-------------|-------------|----------|
| Cache-Aside (Lazy Loading) | App checks cache → miss → read DB → populate cache. App writes to DB, invalidates/updates cache. | Eventual | Most common. Read-heavy workloads. |
| Read-Through | Cache itself handles DB read on miss (cache library manages it) | Eventual | Simplifies app code |
| Write-Through | Write to cache AND DB synchronously (both must succeed) | Strong | When consistency is critical |
| Write-Behind (Write-Back) | Write to cache only, async batch write to DB later | Eventual | High write throughput (risk: data loss if cache crashes before flush) |
| Write-Around | Write directly to DB, skip cache entirely | Eventual | Write-once, read-rarely data |

```
Cache-Aside flow (most common):

READ:
  App → Cache: "Do you have key X?"
  Cache → App: "No (miss)"
  App → DB: "Give me key X"
  DB → App: data
  App → Cache: "Store key X = data"
  App → Client: data

WRITE:
  App → DB: "Update key X"
  App → Cache: "Delete key X" (invalidate)
  Next read will be a cache miss → fresh data loaded from DB
```

💡 **Intuition — Why Cache-Aside is Most Common:** It's simple, the app has full control, and it naturally handles the "cold start" problem (cache fills up organically as data is requested). The downside: the first request for any data is always slow (cache miss).

**Cache eviction policies:**
- **LRU (Least Recently Used):** Evict the item not accessed for the longest time. Most common. Good for temporal locality.
- **LFU (Least Frequently Used):** Evict the item accessed the fewest times. Good for frequency-based access patterns.
- **FIFO:** Evict the oldest item. Simple but doesn't consider access patterns.
- **TTL (Time To Live):** Expire after a fixed duration. Used alongside other policies.

**Cache invalidation** — "the two hardest problems in CS are cache invalidation, naming things, and off-by-one errors":
- **TTL-based:** Simple but stale data for up to TTL duration. Set TTL based on how stale you can tolerate.
- **Event-based:** Invalidate on write. More complex but fresher data. Requires pub/sub or change data capture.
- **Versioning:** Include version in cache key (`user:123:v5`). New version = cache miss = fresh data.

💥 **What Can Go Wrong — Cache Failure Modes:**

| Problem | What Happens | Solution |
|---------|-------------|----------|
| Thundering herd | Cache expires → thousands of requests hit DB simultaneously | Lock/mutex on cache miss (only one request fetches from DB), staggered TTLs, pre-warming |
| Cache penetration | Requests for non-existent keys always miss cache and hit DB | Cache null results with short TTL, Bloom filter to reject impossible keys |
| Cache avalanche | Many keys expire at the same time → massive DB load | Randomize TTLs (add jitter), pre-warm cache before expiry |
| Hot key | One key gets extreme traffic → single cache node overloaded | Replicate hot keys across multiple nodes, local in-memory cache for hottest keys |
| Cache inconsistency | Cache has stale data after DB update | Use cache-aside with invalidation, or write-through for strong consistency |

🎯 **Likely Follow-ups:**
- **Q:** Redis vs Memcached?
  **A:** Redis: richer data structures (strings, lists, sets, sorted sets, hashes), persistence (RDB/AOF), replication, Lua scripting. Memcached: simpler, multi-threaded (better for pure key-value caching with many cores), no persistence. Default choice: Redis (more versatile).
- **Q:** How do you handle cache warming?
  **A:** Pre-populate the cache before traffic hits. Options: (1) Run a script that queries the most popular keys. (2) Use a "shadow" cache that mirrors production traffic. (3) Gradually shift traffic to new servers (canary deployment).
- **Q:** What's the difference between local cache and distributed cache?
  **A:** Local cache (HashMap, Caffeine) is per-server — fast (no network hop) but not shared (each server has its own copy, wastes memory, inconsistency risk). Distributed cache (Redis) is shared — one copy, consistent, but adds network latency (~0.1-1ms).

> 🔗 **See Also:** [06-tech-stack/02-redis-deep-dive.md](../06-tech-stack/02-redis-deep-dive.md) for Redis internals. [04-lld/problems/cache-lru-lfu.md](../04-lld/problems/cache-lru-lfu.md) for LRU/LFU cache implementation. [02-system-design/problems/distributed-cache.md](problems/distributed-cache.md) for distributed cache system design.

### CDN (Content Delivery Network)

**A CDN is a network of geographically distributed servers that cache static content close to users, reducing latency from 100-200ms (cross-region) to 10-30ms (local edge server).**

**Push CDN:** Origin pushes content to CDN proactively. Good for static content that changes infrequently (company logos, CSS frameworks).
**Pull CDN:** CDN fetches from origin on first request, caches it. Good for content with unpredictable popularity (user-uploaded images, blog posts).

| Type | Pros | Cons | Best For |
|------|------|------|----------|
| Push | Content always available, no origin hit | Must manage uploads, storage cost | Known static content |
| Pull | Automatic, no management needed | First request is slow (cache miss) | Dynamic/unpredictable content |

**When to use CDN:** Static assets (images, CSS, JS, videos), any content served to geographically distributed users.
**When NOT to use:** Dynamic, personalized content (user dashboards), content that changes every request, single-region users.

### Proxies

**Forward proxy:** Sits between client and internet. Client knows about it. Used for: anonymity, caching, access control, corporate firewalls.
**Reverse proxy:** Sits between internet and servers. Client doesn't know about it. Used for: load balancing, SSL termination, caching, security, rate limiting.

```
Forward proxy:  Client → [Forward Proxy] → Internet → Server
                (client configured to use proxy)

Reverse proxy:  Client → Internet → [Reverse Proxy] → Server
                (client thinks proxy IS the server)
```

**Nginx, HAProxy, Envoy** are common reverse proxies. In system design, when you say "load balancer," you usually mean a reverse proxy with load balancing capabilities.

### Consistent Hashing [🔥 Must Know]

**Consistent hashing distributes keys across servers using a hash ring, so that adding or removing a server only remaps ~K/N keys (instead of almost all keys with simple modulo hashing).**

**Problem with simple hashing:** `server = hash(key) % N`. When N changes (server added/removed), almost ALL keys get remapped → massive cache miss storm.

**Solution — Hash Ring:**

```
Simple hashing: hash(key) % 3 → server 0, 1, or 2
  Add server 3: hash(key) % 4 → almost ALL keys move to different servers!

Consistent hashing: map servers and keys onto a ring [0, 2^32)
  Key assigned to first server clockwise from its position.
  Add server S4: only keys between S4 and its predecessor move to S4.
  ~K/N keys remapped (K = total keys, N = servers).

Ring visualization:
        0
       / \
     S1    S4 (new)
    /        \
  K1→S1    K2→S4 (was S2, now closer to S4)
  /            \
S3              S2
  \            /
   K3→S3    K4→S2
```

**Virtual nodes:** Each physical server gets multiple positions on the ring (e.g., S1 gets S1-v1, S1-v2, ..., S1-v100). This ensures even distribution — without virtual nodes, servers can end up with very unequal key ranges.

**Used in:** Distributed caches (Memcached), distributed databases (Cassandra, DynamoDB), load balancers, content delivery.

⚙️ **Under the Hood — Why Virtual Nodes Fix Uneven Distribution:**
With 3 physical servers on a ring, one server might own 60% of the key space by chance. With 100 virtual nodes per server (300 total points on the ring), the law of large numbers ensures each server owns ~33% ± a small variance.

🎯 **Likely Follow-ups:**
- **Q:** How many virtual nodes should you use?
  **A:** Typically 100-200 per physical server. More virtual nodes = more even distribution but more memory for the ring. The sweet spot depends on the number of physical servers and acceptable variance.
- **Q:** What happens during a server failure with consistent hashing?
  **A:** The failed server's keys are redistributed to the next server clockwise on the ring. Only ~K/N keys are affected. With virtual nodes, these keys are spread across multiple servers (not all dumped on one), preventing a cascade.

> 🔗 **See Also:** [02-system-design/problems/distributed-cache.md](problems/distributed-cache.md) for consistent hashing in distributed cache design. [06-tech-stack/02-redis-deep-dive.md](../06-tech-stack/02-redis-deep-dive.md) for Redis Cluster's hash slot approach (an alternative to consistent hashing).

### Databases — Quick Overview

(Detailed in [02-system-design/02-database-choices.md](02-database-choices.md))

**SQL (Relational):** MySQL, PostgreSQL, Oracle
- Structured data, ACID transactions, joins, strong consistency
- Vertical scaling primarily, read replicas for horizontal reads
- Best for: financial data, user accounts, anything needing transactions

**NoSQL:**

| Type | Examples | Data Model | Best For |
|------|---------|------------|----------|
| Key-Value | Redis, DynamoDB | Simple key→value pairs | Caching, session storage, simple lookups |
| Document | MongoDB, CouchDB | JSON-like documents, flexible schema | Content management, user profiles, catalogs |
| Wide-Column | Cassandra, HBase | Rows with dynamic columns | Time-series, IoT, high write throughput |
| Graph | Neo4j, Amazon Neptune | Nodes + edges + properties | Social networks, recommendations, fraud detection |

💡 **Quick Decision Framework:**
- Need ACID transactions? → SQL
- Need flexible schema? → Document DB
- Need extreme write throughput? → Wide-column
- Need relationship traversal? → Graph DB
- Need simple fast lookups? → Key-Value

> 🔗 **See Also:** [02-system-design/02-database-choices.md](02-database-choices.md) for detailed database comparison and selection criteria.

### Communication Protocols [🔥 Must Know]

| Protocol | Type | Use Case | Latency | Direction |
|----------|------|----------|---------|-----------|
| HTTP/REST | Request-response | CRUD APIs, web services | Medium | Client → Server |
| WebSocket | Full-duplex, persistent | Chat, real-time updates, gaming | Low | Bidirectional |
| gRPC | RPC, binary (protobuf) | Microservice-to-microservice | Low | Bidirectional (streaming) |
| Server-Sent Events (SSE) | Server push | Notifications, live feeds | Low | Server → Client only |
| Long Polling | Client polls, server holds | Fallback for WebSocket | Medium | Client-initiated |

**REST vs gRPC** [🔥 Must Know]:

| Feature | REST | gRPC |
|---------|------|------|
| Format | JSON (text, human-readable) | Protobuf (binary, compact) |
| Speed | Slower (text parsing) | Faster (binary serialization) |
| Typing | Loosely typed | Strongly typed (proto schema) |
| Streaming | No native support | Bidirectional streaming |
| Browser support | Native | Requires gRPC-Web proxy |
| Best for | Public APIs, web clients | Internal microservices |

**WebSocket vs SSE vs Long Polling:**

| Feature | WebSocket | SSE | Long Polling |
|---------|-----------|-----|-------------|
| Direction | Bidirectional | Server → Client | Client-initiated |
| Connection | Persistent | Persistent | Repeated HTTP |
| Overhead | Low (after handshake) | Low | High (new connection each time) |
| Best for | Chat, gaming, collaboration | Notifications, live feeds | Fallback when WebSocket unavailable |

💡 **Intuition — When to use what:**
- **REST:** Default for any API. Client asks, server responds.
- **WebSocket:** When both sides need to send messages anytime (chat, multiplayer games).
- **SSE:** When only the server needs to push updates (stock prices, notifications).
- **gRPC:** When microservices talk to each other and you need speed + type safety.

🎯 **Likely Follow-ups:**
- **Q:** Why not use WebSocket for everything?
  **A:** WebSocket connections are stateful and persistent — they consume server resources (memory, file descriptors) even when idle. For simple request-response patterns, REST is simpler and more scalable (stateless, cacheable). Use WebSocket only when you need real-time bidirectional communication.
- **Q:** How does gRPC handle backward compatibility?
  **A:** Protobuf supports field numbering — you can add new fields without breaking old clients (they ignore unknown fields). Removing fields requires marking them as `reserved`. This is more structured than JSON's ad-hoc evolution.

### Microservices vs Monolith

| Aspect | Monolith | Microservices |
|--------|----------|---------------|
| Deployment | Single unit | Independent services |
| Scaling | Scale entire app | Scale individual services |
| Development | Simpler initially | Complex (service discovery, networking) |
| Data | Shared database | Database per service |
| Failure | One bug can crash everything | Isolated failures (with circuit breakers) |
| Team structure | One team, one codebase | Multiple teams, multiple codebases |
| Best for | Small teams, MVPs, startups | Large teams, complex domains, high scale |

💡 **Intuition — The Monolith-First Approach:** Most successful companies started as monoliths and migrated to microservices as they grew. Amazon, Netflix, and Uber all started monolithic. The complexity of microservices (distributed transactions, service mesh, observability) is only worth it when you have the team size and scale to justify it. "Don't start with microservices" is common advice.

**When to migrate from monolith to microservices:**
- Team is too large to work on one codebase (> 10-15 engineers)
- Different parts of the system have different scaling needs
- Deployment of one feature blocks deployment of others
- You need independent technology choices per service

> 🔗 **See Also:** [06-tech-stack/04-spring-boot.md](../06-tech-stack/04-spring-boot.md) for building microservices with Spring Boot. [06-tech-stack/01-kafka-deep-dive.md](../06-tech-stack/01-kafka-deep-dive.md) for event-driven communication between microservices.

## 3. Comparison Tables

| Concept | When to Use | When NOT to Use |
|---------|------------|-----------------|
| Caching | Read-heavy, repeated queries, latency-sensitive | Write-heavy with strong consistency needs |
| CDN | Static content, global users | Dynamic/personalized content, single region |
| Load Balancer | Multiple servers, high traffic | Single server, low traffic |
| Horizontal scaling | Stateless services, read-heavy | Stateful services (harder), small scale |
| Consistent hashing | Distributed cache/DB, dynamic cluster | Small, fixed cluster |
| WebSocket | Real-time bidirectional (chat, gaming) | Simple request-response |
| gRPC | Internal microservices, high throughput | Public APIs (use REST), browser clients |
| Microservices | Large teams, complex domains, independent scaling | Small teams, MVPs, simple domains |

## 4. How This Shows Up in Interviews

**What SDE-2 candidates are expected to know:**
- All concepts in this document at a conversational level — not just definitions, but trade-offs
- Able to make trade-off decisions and justify them (SQL vs NoSQL, cache-aside vs write-through, REST vs gRPC)
- Understand latency numbers and use them in back-of-the-envelope estimations
- Know when to use each caching strategy and why
- Understand availability math (series vs parallel, nines)

**Red flags in weak answers:**
- Can't explain what a load balancer does or why you need one
- Doesn't know the difference between SQL and NoSQL (or says "NoSQL is faster" without nuance)
- Can't reason about availability ("what happens when a server goes down?")
- Uses buzzwords without understanding ("just use Kafka" without explaining why Kafka and not SQS)
- Doesn't consider trade-offs ("always use microservices" without discussing complexity)
- Can't estimate (doesn't know that a DB handles ~100-200 QPS, or that Redis handles ~100K QPS)

**Strong answer signals:**
- Discusses trade-offs unprompted ("We could use write-through for consistency, but cache-aside is simpler and sufficient here because...")
- Uses latency numbers to justify decisions ("Cross-region latency is 80ms, so we need a CDN for our European users")
- Considers failure modes ("What if the cache goes down? We need a fallback to the database with circuit breakers")

## 5. Deep Dive Questions

1. [🔥 Must Know] **What happens when you type google.com in a browser?** — Walk through DNS, TCP, TLS, HTTP, server processing, response rendering.
2. [🔥 Must Know] **Explain horizontal vs vertical scaling.** — Trade-offs, when to use each, examples.
3. [🔥 Must Know] **What is consistent hashing and why is it needed?** — Problem with modulo hashing, ring concept, virtual nodes.
4. [🔥 Must Know] **Compare cache-aside vs write-through caching.** — Flow, consistency, use cases.
5. [🔥 Must Know] **What is a CDN and when would you use one?** — Push vs pull, latency reduction, static vs dynamic content.
6. [🔥 Must Know] **Explain L4 vs L7 load balancing.** — What each layer sees, trade-offs, examples.
7. **What is the thundering herd problem and how do you solve it?** — Cache expiry, lock/mutex, staggered TTLs.
8. [🔥 Must Know] **What are the trade-offs between REST and gRPC?** — Format, speed, typing, streaming, browser support.
9. **Explain forward proxy vs reverse proxy.** — Direction, who knows about it, use cases.
10. [🔥 Must Know] **What does "five nines" availability mean? How do you achieve it?** — 99.999%, redundancy, no SPOF.
11. **What is the difference between latency and throughput?** — Highway analogy, can have high throughput + high latency.
12. **How does a load balancer detect unhealthy servers?** — Health checks, removal from rotation, recovery.
13. [🔥 Must Know] **When would you choose microservices over a monolith?** — Team size, scaling needs, deployment independence.
14. **What is cache invalidation and why is it hard?** — Stale data, TTL vs event-based, consistency challenges.
15. **Explain push vs pull CDN.** — Proactive vs reactive, management overhead, first-request latency.
16. **What is the CAP theorem?** — Preview: consistency, availability, partition tolerance. Detailed in [03-distributed-systems/01-cap-theorem-consistency.md](../03-distributed-systems/01-cap-theorem-consistency.md).
17. **How does DNS resolution work?** — Recursive lookup, caching at each level, TTL.
18. **What is SSL/TLS termination at the load balancer?** — Offload crypto, simplify cert management, plain HTTP internally.
19. [🔥 Must Know] **What are virtual nodes in consistent hashing?** — Even distribution, multiple ring positions per server.
20. **How do you handle session management with load balancers?** — Sticky sessions (IP hash, cookies) vs stateless (Redis session store).

## 6. Revision Checklist

**Latency numbers (orders of magnitude):**
- [ ] Memory: ~100ns. SSD: ~150μs. HDD: ~10ms. Same-DC round trip: ~0.5ms. Cross-region: ~40-150ms.
- [ ] Redis lookup: ~0.1-1ms. DB query: ~5-10ms. Redis is 10-100x faster than DB.
- [ ] One DB server handles ~100-200 QPS. One Redis server handles ~100K QPS.

**Availability:**
- [ ] 99.9% = 8.76 hours downtime/year. 99.99% = 52.6 min/year. 99.999% = 5.26 min/year.
- [ ] Series: multiply availabilities. Parallel: 1 - product of failure probabilities.
- [ ] Each additional nine is 10x harder and more expensive.

**Caching:**
- [ ] Cache-aside: app manages cache, most common, read-heavy workloads
- [ ] Write-through: sync write to cache + DB, strong consistency
- [ ] Write-behind: async write to DB, high write throughput, data loss risk
- [ ] Eviction: LRU (most common), LFU, TTL
- [ ] Failure modes: thundering herd, cache penetration, cache avalanche, hot key

**Load balancing:**
- [ ] Algorithms: round robin, weighted RR, least connections, IP hash, consistent hashing
- [ ] L4 (transport): fast, routes by IP/port. L7 (application): flexible, routes by HTTP content.
- [ ] Health checks remove unhealthy servers from rotation.

**Scaling:**
- [ ] Vertical: bigger machine (simple, limited). Horizontal: more machines (complex, unlimited).
- [ ] Stateless services → easy to scale horizontally. Stateful → harder (need shared state).

**Communication:**
- [ ] REST: public APIs, human-readable JSON, request-response
- [ ] gRPC: internal microservices, binary protobuf, bidirectional streaming
- [ ] WebSocket: real-time bidirectional (chat, gaming)
- [ ] SSE: server-to-client push only (notifications, feeds)

**Consistent hashing:**
- [ ] Ring-based, O(K/N) remapping on server change (vs O(K) with modulo)
- [ ] Virtual nodes for even distribution (~100-200 per physical server)
- [ ] Used in: distributed caches, Cassandra, DynamoDB

**Databases (quick reference):**
- [ ] SQL: ACID, joins, strong consistency. NoSQL: flexible schema, horizontal scaling.
- [ ] Key-Value (Redis): caching. Document (MongoDB): flexible schema. Wide-Column (Cassandra): high writes. Graph (Neo4j): relationships.

---

## 📋 Suggested New Documents

### 1. Observability & Monitoring
- **Placement**: `02-system-design/06-observability-monitoring.md`
- **Why needed**: Logging, metrics, tracing, alerting, and dashboards are critical for production systems and frequently discussed in system design interviews ("how would you monitor this system?"). Not covered in any existing file.
- **Key subtopics**: Three pillars (logs, metrics, traces), ELK stack, Prometheus/Grafana, distributed tracing (Jaeger, Zipkin), alerting strategies, SLIs/SLOs/SLAs

### 2. Security Fundamentals for System Design
- **Placement**: `02-system-design/06-security-fundamentals.md`
- **Why needed**: Authentication (OAuth, JWT), authorization (RBAC, ABAC), encryption (at rest, in transit), rate limiting, and DDoS protection come up in every system design interview but aren't covered in a dedicated document.
- **Key subtopics**: OAuth 2.0 / OpenID Connect, JWT tokens, API key management, encryption (TLS, AES), rate limiting algorithms, DDoS mitigation, OWASP top 10
