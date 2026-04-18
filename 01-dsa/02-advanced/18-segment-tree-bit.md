> ⚠️ **[OPTIONAL] — Rarely asked at SDE-2 interviews. Skip unless you've mastered files 00-14.**

# Segment Trees & Binary Indexed Trees

## 1. Foundation

**Segment trees and BITs (Fenwick trees) answer range queries (sum, min, max) and handle point updates in O(log n), much faster than the naive O(n) per query.**

💡 **Intuition:** A prefix sum array answers range sum queries in O(1) but takes O(n) to update (must recompute all sums after the changed index). A segment tree is a balanced binary tree where each node stores the aggregate (sum, min, max) of a range. Updating one element only affects O(log n) nodes (the path from leaf to root). Querying a range combines O(log n) nodes.

**Decision framework:**

| Scenario | Best Structure | Why |
|----------|---------------|-----|
| Static array, range sum queries | Prefix sum array | O(1) query, O(n) build, no updates needed |
| Point updates + range sum queries | BIT (Fenwick tree) | Simpler code, O(log n) both operations |
| Point updates + range min/max queries | Segment tree | BIT only supports sum (associative + invertible) |
| Range updates + range queries | Segment tree with lazy propagation | Lazy defers updates to children |
| Count inversions, count smaller after self | BIT or merge sort | BIT with coordinate compression |

⚙️ **Under the Hood, Why O(log n):**

```
Array of 8 elements: [1, 3, 5, 7, 2, 4, 6, 8]

Segment tree (sum):
                    [36]              ← root: sum of [0..7]
                /          \
           [16]              [20]     ← sum of [0..3], [4..7]
          /    \            /    \
        [4]    [12]      [6]    [14]  ← sum of [0..1], [2..3], [4..5], [6..7]
       / \    / \       / \    / \
      1   3  5   7    2   4  6   8   ← leaves = original array

Query sum [2..5]: need nodes covering [2..3] and [4..5]
  = tree[2..3] + tree[4..5] = 12 + 6 = 18 ✓ (5+7+2+4=18)
  Only visited 2 nodes + root path = O(log n)

Update index 3 to 10: change leaf, update path to root
  Leaf: 7 → 10
  Parent [2..3]: 12 → 15
  Parent [0..3]: 16 → 19
  Root [0..7]: 36 → 39
  Only 4 nodes updated = O(log n)
```

> 🔗 **See Also:** [01-dsa/05-trees.md](05-trees.md) for tree concepts. [01-dsa/11-sorting-searching.md](11-sorting-searching.md) for merge sort counting (alternative to BIT for inversions).

---

## 2. Core Patterns

### Pattern 1: Binary Indexed Tree (Fenwick Tree) [🔥 Must Know]

**BIT supports point update and prefix sum query in O(log n) each, with only ~10 lines of code.**

💡 **Intuition:** BIT uses a clever indexing scheme based on the lowest set bit of each index. Each position i is responsible for a range of elements determined by `i & (-i)` (the lowest set bit). This creates a tree-like structure where updates propagate upward and queries accumulate downward.

```java
class BIT {
    int[] tree;
    int n;
    
    BIT(int n) { this.n = n; tree = new int[n + 1]; } // 1-indexed!
    
    void update(int i, int delta) { // add delta to index i
        for (; i <= n; i += i & (-i)) tree[i] += delta;
    }
    
    int query(int i) { // prefix sum [1..i]
        int sum = 0;
        for (; i > 0; i -= i & (-i)) sum += tree[i];
        return sum;
    }
    
    int rangeQuery(int l, int r) { return query(r) - query(l - 1); }
}
```

⚙️ **Under the Hood, How `i & (-i)` Creates the Tree Structure:**

```
Index (decimal): 1    2    3    4    5    6    7    8
Index (binary):  0001 0010 0011 0100 0101 0110 0111 1000
i & (-i):        1    2    1    4    1    2    1    8

Responsibility ranges:
  tree[1] = arr[1]           (range of 1)
  tree[2] = arr[1..2]        (range of 2)
  tree[3] = arr[3]           (range of 1)
  tree[4] = arr[1..4]        (range of 4)
  tree[5] = arr[5]           (range of 1)
  tree[6] = arr[5..6]        (range of 2)
  tree[7] = arr[7]           (range of 1)
  tree[8] = arr[1..8]        (range of 8)

Update index 3: affects tree[3], tree[4], tree[8]
  3 → 3+1=4 → 4+4=8 → done (>n)
  Binary: 011 → 100 → 1000

Query prefix sum [1..6]: sum tree[6] + tree[4]
  6 → 6-2=4 → 4-4=0 → done
  Binary: 110 → 100 → 000
  tree[6] covers [5..6], tree[4] covers [1..4] → total [1..6] ✓
```

⚠️ **Common Pitfall:** BIT is 1-indexed. If your problem uses 0-indexed arrays, add 1 to all indices when calling BIT methods.

**BIT for counting inversions / count smaller after self:**

```java
// LC 315: Count of Smaller Numbers After Self
// Idea: process from right to left, use BIT to count elements smaller than current
public List<Integer> countSmaller(int[] nums) {
    // Coordinate compression: map values to [1, n]
    int[] sorted = nums.clone();
    Arrays.sort(sorted);
    Map<Integer, Integer> rank = new HashMap<>();
    int r = 1;
    for (int val : sorted) rank.putIfAbsent(val, r++);
    
    BIT bit = new BIT(rank.size());
    Integer[] result = new Integer[nums.length];
    for (int i = nums.length - 1; i >= 0; i--) {
        int pos = rank.get(nums[i]);
        result[i] = bit.query(pos - 1); // count elements smaller (ranks 1 to pos-1)
        bit.update(pos, 1);              // add current element
    }
    return Arrays.asList(result);
}
```

---

### Pattern 2: Segment Tree [🔥 Must Know]

**Segment tree supports any associative range query (sum, min, max, GCD) with point or range updates.**

```java
class SegmentTree {
    int[] tree;
    int n;
    
    SegmentTree(int[] arr) {
        n = arr.length;
        tree = new int[4 * n]; // 4n is safe upper bound
        build(arr, 1, 0, n - 1);
    }
    
    void build(int[] arr, int node, int start, int end) {
        if (start == end) { tree[node] = arr[start]; return; }
        int mid = (start + end) / 2;
        build(arr, 2 * node, start, mid);
        build(arr, 2 * node + 1, mid + 1, end);
        tree[node] = tree[2 * node] + tree[2 * node + 1]; // merge function (sum)
    }
    
    void update(int node, int start, int end, int idx, int val) {
        if (start == end) { tree[node] = val; return; }
        int mid = (start + end) / 2;
        if (idx <= mid) update(2 * node, start, mid, idx, val);
        else update(2 * node + 1, mid + 1, end, idx, val);
        tree[node] = tree[2 * node] + tree[2 * node + 1]; // re-merge after update
    }
    
    int query(int node, int start, int end, int l, int r) {
        if (r < start || end < l) return 0;              // completely outside
        if (l <= start && end <= r) return tree[node];    // completely inside
        int mid = (start + end) / 2;
        return query(2 * node, start, mid, l, r) 
             + query(2 * node + 1, mid + 1, end, l, r);  // partial overlap
    }
}
```

💡 **Intuition for the three query cases:**
- **Completely outside** `[l,r]`: return identity (0 for sum, MAX_VALUE for min). This range contributes nothing.
- **Completely inside** `[l,r]`: return the precomputed value. No need to go deeper.
- **Partial overlap**: recurse into both children and merge results.

---

### Pattern 3: Lazy Propagation (Range Updates)

**When you need to update an entire range (e.g., "add 5 to all elements in [2,7]"), lazy propagation defers the update to children until they're actually queried.**

```java
class LazySegTree {
    int[] tree, lazy;
    int n;
    
    LazySegTree(int[] arr) {
        n = arr.length;
        tree = new int[4 * n];
        lazy = new int[4 * n]; // pending updates
        build(arr, 1, 0, n - 1);
    }
    
    void build(int[] arr, int node, int start, int end) {
        if (start == end) { tree[node] = arr[start]; return; }
        int mid = (start + end) / 2;
        build(arr, 2 * node, start, mid);
        build(arr, 2 * node + 1, mid + 1, end);
        tree[node] = tree[2 * node] + tree[2 * node + 1];
    }
    
    void pushDown(int node, int start, int end) {
        if (lazy[node] != 0) {
            int mid = (start + end) / 2;
            apply(2 * node, start, mid, lazy[node]);
            apply(2 * node + 1, mid + 1, end, lazy[node]);
            lazy[node] = 0;
        }
    }
    
    void apply(int node, int start, int end, int val) {
        tree[node] += val * (end - start + 1); // add val to each element in range
        lazy[node] += val;                       // defer to children
    }
    
    void rangeUpdate(int node, int start, int end, int l, int r, int val) {
        if (r < start || end < l) return;
        if (l <= start && end <= r) { apply(node, start, end, val); return; }
        pushDown(node, start, end);
        int mid = (start + end) / 2;
        rangeUpdate(2 * node, start, mid, l, r, val);
        rangeUpdate(2 * node + 1, mid + 1, end, l, r, val);
        tree[node] = tree[2 * node] + tree[2 * node + 1];
    }
    
    int query(int node, int start, int end, int l, int r) {
        if (r < start || end < l) return 0;
        if (l <= start && end <= r) return tree[node];
        pushDown(node, start, end); // push pending updates before querying children
        int mid = (start + end) / 2;
        return query(2 * node, start, mid, l, r) + query(2 * node + 1, mid + 1, end, l, r);
    }
}
```

⚙️ **Under the Hood, Why Lazy Propagation is O(log n):**

```
Range update [2, 7] with +5:

Without lazy: update each of 6 elements individually = O(n log n)

With lazy: 
  Find O(log n) nodes that exactly cover [2,7]
  Mark them with lazy[node] = 5
  Update their tree[node] = old + 5 * range_size
  DON'T recurse into children yet

When a future query needs a child of a lazy node:
  Push the lazy value down to both children (pushDown)
  Clear the parent's lazy value
  Then proceed with the query

Each update/query touches O(log n) nodes. Lazy values are pushed down
only when needed, keeping the total work O(log n) per operation.
```

---

## 3. Comparison Table

| Feature | BIT (Fenwick) | Segment Tree | Segment Tree + Lazy |
|---------|--------------|-------------|-------------------|
| Point update | O(log n) ✓ | O(log n) ✓ | O(log n) ✓ |
| Range update | ✗ | ✗ | O(log n) ✓ |
| Range sum query | O(log n) ✓ | O(log n) ✓ | O(log n) ✓ |
| Range min/max query | ✗ | O(log n) ✓ | O(log n) ✓ |
| Space | O(n) | O(4n) | O(4n) |
| Code complexity | ~10 lines | ~40 lines | ~60 lines |
| Build time | O(n log n) | O(n) | O(n) |

🎯 **Likely Follow-ups:**
- **Q:** When would you use BIT over segment tree?
  **A:** When you only need range sum queries with point updates. BIT is simpler (10 lines vs 40), uses less memory (n vs 4n), and has a smaller constant factor. If you need range min/max or range updates, you must use a segment tree.
- **Q:** Can BIT support range updates?
  **A:** Yes, with a trick: use two BITs to support range add + point query, or range add + range sum. But the code becomes complex enough that a lazy segment tree is cleaner.
- **Q:** Why is the segment tree array size 4n and not 2n?
  **A:** A complete binary tree with n leaves has 2n-1 nodes. But segment trees are not always complete (n might not be a power of 2). The worst case requires up to 4n nodes. Using 4n is a safe upper bound that avoids index-out-of-bounds errors.

---

## 4. Revision Checklist

- [ ] BIT: 1-indexed, `i & (-i)` for lowest set bit. Update: add lowest bit. Query: subtract lowest bit.
- [ ] BIT for range sum only. O(log n) update and query. ~10 lines of code.
- [ ] Segment tree: build O(n), update O(log n), query O(log n). 4n space.
- [ ] Segment tree query: three cases (outside, inside, partial overlap).
- [ ] Lazy propagation: defer range updates to children. Push down before querying children.
- [ ] BIT for inversions: process right to left, query prefix count, update with current element.
- [ ] Coordinate compression: map values to [1, n] for BIT when value range is large.

**Top 5 must-solve:**
1. Range Sum Query - Mutable (LC 307) [Medium] - BIT or segment tree basics
2. Count of Smaller Numbers After Self (LC 315) [Hard] - BIT with coordinate compression
3. Reverse Pairs (LC 493) [Hard] - BIT or merge sort
4. My Calendar III (LC 732) [Hard] - Segment tree with lazy propagation
5. Count of Range Sum (LC 327) [Hard] - Segment tree or merge sort

> 🔗 **See Also:** [01-dsa/05-trees.md](05-trees.md) for tree concepts. [01-dsa/11-sorting-searching.md](11-sorting-searching.md) for merge sort counting (alternative to BIT for inversions). [01-dsa/19-advanced-trees.md](19-advanced-trees.md) for Euler tour + segment tree combination.
