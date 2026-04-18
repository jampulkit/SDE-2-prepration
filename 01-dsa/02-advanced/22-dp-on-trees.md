> ⚠️ **[OPTIONAL] — Rarely asked at SDE-2 interviews. Skip unless you've mastered files 00-14.**

# DP on Trees

## 1. Foundation

**Tree DP combines tree traversal (DFS) with dynamic programming — at each node, compute the optimal answer using results from children. The key insight: a tree's recursive structure naturally defines subproblems.**

💡 **Intuition:** In array DP, `dp[i]` depends on `dp[i-1]`. In tree DP, `dp[node]` depends on `dp[children]`. You solve bottom-up: compute answers for leaves first, then propagate up to the root.

## 2. Core Patterns

### Rob/Not-Rob (House Robber III) [🔥 Must Do]

```java
// LC 337: House Robber III — can't rob adjacent nodes
public int rob(TreeNode root) {
    int[] result = dfs(root); // [notRob, rob]
    return Math.max(result[0], result[1]);
}

private int[] dfs(TreeNode node) {
    if (node == null) return new int[]{0, 0};
    int[] left = dfs(node.left);
    int[] right = dfs(node.right);
    
    int notRob = Math.max(left[0], left[1]) + Math.max(right[0], right[1]); // skip this node
    int rob = node.val + left[0] + right[0]; // rob this node, can't rob children
    return new int[]{notRob, rob};
}
```

### Diameter / Longest Path

```java
// LC 543: Diameter = max(leftHeight + rightHeight) across all nodes
int diameter = 0;
private int height(TreeNode node) {
    if (node == null) return 0;
    int left = height(node.left), right = height(node.right);
    diameter = Math.max(diameter, left + right); // path through this node
    return 1 + Math.max(left, right);
}
```

### Maximum Path Sum (Any-to-Any)

```java
// LC 124: path can start/end at any node
int maxSum = Integer.MIN_VALUE;
private int dfs(TreeNode node) {
    if (node == null) return 0;
    int left = Math.max(0, dfs(node.left));   // ignore negative paths
    int right = Math.max(0, dfs(node.right));
    maxSum = Math.max(maxSum, left + right + node.val); // path through this node
    return node.val + Math.max(left, right);  // return single-side to parent
}
```

### Binary Tree Cameras (Greedy on Tree)

```java
// LC 968: minimum cameras to monitor all nodes
int cameras = 0;
public int minCameraCover(TreeNode root) {
    if (dfs(root) == 0) cameras++; // root needs camera
    return cameras;
}
// Returns: 0 = needs camera, 1 = has camera, 2 = monitored
private int dfs(TreeNode node) {
    if (node == null) return 2; // null nodes are "monitored"
    int left = dfs(node.left), right = dfs(node.right);
    if (left == 0 || right == 0) { cameras++; return 1; } // child needs camera → place here
    if (left == 1 || right == 1) return 2; // child has camera → I'm monitored
    return 0; // neither child has camera → I need one
}
```

### Rerooting Technique

**Compute answer for root, then "reroot" to each child in O(1) by adjusting the parent's contribution.**

💡 **Intuition:** Instead of running DFS from every node (O(n²)), compute the answer for the root first, then for each child, adjust the answer by removing the child's contribution from the parent and adding the parent's contribution to the child. This "reroots" the tree in O(1) per node, giving O(n) total.

```java
// Example: Sum of Distances in Tree (LC 834)
// Phase 1: DFS to compute count[] and dist[] for root
// Phase 2: Reroot - for each child, adjust parent's answer
int[] count, dist;

void dfs1(int u, int parent, List<List<Integer>> tree) {
    count[u] = 1;
    for (int v : tree.get(u)) {
        if (v == parent) continue;
        dfs1(v, u, tree);
        count[u] += count[v];
        dist[u] += dist[v] + count[v]; // sum of distances from u to all nodes in v's subtree
    }
}

void dfs2(int u, int parent, int n, List<List<Integer>> tree) {
    for (int v : tree.get(u)) {
        if (v == parent) continue;
        // Rerooting: moving root from u to v
        // Nodes in v's subtree get 1 closer: -count[v]
        // Nodes outside v's subtree get 1 farther: +(n - count[v])
        dist[v] = dist[u] - count[v] + (n - count[v]);
        dfs2(v, u, n, tree);
    }
}
```

---

## 3. Complexity Summary

| Pattern | Time | Space | Key Insight |
|---------|------|-------|-------------|
| Rob/Not-Rob | O(n) | O(h) | Two states per node: take or skip |
| Diameter / Longest Path | O(n) | O(h) | Max(leftHeight + rightHeight) across all nodes |
| Max Path Sum | O(n) | O(h) | Ignore negative paths with max(0, child) |
| Binary Tree Cameras | O(n) | O(h) | Greedy: place camera at parent of leaf |
| Rerooting | O(n) | O(n) | Compute for root, adjust for each child in O(1) |

🎯 **Likely Follow-ups:**
- **Q:** How do you identify that a problem needs tree DP?
  **A:** When the answer at each node depends on answers from its children, and you need to combine child results optimally. Signals: "maximum/minimum path in tree", "count subtrees with property X", "optimal assignment on tree nodes".
- **Q:** What is the difference between tree DP and regular DFS?
  **A:** Regular DFS just traverses. Tree DP returns computed values from children to parent and makes optimal decisions based on those values. The "DP" part is that each node's answer is computed from its children's answers (optimal substructure).
- **Q:** When do you need rerooting vs running DFS from every node?
  **A:** Rerooting when the answer for each node as root can be derived from the answer of its parent in O(1). This turns O(n²) (DFS from every node) into O(n) (two DFS passes). Classic example: sum of distances to all other nodes.

---

## 4. Revision Checklist

- [ ] Tree DP: `dp[node]` depends on `dp[children]`. Solve bottom-up (postorder DFS).
- [ ] Rob/Not-Rob: return `int[]{notRob, rob}` from each node. Parent chooses max.
- [ ] Diameter: track `left + right` at each node, return `1 + max(left, right)` to parent.
- [ ] Max path sum: `max(0, child)` to ignore negative paths. Update global max with `left + right + node.val`.
- [ ] Binary tree cameras: greedy bottom-up. States: 0=needs camera, 1=has camera, 2=monitored.
- [ ] Rerooting: two DFS passes. First computes answer for root. Second adjusts for each child.
- [ ] Rerooting formula: `dist[child] = dist[parent] - count[child] + (n - count[child])`.

**Top 5 must-solve:**
1. House Robber III (LC 337) [Medium] - Rob/not-rob tree DP
2. Binary Tree Maximum Path Sum (LC 124) [Hard] - Any-to-any path, ignore negatives
3. Diameter of Binary Tree (LC 543) [Easy] - leftHeight + rightHeight at each node
4. Binary Tree Cameras (LC 968) [Hard] - Greedy bottom-up with 3 states
5. Sum of Distances in Tree (LC 834) [Hard] - Rerooting technique

> 🔗 **See Also:** [01-dsa/05-trees.md](05-trees.md) for basic tree DFS patterns. [01-dsa/07-dynamic-programming.md](07-dynamic-programming.md) for DP fundamentals.
