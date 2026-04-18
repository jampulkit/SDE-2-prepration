# CAP Theorem & Consistency Models

## 1. Prerequisites
- [02-system-design/00-prerequisites.md](../02-system-design/00-prerequisites.md) — availability, replication basics
- This document covers the theoretical foundations that underpin every database and distributed system choice

## 2. Core Concepts

### CAP Theorem [🔥 Must Know]

**In a distributed system experiencing a network partition, you must choose between consistency (every read sees the latest write) and availability (every request gets a response). You can't have both.**

In a distributed system, you can only guarantee two of three:
- **Consistency (C):** Every read receives the most recent write (all nodes see the same data at the same time)
- **Availability (A):** Every request receives a non-error response (the system always responds)
- **Partition Tolerance (P):** System continues operating despite network partitions (messages lost or delayed between nodes)

💡 **Intuition — The ATM Analogy:**
Imagine two ATMs connected by a network. Your balance is $100. You withdraw $50 from ATM-A. Before ATM-A can tell ATM-B about the withdrawal, the network cable is cut (partition).

Now you go to ATM-B and check your balance:
- **CP choice:** ATM-B says "Sorry, I can't serve you right now — I'm not sure if my data is current." (Consistent but unavailable)
- **AP choice:** ATM-B says "Your balance is $100." (Available but inconsistent — you could withdraw another $50, overdrawing your account)

Neither is wrong — it depends on the business requirement. For a bank: CP (don't allow overdrafts). For a social media feed: AP (showing a slightly stale feed is fine).

**The reality:** Network partitions WILL happen in any distributed system (hardware failures, network congestion, datacenter issues). So P is not optional — the real choice is between C and A during a partition:

```
During normal operation (no partition): You get BOTH consistency and availability
During a partition: You must CHOOSE:
  CP: Reject requests to maintain consistency (some users get errors)
  AP: Serve potentially stale data to maintain availability (all users get responses)
```

- **CP systems:** Reject requests during partition to maintain consistency
  - Examples: HBase, MongoDB (with majority reads), ZooKeeper, etcd
  - Use when: correctness is critical (payments, inventory, coordination)

- **AP systems:** Serve potentially stale data during partition to maintain availability
  - Examples: Cassandra, DynamoDB, CouchDB
  - Use when: availability is critical, stale data is tolerable (feeds, product catalog, analytics)

⚙️ **Under the Hood — What a Network Partition Looks Like:**

```
Normal:
  Node A ←──network──→ Node B ←──network──→ Node C
  All nodes can communicate. Reads and writes are consistent.

Partition between A and {B, C}:
  Node A ←──BROKEN──→ Node B ←──network──→ Node C
  
  Client writes to Node A: "balance = $50"
  Client reads from Node B: still sees "balance = $100" (stale!)
  
  CP response: Node B refuses to serve reads (might be stale)
  AP response: Node B serves "balance = $100" (stale but available)
```

🎯 **Likely Follow-ups:**
- **Q:** Is CAP a binary choice? Can you have "mostly consistent" and "mostly available"?
  **A:** In practice, yes. CAP is a theoretical framework. Real systems make nuanced trade-offs: Cassandra's tunable consistency lets you choose per-query. DynamoDB offers both eventually consistent and strongly consistent reads. The choice isn't system-wide — it can be per-operation.
- **Q:** What about single-node databases? Where do they fall in CAP?
  **A:** Single-node databases (non-distributed) don't have partitions, so CAP doesn't apply. They provide both C and A. But they sacrifice fault tolerance — if the node dies, the system is down.
- **Q:** Can you give a real-world example of a CAP trade-off decision?
  **A:** Amazon's shopping cart (Dynamo paper): they chose AP because a customer should always be able to add items to their cart, even during a partition. If two datacenters have conflicting cart states, they merge them (union of items). Losing an item from the cart is worse than having a duplicate.

### PACELC Theorem (Extension of CAP)

**PACELC extends CAP: during a Partition, choose Availability or Consistency. Else (normal operation), choose Latency or Consistency.**

CAP only describes behavior during partitions. PACELC adds: even when there's no partition, there's a trade-off between latency and consistency (because achieving consistency requires coordination between nodes, which adds latency).

```
If Partition:
  Choose A (availability) or C (consistency)
Else (no partition):
  Choose L (low latency) or C (consistency)

Examples:
  PA/EL: Cassandra, DynamoDB
    → During partition: stay available (serve stale data)
    → Normal: prioritize low latency (async replication)
  
  PC/EC: HBase, traditional RDBMS (replicated)
    → During partition: maintain consistency (reject some requests)
    → Normal: maintain consistency (synchronous replication, higher latency)
  
  PA/EC: Rare combination
    → During partition: stay available
    → Normal: maintain consistency (sync replication when network is healthy)
```

💡 **Intuition — Why PACELC Matters More Than CAP:** Partitions are rare (maybe a few times per year). The Else clause (latency vs consistency during normal operation) affects EVERY request. A system that's consistent but adds 100ms latency to every read (because it waits for all replicas to agree) has a very different user experience than one that reads from the nearest replica in 1ms.

### Consistency Models [🔥 Must Know]

**Consistency models define what guarantees a distributed system provides about the order and visibility of operations.**

| Model | Guarantee | Latency | Example | Use When |
|-------|-----------|---------|---------|----------|
| **Strong (Linearizability)** | Read always returns the latest write, as if there's one copy | Highest | Single-node DB, Spanner | Payments, inventory, locks |
| **Sequential** | All nodes see operations in the same order (but not necessarily real-time) | High | ZooKeeper | Coordination, leader election |
| **Causal** | Causally related operations seen in order; concurrent ops may differ | Medium | COPS | Social media (see reply after original post) |
| **Read-your-writes** | User always sees their own writes | Medium | Session consistency | User profiles, settings |
| **Monotonic reads** | Once you read a value, you never see an older value | Low | Sticky sessions | Dashboards, feeds |
| **Eventual** | All replicas converge eventually (no ordering guarantee) | Lowest | Cassandra, DynamoDB | Analytics, product views, feeds |

```
Consistency spectrum (strongest → weakest):

  Linearizable → Sequential → Causal → Read-your-writes → Monotonic → Eventual
  ←── harder to scale, higher latency ──→ ←── easier to scale, lower latency ──→
```

💡 **Intuition — Eventual Consistency in Real Life:**
DNS is eventually consistent. When you update a DNS record, it takes minutes to hours for all DNS servers worldwide to see the change. During that window, some users see the old IP, some see the new one. Eventually, everyone sees the new one. This is acceptable because DNS changes are rare and the impact of stale data is low.

**Strong consistency:** Simplest to reason about but hardest to achieve at scale. Requires coordination (consensus protocols like Paxos/Raft), adds latency (must wait for majority of replicas to agree).

**Eventual consistency:** Highest availability and lowest latency. But clients may read stale data. Suitable when: social media feeds, product views, analytics, DNS, caching.

**Tunable consistency (Cassandra/DynamoDB)** [🔥 Must Know]:

```
N = total replicas (typically 3)
W = replicas that must acknowledge a write
R = replicas that must respond to a read

Rule: if W + R > N → strong consistency (at least one replica has the latest write)

Common configurations:
  N=3, W=2, R=2: strong consistency (2+2=4 > 3). Tolerates 1 node failure.
  N=3, W=1, R=1: eventual consistency. Fastest. Tolerates 2 node failures for availability.
  N=3, W=3, R=1: strong writes, fast reads. But write fails if any node is down.
  N=3, W=1, R=3: fast writes, strong reads. But read fails if any node is down.

Trade-off: higher W or R → stronger consistency but lower availability and higher latency.
```

⚙️ **Under the Hood — Why W+R > N Guarantees Consistency:**

```
N=3 replicas: [A, B, C]

Write with W=2: write acknowledged by A and B (C might be behind)
Read with R=2: read from B and C

Overlap: B is in both the write set and read set.
B has the latest write → read returns the latest value.

If W+R ≤ N (e.g., W=1, R=1):
  Write to A only. Read from C only. No overlap → C might return stale data.
```

### Consistency Patterns in Practice

**Read-after-write consistency** [🔥 Must Know]:
User writes a post, then immediately views their profile — they should see the post.

```
Implementation options:
1. Read own data from primary (not replica): route user's reads to the primary
   for a short window (e.g., 10 seconds) after they write.
2. Client-side: after writing, client adds the new data to local state
   without waiting for server confirmation.
3. Timestamp-based: client sends "last write timestamp" with read request.
   Server ensures the replica is at least that fresh before responding.
```

**Monotonic reads:** Once you read a value, you never see an older value.
Implementation: sticky sessions — always route a user to the same replica. If that replica fails, route to a replica that's at least as up-to-date.

**Conflict resolution for eventual consistency** [🔥 Must Know]:

| Strategy | How | Pros | Cons | Used By |
|----------|-----|------|------|---------|
| Last-Write-Wins (LWW) | Highest timestamp wins | Simple, no conflicts | Can lose concurrent writes | Cassandra, DynamoDB |
| Vector Clocks | Track causal ordering per node | Detects conflicts accurately | Complex, metadata grows | Amazon Dynamo (original) |
| CRDTs | Data types that auto-merge without conflicts | No conflicts ever, mathematically proven | Limited data types, higher memory | Riak, Redis (CRDT module) |
| Application-level | App decides how to merge | Full control | Complex, error-prone | Custom systems |

💡 **Intuition — CRDTs (Conflict-free Replicated Data Types):**
A CRDT is a data structure designed so that concurrent updates can always be merged without conflicts. Example: a G-Counter (grow-only counter). Each node maintains its own count. The total is the sum of all nodes' counts. Concurrent increments on different nodes never conflict — you just sum them.

```
G-Counter example (3 nodes):
  Node A: count_A = 5
  Node B: count_B = 3
  Node C: count_C = 7
  Total = 5 + 3 + 7 = 15

Node A increments: count_A = 6. Total = 6 + 3 + 7 = 16.
Node B increments: count_B = 4. Total = 6 + 4 + 7 = 17.
Both increments are captured — no conflict, no data loss.
```

🎯 **Likely Follow-ups:**
- **Q:** How does Google Spanner achieve strong consistency globally?
  **A:** Spanner uses TrueTime — GPS and atomic clocks in every datacenter provide a globally synchronized clock with bounded uncertainty (~7ms). Transactions are assigned timestamps from TrueTime. If the uncertainty interval of two transactions doesn't overlap, their order is determined. If it does, Spanner waits for the uncertainty to pass. This gives external consistency (linearizability) across the globe.
- **Q:** When would you use CRDTs in practice?
  **A:** Collaborative editing (Google Docs uses OT, but CRDTs are an alternative), distributed counters (like counts, views), shopping carts (set union), and any system where you need conflict-free merging across replicas without coordination.

> 🔗 **See Also:** [03-distributed-systems/02-consensus-algorithms.md](02-consensus-algorithms.md) for Paxos/Raft (how CP systems achieve consensus). [03-distributed-systems/04-partitioning-replication.md](04-partitioning-replication.md) for replication strategies. [02-system-design/02-database-choices.md](../02-system-design/02-database-choices.md) for database consistency trade-offs.

## 3. Comparison Tables

| System | CAP | PACELC | Consistency Model | Use Case |
|--------|-----|--------|------------------|----------|
| MySQL (single) | CA* | PC/EC | Strong | OLTP, transactions |
| MySQL (replicated) | CP | PC/EC | Strong (primary), eventual (replicas) | Read scaling |
| Cassandra | AP | PA/EL | Tunable (eventual default) | High write throughput |
| DynamoDB | AP | PA/EL | Tunable (eventual default) | Managed NoSQL |
| MongoDB | CP | PC/EC | Strong (primary reads) | Document store |
| Redis (replicated) | AP | PA/EL | Eventual (async replication) | Caching |
| ZooKeeper | CP | PC/EC | Sequential (linearizable reads optional) | Coordination, config |
| Google Spanner | CP | PC/EC | Strong (external consistency) | Global SQL |
| CockroachDB | CP | PC/EC | Strong (serializable) | Distributed SQL |

*Single-node MySQL is CA because there's no partition to tolerate. But it's not distributed.

## 4. How This Shows Up in Interviews

**When to discuss consistency:**
- "What happens if two users update the same record simultaneously?" → conflict resolution
- "What consistency guarantees does your system provide?" → choose model based on requirements
- "How do you handle network partitions?" → CP vs AP trade-off

**What to say:**
> "For this payment system, I need strong consistency — we can't risk double charges or lost payments. I'll use PostgreSQL with ACID transactions. The trade-off is higher latency and lower availability during partitions, but correctness is non-negotiable for financial data."

> "For the news feed, eventual consistency is fine — a user seeing a post 1-2 seconds late is acceptable. I'll use Cassandra with W=1, R=1 for maximum throughput and availability. The trade-off is that users might briefly see stale data, but the feed refreshes frequently anyway."

**Red flags:**
- "I'll use strong consistency everywhere" (doesn't understand the performance cost)
- "Eventual consistency is always fine" (doesn't understand when correctness matters)
- Can't explain what happens during a network partition
- Doesn't know the difference between CP and AP systems

## 5. Deep Dive Questions

1. [🔥 Must Know] **Explain the CAP theorem with examples of CP and AP systems.**
2. [🔥 Must Know] **What is eventual consistency? When is it acceptable?** — Feeds, analytics, product views.
3. [🔥 Must Know] **How does tunable consistency work in Cassandra?** — W, R, N parameters, W+R>N rule.
4. **What is linearizability vs sequential consistency?** — Real-time ordering vs agreed ordering.
5. [🔥 Must Know] **How do you achieve read-after-write consistency?** — Read from primary, timestamp-based, client-side.
6. **What are vector clocks?** — Per-node counters, detect concurrent writes, application resolves.
7. **What are CRDTs?** — Auto-merging data types, G-Counter example, no conflicts.
8. [🔥 Must Know] **When would you choose strong over eventual consistency?** — Payments, inventory, locks vs feeds, analytics, views.
9. **What is the PACELC theorem?** — Extends CAP with latency vs consistency during normal operation.
10. **How does Google Spanner achieve global strong consistency?** — TrueTime (GPS + atomic clocks), bounded uncertainty.

## 6. Revision Checklist

- [ ] CAP: during partition, choose C (reject requests) or A (serve stale data). P is not optional.
- [ ] Network partitions are inevitable → real choice is CP or AP during partition.
- [ ] PACELC: during partition → A or C. Else → Latency or Consistency.
- [ ] Strong consistency: latest write always visible, requires coordination (Paxos/Raft), higher latency.
- [ ] Eventual consistency: replicas converge eventually, highest availability, lowest latency.
- [ ] Tunable (Cassandra): W + R > N → strong. W=1, R=1 → eventual. N typically 3.
- [ ] Read-after-write: read own writes from primary for short window after write.
- [ ] Monotonic reads: sticky sessions (always same replica).
- [ ] Conflict resolution: LWW (simple, lossy), vector clocks (detect conflicts), CRDTs (auto-merge).
- [ ] CP systems: HBase, MongoDB, ZooKeeper, Spanner. AP systems: Cassandra, DynamoDB, Redis.
- [ ] Choose strong for: payments, inventory, locks. Choose eventual for: feeds, analytics, views.

---

## 📋 Suggested New Documents

### 1. Consistency in Practice — Patterns & Anti-Patterns
- **Placement**: `03-distributed-systems/05-consistency-patterns.md`
- **Why needed**: Read-after-write, monotonic reads, causal consistency, and the dual-write problem are practical patterns that come up in every system design interview but are only briefly mentioned here.
- **Key subtopics**: Dual-write problem and solutions (outbox pattern, CDC), read-after-write implementation strategies, causal consistency with logical clocks, session consistency patterns, consistency in microservices (saga + eventual consistency)
