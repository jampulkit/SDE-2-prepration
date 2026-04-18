# Clocks, Ordering & Gossip Protocols

## 1. Prerequisites
- [01-cap-theorem-consistency.md](01-cap-theorem-consistency.md) — consistency models
- [02-consensus-algorithms.md](02-consensus-algorithms.md) — Raft, Paxos

## 2. Core Concepts

### Why Clocks Matter in Distributed Systems

**In a single machine, events have a natural order (CPU clock). In a distributed system, there is no global clock. Two events on different machines can't be ordered by wall-clock time because clocks drift, skew, and can even jump backward (NTP corrections).**

💡 **Intuition:** Imagine two people in different time zones writing letters. Person A writes at "3:00 PM" and Person B writes at "3:05 PM". Did A write first? Not necessarily. Their clocks might be off by hours. Without a shared reference, you can't determine the true order. Distributed systems face the same problem.

### Physical Clocks and Their Limitations

```
Clock skew: two machines' clocks show different times at the same instant
  Machine A: 10:00:00.000
  Machine B: 10:00:00.150  (150ms ahead)

Clock drift: clocks run at slightly different speeds
  Quartz crystal: drifts ~1ms per 10 seconds
  After 1 hour: ~360ms drift. After 1 day: ~8.6 seconds drift.

NTP (Network Time Protocol): synchronizes clocks to ~1-10ms accuracy
  Problem: NTP can JUMP the clock backward (if clock was ahead)
  This means: timestamp(event_A) < timestamp(event_B) does NOT guarantee A happened before B
```

**Why Last-Write-Wins (LWW) is dangerous:**

```
Machine A (clock is 100ms ahead): writes key=X, value=1 at timestamp 10:00:00.100
Machine B (clock is correct):     writes key=X, value=2 at timestamp 10:00:00.050

LWW picks A's write (higher timestamp). But B's write actually happened LATER.
Result: B's more recent write is lost. Data corruption.

This is why Cassandra and DynamoDB use LWW but warn about clock synchronization.
Google Spanner solves this with TrueTime (atomic clocks + GPS, bounded uncertainty).
```

### Lamport Clocks (Logical Clocks) [🔥 Must Know]

**A Lamport clock assigns a logical timestamp to every event such that if event A causally precedes event B, then timestamp(A) < timestamp(B).**

```
Rules:
  1. Each process maintains a counter C
  2. Before each local event: C = C + 1
  3. When sending a message: attach C to the message
  4. When receiving a message with timestamp T: C = max(C, T) + 1

Example:
  Process P1:        Process P2:        Process P3:
  C=1 (event a)
  C=2 (send m1) ──→  C=3 (recv m1)
                      C=4 (event b)
                      C=5 (send m2) ──→  C=6 (recv m2)
  C=3 (event c)                          C=7 (event d)
  C=4 (send m3) ──────────────────────→  C=8 (recv m3)

Ordering: a(1) < m1_send(2) < m1_recv(3) < b(4) < m2_send(5) < m2_recv(6) < d(7) < m3_recv(8)

Limitation: if timestamp(A) < timestamp(B), we can't conclude A caused B.
  Event c(3) and event b(4): c has lower timestamp, but they're CONCURRENT (no causal relation).
  Lamport clocks capture: causality → order. But NOT: order → causality.
```

### Vector Clocks [🔥 Must Know]

**Vector clocks extend Lamport clocks to detect concurrency. Each process maintains a vector of counters, one per process.**

```
Rules:
  1. Each process Pi maintains vector V[i] where V[i][j] = Pi's knowledge of Pj's clock
  2. Before each local event: V[i][i] = V[i][i] + 1
  3. When sending: attach V[i] to message
  4. When receiving message with vector T: V[i][j] = max(V[i][j], T[j]) for all j, then V[i][i]++

Example (3 processes):
  P1: V=[1,0,0] (event a)
  P1: V=[2,0,0] (send m1) ──→ P2: V=[2,1,0] (recv m1, max then increment P2)
                                P2: V=[2,2,0] (event b)
  P1: V=[3,0,0] (event c)      P2: V=[2,3,0] (send m2) ──→ P3: V=[2,3,1] (recv m2)

Comparing vector clocks:
  V1 < V2 if V1[i] <= V2[i] for ALL i, and V1 != V2 (V1 happened before V2)
  V1 || V2 (concurrent) if neither V1 < V2 nor V2 < V1

  c=[3,0,0] vs b=[2,2,0]: 3>2 but 0<2 → CONCURRENT ✓
  a=[1,0,0] vs b=[2,2,0]: 1<2 and 0<2 → a happened before b ✓
```

**Used by:** Amazon DynamoDB (Dynamo paper) for conflict detection. If two writes have concurrent vector clocks, DynamoDB returns both versions and lets the application resolve the conflict.

### Hybrid Logical Clocks (HLC)

**Combines physical time (for human-readable ordering) with logical counters (for causal ordering). Used by CockroachDB and YugabyteDB.**

```
HLC = (physical_time, logical_counter)

Rules:
  1. On local event: hlc = (max(hlc.physical, wall_clock), 0)
  2. On send: same as local event, attach hlc
  3. On receive with sender's hlc_s:
     if hlc_s.physical > wall_clock: hlc = (hlc_s.physical, hlc_s.logical + 1)
     else: hlc = (wall_clock, 0)

Benefit: timestamps are close to real time (useful for TTL, debugging)
         but still maintain causal ordering guarantees
```

### Gossip Protocol [🔥 Must Know]

**A protocol where nodes periodically exchange state with random peers, eventually propagating information to all nodes. Used for failure detection, membership, and state dissemination.**

💡 **Intuition:** Like how rumors spread in a social network. Each person tells a few random friends. Those friends tell their friends. Within a few rounds, everyone knows. Mathematically, information reaches all N nodes in O(log N) rounds.

```
Gossip protocol for failure detection:

Every T seconds, each node:
  1. Pick a random peer
  2. Send my membership list (node_id, heartbeat_counter, timestamp)
  3. Receive peer's membership list
  4. Merge: for each node, keep the higher heartbeat counter
  5. If a node's heartbeat hasn't increased in T_fail seconds → mark as suspected
  6. If suspected for T_cleanup seconds → remove from membership list

Properties:
  - Scalable: each node communicates with O(1) peers per round
  - Reliable: information propagates in O(log N) rounds
  - Decentralized: no leader, no single point of failure
  - Eventually consistent: all nodes converge to the same membership view

Used by: Cassandra (failure detection), Consul (membership), Redis Cluster (gossip bus)
```

**Gossip protocol variants:**

| Variant | What It Spreads | Used By |
|---------|----------------|---------|
| Anti-entropy | Full state (expensive but complete) | Riak, Dynamo |
| Rumor mongering | New updates only (efficient) | Cassandra |
| SWIM | Membership + failure detection | Consul, Serf |

🎯 **Likely Follow-ups:**
- **Q:** Why not just use NTP for ordering events?
  **A:** NTP accuracy is 1-10ms at best. Two events within that window can't be ordered by NTP. Also, NTP can jump backward, making timestamps non-monotonic. Logical clocks provide causal ordering guarantees that physical clocks cannot.
- **Q:** How does Google Spanner achieve global strong consistency?
  **A:** TrueTime API: atomic clocks + GPS in every datacenter give bounded clock uncertainty (typically < 7ms). Spanner waits for the uncertainty window to pass before committing, guaranteeing that if commit(A) < commit(B) in real time, then timestamp(A) < timestamp(B). This is called "external consistency."
- **Q:** Vector clocks vs Lamport clocks: when to use which?
  **A:** Lamport clocks are simpler (single counter) but can't detect concurrency. Vector clocks detect concurrency but grow with the number of processes (O(N) space per event). For systems with many processes, use dotted version vectors (compact representation) or HLC.

## 3. Revision Checklist

- [ ] Physical clocks: drift (~1ms/10s), skew (different machines), NTP can jump backward
- [ ] LWW is dangerous: higher timestamp doesn't mean later event (clock skew)
- [ ] Lamport clock: C = max(C, received_T) + 1. Causality → order, but NOT order → causality.
- [ ] Vector clock: vector of counters, one per process. Can detect concurrency (neither < nor >).
- [ ] HLC: (physical_time, logical_counter). Close to real time + causal ordering.
- [ ] Gossip protocol: random peer exchange, O(log N) propagation, decentralized, eventually consistent.
- [ ] Gossip for: failure detection (heartbeat timeout), membership, state dissemination.
- [ ] Google Spanner TrueTime: atomic clocks, bounded uncertainty, wait-out for external consistency.

> 🔗 **See Also:** [03-distributed-systems/01-cap-theorem-consistency.md](01-cap-theorem-consistency.md) for consistency models. [03-distributed-systems/04-partitioning-replication.md](04-partitioning-replication.md) for replication and conflict resolution. [06-tech-stack/02-redis-deep-dive.md](../06-tech-stack/02-redis-deep-dive.md) for Redis Cluster gossip.
