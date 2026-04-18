# LLD: Cache (LRU & LFU)

## 1. Problem Statement
Design LRU and LFU cache implementations.

💡 **Why this is the most important LLD problem for DSA interviews:** LRU Cache (LC 146) is one of the most frequently asked LeetCode problems. It tests your ability to combine two data structures (HashMap + Doubly-Linked List) for O(1) operations. LFU is the harder variant that adds frequency tracking. Both appear in system design discussions (Redis eviction, CDN caching).

⚙️ **Under the Hood — Why HashMap + Doubly-Linked List:**
- HashMap gives O(1) key lookup → find the node instantly
- Doubly-linked list gives O(1) move-to-head and remove-from-tail → maintain access order
- Neither alone is sufficient: HashMap can't maintain order, linked list can't do O(1) lookup

> 🔗 **See Also:** [02-system-design/problems/distributed-cache.md](../../02-system-design/problems/distributed-cache.md) for distributed cache design using LRU. [01-dsa/01-arrays-strings-hashing.md](../../01-dsa/01-arrays-strings-hashing.md) for HashMap internals. [06-tech-stack/02-redis-deep-dive.md](../../06-tech-stack/02-redis-deep-dive.md) for Redis eviction policies (allkeys-lru, allkeys-lfu).

## 2. Requirements
- O(1) get and put operations
- Fixed capacity with eviction
- LRU: evict least recently used
- LFU: evict least frequently used (tie-break by LRU)

## 5. Complete Java Implementation

### LRU Cache [🔥 Must Do]

```java
// LC 146: LRU Cache
class LRUCache {
    private final int capacity;
    private final Map<Integer, Node> map = new HashMap<>();
    private final Node head = new Node(0, 0); // dummy head
    private final Node tail = new Node(0, 0); // dummy tail

    LRUCache(int capacity) {
        this.capacity = capacity;
        head.next = tail;
        tail.prev = head;
    }

    int get(int key) {
        if (!map.containsKey(key)) return -1;
        Node node = map.get(key);
        remove(node);
        addToHead(node);
        return node.value;
    }

    void put(int key, int value) {
        if (map.containsKey(key)) {
            Node node = map.get(key);
            node.value = value;
            remove(node);
            addToHead(node);
        } else {
            if (map.size() == capacity) {
                Node lru = tail.prev;
                remove(lru);
                map.remove(lru.key);
            }
            Node node = new Node(key, value);
            map.put(key, node);
            addToHead(node);
        }
    }

    private void addToHead(Node node) {
        node.next = head.next;
        node.prev = head;
        head.next.prev = node;
        head.next = node;
    }

    private void remove(Node node) {
        node.prev.next = node.next;
        node.next.prev = node.prev;
    }

    static class Node {
        int key, value;
        Node prev, next;
        Node(int key, int value) { this.key = key; this.value = value; }
    }
}
```

### LFU Cache

```java
// LC 460: LFU Cache
class LFUCache {
    private final int capacity;
    private int minFreq = 0;
    private final Map<Integer, Node> keyMap = new HashMap<>();
    private final Map<Integer, LinkedHashSet<Integer>> freqMap = new HashMap<>();

    LFUCache(int capacity) { this.capacity = capacity; }

    int get(int key) {
        if (!keyMap.containsKey(key)) return -1;
        Node node = keyMap.get(key);
        updateFreq(node);
        return node.value;
    }

    void put(int key, int value) {
        if (capacity == 0) return;
        if (keyMap.containsKey(key)) {
            Node node = keyMap.get(key);
            node.value = value;
            updateFreq(node);
        } else {
            if (keyMap.size() == capacity) {
                // Evict LFU (tie-break: LRU via LinkedHashSet iteration order)
                LinkedHashSet<Integer> minSet = freqMap.get(minFreq);
                int evictKey = minSet.iterator().next();
                minSet.remove(evictKey);
                keyMap.remove(evictKey);
            }
            Node node = new Node(key, value, 1);
            keyMap.put(key, node);
            freqMap.computeIfAbsent(1, k -> new LinkedHashSet<>()).add(key);
            minFreq = 1;
        }
    }

    private void updateFreq(Node node) {
        int freq = node.freq;
        freqMap.get(freq).remove(node.key);
        if (freqMap.get(freq).isEmpty() && freq == minFreq) minFreq++;
        node.freq++;
        freqMap.computeIfAbsent(node.freq, k -> new LinkedHashSet<>()).add(node.key);
    }

    static class Node { int key, value, freq; Node(int k, int v, int f) { key=k; value=v; freq=f; } }
}
```

## 6-8. Key Points
- LRU: HashMap + Doubly Linked List. O(1) get/put. Most recently used at head, evict from tail.
- LFU: HashMap + frequency buckets (LinkedHashSet for LRU tie-breaking). O(1) get/put. Track minFreq.
- Both are O(1) for all operations.
- LRU is simpler and more commonly used. LFU is better when access patterns have clear frequency differences.


---

### Concurrency & Thread Safety

**Thread-safe LRU cache:**
```java
// Multiple threads read and write the cache concurrently.

// Approach 1: ReadWriteLock (good read:write ratio)
class ThreadSafeLRUCache<K, V> {
    private final LRUCache<K, V> cache;
    private final ReadWriteLock lock = new ReentrantReadWriteLock();
    
    public V get(K key) {
        lock.writeLock().lock(); // write lock because get() updates access order
        try { return cache.get(key); }
        finally { lock.writeLock().unlock(); }
    }
    // Note: even get() needs write lock because it moves the node to head (LRU update).
    // This makes ReadWriteLock less useful for LRU. Use approach 2 instead.
}

// Approach 2: ConcurrentHashMap + striped locks (better throughput)
class ConcurrentLRUCache<K, V> {
    private final int NUM_STRIPES = 16;
    private final LRUCache<K, V>[] stripes;
    
    public V get(K key) {
        int stripe = Math.abs(key.hashCode() % NUM_STRIPES);
        synchronized (stripes[stripe]) {
            return stripes[stripe].get(key);
        }
    }
    // Each stripe is an independent LRU cache. Reduces contention by 16x.
}

// Approach 3: Java's LinkedHashMap with Collections.synchronizedMap (simplest)
Map<K, V> cache = Collections.synchronizedMap(
    new LinkedHashMap<>(capacity, 0.75f, true) { // accessOrder=true for LRU
        protected boolean removeEldestEntry(Map.Entry<K, V> eldest) {
            return size() > capacity;
        }
    }
);
```
