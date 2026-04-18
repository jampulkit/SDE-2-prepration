> ✅ **[CORE] — Must-do for SDE-2 interviews.**

# Linked Lists

## 1. Foundation

**A linked list is a chain of nodes where each node holds a value and a pointer to the next node — unlike arrays, nodes can live anywhere in memory, which makes insertion and deletion at any known position O(1) but sacrifices random access.**

Arrays require contiguous memory and have O(n) insertion/deletion in the middle. Linked lists trade random access for O(1) insertion/deletion at any known position — each node stores a value and a pointer to the next node, so elements can be scattered in memory.

💡 **Intuition:** Think of a linked list like a scavenger hunt. Each clue (node) tells you where the next clue is. To find the 5th clue, you must follow clues 1→2→3→4→5 — you can't jump directly to it. But if you want to insert a new clue between clue 3 and clue 4, you just change clue 3's "next" pointer — no need to move any other clues.

**When linked lists beat arrays:**
- Frequent insertions/deletions at arbitrary positions (given a reference to the node)
- Unknown size upfront (no resizing needed)
- Implementing stacks, queues, LRU caches
- When you need O(1) splice/merge operations

**When arrays beat linked lists:**
- Random access needed (linked list is O(n) to reach index i)
- Cache performance matters (arrays are cache-friendly; linked list nodes are scattered in heap)
- Memory overhead: each linked list node has ~32-40 bytes overhead in Java (object header + next pointer + padding)

⚙️ **Under the Hood — Memory Layout Comparison:**

```
Array (int[5]):
  Contiguous memory: [10][20][30][40][50]
  One object header for the entire array.
  CPU cache loads multiple elements at once (spatial locality).
  Total memory: 16 (header) + 5×4 (ints) = 36 bytes

Linked List (5 nodes):
  Scattered in heap:
    Node@0x100: [val=10|next→0x250]
    Node@0x250: [val=20|next→0x480]
    Node@0x480: [val=30|next→0x120]
    Node@0x120: [val=40|next→0x390]
    Node@0x390: [val=50|next→null]
  Each node: 16 (header) + 4 (val) + 8 (next ref) + 4 (padding) = 32 bytes
  Total: 5 × 32 = 160 bytes (4.4× more than array!)
  CPU cache misses on every node access (poor spatial locality).
```

**Types of linked lists:**

| Type | Structure | Use Case | Java Class |
|------|-----------|----------|------------|
| Singly linked | `val → next` | Most interview problems | Custom `ListNode` |
| Doubly linked | `prev ← val → next` | LRU cache, browser history | `java.util.LinkedList` |
| Circular | Last node points to head | Round-robin scheduling, circular buffers | Custom |

**Standard ListNode definition (used in LeetCode):**

```java
public class ListNode {
    int val;
    ListNode next;
    ListNode() {}
    ListNode(int val) { this.val = val; }
    ListNode(int val, ListNode next) { this.val = val; this.next = next; }
}
```

**Java's `LinkedList<E>` internals:**
- Doubly-linked list of `Node<E>` objects (each has `item`, `next`, `prev`)
- Implements both `List<E>` and `Deque<E>`
- `get(i)` is O(n) — traverses from head or tail (whichever is closer, optimization: checks if `i < size/2`)
- `add()`/`remove()` at head/tail is O(1)
- Rarely used in practice — `ArrayList` and `ArrayDeque` are almost always better due to cache performance

**Operations complexity:**

| Operation | Singly Linked | Doubly Linked | ArrayList |
|-----------|--------------|---------------|-----------|
| Access by index | O(n) | O(n) | O(1) |
| Insert at head | O(1) | O(1) | O(n) |
| Insert at tail | O(n)* / O(1)** | O(1) | O(1) amortized |
| Insert at middle (given node) | O(1) | O(1) | O(n) |
| Delete (given node) | O(n)*** | O(1) | O(n) |
| Search | O(n) | O(n) | O(n) |

\* O(n) if no tail pointer, \*\* O(1) with tail pointer, \*\*\* O(n) because you need the previous node in singly linked

| Approach | Pros | Cons | Best When |
|----------|------|------|-----------|
| Singly linked list | Simple, less memory per node | Can't go backwards, delete needs prev | Most interview problems |
| Doubly linked list | O(1) delete given node, bidirectional | More memory (prev pointer), more complex | LRU cache, browser history |
| ArrayList | O(1) random access, cache-friendly | O(n) insert/delete in middle | Default choice for most applications |

**The dummy head technique** [🔥 Must Know]:

Many linked list problems have edge cases when modifying the head. A dummy node eliminates these:

```java
ListNode dummy = new ListNode(0);
dummy.next = head;
// ... do operations (head might change) ...
return dummy.next; // new head — always correct
```

💡 **Intuition — Why dummy head?** Without a dummy, you need special-case logic for "what if the head itself needs to be removed/changed?" For example, removing duplicates from `[1,1,2]` — the head node (1) needs to be removed. With a dummy, the head is just another node in the list, and the code handles it uniformly.

```
Without dummy (needs special case):
  if (head.val == target) head = head.next; // special case for head
  // ... handle rest of list differently

With dummy (uniform handling):
  dummy → head → ... → null
  // Every node (including head) has a predecessor — no special case needed
```

🎯 **Likely Follow-ups:**
- **Q:** When would you NOT use a dummy head?
  **A:** When you're only reading the list (not modifying structure), or when the problem guarantees the head won't change. Also, in cycle detection problems, a dummy head would break the cycle structure.
- **Q:** Why are linked lists used in LRU caches instead of arrays?
  **A:** LRU cache needs O(1) removal of any node (when accessed, move to front) and O(1) eviction of the least recently used (remove from tail). A doubly linked list with a HashMap (key → node reference) achieves both. An array would need O(n) shifting for removal.

> 🔗 **See Also:** [04-lld/problems/cache-lru-lfu.md](../04-lld/problems/cache-lru-lfu.md) for LRU/LFU cache design using doubly linked lists. [05-java/02-collections-internals.md](../05-java/02-collections-internals.md) for Java's LinkedList internals.


---

## 2. Core Patterns

### Pattern 1: Fast and Slow Pointers (Floyd's Algorithm) [🔥 Must Know]

**Two pointers start at the head — slow moves 1 step, fast moves 2 steps. When fast reaches the end, slow is at the middle. If there's a cycle, they'll eventually meet inside it.**

**When to recognize it:** Cycle detection, finding the middle of a list, finding the start of a cycle, or any problem where you need to relate positions in a list.

💡 **Intuition:** Imagine two runners on a circular track. The fast runner goes twice as fast. If the track is circular (cycle), the fast runner will eventually lap the slow runner — they'll meet. If the track is straight (no cycle), the fast runner reaches the end first.

**Sub-pattern 1a: Find middle of linked list**

```java
// LC 876: Middle of the Linked List
public ListNode middleNode(ListNode head) {
    ListNode slow = head, fast = head;
    while (fast != null && fast.next != null) {
        slow = slow.next;       // 1 step
        fast = fast.next.next;  // 2 steps
    }
    return slow; // for even-length list, returns SECOND middle
}
```

**Why it works:** When `fast` reaches the end (traveled ~2n steps), `slow` has traveled ~n steps — the middle.

```
Odd length:  1 → 2 → 3 → 4 → 5
                     ↑ slow stops here (fast at 5, fast.next=null)

Even length: 1 → 2 → 3 → 4 → 5 → 6
                          ↑ slow stops here (second middle, fast at null)
```

**To get the FIRST middle for even-length lists:** Change the condition to `while (fast.next != null && fast.next.next != null)`. This stops slow one node earlier.

**Sub-pattern 1b: Detect cycle**

```java
// LC 141: Linked List Cycle
public boolean hasCycle(ListNode head) {
    ListNode slow = head, fast = head;
    while (fast != null && fast.next != null) {
        slow = slow.next;
        fast = fast.next.next;
        if (slow == fast) return true; // they met → cycle exists
    }
    return false; // fast reached end → no cycle
}
```

**Sub-pattern 1c: Find cycle start** [🔥 Must Know]

```java
// LC 142: Linked List Cycle II
public ListNode detectCycle(ListNode head) {
    ListNode slow = head, fast = head;
    while (fast != null && fast.next != null) {
        slow = slow.next;
        fast = fast.next.next;
        if (slow == fast) {
            // Phase 2: find cycle start
            ListNode entry = head;
            while (entry != slow) {
                entry = entry.next;
                slow = slow.next;
            }
            return entry; // both pointers meet at cycle start
        }
    }
    return null; // no cycle
}
```

⚙️ **Under the Hood — Mathematical Proof of Phase 2:**

```
Let:
  a = distance from head to cycle start
  b = distance from cycle start to meeting point
  c = cycle length

At meeting point:
  slow traveled: a + b
  fast traveled: a + b + n*c  (n complete cycles, n ≥ 1)

Since fast = 2 × slow:
  a + b + n*c = 2(a + b)
  n*c = a + b
  a = n*c - b

This means: starting from the meeting point, traveling 'a' more steps
lands you at the cycle start (because n*c - b = going around the cycle
n times minus b steps = arriving at cycle start).

And starting from the head, traveling 'a' steps also lands at cycle start.

So both pointers (one from head, one from meeting point) meet at cycle start!
```

```
Visual:

head → [1] → [2] → [3] → [4] → [5]
                     ↑              ↓
                     [8] ← [7] ← [6]

a = 2 (head to cycle start at node 3)
b = 3 (cycle start to meeting point)
c = 6 (cycle length: 3→4→5→6→7→8→3)

Phase 1: slow and fast meet at some node inside the cycle
Phase 2: one pointer from head, one from meeting point
         both travel 'a' steps → meet at node 3 (cycle start)
```

**Edge Cases:**
- ☐ No cycle → fast reaches null → return null/false
- ☐ Cycle of length 1 (node points to itself) → slow and fast meet at that node
- ☐ Cycle includes the head → a = 0, entry pointer starts at head and immediately matches
- ☐ Single node with no cycle → fast.next is null → return false
- ☐ Single node pointing to itself → fast = slow after one step

🎯 **Likely Follow-ups:**
- **Q:** Can you detect a cycle without modifying the list and using O(1) space?
  **A:** Floyd's algorithm does exactly this — O(n) time, O(1) space. The alternative (HashSet of visited nodes) uses O(n) space.
- **Q:** How would you find the cycle length?
  **A:** After detecting the meeting point, keep one pointer fixed and move the other around the cycle, counting steps until they meet again. That count is the cycle length.
- **Q:** Does Floyd's algorithm work for directed graphs?
  **A:** Yes — it detects cycles in any sequence where you can follow "next" pointers. It's used in the "find duplicate number" problem (LC 287) where array values are treated as next pointers.

> 🔗 **See Also:** [01-dsa/06-graphs.md](06-graphs.md) for cycle detection in general graphs (DFS-based). [01-dsa/02-two-pointers-sliding-window.md](02-two-pointers-sliding-window.md) for the fast/slow pointer concept applied to arrays.

---

### Pattern 2: Reverse a Linked List [🔥 Must Know]

**Reverse the direction of all pointers — each node's `next` should point to its predecessor instead of its successor. The key is saving the next node before overwriting the pointer.**

**When to recognize it:** "Reverse a list", "reverse a portion", "palindrome check", or any problem where you need to process nodes in reverse order.

💡 **Intuition:** Imagine a one-way street where all arrows point right. To reverse it, you visit each intersection and flip the arrow to point left. But before flipping, you need to remember where the next intersection is (because the arrow you're about to flip is your only way to find it).

**Iterative reversal (memorize this — you'll use it in 5+ problems):**

```java
// LC 206: Reverse Linked List [🔥 Must Do]
public ListNode reverseList(ListNode head) {
    ListNode prev = null, curr = head;
    while (curr != null) {
        ListNode next = curr.next; // 1. save next (before we lose it)
        curr.next = prev;          // 2. reverse the pointer
        prev = curr;               // 3. advance prev
        curr = next;               // 4. advance curr
    }
    return prev; // prev is the new head
}
```

**Dry run:** `1 → 2 → 3 → null`

```
Step 0: prev=null, curr=1→2→3→null

Step 1: next=2, 1→null, prev=1, curr=2
        null ← 1   2 → 3 → null
               ↑prev  ↑curr

Step 2: next=3, 2→1, prev=2, curr=3
        null ← 1 ← 2   3 → null
                    ↑prev  ↑curr

Step 3: next=null, 3→2, prev=3, curr=null
        null ← 1 ← 2 ← 3
                         ↑prev  ↑curr=null → STOP

Return prev = 3 (new head)
Result: 3 → 2 → 1 → null ✓
```

**Recursive reversal:**

```java
public ListNode reverseList(ListNode head) {
    if (head == null || head.next == null) return head; // base case
    ListNode newHead = reverseList(head.next);          // reverse the rest
    head.next.next = head;  // make the next node point back to current
    head.next = null;       // break the old forward pointer
    return newHead;         // new head is always the last node
}
```

```
Recursive call trace for 1→2→3:
  reverseList(1): calls reverseList(2)
    reverseList(2): calls reverseList(3)
      reverseList(3): base case, return 3
    Back in reverseList(2): 3.next=2, 2.next=null → 3→2→null. Return 3.
  Back in reverseList(1): 2.next=1, 1.next=null → 3→2→1→null. Return 3.
```

⚠️ **Common Pitfall:** Recursive reversal uses O(n) stack space. For very long lists (10⁵+ nodes), this can cause StackOverflowError. Always prefer iterative in interviews unless asked for recursive.

**Reverse a portion (LC 92: Reverse Linked List II):**

```java
// Reverse nodes from position left to right (1-indexed)
public ListNode reverseBetween(ListNode head, int left, int right) {
    ListNode dummy = new ListNode(0, head);
    ListNode prev = dummy;

    // Move prev to the node just before position 'left'
    for (int i = 1; i < left; i++) prev = prev.next;

    // Reverse 'right - left' links using the "insert at front" technique
    ListNode curr = prev.next;
    for (int i = 0; i < right - left; i++) {
        ListNode next = curr.next;    // node to move
        curr.next = next.next;        // skip over 'next'
        next.next = prev.next;        // insert 'next' after prev
        prev.next = next;             // update prev's next
    }
    return dummy.next;
}
```

**Dry run:** `1 → 2 → 3 → 4 → 5`, left=2, right=4

```
Initial: dummy → 1 → 2 → 3 → 4 → 5
prev = node 1 (just before position 2)
curr = node 2

i=0: next=3, curr(2)→4, 3→2, prev(1)→3
     dummy → 1 → 3 → 2 → 4 → 5

i=1: next=4, curr(2)→5, 4→3, prev(1)→4
     dummy → 1 → 4 → 3 → 2 → 5

Result: 1 → 4 → 3 → 2 → 5 ✓ (positions 2-4 reversed)
```

**Edge Cases:**
- ☐ Single node → return as-is
- ☐ left == right → no reversal needed
- ☐ left == 1 → head changes (dummy head handles this)
- ☐ right == length → reversal goes to the end
- ☐ Entire list reversed (left=1, right=n) → same as full reversal

🎯 **Likely Follow-ups:**
- **Q:** How would you reverse in groups of k (LC 25)?
  **A:** Count k nodes ahead. If k nodes exist, reverse them using the iterative method, then recursively (or iteratively) handle the rest. Connect the reversed group's tail to the next group's head.
- **Q:** Can you reverse without extra space (no `next` variable)?
  **A:** No — you need at least one temporary variable to save the next pointer before overwriting it. The iterative approach already uses O(1) extra space (just `prev`, `curr`, `next`).

---

### Pattern 3: Merge Linked Lists

**Compare heads of two sorted lists, pick the smaller one, and advance that list's pointer — repeat until one list is exhausted, then attach the remainder.**

**When to recognize it:** "Merge two sorted lists", "merge k sorted lists", or combining lists.

💡 **Intuition:** Like merging two sorted piles of cards into one sorted pile. You always pick the smaller top card from either pile and place it on the result pile.

```java
// LC 21: Merge Two Sorted Lists [🔥 Must Do]
public ListNode mergeTwoLists(ListNode l1, ListNode l2) {
    ListNode dummy = new ListNode(0);
    ListNode curr = dummy;

    while (l1 != null && l2 != null) {
        if (l1.val <= l2.val) {
            curr.next = l1;    // pick from l1
            l1 = l1.next;
        } else {
            curr.next = l2;    // pick from l2
            l2 = l2.next;
        }
        curr = curr.next;
    }
    curr.next = (l1 != null) ? l1 : l2; // attach remaining
    return dummy.next;
}
```

**Complexity:** O(n + m) time, O(1) space (reusing existing nodes).

**Merge K sorted lists (LC 23)** [🔥 Must Do] — use a min-heap:

```java
public ListNode mergeKLists(ListNode[] lists) {
    // Min-heap ordered by node value
    PriorityQueue<ListNode> pq = new PriorityQueue<>((a, b) -> a.val - b.val);
    for (ListNode head : lists) {
        if (head != null) pq.offer(head);
    }

    ListNode dummy = new ListNode(0), curr = dummy;
    while (!pq.isEmpty()) {
        ListNode node = pq.poll();     // smallest node across all lists
        curr.next = node;
        curr = curr.next;
        if (node.next != null) pq.offer(node.next); // add next node from same list
    }
    return dummy.next;
}
```

⚙️ **Under the Hood — Why Heap for K-way Merge:**
At any point, we need the smallest element among k list heads. A min-heap gives us this in O(log k). We process n total nodes, each requiring one heap operation → O(n log k) total.

| Approach | Time | Space | Notes |
|----------|------|-------|-------|
| Merge one by one | O(nk) | O(1) | Merge list 1+2, then result+3, etc. |
| Divide and conquer | O(n log k) | O(log k) | Pair up lists, merge pairs, repeat |
| Min-heap | O(n log k) | O(k) | Heap of k list heads |

**Complexity:** O(n log k) where n = total nodes, k = number of lists.

**Edge Cases:**
- ☐ Empty lists array → return null
- ☐ Some lists are null → skip them when adding to heap
- ☐ All lists empty → heap is empty → return null
- ☐ k = 1 → return the single list
- ☐ k = 2 → degenerates to merge two sorted lists

🎯 **Likely Follow-ups:**
- **Q:** What if the lists are not sorted?
  **A:** Sort each list first (merge sort on linked list is O(n log n)), then merge. Or dump all values into an array, sort, and rebuild the list.
- **Q:** How would you merge k sorted lists in a distributed system?
  **A:** External merge sort: each machine sorts its portion, then a coordinator does k-way merge using a min-heap. This is exactly how MapReduce's shuffle phase works.

> 🔗 **See Also:** [01-dsa/09-heap-priority-queue.md](09-heap-priority-queue.md) for heap internals and k-way merge patterns. [01-dsa/11-sorting-searching.md](11-sorting-searching.md) for merge sort.

---

### Pattern 4: Two Pointers with Gap

**Advance the fast pointer by n steps first, creating a gap. Then move both pointers together — when fast reaches the end, slow is at the target position.**

**When to recognize it:** "Remove nth node from end", "find kth from end" — need to find a position relative to the end without knowing the length.

💡 **Intuition:** Imagine two people walking along a path. Person A starts walking first and gets n steps ahead. Then both walk at the same speed. When Person A reaches the end, Person B is exactly n steps from the end.

```java
// LC 19: Remove Nth Node From End of List [🔥 Must Do]
public ListNode removeNthFromEnd(ListNode head, int n) {
    ListNode dummy = new ListNode(0, head);
    ListNode fast = dummy, slow = dummy;

    // Move fast n+1 steps ahead (so slow stops ONE BEFORE the target)
    for (int i = 0; i <= n; i++) fast = fast.next;

    // Move both until fast reaches null
    while (fast != null) {
        fast = fast.next;
        slow = slow.next;
    }
    slow.next = slow.next.next; // skip the nth node from end
    return dummy.next;
}
```

**Why `n+1` steps:** We need `slow` to stop one node BEFORE the target so we can modify `slow.next`. If we only moved n steps, slow would be AT the target, and we'd need the previous node (which we don't have in a singly linked list).

**Dry run:** `1 → 2 → 3 → 4 → 5`, n=2 (remove 4, which is 2nd from end)

```
dummy → 1 → 2 → 3 → 4 → 5 → null

Move fast n+1=3 steps: fast at node 2
  dummy → 1 → 2 → 3 → 4 → 5 → null
  ↑slow        ↑fast

Move both until fast=null:
  fast=3, slow=1
  fast=4, slow=2
  fast=5, slow=3
  fast=null → STOP. slow at node 3.

slow.next = slow.next.next → skip node 4
Result: 1 → 2 → 3 → 5 ✓
```

**Edge Cases:**
- ☐ Remove the head (n = list length) → dummy head handles this
- ☐ Remove the tail (n = 1) → slow stops at second-to-last
- ☐ Single node, n = 1 → remove the only node → return null
- ☐ n equals list length → remove head

---

### Pattern 5: Reorder / Rearrange List

**Find the middle, reverse the second half, then merge the two halves alternately — this combines three fundamental patterns into one problem.**

**When to recognize it:** "Reorder list", "odd-even linked list", "partition list" — rearranging nodes without creating new ones.

```java
// LC 143: Reorder List [🔥 Must Do]
// 1→2→3→4→5 becomes 1→5→2→4→3
public void reorderList(ListNode head) {
    if (head == null || head.next == null) return;

    // Step 1: Find middle (slow stops at end of first half)
    ListNode slow = head, fast = head;
    while (fast.next != null && fast.next.next != null) {
        slow = slow.next;
        fast = fast.next.next;
    }

    // Step 2: Reverse second half
    ListNode second = reverse(slow.next);
    slow.next = null; // cut the list into two halves

    // Step 3: Merge alternately (interleave)
    ListNode first = head;
    while (second != null) {
        ListNode tmp1 = first.next, tmp2 = second.next;
        first.next = second;    // first points to second
        second.next = tmp1;     // second points to first's old next
        first = tmp1;           // advance first
        second = tmp2;          // advance second
    }
}
```

**Dry run:** `1 → 2 → 3 → 4 → 5`

```
Step 1: Find middle → slow at 3
        First half: 1 → 2 → 3 → null
        Second half: 4 → 5

Step 2: Reverse second half → 5 → 4

Step 3: Interleave:
  first=1, second=5: 1→5, 5→2. first=2, second=4
  first=2, second=4: 2→4, 4→3. first=3, second=null → STOP

Result: 1 → 5 → 2 → 4 → 3 ✓
```

**This problem combines three patterns:** find middle + reverse + merge. Very common in interviews — if you can solve this cleanly, you demonstrate mastery of linked list fundamentals.

**Edge Cases:**
- ☐ Empty list or single node → return as-is
- ☐ Two nodes `1→2` → becomes `1→2` (no change needed)
- ☐ Three nodes `1→2→3` → becomes `1→3→2`
- ☐ Even length `1→2→3→4` → becomes `1→4→2→3`

---

### Pattern 6: Palindrome Check

**Find the middle, reverse the second half, compare both halves node by node.**

```java
// LC 234: Palindrome Linked List
public boolean isPalindrome(ListNode head) {
    // Step 1: Find middle
    ListNode slow = head, fast = head;
    while (fast != null && fast.next != null) {
        slow = slow.next;
        fast = fast.next.next;
    }

    // Step 2: Reverse second half
    ListNode rev = reverse(slow);

    // Step 3: Compare first half with reversed second half
    ListNode p1 = head, p2 = rev;
    while (p2 != null) {
        if (p1.val != p2.val) return false;
        p1 = p1.next;
        p2 = p2.next;
    }
    return true;
    // Note: this modifies the list. To restore, reverse 'rev' again.
}
```

⚠️ **Common Pitfall:** This approach modifies the original list (the second half is reversed). If the interviewer asks you to preserve the list, reverse the second half again after comparison.

---

### Pattern 7: Intersection of Two Lists

**Redirect each pointer to the other list's head when it reaches the end — after traversing m+n nodes each, both pointers align at the intersection (or both reach null).**

```java
// LC 160: Intersection of Two Linked Lists [🔥 Must Do]
public ListNode getIntersectionNode(ListNode headA, ListNode headB) {
    ListNode a = headA, b = headB;
    while (a != b) {
        a = (a != null) ? a.next : headB; // redirect to other list at end
        b = (b != null) ? b.next : headA;
    }
    return a; // either intersection node or null (no intersection)
}
```

⚙️ **Under the Hood — Why This Works:**

```
List A: a1 → a2 → c1 → c2 → c3        (length m = 5)
List B: b1 → b2 → b3 → c1 → c2 → c3   (length n = 6)

Pointer a travels: a1→a2→c1→c2→c3 → b1→b2→b3→c1  (m + n - common = 5+3 = 8 steps)
Pointer b travels: b1→b2→b3→c1→c2→c3 → a1→a2→c1  (n + m - common = 6+2 = 8 steps)

Both arrive at c1 after the same number of steps!

If no intersection:
Pointer a: a1→a2→a3 → b1→b2 → null  (m + n steps)
Pointer b: b1→b2 → a1→a2→a3 → null  (n + m steps)
Both reach null simultaneously → return null.
```

**Edge Cases:**
- ☐ No intersection → both reach null → return null
- ☐ Lists of equal length → no redirection needed, they align naturally
- ☐ One list is empty → immediately returns null
- ☐ Intersection at the head → both pointers start at the same node

🎯 **Likely Follow-ups:**
- **Q:** Can you solve this with O(1) space without the redirect trick?
  **A:** Yes — compute lengths of both lists, advance the longer list's pointer by the difference, then walk both together. They'll meet at the intersection.
- **Q:** What if the lists might have cycles?
  **A:** First detect and find cycles in both lists. If both have cycles, check if the cycle is shared (a node in one cycle is reachable from the other). This is significantly more complex.


---

## 3. Patterns Summary Table

| # | Pattern | When to Use | Key Idea | Time | Space | Example Problem |
|---|---------|------------|----------|------|-------|-----------------|
| 1 | Fast/slow pointers | Cycle, middle, kth from end | slow=1 step, fast=2 steps | O(n) | O(1) | Linked List Cycle II (LC 142) |
| 2 | Reverse list | Reverse all/portion, palindrome | prev/curr/next pointer dance | O(n) | O(1) | Reverse Linked List (LC 206) |
| 3 | Merge lists | Merge sorted, merge k lists | Dummy head + comparison / heap | O(n)/O(n log k) | O(1)/O(k) | Merge K Lists (LC 23) |
| 4 | Two pointers with gap | Nth from end, kth from end | Advance fast by n+1, then move both | O(n) | O(1) | Remove Nth From End (LC 19) |
| 5 | Reorder / rearrange | Reorder, odd-even, partition | Find middle + reverse + merge | O(n) | O(1) | Reorder List (LC 143) |
| 6 | Palindrome check | Is list a palindrome? | Middle + reverse second half + compare | O(n) | O(1) | Palindrome Linked List (LC 234) |
| 7 | Intersection | Find meeting point of two lists | Redirect at end, travel m+n steps | O(m+n) | O(1) | Intersection (LC 160) |

**Pattern Selection Flowchart:**

```
What does the problem ask?
├── Detect/find cycle? → Pattern 1: Fast/slow pointers
├── Reverse (all or part)? → Pattern 2: Reverse
├── Merge sorted lists? → Pattern 3: Merge (2 lists: compare, k lists: heap)
├── Find nth from end? → Pattern 4: Gap pointers
├── Rearrange nodes? → Pattern 5: Usually middle + reverse + merge
├── Check palindrome? → Pattern 6: Middle + reverse + compare
└── Find intersection? → Pattern 7: Redirect trick
```

---

## 4. LeetCode Problem List (Must-Solve)

### Easy

| # | Problem Name | LC # | Pattern(s) | Why Important |
|---|-------------|------|-----------|---------------|
| 1 | Reverse Linked List | 206 | Reverse | [🔥 Must Do] Fundamental — must be instant |
| 2 | Merge Two Sorted Lists | 21 | Merge | [🔥 Must Do] Merge pattern foundation |
| 3 | Linked List Cycle | 141 | Fast/slow | [🔥 Must Do] Basic cycle detection |
| 4 | Middle of the Linked List | 876 | Fast/slow | Fast/slow for middle |
| 5 | Intersection of Two Linked Lists | 160 | Two pointers | [🔥 Must Do] Elegant pointer redirect |
| 6 | Palindrome Linked List | 234 | Middle + reverse | Combines multiple patterns |
| 7 | Remove Duplicates from Sorted List | 83 | Single pass | Simple pointer manipulation |
| 8 | Remove Linked List Elements | 203 | Dummy head | Dummy head practice |

### Medium

| # | Problem Name | LC # | Pattern(s) | Why Important |
|---|-------------|------|-----------|---------------|
| 1 | Add Two Numbers | 2 | Traversal + carry | [🔥 Must Do] Digit-by-digit addition |
| 2 | Remove Nth Node From End of List | 19 | Gap pointers | [🔥 Must Do] Two-pointer gap technique |
| 3 | Reorder List | 143 | Middle + reverse + merge | [🔥 Must Do] Combines three patterns |
| 4 | Linked List Cycle II | 142 | Fast/slow (cycle start) | [🔥 Must Do] Mathematical proof |
| 5 | Sort List | 148 | Merge sort | [🔥 Must Do] O(n log n) sort on linked list |
| 6 | Copy List with Random Pointer | 138 | HashMap / interleaving | [🔥 Must Do] Deep copy with random pointers |
| 7 | Odd Even Linked List | 328 | Rearrange | Separate odd/even indexed nodes |
| 8 | Swap Nodes in Pairs | 24 | Pointer manipulation | Pairwise swap |
| 9 | Reverse Linked List II | 92 | Partial reverse | Reverse between positions |
| 10 | Rotate List | 61 | Cycle + break | Make circular, then break |
| 11 | Partition List | 86 | Two dummy lists | Split and reconnect |
| 12 | Flatten a Multilevel Doubly Linked List | 430 | Stack / recursion | DFS flattening |
| 13 | LRU Cache | 146 | Doubly linked + HashMap | [🔥 Must Do] Classic LLD problem |
| 14 | Design Linked List | 707 | Implementation | Full linked list from scratch |
| 15 | Remove Duplicates from Sorted List II | 82 | Dummy head + skip | Remove all duplicates |

### Hard

| # | Problem Name | LC # | Pattern(s) | Why Important |
|---|-------------|------|-----------|---------------|
| 1 | Merge K Sorted Lists | 23 | Heap + merge | [🔥 Must Do] Heap-based k-way merge |
| 2 | Reverse Nodes in k-Group | 25 | Reverse in groups | [🔥 Must Do] Hardest linked list problem |
| 3 | LFU Cache | 460 | Doubly linked + two maps | Extension of LRU |

---

## 5. Interview Strategy

**How to approach linked list problems:**

1. **Draw it out.** Always draw the list and trace pointer changes on paper/whiteboard. Linked list bugs are almost always pointer errors that are invisible in your head but obvious in a diagram.

2. **Use a dummy head** when the head might change (deletion, insertion at front, merging).

3. **Think about which patterns combine.** Many medium/hard problems combine 2-3 basic patterns:
   - Reorder List = find middle + reverse + merge
   - Palindrome = find middle + reverse + compare
   - Sort List = find middle + merge sort

4. **Consider edge cases immediately:** empty list, single node, two nodes, cycle.

5. **Save `next` before modifying pointers.** The #1 bug in linked list code is losing the reference to the next node.

**Sample dialogue with interviewer:**

```
You: "I'll use the fast/slow pointer technique to find the middle of the list.
     Then I'll reverse the second half. Finally, I'll interleave the two halves.
     This gives me O(n) time and O(1) space."

Interviewer: "What about edge cases?"

You: "Empty list and single node — I'll handle those with an early return.
     For even-length lists, the middle finder gives me the end of the first half,
     which is what I need for the split. I'll use a dummy head in case the
     head changes."
```

**Common mistakes:**
- Losing reference to the next node before changing pointers (save `next` first!)
- Forgetting to set the last node's `next` to `null` after reversal or splitting
- Not using a dummy head → special-casing head operations
- Off-by-one in "nth from end" (need to stop one node before target, hence n+1 gap)
- Modifying the list while also trying to read it (palindrome check — reverse modifies the list)
- Using recursion for very long lists → StackOverflowError (use iterative)
- Forgetting to handle null input

💥 **What Can Go Wrong in Interviews:**

| Mistake | Impact | Prevention |
|---------|--------|------------|
| NullPointerException | Runtime crash | Always check `node != null` before `node.next` |
| Lost pointer | Corrupted list, infinite loop | Save `next` BEFORE modifying `curr.next` |
| No dummy head | Special case for head, messy code | Default to using dummy head |
| Wrong middle for even length | Off-by-one in split | Test with both odd and even length lists |
| Recursive reversal on long list | StackOverflow | Use iterative reversal |

---

## 6. Edge Cases & Pitfalls

**Linked list edge cases:**
- ☐ Empty list (`head == null`) → return null/false/0
- ☐ Single node (`head.next == null`) → often trivial base case
- ☐ Two nodes → minimum for most operations (swap, reverse, etc.)
- ☐ Cycle that includes the head node → a = 0 in Floyd's
- ☐ Cycle of length 1 (node points to itself) → fast == slow after one step
- ☐ Very long list → recursion will stack overflow, use iterative
- ☐ Even vs odd length → affects middle finding (first vs second middle)
- ☐ Duplicate values → affects comparison-based operations

**Java-specific pitfalls:**

```java
// PITFALL 1: NullPointerException — the #1 linked list bug
ListNode node = null;
node.next; // NullPointerException!
// ALWAYS check: if (node != null && node.next != null)

// PITFALL 2: Reference vs value comparison
ListNode a = new ListNode(5);
ListNode b = new ListNode(5);
a == b;      // false — different objects
a.val == b.val; // true — same value
// Use == for "same node" checks (correct for cycle detection)
// Use .val == for value comparison

// PITFALL 3: Modifying list while iterating
// If you reverse part of a list, the original references become stale
ListNode head = ...; // 1→2→3→4→5
ListNode mid = findMiddle(head); // mid = node 3
reverse(mid); // now 3→2→1, but head still points to 1
// head.next.next is now null (node 2's next was changed!)
// Solution: cut the list before reversing (slow.next = null)

// PITFALL 4: Integer overflow in "Add Two Numbers"
// Each digit is 0-9, carry is 0-1, sum is at most 9+9+1=19
// No overflow risk for individual digits, but don't try to convert to int/long
// (the number can have 100+ digits — way beyond long range)
```

---

## 7. Connections to Other Topics

| This Pattern | Connects To | How |
|-------------|-------------|-----|
| Fast/slow pointers | [01-dsa/02-two-pointers-sliding-window.md](02-two-pointers-sliding-window.md) | Same concept applied to arrays (fast/slow for partitioning) |
| Merge sorted lists | [01-dsa/11-sorting-searching.md](11-sorting-searching.md) | Merge step of merge sort; merge sort is optimal for linked lists |
| Sort List | [01-dsa/11-sorting-searching.md](11-sorting-searching.md) | Merge sort on linked list — no random access needed |
| LRU Cache | [04-lld/problems/cache-lru-lfu.md](../04-lld/problems/cache-lru-lfu.md) | Doubly linked list + HashMap = O(1) LRU |
| Reverse list | [01-dsa/03-stacks-queues.md](03-stacks-queues.md) | Reversing is equivalent to pushing all then popping (stack) |
| Cycle detection | [01-dsa/06-graphs.md](06-graphs.md) | Floyd's works on directed graphs; DFS-based cycle detection for general graphs |
| K-way merge | [01-dsa/09-heap-priority-queue.md](09-heap-priority-queue.md) | Min-heap for efficient k-way merge |
| Linked list in Java | [05-java/02-collections-internals.md](../05-java/02-collections-internals.md) | Java's LinkedList implementation, Node structure |
| Skip list | [07-cs-fundamentals/03-database-internals.md](../07-cs-fundamentals/03-database-internals.md) | Skip lists (used in Redis, LevelDB) are layered linked lists for O(log n) search |

---

## 8. Revision Checklist

**Core operations to code instantly (under 2 minutes each):**
- [ ] Reverse a linked list (iterative): `prev=null, curr=head; while(curr) { next=curr.next; curr.next=prev; prev=curr; curr=next; } return prev;`
- [ ] Find middle: `slow=head, fast=head; while(fast && fast.next) { slow=slow.next; fast=fast.next.next; } return slow;`
- [ ] Detect cycle: slow/fast, check `if (slow == fast) return true`
- [ ] Find cycle start: after meeting, one pointer from head, one from meeting point, advance both by 1
- [ ] Merge two sorted lists: dummy head, compare and link smaller, attach remainder
- [ ] Remove nth from end: fast ahead by n+1, then move both, `slow.next = slow.next.next`

**Patterns:**
- [ ] Fast/slow → middle (fast=2×slow), cycle (they meet), cycle start (phase 2 from head)
- [ ] Reverse → iterative (prev/curr/next), recursive (head.next.next=head), partial (insert-at-front technique)
- [ ] Merge → two lists (compare heads), k lists (min-heap of k heads, O(n log k))
- [ ] Gap pointers → nth from end (fast ahead by n+1)
- [ ] Reorder → find middle + reverse second half + interleave
- [ ] Dummy head → whenever head might change (deletion, insertion, merging)

**Critical details:**
- [ ] Floyd's cycle start proof: `a = nc - b`, so head and meeting point converge at cycle start
- [ ] Dummy head eliminates special cases for head modification
- [ ] Save `next` BEFORE modifying `curr.next` — the #1 linked list bug
- [ ] For even-length lists, `slow` stops at second middle (use `fast.next && fast.next.next` for first middle)
- [ ] Merge K lists: heap size is always k → O(log k) per operation, O(n log k) total
- [ ] Recursive reversal uses O(n) stack space — prefer iterative in interviews

**Complexity:**
- [ ] All single-pass operations: O(n) time, O(1) space
- [ ] Merge K lists: O(n log k) time, O(k) space
- [ ] Sort list (merge sort): O(n log n) time, O(log n) space (recursion stack)
- [ ] Intersection: O(m + n) time, O(1) space

**Top 8 must-solve:**
1. Reverse Linked List (LC 206) [Easy] — The foundation
2. Linked List Cycle II (LC 142) [Medium] — Floyd's with mathematical proof
3. Merge Two Sorted Lists (LC 21) [Easy] — Merge pattern
4. Remove Nth From End (LC 19) [Medium] — Gap pointer technique
5. Reorder List (LC 143) [Medium] — Combines middle + reverse + merge
6. Sort List (LC 148) [Medium] — Merge sort on linked list
7. Copy List with Random Pointer (LC 138) [Medium] — Deep copy technique
8. Reverse Nodes in k-Group (LC 25) [Hard] — Hardest linked list problem

---

## 📋 Suggested New Documents

### 1. Advanced Linked List Patterns
- **Placement**: `01-dsa/12-advanced-linked-list.md`
- **Why needed**: Skip lists (used in Redis sorted sets, LevelDB), XOR linked lists (doubly linked with O(1) extra space), and self-organizing lists are advanced topics that appear in system design discussions and senior-level interviews.
- **Key subtopics**: Skip list structure and O(log n) search, XOR linked list trick, unrolled linked lists, memory-efficient doubly linked lists
