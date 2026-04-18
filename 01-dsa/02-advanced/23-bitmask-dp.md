> ⚠️ **[OPTIONAL] — Rarely asked at SDE-2 interviews. Skip unless you've mastered files 00-14.**

# Bitmask DP

## 1. Foundation

**Bitmask DP uses an integer's bits to represent a subset of elements as the DP state. This enables O(2ⁿ × n) solutions for problems involving subsets of small sets (n ≤ 20).**

💡 **Intuition:** For a set of n elements, there are 2ⁿ possible subsets. A bitmask of n bits can represent any subset: bit i = 1 means element i is included. DP state = which elements have been used/visited. Transition = add one more element to the subset.

## 2. Core Patterns

### Traveling Salesman Problem (TSP) [🔥 Must Know]

```java
// Visit all n cities with minimum cost, returning to start
// dp[mask][i] = min cost to visit all cities in mask, ending at city i
public int tsp(int[][] dist) {
    int n = dist.length;
    int[][] dp = new int[1 << n][n];
    for (int[] row : dp) Arrays.fill(row, Integer.MAX_VALUE);
    dp[1][0] = 0; // start at city 0, only city 0 visited
    
    for (int mask = 1; mask < (1 << n); mask++) {
        for (int u = 0; u < n; u++) {
            if (dp[mask][u] == Integer.MAX_VALUE) continue;
            if ((mask >> u & 1) == 0) continue; // u must be in mask
            for (int v = 0; v < n; v++) {
                if ((mask >> v & 1) == 1) continue; // v must NOT be in mask
                int newMask = mask | (1 << v);
                dp[newMask][v] = Math.min(dp[newMask][v], dp[mask][u] + dist[u][v]);
            }
        }
    }
    
    int fullMask = (1 << n) - 1;
    int minCost = Integer.MAX_VALUE;
    for (int u = 0; u < n; u++) {
        if (dp[fullMask][u] != Integer.MAX_VALUE) {
            minCost = Math.min(minCost, dp[fullMask][u] + dist[u][0]); // return to start
        }
    }
    return minCost;
}
```

**Complexity:** O(2ⁿ × n²) time, O(2ⁿ × n) space. Feasible for n ≤ 20.

### Shortest Path Visiting All Nodes [🔥 Must Do]

```java
// LC 847: BFS with state = (current_node, visited_mask)
public int shortestPathLength(int[][] graph) {
    int n = graph.length;
    int fullMask = (1 << n) - 1;
    Deque<int[]> queue = new ArrayDeque<>(); // {node, visited_mask}
    Set<Long> visited = new HashSet<>();
    
    for (int i = 0; i < n; i++) {
        int mask = 1 << i;
        queue.offer(new int[]{i, mask});
        visited.add((long) i * (fullMask + 1) + mask);
    }
    
    int steps = 0;
    while (!queue.isEmpty()) {
        int size = queue.size();
        for (int i = 0; i < size; i++) {
            int[] curr = queue.poll();
            if (curr[1] == fullMask) return steps;
            for (int next : graph[curr[0]]) {
                int newMask = curr[1] | (1 << next);
                long state = (long) next * (fullMask + 1) + newMask;
                if (visited.add(state)) {
                    queue.offer(new int[]{next, newMask});
                }
            }
        }
        steps++;
    }
    return -1;
}
```

### Partition to K Equal Sum Subsets

```java
// LC 698: Can we partition array into k subsets with equal sum?
public boolean canPartitionKSubsets(int[] nums, int k) {
    int total = Arrays.stream(nums).sum();
    if (total % k != 0) return false;
    int target = total / k;
    Arrays.sort(nums); // sort for pruning
    return backtrack(nums, new boolean[nums.length], k, 0, 0, target);
}
// Bitmask optimization: dp[mask] = can we form complete subsets using elements in mask?
```

🎯 **Likely Follow-ups:**
- **Q:** What is the maximum n for bitmask DP?
  **A:** n <= 20 is the practical limit. 2²⁰ = ~1M states, and with O(n) or O(n²) transitions per state, total work is 20M-400M operations. n=23 is borderline (8M states). n=25+ is infeasible.
- **Q:** How do you enumerate all subsets of a given bitmask?
  **A:** `for (int sub = mask; sub > 0; sub = (sub - 1) & mask)` iterates all non-empty subsets of mask. This runs in O(2^popcount(mask)) time. Don't forget to handle the empty subset (sub=0) separately if needed.
- **Q:** What is profile DP?
  **A:** DP where the state includes a bitmask representing one row (or column) of a grid. Used for problems like "Maximum Students Taking Exam" (LC 1349) where each row's valid configurations depend on the previous row's configuration.

---

## 3. Complexity Summary

| Pattern | Time | Space | Constraint |
|---------|------|-------|-----------|
| TSP | O(2^n * n²) | O(2^n * n) | n <= 20 |
| BFS + bitmask | O(n * 2^n) | O(n * 2^n) | n <= 20 |
| Subset enumeration | O(3^n) | O(2^n) | n <= 15 |
| Profile DP | O(rows * 2^cols * 2^cols) | O(2^cols) | cols <= 20 |

---

## 4. LeetCode Problem List

**Top 5 must-solve:**
1. Shortest Path Visiting All Nodes (LC 847) [Hard] - BFS with bitmask state
2. Partition to K Equal Sum Subsets (LC 698) [Medium] - Bitmask DP or backtracking
3. Find the Shortest Superstring (LC 943) [Hard] - TSP variant with string overlap
4. Maximum Students Taking Exam (LC 1349) [Hard] - Profile DP with bitmask per row
5. Parallel Courses II (LC 1494) [Hard] - Bitmask DP with topological constraints

---

## 5. Revision Checklist

- [ ] Bitmask: bit i = 1 means element i is in the subset. `mask | (1 << i)` adds, `mask & ~(1 << i)` removes.
- [ ] TSP: `dp[mask][i]` = min cost visiting all in mask, ending at i. O(2ⁿ × n²).
- [ ] BFS + bitmask: state = (node, visited_mask). Used for shortest path visiting all nodes.
- [ ] Subset enumeration: `for (sub = mask; sub > 0; sub = (sub-1) & mask)` iterates all subsets of mask.
- [ ] Feasible for n ≤ 20 (2²⁰ ≈ 1M states).

> 🔗 **See Also:** [01-dsa/10-bit-manipulation.md](10-bit-manipulation.md) for bitmask basics. [01-dsa/06-graphs.md](06-graphs.md) for BFS + state-space search.
