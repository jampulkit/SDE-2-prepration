> ✅ **[CORE] — Must-do for SDE-2 interviews.**

# Graphs

## 1. Foundation

**A graph is a collection of nodes (vertices) connected by edges — unlike trees, graphs can have cycles, multiple paths between nodes, and disconnected components. They model relationships: social networks, road maps, dependencies, web pages.**

Graphs model relationships between entities — social networks, road maps, dependencies, web pages. Unlike trees, graphs can have cycles, multiple paths between nodes, and disconnected components.

💡 **Intuition:** Think of a city map. Intersections are nodes, roads are edges. Some roads are one-way (directed), some have tolls (weighted). You might want to find the shortest route (BFS/Dijkstra), check if two locations are connected (DFS/Union-Find), or find the cheapest way to connect all neighborhoods (MST). Every graph algorithm answers a specific type of question about this "map."

**Terminology:**
- **Vertex (node):** An entity
- **Edge:** A connection between two vertices
- **Directed graph (digraph):** Edges have direction (A→B ≠ B→A). Example: Twitter follows.
- **Undirected graph:** Edges are bidirectional (A—B). Example: Facebook friendships.
- **Weighted graph:** Edges have costs/distances. Example: road distances.
- **Degree:** Number of edges connected to a vertex. For directed: in-degree (incoming) + out-degree (outgoing).
- **Connected:** Every vertex is reachable from every other (undirected)
- **Strongly connected:** Every vertex reachable from every other following edge directions (directed)
- **DAG:** Directed Acyclic Graph — directed graph with no cycles. Example: task dependencies.
- **Sparse graph:** E ≈ V (few edges). Most real-world graphs.
- **Dense graph:** E ≈ V² (many edges). Rare in practice.

**Graph representations** [🔥 Must Know]:

| Representation | Space | Edge Lookup | Add Edge | Iterate Neighbors | Best For |
|---------------|-------|-------------|----------|-------------------|----------|
| Adjacency List | O(V+E) | O(degree) | O(1) | O(degree) | Sparse graphs (most interviews) ✅ |
| Adjacency Matrix | O(V²) | O(1) | O(1) | O(V) | Dense graphs, quick edge lookup |
| Edge List | O(E) | O(E) | O(1) | O(E) | Kruskal's algorithm, sorting edges |

💡 **Intuition — Which representation to use:**
- **Adjacency List:** Default choice for interviews. Most graph problems involve iterating over neighbors, which is O(degree) — efficient for sparse graphs.
- **Adjacency Matrix:** Use when you need O(1) edge lookup (e.g., "is there an edge between u and v?") or when the graph is dense. Wastes memory for sparse graphs.
- **Edge List:** Use when you need to sort edges (Kruskal's MST) or process edges in order.

**Building an adjacency list in Java:**

```java
// For numbered nodes 0 to n-1 (most common in interviews)
List<List<Integer>> graph = new ArrayList<>();
for (int i = 0; i < n; i++) graph.add(new ArrayList<>());

// From edge list: edges = [[0,1], [1,2], [0,2]]
for (int[] edge : edges) {
    graph.get(edge[0]).add(edge[1]);
    graph.get(edge[1]).add(edge[0]); // omit this line for directed graph
}

// Alternative: Map-based (for non-sequential or labeled nodes)
Map<String, List<String>> graph = new HashMap<>();
graph.computeIfAbsent("A", k -> new ArrayList<>()).add("B");
```

**Weighted graph:**

```java
// Adjacency list with weights: node → list of (neighbor, weight)
List<List<int[]>> graph = new ArrayList<>();
for (int i = 0; i < n; i++) graph.add(new ArrayList<>());
graph.get(u).add(new int[]{v, weight});
```

**Grid as implicit graph** [🔥 Must Know]:
Many interview problems use a 2D grid where each cell is a node and adjacent cells (up/down/left/right) are neighbors. No need to build an explicit graph — just use direction arrays.

```java
int[][] dirs = {{0,1}, {0,-1}, {1,0}, {-1,0}}; // right, left, down, up

for (int[] d : dirs) {
    int nr = row + d[0], nc = col + d[1];
    if (nr >= 0 && nr < rows && nc >= 0 && nc < cols && grid[nr][nc] != WALL) {
        // (nr, nc) is a valid neighbor — process it
    }
}
```

⚙️ **Under the Hood — Grid Coordinate Encoding:**
For grid problems, you often need to store visited cells in a Set. Since `HashSet<int[]>` doesn't work (arrays use reference equality), use one of these:

```java
// Option 1: Encode as single integer (most efficient)
int key = row * cols + col; // unique for each cell
Set<Integer> visited = new HashSet<>();
visited.add(key);

// Option 2: Encode as string (readable but slower)
String key = row + "," + col;
Set<String> visited = new HashSet<>();

// Option 3: Use boolean[][] (fastest for grids)
boolean[][] visited = new boolean[rows][cols];
visited[row][col] = true;

// Option 4: Modify grid in-place (saves space, but destructive)
grid[row][col] = '#'; // mark as visited
```

🎯 **Likely Follow-ups:**
- **Q:** When would you use an adjacency matrix over an adjacency list?
  **A:** When the graph is dense (E ≈ V²), when you need O(1) edge existence checks, or when V is small (< 1000). For most interview problems, adjacency list is the right choice.
- **Q:** How do you handle graphs with string-labeled nodes?
  **A:** Use `Map<String, List<String>>` instead of `List<List<Integer>>`. Or assign each string an integer ID using a HashMap, then use the standard integer-based adjacency list.

> 🔗 **See Also:** [01-dsa/05-trees.md](05-trees.md) — trees are a special case of graphs (connected, acyclic). [02-system-design/01-fundamentals.md](../02-system-design/01-fundamentals.md) for graph concepts in system design (dependency graphs, service meshes).

---

## 2. Core Patterns

### Pattern 1: BFS (Breadth-First Search) [🔥 Must Know]

**BFS explores all nodes at distance d before any node at distance d+1 — this guarantees the first time you reach a node, it's via the shortest path (in unweighted graphs).**

**When to recognize it:** Shortest path in unweighted graph, level-order traversal, minimum steps/moves, "nearest" anything, multi-source spreading (rotting oranges, walls and gates).

💡 **Intuition:** BFS is like dropping a stone in a pond. Ripples expand outward one ring at a time. Every cell at distance 1 is reached before any cell at distance 2. This is why BFS finds shortest paths — it explores in order of increasing distance.

```java
// BFS template — shortest path in unweighted graph
public int bfs(int start, int end, List<List<Integer>> graph) {
    Deque<Integer> queue = new ArrayDeque<>();
    Set<Integer> visited = new HashSet<>();
    queue.offer(start);
    visited.add(start);
    int distance = 0;

    while (!queue.isEmpty()) {
        int size = queue.size(); // process one "ring" at a time
        for (int i = 0; i < size; i++) {
            int node = queue.poll();
            if (node == end) return distance;
            for (int neighbor : graph.get(node)) {
                if (visited.add(neighbor)) { // add returns false if already present
                    queue.offer(neighbor);
                }
            }
        }
        distance++;
    }
    return -1; // unreachable
}
```

⚙️ **Under the Hood — Why `visited.add()` instead of `visited.contains()` + `visited.add()`:**
`HashSet.add()` returns `false` if the element already exists. Using it as the condition combines the check and the add into one operation — cleaner and slightly faster (one hash computation instead of two).

**BFS on grid — LC 994: Rotting Oranges** [🔥 Must Do]

```java
public int orangesRotting(int[][] grid) {
    int rows = grid.length, cols = grid[0].length;
    Deque<int[]> queue = new ArrayDeque<>();
    int fresh = 0;

    // Multi-source BFS: add ALL rotten oranges to queue initially
    for (int r = 0; r < rows; r++)
        for (int c = 0; c < cols; c++) {
            if (grid[r][c] == 2) queue.offer(new int[]{r, c});
            else if (grid[r][c] == 1) fresh++;
        }

    int[][] dirs = {{0,1},{0,-1},{1,0},{-1,0}};
    int minutes = 0;

    while (!queue.isEmpty() && fresh > 0) {
        int size = queue.size();
        for (int i = 0; i < size; i++) {
            int[] cell = queue.poll();
            for (int[] d : dirs) {
                int nr = cell[0] + d[0], nc = cell[1] + d[1];
                if (nr >= 0 && nr < rows && nc >= 0 && nc < cols && grid[nr][nc] == 1) {
                    grid[nr][nc] = 2; // mark as rotten (also serves as visited)
                    fresh--;
                    queue.offer(new int[]{nr, nc});
                }
            }
        }
        minutes++;
    }
    return fresh == 0 ? minutes : -1; // -1 if some oranges can't be reached
}
```

💡 **Intuition — Multi-source BFS:** Instead of running BFS from each rotten orange separately (which would be O(V²)), we add ALL rotten oranges to the queue at the start. This is equivalent to adding a virtual "super-source" connected to all rotten oranges with distance 0. The BFS then expands from all sources simultaneously, like multiple stones dropped in a pond at the same time.

**Dry run:** 
```
Grid:  2 1 1     Step 0: Queue = [(0,0)], fresh = 4
       1 1 0     Step 1: (0,0) rots (0,1) and (1,0). Queue = [(0,1),(1,0)], fresh = 2
       0 1 1     Step 2: (0,1) rots (0,2), (1,0) rots (1,1). Queue = [(0,2),(1,1)], fresh = 0... wait
                 Actually (0,2) and (1,1) rot. But (2,1) and (2,2) still fresh.
                 Step 3: (1,1) rots (2,1). Queue = [(2,1)], fresh = 1
                 Step 4: (2,1) rots (2,2). fresh = 0. minutes = 4 ✓
```

**Edge Cases:**
- ☐ No fresh oranges → return 0 (already done)
- ☐ No rotten oranges but fresh exist → return -1 (impossible)
- ☐ Fresh oranges unreachable (blocked by empty cells) → return -1
- ☐ Single cell → 0 if rotten, -1 if fresh with no rotten neighbor

🎯 **Likely Follow-ups:**
- **Q:** What's the difference between BFS and Dijkstra?
  **A:** BFS works on unweighted graphs (all edges cost 1). Dijkstra works on weighted graphs with non-negative weights. BFS uses a regular queue; Dijkstra uses a priority queue (min-heap). If all weights are 1, Dijkstra degenerates to BFS.
- **Q:** Can BFS find shortest path in a weighted graph?
  **A:** Only if all weights are equal. For different weights, use Dijkstra. For weights of 0 and 1 only, use 0-1 BFS with a deque (add weight-0 edges to front, weight-1 to back).
- **Q:** What's the time complexity of BFS?
  **A:** O(V + E) — each vertex is enqueued/dequeued once (O(V)), and each edge is examined once (O(E)). For grids: O(rows × cols).

> 🔗 **See Also:** [01-dsa/05-trees.md](05-trees.md) Pattern 2 for BFS on trees (same algorithm, no visited set needed).

---

### Pattern 2: DFS (Depth-First Search) [🔥 Must Know]

**DFS explores as deep as possible along each branch before backtracking — it's the go-to for finding connected components, detecting cycles, checking path existence, and any problem that requires exploring all possibilities.**

**When to recognize it:** Connected components, cycle detection, path existence, topological sort, backtracking on graphs.

💡 **Intuition:** DFS is like exploring a maze. You pick a direction and keep going until you hit a dead end, then backtrack to the last intersection and try a different direction. You mark walls you've visited so you don't go in circles.

```java
// DFS template — recursive (preferred for interviews)
Set<Integer> visited = new HashSet<>();

public void dfs(int node, List<List<Integer>> graph) {
    visited.add(node);
    for (int neighbor : graph.get(node)) {
        if (!visited.contains(neighbor)) {
            dfs(neighbor, graph);
        }
    }
}

// DFS template — iterative (for very deep graphs to avoid stack overflow)
public void dfsIterative(int start, List<List<Integer>> graph) {
    Deque<Integer> stack = new ArrayDeque<>();
    Set<Integer> visited = new HashSet<>();
    stack.push(start);

    while (!stack.isEmpty()) {
        int node = stack.pop();
        if (!visited.add(node)) continue; // skip if already visited
        for (int neighbor : graph.get(node)) {
            if (!visited.contains(neighbor)) stack.push(neighbor);
        }
    }
}
```

**DFS on grid — LC 200: Number of Islands** [🔥 Must Do]

```java
public int numIslands(char[][] grid) {
    int count = 0;
    for (int r = 0; r < grid.length; r++) {
        for (int c = 0; c < grid[0].length; c++) {
            if (grid[r][c] == '1') {
                count++;              // found a new island
                dfs(grid, r, c);      // sink the entire island
            }
        }
    }
    return count;
}

private void dfs(char[][] grid, int r, int c) {
    // Boundary check + already visited/water check
    if (r < 0 || r >= grid.length || c < 0 || c >= grid[0].length || grid[r][c] != '1') return;
    grid[r][c] = '0'; // mark visited by "sinking" the land (modifying grid in-place)
    dfs(grid, r + 1, c); // down
    dfs(grid, r - 1, c); // up
    dfs(grid, r, c + 1); // right
    dfs(grid, r, c - 1); // left
}
```

💡 **Intuition — "Sinking" the island:** When we find a '1', we DFS to mark all connected '1's as '0' (visited). This way, the next time we scan the grid, we won't count the same island again. Each DFS call explores one complete island.

**Counting connected components (general pattern):**

```java
// Count connected components in an undirected graph
public int countComponents(int n, List<List<Integer>> graph) {
    boolean[] visited = new boolean[n];
    int count = 0;
    for (int i = 0; i < n; i++) {
        if (!visited[i]) {
            count++;
            dfs(i, graph, visited); // explore entire component
        }
    }
    return count;
}
```

**Edge Cases:**
- ☐ Disconnected graph → must loop over ALL nodes, not just start from node 0
- ☐ Single node with no edges → one component
- ☐ Grid with all water → 0 islands
- ☐ Grid with all land → 1 island
- ☐ Very large grid → recursive DFS may stack overflow; use iterative or BFS

🎯 **Likely Follow-ups:**
- **Q:** BFS or DFS for Number of Islands?
  **A:** Both work with the same complexity O(rows × cols). DFS is simpler to code (recursive). BFS uses a queue and is iterative (no stack overflow risk). In interviews, DFS is more common for this problem.
- **Q:** How would you count islands in a stream of grid updates?
  **A:** Use Union-Find. Each time a cell becomes land, union it with adjacent land cells. The number of components is tracked by the Union-Find structure.

---

### Pattern 3: Topological Sort [🔥 Must Know]

**Order the nodes of a DAG so that for every edge u→v, u comes before v. If no such ordering exists, the graph has a cycle.**

**When to recognize it:** "Order of tasks with dependencies", "course schedule", "build order", "detect cycle in directed graph". Any problem with prerequisites/dependencies on a DAG.

💡 **Intuition:** Think of getting dressed. You must put on underwear before pants, socks before shoes. These are dependencies. Topological sort gives you a valid order to get dressed. If there's a circular dependency (pants require shoes, shoes require pants), no valid order exists — that's a cycle.

**Kahn's Algorithm (BFS-based)** — preferred in interviews because it's intuitive and naturally detects cycles:

```java
// LC 210: Course Schedule II [🔥 Must Do]
public int[] findOrder(int numCourses, int[][] prerequisites) {
    // Build graph and compute in-degrees
    List<List<Integer>> graph = new ArrayList<>();
    int[] inDegree = new int[numCourses];
    for (int i = 0; i < numCourses; i++) graph.add(new ArrayList<>());

    for (int[] pre : prerequisites) {
        graph.get(pre[1]).add(pre[0]); // pre[1] → pre[0] (must take pre[1] first)
        inDegree[pre[0]]++;
    }

    // Start with all nodes that have no prerequisites (in-degree 0)
    Deque<Integer> queue = new ArrayDeque<>();
    for (int i = 0; i < numCourses; i++) {
        if (inDegree[i] == 0) queue.offer(i);
    }

    // Process nodes in topological order
    int[] order = new int[numCourses];
    int idx = 0;
    while (!queue.isEmpty()) {
        int course = queue.poll();
        order[idx++] = course;
        for (int next : graph.get(course)) {
            if (--inDegree[next] == 0) queue.offer(next); // all prerequisites met
        }
    }
    return idx == numCourses ? order : new int[]{}; // empty = cycle detected
}
```

⚙️ **Under the Hood — Cycle Detection with Kahn's:**
If `idx < numCourses` after the BFS, some nodes never reached in-degree 0. This means they're part of a cycle — each node in the cycle always has at least one unprocessed predecessor (the other nodes in the cycle). This is the cleanest way to detect cycles in a directed graph.

**Dry run:** `numCourses=4, prerequisites=[[1,0],[2,0],[3,1],[3,2]]`

```
Graph: 0→1, 0→2, 1→3, 2→3
In-degrees: [0, 1, 1, 2]

Queue starts with: [0] (only node with in-degree 0)

Process 0: order=[0], reduce in-degree of 1 and 2
  inDegree: [0, 0, 0, 2]. Queue: [1, 2]

Process 1: order=[0,1], reduce in-degree of 3
  inDegree: [0, 0, 0, 1]. Queue: [2]

Process 2: order=[0,1,2], reduce in-degree of 3
  inDegree: [0, 0, 0, 0]. Queue: [3]

Process 3: order=[0,1,2,3]. idx=4 == numCourses ✓

Valid order: [0, 1, 2, 3]
```

**DFS-based topological sort (three-color approach):**

```java
// Uses three states: 0=unvisited (white), 1=in-progress (gray), 2=done (black)
public int[] topologicalSort(int n, List<List<Integer>> graph) {
    int[] state = new int[n];
    Deque<Integer> stack = new ArrayDeque<>(); // result in reverse order

    for (int i = 0; i < n; i++) {
        if (state[i] == 0 && !dfs(i, graph, state, stack)) return new int[]{}; // cycle
    }

    int[] result = new int[n];
    for (int i = 0; i < n; i++) result[i] = stack.pop();
    return result;
}

private boolean dfs(int node, List<List<Integer>> graph, int[] state, Deque<Integer> stack) {
    state[node] = 1; // mark as in-progress (gray)
    for (int neighbor : graph.get(node)) {
        if (state[neighbor] == 1) return false; // back edge → CYCLE!
        if (state[neighbor] == 0 && !dfs(neighbor, graph, state, stack)) return false;
    }
    state[node] = 2; // mark as done (black)
    stack.push(node); // add to result (reverse postorder)
    return true;
}
```

| Approach | Pros | Cons | Best When |
|----------|------|------|-----------|
| Kahn's (BFS) | Intuitive, easy cycle detection, gives one valid order | Needs in-degree array | Default choice for interviews |
| DFS (three-color) | No in-degree array needed, natural for recursive problems | Cycle detection is trickier | When you're already doing DFS |

**Edge Cases:**
- ☐ No prerequisites → any order is valid (all in-degrees are 0)
- ☐ Cycle exists → return empty array
- ☐ Multiple valid orderings → return any one
- ☐ Single node → trivially ordered
- ☐ Disconnected DAG → Kahn's handles this (multiple nodes start with in-degree 0)

🎯 **Likely Follow-ups:**
- **Q:** Can there be multiple valid topological orderings?
  **A:** Yes — whenever the queue has more than one node at the same time in Kahn's algorithm, any of them can go next. The number of valid orderings can be exponential.
- **Q:** How would you find the longest path in a DAG?
  **A:** Process nodes in topological order. For each node, `dist[v] = max(dist[u] + weight(u,v))` for all predecessors u. This is DP on a DAG. (See LC 2050: Parallel Courses III)
- **Q:** How does topological sort relate to build systems?
  **A:** Build systems (Make, Gradle, Bazel) use topological sort to determine compilation order. Source files are nodes, dependencies are edges. Cycles mean circular dependencies — a build error.

> 🔗 **See Also:** [01-dsa/07-dynamic-programming.md](07-dynamic-programming.md) for DP on DAGs (topological order enables DP). [02-system-design/03-message-queues-event-driven.md](../02-system-design/03-message-queues-event-driven.md) for event ordering in distributed systems.

---

### Pattern 4: Union-Find (Disjoint Set Union) [🔥 Must Know]

**Union-Find tracks which elements belong to the same group, supporting near-O(1) "merge two groups" and "are these in the same group?" operations.**

**When to recognize it:** "Connected components", "are two nodes connected?", "number of groups", "redundant connection". Especially useful when edges are added dynamically.

💡 **Intuition:** Imagine a room full of people. Initially, everyone is their own group. When two people shake hands, their groups merge. Union-Find efficiently answers: "Are Alice and Bob in the same group?" and "Merge Alice's group with Bob's group." Path compression is like creating a shortcut — instead of following a long chain of handshakes, everyone points directly to the group leader.

```java
class UnionFind {
    int[] parent, rank;
    int components;

    UnionFind(int n) {
        parent = new int[n];
        rank = new int[n];
        components = n;
        for (int i = 0; i < n; i++) parent[i] = i; // everyone is their own parent
    }

    int find(int x) {
        if (parent[x] != x) parent[x] = find(parent[x]); // path compression
        return parent[x];
    }

    boolean union(int x, int y) {
        int px = find(x), py = find(y);
        if (px == py) return false; // already in same group
        // Union by rank: attach shorter tree under taller tree
        if (rank[px] < rank[py]) { int tmp = px; px = py; py = tmp; }
        parent[py] = px;
        if (rank[px] == rank[py]) rank[px]++;
        components--;
        return true;
    }

    boolean connected(int x, int y) { return find(x) == find(y); }
}
```

⚙️ **Under the Hood — Path Compression Visualization:**

```
Before path compression:        After find(4) with path compression:
    0                               0
    |                             / | \
    1                            1  2  4
    |                            |
    2                            3
    |
    3
    |
    4

find(4): 4→3→2→1→0 (root)
Path compression: 4→0, 3→0, 2→0 (all point directly to root)
Next find(4): 4→0 (one step!)
```

**Complexity with path compression + union by rank:**
- `find`: O(α(n)) ≈ O(1) amortized (α = inverse Ackermann function, ≤ 4 for any practical n)
- `union`: O(α(n)) ≈ O(1) amortized
- Without optimizations: `find` is O(n) worst case (long chain)

| Optimization | find() Complexity | Notes |
|-------------|------------------|-------|
| None | O(n) | Degenerates to linked list |
| Path compression only | O(log n) amortized | Good enough for most cases |
| Union by rank only | O(log n) | Tree height bounded by log n |
| Both | O(α(n)) ≈ O(1) | Optimal — always use both |

**Example — LC 684: Redundant Connection** [🔥 Must Do]

```java
// Find the edge that, when removed, makes the graph a tree
public int[] findRedundantConnection(int[][] edges) {
    int n = edges.length;
    UnionFind uf = new UnionFind(n + 1); // 1-indexed nodes

    for (int[] edge : edges) {
        if (!uf.union(edge[0], edge[1])) {
            return edge; // this edge creates a cycle — it's redundant
        }
    }
    return new int[]{};
}
```

💡 **Intuition:** Process edges one by one. If both endpoints are already in the same component (connected), adding this edge creates a cycle — it's the redundant one.

🎯 **Likely Follow-ups:**
- **Q:** Union-Find vs DFS for connected components?
  **A:** DFS is simpler for static graphs (build once, query once). Union-Find is better for dynamic graphs (edges added over time, queries interleaved with additions). Union-Find also naturally counts components.
- **Q:** Can Union-Find detect cycles in directed graphs?
  **A:** No — Union-Find works for undirected graphs only. For directed graphs, use DFS with three-color marking (topological sort approach).
- **Q:** How would you implement Union-Find with weighted edges?
  **A:** Store a weight/offset for each node relative to its parent. During `find`, accumulate weights along the path. Used in problems like "Evaluate Division" (LC 399).

> 🔗 **See Also:** [01-dsa/01-arrays-strings-hashing.md](01-arrays-strings-hashing.md) Pattern 5 — HashSet for sequences is an alternative to Union-Find for static connectivity.

---

### Pattern 5: Dijkstra's Algorithm (Shortest Path — Weighted) [🔥 Must Know]

**Use a min-heap to always process the node with the smallest known distance first. Relax edges: if going through the current node gives a shorter path to a neighbor, update it.**

**When to recognize it:** Shortest path in a weighted graph with non-negative weights.

💡 **Intuition:** Dijkstra is like BFS, but instead of a regular queue (FIFO), it uses a priority queue (min-heap) that always processes the closest unvisited node first. This ensures that when you process a node, you've already found the shortest path to it.

```java
// LC 743: Network Delay Time [🔥 Must Do]
public int networkDelayTime(int[][] times, int n, int k) {
    // Build weighted adjacency list
    List<List<int[]>> graph = new ArrayList<>();
    for (int i = 0; i <= n; i++) graph.add(new ArrayList<>());
    for (int[] t : times) graph.get(t[0]).add(new int[]{t[1], t[2]});

    // Distance array — shortest known distance from source to each node
    int[] dist = new int[n + 1];
    Arrays.fill(dist, Integer.MAX_VALUE);
    dist[k] = 0;

    // Min-heap: (distance, node) — always process closest node first
    PriorityQueue<int[]> pq = new PriorityQueue<>(Comparator.comparingInt(a -> a[0]));
    pq.offer(new int[]{0, k});

    while (!pq.isEmpty()) {
        int[] curr = pq.poll();
        int d = curr[0], u = curr[1];
        if (d > dist[u]) continue; // CRITICAL: skip outdated entries (lazy deletion)

        for (int[] edge : graph.get(u)) {
            int v = edge[0], w = edge[1];
            if (dist[u] + w < dist[v]) {     // relaxation
                dist[v] = dist[u] + w;
                pq.offer(new int[]{dist[v], v});
            }
        }
    }

    int maxDist = 0;
    for (int i = 1; i <= n; i++) maxDist = Math.max(maxDist, dist[i]);
    return maxDist == Integer.MAX_VALUE ? -1 : maxDist;
}
```

⚙️ **Under the Hood — Why `if (d > dist[u]) continue`:**
Java's PriorityQueue doesn't support `decreaseKey`. When we find a shorter path to a node, we add a new entry to the heap instead of updating the existing one. This means the heap can have multiple entries for the same node. The `d > dist[u]` check skips outdated (longer) entries — this is called "lazy deletion."

**Complexity:** O((V + E) log V) with binary heap. The log V factor comes from heap operations.

| Algorithm | Graph Type | Time | Space | Notes |
|-----------|-----------|------|-------|-------|
| BFS | Unweighted | O(V+E) | O(V) | All edges weight 1 |
| Dijkstra | Weighted (non-negative) | O((V+E) log V) | O(V) | Min-heap based |
| Bellman-Ford | Weighted (any) | O(VE) | O(V) | Handles negative weights |
| Floyd-Warshall | All pairs | O(V³) | O(V²) | All pairs shortest path |
| 0-1 BFS | Weights 0 or 1 only | O(V+E) | O(V) | Deque: 0-weight to front, 1-weight to back |

**Edge Cases:**
- ☐ Unreachable nodes → dist stays MAX_VALUE → return -1
- ☐ Source node → dist = 0
- ☐ Negative weights → Dijkstra gives WRONG answers. Use Bellman-Ford.
- ☐ Self-loops with weight 0 → handled correctly (d > dist[u] skips them)

🎯 **Likely Follow-ups:**
- **Q:** Why doesn't Dijkstra work with negative weights?
  **A:** Dijkstra assumes that once a node is processed (popped from heap), its shortest distance is final. With negative weights, a later edge could provide a shorter path to an already-processed node, violating this assumption.
- **Q:** What's 0-1 BFS?
  **A:** When all edge weights are 0 or 1, use a deque instead of a heap. Add 0-weight neighbors to the front, 1-weight neighbors to the back. This gives O(V+E) instead of O((V+E) log V).

> 🔗 **See Also:** [01-dsa/09-heap-priority-queue.md](09-heap-priority-queue.md) for heap internals used in Dijkstra.

---

### Pattern 6: Cycle Detection

**For undirected graphs: if DFS visits a neighbor that's already visited AND it's not the parent, there's a cycle. For directed graphs: use three-color DFS (white/gray/black).**

**Undirected graph — DFS with parent tracking:**

```java
public boolean hasCycle(List<List<Integer>> graph, int n) {
    boolean[] visited = new boolean[n];
    for (int i = 0; i < n; i++) {
        if (!visited[i] && dfs(graph, i, -1, visited)) return true;
    }
    return false;
}

private boolean dfs(List<List<Integer>> graph, int node, int parent, boolean[] visited) {
    visited[node] = true;
    for (int neighbor : graph.get(node)) {
        if (!visited[neighbor]) {
            if (dfs(graph, neighbor, node, visited)) return true;
        } else if (neighbor != parent) {
            return true; // visited neighbor that isn't parent = CYCLE
        }
    }
    return false;
}
```

💡 **Intuition — Why check `neighbor != parent`:** In an undirected graph, if node A is connected to node B, then B is also connected to A. When DFS goes from A to B, B sees A as a neighbor. But A is B's parent in the DFS tree — this isn't a cycle, it's just the edge we came from. A real cycle is when we reach a visited node through a DIFFERENT path.

**Directed graph — three-color DFS:** Already shown in Pattern 3 (topological sort). Gray node = in current DFS path. Visiting a gray node = back edge = cycle.

---

### Pattern 7: Minimum Spanning Tree (MST)

**Connect all nodes with the minimum total edge cost. Kruskal's: sort edges by weight, add them one by one using Union-Find, skip edges that would create a cycle.**

**When to recognize it:** "Connect all nodes with minimum total cost", "minimum cost to connect all cities".

💡 **Intuition:** Imagine you're building roads between cities. You want every city connected (directly or indirectly) with the minimum total road length. Kruskal's greedy approach: always build the cheapest road that connects two previously disconnected cities.

```java
// LC 1584: Min Cost to Connect All Points [🔥 Must Do]
public int minCostConnectPoints(int[][] points) {
    int n = points.length;
    List<int[]> edges = new ArrayList<>(); // {cost, i, j}

    // Generate all possible edges with Manhattan distance
    for (int i = 0; i < n; i++)
        for (int j = i + 1; j < n; j++) {
            int cost = Math.abs(points[i][0] - points[j][0]) + Math.abs(points[i][1] - points[j][1]);
            edges.add(new int[]{cost, i, j});
        }

    edges.sort(Comparator.comparingInt(a -> a[0])); // sort by cost
    UnionFind uf = new UnionFind(n);
    int totalCost = 0, edgesUsed = 0;

    for (int[] edge : edges) {
        if (uf.union(edge[1], edge[2])) { // only add if it connects two components
            totalCost += edge[0];
            if (++edgesUsed == n - 1) break; // MST has exactly V-1 edges
        }
    }
    return totalCost;
}
```

**Complexity:** O(E log E) for sorting edges. For complete graph: E = V²/2, so O(V² log V).

**MST properties:**
- MST has exactly V-1 edges
- MST is unique if all edge weights are distinct
- Cutting any edge in MST splits it into two components; the cut edge is the minimum weight edge crossing that cut

---

### Pattern 8: Bipartite Check / Graph Coloring

**Try to color the graph with two colors such that no adjacent nodes share a color. If you can, it's bipartite. If you find a conflict, it's not.**

**When to recognize it:** "Can we divide nodes into two groups?", "is graph 2-colorable?", "possible bipartition".

💡 **Intuition:** Think of assigning students to two teams for a debate. Friends can't be on the same team. You start coloring: "Alice is Team A, so her friend Bob must be Team B, and Bob's friend Carol must be Team A..." If you ever need to assign someone to both teams, it's impossible — the graph isn't bipartite.

```java
// LC 785: Is Graph Bipartite? [🔥 Must Do]
public boolean isBipartite(int[][] graph) {
    int n = graph.length;
    int[] color = new int[n]; // 0=uncolored, 1=group A, -1=group B

    for (int i = 0; i < n; i++) {
        if (color[i] == 0 && !bfs(graph, i, color)) return false;
    }
    return true;
}

private boolean bfs(int[][] graph, int start, int[] color) {
    Deque<Integer> queue = new ArrayDeque<>();
    queue.offer(start);
    color[start] = 1;

    while (!queue.isEmpty()) {
        int node = queue.poll();
        for (int neighbor : graph[node]) {
            if (color[neighbor] == 0) {
                color[neighbor] = -color[node]; // opposite color
                queue.offer(neighbor);
            } else if (color[neighbor] == color[node]) {
                return false; // same color as neighbor → NOT bipartite
            }
        }
    }
    return true;
}
```

**Key fact:** A graph is bipartite if and only if it contains no odd-length cycles.

🎯 **Likely Follow-ups:**
- **Q:** Can you check bipartiteness with DFS instead of BFS?
  **A:** Yes — same coloring logic, just use DFS instead of BFS. Both are O(V+E).
- **Q:** What's the connection between bipartite graphs and matching?
  **A:** Maximum matching in bipartite graphs can be found with the Hopcroft-Karp algorithm in O(E√V). This is used in assignment problems.


---

## 3. Patterns Summary Table

| # | Pattern | When to Use | Key Idea | Time | Space | Example Problem |
|---|---------|------------|----------|------|-------|-----------------|
| 1 | BFS | Shortest path (unweighted), levels | Queue + visited, level-by-level | O(V+E) | O(V) | Rotting Oranges (LC 994) |
| 2 | DFS | Components, paths, cycle detection | Recursion/stack + visited | O(V+E) | O(V) | Number of Islands (LC 200) |
| 3 | Topological Sort | Dependencies, ordering DAG | Kahn's (BFS + in-degree) or DFS 3-color | O(V+E) | O(V) | Course Schedule II (LC 210) |
| 4 | Union-Find | Dynamic connectivity, components | Path compression + union by rank | O(α(n))≈O(1) | O(V) | Redundant Connection (LC 684) |
| 5 | Dijkstra | Shortest path (weighted, non-negative) | Min-heap + relaxation + lazy deletion | O((V+E)logV) | O(V) | Network Delay (LC 743) |
| 6 | Cycle Detection | Detect cycles | Undirected: parent check; Directed: 3-color | O(V+E) | O(V) | Course Schedule (LC 207) |
| 7 | MST (Kruskal) | Min cost to connect all | Sort edges + Union-Find, stop at V-1 | O(E log E) | O(V) | Min Cost Connect (LC 1584) |
| 8 | Bipartite | Two-group division | BFS/DFS coloring with +1/-1 | O(V+E) | O(V) | Is Bipartite (LC 785) |

**Pattern Selection Flowchart:**

```
Graph problem?
├── Grid problem? → DFS/BFS on grid (4-directional)
│   ├── Count components → DFS (sink visited cells)
│   ├── Shortest path → BFS
│   └── Fill/mark regions → DFS from border
├── Ordering/dependencies? → Topological Sort (Kahn's BFS)
├── Connectivity?
│   ├── Static graph → DFS (count components)
│   └── Dynamic (edges added over time) → Union-Find
├── Shortest path?
│   ├── Unweighted → BFS
│   ├── Weighted (non-negative) → Dijkstra
│   ├── Weighted (negative) → Bellman-Ford
│   └── Weights 0 or 1 → 0-1 BFS (deque)
├── Minimum spanning tree? → Kruskal's (sort edges + Union-Find)
├── Two-group division? → Bipartite check (BFS coloring)
└── Cycle detection?
    ├── Undirected → DFS with parent tracking
    └── Directed → DFS with 3-color (or Kahn's: cycle if count < V)
```

---

## 4. LeetCode Problem List (Must-Solve)

### Easy

| # | Problem Name | LC # | Pattern(s) | Why Important |
|---|-------------|------|-----------|---------------|
| 1 | Flood Fill | 733 | DFS/BFS on grid | [🔥 Must Do] Simplest grid traversal |
| 2 | Find if Path Exists in Graph | 1971 | BFS/DFS/Union-Find | Basic connectivity |
| 3 | Island Perimeter | 463 | Grid counting | Count edges, not components |
| 4 | Find the Town Judge | 997 | In-degree/out-degree | Degree counting |

### Medium

| # | Problem Name | LC # | Pattern(s) | Why Important |
|---|-------------|------|-----------|---------------|
| 1 | Number of Islands | 200 | DFS/BFS on grid | [🔥 Must Do] Classic grid DFS |
| 2 | Clone Graph | 133 | DFS + HashMap | [🔥 Must Do] Deep copy graph |
| 3 | Course Schedule | 207 | Topological sort / cycle | [🔥 Must Do] Cycle detection in DAG |
| 4 | Course Schedule II | 210 | Topological sort | [🔥 Must Do] Return valid ordering |
| 5 | Rotting Oranges | 994 | Multi-source BFS | [🔥 Must Do] BFS from multiple sources |
| 6 | Pacific Atlantic Water Flow | 417 | Multi-source DFS | Reverse thinking — DFS from ocean |
| 7 | Surrounded Regions | 130 | DFS from border | Mark border-connected, flip rest |
| 8 | Number of Connected Components | 323 | DFS/Union-Find | [🔥 Must Do] Count components |
| 9 | Graph Valid Tree | 261 | Union-Find / DFS | Tree = connected + no cycle + V-1 edges |
| 10 | Redundant Connection | 684 | Union-Find | [🔥 Must Do] Find cycle-causing edge |
| 11 | Network Delay Time | 743 | Dijkstra | [🔥 Must Do] Shortest path weighted |
| 12 | Cheapest Flights Within K Stops | 787 | BFS/Bellman-Ford | Modified shortest path with constraint |
| 13 | Is Graph Bipartite? | 785 | BFS coloring | [🔥 Must Do] Two-coloring |
| 14 | Possible Bipartition | 886 | BFS coloring | Extension of bipartite |
| 15 | Min Cost to Connect All Points | 1584 | Kruskal's MST | [🔥 Must Do] MST with Union-Find |
| 16 | Accounts Merge | 721 | Union-Find | [🔥 Must Do] Group by shared emails |
| 17 | Evaluate Division | 399 | DFS/BFS weighted graph | Graph from equations |
| 18 | Word Ladder | 127 | BFS | [🔥 Must Do] Shortest transformation |
| 19 | Snakes and Ladders | 909 | BFS | Shortest path on board |
| 20 | Minimum Height Trees | 310 | Topological sort (leaf removal) | Peel leaves layer by layer |
| 21 | All Paths From Source to Target | 797 | DFS/backtracking | All paths in DAG |
| 22 | Keys and Rooms | 841 | DFS/BFS | Reachability |
| 23 | Number of Provinces | 547 | DFS/Union-Find | Connected components in adjacency matrix |
| 24 | Shortest Path in Binary Matrix | 1091 | BFS | 8-directional BFS |
| 25 | Max Area of Island | 695 | DFS on grid | DFS with area counting |
| 26 | 01 Matrix | 542 | Multi-source BFS | BFS from all 0s |
| 27 | Walls and Gates | 286 | Multi-source BFS | BFS from all gates |
| 28 | Alien Dictionary | 269 | Topological sort | [🔥 Must Do] Build graph from ordering |
| 29 | Shortest Bridge | 934 | DFS + BFS | Find island (DFS), expand (BFS) |
| 30 | Open the Lock | 752 | BFS | State-space BFS |

### Hard

| # | Problem Name | LC # | Pattern(s) | Why Important |
|---|-------------|------|-----------|---------------|
| 1 | Word Ladder II | 126 | BFS + DFS backtrack | All shortest transformations |
| 2 | Alien Dictionary | 269 | Topological sort | [🔥 Must Do] Premium classic |
| 3 | Swim in Rising Water | 778 | Dijkstra / binary search + BFS | Min-max path |
| 4 | Critical Connections in a Network | 1192 | Tarjan's bridges | [🔥 Must Do] Bridge finding |
| 5 | Reconstruct Itinerary | 332 | Euler path (DFS) | Hierholzer's algorithm |
| 6 | Shortest Path Visiting All Nodes | 847 | BFS + bitmask | State = (node, visited set) |
| 7 | Making A Large Island | 827 | DFS + Union-Find | Component sizes + flip one cell |
| 8 | Bus Routes | 815 | BFS on routes | Route-level BFS |
| 9 | Minimum Cost to Make at Least One Valid Path | 1368 | 0-1 BFS (deque) | Deque-based shortest path |
| 10 | Parallel Courses III | 2050 | Topological sort + DP | Longest path in DAG |

---

## 5. Interview Strategy

**Decision tree:** (see flowchart in Section 3)

**Communication tips:**

```
You: "This is a shortest path problem on an unweighted graph, so I'll use BFS.
     Each cell in the grid is a node, and adjacent cells are neighbors.
     BFS guarantees the first time I reach the target, it's the shortest path."

You: "I see dependencies between tasks, which forms a DAG. I'll use Kahn's
     algorithm for topological sort — start with tasks that have no prerequisites
     (in-degree 0), process them, and reduce in-degrees of dependent tasks.
     If I can't process all tasks, there's a cycle."

You: "This is a dynamic connectivity problem — edges are added one by one.
     Union-Find is perfect here. I'll use path compression and union by rank
     for near-O(1) operations."
```

**Common mistakes:**
- Forgetting the visited set → infinite loop in cyclic graphs
- Using DFS for shortest path (DFS doesn't guarantee shortest path in general graphs)
- Not handling disconnected components (loop over ALL nodes, not just node 0)
- In grid problems: forgetting boundary checks before accessing `grid[nr][nc]`
- Union-Find: forgetting path compression → O(n) instead of O(α(n))
- Dijkstra: using with negative weights (gives wrong answers)
- Topological sort: confusing edge direction (pre[1]→pre[0] means "take pre[1] before pre[0]")
- Using `HashSet<int[]>` for visited cells (arrays use reference equality — use encoding instead)

💥 **What Can Go Wrong in Interviews:**

| Mistake | Impact | Prevention |
|---------|--------|------------|
| No visited set | Infinite loop | Always mark nodes as visited |
| DFS for shortest path | Wrong answer | Use BFS for unweighted, Dijkstra for weighted |
| Forget disconnected components | Miss some nodes | Loop over all nodes: `for (int i = 0; i < n; i++)` |
| Wrong edge direction in topo sort | Wrong ordering | Draw the dependency graph before coding |
| Dijkstra with negative weights | Wrong shortest paths | Ask: "Are all weights non-negative?" |
| Grid boundary violation | ArrayIndexOutOfBounds | Always check `nr >= 0 && nr < rows && nc >= 0 && nc < cols` |

---

## 6. Edge Cases & Pitfalls

**Graph edge cases:**
- ☐ Empty graph (0 nodes or 0 edges) → return 0/empty
- ☐ Single node → one component, no cycle
- ☐ Disconnected graph → multiple components, must check all
- ☐ Self-loops → handle in cycle detection (undirected: `neighbor == node`, directed: gray node)
- ☐ Parallel edges (multiple edges between same pair) → adjacency list handles naturally
- ☐ Node values vs node indices (0-indexed vs 1-indexed) → clarify with interviewer
- ☐ Grid boundaries → always check before accessing

**Java-specific pitfalls:**

```java
// PITFALL 1: PriorityQueue comparator overflow
PriorityQueue<int[]> pq = new PriorityQueue<>((a, b) -> a[0] - b[0]);
// If a[0] = Integer.MAX_VALUE and b[0] = -1, subtraction overflows!
// SAFE: use Integer.compare
PriorityQueue<int[]> pq = new PriorityQueue<>(Comparator.comparingInt(a -> a[0]));

// PITFALL 2: HashSet<int[]> doesn't work as expected
Set<int[]> visited = new HashSet<>();
visited.add(new int[]{1, 2});
visited.contains(new int[]{1, 2}); // FALSE! Different array objects
// Use: boolean[][] visited, or encode as int (row * cols + col), or String "1,2"

// PITFALL 3: Recursive DFS stack overflow on large grids
// Grid 500×500 = 250,000 cells. Max recursion depth = 250,000.
// Java default stack size ~512KB → ~10,000-20,000 frames → StackOverflowError
// Solution: use iterative DFS with explicit stack, or BFS

// PITFALL 4: Modifying grid as visited marker
// Works in interviews, but mention it: "I'm modifying the input grid to mark visited cells.
// In production, I'd use a separate visited array to preserve the original data."
```

---

## 7. Connections to Other Topics

| This Pattern | Connects To | How |
|-------------|-------------|-----|
| BFS | [01-dsa/05-trees.md](05-trees.md) | Tree BFS = graph BFS without visited set (no cycles) |
| DFS | [01-dsa/08-greedy-backtracking.md](08-greedy-backtracking.md) | DFS with choices = backtracking |
| Topological Sort | [01-dsa/07-dynamic-programming.md](07-dynamic-programming.md) | DP on DAGs follows topological order |
| Union-Find | [01-dsa/01-arrays-strings-hashing.md](01-arrays-strings-hashing.md) | Alternative to HashSet for connectivity (LC 128 longest consecutive) |
| Dijkstra | [01-dsa/09-heap-priority-queue.md](09-heap-priority-queue.md) | Dijkstra = BFS with a min-heap |
| Grid DFS | [02-system-design/problems/file-storage-system.md](../02-system-design/problems/file-storage-system.md) | File system is a tree/graph structure |
| Cycle detection | [03-distributed-systems/03-distributed-transactions.md](../03-distributed-systems/03-distributed-transactions.md) | Deadlock = cycle in resource wait graph |
| MST | [02-system-design/01-fundamentals.md](../02-system-design/01-fundamentals.md) | Network topology optimization |
| Bipartite | [04-lld/02-design-patterns.md](../04-lld/02-design-patterns.md) | Observer pattern models bipartite relationships |
| BFS shortest path | [02-system-design/problems/chat-system.md](../02-system-design/problems/chat-system.md) | Routing in network graphs |

---

## 8. Revision Checklist

**Graph representations:**
- [ ] Adjacency list: `List<List<Integer>>` — O(V+E) space, best for sparse graphs
- [ ] Grid as graph: `int[][] dirs = {{0,1},{0,-1},{1,0},{-1,0}}`, always check bounds
- [ ] Weighted: `List<List<int[]>>` where int[] = {neighbor, weight}
- [ ] Grid visited: `boolean[][]` or modify grid in-place or encode `row * cols + col`

**Algorithms:**
- [ ] BFS: queue + visited, level-by-level, shortest path unweighted. O(V+E).
- [ ] DFS: recursion/stack + visited, components, paths. O(V+E).
- [ ] Topological sort (Kahn's): in-degree array, queue starts with in-degree 0, cycle if count < V. O(V+E).
- [ ] Union-Find: path compression + union by rank, O(α(n)) ≈ O(1) per operation.
- [ ] Dijkstra: min-heap, relaxation, skip outdated entries (`d > dist[u]`), O((V+E) log V).
- [ ] Kruskal's MST: sort edges, Union-Find, stop at V-1 edges. O(E log E).
- [ ] Bipartite: BFS/DFS coloring with +1/-1. O(V+E).
- [ ] Cycle detection: undirected = parent check, directed = 3-color DFS.

**Key facts:**
- [ ] Tree = connected graph with V-1 edges and no cycles
- [ ] DAG = directed graph with no cycles → topological sort exists
- [ ] Dijkstra fails with negative weights → use Bellman-Ford
- [ ] BFS = shortest path (unweighted), Dijkstra = shortest path (weighted non-negative)
- [ ] Union-Find with both optimizations: O(α(n)) ≈ O(1) amortized
- [ ] MST has exactly V-1 edges
- [ ] Bipartite ↔ no odd-length cycles
- [ ] Multi-source BFS: add all sources to queue initially (virtual super-source)

**Top 12 must-solve:**
1. Number of Islands (LC 200) [Medium] — Grid DFS
2. Course Schedule II (LC 210) [Medium] — Topological sort
3. Rotting Oranges (LC 994) [Medium] — Multi-source BFS
4. Clone Graph (LC 133) [Medium] — DFS + HashMap deep copy
5. Word Ladder (LC 127) [Hard] — BFS shortest transformation
6. Network Delay Time (LC 743) [Medium] — Dijkstra
7. Redundant Connection (LC 684) [Medium] — Union-Find cycle detection
8. Accounts Merge (LC 721) [Medium] — Union-Find grouping
9. Is Graph Bipartite (LC 785) [Medium] — BFS coloring
10. Min Cost to Connect All Points (LC 1584) [Medium] — Kruskal's MST
11. Alien Dictionary (LC 269) [Hard] — Topological sort from ordering
12. Pacific Atlantic Water Flow (LC 417) [Medium] — Multi-source reverse DFS

---

## 📋 Suggested New Documents

### 1. Advanced Graph Algorithms
- **Placement**: `01-dsa/12-advanced-graphs.md`
- **Why needed**: Tarjan's algorithm (bridges, articulation points, SCCs), Bellman-Ford, Floyd-Warshall, A* search, Euler paths, and network flow appear in hard interview problems and are not covered in the current project.
- **Key subtopics**: Tarjan's bridges/SCCs, Bellman-Ford (negative weights), Floyd-Warshall (all pairs), 0-1 BFS, A* heuristic search, Euler path/circuit, maximum flow (overview)

### 2. State-Space BFS / BFS with Complex States
- **Placement**: `01-dsa/12-state-space-search.md`
- **Why needed**: Problems like "Open the Lock" (LC 752), "Shortest Path Visiting All Nodes" (LC 847), and "Sliding Puzzle" (LC 773) require BFS where the "state" is more than just a node — it includes visited sets, key collections, or board configurations. This pattern is distinct from standard graph BFS.
- **Key subtopics**: State encoding (bitmask, string), BFS on implicit graphs, bidirectional BFS, A* with heuristics
