> ✅ **[CORE] — Must-do for SDE-2 interviews.**

# Arrays, Strings & Hashing

## 1. Foundation

### Arrays

**An array is a fixed-size, contiguous block of memory where every element lives right next to the other — this is what gives you instant access to any element by index.**

Every other data structure is built on top of arrays (or linked nodes). An array gives you the most fundamental guarantee in computing: **O(1) random access by index**. The CPU can compute the memory address of any element in constant time because elements are stored contiguously: `address = base + (index × element_size)`.

💡 **Intuition:** Think of an array like a row of numbered lockers in a hallway. If someone says "open locker 47," you don't need to walk past lockers 1-46 — you just calculate where locker 47 is and go straight there. That's O(1) access. A linked list, by contrast, is like a treasure hunt where each clue tells you where the next clue is — you must follow the chain.

**Internal workings:**
- Contiguous block of memory allocated on the heap (in Java)
- Fixed size at creation — cannot grow or shrink
- Elements are stored sequentially, enabling CPU cache-line prefetching (arrays are cache-friendly)
- In Java, `int[]` stores primitives directly; `Integer[]` and `String[]` store references (pointers to heap objects)

⚙️ **Under the Hood — Why Arrays Are Cache-Friendly:**
When the CPU reads `arr[0]`, it doesn't just fetch that one element. It loads an entire **cache line** (typically 64 bytes) into L1 cache. For an `int[]`, that's 16 consecutive integers loaded at once. So when you access `arr[1]`, `arr[2]`, etc., they're already in cache — no main memory trip needed. This is called **spatial locality** and it's why iterating over an array is 10-100x faster than iterating over a linked list (where nodes are scattered across the heap).

```
Memory layout of int[] arr = {10, 20, 30, 40}:

Address:  0x100  0x104  0x108  0x10C
Value:    [ 10 ] [ 20 ] [ 30 ] [ 40 ]
           ↑ base address

arr[2] address = 0x100 + (2 × 4 bytes) = 0x108 → instant lookup
```

**Java arrays vs ArrayList:**

| Feature | `int[]` / `String[]` | `ArrayList<T>` |
|---------|----------------------|-----------------|
| Size | Fixed at creation | Dynamic (grows by ~50%) |
| Primitives | Yes (`int[]`) | No (autoboxing → `Integer`) |
| Memory | Compact | Overhead per element (object headers) |
| Thread-safe | No | No (`Collections.synchronizedList` or `CopyOnWriteArrayList`) |
| Null elements | Yes | Yes |
| Performance | Faster (no boxing) | Slightly slower |
| Use when | Size known, performance-critical | Size unknown, need dynamic resizing |

**ArrayList internals** [🔥 Must Know]:
- Backed by `Object[] elementData`
- Default initial capacity: **10**
- Growth: `newCapacity = oldCapacity + (oldCapacity >> 1)` → ~1.5x
- `add()` is amortized O(1), but a single add can be O(n) when resizing triggers `Arrays.copyOf`
- `add(index, element)` is O(n) — shifts elements right
- `remove(index)` is O(n) — shifts elements left
- `get(index)` is O(1)

⚙️ **Under the Hood — ArrayList Resizing Step by Step:**

```
Initial: capacity=10, size=0, elementData = [_, _, _, _, _, _, _, _, _, _]

After 10 adds: capacity=10, size=10, elementData = [a, b, c, d, e, f, g, h, i, j]

11th add triggers resize:
  1. newCapacity = 10 + (10 >> 1) = 10 + 5 = 15
  2. Allocate new Object[15]
  3. System.arraycopy(old, 0, new, 0, 10)  ← O(n) operation
  4. elementData = new array
  5. elementData[10] = newElement

Resize history: 10 → 15 → 22 → 33 → 49 → 73 → 109 → ...
```

**Why amortized O(1)?** If you add n elements, resizing happens at sizes 10, 15, 22, 33, ... The total copy work across all resizes is roughly 2n (geometric series). Spread across n operations, that's O(1) per operation on average. This is the same amortized analysis used in dynamic arrays across all languages.

🎯 **Likely Follow-ups:**
- **Q:** Why does ArrayList grow by 1.5x and not 2x?
  **A:** 1.5x balances memory waste vs copy frequency. With 2x growth, you waste up to 50% of allocated memory. With 1.5x, worst case waste is ~33%. The JDK team benchmarked this — 1.5x hits the sweet spot for most workloads.
- **Q:** What happens if you call `add(0, element)` repeatedly on an ArrayList?
  **A:** Each insertion shifts all existing elements right — O(n) per call. For n insertions at index 0, total work is O(n²). Use a `LinkedList` or `ArrayDeque` if you need frequent head insertions.
- **Q:** How would you implement a thread-safe dynamic array?
  **A:** `Collections.synchronizedList(new ArrayList<>())` wraps every method in a `synchronized` block — simple but coarse-grained. `CopyOnWriteArrayList` creates a new array on every write — great for read-heavy workloads, terrible for write-heavy ones.

**Operations complexity:**

| Operation | Array | ArrayList | Notes |
|-----------|-------|-----------|-------|
| Access by index | O(1) | O(1) | Direct address calculation |
| Search (unsorted) | O(n) | O(n) | Linear scan |
| Search (sorted) | O(log n) | O(log n) | Binary search |
| Insert at end | — | O(1) amortized | Resize cost occasionally |
| Insert at index | O(n) | O(n) | Shift elements right |
| Delete at index | O(n) | O(n) | Shift elements left |
| Delete at end | — | O(1) | No shifting needed |

### Strings

**A String in Java is an immutable array of characters — every time you "modify" a string, you're actually creating a brand new object.**

Strings are arrays of characters with extra constraints — immutability in Java, Unicode handling, and a rich API that can make or break your solution's complexity. They appear in nearly every interview round.

💡 **Intuition:** Think of a Java String like a printed page. You can't erase a word on a printed page — you have to print a whole new page with the change. That's why `s += "x"` in a loop is O(n²) — you're "reprinting" the entire string every iteration. `StringBuilder` is like a whiteboard — you can append, erase, and modify in place.

**Java String internals** [🔥 Must Know]:
- `String` is **immutable** — every modification creates a new object
- Backed by `byte[]` (since Java 9; was `char[]` before) with a `coder` field (LATIN1 or UTF16)
- **String Pool**: string literals are interned in a pool in the heap. `"abc" == "abc"` is `true`, but `new String("abc") == "abc"` is `false`
- `s1.equals(s2)` compares content; `==` compares references
- String concatenation in a loop: **O(n²)** — use `StringBuilder` instead

⚙️ **Under the Hood — Compact Strings (Java 9+):**
Before Java 9, every `String` used a `char[]` where each character took 2 bytes (UTF-16). But most strings in real applications are ASCII/Latin-1 (1 byte per char). Java 9 introduced **Compact Strings**: if all characters fit in Latin-1, the backing `byte[]` uses 1 byte per character. The `coder` field tracks which encoding is used. This saves ~50% memory for typical English text.

```
"hello" in Java 8:  char[] = [h, e, l, l, o]  → 10 bytes (2 per char)
"hello" in Java 9+: byte[] = [h, e, l, l, o]  → 5 bytes (1 per char, LATIN1)
"héllo" in Java 9+: byte[] = [h, é, l, l, o]  → 10 bytes (2 per char, UTF16)
```

⚙️ **Under the Hood — String Pool and Interning:**

```java
String s1 = "hello";           // Goes to String Pool
String s2 = "hello";           // Reuses same object from Pool
String s3 = new String("hello"); // New object on heap (NOT in pool)
String s4 = s3.intern();       // Puts s3's value in pool, returns pool reference

System.out.println(s1 == s2);  // true  — same pool reference
System.out.println(s1 == s3);  // false — different objects
System.out.println(s1 == s4);  // true  — intern() returns pool reference
```

The String Pool lives in the heap (moved from PermGen in Java 7). It uses a hashtable internally. `intern()` is useful when you have many duplicate strings (e.g., parsing CSV with repeated column values) — it deduplicates memory.

**StringBuilder vs StringBuffer:**

| Feature | StringBuilder | StringBuffer |
|---------|--------------|--------------|
| Thread-safe | No | Yes (synchronized) |
| Performance | Faster | Slower (lock overhead) |
| Use when | Single-threaded (almost always) | Multi-threaded (rare in practice) |
| Default capacity | 16 characters | 16 characters |
| Growth | Doubles + 2: `(old + 1) * 2` | Same formula |

**Critical pitfall — string concatenation in loops:**

```java
// BAD — O(n²) because each += creates a new String
// For n=100,000 strings of avg length 10:
//   Total chars copied: 10 + 20 + 30 + ... + 1,000,000 = ~50 billion chars
String result = "";
for (int i = 0; i < n; i++) {
    result += arr[i]; // new String object every iteration
}

// GOOD — O(n) total
StringBuilder sb = new StringBuilder();
for (int i = 0; i < n; i++) {
    sb.append(arr[i]); // appends to internal buffer, resizes only when needed
}
String result = sb.toString();
```

⚠️ **Common Pitfall — Compiler Optimization Myth:**
The Java compiler does optimize `s1 + s2` into `new StringBuilder().append(s1).append(s2).toString()` for single-line concatenation. But inside a loop, it creates a NEW StringBuilder each iteration — so the loop is still O(n²). Don't rely on compiler magic for loops.

**Key String methods and their complexity:**

| Method | Time | Notes |
|--------|------|-------|
| `charAt(i)` | O(1) | Direct array access |
| `length()` | O(1) | Stored field |
| `substring(i, j)` | O(j-i) | Creates new String (since Java 7u6) |
| `equals()` | O(n) | Compares char by char |
| `indexOf()` | O(n*m) | Naive search; m = pattern length |
| `toCharArray()` | O(n) | Creates new array — allocates memory |
| `split()` | O(n) | Uses regex internally — can be slow |
| `trim()` | O(n) | Scans from both ends |
| `compareTo()` | O(min(n,m)) | Lexicographic comparison |
| `contains()` | O(n*m) | Delegates to indexOf() |
| `replace()` | O(n) | Creates new String |
| `toLowerCase()` | O(n) | Creates new String |

🎯 **Likely Follow-ups:**
- **Q:** Why is String immutable in Java?
  **A:** Three reasons: (1) Thread safety — immutable objects are inherently thread-safe, no synchronization needed. (2) String Pool — interning only works if strings can't change after creation. (3) Security — strings are used for class loading, network connections, file paths. If they were mutable, a reference could be changed after a security check.
- **Q:** What's the time complexity of `String.substring()` in Java 6 vs Java 7+?
  **A:** In Java 6, `substring()` was O(1) — it shared the same `char[]` with the original string and just stored different offset/length. This caused memory leaks (a small substring could keep a huge char[] alive). Java 7u6 changed it to O(n) — it copies the characters into a new array.
- **Q:** When would you use `String.intern()`?
  **A:** When you're processing large datasets with many duplicate strings (e.g., parsing log files where the same IP addresses repeat millions of times). Interning deduplicates them in the String Pool. But be careful — the pool has a fixed-size hashtable, and too many interned strings can cause GC pressure.

### Hashing

**Hashing is a technique that converts any key into an array index in O(1) average time — it's the engine behind HashMap, HashSet, and most "optimize from O(n²) to O(n)" interview solutions.**

We need a way to map arbitrary keys to array indices in O(1) average time. Hashing converts a key into an integer (hash code), then maps that integer to a bucket index.

💡 **Intuition:** Imagine a library with 1000 shelves. Instead of searching every shelf for a book, you run the book's title through a formula that tells you "shelf 347." You go directly there. Occasionally two books map to the same shelf (collision), so you keep a small list on that shelf. As long as the formula distributes books evenly, most shelves have 0-1 books, and lookup is instant.

**How HashMap works internally** [🔥 Must Know]:

1. **Hash function**: `key.hashCode()` returns an `int`. HashMap then applies a "spread" function: `hash = hashCode ^ (hashCode >>> 16)` — this mixes high bits into low bits to reduce collisions when the table size is a power of 2.

2. **Bucket index**: `index = hash & (capacity - 1)` — equivalent to `hash % capacity` when capacity is a power of 2, but faster (bitwise AND vs modulo).

3. **Collision handling**:
   - **Separate chaining**: each bucket is a linked list of `Node<K,V>` entries
   - **Treeification** (Java 8+): when a bucket has ≥ **8** entries AND table capacity ≥ **64**, the linked list converts to a **red-black tree** → worst-case lookup goes from O(n) to O(log n)
   - **Untreeification**: when a bucket shrinks to ≤ **6** entries, it converts back to a linked list
   - The gap between 8 (treeify) and 6 (untreeify) prevents thrashing between list and tree

4. **Resizing**: when `size > capacity × loadFactor` (default loadFactor = **0.75**), the table doubles in size and all entries are rehashed. Default initial capacity = **16**.

5. **Lookup**: compute hash → find bucket → traverse chain/tree comparing `equals()` → return value or null.

⚙️ **Under the Hood — HashMap Put Operation Step by Step:**

```
put("alice", 100) on a HashMap with capacity=16, loadFactor=0.75:

Step 1: hashCode("alice") = 92668751
Step 2: spread: 92668751 ^ (92668751 >>> 16) = 92667337
Step 3: bucket index: 92667337 & (16-1) = 92667337 & 15 = 9
Step 4: Go to bucket[9]
  - If empty: create new Node("alice", 100), place in bucket[9]
  - If occupied: traverse chain
    - For each node: if node.hash == hash AND node.key.equals("alice")
      → replace value, return old value
    - If no match: append new Node to end of chain
Step 5: size++. If size > 16 * 0.75 = 12, trigger resize to capacity=32
```

```
HashMap internal structure (capacity=8):

bucket[0]: null
bucket[1]: [Node("cat",1)] → null
bucket[2]: null
bucket[3]: [Node("dog",2)] → [Node("fox",3)] → null   ← collision chain
bucket[4]: null
bucket[5]: [Node("ant",4)] → null
bucket[6]: null
bucket[7]: null

After treeification (bucket[3] reaches 8+ nodes AND capacity ≥ 64):
bucket[3]: RedBlackTree { "dog":2, "fox":3, "bat":5, ... }
```

⚙️ **Under the Hood — Why Power-of-2 Capacity?**
HashMap always keeps capacity as a power of 2 (16, 32, 64, ...). This allows using `hash & (capacity - 1)` instead of `hash % capacity`. Bitwise AND is a single CPU instruction; modulo requires division (much slower). The spread function (`hashCode ^ (hashCode >>> 16)`) compensates for the fact that only the low bits of the hash are used when capacity is small.

**HashMap complexity:**

| Operation | Average | Worst (pre-Java 8) | Worst (Java 8+) |
|-----------|---------|---------------------|------------------|
| `get` | O(1) | O(n) | O(log n) |
| `put` | O(1) | O(n) | O(log n) |
| `remove` | O(1) | O(n) | O(log n) |
| `containsKey` | O(1) | O(n) | O(log n) |
| `containsValue` | O(n) | O(n) | O(n) |

**When O(1) breaks** [🔥 Must Know]:
- All keys hash to the same bucket (pathological input — e.g., adversarial hash collision attacks)
- Poor `hashCode()` implementation (e.g., always returns 0 — everything goes to bucket 0)
- Resizing: a single `put` can trigger O(n) rehash (but amortized O(1) over many puts)
- Very high load factor: more collisions, longer chains

**HashSet internals:** `HashSet` is literally a `HashMap<E, Object>` where every value is a dummy `PRESENT` object. All operations delegate to the underlying HashMap. This is why `HashSet.add(e)` returns `false` if the element already exists — it's checking if `HashMap.put(e, PRESENT)` returned a non-null previous value.

**LinkedHashMap:** Maintains insertion order via a doubly-linked list threading through all entries. Each `Entry` has `before` and `after` pointers in addition to the hash chain. Useful for LRU cache implementation (override `removeEldestEntry`).

```java
// LRU Cache in 5 lines using LinkedHashMap
Map<Integer, Integer> lru = new LinkedHashMap<>(16, 0.75f, true) { // true = access-order
    @Override
    protected boolean removeEldestEntry(Map.Entry<Integer, Integer> eldest) {
        return size() > CAPACITY; // evict oldest when over capacity
    }
};
```

**TreeMap:** Red-black tree. All operations O(log n). Keys must be `Comparable` or you provide a `Comparator`. Use when you need sorted keys, floor/ceiling operations, or range queries.

**Choosing the right Map:**

| Need | Use | Why |
|------|-----|-----|
| Fast lookup, no ordering | `HashMap` | O(1) average, lowest overhead |
| Insertion order | `LinkedHashMap` | O(1) + maintains order via linked list |
| Sorted keys | `TreeMap` | O(log n), red-black tree, supports range queries |
| Thread-safe | `ConcurrentHashMap` | Lock striping, no global lock |
| Enum keys | `EnumMap` | Array-backed, fastest possible for enum keys |
| Weak references | `WeakHashMap` | Keys eligible for GC when no strong references |

| Approach | Pros | Cons | Best When |
|----------|------|------|-----------|
| `HashMap` | O(1) ops, simple | No ordering, not thread-safe | Default choice for key-value lookup |
| `TreeMap` | Sorted, range queries | O(log n) ops, more memory | Need floor/ceiling/subMap |
| `LinkedHashMap` | Insertion/access order | Slightly more memory than HashMap | LRU cache, ordered iteration |
| `ConcurrentHashMap` | Thread-safe, high throughput | More complex, no null keys/values | Multi-threaded applications |

**hashCode/equals contract** [🔥 Must Know]:
- If `a.equals(b)` is `true`, then `a.hashCode() == b.hashCode()` must be `true`
- If `a.hashCode() == b.hashCode()`, `a.equals(b)` may or may not be `true` (collision)
- If you override `equals()`, you **must** override `hashCode()` — otherwise HashMap breaks

⚠️ **Common Pitfall — Breaking the Contract:**

```java
// BROKEN: overrides equals() but not hashCode()
class Employee {
    String name;
    int id;

    @Override
    public boolean equals(Object o) {
        if (this == o) return true;
        if (!(o instanceof Employee)) return false;
        Employee e = (Employee) o;
        return id == e.id && name.equals(e.name);
    }
    // Missing hashCode()! Default hashCode() uses memory address.
    // Two equal Employee objects will have different hashCodes
    // → HashMap.get() will look in the WRONG bucket → returns null
}

// FIXED:
@Override
public int hashCode() {
    return Objects.hash(name, id); // consistent with equals()
}
```

🎯 **Likely Follow-ups:**
- **Q:** Why does HashMap use a load factor of 0.75?
  **A:** It's a trade-off between space and time. Lower load factor (e.g., 0.5) means fewer collisions but wastes 50% of memory. Higher load factor (e.g., 1.0) uses memory efficiently but increases collision probability. 0.75 was chosen empirically — with a good hash function, the average chain length at 75% load is about 0.5, meaning most buckets have 0 or 1 entries.
- **Q:** What happens if you use a mutable object as a HashMap key and then modify it?
  **A:** The hashCode changes, but the object is still in the old bucket. `get()` computes the new hash, looks in the wrong bucket, and returns null. The entry becomes "orphaned" — it exists in the map but is unreachable. This is a subtle memory leak. Always use immutable objects as map keys.
- **Q:** How does ConcurrentHashMap differ from `Collections.synchronizedMap()`?
  **A:** `synchronizedMap` wraps every method in a single `synchronized` block — only one thread can access the map at a time. `ConcurrentHashMap` uses lock striping (Java 7: segment locks, Java 8: per-bucket CAS + synchronized on individual bins) — multiple threads can read/write different buckets concurrently. ConcurrentHashMap also supports atomic operations like `computeIfAbsent()`.

> 🔗 **See Also:** [05-java/02-collections-internals.md](../05-java/02-collections-internals.md) for deeper HashMap/ConcurrentHashMap internals, [04-lld/problems/cache-lru-lfu.md](../04-lld/problems/cache-lru-lfu.md) for LinkedHashMap-based LRU cache design.


---

## 2. Core Patterns

### Pattern 1: Frequency Counting (HashMap)

**Count how many times each element appears — the bread and butter of array/string problems.**

**When to recognize it:** Problem asks about duplicates, anagrams, most/least frequent element, character counts, or "appears exactly k times."

💡 **Intuition:** Frequency counting is like tallying votes. You walk through the ballot box once, keeping a running count for each candidate. At the end, you know exactly who got how many votes — without ever going back to recount.

**Approach:**
1. Iterate through the input
2. Build a frequency map: `Map<Key, Integer>`
3. Query the map for the answer

**Java code template:**

```java
public Map<Character, Integer> buildFrequencyMap(String s) {
    Map<Character, Integer> freq = new HashMap<>();
    for (char c : s.toCharArray()) {
        freq.merge(c, 1, Integer::sum); // cleaner than getOrDefault
    }
    return freq;
}

// Alternative using getOrDefault (more readable for some):
for (char c : s.toCharArray()) {
    freq.put(c, freq.getOrDefault(c, 0) + 1);
}

// For lowercase English letters only — use int[26] (faster, no boxing):
int[] count = new int[26];
for (char c : s.toCharArray()) {
    count[c - 'a']++;
}
```

**When to use `int[26]` vs `HashMap`:**

| Approach | Pros | Cons | Best When |
|----------|------|------|-----------|
| `int[26]` | No boxing, cache-friendly, O(1) space | Only works for fixed small key space | Lowercase letters, digits |
| `HashMap<Character, Integer>` | Works for any key type | Boxing overhead, hash computation | Unicode, arbitrary keys |
| `int[128]` | Covers all ASCII | Wastes space if few distinct chars | ASCII character problems |

**Variations:**
- Count frequency of words → `Map<String, Integer>`
- Count frequency of array elements → `Map<Integer, Integer>`
- Group by frequency → build freq map, then invert it: `Map<Integer, List<Key>>`
- Check if two strings are anagrams → compare frequency maps (or sort both)
- Top K frequent → frequency map + min-heap of size K (or bucket sort)

**Complexity:** O(n) time, O(k) space where k = number of distinct elements.

**Example walkthrough — LC 242: Valid Anagram** [🔥 Must Do]

> Given two strings `s` and `t`, return `true` if `t` is an anagram of `s`.

**Brute force:** Sort both strings, compare. O(n log n) time, O(n) space.

**Optimized — frequency counting:**

```java
public boolean isAnagram(String s, String t) {
    if (s.length() != t.length()) return false; // quick reject

    int[] count = new int[26]; // fixed-size array beats HashMap for lowercase letters
    for (int i = 0; i < s.length(); i++) {
        count[s.charAt(i) - 'a']++;  // increment for s
        count[t.charAt(i) - 'a']--;  // decrement for t
    }
    for (int c : count) {
        if (c != 0) return false; // any non-zero means mismatch
    }
    return true;
}
```

**Dry run:** `s = "anagram"`, `t = "nagaram"`

```
Initial count[26] = all zeros

Processing each character pair:
i=0: s='a'(0), t='n'(13) → count[0]=+1, count[13]=-1
i=1: s='n'(13), t='a'(0) → count[13]=0, count[0]=0
i=2: s='a'(0), t='g'(6) → count[0]=+1, count[6]=-1
i=3: s='g'(6), t='a'(0) → count[6]=0, count[0]=0
i=4: s='r'(17), t='r'(17) → count[17]=+1, count[17]=0
i=5: s='a'(0), t='a'(0) → count[0]=+1, count[0]=0
i=6: s='m'(12), t='m'(12) → count[12]=+1, count[12]=0

Final: all counts are 0 → return true
```

- Time: O(n), Space: O(1) (fixed 26-element array)

**Why `int[26]` over HashMap:** When the key space is small and known (e.g., lowercase English letters), a fixed array is faster — no hashing overhead, no boxing, cache-friendly. The array approach also avoids HashMap's constant factor overhead (Node objects, linked list pointers).

**Edge Cases:**
- ☐ Empty strings → both empty = true, one empty = false (caught by length check)
- ☐ Single character → trivially works
- ☐ Unicode characters → use `HashMap<Character, Integer>` instead of `int[26]`
- ☐ Strings with spaces → spaces are valid characters, count them too

🎯 **Likely Follow-ups:**
- **Q:** What if the input contains Unicode characters?
  **A:** Replace `int[26]` with `HashMap<Character, Integer>`. The algorithm stays the same, but you can't use a fixed-size array because the character space is too large (1.1M+ Unicode code points).
- **Q:** Can you solve this with a single counter variable instead of an array?
  **A:** No — a single counter can't distinguish between "same characters in different quantities" and "different characters that happen to balance out." You need per-character tracking.
- **Q:** How would you check if two very large files are anagrams of each other?
  **A:** Stream both files character by character, maintaining a single frequency map. Increment for file 1, decrement for file 2. At the end, all counts should be zero. This uses O(k) memory where k is the alphabet size, regardless of file size.

---

### Pattern 2: Two-Pass HashMap (Index Mapping)

**Store values you've seen so far in a HashMap, so you can instantly check if the "missing piece" exists — turning O(n²) brute force into O(n).**

**When to recognize it:** Problem asks "find two elements that satisfy a condition" or "find the index of an element" — and brute force is O(n²) nested loops.

💡 **Intuition:** Imagine you're at a party looking for someone whose age plus yours equals 100. Brute force: ask every person their age, then check every other person. Smart way: as you meet each person, write their age on a sticky note and put it on a board. When you meet someone new, check the board for `100 - their_age`. If it's there, you found your pair.

**Approach:**
1. First pass (or single pass): store `value → index` in a HashMap
2. For each element, check if the complement/target exists in the map

**Java code template:**

```java
// Single-pass variant (most common and preferred)
public int[] twoSum(int[] nums, int target) {
    Map<Integer, Integer> seen = new HashMap<>(); // value → index
    for (int i = 0; i < nums.length; i++) {
        int complement = target - nums[i];
        if (seen.containsKey(complement)) {
            return new int[]{seen.get(complement), i};
        }
        seen.put(nums[i], i); // add AFTER checking — avoids using same element twice
    }
    return new int[]{}; // no solution found
}
```

**Why single-pass works:** We add elements to the map as we go. When we reach element `nums[i]`, all elements before index `i` are already in the map. If the complement exists among them, we find it. If the complement comes later, it will find `nums[i]` when it's processed.

**Variations:**
- Two Sum → find pair with given sum
- Two Sum II (sorted array) → two pointers instead of HashMap (O(1) space)
- Subarray Sum Equals K → prefix sum + HashMap (see Pattern 4)
- Longest substring without repeating characters → HashMap storing last index of each character
- Two Sum with multiple pairs → store all indices in `Map<Integer, List<Integer>>`

**Complexity:** O(n) time, O(n) space.

**Example walkthrough — LC 1: Two Sum** [🔥 Must Do]

> Given `nums = [2, 7, 11, 15]`, `target = 9`, return indices `[0, 1]`.

**Brute force:** Check all pairs. O(n²).

**Optimized — single-pass HashMap:**

```
i=0: nums[0]=2, complement=9-2=7, seen={} → 7 not found. Add {2→0}
i=1: nums[1]=7, complement=9-7=2, seen={2→0} → 2 FOUND at index 0!
Return [0, 1]
```

**Edge Cases:**
- ☐ Array with exactly 2 elements → works directly
- ☐ Negative numbers → complement calculation still works
- ☐ Duplicate values → HashMap stores latest index, but we check before inserting
- ☐ No solution exists → return empty array (clarify with interviewer)
- ☐ Target is double of an element → e.g., `[3, 3]`, target=6. Works because we check before inserting current element

🎯 **Likely Follow-ups:**
- **Q:** What if there are multiple valid pairs?
  **A:** The basic HashMap approach finds the first pair. To find all pairs, use `Map<Integer, List<Integer>>` to store all indices for each value, then collect all valid pairs.
- **Q:** What if the array is sorted?
  **A:** Use two pointers (left and right) instead of HashMap — O(1) space. If `nums[left] + nums[right] < target`, move left right. If greater, move right left.
- **Q:** Can you solve Three Sum using this pattern?
  **A:** Yes — fix one element, then run Two Sum on the rest. But the standard approach for 3Sum (LC 15) is sort + two pointers, which handles duplicates more cleanly.

> 🔗 **See Also:** [01-dsa/02-two-pointers-sliding-window.md](02-two-pointers-sliding-window.md) for the two-pointer variant of Two Sum on sorted arrays.

---

### Pattern 3: Grouping / Bucketing

**Group elements by a computed key — anything that shares the same key goes into the same bucket.**

**When to recognize it:** Problem asks to "group elements by some property" — anagrams, same frequency, same digit sum, etc.

💡 **Intuition:** Think of sorting mail at a post office. You don't compare every letter to every other letter. You compute the zip code (the key), and drop each letter into the matching bin. At the end, each bin contains all letters for that zip code.

**Approach:**
1. Define a key function that maps each element to its group
2. Use `Map<Key, List<Element>>` to collect groups

**Java code template:**

```java
// Group Anagrams — LC 49 [🔥 Must Do]
public List<List<String>> groupAnagrams(String[] strs) {
    Map<String, List<String>> groups = new HashMap<>();
    for (String s : strs) {
        char[] chars = s.toCharArray();
        Arrays.sort(chars);
        String key = new String(chars); // sorted string as key — all anagrams sort to same string
        groups.computeIfAbsent(key, k -> new ArrayList<>()).add(s);
    }
    return new ArrayList<>(groups.values());
}
```

**Alternative key (faster for long strings):** Use character frequency as key:

```java
private String frequencyKey(String s) {
    int[] count = new int[26];
    for (char c : s.toCharArray()) count[c - 'a']++;
    // "2#1#0#0#..." format — unique for each anagram group
    StringBuilder sb = new StringBuilder();
    for (int i = 0; i < 26; i++) {
        sb.append(count[i]).append('#');
    }
    return sb.toString();
}
// Key for "eat" = "1#0#0#0#1#0#0#0#0#0#0#0#0#0#0#0#0#0#0#1#0#0#0#0#0#0#"
// Key for "tea" = "1#0#0#0#1#0#0#0#0#0#0#0#0#0#0#0#0#0#0#1#0#0#0#0#0#0#"  ← same!
```

**Complexity comparison:**

| Key Strategy | Time per Key | Total Time | When to Use |
|-------------|-------------|------------|-------------|
| Sort chars | O(k log k) | O(n × k log k) | Short strings (k < 20) |
| Frequency string | O(k) | O(n × k) | Long strings |
| Frequency array as key | O(k) | O(n × k) | If language supports array hashing |

Where k = max string length, n = number of strings.

**Dry run:** `strs = ["eat", "tea", "tan", "ate", "nat", "bat"]`

```
"eat" → sort → "aet" → groups: {"aet": ["eat"]}
"tea" → sort → "aet" → groups: {"aet": ["eat", "tea"]}
"tan" → sort → "ant" → groups: {"aet": ["eat", "tea"], "ant": ["tan"]}
"ate" → sort → "aet" → groups: {"aet": ["eat", "tea", "ate"], "ant": ["tan"]}
"nat" → sort → "ant" → groups: {"aet": ["eat", "tea", "ate"], "ant": ["tan", "nat"]}
"bat" → sort → "abt" → groups: {"aet": ["eat", "tea", "ate"], "ant": ["tan", "nat"], "abt": ["bat"]}

Result: [["eat","tea","ate"], ["tan","nat"], ["bat"]]
```

**Edge Cases:**
- ☐ Empty string `""` → sorts to `""`, groups with other empty strings
- ☐ Single-character strings → each is its own anagram group (unless duplicates)
- ☐ All strings are anagrams of each other → one big group
- ☐ All strings are unique (no anagrams) → each in its own group

🎯 **Likely Follow-ups:**
- **Q:** How would you group anagrams in a distributed system with billions of strings?
  **A:** MapReduce: the map phase computes the sorted key for each string, the reduce phase collects all strings with the same key. The key design (sorted string or frequency string) determines the shuffle/sort cost.
- **Q:** What if strings contain Unicode characters?
  **A:** The sorting approach still works (sort by Unicode code point). The frequency approach needs a `HashMap<Character, Integer>` instead of `int[26]`, and the key becomes a serialized map.

---

### Pattern 4: Prefix Sum + HashMap [🔥 Must Know]

**Keep a running total as you scan the array. If the running total at position j minus the running total at position i equals your target, then the subarray between i and j has that target sum.**

**When to recognize it:** Problem involves subarrays with a given sum, count of subarrays, or "contiguous subarray" with some sum property. This is one of the most powerful and frequently tested patterns.

💡 **Intuition:** Imagine you're tracking your bank balance day by day. Your balance on day 5 is $500, and on day 2 it was $300. That means you earned $200 between days 3-5 — without adding up each day individually. That's prefix sum: `balance[5] - balance[2] = sum of days 3 to 5`.

**Core insight:** If `prefixSum[j] - prefixSum[i] == k`, then the subarray `[i+1 ... j]` has sum `k`. So for each index `j`, we need to check if `prefixSum[j] - k` has been seen before.

```
Array:      [1,  2,  3, -1,  4]
PrefixSum:  [1,  3,  6,  5,  9]
             ↑           ↑
             i=0         j=3

prefixSum[3] - prefixSum[0] = 5 - 1 = 4
→ subarray [2, 3, -1] (indices 1 to 3) has sum 4
```

**Approach:**
1. Maintain a running prefix sum
2. Store `prefixSum → count` in a HashMap
3. At each index, check if `currentSum - target` exists in the map

**Java code template:**

```java
// LC 560: Subarray Sum Equals K [🔥 Must Do]
public int subarraySum(int[] nums, int k) {
    Map<Integer, Integer> prefixCount = new HashMap<>();
    prefixCount.put(0, 1); // CRITICAL: empty prefix — handles subarray starting at index 0
    int sum = 0, count = 0;

    for (int num : nums) {
        sum += num;                                          // running prefix sum
        count += prefixCount.getOrDefault(sum - k, 0);      // how many times have we seen sum-k?
        prefixCount.merge(sum, 1, Integer::sum);             // record current prefix sum
    }
    return count;
}
```

**Why `prefixCount.put(0, 1)` is critical:** Without it, you miss subarrays that start at index 0. If `sum == k` at some point, `sum - k == 0` must be in the map. The `0 → 1` entry represents the "empty prefix" before the array starts.

```
Example: nums = [3], k = 3
Without {0:1}: sum=3, sum-k=0, map={} → 0 not found → count=0 ← WRONG!
With {0:1}:    sum=3, sum-k=0, map={0:1} → found 1 → count=1 ← CORRECT!
```

**Variations:**

| Variation | Key Modification | Example |
|-----------|-----------------|---------|
| Subarray sum equals k | `prefixSum → count` | LC 560 |
| Longest subarray with sum k | `prefixSum → first index` (store first occurrence only) | — |
| Subarray sum divisible by k | `prefixSum % k → count` (handle negative modulo!) | LC 974 |
| Binary subarray with sum | Same as basic, binary array | LC 930 |
| Equal 0s and 1s | Replace 0 with -1, find subarrays with sum 0 | LC 525 |
| Subarray with equal letters | Transform to +1/-1 based on character | — |

⚠️ **Common Pitfall — Negative Modulo in Java:**

```java
// Java's % operator can return negative values!
// -1 % 5 = -1 in Java (not 4)

// WRONG for "subarray sum divisible by k":
int key = sum % k; // can be negative!

// CORRECT:
int key = ((sum % k) + k) % k; // always non-negative
```

**Complexity:** O(n) time, O(n) space.

**Example walkthrough — LC 560: Subarray Sum Equals K**

> `nums = [1, 2, 3]`, `k = 3`

| Step | num | sum | sum-k | Look up sum-k | prefixCount (after) | count |
|------|-----|-----|-------|---------------|---------------------|-------|
| init | — | 0 | — | — | {0:1} | 0 |
| 1 | 1 | 1 | -2 | not found | {0:1, 1:1} | 0 |
| 2 | 2 | 3 | 0 | found! count=1 | {0:1, 1:1, 3:1} | 1 |
| 3 | 3 | 6 | 3 | found! count=1 | {0:1, 1:1, 3:1, 6:1} | 2 |

Answer: 2 → subarrays `[1,2]` (sum=3) and `[3]` (sum=3).

**Edge Cases:**
- ☐ All elements are zero, k=0 → every subarray sums to 0, count = n*(n+1)/2
- ☐ Negative numbers → prefix sum can decrease, same algorithm works
- ☐ k=0 → looking for subarrays with sum 0, need duplicate prefix sums
- ☐ Single element equals k → caught by the {0:1} initialization
- ☐ Very large prefix sums → use `long` to avoid integer overflow

🎯 **Likely Follow-ups:**
- **Q:** Can you find the actual subarray, not just the count?
  **A:** Store `prefixSum → first index` instead of count. When you find a match, the subarray is from `map.get(sum-k) + 1` to current index.
- **Q:** What if we need subarrays of length at least 2?
  **A:** Delay adding prefix sums to the map by one step. At index `i`, check the map (which contains prefix sums up to index `i-2`), then add `prefixSum[i-1]` to the map. This ensures any matching subarray has length ≥ 2. (See LC 523: Continuous Subarray Sum)
- **Q:** How does this relate to the "running sum" approach in sliding window?
  **A:** Prefix sum + HashMap works for any target sum (including negative numbers and non-contiguous patterns). Sliding window only works when all elements are positive (or the window has a fixed size), because you need the guarantee that expanding the window increases the sum and shrinking decreases it.

> 🔗 **See Also:** [01-dsa/07-dynamic-programming.md](07-dynamic-programming.md) — prefix sum is a 1D DP concept. [01-dsa/02-two-pointers-sliding-window.md](02-two-pointers-sliding-window.md) — sliding window is an alternative for positive-only arrays.

---

### Pattern 5: HashSet for O(1) Lookup

**Throw elements into a HashSet so you can answer "does X exist?" in O(1) — eliminating the inner loop of brute force solutions.**

**When to recognize it:** Problem asks "does X exist?", "find duplicates", "find missing element", or you need to eliminate O(n) inner loop in a brute force.

💡 **Intuition:** A HashSet is like a guest list at a club. Instead of scanning the entire list every time someone arrives, the bouncer has a hash table — instant lookup. "Is John on the list?" → check bucket → yes/no in O(1).

**Approach:**
1. Store elements in a HashSet
2. Query with `contains()` in O(1)

**Java code template:**

```java
// LC 128: Longest Consecutive Sequence [🔥 Must Do]
public int longestConsecutive(int[] nums) {
    Set<Integer> set = new HashSet<>();
    for (int n : nums) set.add(n);

    int longest = 0;
    for (int n : set) {
        // KEY INSIGHT: only start counting from the BEGINNING of a sequence
        // n-1 not in set means n is the start of a new sequence
        if (!set.contains(n - 1)) {
            int length = 1;
            while (set.contains(n + length)) length++;
            longest = Math.max(longest, length);
        }
    }
    return longest;
}
```

**Why this is O(n) despite nested loops:** Each element is visited at most twice — once in the outer loop, and once as part of a sequence extension in the inner while loop. The `if (!set.contains(n - 1))` guard ensures we only start counting from sequence beginnings, so the while loop across ALL iterations of the outer loop processes each element at most once.

**Dry run:** `nums = [100, 4, 200, 1, 3, 2]`

```
Set = {100, 4, 200, 1, 3, 2}

n=100: 99 not in set → start of sequence. 101? No. Length=1.
n=4:   3 in set → skip (not start of sequence)
n=200: 199 not in set → start. 201? No. Length=1.
n=1:   0 not in set → start. 2? Yes. 3? Yes. 4? Yes. 5? No. Length=4.
n=3:   2 in set → skip
n=2:   1 in set → skip

Longest = 4 (sequence: 1,2,3,4)
```

**Edge Cases:**
- ☐ Empty array → return 0
- ☐ All same elements → `[5,5,5]` → HashSet deduplicates → length 1
- ☐ Already consecutive → `[1,2,3,4,5]` → length 5
- ☐ Negative numbers → `[-1,0,1]` → works fine, length 3
- ☐ Single element → length 1

| Approach | Time | Space | Notes |
|----------|------|-------|-------|
| Sort + scan | O(n log n) | O(1) | Simple but slower |
| HashSet | O(n) | O(n) | Optimal time, uses extra space |
| Union-Find | O(n α(n)) | O(n) | Overkill for this problem |

🎯 **Likely Follow-ups:**
- **Q:** Can you prove this is O(n) and not O(n²)?
  **A:** The outer loop runs n times. The inner while loop only executes for sequence starts (elements where `n-1` is not in the set). Each element is part of exactly one sequence, so the total work done by ALL inner while loops combined is at most n. Total: O(n) + O(n) = O(n).
- **Q:** What if you need to return the actual sequence, not just the length?
  **A:** Track the start element when you find the longest. Then reconstruct: `start, start+1, ..., start+length-1`.

---

### Pattern 6: String Manipulation Patterns

**A collection of techniques for in-place character operations, encoding/decoding, and string transformations.**

**When to recognize it:** Problems involving palindromes, substrings, character replacement, encoding/decoding.

**Sub-pattern 6a: In-place array manipulation (for character arrays)**

```java
// Reverse a string in-place — O(n) time, O(1) space
public void reverseString(char[] s) {
    int left = 0, right = s.length - 1;
    while (left < right) {
        char temp = s[left];
        s[left++] = s[right];
        s[right--] = temp;
    }
}
```

**Dry run:** `s = ['h','e','l','l','o']`

```
left=0, right=4: swap h↔o → ['o','e','l','l','h']
left=1, right=3: swap e↔l → ['o','l','l','e','h']
left=2, right=2: left >= right → stop
Result: ['o','l','l','e','h']
```

**Sub-pattern 6b: Encode/Decode strings**

💡 **Intuition:** The challenge is: how do you pack multiple strings into one string and unpack them perfectly — even if the strings contain your delimiter character? Length-prefixing solves this: before each string, write its length followed by a separator. The decoder reads the length first, then knows exactly how many characters to grab.

```java
// LC 271: Encode and Decode Strings
// Strategy: length-prefixed encoding → "4#abcd3#xyz"
public String encode(List<String> strs) {
    StringBuilder sb = new StringBuilder();
    for (String s : strs) {
        sb.append(s.length()).append('#').append(s);
    }
    return sb.toString();
}

public List<String> decode(String str) {
    List<String> result = new ArrayList<>();
    int i = 0;
    while (i < str.length()) {
        int j = str.indexOf('#', i);                    // find the # separator
        int len = Integer.parseInt(str.substring(i, j)); // parse the length
        result.add(str.substring(j + 1, j + 1 + len));  // extract exactly 'len' chars
        i = j + 1 + len;                                 // move past this string
    }
    return result;
}
```

**Dry run:** `encode(["hello", "world#2"])` → `"5#hello7#world#2"`

```
Decode "5#hello7#world#2":
i=0: j=1 (first #), len=5, extract "hello" (chars 2-6), i=7
i=7: j=8 (next #), len=7, extract "world#2" (chars 9-15), i=16
Result: ["hello", "world#2"]  ← correctly handles # inside the string!
```

**Why length-prefix over delimiter-based?** A simple delimiter like `,` breaks if strings contain commas. Escaping (e.g., `\,`) adds complexity. Length-prefixing is unambiguous — the decoder always knows exactly how many characters to read, regardless of content.

**Sub-pattern 6c: Palindrome checking**

```java
// Check if a string is a palindrome (ignoring non-alphanumeric, case-insensitive)
public boolean isPalindrome(String s) {
    int left = 0, right = s.length() - 1;
    while (left < right) {
        while (left < right && !Character.isLetterOrDigit(s.charAt(left))) left++;
        while (left < right && !Character.isLetterOrDigit(s.charAt(right))) right--;
        if (Character.toLowerCase(s.charAt(left)) != Character.toLowerCase(s.charAt(right))) {
            return false;
        }
        left++;
        right--;
    }
    return true;
}
```

**Edge Cases for String Problems:**
- ☐ Empty string → usually return true for palindrome, empty for encoding
- ☐ Single character → palindrome = true
- ☐ Strings with only special characters → `"!@#"` → after filtering, empty = palindrome
- ☐ Very long strings → ensure O(n) solution, not O(n²)
- ☐ Strings containing the delimiter character → length-prefix encoding handles this

---

### Pattern 7: Sorting as Preprocessing

**Sort the input first, then the problem becomes much easier — duplicates are adjacent, pairs can be found with two pointers, and intervals can be merged in a single pass.**

**When to recognize it:** Problem becomes trivial or significantly easier if the input is sorted. Often combined with two pointers or binary search after sorting.

💡 **Intuition:** Sorting is like organizing a messy bookshelf alphabetically. Finding a specific book goes from "scan every shelf" to "go directly to the B section." Many problems that seem hard on unsorted data become simple linear scans on sorted data.

**When to sort:**
- Finding duplicates → sort, then check adjacent elements
- Finding pairs/triplets with a target sum → sort + two pointers
- Grouping → sort by key
- Merge intervals → sort by start time
- Kth largest/smallest → sort (or use heap for better complexity)

**Caution:** Sorting costs O(n log n). If the problem can be solved in O(n) with hashing, sorting is suboptimal. But sorting uses O(1) extra space (in-place) vs O(n) for a HashMap — trade-off.

| Approach | Time | Space | Best When |
|----------|------|-------|-----------|
| Sort + scan | O(n log n) | O(1) | Memory-constrained, need stable order |
| HashMap/HashSet | O(n) | O(n) | Speed is priority, memory available |
| Bit manipulation | O(n) | O(1) | Special cases (XOR for single missing) |

```java
// LC 217: Contains Duplicate — sorting approach
public boolean containsDuplicate(int[] nums) {
    Arrays.sort(nums); // O(n log n)
    for (int i = 1; i < nums.length; i++) {
        if (nums[i] == nums[i - 1]) return true; // duplicates are now adjacent
    }
    return false;
}
// O(n log n) time, O(1) space (vs HashSet: O(n) time, O(n) space)
```

⚙️ **Under the Hood — Java's Sort Algorithms:**

| Method | Algorithm | Time | Stable? | Notes |
|--------|-----------|------|---------|-------|
| `Arrays.sort(int[])` | Dual-pivot Quicksort | O(n log n) avg | No | For primitives |
| `Arrays.sort(Object[])` | TimSort | O(n log n) worst | Yes | For objects |
| `Collections.sort()` | TimSort | O(n log n) worst | Yes | Delegates to Arrays.sort |

TimSort is a hybrid of merge sort and insertion sort. It exploits existing order in the data ("runs") — nearly sorted arrays are sorted in O(n). This is why it's the default for objects where stability matters.

🎯 **Likely Follow-ups:**
- **Q:** When would you choose sorting over hashing?
  **A:** When (1) you need O(1) extra space, (2) the problem requires ordered output, (3) you need to process elements in sorted order (e.g., merge intervals), or (4) the follow-up question involves "what if the array is already sorted?"
- **Q:** Does sorting modify the input? Is that acceptable?
  **A:** Yes, in-place sorting modifies the original array. If the interviewer says "don't modify the input," you need to either copy the array first (O(n) space) or use a different approach.

> 🔗 **See Also:** [01-dsa/11-sorting-searching.md](11-sorting-searching.md) for deep dive into sorting algorithms. [01-dsa/02-two-pointers-sliding-window.md](02-two-pointers-sliding-window.md) for two-pointer techniques on sorted arrays.


---

## 3. Patterns Summary Table

| # | Pattern | When to Use | Key Idea | Time | Space | Example Problem |
|---|---------|------------|----------|------|-------|-----------------|
| 1 | Frequency Counting | Duplicates, anagrams, top-k frequent | HashMap/array to count occurrences | O(n) | O(k) | Valid Anagram (LC 242) |
| 2 | Two-Pass / Index HashMap | Find pair/element by complement | Store value→index, check complement | O(n) | O(n) | Two Sum (LC 1) |
| 3 | Grouping / Bucketing | Group by property | Map<Key, List> with computed key | O(n·k) | O(n) | Group Anagrams (LC 49) |
| 4 | Prefix Sum + HashMap | Subarray sum = k, divisible by k | prefixSum→count map, check sum-k | O(n) | O(n) | Subarray Sum Equals K (LC 560) |
| 5 | HashSet Lookup | Existence check, duplicates, sequences | O(1) contains() | O(n) | O(n) | Longest Consecutive (LC 128) |
| 6 | String Manipulation | Palindromes, encoding, reversal | Two pointers, StringBuilder | O(n) | O(n) | Encode/Decode Strings (LC 271) |
| 7 | Sorting + Scan | Duplicates, merge intervals, ordering | Sort first, then linear scan | O(n log n) | O(1) | Contains Duplicate (LC 217) |

**Pattern Selection Flowchart:**

```
Problem involves arrays/strings?
├── Need to count occurrences? → Pattern 1: Frequency Counting
├── Need to find pair/complement? → Pattern 2: Index HashMap
├── Need to group elements? → Pattern 3: Grouping
├── Need subarray with target sum? → Pattern 4: Prefix Sum + HashMap
├── Need existence check / duplicates? → Pattern 5: HashSet
├── Need string transformation? → Pattern 6: String Manipulation
└── Problem easier if sorted? → Pattern 7: Sorting + Scan
```

---

## 4. LeetCode Problem List (Must-Solve)

### Easy

| # | Problem Name | LC # | Pattern(s) | Why Important |
|---|-------------|------|-----------|---------------|
| 1 | Two Sum | 1 | Index HashMap | [🔥 Must Do] Classic warm-up, tests HashMap thinking |
| 2 | Valid Anagram | 242 | Frequency Counting | [🔥 Must Do] Frequency map fundamentals |
| 3 | Contains Duplicate | 217 | HashSet / Sorting | Basic set usage |
| 4 | Best Time to Buy and Sell Stock | 121 | Single Pass / Kadane variant | [🔥 Must Do] Track min so far |
| 5 | Valid Palindrome | 125 | Two Pointers + String | Character filtering + comparison |
| 6 | Roman to Integer | 13 | HashMap + Scan | Simple mapping logic |
| 7 | Longest Common Prefix | 14 | String Comparison | Vertical/horizontal scan |
| 8 | Find the Index of the First Occurrence | 28 | String Search | Substring matching |
| 9 | Length of Last Word | 58 | String Scan | Edge cases with spaces |
| 10 | Majority Element | 169 | Boyer-Moore / HashMap | [🔥 Must Do] Boyer-Moore voting |
| 11 | Missing Number | 268 | Math / XOR / HashSet | Multiple approaches |
| 12 | Isomorphic Strings | 205 | Two HashMaps | Bidirectional mapping |
| 13 | Word Pattern | 290 | Two HashMaps | Same as isomorphic, with words |
| 14 | Ransom Note | 383 | Frequency Counting | Simple frequency check |
| 15 | Find All Numbers Disappeared in Array | 448 | Index Marking | In-place O(1) space trick |

### Medium

| # | Problem Name | LC # | Pattern(s) | Why Important |
|---|-------------|------|-----------|---------------|
| 1 | Group Anagrams | 49 | Grouping | [🔥 Must Do] Key design for grouping |
| 2 | Top K Frequent Elements | 347 | Frequency + Bucket Sort | [🔥 Must Do] Multiple approaches (heap, bucket sort) |
| 3 | Product of Array Except Self | 238 | Prefix/Suffix Product | [🔥 Must Do] No division, O(1) space trick |
| 4 | Longest Consecutive Sequence | 128 | HashSet | [🔥 Must Do] O(n) with smart start detection |
| 5 | Subarray Sum Equals K | 560 | Prefix Sum + HashMap | [🔥 Must Do] Core prefix sum pattern |
| 6 | Encode and Decode Strings | 271 | String Encoding | Length-prefix encoding |
| 7 | Valid Sudoku | 36 | HashSet per row/col/box | Set-based validation |
| 8 | Longest Substring Without Repeating Characters | 3 | HashMap + Sliding Window | [🔥 Must Do] Bridges to sliding window |
| 9 | String to Integer (atoi) | 8 | String Parsing | Edge case heavy |
| 10 | Zigzag Conversion | 6 | String + Math | Row-based simulation |
| 11 | Longest Palindromic Substring | 5 | Expand Around Center / DP | [🔥 Must Do] Two approaches |
| 12 | 3Sum | 15 | Sorting + Two Pointers | [🔥 Must Do] Duplicate handling |
| 13 | 4Sum | 18 | Sorting + Two Pointers | Extension of 3Sum |
| 14 | Container With Most Water | 11 | Two Pointers | [🔥 Must Do] Greedy pointer movement |
| 15 | Next Permutation | 31 | Array Manipulation | [🔥 Must Do] Algorithm to memorize |
| 16 | Rotate Array | 189 | Reverse Trick | Three-reverse approach |
| 17 | Set Matrix Zeroes | 73 | In-place Marking | Use first row/col as markers |
| 18 | Spiral Matrix | 54 | Simulation | Boundary tracking |
| 19 | Sort Colors | 75 | Dutch National Flag | [🔥 Must Do] Three-way partition |
| 20 | Find All Anagrams in a String | 438 | Sliding Window + Frequency | Fixed-size window |
| 21 | Minimum Window Substring | 76 | Sliding Window + HashMap | [🔥 Must Do] Variable-size window |
| 22 | Contiguous Array | 525 | Prefix Sum + HashMap | Replace 0→-1, find sum=0 |
| 23 | Subarray Sums Divisible by K | 974 | Prefix Sum + Modulo | Negative modulo handling |
| 24 | Brick Wall | 554 | HashMap (gap counting) | Count gaps at each position |
| 25 | Maximum Product Subarray | 152 | Track min and max | [🔥 Must Do] Negative × negative = positive |
| 26 | Merge Intervals | 56 | Sorting + Scan | [🔥 Must Do] Sort by start, merge overlaps |
| 27 | Insert Interval | 57 | Interval Merge | Three-phase: before, overlap, after |
| 28 | Non-overlapping Intervals | 435 | Greedy + Sorting | Sort by end time |
| 29 | Longest Repeating Character Replacement | 424 | Sliding Window + Frequency | Window validity condition |
| 30 | Permutation in String | 567 | Sliding Window + Frequency | Fixed-size window anagram check |
| 31 | Continuous Subarray Sum | 523 | Prefix Sum + Modulo | Subarray length ≥ 2 |
| 32 | Rotate Image | 48 | Matrix Manipulation | Transpose + reverse |
| 33 | Game of Life | 289 | In-place State Encoding | Encode old+new state in bits |
| 34 | Repeated DNA Sequences | 187 | HashSet + Sliding Window | Fixed 10-char window |
| 35 | Integer to Roman | 12 | Greedy + Mapping | Descending value mapping |

### Hard

| # | Problem Name | LC # | Pattern(s) | Why Important |
|---|-------------|------|-----------|---------------|
| 1 | First Missing Positive | 41 | Index Marking | [🔥 Must Do] O(n) time, O(1) space — cyclic sort |
| 2 | Trapping Rain Water | 42 | Two Pointers / Stack / Prefix | [🔥 Must Do] Multiple approaches |
| 3 | Minimum Window Substring | 76 | Sliding Window + HashMap | [🔥 Must Do] Classic hard sliding window |
| 4 | Substring with Concatenation of All Words | 30 | Sliding Window + HashMap | Multi-word window |
| 5 | Text Justification | 68 | String Simulation | Greedy line packing |
| 6 | Longest Duplicate Substring | 1044 | Binary Search + Rolling Hash | Rabin-Karp application |
| 7 | Smallest Range Covering Elements from K Lists | 632 | Heap + Sliding Window | Multi-list coordination |
| 8 | Count of Range Sum | 327 | Merge Sort / BIT + Prefix Sum | Advanced prefix sum |
| 9 | Max Points on a Line | 149 | HashMap (slope counting) | GCD for slope representation |
| 10 | Minimum Number of K Consecutive Bit Flips | 995 | Greedy + Queue | Deferred flip tracking |


---

## 5. Interview Strategy

**How to approach an unseen array/string/hashing problem:**

1. **Read carefully.** Identify: what's the input? What's the output? What are the constraints (size, value range)?

2. **Classify the problem.** Ask yourself:
   - Is this about pairs/subarrays? → Two pointers, prefix sum, sliding window
   - Is this about frequency/counting? → HashMap/array
   - Is this about existence/duplicates? → HashSet
   - Is this about grouping? → HashMap with computed key
   - Is this about ordering? → Sorting as preprocessing

3. **Start with brute force.** State it explicitly: "The brute force is O(n²) — we check all pairs." This shows the interviewer you understand the baseline.

4. **Identify the inefficiency.** What's the repeated work? Usually it's a nested loop doing a lookup that could be O(1) with a HashMap.

5. **Optimize.** Apply the matching pattern. State the new complexity.

6. **Code.** Write clean code. Use meaningful variable names. Handle edge cases.

7. **Test.** Walk through with a small example. Then test edge cases.

**Sample dialogue with interviewer (Two Sum):**

```
You: "Let me make sure I understand — we need to find two indices whose values sum
     to the target. Can there be duplicate values? Is there always exactly one solution?"

Interviewer: "Yes, exactly one solution, no duplicate indices."

You: "The brute force would check all pairs — O(n²). But I notice that for each
     element, I'm looking for a specific complement (target - current). If I store
     values I've seen in a HashMap, I can check for the complement in O(1).
     That brings it down to O(n) time, O(n) space. Shall I code that up?"

Interviewer: "Go ahead."
```

**Time management (45-minute interview):**

| Phase | Time | What to Do |
|-------|------|------------|
| Understand | 5 min | Read problem, ask clarifying questions, confirm examples |
| Approach | 5 min | State brute force, identify inefficiency, propose optimized approach |
| Code | 20 min | Write clean solution, talk through your logic as you code |
| Test | 10 min | Trace through example, test edge cases, fix bugs |
| Discuss | 5 min | State complexity, discuss follow-ups, alternative approaches |

**Common mistakes:**
- Jumping to code without discussing approach — interviewers want to see your thought process
- Not handling empty input, single element, all same elements
- Integer overflow: `nums[i] + nums[j]` can overflow `int` — use `long` if needed
- Modifying a collection while iterating (`ConcurrentModificationException`)
- Using `==` instead of `.equals()` for String/Integer comparison
- Off-by-one errors in substring operations (`substring(i, j)` is exclusive of `j`)
- Forgetting to initialize the prefix sum map with `{0: 1}`
- Not considering negative numbers in modulo operations

💥 **What Can Go Wrong in Interviews:**

| Mistake | Impact | Prevention |
|---------|--------|------------|
| Jump straight to optimal | Interviewer thinks you've seen the problem | Always start with brute force |
| Silent coding | Interviewer can't evaluate your thinking | Narrate as you code |
| Ignore edge cases | Bugs in testing phase, looks careless | List edge cases before coding |
| Over-engineer | Run out of time | Solve the stated problem, not extensions |
| Wrong data structure | O(n) becomes O(n²) | Pause and think about operations needed |

---

## 6. Edge Cases & Pitfalls

**Array edge cases:**
- ☐ Empty array (`length == 0`) → return 0 / empty result / handle gracefully
- ☐ Single element → often a trivial base case
- ☐ All elements identical → affects duplicate detection, partitioning
- ☐ Already sorted / reverse sorted → best/worst case for some algorithms
- ☐ Contains `Integer.MIN_VALUE` or `Integer.MAX_VALUE` → overflow on negation or addition
- ☐ Negative numbers → affects sum, product, modulo operations
- ☐ Very large arrays (10⁵ to 10⁶ elements) → O(n²) will TLE, need O(n) or O(n log n)

**String edge cases:**
- ☐ Empty string (`""`) → length 0, no characters to process
- ☐ Single character → palindrome = true, anagram of itself
- ☐ All same characters (`"aaaa"`) → affects sliding window, palindrome checks
- ☐ Unicode / special characters → usually not in interviews, but ask
- ☐ Spaces — leading, trailing, multiple consecutive → `trim()` and `split("\\s+")` 
- ☐ Case sensitivity → always clarify with interviewer

**HashMap edge cases:**
- ☐ Null keys → HashMap allows one null key; TreeMap does not; ConcurrentHashMap does not
- ☐ Null values → HashMap allows; ConcurrentHashMap does not
- ☐ Negative numbers as keys → works fine, but affects modulo operations
- ☐ Integer overflow in hash computation → Java handles this (hashCode returns int, wraps around)

**Java-specific pitfalls:**

```java
// PITFALL 1: Integer cache
Integer a = 127, b = 127;
System.out.println(a == b);  // true — cached range [-128, 127]

Integer c = 128, d = 128;
System.out.println(c == d);  // FALSE! Different objects outside cache range
System.out.println(c.equals(d)); // true — always use .equals() for wrapper types

// PITFALL 2: Arrays.asList() returns fixed-size list
List<Integer> list = Arrays.asList(1, 2, 3);
list.add(4);    // throws UnsupportedOperationException!
list.set(0, 10); // OK — modification allowed, just not structural changes

// Use this instead for a mutable list:
List<Integer> mutable = new ArrayList<>(Arrays.asList(1, 2, 3));

// PITFALL 3: Sorting stability
int[] primitives = {3, 1, 2};
Arrays.sort(primitives); // Dual-pivot Quicksort — NOT stable

Integer[] objects = {3, 1, 2};
Arrays.sort(objects); // TimSort — stable

// PITFALL 4: String.substring() since Java 7u6
String big = "a very long string..."; // 1MB string
String small = big.substring(0, 5);   // Creates NEW 5-char string
// In Java 6, small would share big's char[] → memory leak if big is GC'd but small isn't

// PITFALL 5: Autoboxing in loops
long sum = 0;
for (int i = 0; i < 1000000; i++) {
    sum += i; // OK — primitive arithmetic
}

Long sum2 = 0L; // WRONG — creates new Long object on every +=
for (int i = 0; i < 1000000; i++) {
    sum2 += i; // Autoboxing: Long.valueOf(sum2.longValue() + i) — millions of objects!
}
```

⚠️ **Common Pitfall — Modifying HashMap While Iterating:**

```java
// WRONG — ConcurrentModificationException
Map<String, Integer> map = new HashMap<>();
map.put("a", 1); map.put("b", 2); map.put("c", 3);
for (String key : map.keySet()) {
    if (map.get(key) < 2) {
        map.remove(key); // BOOM! ConcurrentModificationException
    }
}

// CORRECT — use Iterator.remove()
Iterator<Map.Entry<String, Integer>> it = map.entrySet().iterator();
while (it.hasNext()) {
    if (it.next().getValue() < 2) {
        it.remove(); // safe removal during iteration
    }
}

// ALSO CORRECT — Java 8+ removeIf
map.entrySet().removeIf(entry -> entry.getValue() < 2);
```


---

## 7. Connections to Other Topics

| This Pattern | Connects To | How |
|-------------|-------------|-----|
| Prefix Sum + HashMap | [01-dsa/07-dynamic-programming.md](07-dynamic-programming.md) | Prefix sum is a 1D DP concept; Kadane's algorithm is a related pattern |
| Sorting + Two Pointers | [01-dsa/02-two-pointers-sliding-window.md](02-two-pointers-sliding-window.md) | Sorting enables pointer-based approaches for 3Sum, container problems |
| Frequency Counting | [01-dsa/09-heap-priority-queue.md](09-heap-priority-queue.md) | Top-K problems: frequency map → heap for efficient selection |
| HashSet for sequences | [01-dsa/06-graphs.md](06-graphs.md) | Union-Find is an alternative approach for connected components / sequences |
| String patterns | [01-dsa/05-trees.md](05-trees.md) | Tries for prefix matching, autocomplete — tree-based string structure |
| Interval problems | [01-dsa/08-greedy-backtracking.md](08-greedy-backtracking.md) | Merge/schedule intervals use greedy algorithms after sorting |
| HashMap design | [04-lld/problems/cache-lru-lfu.md](../04-lld/problems/cache-lru-lfu.md) | LinkedHashMap for LRU cache, HashMap + doubly-linked list for LFU |
| Hashing internals | [05-java/02-collections-internals.md](../05-java/02-collections-internals.md) | Deep dive into HashMap, ConcurrentHashMap, TreeMap internals |
| Subarray problems | [02-system-design/problems/rate-limiter.md](../02-system-design/problems/rate-limiter.md) | Sliding window counting is the basis for rate limiting algorithms |
| String encoding | [02-system-design/problems/url-shortener.md](../02-system-design/problems/url-shortener.md) | Base62 encoding, hashing for URL shortening |
| Array manipulation | [01-dsa/10-bit-manipulation.md](10-bit-manipulation.md) | XOR for finding missing/duplicate elements, bit arrays for space optimization |
| Sorting algorithms | [01-dsa/11-sorting-searching.md](11-sorting-searching.md) | Deep dive into quicksort, mergesort, counting sort, and their applications |

---

## 8. Revision Checklist

**Data Structures:**
- [ ] ArrayList: backed by Object[], grows 1.5x, default capacity 10, amortized O(1) add
- [ ] HashMap: array of buckets, load factor 0.75, treeifies at 8 nodes (capacity ≥ 64), capacity always power of 2
- [ ] HashMap spread function: `hash = hashCode ^ (hashCode >>> 16)`, bucket = `hash & (capacity - 1)`
- [ ] HashSet: wrapper around HashMap with dummy PRESENT values
- [ ] String: immutable, backed by byte[] (Java 9+ compact strings), use StringBuilder in loops
- [ ] StringBuilder: mutable, default capacity 16, grows by `(old + 1) * 2`
- [ ] LinkedHashMap: insertion/access-ordered, useful for LRU cache
- [ ] TreeMap: red-black tree, O(log n), sorted keys, supports floor/ceiling/range queries
- [ ] ConcurrentHashMap: lock striping (Java 8: per-bucket CAS), no null keys/values

**Patterns (one-line each):**
- [ ] Frequency counting → HashMap or int[26] for character problems
- [ ] Index mapping → value→index HashMap, check complement in one pass
- [ ] Grouping → Map<ComputedKey, List<Element>>, key = sorted string or frequency string
- [ ] Prefix sum + HashMap → running sum, check (sum - k) in map, ALWAYS init with {0:1}
- [ ] HashSet lookup → O(1) existence check, sequence start detection (check n-1 not in set)
- [ ] String manipulation → StringBuilder for building, two pointers for in-place, length-prefix for encoding
- [ ] Sorting as preprocessing → enables two pointers, simplifies duplicate detection, O(n log n) + O(1) space

**Critical Details to Remember:**
- [ ] `prefixCount.put(0, 1)` — without this, prefix sum misses subarrays starting at index 0
- [ ] Negative modulo in Java: `((sum % k) + k) % k` to ensure non-negative
- [ ] hashCode/equals contract: override both or neither
- [ ] Integer cache: -128 to 127 — use `.equals()` for wrapper types, never `==`
- [ ] `Arrays.asList()` returns fixed-size list — wrap in `new ArrayList<>()` for mutability
- [ ] String concatenation in loops is O(n²) — always use StringBuilder
- [ ] `Arrays.sort(int[])` = Quicksort (unstable), `Arrays.sort(Object[])` = TimSort (stable)

**Complexity quick reference:**

| Operation | HashMap | TreeMap | HashSet | ArrayList | Arrays.sort |
|-----------|---------|---------|---------|-----------|-------------|
| Get/Contains | O(1) | O(log n) | O(1) | O(n) | — |
| Put/Add | O(1)* | O(log n) | O(1)* | O(1)* | — |
| Remove | O(1) | O(log n) | O(1) | O(n) | — |
| Sort | — | — | — | O(n log n) | O(n log n) |
| Min/Max | O(n) | O(log n) | O(n) | O(n) | — |
| Floor/Ceiling | — | O(log n) | — | — | — |

*amortized

**Must-remember numbers:**
- HashMap default capacity: 16, load factor: 0.75, treeify threshold: 8, untreeify: 6
- ArrayList default capacity: 10, growth factor: 1.5x
- StringBuilder default capacity: 16, growth: `(old + 1) * 2`
- Integer cache range: -128 to 127
- `int` range: -2³¹ to 2³¹-1 (~2.1 billion)
- `long` range: -2⁶³ to 2⁶³-1 (~9.2 × 10¹⁸)
- For n = 10⁵, O(n²) = 10¹⁰ → TLE. Need O(n log n) or better.
- For n = 10⁴, O(n²) = 10⁸ → borderline. O(n log n) is safe.
- For n = 10³, O(n²) = 10⁶ → usually fine.

**Top 10 must-solve before interview:**
1. Two Sum (LC 1) [Easy] — Index HashMap
2. Group Anagrams (LC 49) [Medium] — Grouping with computed key
3. Top K Frequent Elements (LC 347) [Medium] — Frequency map + bucket sort/heap
4. Product of Array Except Self (LC 238) [Medium] — Prefix/suffix product
5. Longest Consecutive Sequence (LC 128) [Medium] — HashSet with start detection
6. Subarray Sum Equals K (LC 560) [Medium] — Prefix sum + HashMap
7. 3Sum (LC 15) [Medium] — Sort + two pointers + duplicate handling
8. Merge Intervals (LC 56) [Medium] — Sort by start + merge overlaps
9. Trapping Rain Water (LC 42) [Hard] — Two pointers / prefix max arrays
10. First Missing Positive (LC 41) [Hard] — Cyclic sort / index marking

---

## 📋 Suggested New Documents

### 1. Rolling Hash & String Matching Algorithms
- **Placement**: `01-dsa/12-string-matching-algorithms.md`
- **Why needed**: Rabin-Karp (rolling hash), KMP, and Z-algorithm appear in hard string problems (LC 28, 1044, 214) and are not covered in any existing file. These are distinct from the basic string patterns in this document.
- **Key subtopics**: Rabin-Karp with modular arithmetic, KMP failure function, Z-array, suffix arrays (overview), when to use which algorithm

### 2. Interval Problems Deep Dive
- **Placement**: `01-dsa/12-interval-problems.md`
- **Why needed**: Merge Intervals, Insert Interval, Meeting Rooms, and similar problems form a distinct pattern family that spans sorting, greedy, and sweep line techniques. Currently scattered across this doc and greedy/backtracking.
- **Key subtopics**: Sweep line algorithm, interval scheduling maximization, weighted job scheduling, calendar booking problems, line sweep for rectangle overlap

### 3. Mathematical Techniques for Interviews
- **Placement**: `01-dsa/12-math-techniques.md`
- **Why needed**: Boyer-Moore voting, reservoir sampling, Fisher-Yates shuffle, modular arithmetic, GCD/LCM, and combinatorics appear in interviews but aren't covered in any existing file.
- **Key subtopics**: Modular arithmetic (especially for large numbers), probability/randomization problems, number theory basics (primes, GCD), combinatorics for counting problems
