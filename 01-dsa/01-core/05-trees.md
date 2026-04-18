> ✅ **[CORE] — Must-do for SDE-2 interviews.**

# Trees

## 1. Foundation

**A tree is a hierarchical data structure where each node has a value and pointers to child nodes — it's the backbone of efficient searching (BST), priority access (heaps), prefix matching (tries), and most divide-and-conquer algorithms.**

Trees model hierarchical relationships — file systems, org charts, HTML DOM, database indices. In DSA, trees are the foundation for efficient searching (BST), priority access (heaps), prefix matching (tries), and divide-and-conquer algorithms.

💡 **Intuition:** Think of a family tree. The root is the oldest ancestor. Each person (node) can have children. Leaves are people with no children. The "height" is how many generations deep the tree goes. Every tree problem is essentially: "visit nodes in some order and compute something along the way."

**Terminology:**
- **Root:** Top node (no parent)
- **Leaf:** Node with no children
- **Height:** Longest path from node to a leaf (leaf height = 0)
- **Depth:** Distance from root to node (root depth = 0)
- **Level:** Same as depth
- **Subtree:** A node and all its descendants
- **Complete binary tree:** All levels full except possibly the last, which is filled left to right
- **Full binary tree:** Every node has 0 or 2 children
- **Perfect binary tree:** All internal nodes have 2 children, all leaves at same level
- **Balanced binary tree:** Height difference between left and right subtrees ≤ 1 for every node

⚠️ **Common Confusion — Height vs Depth:**
```
        1          depth=0, height=2
       / \
      2   3        depth=1, height=1
     / \
    4   5          depth=2, height=0 (leaves)

Height: measured from bottom up (leaf=0, root=max)
Depth: measured from top down (root=0, leaf=max)
Some sources define height of leaf as 0, others as -1. Clarify with interviewer.
```

**Binary tree properties** [🔥 Must Know]:
- Max nodes at level `d`: `2^d`
- Max total nodes with height `h`: `2^(h+1) - 1`
- For `n` nodes, min height = `⌊log₂(n)⌋`
- Number of null pointers in a binary tree with `n` nodes: `n + 1`
- In a full binary tree: `leaves = internal_nodes + 1`

⚙️ **Under the Hood — Why These Properties Matter:**
- `2^(h+1) - 1` tells you a balanced tree with 1 million nodes has height ~20. That's 20 recursive calls max — no stack overflow risk.
- `n + 1` null pointers: every node has 2 child pointers (2n total), but only n-1 are used (n-1 edges in a tree with n nodes). So 2n - (n-1) = n+1 are null. This is why null checks dominate tree code.
- For n = 10⁵ nodes, a balanced tree has height ~17 (log₂(100000) ≈ 17). A skewed tree has height 10⁵ — recursion will stack overflow.

**Standard TreeNode definition:**

```java
public class TreeNode {
    int val;
    TreeNode left, right;
    TreeNode(int val) { this.val = val; }
}
```

**Tree traversals** [🔥 Must Know]:

| Traversal | Order | Use Case | Mnemonic |
|-----------|-------|----------|----------|
| Preorder | Root → Left → Right | Serialize tree, copy tree | "Process, then explore" |
| Inorder | Left → Root → Right | BST → sorted order | "Left first, then me" |
| Postorder | Left → Right → Root | Delete tree, calculate height | "Children first, then me" |
| Level-order (BFS) | Level by level | Level-based problems, shortest path | "Ring by ring" |

💡 **Intuition — When to use which traversal:**
- **Preorder:** When you need to process the node BEFORE its children (e.g., making a copy — create the node first, then copy children)
- **Inorder:** When you need sorted order from a BST (left subtree < root < right subtree)
- **Postorder:** When you need information FROM children to compute the node's answer (e.g., height = 1 + max(left_height, right_height) — you need children's heights first)
- **Level-order:** When the problem is about levels, layers, or breadth (e.g., "rightmost node at each level")

```java
// Recursive traversals — the foundation of all tree problems
void preorder(TreeNode node) {
    if (node == null) return;
    process(node);          // root first
    preorder(node.left);
    preorder(node.right);
}

void inorder(TreeNode node) {
    if (node == null) return;
    inorder(node.left);
    process(node);          // root in middle → sorted order for BST
    inorder(node.right);
}

void postorder(TreeNode node) {
    if (node == null) return;
    postorder(node.left);
    postorder(node.right);
    process(node);          // root last → children computed first
}
```

**Iterative traversals** (important for interviews — shows you understand the call stack) [🔥 Must Know]:

```java
// Iterative inorder — most commonly asked
public List<Integer> inorderIterative(TreeNode root) {
    List<Integer> result = new ArrayList<>();
    Deque<TreeNode> stack = new ArrayDeque<>();
    TreeNode curr = root;

    while (curr != null || !stack.isEmpty()) {
        while (curr != null) {   // go as far left as possible
            stack.push(curr);
            curr = curr.left;
        }
        curr = stack.pop();      // process leftmost unprocessed node
        result.add(curr.val);
        curr = curr.right;       // explore right subtree
    }
    return result;
}
```

⚙️ **Under the Hood — Why Iterative Inorder Works:**
The recursive call stack implicitly saves "where to return to." The explicit stack does the same thing manually. The inner `while (curr != null)` loop simulates the recursive descent into left children. `stack.pop()` simulates returning from the left subtree. `curr = curr.right` simulates the recursive call to the right subtree.

```
Tree:     4
         / \
        2   6
       / \
      1   3

Stack trace:
curr=4: push 4, go left → curr=2: push 2, go left → curr=1: push 1, go left → curr=null
Pop 1: result=[1], curr=1.right=null
Pop 2: result=[1,2], curr=2.right=3
curr=3: push 3, go left → curr=null
Pop 3: result=[1,2,3], curr=3.right=null
Pop 4: result=[1,2,3,4], curr=4.right=6
curr=6: push 6, go left → curr=null
Pop 6: result=[1,2,3,4,6], curr=6.right=null
Stack empty, curr=null → DONE

Result: [1, 2, 3, 4, 6] ✓ (sorted order for BST)
```

**Iterative preorder (simpler — process before pushing children):**

```java
public List<Integer> preorderIterative(TreeNode root) {
    List<Integer> result = new ArrayList<>();
    if (root == null) return result;
    Deque<TreeNode> stack = new ArrayDeque<>();
    stack.push(root);

    while (!stack.isEmpty()) {
        TreeNode node = stack.pop();
        result.add(node.val);
        if (node.right != null) stack.push(node.right); // right first (LIFO)
        if (node.left != null) stack.push(node.left);   // left processed first
    }
    return result;
}
```

**Level-order traversal (BFS):**

```java
public List<List<Integer>> levelOrder(TreeNode root) {
    List<List<Integer>> result = new ArrayList<>();
    if (root == null) return result;

    Deque<TreeNode> queue = new ArrayDeque<>();
    queue.offer(root);

    while (!queue.isEmpty()) {
        int size = queue.size(); // CRITICAL: capture before inner loop
        List<Integer> level = new ArrayList<>();
        for (int i = 0; i < size; i++) {
            TreeNode node = queue.poll();
            level.add(node.val);
            if (node.left != null) queue.offer(node.left);
            if (node.right != null) queue.offer(node.right);
        }
        result.add(level);
    }
    return result;
}
```

🎯 **Likely Follow-ups:**
- **Q:** Can you do inorder traversal without a stack and without recursion?
  **A:** Yes — Morris Traversal. It uses the tree's null pointers to create temporary links (threading). O(n) time, O(1) space. The idea: for each node, find its inorder predecessor and create a temporary link back. This lets you "return" to the node after processing the left subtree without a stack.
- **Q:** What's the space complexity of recursive DFS vs BFS?
  **A:** DFS: O(h) where h = height (recursion stack). BFS: O(w) where w = max width. For a balanced tree, h = log n and w = n/2, so DFS uses less space. For a skewed tree, h = n and w = 1, so BFS uses less space.
- **Q:** How would you traverse a tree if it's too deep for recursion?
  **A:** Use iterative traversal with an explicit stack. Java's default thread stack size is ~512KB, which supports ~10,000-20,000 recursive calls. For trees deeper than that, iterative is necessary.

> 🔗 **See Also:** [01-dsa/03-stacks-queues.md](03-stacks-queues.md) Pattern 5 for BFS queue template. [01-dsa/06-graphs.md](06-graphs.md) for DFS/BFS on general graphs.

### Binary Search Tree (BST)

**A BST is a binary tree where every node's left subtree contains only smaller values and right subtree contains only larger values — this gives you O(log n) search, insert, and delete on a balanced tree.**

**BST property:** For every node, all values in the left subtree < node.val < all values in the right subtree.

💡 **Intuition:** A BST is like a decision tree for binary search. At each node, you ask "is my target less than or greater than this value?" and go left or right accordingly. This is why inorder traversal of a BST gives sorted order — you visit all smaller values (left), then the node, then all larger values (right).

```
BST example:
        8
       / \
      3   10
     / \    \
    1   6    14
       / \   /
      4   7 13

Inorder: 1, 3, 4, 6, 7, 8, 10, 13, 14 (sorted!)
Search for 7: 8→left→3→right→6→right→7 ✓ (3 comparisons = O(log n))
```

**BST operations complexity:**

| Operation | Balanced BST | Skewed BST | Notes |
|-----------|-------------|------------|-------|
| Search | O(log n) | O(n) | Follow left/right based on comparison |
| Insert | O(log n) | O(n) | Find correct leaf position |
| Delete | O(log n) | O(n) | Three cases: leaf, one child, two children |
| Min/Max | O(log n) | O(n) | Go all the way left/right |
| Inorder | O(n) | O(n) | Visit all nodes |

⚙️ **Under the Hood — BST Deletion (Three Cases):**

```
Case 1: Leaf node → just remove it
Case 2: One child → replace node with its child
Case 3: Two children → replace with inorder successor (smallest in right subtree)
         or inorder predecessor (largest in left subtree)

Delete 3 from:     8              8
                   / \            / \
                  3   10   →    4   10
                 / \    \      / \    \
                1   6    14   1   6    14
                   / \   /       / \   /
                  4   7 13      (4) 7 13

Inorder successor of 3 is 4. Replace 3 with 4, remove original 4.
```

**Self-balancing BSTs** (know conceptually, rarely code in interviews):

| Type | Balance Guarantee | Used In | Key Idea |
|------|------------------|---------|----------|
| AVL Tree | Height diff ≤ 1 | Academic, some DBs | Rotations on every insert/delete |
| Red-Black Tree | No path is 2× longer than another | Java TreeMap/TreeSet, Linux kernel | Color-based rules, fewer rotations |
| B-Tree / B+ Tree | All leaves at same depth | Databases, file systems | Multi-way tree, optimized for disk I/O |

**Java's TreeMap/TreeSet** [🔥 Must Know]:
- Backed by a red-black tree
- All operations O(log n)
- `TreeMap` power methods:
  - `floorKey(k)` → greatest key ≤ k (or null)
  - `ceilingKey(k)` → smallest key ≥ k (or null)
  - `firstKey()` / `lastKey()` → min/max key
  - `subMap(from, to)` → view of keys in range
  - `headMap(to)` / `tailMap(from)` → view of keys before/after
- These are incredibly useful for interval problems, scheduling, and range queries

```java
// TreeMap example — finding the closest value
TreeMap<Integer, String> map = new TreeMap<>();
map.put(10, "a"); map.put(20, "b"); map.put(30, "c");

map.floorKey(25);   // 20 (greatest key ≤ 25)
map.ceilingKey(25); // 30 (smallest key ≥ 25)
map.floorKey(10);   // 10 (exact match)
map.floorKey(5);    // null (no key ≤ 5)
```

🎯 **Likely Follow-ups:**
- **Q:** Why does Java use a red-black tree instead of an AVL tree for TreeMap?
  **A:** Red-black trees require fewer rotations on insert/delete (at most 2-3 rotations vs potentially O(log n) for AVL). AVL trees are more strictly balanced, so lookups are slightly faster, but the insert/delete overhead makes red-black trees better for general-purpose use.
- **Q:** When would you use TreeMap over HashMap?
  **A:** When you need sorted keys, range queries (`subMap`), or floor/ceiling operations. HashMap is O(1) for basic operations but doesn't support ordering. TreeMap is O(log n) but supports all ordered operations.

> 🔗 **See Also:** [07-cs-fundamentals/03-database-internals.md](../07-cs-fundamentals/03-database-internals.md) for B-tree/B+ tree in database indexing. [05-java/02-collections-internals.md](../05-java/02-collections-internals.md) for TreeMap/TreeSet internals.

---

## 2. Core Patterns

### Pattern 1: DFS — Recursive Tree Traversal [🔥 Must Know]

**Almost every tree problem is solved with DFS. The key question is: do you need information from the parent (top-down) or from the children (bottom-up)?**

**When to recognize it:** Almost every tree problem. The question is: what information do you need from subtrees, and when do you process the current node?

**Three DFS strategies:**

| Strategy | When to Use | Information Flow | Example |
|----------|------------|-----------------|---------|
| Top-down (preorder) | Pass information from parent to children | Parent → Child | Max depth, path sum, good nodes count |
| Bottom-up (postorder) | Compute answer from children's results | Children → Parent | Height, diameter, balanced check |
| In-order | BST problems (sorted order) | Left → Node → Right | Validate BST, kth smallest |

💡 **Intuition — Top-down vs Bottom-up:**
- **Top-down:** "I know something about my ancestors, and I'll tell my children." Example: "Is this node a good node?" — you need to know the max value on the path from root to here (passed down from parent).
- **Bottom-up:** "I need to ask my children something, then compute my answer." Example: "What's the height of this subtree?" — you need children's heights first, then add 1.

**Template — bottom-up (most common):**

```java
// Return some value computed from children
int solve(TreeNode node) {
    if (node == null) return BASE_CASE;          // base case
    int left = solve(node.left);                  // get left child's answer
    int right = solve(node.right);                // get right child's answer
    // Optionally update global answer using left, right, node.val
    return COMBINED_RESULT;                       // return answer for this subtree
}
```

**Example — LC 104: Maximum Depth of Binary Tree** [🔥 Must Do]

```java
public int maxDepth(TreeNode root) {
    if (root == null) return 0;                                    // empty tree has depth 0
    return 1 + Math.max(maxDepth(root.left), maxDepth(root.right)); // 1 + max of children
}
```

**Dry run:**
```
        3
       / \
      9   20
         /  \
        15   7

maxDepth(3):
  maxDepth(9):
    maxDepth(null) = 0
    maxDepth(null) = 0
    return 1 + max(0, 0) = 1
  maxDepth(20):
    maxDepth(15) = 1
    maxDepth(7) = 1
    return 1 + max(1, 1) = 2
  return 1 + max(1, 2) = 3 ✓
```

**Example — LC 543: Diameter of Binary Tree** [🔥 Must Do]

The diameter is the longest path between any two nodes (may not pass through root).

```java
int diameter = 0; // global variable to track the answer

public int diameterOfBinaryTree(TreeNode root) {
    height(root);
    return diameter;
}

private int height(TreeNode node) {
    if (node == null) return 0;
    int left = height(node.left);
    int right = height(node.right);
    diameter = Math.max(diameter, left + right); // path through this node
    return 1 + Math.max(left, right);            // height of this subtree
}
```

⚙️ **Under the Hood — Why Global Variable for Diameter:**
The diameter through a node = left height + right height. But the diameter of the tree might not pass through the root — it could be entirely in a subtree. So we check every node and keep the global maximum. The function returns height (for the parent to use), but updates diameter as a side effect.

```
        1
       / \
      2   3
     / \
    4   5

height(4) = 1, height(5) = 1
height(2): left=1, right=1, diameter = max(0, 1+1) = 2, return 2
height(3) = 1
height(1): left=2, right=1, diameter = max(2, 2+1) = 3, return 3

Diameter = 3 (path: 4→2→1→3 or 5→2→1→3)
```

**Edge Cases:**
- ☐ Empty tree → depth 0, diameter 0
- ☐ Single node → depth 1, diameter 0
- ☐ Skewed tree (linked list) → depth n, diameter n-1
- ☐ Diameter not through root → global variable catches it

🎯 **Likely Follow-ups:**
- **Q:** Can you solve diameter without a global variable?
  **A:** Yes — return a pair `(height, diameter)` from each recursive call. This is cleaner but more verbose in Java (need an array or custom class for the pair).
- **Q:** What's the time and space complexity?
  **A:** O(n) time (visit every node once), O(h) space (recursion stack, where h = height). For balanced tree, h = log n. For skewed tree, h = n.
- **Q:** How would you find the diameter of an N-ary tree?
  **A:** Same idea — at each node, find the two tallest children. The diameter through this node = sum of the two tallest heights. Track global max.

---

### Pattern 2: BFS — Level-Order Traversal

**Use a queue to process nodes level by level — capture `queue.size()` before the inner loop to separate levels.**

**When to recognize it:** "Level by level", "minimum depth", "right side view", "zigzag", "connect next pointers" — anything that requires processing nodes level by level.

💡 **Intuition:** BFS on a tree is like peeling an onion layer by layer. Each layer (level) is processed completely before moving to the next. The queue ensures FIFO order within each level.

**Example — LC 199: Binary Tree Right Side View**

```java
public List<Integer> rightSideView(TreeNode root) {
    List<Integer> result = new ArrayList<>();
    if (root == null) return result;

    Deque<TreeNode> queue = new ArrayDeque<>();
    queue.offer(root);

    while (!queue.isEmpty()) {
        int size = queue.size();
        for (int i = 0; i < size; i++) {
            TreeNode node = queue.poll();
            if (i == size - 1) result.add(node.val); // last node in level = rightmost
            if (node.left != null) queue.offer(node.left);
            if (node.right != null) queue.offer(node.right);
        }
    }
    return result;
}
```

**BFS vs DFS for tree problems:**

| Use BFS When | Use DFS When |
|-------------|-------------|
| Need level information | Need subtree information |
| Minimum depth (BFS finds it first) | Maximum depth, diameter |
| Right/left side view | Path sum, path collection |
| Zigzag traversal | Validate BST |
| Connect next pointers | LCA, tree construction |

🎯 **Likely Follow-ups:**
- **Q:** Can you solve right side view with DFS?
  **A:** Yes — do a preorder DFS (root → right → left), tracking the current depth. The first node you visit at each depth is the rightmost. Use `result.size() == depth` to check if this depth has been seen.
- **Q:** What's the space complexity of BFS on a tree?
  **A:** O(w) where w = maximum width. For a complete binary tree, the last level has ~n/2 nodes, so BFS uses O(n/2) = O(n) space. For a skewed tree, each level has 1 node, so O(1).

> 🔗 **See Also:** [01-dsa/03-stacks-queues.md](03-stacks-queues.md) Pattern 5 for the BFS queue template.

---

### Pattern 3: BST Properties [🔥 Must Know]

**In a BST, inorder traversal gives sorted order, and every node has a valid range (min, max) — exploit these properties for validation, search, and kth element problems.**

**Sub-pattern 3a: Validate BST**

```java
// LC 98: Validate Binary Search Tree [🔥 Must Do]
public boolean isValidBST(TreeNode root) {
    return validate(root, Long.MIN_VALUE, Long.MAX_VALUE);
}

private boolean validate(TreeNode node, long min, long max) {
    if (node == null) return true;
    if (node.val <= min || node.val >= max) return false; // out of valid range
    return validate(node.left, min, node.val) &&          // left must be < node
           validate(node.right, node.val, max);           // right must be > node
}
```

⚠️ **Common Pitfall — Why `long` instead of `int`:** Node values can be `Integer.MIN_VALUE` or `Integer.MAX_VALUE`. If you use `int` bounds initialized to these values, the first comparison fails. Using `long` gives you a wider range.

**Alternative — Inorder traversal approach:**

```java
// BST inorder is sorted → check if each value > previous
public boolean isValidBST(TreeNode root) {
    Deque<TreeNode> stack = new ArrayDeque<>();
    TreeNode curr = root;
    long prev = Long.MIN_VALUE;

    while (curr != null || !stack.isEmpty()) {
        while (curr != null) { stack.push(curr); curr = curr.left; }
        curr = stack.pop();
        if (curr.val <= prev) return false; // not strictly increasing
        prev = curr.val;
        curr = curr.right;
    }
    return true;
}
```

**Sub-pattern 3b: Kth Smallest in BST**

```java
// LC 230: Kth Smallest Element in a BST
// Inorder traversal stops at the kth element
public int kthSmallest(TreeNode root, int k) {
    Deque<TreeNode> stack = new ArrayDeque<>();
    TreeNode curr = root;

    while (curr != null || !stack.isEmpty()) {
        while (curr != null) { stack.push(curr); curr = curr.left; }
        curr = stack.pop();
        if (--k == 0) return curr.val; // found kth smallest
        curr = curr.right;
    }
    return -1; // shouldn't reach here if k is valid
}
```

🎯 **Likely Follow-ups:**
- **Q:** What if the BST is modified frequently and you need kth smallest repeatedly?
  **A:** Augment each node with a `leftCount` field (number of nodes in left subtree). Then kth smallest is O(h): if `leftCount + 1 == k`, return current; if `k ≤ leftCount`, go left; else go right with `k -= leftCount + 1`.
- **Q:** How would you find the closest value to a target in a BST?
  **A:** Binary search: at each node, update the closest if `|node.val - target|` is smaller. Go left if target < node.val, right otherwise. O(h) time.

---

### Pattern 4: Path Problems

**Track a running sum or path as you traverse from root to leaves (top-down), or compute path values from children up (bottom-up).**

**Sub-pattern 4a: Root-to-leaf paths**

```java
// LC 112: Path Sum — does any root-to-leaf path sum to target?
public boolean hasPathSum(TreeNode root, int targetSum) {
    if (root == null) return false;
    if (root.left == null && root.right == null) return root.val == targetSum; // leaf check
    return hasPathSum(root.left, targetSum - root.val) ||
           hasPathSum(root.right, targetSum - root.val);
}
```

💡 **Intuition:** Instead of tracking the running sum, subtract the current node's value from the target. At a leaf, check if the remaining target is 0 (or equals the leaf value). This avoids passing an extra parameter.

**Sub-pattern 4b: Any-to-any path (maximum path sum)** [🔥 Must Do]

```java
// LC 124: Binary Tree Maximum Path Sum
int maxSum = Integer.MIN_VALUE;

public int maxPathSum(TreeNode root) {
    dfs(root);
    return maxSum;
}

private int dfs(TreeNode node) {
    if (node == null) return 0;
    int left = Math.max(0, dfs(node.left));   // ignore negative paths (take 0 instead)
    int right = Math.max(0, dfs(node.right));
    maxSum = Math.max(maxSum, left + right + node.val); // path through this node
    return node.val + Math.max(left, right);  // return best SINGLE-SIDE path to parent
}
```

⚙️ **Under the Hood — Why Return Single-Side Only:**
A path can't fork — it goes from some node A to some node B through their LCA. At the LCA, the path uses both left and right branches. But when returning to the LCA's parent, the path can only continue through ONE branch (left or right), not both. So we return `node.val + max(left, right)` — the best single-side contribution.

```
        -10
        /  \
       9    20
           /  \
          15   7

dfs(9) = max(0, 0) + max(0, 0) + 9 = 9. maxSum = 9. Return 9.
dfs(15) = 15. maxSum = 15. Return 15.
dfs(7) = 7. maxSum = 15. Return 7.
dfs(20): left=15, right=7. maxSum = max(15, 15+7+20) = 42. Return 20+15 = 35.
dfs(-10): left=max(0,9)=9, right=max(0,35)=35. maxSum = max(42, 9+35+(-10)) = 42. Return -10+35 = 25.

Answer: 42 (path: 15→20→7)
```

**Sub-pattern 4c: Path Sum III (prefix sum on tree)** [🔥 Must Do]

```java
// LC 437: Path Sum III — count paths with target sum (path can start/end anywhere)
public int pathSum(TreeNode root, int targetSum) {
    Map<Long, Integer> prefixSum = new HashMap<>();
    prefixSum.put(0L, 1); // empty path
    return dfs(root, 0, targetSum, prefixSum);
}

private int dfs(TreeNode node, long currSum, int target, Map<Long, Integer> prefixSum) {
    if (node == null) return 0;
    currSum += node.val;
    int count = prefixSum.getOrDefault(currSum - target, 0); // paths ending here with target sum
    prefixSum.merge(currSum, 1, Integer::sum);                // add current prefix sum

    count += dfs(node.left, currSum, target, prefixSum);
    count += dfs(node.right, currSum, target, prefixSum);

    prefixSum.merge(currSum, -1, Integer::sum);               // BACKTRACK: remove current prefix sum
    return count;
}
```

💡 **Intuition:** This is the prefix sum + HashMap pattern from arrays (LC 560), applied to a tree. The "array" is the path from root to current node. We backtrack (remove the prefix sum) when returning from a subtree, because that path is no longer valid for other branches.

> 🔗 **See Also:** [01-dsa/01-arrays-strings-hashing.md](01-arrays-strings-hashing.md) Pattern 4 (Prefix Sum + HashMap) — same technique on arrays.

---

### Pattern 5: Tree Construction

**Use the first element of preorder (or last of postorder) as the root, find it in inorder to determine left/right subtree boundaries, then recurse.**

```java
// LC 105: Construct Binary Tree from Preorder and Inorder [🔥 Must Do]
Map<Integer, Integer> inorderIndex = new HashMap<>();
int preIdx = 0;

public TreeNode buildTree(int[] preorder, int[] inorder) {
    for (int i = 0; i < inorder.length; i++) inorderIndex.put(inorder[i], i);
    return build(preorder, 0, inorder.length - 1);
}

private TreeNode build(int[] preorder, int left, int right) {
    if (left > right) return null;
    int rootVal = preorder[preIdx++];                    // next preorder element is root
    TreeNode root = new TreeNode(rootVal);
    int mid = inorderIndex.get(rootVal);                 // find root in inorder
    root.left = build(preorder, left, mid - 1);          // left subtree
    root.right = build(preorder, mid + 1, right);        // right subtree
    return root;
}
```

⚙️ **Under the Hood — Why This Works:**
- Preorder: [root, ...left subtree..., ...right subtree...]
- Inorder: [...left subtree..., root, ...right subtree...]
- The root is always the first element in preorder. Finding it in inorder splits the array into left and right subtrees. The HashMap makes the lookup O(1) instead of O(n).

**Edge Cases:**
- ☐ Single node → root with no children
- ☐ All nodes in left subtree (skewed left) → right is always empty
- ☐ Duplicate values → this approach assumes unique values (stated in problem)

---

### Pattern 6: Lowest Common Ancestor (LCA) [🔥 Must Know]

**Recurse into both subtrees. If both return non-null, the current node is the LCA. If only one returns non-null, propagate it up.**

```java
// LC 236: Lowest Common Ancestor of a Binary Tree [🔥 Must Do]
public TreeNode lowestCommonAncestor(TreeNode root, TreeNode p, TreeNode q) {
    if (root == null || root == p || root == q) return root; // base case
    TreeNode left = lowestCommonAncestor(root.left, p, q);
    TreeNode right = lowestCommonAncestor(root.right, p, q);
    if (left != null && right != null) return root; // p and q on different sides → root is LCA
    return left != null ? left : right;              // both on same side → propagate up
}
```

💡 **Intuition:** Think of it as sending scouts down both branches. If the left scout finds p and the right scout finds q (or vice versa), then the current node is where they diverge — it's the LCA. If both are found on the same side, the LCA is deeper in that subtree.

**For BST (LC 235):** Exploit sorted property — if both values < root, go left; if both > root, go right; otherwise root is the LCA.

```java
public TreeNode lowestCommonAncestor(TreeNode root, TreeNode p, TreeNode q) {
    while (root != null) {
        if (p.val < root.val && q.val < root.val) root = root.left;       // both smaller
        else if (p.val > root.val && q.val > root.val) root = root.right; // both larger
        else return root; // split point → LCA
    }
    return null;
}
```

🎯 **Likely Follow-ups:**
- **Q:** What if the tree has parent pointers?
  **A:** Treat it like the "intersection of two linked lists" problem. Traverse from p and q to root, then use the redirect trick to find where paths converge.
- **Q:** What if you need LCA for multiple queries?
  **A:** Preprocess with Euler tour + sparse table for O(1) per query after O(n log n) preprocessing. Or use binary lifting for O(log n) per query.

---

### Pattern 7: Serialize / Deserialize

**Convert a tree to a string (preorder with null markers) and back — the null markers preserve the tree structure.**

```java
// LC 297: Serialize and Deserialize Binary Tree [🔥 Must Do]
public String serialize(TreeNode root) {
    if (root == null) return "null";
    return root.val + "," + serialize(root.left) + "," + serialize(root.right);
}

public TreeNode deserialize(String data) {
    Deque<String> nodes = new ArrayDeque<>(Arrays.asList(data.split(",")));
    return buildTree(nodes);
}

private TreeNode buildTree(Deque<String> nodes) {
    String val = nodes.poll();
    if ("null".equals(val)) return null;
    TreeNode node = new TreeNode(Integer.parseInt(val));
    node.left = buildTree(nodes);   // preorder: left first
    node.right = buildTree(nodes);  // then right
    return node;
}
```

**Why preorder with null markers works:** The null markers tell the deserializer exactly where each subtree ends. Without them, you'd need two traversals (preorder + inorder) to reconstruct the tree.

```
Tree:     1
         / \
        2   3
           / \
          4   5

Serialized: "1,2,null,null,3,4,null,null,5,null,null"

Deserialize:
  poll "1" → create node 1
    poll "2" → create node 2
      poll "null" → left = null
      poll "null" → right = null
    poll "3" → create node 3
      poll "4" → create node 4
        poll "null" → left = null
        poll "null" → right = null
      poll "5" → create node 5
        poll "null" → left = null
        poll "null" → right = null
```

---

### Pattern 8: Trie (Prefix Tree) [🔥 Must Know]

**A trie is a tree where each path from root to a node spells out a prefix — it trades memory for O(L) prefix lookups regardless of how many words are stored.**

**Why tries exist:** Efficient prefix-based operations — autocomplete, spell check, word search. Lookup is O(L) where L = word length, independent of how many words are stored.

💡 **Intuition:** Imagine a dictionary organized not alphabetically on pages, but as a tree of letters. To look up "cat", you follow c→a→t. To find all words starting with "ca", you follow c→a and then explore all branches below. This is much faster than scanning every word in the dictionary.

```java
// LC 208: Implement Trie [🔥 Must Do]
class Trie {
    private Trie[] children = new Trie[26]; // one child per letter
    private boolean isEnd = false;           // marks end of a complete word

    public void insert(String word) {
        Trie node = this;
        for (char c : word.toCharArray()) {
            int idx = c - 'a';
            if (node.children[idx] == null) node.children[idx] = new Trie();
            node = node.children[idx];
        }
        node.isEnd = true; // mark the last node as end of word
    }

    public boolean search(String word) {
        Trie node = find(word);
        return node != null && node.isEnd; // must be a complete word
    }

    public boolean startsWith(String prefix) {
        return find(prefix) != null; // just needs to exist as a prefix
    }

    private Trie find(String s) {
        Trie node = this;
        for (char c : s.toCharArray()) {
            int idx = c - 'a';
            if (node.children[idx] == null) return null; // prefix doesn't exist
            node = node.children[idx];
        }
        return node;
    }
}
```

```
Trie after inserting "apple", "app", "apt":

root
 └── a
      └── p
           ├── p
           │    ├── l
           │    │    └── e [isEnd=true]  ← "apple"
           │    └── [isEnd=true]         ← "app"
           └── t [isEnd=true]            ← "apt"

search("app") → follow a→p→p, isEnd=true → true ✓
search("ap")  → follow a→p, isEnd=false → false ✓
startsWith("ap") → follow a→p, node exists → true ✓
```

**Trie complexity:**

| Operation | Time | Space |
|-----------|------|-------|
| Insert | O(L) | O(L) new nodes in worst case |
| Search | O(L) | O(1) |
| StartsWith | O(L) | O(1) |
| Total space | — | O(ALPHABET × L × N) worst case |

Where L = word length, N = number of words, ALPHABET = 26 for lowercase English.

| Approach | Pros | Cons | Best When |
|----------|------|------|-----------|
| Trie | O(L) prefix search, autocomplete | High memory (26 pointers per node) | Prefix-heavy problems, word search |
| HashSet | O(L) exact search | No prefix support | Exact word lookup only |
| Sorted array + binary search | O(L log N) search | No prefix support | Static dictionary |

🎯 **Likely Follow-ups:**
- **Q:** How would you implement autocomplete with a trie?
  **A:** Navigate to the prefix node, then DFS from there to collect all words. To get top-k suggestions, store frequency at each end node and use a priority queue during DFS.
- **Q:** How would you optimize trie memory?
  **A:** Use a HashMap instead of array for children (sparse tries), or use compressed tries (radix trees) where chains of single-child nodes are merged into one node with a string label.
- **Q:** How does a trie compare to a HashMap for word storage?
  **A:** Trie uses more memory but supports prefix operations. HashMap is more memory-efficient for exact lookups. For autocomplete or spell-check, trie wins. For simple word existence checks, HashMap wins.

> 🔗 **See Also:** [02-system-design/problems/search-autocomplete.md](../02-system-design/problems/search-autocomplete.md) for trie in autocomplete system design.


---

## 3. Patterns Summary Table

| # | Pattern | When to Use | Key Idea | Time | Space | Example Problem |
|---|---------|------------|----------|------|-------|-----------------|
| 1 | DFS (recursive) | Most tree problems | Top-down or bottom-up recursion | O(n) | O(h) | Diameter (LC 543) |
| 2 | BFS (level-order) | Level-based problems | Queue + levelSize | O(n) | O(w) | Right Side View (LC 199) |
| 3 | BST properties | Sorted order, validation | Inorder = sorted; bounds checking | O(n) | O(h) | Validate BST (LC 98) |
| 4 | Path problems | Path sum, max path | Track sum top-down or bottom-up | O(n) | O(h) | Max Path Sum (LC 124) |
| 5 | Tree construction | Build from traversals | Preorder root + inorder split | O(n) | O(n) | Build Tree (LC 105) |
| 6 | LCA | Common ancestor | Recurse both sides, check null | O(n) | O(h) | LCA (LC 236) |
| 7 | Serialize/Deserialize | Save/restore tree | Preorder with null markers | O(n) | O(n) | Serialize (LC 297) |
| 8 | Trie | Prefix operations | Array of children per node | O(L) | O(A×L×N) | Implement Trie (LC 208) |

h = height, w = max width, L = word length, A = alphabet size, N = number of words

**Pattern Selection Flowchart:**

```
Tree problem?
├── Is it a BST?
│   ├── Validation? → Pattern 3a: bounds checking or inorder
│   ├── Search/insert/delete? → Pattern 3c: BST operations
│   ├── Kth element? → Pattern 3b: inorder traversal
│   └── LCA in BST? → Pattern 6 (BST variant): compare values
├── Level-based? (level order, right view, zigzag) → Pattern 2: BFS
├── Path-based? (path sum, max path) → Pattern 4: DFS with sum tracking
├── Construction? (build from traversals) → Pattern 5: preorder root + inorder split
├── LCA? → Pattern 6: recurse both sides
├── Serialize? → Pattern 7: preorder with null markers
├── Prefix/word problem? → Pattern 8: Trie
└── General tree problem → Pattern 1: DFS (top-down or bottom-up)
```

---

## 4. LeetCode Problem List (Must-Solve)

### Easy

| # | Problem Name | LC # | Pattern(s) | Why Important |
|---|-------------|------|-----------|---------------|
| 1 | Maximum Depth of Binary Tree | 104 | DFS bottom-up | [🔥 Must Do] Simplest recursion |
| 2 | Invert Binary Tree | 226 | DFS | [🔥 Must Do] Swap children recursively |
| 3 | Same Tree | 100 | DFS | Simultaneous traversal |
| 4 | Symmetric Tree | 101 | DFS (mirror) | Mirror comparison |
| 5 | Subtree of Another Tree | 572 | DFS + same tree | Nested recursion |
| 6 | Balanced Binary Tree | 110 | DFS bottom-up | Height check at every node |
| 7 | Diameter of Binary Tree | 543 | DFS bottom-up | [🔥 Must Do] Height + global max |
| 8 | Path Sum | 112 | DFS top-down | Root-to-leaf sum |
| 9 | Minimum Depth of Binary Tree | 111 | BFS / DFS | BFS finds it faster |
| 10 | Merge Two Binary Trees | 617 | DFS | Simultaneous traversal |
| 11 | Search in a BST | 700 | BST search | Basic BST navigation |
| 12 | Lowest Common Ancestor of a BST | 235 | BST + LCA | [🔥 Must Do] Exploit sorted property |

### Medium

| # | Problem Name | LC # | Pattern(s) | Why Important |
|---|-------------|------|-----------|---------------|
| 1 | Binary Tree Level Order Traversal | 102 | BFS | [🔥 Must Do] Foundation for all BFS problems |
| 2 | Binary Tree Right Side View | 199 | BFS | Last node per level |
| 3 | Binary Tree Zigzag Level Order | 103 | BFS + alternating | Reverse alternate levels |
| 4 | Validate Binary Search Tree | 98 | BST bounds | [🔥 Must Do] Range validation |
| 5 | Kth Smallest Element in a BST | 230 | BST inorder | Iterative inorder |
| 6 | Lowest Common Ancestor | 236 | LCA | [🔥 Must Do] Classic recursion |
| 7 | Construct Binary Tree from Preorder and Inorder | 105 | Construction | [🔥 Must Do] Index mapping |
| 8 | Construct Binary Tree from Inorder and Postorder | 106 | Construction | Reverse of 105 |
| 9 | Binary Tree Maximum Path Sum | 124 | Path (any-to-any) | [🔥 Must Do] Hardest path problem |
| 10 | Path Sum II | 113 | DFS + backtracking | Collect all root-to-leaf paths |
| 11 | Path Sum III | 437 | DFS + prefix sum | [🔥 Must Do] Prefix sum on tree |
| 12 | Flatten Binary Tree to Linked List | 114 | DFS / Morris | Preorder to linked list |
| 13 | Populating Next Right Pointers | 116 | BFS / O(1) space | Level-order connection |
| 14 | Count Good Nodes in Binary Tree | 1448 | DFS top-down | Track max on path |
| 15 | House Robber III | 337 | DFS + DP | Rob/not-rob at each node |
| 16 | Implement Trie | 208 | Trie | [🔥 Must Do] Prefix tree implementation |
| 17 | Word Search II | 212 | Trie + backtracking | [🔥 Must Do] Trie-guided DFS on grid |
| 18 | Design Add and Search Words | 211 | Trie + DFS | Wildcard search in trie |
| 19 | Delete Node in a BST | 450 | BST delete | Three cases: leaf, one child, two children |
| 20 | Trim a BST | 669 | BST recursion | Prune nodes outside range |
| 21 | Convert BST to Sorted Doubly Linked List | 426 | BST inorder | In-place conversion |
| 22 | All Nodes Distance K in Binary Tree | 863 | BFS + parent map | [🔥 Must Do] Convert tree to graph |
| 23 | Serialize and Deserialize Binary Tree | 297 | Serialize | [🔥 Must Do] Preorder with nulls |
| 24 | Binary Search Tree Iterator | 173 | Iterative inorder | Controlled traversal |
| 25 | Sum Root to Leaf Numbers | 129 | DFS top-down | Accumulate number on path |

### Hard

| # | Problem Name | LC # | Pattern(s) | Why Important |
|---|-------------|------|-----------|---------------|
| 1 | Binary Tree Maximum Path Sum | 124 | Path + global max | [🔥 Must Do] Any-to-any path |
| 2 | Serialize and Deserialize Binary Tree | 297 | Serialize | [🔥 Must Do] Multiple approaches |
| 3 | Word Search II | 212 | Trie + backtracking | [🔥 Must Do] Trie optimization |
| 4 | Binary Tree Cameras | 968 | DFS greedy | Greedy bottom-up |
| 5 | Vertical Order Traversal | 987 | BFS + sorting | Column-based ordering |
| 6 | Count of Smaller Numbers After Self | 315 | BST / merge sort | Inversion counting |
| 7 | Recover Binary Search Tree | 99 | BST inorder | Find two swapped nodes |
| 8 | Maximum Sum BST in Binary Tree | 1373 | DFS + BST validation | Combine validation + sum |

---

## 5. Interview Strategy

**Decision tree for tree problems:**

```
Is it a BST?
├── YES → Exploit sorted property (inorder, bounds, binary search)
└── NO → Is it level-based?
    ├── YES → BFS with queue + levelSize
    └── NO → DFS
        ├── Need info from children? → Bottom-up (postorder)
        ├── Need to pass info down? → Top-down (preorder)
        └── Need global answer? → Global variable + bottom-up
```

**Communication tips:**
1. "I'll use a bottom-up DFS because I need to compute the height of each subtree first, then combine the results."
2. "This is a BST, so inorder traversal gives me sorted order — I can find the kth smallest by doing an inorder traversal and stopping at k."
3. "The key insight is that the maximum path sum through a node equals left_gain + node.val + right_gain, but when returning to the parent, I can only include one branch."

**Common mistakes:**
- Forgetting the base case (`if (node == null)`)
- Confusing height vs depth (height = bottom-up, depth = top-down)
- Not handling the case where the answer doesn't pass through the root (diameter, max path sum)
- Using global variables without resetting them between test cases
- In BST validation: using `int` bounds instead of `long` (fails for `Integer.MIN_VALUE`)
- Forgetting to backtrack in path collection problems (remove last element after recursion)

💥 **What Can Go Wrong in Interviews:**

| Mistake | Impact | Prevention |
|---------|--------|------------|
| Missing base case | StackOverflow or wrong answer | Always start with `if (node == null)` |
| Height vs depth confusion | Wrong calculation | Height = from bottom, depth = from top |
| Global variable not reset | Wrong answer on second test case | Use return values instead, or reset before each call |
| BST validation with int bounds | Fails for MIN_VALUE/MAX_VALUE | Use `long` for bounds |
| Forgetting backtrack | Wrong paths collected | Remove added element after recursive calls |

---

## 6. Edge Cases & Pitfalls

**Tree edge cases:**
- ☐ Empty tree (`root == null`) → return 0/null/empty/false
- ☐ Single node → height 0, depth 0, diameter 0, is BST, is balanced
- ☐ Skewed tree (all left or all right) → degenerates to linked list, height = n-1
- ☐ Negative values in path sum problems → can't prune early (negative + negative might still reach target)
- ☐ BST with duplicate values → clarify with interviewer (usually not allowed)
- ☐ Very deep tree → recursion stack overflow (use iterative approach)
- ☐ Perfect binary tree → max width at last level = n/2

**Java-specific pitfalls:**

```java
// PITFALL 1: TreeMap null handling
TreeMap<Integer, String> map = new TreeMap<>();
map.floorKey(5); // returns null if no key ≤ 5 — check for null!

// PITFALL 2: Integer overflow in path sum
// Node values can be up to 10^4, tree can have 3×10^4 nodes
// Max path sum: 10^4 × 3×10^4 = 3×10^8 — fits in int
// But for safety, use long in prefix sum problems

// PITFALL 3: Modifying tree during traversal
// If you flatten a tree to a linked list, the original tree structure is destroyed
// Save references before modifying pointers
```

---

## 7. Connections to Other Topics

| This Pattern | Connects To | How |
|-------------|-------------|-----|
| DFS on trees | [01-dsa/06-graphs.md](06-graphs.md) | Trees are acyclic connected graphs; DFS is the same |
| BFS on trees | [01-dsa/06-graphs.md](06-graphs.md) | Same algorithm, no visited set needed (no cycles) |
| BST | [01-dsa/11-sorting-searching.md](11-sorting-searching.md) | BST search = binary search on a linked structure |
| Trie | [01-dsa/01-arrays-strings-hashing.md](01-arrays-strings-hashing.md) | Prefix-based alternative to HashMap for string problems |
| Trie | [02-system-design/problems/search-autocomplete.md](../02-system-design/problems/search-autocomplete.md) | Trie is the core data structure for autocomplete |
| Tree DP | [01-dsa/07-dynamic-programming.md](07-dynamic-programming.md) | Many DP problems have tree structure (house robber III, etc.) |
| Serialize tree | [02-system-design/01-fundamentals.md](../02-system-design/01-fundamentals.md) | Data serialization for storage/network transfer |
| Balanced BST | [07-cs-fundamentals/03-database-internals.md](../07-cs-fundamentals/03-database-internals.md) | B-tree/B+ tree for database indexing |
| LCA | [01-dsa/06-graphs.md](06-graphs.md) | LCA generalizes to DAGs and general graphs |
| Prefix sum on tree | [01-dsa/01-arrays-strings-hashing.md](01-arrays-strings-hashing.md) | Same prefix sum + HashMap technique applied to tree paths |
| TreeMap/TreeSet | [05-java/02-collections-internals.md](../05-java/02-collections-internals.md) | Red-black tree implementation in Java |

---

## 8. Revision Checklist

**Traversals:**
- [ ] Preorder: root → left → right (serialize, copy). Iterative: stack, process on pop, push right then left.
- [ ] Inorder: left → root → right (BST sorted order). Iterative: stack + go-left loop, process on pop, go right.
- [ ] Postorder: left → right → root (height, delete). Iterative: two stacks or reverse of modified preorder.
- [ ] Level-order: BFS with queue + `levelSize = queue.size()` before inner loop.

**Patterns:**
- [ ] Bottom-up DFS: compute from children, combine at node. Used for height, diameter, balanced check.
- [ ] Top-down DFS: pass info from parent to children. Used for path sum, good nodes, depth tracking.
- [ ] BST validation: pass (min, max) bounds using `long`, or check inorder is strictly increasing.
- [ ] LCA: recurse both sides. If both non-null → current is LCA. If one null → propagate the other.
- [ ] Max path sum: global max updated at each node. Return single-side path. Ignore negatives with `max(0, ...)`.
- [ ] Tree construction: preorder gives root, inorder gives left/right split. HashMap for O(1) index lookup.
- [ ] Serialize: preorder with "null" markers. Deserialize: queue of tokens, consume in preorder.
- [ ] Trie: `children[26]` array + `isEnd` flag. Insert/search/startsWith all O(L).
- [ ] Prefix sum on tree: same as array prefix sum, but BACKTRACK when returning from subtree.

**Complexity:**
- [ ] DFS: O(n) time, O(h) space (h = height, log n for balanced, n for skewed)
- [ ] BFS: O(n) time, O(w) space (w = max width, up to n/2 for complete tree)
- [ ] BST operations: O(log n) balanced, O(n) skewed
- [ ] Trie: O(L) per operation, L = word length

**Critical details:**
- [ ] Height vs depth: height = bottom-up (leaf=0), depth = top-down (root=0)
- [ ] BST validation: use `long` bounds, not `int` (handles Integer.MIN_VALUE/MAX_VALUE)
- [ ] Max path sum: return single-side to parent (path can't fork), update global with both sides
- [ ] Diameter: left_height + right_height at each node, track global max
- [ ] Prefix sum on tree: MUST backtrack (remove prefix sum) when returning from subtree
- [ ] Iterative inorder: `while (curr != null || !stack.isEmpty())` — both conditions needed
- [ ] BFS levelSize: capture `queue.size()` BEFORE the inner loop

**Top 12 must-solve:**
1. Maximum Depth (LC 104) [Easy] — Simplest bottom-up DFS
2. Invert Binary Tree (LC 226) [Easy] — Swap children recursively
3. Diameter (LC 543) [Easy] — Height + global max
4. Validate BST (LC 98) [Medium] — Bounds checking with long
5. LCA (LC 236) [Medium] — Recurse both sides
6. Binary Tree Level Order (LC 102) [Medium] — BFS foundation
7. Max Path Sum (LC 124) [Hard] — Any-to-any path, single-side return
8. Construct from Preorder + Inorder (LC 105) [Medium] — Index mapping
9. Serialize/Deserialize (LC 297) [Hard] — Preorder with null markers
10. Implement Trie (LC 208) [Medium] — Prefix tree
11. Word Search II (LC 212) [Hard] — Trie + backtracking on grid
12. Kth Smallest in BST (LC 230) [Medium] — Iterative inorder

---

## 📋 Suggested New Documents

### 1. Segment Trees & Binary Indexed Trees
- **Placement**: `01-dsa/12-segment-tree-bit.md`
- **Why needed**: Range query problems (range sum, range min/max, range update) appear in hard interview problems and competitive programming. Segment trees and BITs are not covered anywhere in the current project.
- **Key subtopics**: Segment tree build/query/update, lazy propagation, Binary Indexed Tree (Fenwick tree), range sum queries, count of smaller numbers after self (LC 315)

### 2. Advanced Tree Problems
- **Placement**: `01-dsa/12-advanced-trees.md`
- **Why needed**: Morris traversal (O(1) space), threaded binary trees, Euler tour for LCA, binary lifting, centroid decomposition — these advanced techniques appear in hard problems and system design discussions.
- **Key subtopics**: Morris traversal, tree flattening techniques, LCA with binary lifting, tree diameter algorithms, heavy-light decomposition (overview)
