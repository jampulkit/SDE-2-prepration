> ⚠️ **[OPTIONAL] — Rarely asked at SDE-2 interviews. Skip unless you've mastered files 00-14.**

# State-Space BFS / Complex State Search

## 1. Foundation

**When the "graph" isn't explicit but defined by states and transitions, BFS on the state space finds the shortest path. The state can include position + visited set, position + keys collected, or board configuration.**

💡 **Intuition:** In "Open the Lock" (LC 752), each state is a 4-digit combination. Each transition is turning one wheel ±1. BFS finds the minimum turns from "0000" to the target, avoiding deadends.

## 2. Core Patterns

### BFS with Bitmask State
```java
// LC 847: Shortest Path Visiting All Nodes
// State = (current_node, visited_bitmask)
// See 12-bitmask-dp.md for full implementation
```

### BFS on Implicit Graph
```java
// LC 752: Open the Lock
public int openLock(String[] deadends, String target) {
    Set<String> dead = new HashSet<>(Arrays.asList(deadends));
    Set<String> visited = new HashSet<>();
    if (dead.contains("0000")) return -1;
    
    Deque<String> queue = new ArrayDeque<>();
    queue.offer("0000");
    visited.add("0000");
    int steps = 0;
    
    while (!queue.isEmpty()) {
        int size = queue.size();
        for (int i = 0; i < size; i++) {
            String curr = queue.poll();
            if (curr.equals(target)) return steps;
            for (String next : getNeighbors(curr)) {
                if (!visited.contains(next) && !dead.contains(next)) {
                    visited.add(next);
                    queue.offer(next);
                }
            }
        }
        steps++;
    }
    return -1;
}

private List<String> getNeighbors(String s) {
    List<String> result = new ArrayList<>();
    char[] arr = s.toCharArray();
    for (int i = 0; i < 4; i++) {
        char orig = arr[i];
        arr[i] = orig == '9' ? '0' : (char)(orig + 1); result.add(new String(arr));
        arr[i] = orig == '0' ? '9' : (char)(orig - 1); result.add(new String(arr));
        arr[i] = orig;
    }
    return result;
}
```

### Bidirectional BFS
Start BFS from both source and target simultaneously. Meet in the middle. Reduces search space from O(b^d) to O(b^(d/2)).

⚙️ **Under the Hood, State Encoding Strategies:**

```
Problem: Shortest Path Visiting All Nodes (LC 847)
State: (current_node, set_of_visited_nodes)

Encoding options:
1. Bitmask: visited = integer where bit i = 1 means node i visited
   State = (node, bitmask). Encode as: node * (1 << n) + bitmask
   Space: O(n * 2^n). Works for n <= 20.

2. String: visited = sorted string of visited node IDs
   State = "node:1,3,5". Encode as String for HashSet.
   Space: O(n * n!). Only for very small n.

3. Tuple: (node, frozenset) in Python. In Java, encode as long or String.

Rule of thumb: if n <= 20, use bitmask. If state is a board/grid, use String.
```

🎯 **Likely Follow-ups:**
- **Q:** When is bidirectional BFS better than regular BFS?
  **A:** When the branching factor b is large and the shortest path length d is known to be moderate. Regular BFS explores O(b^d) states. Bidirectional explores O(2 * b^(d/2)) states, which is exponentially smaller. Example: Word Ladder with 26 possible character changes per position.
- **Q:** How do you implement bidirectional BFS?
  **A:** Maintain two sets (frontA from source, frontB from target). At each step, expand the SMALLER set. When a node appears in both sets, you've found the shortest path. Always expand the smaller set to minimize total work.
- **Q:** What if the state space is too large for BFS?
  **A:** Use A* search (BFS with a heuristic that estimates remaining distance). Or use iterative deepening DFS (IDDFS) which uses O(d) space instead of O(b^d). For optimization problems, consider DP with memoization instead of BFS.

---

## 3. Complexity Summary

| Technique | Time | Space | When to Use |
|-----------|------|-------|-------------|
| BFS on implicit graph | O(V + E) in state space | O(V) | Shortest path in unweighted state graph |
| BFS with bitmask | O(n * 2^n) | O(n * 2^n) | Visit all nodes, n <= 20 |
| Bidirectional BFS | O(b^(d/2)) | O(b^(d/2)) | Large branching factor, known target |
| A* search | O(b^d) worst, much better with good heuristic | O(b^d) | When a good heuristic exists |

---

## 4. LeetCode Problem List

**Top 5 must-solve:**
1. Open the Lock (LC 752) [Medium] - BFS on implicit graph with deadends
2. Word Ladder (LC 127) [Hard] - BFS with wildcard pattern matching
3. Shortest Path Visiting All Nodes (LC 847) [Hard] - BFS with bitmask state
4. Sliding Puzzle (LC 773) [Hard] - BFS with board state as string
5. Minimum Genetic Mutation (LC 433) [Medium] - BFS with gene string state

---

## 5. Revision Checklist
- [ ] State = all information needed to determine next moves (position + visited + keys + ...)
- [ ] Encode state as string or long for HashSet membership check
- [ ] BFS guarantees shortest path in unweighted state graph
- [ ] Bidirectional BFS: search from both ends, meet in middle, O(b^(d/2))

> 🔗 **See Also:** [01-dsa/06-graphs.md](06-graphs.md) for basic BFS. [01-dsa/12-bitmask-dp.md](12-bitmask-dp.md) for bitmask state encoding.
