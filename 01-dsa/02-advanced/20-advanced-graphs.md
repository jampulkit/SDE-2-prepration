> ⚠️ **[OPTIONAL] — Rarely asked at SDE-2 interviews. Skip unless you've mastered files 00-14.**

# Advanced Graph Algorithms

## 1. Foundation

**Advanced graph algorithms handle problems beyond basic BFS/DFS: negative weights (Bellman-Ford), all-pairs shortest paths (Floyd-Warshall), bridges/articulation points (Tarjan's), and Euler paths.**

## 2. Core Patterns

### Bellman-Ford (Negative Weights) [🔥 Must Know]

```java
// Shortest path with negative weights. Detects negative cycles.
// O(V × E) — slower than Dijkstra but handles negatives.
public int[] bellmanFord(int n, int[][] edges, int src) {
    int[] dist = new int[n];
    Arrays.fill(dist, Integer.MAX_VALUE);
    dist[src] = 0;
    
    for (int i = 0; i < n - 1; i++) { // relax all edges V-1 times
        for (int[] edge : edges) {
            int u = edge[0], v = edge[1], w = edge[2];
            if (dist[u] != Integer.MAX_VALUE && dist[u] + w < dist[v]) {
                dist[v] = dist[u] + w;
            }
        }
    }
    
    // Check for negative cycles (one more relaxation)
    for (int[] edge : edges) {
        if (dist[edge[0]] != Integer.MAX_VALUE && dist[edge[0]] + edge[2] < dist[edge[1]]) {
            return null; // negative cycle detected
        }
    }
    return dist;
}
```

### Floyd-Warshall (All-Pairs Shortest Path)

```java
// O(V³) — shortest path between ALL pairs of vertices
public int[][] floydWarshall(int[][] graph, int n) {
    int[][] dist = new int[n][n];
    for (int[] row : dist) Arrays.fill(row, Integer.MAX_VALUE / 2);
    for (int i = 0; i < n; i++) dist[i][i] = 0;
    // Initialize with direct edges...
    
    for (int k = 0; k < n; k++)       // intermediate vertex
        for (int i = 0; i < n; i++)    // source
            for (int j = 0; j < n; j++) // destination
                dist[i][j] = Math.min(dist[i][j], dist[i][k] + dist[k][j]);
    return dist;
}
```

### Tarjan's Algorithm (Bridges & Articulation Points) [🔥 Must Know]

```java
// LC 1192: Critical Connections in a Network (find bridges)
int timer = 0;
public List<List<Integer>> criticalConnections(int n, List<List<Integer>> connections) {
    List<List<Integer>> graph = new ArrayList<>(), result = new ArrayList<>();
    for (int i = 0; i < n; i++) graph.add(new ArrayList<>());
    for (var c : connections) { graph.get(c.get(0)).add(c.get(1)); graph.get(c.get(1)).add(c.get(0)); }
    
    int[] disc = new int[n], low = new int[n];
    Arrays.fill(disc, -1);
    dfs(0, -1, graph, disc, low, result);
    return result;
}

void dfs(int u, int parent, List<List<Integer>> graph, int[] disc, int[] low, List<List<Integer>> result) {
    disc[u] = low[u] = timer++;
    for (int v : graph.get(u)) {
        if (v == parent) continue;
        if (disc[v] == -1) {
            dfs(v, u, graph, disc, low, result);
            low[u] = Math.min(low[u], low[v]);
            if (low[v] > disc[u]) result.add(List.of(u, v)); // bridge!
        } else {
            low[u] = Math.min(low[u], disc[v]); // back edge
        }
    }
}
```

💡 **Intuition — Bridges:** An edge (u,v) is a bridge if removing it disconnects the graph. Tarjan's detects this: if `low[v] > disc[u]`, there's no back edge from v's subtree to u or above — so (u,v) is the only connection.

### 0-1 BFS (Weights 0 or 1)

```java
// Use deque: 0-weight edges → add to front, 1-weight edges → add to back
// O(V + E) — faster than Dijkstra for 0/1 weights
public int[] bfs01(int n, List<List<int[]>> graph, int src) {
    int[] dist = new int[n];
    Arrays.fill(dist, Integer.MAX_VALUE);
    dist[src] = 0;
    Deque<Integer> deque = new ArrayDeque<>();
    deque.offerFirst(src);
    while (!deque.isEmpty()) {
        int u = deque.pollFirst();
        for (int[] edge : graph.get(u)) {
            int v = edge[0], w = edge[1];
            if (dist[u] + w < dist[v]) {
                dist[v] = dist[u] + w;
                if (w == 0) deque.offerFirst(v); else deque.offerLast(v);
            }
        }
    }
    return dist;
}
```

## 3. Algorithm Comparison

| Algorithm | Time | Space | Negative Weights | Negative Cycle Detection | Use Case |
|-----------|------|-------|-----------------|------------------------|----------|
| Dijkstra | O((V+E) log V) | O(V) | No | No | Single-source, non-negative weights |
| Bellman-Ford | O(V*E) | O(V) | Yes | Yes | Single-source, negative weights |
| Floyd-Warshall | O(V³) | O(V²) | Yes | Yes (negative diagonal) | All-pairs shortest path |
| 0-1 BFS | O(V+E) | O(V) | No (only 0 and 1) | No | Binary weight graphs |
| Tarjan's | O(V+E) | O(V) | N/A | N/A | Bridges, articulation points, SCCs |

🎯 **Likely Follow-ups:**
- **Q:** Why does Dijkstra fail with negative weights?
  **A:** Dijkstra assumes that once a node is finalized (popped from the priority queue), its shortest distance is known. With negative weights, a later path through a negative edge could produce a shorter distance, but Dijkstra won't revisit the node. Example: A→B (weight 1), A→C (weight 5), C→B (weight -10). Dijkstra finalizes B with distance 1, but the actual shortest is A→C→B = -5.
- **Q:** When would you use Floyd-Warshall over running Dijkstra from every node?
  **A:** Floyd-Warshall is simpler to implement and handles negative weights. Running Dijkstra V times is O(V(V+E) log V), which is faster for sparse graphs. Floyd-Warshall at O(V³) is better for dense graphs (E ≈ V²) or when you need negative weight support.
- **Q:** What is the difference between a bridge and an articulation point?
  **A:** A bridge is an EDGE whose removal disconnects the graph. An articulation point is a VERTEX whose removal disconnects the graph. Detection is similar: bridge if `low[v] > disc[u]`, articulation point if `low[v] >= disc[u]` (with special handling for the root).

---

## 4. LeetCode Problem List

**Top 5 must-solve:**
1. Critical Connections in a Network (LC 1192) [Hard] - Tarjan's bridges
2. Cheapest Flights Within K Stops (LC 787) [Medium] - Bellman-Ford with K iterations
3. Network Delay Time (LC 743) [Medium] - Dijkstra or Bellman-Ford
4. Swim in Rising Water (LC 778) [Hard] - Dijkstra on grid / binary search + BFS
5. Minimum Cost to Make at Least One Valid Path (LC 1368) [Hard] - 0-1 BFS

---

## 5. Revision Checklist
- [ ] Bellman-Ford: O(VE), handles negative weights, detects negative cycles (V-th relaxation)
- [ ] Floyd-Warshall: O(V³), all-pairs shortest path, triple nested loop (k, i, j)
- [ ] Tarjan's: disc[] + low[], bridge if `low[v] > disc[u]`, articulation point if `low[v] >= disc[u]`
- [ ] 0-1 BFS: deque, 0-weight to front, 1-weight to back, O(V+E)
- [ ] Dijkstra fails with negative weights → use Bellman-Ford

> 🔗 **See Also:** [01-dsa/06-graphs.md](06-graphs.md) for BFS, DFS, Dijkstra, Union-Find basics.
