# Collections Internals

## 1. What & Why

**Java Collections Framework provides the data structures you use every day. Knowing the internals — not just the API — is what separates SDE-2 from SDE-1 in interviews. "HashMap is O(1)" is SDE-1. "HashMap uses separate chaining with treeification at 8 nodes, and the spread function mixes high bits into low bits because capacity is always a power of 2" is SDE-2.**

## 2. Core Concepts

### Collections Hierarchy

```
Iterable
└── Collection
    ├── List (ordered, allows duplicates)
    │   ├── ArrayList ✅ (default choice)
    │   ├── LinkedList (rarely used)
    │   ├── Vector (legacy, synchronized — don't use)
    │   └── Stack (legacy — use ArrayDeque)
    ├── Set (no duplicates)
    │   ├── HashSet ✅ (default choice, backed by HashMap)
    │   ├── LinkedHashSet (insertion order)
    │   └── TreeSet (sorted, red-black tree)
    └── Queue / Deque
        ├── ArrayDeque ✅ (stack + queue, default choice)
        ├── PriorityQueue (min-heap)
        └── LinkedList (implements both List and Deque)

Map (separate hierarchy, not Collection)
├── HashMap ✅ (default choice)
├── LinkedHashMap (insertion/access order, LRU cache)
├── TreeMap (sorted keys, red-black tree)
├── ConcurrentHashMap ✅ (thread-safe)
├── Hashtable (legacy, synchronized — don't use)
└── EnumMap (enum keys, array-backed, fastest)
```

### HashMap Internals [🔥 Must Know]

(Covered in depth in [01-dsa/01-arrays-strings-hashing.md](../01-dsa/01-arrays-strings-hashing.md))

**Quick reference:**
- Array of `Node<K,V>` buckets. Each bucket: linked list → red-black tree at 8 nodes (if capacity ≥ 64)
- Default capacity: **16**, load factor: **0.75**, treeify threshold: **8**, untreeify: **6**
- Hash spread: `hash = key.hashCode() ^ (hashCode >>> 16)` — mixes high bits into low bits
- Bucket index: `hash & (capacity - 1)` — bitwise AND (faster than modulo, works because capacity is power of 2)
- Resize: when `size > capacity × 0.75`, double capacity, rehash all entries

⚙️ **Under the Hood — Why Capacity Must Be Power of 2:**
`hash & (capacity - 1)` is equivalent to `hash % capacity` only when capacity is a power of 2. Bitwise AND is a single CPU instruction; modulo requires division (much slower). The spread function compensates for only using low bits of the hash.

**Key operations:**

| Operation | Average | Worst (Java 8+) | Notes |
|-----------|---------|-----------------|-------|
| `get(key)` | O(1) | O(log n) | Treeified bucket |
| `put(key, val)` | O(1) | O(log n) | May trigger resize O(n) |
| `remove(key)` | O(1) | O(log n) | |
| `containsKey` | O(1) | O(log n) | |
| `containsValue` | O(n) | O(n) | Must scan all buckets |

### ConcurrentHashMap [🔥 Must Know]

**Thread-safe HashMap without locking the entire map — uses CAS + per-bin synchronization for fine-grained concurrency.**

| Feature | HashMap | ConcurrentHashMap | Hashtable |
|---------|---------|-------------------|-----------|
| Thread-safe | No | Yes (CAS + per-bin sync) | Yes (global sync) |
| Null keys | 1 allowed | ❌ Not allowed | ❌ Not allowed |
| Null values | Allowed | ❌ Not allowed | ❌ Not allowed |
| Performance | Fastest (single-threaded) | Fast (concurrent) | Slow (global lock) |
| Iterator | Fail-fast | Weakly consistent | Fail-fast |

⚙️ **Under the Hood — ConcurrentHashMap (Java 8+):**

```
Java 7: Segment-based locking (16 segments, each with its own lock)
  → Only 16 concurrent writers max

Java 8+: CAS + synchronized on individual bins (buckets)
  → Concurrent writers limited only by number of buckets (thousands)
  
  put(key, value):
    1. Compute hash, find bucket
    2. If bucket is empty: CAS to insert (no lock needed)
    3. If bucket is occupied: synchronized(bucket_head) { insert into chain/tree }
    4. Only the specific bucket is locked — other buckets are unaffected

  get(key):
    No locking at all! Uses volatile reads for visibility.
    Reads are always lock-free → extremely fast.
```

**Atomic compound operations (why ConcurrentHashMap > synchronizedMap):**

```java
// WRONG with synchronizedMap — not atomic:
if (!map.containsKey(key)) {  // check
    map.put(key, value);       // then act — another thread might put between check and act!
}

// CORRECT with ConcurrentHashMap — atomic:
map.putIfAbsent(key, value);           // atomic check-and-put
map.computeIfAbsent(key, k -> new ArrayList<>()); // atomic check-and-compute
map.merge(key, 1, Integer::sum);       // atomic read-modify-write
```

🎯 **Likely Follow-ups:**
- **Q:** Why doesn't ConcurrentHashMap allow null keys/values?
  **A:** Ambiguity: if `get(key)` returns null, you can't tell if the key is absent or the value is null. In a concurrent context, you can't safely check `containsKey` then `get` (another thread might modify between the two calls). HashMap doesn't have this problem because it's single-threaded.
- **Q:** What are weakly consistent iterators?
  **A:** They reflect the state of the map at some point during or after iterator creation. They don't throw ConcurrentModificationException, but may or may not reflect concurrent modifications. This is acceptable for most use cases (you get a "snapshot-ish" view).

### ArrayList vs LinkedList

| Feature | ArrayList | LinkedList |
|---------|-----------|------------|
| Backing | Dynamic array (`Object[]`) | Doubly-linked list of `Node` objects |
| Random access | O(1) — direct index calculation | O(n) — must traverse from head/tail |
| Add at end | O(1) amortized (resize occasionally) | O(1) — append to tail |
| Add at index | O(n) — shift elements right | O(n) — find node O(n) + insert O(1) |
| Remove at index | O(n) — shift elements left | O(n) — find node O(n) + remove O(1) |
| Memory per element | ~4-8 bytes (reference in array) | ~32-40 bytes (Node object + prev/next pointers) |
| Cache performance | Excellent (contiguous memory) | Poor (nodes scattered in heap) |
| Implements | List | List + Deque |

**Almost always use ArrayList.** LinkedList is rarely better in practice due to cache performance. The only case for LinkedList: when you need a Deque AND a List simultaneously (rare).

💡 **Intuition — Why Cache Performance Matters So Much:**
ArrayList stores elements in a contiguous array. When the CPU reads element [0], it loads a cache line (~64 bytes = ~16 references) into L1 cache. Elements [1] through [15] are already in cache — free access. LinkedList nodes are scattered across the heap. Every `node.next` is a cache miss — the CPU must fetch from main memory (~100ns vs ~0.5ns for cache hit). For iteration, ArrayList can be 10-100x faster.

### TreeMap / TreeSet [🔥 Must Know]

- Red-black tree (self-balancing BST)
- O(log n) for get, put, remove, containsKey
- Keys must be `Comparable` or provide a `Comparator`
- **Power methods** (not available in HashMap):

```java
TreeMap<Integer, String> map = new TreeMap<>();
map.put(10, "a"); map.put(20, "b"); map.put(30, "c"); map.put(40, "d");

map.floorKey(25);    // 20 — greatest key ≤ 25
map.ceilingKey(25);  // 30 — smallest key ≥ 25
map.lowerKey(20);    // 10 — greatest key < 20 (strictly less)
map.higherKey(20);   // 30 — smallest key > 20 (strictly greater)
map.firstKey();      // 10 — minimum key
map.lastKey();       // 40 — maximum key
map.subMap(15, 35);  // {20=b, 30=c} — keys in range [15, 35)
map.headMap(25);     // {10=a, 20=b} — keys < 25
map.tailMap(25);     // {30=c, 40=d} — keys ≥ 25
```

💡 **When to use TreeMap over HashMap:** When you need sorted keys, range queries, floor/ceiling operations. Example: finding the nearest timestamp, scheduling intervals, implementing a calendar.

### PriorityQueue

- Min-heap by default (smallest element at top)
- O(log n) offer/poll, O(1) peek, O(n) remove(Object)
- NOT thread-safe (use `PriorityBlockingQueue` for concurrency)
- Iteration order is NOT sorted — only `poll()` returns elements in order
- No null elements

### Fail-Fast vs Fail-Safe Iterators [🔥 Frequently Asked]

| Type | Behavior | How | Examples |
|------|----------|-----|---------|
| Fail-fast | Throws `ConcurrentModificationException` if collection modified during iteration | Checks `modCount` field — incremented on structural modification | ArrayList, HashMap, HashSet |
| Fail-safe | No exception, works on a snapshot or concurrent structure | Uses copy (CopyOnWriteArrayList) or weakly consistent view (ConcurrentHashMap) | ConcurrentHashMap, CopyOnWriteArrayList |

```java
// Fail-fast — WRONG:
List<String> list = new ArrayList<>(List.of("a", "b", "c"));
for (String s : list) {
    if (s.equals("b")) list.remove(s); // ConcurrentModificationException!
}

// CORRECT options:
// 1. Iterator.remove()
Iterator<String> it = list.iterator();
while (it.hasNext()) { if (it.next().equals("b")) it.remove(); }

// 2. removeIf (Java 8+)
list.removeIf(s -> s.equals("b"));

// 3. CopyOnWriteArrayList (fail-safe, but copies on every write)
List<String> list = new CopyOnWriteArrayList<>(List.of("a", "b", "c"));
for (String s : list) { if (s.equals("b")) list.remove(s); } // no exception
```

### Immutable Collections (Java 9+)

```java
List<Integer> list = List.of(1, 2, 3);           // immutable, no nulls
Set<String> set = Set.of("a", "b", "c");          // immutable, no nulls, no duplicates
Map<String, Integer> map = Map.of("a", 1, "b", 2); // immutable, no nulls

list.add(4);    // UnsupportedOperationException!
list.set(0, 5); // UnsupportedOperationException!

// Mutable copy:
List<Integer> mutable = new ArrayList<>(List.of(1, 2, 3));
```

> 🔗 **See Also:** [01-dsa/01-arrays-strings-hashing.md](../01-dsa/01-arrays-strings-hashing.md) for HashMap deep dive with dry runs. [05-java/03-concurrency-multithreading.md](03-concurrency-multithreading.md) for ConcurrentHashMap in multi-threaded contexts. [04-lld/problems/cache-lru-lfu.md](../04-lld/problems/cache-lru-lfu.md) for LinkedHashMap-based LRU cache.

## 5. Must-Know Interview Questions

1. [🔥 Must Know] **Q:** How does HashMap work internally? **A:** Array of buckets. `hashCode()` → spread function → bucket index. Collisions: linked list → red-black tree at 8 nodes. Load factor 0.75 triggers 2x resize. Capacity always power of 2 for fast modulo (bitwise AND).

2. [🔥 Must Know] **Q:** HashMap vs ConcurrentHashMap? **A:** HashMap: not thread-safe, allows null key/values. ConcurrentHashMap: thread-safe via CAS + per-bin sync (Java 8+), no null keys/values, atomic compound operations (`computeIfAbsent`, `merge`), weakly consistent iterators.

3. [🔥 Must Know] **Q:** ArrayList vs LinkedList? **A:** Almost always ArrayList. O(1) random access, cache-friendly (contiguous memory). LinkedList: O(n) random access, poor cache performance, higher memory overhead. LinkedList only if you need Deque + List simultaneously.

4. [🔥 Must Know] **Q:** What is fail-fast iterator? **A:** Throws ConcurrentModificationException if collection is structurally modified during iteration (except via iterator's own `remove()`). Uses internal `modCount` field. Fix: use `Iterator.remove()`, `removeIf()`, or concurrent collections.

5. [🔥 Must Know] **Q:** How does HashSet work? **A:** It's literally a `HashMap<E, Object>` where every value is a dummy `PRESENT` object. `add(e)` calls `map.put(e, PRESENT)`. `contains(e)` calls `map.containsKey(e)`.

6. **Q:** TreeMap vs HashMap? **A:** HashMap: O(1) average, unordered. TreeMap: O(log n), sorted by keys, supports floor/ceiling/range queries. Use TreeMap when you need sorted iteration or range operations.

7. [🔥 Must Know] **Q:** What happens when two keys have the same hashCode? **A:** Collision. Both go to the same bucket. Stored in linked list (or red-black tree if ≥ 8). On `get()`, `equals()` is used to find the correct entry in the chain.

8. **Q:** Why is ConcurrentHashMap better than `Collections.synchronizedMap()`? **A:** `synchronizedMap` wraps every method in a global `synchronized` block — only one thread can access the map at a time. ConcurrentHashMap uses per-bin locking — multiple threads can read/write different buckets concurrently. Also, ConcurrentHashMap provides atomic compound operations.

## 7. Revision Checklist

- [ ] HashMap: array of buckets, linked list → tree at 8 (capacity ≥ 64), capacity 16, load 0.75, power-of-2 capacity
- [ ] HashMap spread: `hashCode ^ (hashCode >>> 16)`, index: `hash & (capacity - 1)`
- [ ] ConcurrentHashMap: CAS + per-bin sync (Java 8+), no null keys/values, atomic `computeIfAbsent`/`merge`
- [ ] ArrayList: dynamic array, O(1) access, O(n) insert, cache-friendly. Default choice.
- [ ] LinkedList: doubly-linked, O(1) add/remove at ends, poor cache performance. Rarely use.
- [ ] TreeMap: red-black tree, O(log n), sorted keys, `floorKey`/`ceilingKey`/`subMap`
- [ ] PriorityQueue: min-heap, O(log n) offer/poll, iteration NOT sorted
- [ ] HashSet = HashMap with dummy values
- [ ] Fail-fast: ConcurrentModificationException on structural modification during iteration (modCount)
- [ ] Fail-safe: ConcurrentHashMap (weakly consistent), CopyOnWriteArrayList (snapshot)
- [ ] Immutable: `List.of()`, `Set.of()`, `Map.of()` (Java 9+) — no nulls, no modification
- [ ] `Collections.synchronizedMap()` = global lock (slow). ConcurrentHashMap = per-bin lock (fast).
