# Design: Distributed ID Generator

## 1. Problem Statement & Scope

**Design a system that generates globally unique, roughly time-ordered IDs at high throughput across multiple datacenters. Used for: database primary keys, order IDs, message IDs, trace IDs.**

**Clarifying questions to ask:**
- Must IDs be sortable by time? → Yes (roughly ordered)
- Numeric or string? → 64-bit integer preferred (compact, indexable)
- Throughput? → 100K+ IDs/sec per datacenter
- How many datacenters? → 2-5
- Must be unique across datacenters without coordination? → Yes

💡 **Why this is asked:** Every distributed system needs unique IDs. Auto-increment doesn't work across multiple databases. UUIDs are random (not sortable, bad for B+ tree indexes). Snowflake IDs solve both problems. This tests your understanding of bit manipulation, clock handling, and distributed coordination.

## 2. Requirements

**Functional:**
- Generate globally unique 64-bit IDs
- IDs are roughly time-ordered (IDs generated later have higher values)
- No coordination between generators (each node generates independently)

**Non-functional:**
- High throughput: 100K+ IDs/sec per node
- Low latency: < 1ms per ID generation
- No single point of failure
- IDs fit in a 64-bit long (for database efficiency)

## 3. Approaches Comparison

| Approach | Uniqueness | Sortable | Size | Throughput | Coordination |
|----------|-----------|----------|------|-----------|-------------|
| Auto-increment | Per-DB only | Yes | 64-bit | DB-limited | Requires single DB |
| UUID v4 | Global | No (random) | 128-bit | Unlimited | None |
| UUID v7 | Global | Yes (time-based) | 128-bit | Unlimited | None |
| Snowflake ID | Global | Yes | 64-bit | 4096/ms/node | None (pre-assigned node IDs) |
| DB ticket server | Global | Yes | 64-bit | DB-limited | Centralized |

### Why Not Auto-Increment?

```
Single DB: works fine. But in a distributed system:
  DB-1 generates: 1, 2, 3, 4, 5...
  DB-2 generates: 1, 2, 3, 4, 5... → COLLISION!

Fix 1: odd/even (DB-1: 1,3,5. DB-2: 2,4,6)
  Problem: adding a 3rd DB requires renumbering. Not scalable.

Fix 2: range allocation (DB-1: 1-1000, DB-2: 1001-2000)
  Problem: need a coordinator to allocate ranges. Single point of failure.
```

### Why Not UUID v4?

```
UUID v4: 128-bit random. Example: 550e8400-e29b-41d4-a716-446655440000

Problems:
  1. 128 bits = 16 bytes. Twice the size of a 64-bit long. Wastes index space.
  2. Random → terrible B+ tree performance. New IDs scatter across all leaf pages.
     Every insert causes a random disk seek. With sequential IDs, inserts are append-only.
  3. Not sortable by time. Can't do "get latest 10 orders" by ID order.

UUID v7 (2022 standard): timestamp-based, sortable. Fixes problem 2 and 3.
  But still 128 bits (problem 1).
```

## 4. Snowflake ID (Twitter's Approach) [🔥 Must Know]

**64-bit ID = timestamp + datacenter + machine + sequence**

```
Bit layout (64 bits total):
  0 | 41 bits timestamp | 5 bits datacenter | 5 bits machine | 12 bits sequence
  
  Sign bit (1): always 0 (positive number)
  Timestamp (41): milliseconds since custom epoch. Lasts 2^41 ms ≈ 69 years.
  Datacenter ID (5): 0-31 datacenters
  Machine ID (5): 0-31 machines per datacenter
  Sequence (12): 0-4095 IDs per millisecond per machine

  Max throughput per machine: 4096 IDs/ms = 4,096,000 IDs/sec
  Total capacity: 32 datacenters × 32 machines × 4096/ms = 4.2 billion IDs/sec
```

**Java implementation:**

```java
public class SnowflakeIdGenerator {
    private static final long EPOCH = 1609459200000L; // 2021-01-01 00:00:00 UTC
    private static final int DATACENTER_BITS = 5;
    private static final int MACHINE_BITS = 5;
    private static final int SEQUENCE_BITS = 12;
    
    private static final long MAX_SEQUENCE = (1L << SEQUENCE_BITS) - 1; // 4095
    
    private final long datacenterId;
    private final long machineId;
    private long sequence = 0;
    private long lastTimestamp = -1;
    
    public SnowflakeIdGenerator(long datacenterId, long machineId) {
        this.datacenterId = datacenterId;
        this.machineId = machineId;
    }
    
    public synchronized long nextId() {
        long timestamp = System.currentTimeMillis();
        
        if (timestamp == lastTimestamp) {
            sequence = (sequence + 1) & MAX_SEQUENCE;
            if (sequence == 0) {
                timestamp = waitNextMillis(lastTimestamp); // sequence exhausted, wait
            }
        } else {
            sequence = 0; // new millisecond, reset sequence
        }
        
        if (timestamp < lastTimestamp) {
            throw new RuntimeException("Clock moved backwards!"); // clock skew
        }
        
        lastTimestamp = timestamp;
        
        return ((timestamp - EPOCH) << (DATACENTER_BITS + MACHINE_BITS + SEQUENCE_BITS))
             | (datacenterId << (MACHINE_BITS + SEQUENCE_BITS))
             | (machineId << SEQUENCE_BITS)
             | sequence;
    }
    
    private long waitNextMillis(long lastTs) {
        long ts = System.currentTimeMillis();
        while (ts <= lastTs) ts = System.currentTimeMillis();
        return ts;
    }
}
```

### Clock Skew Handling [🔥 Must Know]

```
Problem: System clock jumps backward (NTP correction).
  If we generate IDs with the old (future) timestamp and then the clock goes back,
  new IDs could have LOWER timestamps than old IDs → ordering broken.
  Worse: same timestamp + same sequence → DUPLICATE IDs.

Solutions:
  1. Reject: throw exception, let caller retry. Simple but causes brief unavailability.
  2. Wait: if clock goes back by < 5ms, wait until it catches up. Adds latency.
  3. Logical clock: track last used timestamp. If wall clock < last timestamp, use last+1.
     This is what most production systems do.
  4. Leaf (Meituan): pre-allocate ID ranges from a central DB. No clock dependency.
```

### DB Ticket Server (Flickr's Approach)

```
Two MySQL servers with auto-increment:
  Server 1: increment by 2, start at 1 → generates 1, 3, 5, 7...
  Server 2: increment by 2, start at 2 → generates 2, 4, 6, 8...

Client round-robins between servers.
If one server dies, the other still generates unique IDs.

Pros: simple, sequential, 64-bit
Cons: single point of failure (2 servers), limited throughput (DB-bound), not time-ordered
```

## 5. Bottlenecks & Trade-offs

| Concern | Snowflake Solution |
|---------|-------------------|
| Clock skew | Reject or wait. Use logical clock as fallback. |
| Machine ID assignment | ZooKeeper, etcd, or config file. Must be unique per machine. |
| Sequence exhaustion | 4096/ms is plenty. If exceeded, wait for next millisecond. |
| 69-year limit | Choose epoch close to current date. Extend timestamp bits if needed. |
| Not cryptographically random | IDs are predictable (timestamp + sequence). Don't use for security tokens. |

🎯 **Likely Follow-ups:**
- **Q:** How do you assign machine IDs?
  **A:** Options: (1) ZooKeeper/etcd: each machine registers and gets a unique ID. (2) Config file: manually assign during deployment. (3) MAC address hash mod 1024. (4) Kubernetes pod ordinal index.
- **Q:** Can you extract the timestamp from a Snowflake ID?
  **A:** Yes. `timestamp = (id >> 22) + EPOCH`. This is useful for "get all orders created in the last hour" without a separate timestamp column.
- **Q:** How does this compare to UUID v7?
  **A:** UUID v7 is 128-bit (timestamp + random). Snowflake is 64-bit (timestamp + machine + sequence). Snowflake is more compact and guarantees uniqueness without randomness. UUID v7 doesn't need machine ID assignment but uses twice the storage.

## 6. Revision Checklist

- [ ] Auto-increment fails across multiple DBs (collisions).
- [ ] UUID v4: 128-bit, random, bad for B+ tree indexes, not sortable.
- [ ] Snowflake: 64-bit = 41 timestamp + 5 datacenter + 5 machine + 12 sequence.
- [ ] Snowflake throughput: 4096 IDs/ms/machine. 69-year lifespan from epoch.
- [ ] Clock skew: reject, wait, or use logical clock. NTP can jump backward.
- [ ] Machine ID: assign via ZooKeeper, config, or pod ordinal.
- [ ] Extract timestamp: `(id >> 22) + EPOCH`. Enables time-range queries by ID.
- [ ] DB ticket server: simple but centralized. Two servers with odd/even for HA.

> 🔗 **See Also:** [02-system-design/problems/url-shortener.md](url-shortener.md) for Base62 encoding of IDs. [01-dsa/10-bit-manipulation.md](../../01-dsa/10-bit-manipulation.md) for bit shifting operations.

---

## 9. Interviewer Deep-Dive Questions

1. **"Clock goes backward (NTP adjustment). What happens to Snowflake IDs?"**
   → IDs would no longer be monotonically increasing — could generate duplicate IDs. Solutions: (1) Refuse to generate IDs until clock catches up (simple, causes brief unavailability). (2) Use a logical clock that never goes backward (track last timestamp, increment sequence if clock goes back). (3) Wait for clock to advance past last used timestamp.

2. **"Datacenter ID exhaustion — you have 5 bits (32 DCs) and need a 33rd."**
   → Redesign bit allocation. Or: use a different ID scheme for the new DC. Or: reclaim IDs from decommissioned DCs. In practice: 5 bits for DC + 5 bits for machine = 1024 unique generators. Rarely exhausted.

3. **"Why not just use UUID v4?"**
   → 128 bits (wastes space in DB indexes). Random (not sortable — terrible for B+ tree index performance, causes random I/O). Snowflake: 64 bits, time-sorted (sequential inserts into B+ tree, excellent write performance). UUID v7 (time-based) is a good middle ground if 128 bits is acceptable.

4. **"How do you assign machine IDs without a coordinator?"**
   → Options: (1) ZooKeeper/etcd: each machine registers and gets a unique ID. (2) Pre-assign: configure machine ID in deployment config. (3) MAC address hash: use lower bits of MAC address (risk of collision). (4) Kubernetes pod ordinal (StatefulSet gives stable IDs).

5. **"What happens if two machines accidentally get the same machine ID?"**
   → Duplicate IDs generated. Detection: monitor for duplicate IDs in downstream systems. Prevention: ZooKeeper lease — machine must hold a lease on its ID. If lease expires (machine dies), ID is reclaimed and reassigned.

## 10. Failure Matrix

| Component Down | Impact | Mitigation |
|---|---|---|
| ZooKeeper (ID assignment) | Can't assign new machine IDs | Existing machines keep their IDs (cached locally). Only new machines affected. |
| NTP | Clock drift → non-monotonic IDs | Logical clock fallback. Alert on clock skew > threshold. |
