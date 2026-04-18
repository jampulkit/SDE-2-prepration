> ⚠️ **[OPTIONAL] — Rarely asked at SDE-2 interviews. Skip unless you've mastered files 00-14.**

# Advanced Linked List Patterns

## 1. Foundation

**Advanced linked list topics go beyond basic pointer manipulation: skip lists provide O(log n) search in a linked structure, and specialized variants like unrolled linked lists optimize for cache performance.**

💡 **Intuition:** Basic linked lists have O(n) search because you must traverse node by node. Skip lists solve this by adding "express lanes" (higher-level lists that skip over nodes), similar to how an express train skips local stops. This gives O(log n) expected search time while keeping the simplicity of a linked structure.

**When these appear in interviews:** Skip lists are asked at Google and Amazon (especially for system design discussions about Redis internals). The LeetCode problem "Design Skiplist" (LC 1206) tests direct implementation. XOR linked lists and unrolled linked lists are theoretical knowledge that shows depth.

**Comparison of linked list variants:**

| Variant | Search | Insert | Delete | Space per Node | Use Case |
|---------|--------|--------|--------|---------------|----------|
| Singly Linked | O(n) | O(1)* | O(n) | 1 pointer | Most interview problems |
| Doubly Linked | O(n) | O(1)* | O(1)* | 2 pointers | LRU cache, browser history |
| Skip List | O(log n) expected | O(log n) | O(log n) | ~2 pointers avg | Sorted set, concurrent maps |
| Unrolled Linked | O(n) | O(sqrt n) | O(sqrt n) | Array + 1 pointer | Text editors, cache-friendly lists |

*Given a reference to the node or its predecessor.

> 🔗 **See Also:** [01-dsa/04-linked-lists.md](04-linked-lists.md) for basic linked list patterns. [06-tech-stack/02-redis-deep-dive.md](../06-tech-stack/02-redis-deep-dive.md) for Redis sorted sets using skip lists.

---

## 2. Core Patterns

### Pattern 1: Skip List [🔥 Must Know]

**A skip list is a probabilistic data structure that layers multiple sorted linked lists on top of each other, enabling O(log n) search, insert, and delete.**

```
Level 3: HEAD ──────────────────────────────→ 50 ──────────→ NIL
Level 2: HEAD ──────────→ 20 ──────────────→ 50 ──────────→ NIL
Level 1: HEAD ──→ 10 ──→ 20 ──→ 30 ──→ 40 → 50 ──→ 60 ──→ NIL
Level 0: HEAD ──→ 10 ──→ 20 ──→ 25 → 30 → 40 → 50 → 55 → 60 → NIL

Search for 30:
  Start at Level 3: HEAD → 50 (too far) → go down
  Level 2: HEAD → 20 → 50 (too far) → go down from 20
  Level 1: 20 → 30 ✓ Found!
  
  3 comparisons instead of 8 (linear scan). O(log n) expected.
```

💡 **Intuition:** Think of a skip list like a book's table of contents. Level 0 is every page. Level 1 is every chapter. Level 2 is every section. To find page 150, you first jump to the right section (level 2), then the right chapter (level 1), then scan pages (level 0). Each level halves the search space.

⚙️ **Under the Hood, Level Assignment:**

```
When inserting a new node, randomly assign its level:
  Level 0: always (100%)
  Level 1: with probability p (typically p=0.5 or p=0.25)
  Level 2: with probability p²
  Level k: with probability p^k

With p=0.5:
  50% of nodes are at level 0 only
  25% reach level 1
  12.5% reach level 2
  ...

Expected number of levels: O(log n)
Expected space per node: 1/(1-p) pointers ≈ 2 pointers (for p=0.5)
Total expected space: O(n)
```

**Java implementation (LC 1206: Design Skiplist):**

```java
class Skiplist {
    private static final int MAX_LEVEL = 16;
    private static final double P = 0.5;
    private Node head = new Node(-1, MAX_LEVEL);
    private int level = 0;
    
    static class Node {
        int val;
        Node[] next; // next[i] = next node at level i
        Node(int val, int level) {
            this.val = val;
            this.next = new Node[level + 1];
        }
    }
    
    private int randomLevel() {
        int lvl = 0;
        while (lvl < MAX_LEVEL && Math.random() < P) lvl++;
        return lvl;
    }
    
    public boolean search(int target) {
        Node curr = head;
        for (int i = level; i >= 0; i--) { // start from highest level
            while (curr.next[i] != null && curr.next[i].val < target) {
                curr = curr.next[i]; // move right at this level
            }
            // Can't go further right at this level, go down
        }
        curr = curr.next[0]; // move to the actual node at level 0
        return curr != null && curr.val == target;
    }
    
    public void add(int num) {
        Node[] update = new Node[MAX_LEVEL + 1]; // predecessors at each level
        Node curr = head;
        for (int i = level; i >= 0; i--) {
            while (curr.next[i] != null && curr.next[i].val < num) curr = curr.next[i];
            update[i] = curr; // save predecessor at level i
        }
        int newLevel = randomLevel();
        if (newLevel > level) {
            for (int i = level + 1; i <= newLevel; i++) update[i] = head;
            level = newLevel;
        }
        Node newNode = new Node(num, newLevel);
        for (int i = 0; i <= newLevel; i++) {
            newNode.next[i] = update[i].next[i]; // insert after predecessor
            update[i].next[i] = newNode;
        }
    }
    
    public boolean erase(int num) {
        Node[] update = new Node[MAX_LEVEL + 1];
        Node curr = head;
        for (int i = level; i >= 0; i--) {
            while (curr.next[i] != null && curr.next[i].val < num) curr = curr.next[i];
            update[i] = curr;
        }
        curr = curr.next[0];
        if (curr == null || curr.val != num) return false;
        for (int i = 0; i <= level; i++) {
            if (update[i].next[i] != curr) break;
            update[i].next[i] = curr.next[i]; // bypass deleted node
        }
        while (level > 0 && head.next[level] == null) level--; // reduce level if needed
        return true;
    }
}
```

**Complexity:**

| Operation | Expected | Worst Case | Space |
|-----------|----------|-----------|-------|
| Search | O(log n) | O(n) | O(1) |
| Insert | O(log n) | O(n) | O(log n) for new node |
| Delete | O(log n) | O(n) | O(1) |
| Total space | O(n) | O(n log n) | - |

**Skip list vs balanced BST (Red-Black Tree, AVL):**

| Aspect | Skip List | Balanced BST |
|--------|-----------|-------------|
| Search/Insert/Delete | O(log n) expected | O(log n) guaranteed |
| Implementation | Simpler (no rotations) | Complex (rotations, color flips) |
| Concurrency | Lock-free implementations exist | Hard to make lock-free |
| Cache performance | Poor (pointer chasing) | Poor (pointer chasing) |
| Range queries | Natural (traverse level 0) | Inorder traversal |
| Space | ~2 pointers/node average | 3 pointers/node (left, right, parent) |

**Used in:** Redis sorted sets (ZSET), LevelDB/RocksDB memtable, Java's `ConcurrentSkipListMap` and `ConcurrentSkipListSet`.

🎯 **Likely Follow-ups:**
- **Q:** Why does Redis use skip lists instead of balanced BSTs for sorted sets?
  **A:** Three reasons: (1) Skip lists are simpler to implement and debug. (2) Skip lists support efficient range queries by traversing level 0. (3) Skip lists are easier to make concurrent (CAS-based lock-free insertion). Redis creator Salvatore Sanfilippo has stated simplicity was the primary reason.
- **Q:** What is the worst case for a skip list and how likely is it?
  **A:** Worst case is O(n) when all nodes are at level 0 (no express lanes). The probability of this is astronomically low: (1-p)^n. For n=1000 and p=0.5, that's 2^(-1000). In practice, skip lists perform very close to O(log n).
- **Q:** How does `ConcurrentSkipListMap` achieve thread safety without locks?
  **A:** It uses CAS (Compare-And-Swap) operations for insertion and deletion. The multi-level structure means concurrent operations on different parts of the list don't interfere. This is much harder to achieve with tree rotations in a BST.

---

### Pattern 2: XOR Linked List (Theoretical)

**A doubly-linked list using XOR of prev and next pointers instead of storing both. Each node stores `prev XOR next`.**

```
Standard doubly-linked: each node has prev + next = 2 pointers
XOR linked list: each node has (prev XOR next) = 1 pointer

Traversal forward: next = prev XOR node.xorPtr
Traversal backward: prev = next XOR node.xorPtr

Example: A ↔ B ↔ C ↔ D
  A.xor = 0 XOR addr(B) = addr(B)
  B.xor = addr(A) XOR addr(C)
  C.xor = addr(B) XOR addr(D)
  D.xor = addr(C) XOR 0 = addr(C)

To go from B to C (knowing we came from A):
  next = prev XOR B.xor = addr(A) XOR (addr(A) XOR addr(C)) = addr(C) ✓
```

Not practical in Java (no raw pointer arithmetic in managed languages). Relevant for C/C++ interviews or as a theoretical discussion point.

---

### Pattern 3: Unrolled Linked List

**Each node stores an array of elements instead of a single element. Combines linked list flexibility with array cache performance.**

```
Standard linked list: [1] → [2] → [3] → [4] → [5] → [6]
  6 nodes, 6 pointer dereferences to traverse

Unrolled (block size 3): [1,2,3] → [4,5,6]
  2 nodes, 2 pointer dereferences + array access within each block
  Better cache performance (array elements are contiguous)
```

**Used in:** Text editors (each node = one line or block of text), B+ tree leaf nodes.

**Complexity:** Search O(n), insert/delete O(sqrt(n)) with block size sqrt(n).

---

## 3. Revision Checklist

- [ ] Skip list: layered sorted linked lists, O(log n) expected, probabilistic level assignment
- [ ] Level assignment: each level with probability p (typically 0.5). Expected levels = O(log n).
- [ ] Skip list operations: search (top-down, right then down), insert (find predecessors, random level, splice), delete (find predecessors, bypass)
- [ ] Used in Redis ZSET, ConcurrentSkipListMap, LevelDB
- [ ] Skip list vs BST: simpler, concurrent-friendly, probabilistic vs guaranteed
- [ ] XOR linked list: `prev XOR next` in one field, theoretical, not practical in Java
- [ ] Unrolled linked list: array per node, better cache performance, used in text editors

**Top 5 must-solve:**
1. Design Skiplist (LC 1206) [Hard] - Full skip list implementation
2. LRU Cache (LC 146) [Medium] - Doubly-linked list + HashMap (basic but foundational)
3. LFU Cache (LC 460) [Hard] - Multiple doubly-linked lists by frequency
4. Flatten a Multilevel Doubly Linked List (LC 430) [Medium] - Recursive flattening
5. Copy List with Random Pointer (LC 138) [Medium] - Interleaving or HashMap approach

> 🔗 **See Also:** [01-dsa/04-linked-lists.md](04-linked-lists.md) for basic linked list patterns. [06-tech-stack/02-redis-deep-dive.md](../06-tech-stack/02-redis-deep-dive.md) for Redis sorted sets using skip lists. [05-java/02-collections-internals.md](../05-java/02-collections-internals.md) for ConcurrentSkipListMap.
