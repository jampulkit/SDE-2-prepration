> ⚠️ **[OPTIONAL] — Rarely asked at SDE-2 interviews. Skip unless you've mastered files 00-14.**

# Advanced Tree Problems

## 1. Foundation

**Advanced tree techniques go beyond basic DFS/BFS: Morris traversal (O(1) space), Euler tour for LCA queries, binary lifting, and tree serialization techniques.**

## 2. Core Patterns

### Morris Traversal (O(1) Space Inorder) [🔥 Must Know]

```java
// Inorder traversal without stack or recursion — O(n) time, O(1) space
public List<Integer> morrisInorder(TreeNode root) {
    List<Integer> result = new ArrayList<>();
    TreeNode curr = root;
    while (curr != null) {
        if (curr.left == null) {
            result.add(curr.val); // process
            curr = curr.right;
        } else {
            // Find inorder predecessor (rightmost node in left subtree)
            TreeNode pred = curr.left;
            while (pred.right != null && pred.right != curr) pred = pred.right;
            
            if (pred.right == null) {
                pred.right = curr; // create temporary link back to curr
                curr = curr.left;  // go left
            } else {
                pred.right = null; // remove temporary link (restore tree)
                result.add(curr.val); // process
                curr = curr.right;
            }
        }
    }
    return result;
}
```

💡 **Intuition:** Morris traversal uses the tree's own null pointers to create temporary "threads" back to ancestors. This replaces the stack/recursion. After processing, the threads are removed, restoring the original tree.

⚙️ **Under the Hood, Morris Traversal Step by Step:**

```
Tree:     1
         / \
        2   3
       / \
      4   5

Step 1: curr=1, left exists. Find predecessor: 2→5 (rightmost in left subtree).
        pred.right=null → set pred.right=1 (thread). Move curr=2.
Step 2: curr=2, left exists. Find predecessor: 4 (rightmost in left subtree).
        pred.right=null → set pred.right=2 (thread). Move curr=4.
Step 3: curr=4, no left. Process 4. Move curr=4.right=2 (thread!).
Step 4: curr=2, left exists. Find predecessor: 4→4.right=2 (found thread!).
        pred.right=curr → remove thread (pred.right=null). Process 2. Move curr=5.
Step 5: curr=5, no left. Process 5. Move curr=5.right=1 (thread!).
Step 6: curr=1, left exists. Find predecessor: 2→5→5.right=1 (found thread!).
        Remove thread. Process 1. Move curr=3.
Step 7: curr=3, no left. Process 3. Move curr=null. Done.

Result: [4, 2, 5, 1, 3] ✓ (inorder)
```

🎯 **Likely Follow-ups:**
- **Q:** Does Morris traversal modify the tree? Is it safe for concurrent access?
  **A:** Yes, it temporarily modifies the tree (adds thread pointers). It restores the tree after processing. It is NOT safe for concurrent access. If another thread reads the tree during Morris traversal, it will see corrupted pointers.
- **Q:** Can Morris traversal be adapted for preorder?
  **A:** Yes. Move the `result.add(curr.val)` to when you CREATE the thread (not when you remove it). The rest of the logic is identical.

---

### Binary Lifting for LCA [🔥 Must Know]

**O(n log n) preprocessing, O(log n) per LCA query.**

💡 **Intuition:** Binary lifting precomputes the 2^k-th ancestor of every node. To find LCA, first bring both nodes to the same depth (using binary representation of the depth difference), then lift both nodes simultaneously until they meet. Each "lift" jumps by a power of 2, so the total work is O(log n).

```java
int[][] up; // up[v][k] = 2^k ancestor of v
int[] depth;
int LOG;

void preprocess(int root, List<List<Integer>> tree) {
    int n = tree.size();
    LOG = (int)(Math.ceil(Math.log(n) / Math.log(2))) + 1;
    up = new int[n][LOG];
    depth = new int[n];
    dfs(root, root, tree);
    for (int k = 1; k < LOG; k++)
        for (int v = 0; v < n; v++)
            up[v][k] = up[up[v][k-1]][k-1]; // 2^k ancestor = 2^(k-1) ancestor of 2^(k-1) ancestor
}

int lca(int u, int v) {
    if (depth[u] < depth[v]) { int t = u; u = v; v = t; }
    int diff = depth[u] - depth[v];
    for (int k = 0; k < LOG; k++)
        if (((diff >> k) & 1) == 1) u = up[u][k]; // lift u to same depth as v
    if (u == v) return u;
    for (int k = LOG - 1; k >= 0; k--)
        if (up[u][k] != up[v][k]) { u = up[u][k]; v = up[v][k]; }
    return up[u][0];
}
```

### Euler Tour (Flatten Tree to Array)

Convert tree to array using entry/exit times. Subtree of node v = contiguous range `[tin[v], tout[v]]` in the array. This enables range queries on subtrees using segment tree or BIT.

```java
int timer = 0;
int[] tin, tout, euler;

void eulerTour(int v, int parent, List<List<Integer>> tree) {
    tin[v] = timer;
    euler[timer++] = v;
    for (int u : tree.get(v)) {
        if (u != parent) eulerTour(u, v, tree);
    }
    tout[v] = timer - 1;
}
// Subtree of v = euler[tin[v]..tout[v]]
// Use segment tree on this range for subtree sum/min/max queries
```

---

## 3. Complexity Summary

| Technique | Preprocessing | Per Query | Space | Use Case |
|-----------|-------------|-----------|-------|----------|
| Morris Traversal | None | O(n) total | O(1) | Inorder/preorder without stack |
| Binary Lifting LCA | O(n log n) | O(log n) | O(n log n) | Multiple LCA queries |
| Euler Tour + Seg Tree | O(n) | O(log n) | O(n) | Subtree aggregate queries |

---

## 4. LeetCode Problem List

**Top 5 must-solve:**
1. Recover Binary Search Tree (LC 99) [Medium] - Morris traversal to find swapped nodes
2. Flatten Binary Tree to Linked List (LC 114) [Medium] - Morris-like or reverse preorder
3. All Nodes Distance K in Binary Tree (LC 863) [Medium] - BFS + parent map
4. Lowest Common Ancestor of a Binary Tree (LC 236) [Medium] - Recursive LCA
5. Vertical Order Traversal (LC 987) [Hard] - BFS + column tracking

---

## 5. Revision Checklist
- [ ] Morris traversal: O(1) space inorder using temporary thread pointers. O(n) time.
- [ ] Binary lifting: O(n log n) preprocess, O(log n) per LCA query. `up[v][k]` = 2^k ancestor.
- [ ] Euler tour: flatten tree to array, subtree = contiguous range, enables range queries.

> 🔗 **See Also:** [01-dsa/05-trees.md](05-trees.md) for basic tree patterns. [01-dsa/12-segment-tree-bit.md](12-segment-tree-bit.md) for range queries on Euler tour arrays.
