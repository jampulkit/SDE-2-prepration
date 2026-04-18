# Partitioning & Replication

## 1. Prerequisites
- [01-cap-theorem-consistency.md](./01-cap-theorem-consistency.md) — CAP theorem, consistency models, tunable consistency

## 2. Core Concepts

### Replication [🔥 Must Know]

**Replication keeps copies of data on multiple nodes for availability (survive failures), read scalability (distribute reads), and latency (serve from nearest replica).**

💡 **Intuition:** Replication is like having backup copies of important documents. If one copy is destroyed (node failure), you still have others. If many people need to read the document simultaneously, they can each read from a different copy (read scaling). If people are in different cities, they can read from the nearest copy (latency).

**Three replication models:**

**1. Single-leader (most common)** [🔥 Must Know]:

```
Writes: Client → Leader (single writer)
Reads:  Client → Leader OR any Replica

Leader ──async replication──→ Replica 1
                           ──→ Replica 2
                           ──→ Replica 3
```

- One primary (leader) handles ALL writes
- Replicas (followers) receive write stream, typically asynchronously
- Reads from replicas may be stale (replication lag: typically 10-100ms)
- Leader failure → failover: promote a replica to leader
- Used by: MySQL, PostgreSQL, MongoDB, Redis

⚙️ **Under the Hood — Leader Failover:**

```
1. Leader fails (crash, network partition)
2. Detection: replicas notice missing heartbeats (timeout: 10-30 seconds)
3. Election: replicas elect a new leader (most up-to-date replica wins)
4. Reconfiguration: clients redirected to new leader, old leader demoted on recovery

What can go wrong during failover:
  - Split-brain: old leader comes back, thinks it's still leader → two leaders!
    Solution: fencing (old leader's writes rejected via epoch/term number)
  - Data loss: new leader may be behind old leader (async replication)
    Lost writes: old leader had committed writes that weren't replicated yet
  - Failover time: 10-30 seconds of unavailability (or longer if manual)
```

**2. Multi-leader replication:**

```
Writes: Client → Leader A (datacenter 1) OR Leader B (datacenter 2)
Both leaders replicate to each other asynchronously.

Leader A (US) ←──async──→ Leader B (EU)
     ↓                         ↓
  Replicas                  Replicas
```

- Multiple nodes accept writes (typically one leader per datacenter)
- Conflict resolution needed when same data modified in different datacenters
- Used for: multi-datacenter setups, offline-capable apps (each device is a "leader")
- Complexity: write conflicts, convergence, conflict resolution

**Conflict resolution strategies:**

| Strategy | How | Pros | Cons |
|----------|-----|------|------|
| Last-Write-Wins (LWW) | Highest timestamp wins | Simple | Can lose concurrent writes |
| Custom merge | Application-specific logic | Full control | Complex, error-prone |
| CRDTs | Auto-merging data types | No conflicts | Limited data types |

**3. Leaderless replication** [🔥 Must Know]:

```
Writes: Client → write to W nodes (out of N total)
Reads:  Client → read from R nodes, take the latest value

If W + R > N → guaranteed to read the latest write (quorum overlap)
```

- ANY node accepts reads and writes (no leader)
- Quorum: write to W nodes, read from R nodes. W + R > N → consistency
- Used by: Cassandra, DynamoDB, Riak
- Handles node failures gracefully (no failover needed — just write to available nodes)
- Read repair: when a read detects stale data on a node, update it

💡 **Intuition — Why Leaderless is Resilient:** With single-leader, if the leader dies, you need failover (downtime). With leaderless, there's no leader to fail. If one node is down, writes go to the remaining nodes. When the node recovers, it catches up via anti-entropy (background sync) or read repair.

| Replication Type | Write Nodes | Consistency | Failover | Complexity | Use Case |
|-----------------|-------------|-------------|----------|------------|----------|
| Single-leader | 1 (leader) | Strong (primary reads) | Required (downtime risk) | Low | Most databases (MySQL, PostgreSQL) |
| Multi-leader | Multiple | Eventual (conflicts) | No single leader | High (conflicts) | Multi-datacenter |
| Leaderless | Any (quorum) | Tunable (W+R>N) | Not needed | Medium | Cassandra, DynamoDB |

**Replication lag issues** [🔥 Must Know]:

| Problem | Scenario | Solution |
|---------|----------|---------|
| Read-after-write | User writes post, reads from replica, doesn't see own post | Read own data from primary for 10s after write |
| Monotonic reads | User sees newer data, refreshes, sees older data (different replica) | Sticky sessions (always same replica) |
| Consistent prefix | User sees reply before original message (causal order violated) | Causal consistency (track dependencies) |

🎯 **Likely Follow-ups:**
- **Q:** Synchronous vs asynchronous replication?
  **A:** Sync: leader waits for replica ack before confirming write. No data loss, but higher latency and lower availability (replica down = writes blocked). Async: leader confirms immediately, replicates in background. Lower latency, but may lose recent writes on leader failure. Semi-sync: wait for ONE replica (compromise).
- **Q:** How does Cassandra handle replication?
  **A:** Leaderless with tunable consistency. N=3 replicas per partition. Write to W nodes, read from R nodes. W+R>N for strong consistency. Replicas determined by consistent hashing (partition key → ring position → next N nodes clockwise).

### Partitioning (Sharding) [🔥 Must Know]

**Partitioning splits data across multiple nodes so that no single node holds all the data or handles all the traffic.**

💡 **Intuition:** A library with 10 million books can't fit in one building. Split into 10 buildings by author's last name: A-C in building 1, D-F in building 2, etc. Each building (partition/shard) is independent. To find a book, first determine which building (partition routing), then search within.

**Strategies:**

| Strategy | How | Pros | Cons | Best For |
|----------|-----|------|------|----------|
| Key range | A-M → shard 1, N-Z → shard 2 | Range queries efficient | Hotspots (uneven distribution) | Time-series (partition by date range) |
| Hash | hash(key) % N | Even distribution | No range queries, resharding moves all keys | Simple even distribution |
| Consistent hashing | Hash ring with virtual nodes | Minimal redistribution on node change | More complex | Distributed caches, Cassandra |
| Directory | Lookup table maps key → shard | Flexible, can rebalance arbitrarily | Lookup table is SPOF, extra hop | Custom routing logic |

⚙️ **Under the Hood — Choosing a Partition Key:**

```
Good partition key:
  ✅ High cardinality (many distinct values) → even distribution
  ✅ Frequently used in queries → queries hit one partition
  ✅ Immutable (changing key = moving data between partitions)

Bad partition key:
  ❌ Low cardinality (country, gender) → few partitions, uneven
  ❌ Monotonically increasing (timestamp) → all writes go to latest partition (hotspot)
  ❌ Frequently changing → data migration between partitions

Examples:
  Social media: user_id (good — high cardinality, queries are per-user)
  E-commerce: order_id (good) or user_id (good for user's orders)
  Time-series: sensor_id + time_bucket (good — distributes across sensors)
  BAD: country (US shard 10x larger than others)
  BAD: auto-increment ID with hash (good distribution but no locality)
```

**Rebalancing** [🔥 Must Know]:

When adding/removing nodes, data must be redistributed.

| Strategy | How | Redistribution | Complexity |
|----------|-----|---------------|------------|
| Fixed partitions | Pre-create many partitions (e.g., 1000), assign to nodes | Move whole partitions to new node | Low (just reassign) |
| Dynamic partitions | Split when partition grows too large, merge when too small | Split/merge individual partitions | Medium |
| Consistent hashing | Hash ring with virtual nodes | Only K/N keys move on node change | Medium |

💡 **Intuition — Fixed Partitions (Simplest):** Create 1000 partitions upfront, even if you only have 10 nodes (100 partitions per node). When you add an 11th node, move ~90 partitions to it. No data splitting needed — just reassign whole partitions. This is how Elasticsearch, Kafka, and Riak work.

**Secondary indexes with partitioning:**

| Type | How | Write | Read | Used By |
|------|-----|-------|------|---------|
| Local (document-partitioned) | Each partition has its own index | Fast (single partition) | Slow (scatter-gather all partitions) | MongoDB, Cassandra |
| Global (term-partitioned) | Index itself is partitioned by term | Slow (may touch multiple partitions) | Fast (single partition for index lookup) | DynamoDB (GSI) |

### Combining Replication + Partitioning

```
Each partition has its own leader and replicas:

Partition 1: Leader (Node A) → Replica (Node B) → Replica (Node C)
Partition 2: Leader (Node B) → Replica (Node C) → Replica (Node A)
Partition 3: Leader (Node C) → Replica (Node A) → Replica (Node B)

Each node is leader for some partitions and replica for others.
This distributes both write load (leadership) and data (partitions) evenly.
```

💥 **What Can Go Wrong:**

| Problem | Impact | Solution |
|---------|--------|---------|
| Hot partition | One partition gets disproportionate traffic | Split hot partition, cache hot keys, add salt to key |
| Cross-partition queries | Slow (scatter-gather) | Design partition key to keep related data together |
| Rebalancing storm | Moving data overloads network | Throttle rebalancing, do it during low-traffic periods |
| Partition key change | Must migrate all data | Choose immutable partition key upfront |

> 🔗 **See Also:** [02-system-design/01-fundamentals.md](../02-system-design/01-fundamentals.md) for sharding in system design context. [02-system-design/00-prerequisites.md](../02-system-design/00-prerequisites.md) for consistent hashing details.

## 3. Comparison Tables

(See tables inline above)

## 4. How This Shows Up in Interviews

**What to say:**
> "I'll use single-leader replication with PostgreSQL — the primary handles writes, and 2 read replicas handle the read-heavy traffic. Replication is async for low latency, with read-after-write consistency for the user's own data (route to primary for 10 seconds after a write)."

> "For partitioning, I'll shard by user_id using consistent hashing. This keeps all of a user's data on one shard (no cross-shard queries for user-specific operations) and distributes evenly across nodes."

## 5. Deep Dive Questions

1. [🔥 Must Know] **Explain single-leader vs multi-leader vs leaderless replication.** — Write handling, consistency, failover.
2. [🔥 Must Know] **What is a quorum? How does W + R > N ensure consistency?** — Overlap guarantees latest write is read.
3. [🔥 Must Know] **Compare hash partitioning vs range partitioning.** — Distribution vs range queries.
4. **What is replication lag and how do you handle it?** — Read-after-write, monotonic reads, sticky sessions.
5. [🔥 Must Know] **How does consistent hashing help with rebalancing?** — Only K/N keys move, virtual nodes for balance.
6. **What happens during a leader failover?** — Detection, election, reconfiguration, split-brain risk.
7. **How do secondary indexes work with partitioned data?** — Local (scatter-gather reads) vs global (scatter writes).
8. **What is the split-brain problem?** — Two leaders after network partition. Fencing with epoch numbers.
9. [🔥 Must Know] **How does Cassandra handle partitioning and replication?** — Consistent hashing, leaderless, tunable quorum.
10. **Synchronous vs asynchronous replication trade-offs?** — Latency vs data safety.

## 6. Revision Checklist

- [ ] Single-leader: one writer, replicas for reads, failover needed, most common (MySQL, PostgreSQL)
- [ ] Multi-leader: multiple writers, conflict resolution needed, multi-datacenter
- [ ] Leaderless: quorum (W+R>N), no failover, tunable consistency (Cassandra, DynamoDB)
- [ ] Sync replication: no data loss, higher latency. Async: lower latency, may lose recent writes.
- [ ] Hash partitioning: even distribution, no range queries
- [ ] Range partitioning: range queries efficient, risk of hotspots
- [ ] Consistent hashing: minimal redistribution (K/N keys), virtual nodes for balance
- [ ] Fixed partitions: pre-create many, reassign on node change (simplest rebalancing)
- [ ] Replication lag: read-after-write (read from primary), monotonic reads (sticky sessions)
- [ ] Secondary indexes: local (fast writes, scatter reads) vs global (scatter writes, fast reads)
- [ ] Combine: each partition has its own leader + replicas. Nodes share leadership across partitions.
