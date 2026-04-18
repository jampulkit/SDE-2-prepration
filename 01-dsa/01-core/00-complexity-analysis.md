> ✅ **[CORE] — Must-do for SDE-2 interviews.**

# Complexity Analysis

## 1. Foundation

**Complexity analysis tells you how an algorithm's runtime and memory usage grow as input size increases. It's the first thing interviewers evaluate: "What's the time and space complexity?" If you can't answer this, the solution doesn't count.**

💡 **Intuition:** Complexity analysis is not about measuring exact time (that depends on hardware). It's about measuring growth rate. An O(n) algorithm on a slow computer will eventually beat an O(n²) algorithm on a fast computer, because growth rate dominates for large inputs.

### Big-O, Big-Omega, Big-Theta

| Notation | Meaning | Analogy |
|----------|---------|---------|
| **O(f(n))** | Upper bound (worst case) | "At most this fast" |
| **Ω(f(n))** | Lower bound (best case) | "At least this fast" |
| **Θ(f(n))** | Tight bound (average case) | "Exactly this fast" |

In interviews, when someone says "time complexity", they mean **O (worst case)** unless stated otherwise.

**Rules for calculating Big-O:**
1. Drop constants: O(2n) = O(n)
2. Drop lower-order terms: O(n² + n) = O(n²)
3. Different inputs use different variables: O(n + m), not O(n)
4. Nested loops multiply: O(n) * O(m) = O(n*m)
5. Sequential steps add: O(n) + O(m) = O(n + m)

### Common Complexity Classes

| Complexity | Name | Example | n=10⁵ operations |
|-----------|------|---------|-------------------|
| O(1) | Constant | HashMap lookup, array access | 1 |
| O(log n) | Logarithmic | Binary search, balanced BST lookup | 17 |
| O(n) | Linear | Array scan, single loop | 100,000 |
| O(n log n) | Linearithmic | Merge sort, heap sort | 1,700,000 |
| O(n²) | Quadratic | Nested loops, bubble sort | 10,000,000,000 ❌ TLE |
| O(n³) | Cubic | Triple nested loops, Floyd-Warshall | 10¹⁵ ❌ |
| O(2ⁿ) | Exponential | Subsets, recursive Fibonacci | 10³⁰ ❌ |
| O(n!) | Factorial | Permutations, brute-force TSP | 10⁵⁰⁰⁰⁰⁰ ❌ |

### Will My Solution TLE? [🔥 Must Know]

**Rule of thumb: ~10⁸ simple operations per second in Java.**

| n | Max Acceptable Complexity | Why |
|---|--------------------------|-----|
| n ≤ 10 | O(n!), O(2ⁿ) | 10! = 3.6M, 2¹⁰ = 1024 |
| n ≤ 20 | O(2ⁿ), O(n * 2ⁿ) | 2²⁰ = 1M, 20 * 2²⁰ = 20M |
| n ≤ 500 | O(n³) | 500³ = 125M |
| n ≤ 5,000 | O(n²) | 5000² = 25M |
| n ≤ 10⁵ | O(n log n) | 10⁵ * 17 = 1.7M |
| n ≤ 10⁶ | O(n) | 10⁶ |
| n ≤ 10⁸ | O(n) with small constant | Tight |
| n ≤ 10¹⁸ | O(log n) or O(1) | Binary search, math formula |

**How to use this table:** Read the constraint in the problem. If n ≤ 10⁵, you need O(n log n) or better. If your solution is O(n²), it will TLE. Rethink.

---

## 2. Analyzing Complexity

### Loops

```java
// Single loop: O(n)
for (int i = 0; i < n; i++) { ... }

// Nested loops: O(n²)
for (int i = 0; i < n; i++)
    for (int j = 0; j < n; j++) { ... }

// Loop with halving: O(log n)
for (int i = n; i > 0; i /= 2) { ... }

// Loop with different bounds: O(n * m)
for (int i = 0; i < n; i++)
    for (int j = 0; j < m; j++) { ... }

// Inner loop depends on outer: O(n²) — sum of 1+2+...+n = n(n+1)/2
for (int i = 0; i < n; i++)
    for (int j = 0; j < i; j++) { ... }

// Two sequential loops: O(n + m) — NOT O(n * m)
for (int i = 0; i < n; i++) { ... }
for (int j = 0; j < m; j++) { ... }
```

### Recursion

```java
// Linear recursion: O(n) time, O(n) space (call stack)
void f(int n) {
    if (n == 0) return;
    f(n - 1);
}

// Binary recursion (Fibonacci): O(2ⁿ) time, O(n) space
int fib(int n) {
    if (n <= 1) return n;
    return fib(n-1) + fib(n-2); // two branches per call
}

// Divide and conquer (merge sort): O(n log n) time, O(n) space
void mergeSort(int[] arr, int lo, int hi) {
    if (lo >= hi) return;
    int mid = (lo + hi) / 2;
    mergeSort(arr, lo, mid);      // T(n/2)
    mergeSort(arr, mid+1, hi);    // T(n/2)
    merge(arr, lo, mid, hi);      // O(n)
}
// T(n) = 2T(n/2) + O(n) → O(n log n) by Master Theorem
```

### Master Theorem [🔥 Must Know]

**For recurrences of the form T(n) = aT(n/b) + O(n^d):**

| Condition | Result | Example |
|-----------|--------|---------|
| d < log_b(a) | O(n^(log_b(a))) | T(n) = 8T(n/2) + O(n) → O(n³) |
| d = log_b(a) | O(n^d * log n) | T(n) = 2T(n/2) + O(n) → O(n log n) (merge sort) |
| d > log_b(a) | O(n^d) | T(n) = 2T(n/2) + O(n²) → O(n²) |

**Common recurrences:**

| Recurrence | Algorithm | Complexity |
|-----------|-----------|-----------|
| T(n) = T(n-1) + O(1) | Linear scan | O(n) |
| T(n) = T(n-1) + O(n) | Selection sort inner loop | O(n²) |
| T(n) = 2T(n-1) + O(1) | Fibonacci (naive) | O(2ⁿ) |
| T(n) = T(n/2) + O(1) | Binary search | O(log n) |
| T(n) = 2T(n/2) + O(n) | Merge sort | O(n log n) |
| T(n) = 2T(n/2) + O(1) | Tree traversal | O(n) |
| T(n) = T(n/2) + O(n) | Quickselect (average) | O(n) |

### Amortized Analysis

**Some operations are expensive occasionally but cheap on average. Amortized analysis spreads the cost over all operations.**

```
ArrayList.add():
  Usually O(1): just append to array
  Occasionally O(n): when array is full, copy to new array (1.5x size)
  
  Amortized analysis: after n adds, total copy work ≈ 2n (geometric series)
  Amortized cost per add: 2n / n = O(1)

HashMap.put():
  Usually O(1): hash and insert
  Occasionally O(n): when load factor exceeded, rehash entire table
  Amortized: O(1) per put
```

### Space Complexity

| Source | Space | Example |
|--------|-------|---------|
| Input (not counted) | — | The array itself |
| Auxiliary variables | O(1) | int temp, pointers |
| Auxiliary array | O(n) | Merge sort temp array |
| Recursion stack | O(depth) | DFS on tree: O(h), on graph: O(V) |
| HashMap/HashSet | O(n) | Frequency counting |
| 2D DP table | O(n*m) | LCS, edit distance |

**Space optimization:** Many DP problems can reduce from O(n*m) to O(n) by keeping only the previous row.

---

## 3. Revision Checklist

- [ ] Big-O = worst case upper bound. Drop constants and lower-order terms.
- [ ] n ≤ 10⁵ → need O(n log n). n ≤ 5000 → O(n²) OK. n ≤ 20 → O(2ⁿ) OK.
- [ ] ~10⁸ operations/second in Java. Use this to estimate TLE.
- [ ] Nested loops multiply. Sequential steps add. Different inputs use different variables.
- [ ] Master Theorem: T(n) = aT(n/b) + O(n^d). Compare d with log_b(a).
- [ ] Merge sort: T(n) = 2T(n/2) + O(n) → O(n log n). Binary search: T(n) = T(n/2) + O(1) → O(log n).
- [ ] Amortized O(1): ArrayList add, HashMap put (occasional O(n) resize, but O(1) on average).
- [ ] Space: recursion stack = O(depth). DP table = O(states). HashMap = O(keys).
- [ ] Space optimization: keep only previous row in 2D DP → O(n) instead of O(n*m).

> 🔗 **See Also:** [01-dsa/07-dynamic-programming.md](07-dynamic-programming.md) for DP space optimization. [01-dsa/11-sorting-searching.md](11-sorting-searching.md) for sorting algorithm complexities.
