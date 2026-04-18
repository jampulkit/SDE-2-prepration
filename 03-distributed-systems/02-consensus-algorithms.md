# Consensus Algorithms

## 1. Prerequisites
- [01-cap-theorem-consistency.md](./01-cap-theorem-consistency.md) — CAP theorem, consistency models

## 2. Core Concepts

### Why Consensus Exists

**Consensus algorithms allow multiple nodes in a distributed system to agree on a single value — even when some nodes fail or messages are lost. Without consensus, you can't have reliable leader election, distributed transactions, or consistent replication.**

💡 **Intuition — The Generals Problem:** Imagine 5 generals surrounding a city. They must all attack at the same time or all retreat — a split decision means defeat. But their messengers can be captured (messages lost). How do they agree? Consensus algorithms solve this: if a majority (3 of 5) agree on "attack," the decision is final, even if 2 generals never get the message.

**Where consensus is used:**
- **Leader election:** Which node is the primary? (Raft, ZooKeeper)
- **Log replication:** All replicas agree on the order of operations (Raft, Paxos)
- **Distributed transactions:** All participants commit or all abort (2PC)
- **Configuration management:** All nodes agree on the current config (ZooKeeper, etcd)
- **Distributed locks:** Only one process holds the lock at a time (ZooKeeper, etcd)

### Raft [🔥 Must Know]

**Raft is a consensus algorithm designed to be understandable. It elects a leader, replicates a log of operations to all followers, and guarantees that committed entries are never lost — even if a minority of nodes crash.**

Used in: etcd (Kubernetes), CockroachDB, TiKV, Consul.

**Three states:** Every node is in one of: Leader, Follower, or Candidate.

```
Normal operation:
  [Follower] ←heartbeat← [LEADER] →heartbeat→ [Follower]
  
  All client requests go to the Leader.
  Leader replicates to Followers.
  If majority acknowledge → committed.

Leader failure:
  [Follower] ←no heartbeat← [LEADER dies]
  [Follower] timeout → becomes [CANDIDATE] → requests votes
  Majority votes → becomes new [LEADER]
```

**Leader election (detailed):**

```
1. All nodes start as Followers with a random election timeout (150-300ms)
2. If a Follower doesn't receive a heartbeat before timeout → becomes Candidate
3. Candidate increments its term number, votes for itself, requests votes from all others
4. Each node votes for at most ONE candidate per term (first-come-first-served)
5. If Candidate receives majority votes → becomes Leader
6. Leader sends heartbeats to all Followers to prevent new elections
7. If two Candidates split the vote → neither gets majority → timeout → new election with new term

Why random timeout? Prevents all nodes from becoming Candidates simultaneously.
Why majority? Ensures at most ONE leader per term (two majorities must overlap).
```

💡 **Intuition — Why Majority Prevents Split-Brain:**
With 5 nodes, a majority is 3. Two groups of 3 must share at least 1 node (pigeonhole principle). That shared node can only vote for one candidate → only one candidate gets a majority → only one leader.

**Log replication (detailed):**

```
1. Client sends write request to Leader
2. Leader appends entry to its log (uncommitted)
3. Leader sends AppendEntries RPC to all Followers
4. Each Follower appends to its log, responds with success
5. When Leader receives majority acknowledgments → entry is COMMITTED
6. Leader responds to client: "success"
7. Leader notifies Followers that entry is committed (in next heartbeat)
8. Followers apply committed entries to their state machines

Key guarantee: once committed, the entry is on a majority of nodes.
Even if the Leader crashes, the new Leader will have this entry
(because it must have the most up-to-date log to win the election).
```

⚙️ **Under the Hood — What Happens When the Leader Crashes:**

```
Term 1: Leader A has log [1, 2, 3, 4, 5]. Entries 1-4 committed. Entry 5 uncommitted.
Leader A crashes.

Election: Node B (log [1, 2, 3, 4]) and Node C (log [1, 2, 3, 4]) compete.
  B wins election (has all committed entries).
  B becomes Leader for Term 2.

Entry 5 (uncommitted): LOST. It was only on A's log.
  This is correct — the client never received a success response for entry 5.
  The client should retry.

Entries 1-4 (committed): SAFE. They're on a majority of nodes.
  New Leader B has them all.
```

**Key properties:**
- Only one leader per term (majority vote prevents split-brain)
- Leader has the most up-to-date log (election requirement)
- Committed entries are never lost (on majority of nodes)
- Safety: no two nodes decide differently
- Liveness: eventually makes progress if majority is available

🎯 **Likely Follow-ups:**
- **Q:** What's the difference between Paxos and Raft?
  **A:** Paxos is the theoretical foundation (proven correct by Lamport). Raft is a practical redesign that's equivalent in guarantees but much easier to understand and implement. Raft separates leader election from log replication (Paxos combines them). Most modern systems use Raft.
- **Q:** How many node failures can Raft tolerate?
  **A:** With 2f+1 nodes, Raft tolerates f failures. 3 nodes → 1 failure. 5 nodes → 2 failures. 7 nodes → 3 failures. More nodes = more fault tolerance but slower consensus (more messages).
- **Q:** What is a "term" in Raft?
  **A:** A term is a logical clock / epoch number. Each election starts a new term. Terms are monotonically increasing. If a node receives a message with a higher term, it steps down to Follower. Terms prevent stale leaders from causing confusion.

### Paxos (Conceptual)

**Paxos is the original consensus algorithm — theoretically elegant but notoriously difficult to implement. Most modern systems use Raft instead, but Paxos is worth knowing conceptually.**

- Three roles: **Proposers** (propose values), **Acceptors** (vote on proposals), **Learners** (learn the decided value)
- Two phases: **Prepare** (proposer asks acceptors to promise not to accept older proposals) → **Accept** (proposer sends value, acceptors accept if they haven't promised to a newer proposal)
- Guarantees: safety (no two nodes decide differently), liveness (eventually decides if majority available)
- Complex to implement correctly. Multi-Paxos (for a sequence of values) is even more complex.

### ZooKeeper (ZAB Protocol)

**ZooKeeper is a distributed coordination service used for leader election, configuration management, distributed locks, and service discovery.**

- **ZAB (ZooKeeper Atomic Broadcast):** Similar to Raft — leader-based, majority quorum, log replication
- **Data model:** Hierarchical namespace (like a file system) with znodes
- **Watches:** Clients can watch a znode for changes — get notified when it changes
- **Ephemeral nodes:** Automatically deleted when the client session ends — used for leader election and service discovery
- **Sequential nodes:** Auto-incrementing names — used for distributed locks and queues

```
ZooKeeper use cases:
  Leader election: each candidate creates an ephemeral sequential znode under /election.
    Lowest sequence number = leader. If leader dies, ephemeral node deleted → next in line becomes leader.
  
  Distributed lock: create ephemeral sequential znode under /locks.
    Lowest sequence number holds the lock. Watch the previous znode — when it's deleted, you get the lock.
  
  Configuration: store config in a znode. All services watch it. On change, all get notified.
  
  Service discovery: each service registers an ephemeral znode under /services/{name}.
    Clients list children of /services/{name} to find available instances.
```

💡 **Intuition — Why ZooKeeper, Not Just a Database?** ZooKeeper provides primitives (watches, ephemeral nodes, sequential nodes) that make coordination patterns easy to implement. You COULD build leader election with a database (row-level locking), but it's fragile, slow, and doesn't handle node failures gracefully. ZooKeeper is purpose-built for this.

> 🔗 **See Also:** [06-tech-stack/01-kafka-deep-dive.md](../06-tech-stack/01-kafka-deep-dive.md) — Kafka uses ZooKeeper (or KRaft in newer versions) for broker coordination and leader election.

### Two-Phase Commit (2PC) [🔥 Must Know]

**2PC ensures all participants in a distributed transaction either ALL commit or ALL abort — but it's a blocking protocol that can get stuck if the coordinator crashes.**

```
Phase 1 — PREPARE (voting):
  Coordinator → all Participants: "Can you commit transaction T?"
  Each Participant:
    - Acquires locks, writes to WAL
    - Responds: YES (I can commit) or NO (I can't)

Phase 2 — COMMIT or ABORT (decision):
  If ALL participants said YES:
    Coordinator → all Participants: "COMMIT"
    Participants: commit, release locks
  If ANY participant said NO:
    Coordinator → all Participants: "ABORT"
    Participants: rollback, release locks
```

💡 **Intuition — The Wedding Analogy:** The priest (coordinator) asks the bride and groom (participants): "Do you take this person?" If both say "I do" → married (commit). If either says "I don't" → no marriage (abort). But if the priest faints after asking and before announcing the result → everyone is stuck waiting (blocking).

**The blocking problem** [🔥 Must Know]:

```
Scenario: Coordinator crashes after Phase 1 (after receiving all YES votes)
  - Participants have said YES and are holding locks
  - They don't know if the coordinator decided COMMIT or ABORT
  - They can't commit (what if coordinator decided ABORT?)
  - They can't abort (what if coordinator decided COMMIT?)
  - They're STUCK, holding locks, blocking other transactions

This is why 2PC is called a "blocking protocol."
Solution: use a consensus algorithm (Paxos/Raft) for the coordinator,
  so if the coordinator crashes, a new one takes over with the decision.
```

| Aspect | 2PC | 3PC | Consensus (Raft/Paxos) |
|--------|-----|-----|----------------------|
| Blocking | Yes (coordinator crash) | Less (but still possible) | No (leader election) |
| Partition tolerant | No | No | Yes |
| Latency | 2 round trips | 3 round trips | 2+ round trips |
| Use case | DB transactions | Rarely used | Leader election, replication |

🎯 **Likely Follow-ups:**
- **Q:** How do modern distributed databases avoid 2PC's blocking problem?
  **A:** They use consensus-based approaches. Spanner uses Paxos for each shard's replication and 2PC across shards (but the coordinator is itself replicated via Paxos, so coordinator failure is handled). CockroachDB uses Raft for replication and a parallel commit protocol that avoids the blocking window.
- **Q:** Is 2PC used in practice?
  **A:** Yes, within a single datacenter where network partitions are rare. MySQL's XA transactions use 2PC. But across datacenters, saga pattern (compensating transactions) is preferred over 2PC because it's non-blocking.

> 🔗 **See Also:** [03-distributed-systems/03-distributed-transactions.md](03-distributed-transactions.md) for saga pattern and alternatives to 2PC.

## 3. Comparison Tables

| Algorithm | Use Case | Fault Tolerance | Blocking | Complexity | Used By |
|-----------|----------|----------------|----------|------------|---------|
| Raft | Leader election, log replication | f failures with 2f+1 nodes | No | Medium | etcd, CockroachDB, TiKV |
| Paxos | Consensus (theoretical) | f failures with 2f+1 nodes | No | Very High | Google Chubby, Spanner |
| ZAB | Coordination, config | f failures with 2f+1 nodes | No | High | ZooKeeper |
| 2PC | Distributed transactions | Coordinator crash = blocking | Yes | Medium | MySQL XA, traditional DBs |
| 3PC | Distributed transactions | Less blocking | Partially | High | Rarely used |

## 4. How This Shows Up in Interviews

**What SDE-2 candidates should know:**
- Raft leader election and log replication at a high level (not implementation details)
- 2PC flow and its blocking problem
- When to use ZooKeeper (coordination, not data storage)
- Why consensus requires a majority (2f+1 nodes for f failures)
- The difference between consensus (agreement) and 2PC (transaction commit)

**What to say:**
> "For leader election among my database replicas, I'll use Raft (via etcd). It guarantees that only one leader exists at a time, even during network partitions, because election requires a majority vote."

> "For distributed transactions across microservices, I'll use the saga pattern instead of 2PC, because 2PC is blocking — if the coordinator crashes, all participants are stuck holding locks."

## 5. Deep Dive Questions

1. [🔥 Must Know] **Explain Raft leader election.** — Random timeout, candidate, majority vote, terms.
2. [🔥 Must Know] **What is 2PC and what are its limitations?** — Prepare/commit, blocking on coordinator failure.
3. **How does Raft handle log replication?** — Leader appends, sends to followers, majority ack = committed.
4. **What is split-brain and how does Raft prevent it?** — Two leaders. Prevented by majority requirement.
5. [🔥 Must Know] **When would you use ZooKeeper?** — Leader election, distributed locks, config, service discovery.
6. **What happens in Raft when the leader crashes?** — Election timeout, new election, new leader has all committed entries.
7. **Why is 2PC called a blocking protocol?** — Coordinator crash after prepare = participants stuck.
8. **Paxos vs Raft?** — Same guarantees, Raft is easier to understand and implement.
9. **How many failures can a 5-node Raft cluster tolerate?** — 2 (majority = 3 must be alive).
10. **What are ephemeral nodes in ZooKeeper?** — Auto-deleted when session ends, used for leader election and service discovery.

## 6. Revision Checklist

- [ ] Raft: leader election (random timeout, majority vote, one leader per term)
- [ ] Raft: log replication (leader appends, majority ack = committed, committed entries never lost)
- [ ] Raft: 2f+1 nodes tolerate f failures. 5 nodes → tolerate 2 failures.
- [ ] Raft: split-brain prevented by majority requirement (two majorities must overlap)
- [ ] 2PC: prepare (vote) → commit/abort (decision). Blocking if coordinator crashes after prepare.
- [ ] ZooKeeper: coordination service. Ephemeral nodes (leader election), watches (config changes), sequential nodes (locks).
- [ ] Consensus vs 2PC: consensus = agreement on a value. 2PC = all-or-nothing transaction commit.
- [ ] Modern alternative to 2PC: saga pattern (compensating transactions, non-blocking).
- [ ] Paxos = theoretical foundation. Raft = practical implementation. Same guarantees.
