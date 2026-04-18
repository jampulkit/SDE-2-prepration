> ✅ **[CORE] — Must-do for SDE-2 interviews.**

# Heaps & Priority Queues

## 1. Foundation

**A heap is a complete binary tree stored as an array where every parent is smaller (min-heap) or larger (max-heap) than its children — this gives you O(1) access to the min/max and O(log n) insertion/removal.**

When you need fast access to the minimum or maximum element while also supporting efficient insertion. Arrays give O(1) access to min/max (if sorted) but O(n) insertion. Heaps give O(1) access to min/max and O(log n) insertion/removal.

💡 **Intuition:** Think of a heap as a tournament bracket. In a min-heap, the champion (root) is the smallest element. To find the champion, you don't need to look at every player — just the root. When the champion is removed, the runner-up bubbles up to take its place. When a new player enters, they start at the bottom and challenge their way up.

**Heap properties** [🔥 Must Know]:
- **Complete binary tree** stored as an array (no gaps — filled level by level, left to right)
- **Min-heap:** parent ≤ children (root is minimum)
- **Max-heap:** parent ≥ children (root is maximum)
- For node at index `i`: left child = `2i+1`, right child = `2i+2`, parent = `(i-1)/2`

⚙️ **Under the Hood — Why Array Representation Works:**
A complete binary tree has no gaps, so array indices map perfectly to tree positions. No pointers needed — parent/child relationships are computed with simple arithmetic.

```
Min-heap as tree:          Min-heap as array:
        1                  index: [0] [1] [2] [3] [4] [5]
       / \                 value: [ 1,  3,  2,  7,  4,  5]
      3   2
     / \  /                Parent of index 4: (4-1)/2 = 1 → value 3 ✓
    7  4 5                 Children of index 1: 2*1+1=3, 2*1+2=4 → values 7, 4 ✓
```

⚙️ **Under the Hood — Bubble Up and Bubble Down:**

```
INSERT (offer) — Bubble Up:
  1. Add new element at the END of the array (next available position)
  2. Compare with parent. If smaller (min-heap), swap with parent.
  3. Repeat until heap property is restored or reach root.
  Time: O(log n) — at most height of tree = log n swaps.

  Insert 0 into [1, 3, 2, 7, 4, 5]:
  Step 1: [1, 3, 2, 7, 4, 5, 0]  ← added at end (index 6)
  Step 2: parent of 6 = (6-1)/2 = 2. arr[6]=0 < arr[2]=2 → swap
          [1, 3, 0, 7, 4, 5, 2]
  Step 3: parent of 2 = (2-1)/2 = 0. arr[2]=0 < arr[0]=1 → swap
          [0, 3, 1, 7, 4, 5, 2]  ← 0 is now root ✓

REMOVE MIN (poll) — Bubble Down:
  1. Replace root with the LAST element. Remove last.
  2. Compare root with children. Swap with the SMALLER child (min-heap).
  3. Repeat until heap property is restored or reach a leaf.
  Time: O(log n).

  Poll from [1, 3, 2, 7, 4, 5]:
  Step 1: Replace root with last: [5, 3, 2, 7, 4]
  Step 2: 5 > min(3, 2) = 2 → swap with 2
          [2, 3, 5, 7, 4]
  Step 3: 5 > min(children)? 5 has no children at valid indices → stop
          [2, 3, 5, 7, 4] ✓ Root is now 2 (next smallest)
```

**Operations complexity:**

| Operation | Time | Notes |
|-----------|------|-------|
| peek (min/max) | O(1) | Just return root (index 0) |
| offer (insert) | O(log n) | Add at end, bubble up |
| poll (remove min/max) | O(log n) | Replace root with last, bubble down |
| remove(Object) | O(n) | Linear search to find + O(log n) heapify |
| heapify (build heap) | O(n) | Bottom-up heapify, NOT O(n log n) |
| contains | O(n) | Linear search (heap is NOT sorted) |

⚙️ **Under the Hood — Why Build Heap is O(n), Not O(n log n):**
Bottom-up heapify starts from the last non-leaf node and bubbles down. Nodes near the bottom (most nodes) only bubble down 1-2 levels. The math: Σ(nodes at height h × h) = n × Σ(h/2^h) ≈ 2n = O(n). This is a common interview question.

**Java's PriorityQueue** [🔥 Must Know]:
- **Min-heap by default** — smallest element at the top
- Backed by a resizable array (grows by 50% when small, 100% when large)
- Default capacity: 11
- Not thread-safe (use `PriorityBlockingQueue` for concurrency)
- Does NOT guarantee order of iteration (only `poll()` returns elements in order)
- `null` elements not allowed

```java
// Min-heap (default) — smallest first
PriorityQueue<Integer> minHeap = new PriorityQueue<>();

// Max-heap — largest first
PriorityQueue<Integer> maxHeap = new PriorityQueue<>(Comparator.reverseOrder());

// Custom comparator (sort by second element of array)
PriorityQueue<int[]> pq = new PriorityQueue<>(Comparator.comparingInt(a -> a[1]));

// Multi-field comparator
PriorityQueue<int[]> pq = new PriorityQueue<>((a, b) -> {
    if (a[0] != b[0]) return Integer.compare(a[0], b[0]); // primary: ascending
    return Integer.compare(b[1], a[1]);                     // secondary: descending
});
```

⚠️ **Common Pitfall — Comparator Overflow:**

```java
// DANGEROUS — overflow when a and b have different signs and large magnitudes
PriorityQueue<Integer> pq = new PriorityQueue<>((a, b) -> a - b);
// Example: a = Integer.MIN_VALUE, b = 1 → a - b overflows to positive!

// SAFE — always use Integer.compare or Comparator methods
PriorityQueue<Integer> pq = new PriorityQueue<>(Integer::compare);
PriorityQueue<Integer> pq = new PriorityQueue<>(Comparator.naturalOrder());
```

| Approach | Pros | Cons | Best When |
|----------|------|------|-----------|
| PriorityQueue (heap) | O(log n) insert/remove, O(1) peek | O(n) remove by value, O(n) contains | Need min/max with dynamic inserts |
| TreeSet/TreeMap | O(log n) all ops, O(log n) remove by value | Higher constant factor | Need remove by value, floor/ceiling |
| Sorted array | O(1) peek, O(n) insert | Slow insert | Static data, only need min/max |

🎯 **Likely Follow-ups:**
- **Q:** Why is PriorityQueue iteration not ordered?
  **A:** The heap property only guarantees parent ≤ children, not that the array is sorted. Siblings have no ordering relationship. Only `poll()` extracts elements in order (by repeatedly removing the root).
- **Q:** How would you implement a max-heap from scratch?
  **A:** Same as min-heap but reverse all comparisons. In `bubbleUp`, swap if child > parent. In `bubbleDown`, swap with the larger child.
- **Q:** When would you use TreeSet instead of PriorityQueue?
  **A:** When you need O(log n) removal of arbitrary elements (not just the min/max), or when you need floor/ceiling operations. PriorityQueue's `remove(Object)` is O(n).

> 🔗 **See Also:** [05-java/02-collections-internals.md](../05-java/02-collections-internals.md) for PriorityQueue internals. [01-dsa/06-graphs.md](06-graphs.md) Pattern 5 for Dijkstra's algorithm using a min-heap.

---

## 2. Core Patterns

### Pattern 1: Top-K Elements [🔥 Must Know]

**To find the k largest elements, use a min-heap of size k. The root is always the kth largest — anything smaller gets rejected.**

**When to recognize it:** "Find k largest/smallest/most frequent elements."

💡 **Intuition:** Imagine a VIP club with exactly k spots. The bouncer (heap root) is the weakest VIP. When someone stronger arrives, the weakest VIP gets kicked out. At the end, the k strongest people are in the club, and the bouncer is the kth strongest.

**Why min-heap for k largest (not max-heap)?**
- Max-heap approach: insert all n elements, poll k times → O(n log n) time, O(n) space
- Min-heap of size k: insert each element, evict smallest when size > k → O(n log k) time, O(k) space
- The min-heap approach is better when k << n

```java
// LC 215: Kth Largest Element in an Array [🔥 Must Do]
public int findKthLargest(int[] nums, int k) {
    PriorityQueue<Integer> minHeap = new PriorityQueue<>(); // min-heap of size k
    for (int num : nums) {
        minHeap.offer(num);
        if (minHeap.size() > k) minHeap.poll(); // evict smallest — not in top k
    }
    return minHeap.peek(); // root = kth largest
}
```

**Dry run:** `nums = [3, 2, 1, 5, 6, 4]`, k = 2

```
3: heap = [3]
2: heap = [2, 3]
1: heap = [1, 3, 2] → size 3 > k=2 → poll 1 → heap = [2, 3]
5: heap = [2, 3, 5] → poll 2 → heap = [3, 5]
6: heap = [3, 5, 6] → poll 3 → heap = [5, 6]
4: heap = [4, 6, 5] → poll 4 → heap = [5, 6]

peek() = 5 = 2nd largest ✓
```

| Approach | Time | Space | Notes |
|----------|------|-------|-------|
| Sort + index | O(n log n) | O(1) | Simple but slow for large n |
| Min-heap of size k | O(n log k) | O(k) | Best when k << n |
| Quickselect | O(n) avg, O(n²) worst | O(1) | Fastest average, but worst case is bad |
| Max-heap (all elements) | O(n + k log n) | O(n) | Build heap O(n), poll k times |

```java
// LC 347: Top K Frequent Elements [🔥 Must Do]
public int[] topKFrequent(int[] nums, int k) {
    // Step 1: Count frequencies
    Map<Integer, Integer> freq = new HashMap<>();
    for (int n : nums) freq.merge(n, 1, Integer::sum);

    // Step 2: Min-heap of size k (by frequency)
    PriorityQueue<Map.Entry<Integer, Integer>> minHeap =
        new PriorityQueue<>(Comparator.comparingInt(Map.Entry::getValue));

    for (var entry : freq.entrySet()) {
        minHeap.offer(entry);
        if (minHeap.size() > k) minHeap.poll(); // evict least frequent
    }

    return minHeap.stream().mapToInt(Map.Entry::getKey).toArray();
}
```

⚙️ **Under the Hood — Bucket Sort Alternative (O(n)):**
Create an array of lists indexed by frequency. `buckets[i]` = list of elements with frequency `i`. Max frequency ≤ n. Iterate from highest bucket to collect top k.

```java
// O(n) bucket sort approach
List<Integer>[] buckets = new List[nums.length + 1];
for (int i = 0; i < buckets.length; i++) buckets[i] = new ArrayList<>();
for (var entry : freq.entrySet()) buckets[entry.getValue()].add(entry.getKey());

int[] result = new int[k];
int idx = 0;
for (int i = buckets.length - 1; i >= 0 && idx < k; i--) {
    for (int num : buckets[i]) {
        if (idx < k) result[idx++] = num;
    }
}
return result;
```

**Edge Cases:**
- ☐ k = 1 → just find the max/min
- ☐ k = n → return all elements
- ☐ All elements equal → any k of them
- ☐ Negative numbers → heap handles them correctly

🎯 **Likely Follow-ups:**
- **Q:** What if k is very close to n?
  **A:** Use a max-heap of size (n-k) to find the (n-k) smallest, then the remaining are the k largest. Or just sort — when k ≈ n, O(n log n) ≈ O(n log k).
- **Q:** What if the data is streaming (infinite)?
  **A:** Min-heap of size k is perfect for streaming — process each element in O(log k) and maintain O(k) space regardless of stream size.
- **Q:** How does Quickselect work?
  **A:** Partition the array around a pivot (like quicksort). If the pivot lands at index n-k, we're done. If it's too far left, recurse on the right half. If too far right, recurse on the left. Average O(n), worst O(n²). Use random pivot for expected O(n).

---

### Pattern 2: Merge K Sorted Streams [🔥 Must Know]

**Keep one element from each stream in a min-heap. Poll the smallest, then add the next element from that stream.**

**When to recognize it:** "Merge k sorted lists/arrays", "smallest range covering elements from k lists."

💡 **Intuition:** Imagine k conveyor belts, each delivering items in sorted order. You have a display showing the front item from each belt. You always pick the smallest item from the display, then the belt advances to show its next item. The min-heap IS the display — it always shows you the k front items and lets you pick the smallest in O(log k).

```java
// Already covered in linked lists doc — see Pattern 3 there
// Complexity: O(n log k) where n = total elements, k = number of streams
```

---

### Pattern 3: Two Heaps (Median Maintenance) [🔥 Must Know]

**Split elements into two halves: a max-heap for the smaller half and a min-heap for the larger half. The median is at the boundary between them.**

**When to recognize it:** "Find median from data stream", "sliding window median", or any problem requiring the middle element of a dynamic set.

💡 **Intuition:** Imagine sorting a deck of cards into two piles: "small" and "large." The small pile is face-up (you can see the largest small card = max-heap root). The large pile is also face-up (you can see the smallest large card = min-heap root). The median is either the top of the small pile (odd count) or the average of both tops (even count).

```java
// LC 295: Find Median from Data Stream [🔥 Must Do]
class MedianFinder {
    PriorityQueue<Integer> maxHeap = new PriorityQueue<>(Comparator.reverseOrder()); // left half (smaller)
    PriorityQueue<Integer> minHeap = new PriorityQueue<>(); // right half (larger)

    public void addNum(int num) {
        maxHeap.offer(num);                    // Step 1: add to left half
        minHeap.offer(maxHeap.poll());         // Step 2: move largest of left to right
        // This ensures: everything in maxHeap ≤ everything in minHeap

        if (minHeap.size() > maxHeap.size()) { // Step 3: rebalance sizes
            maxHeap.offer(minHeap.poll());
        }
        // Invariant: maxHeap.size() == minHeap.size() or maxHeap.size() == minHeap.size() + 1
    }

    public double findMedian() {
        if (maxHeap.size() > minHeap.size()) return maxHeap.peek(); // odd count
        return (maxHeap.peek() + minHeap.peek()) / 2.0;             // even count
    }
}
```

**Dry run:** addNum(1), addNum(2), findMedian(), addNum(3), findMedian()

```
addNum(1): maxHeap=[1], minHeap=[] → move 1 to minHeap → maxHeap=[], minHeap=[1]
           minHeap.size() > maxHeap.size() → move 1 back → maxHeap=[1], minHeap=[]

addNum(2): maxHeap=[2,1], minHeap=[] → move 2 to minHeap → maxHeap=[1], minHeap=[2]
           sizes equal → no rebalance

findMedian(): sizes equal → (1 + 2) / 2.0 = 1.5 ✓

addNum(3): maxHeap=[3,1], minHeap=[2] → move 3 to minHeap → maxHeap=[1], minHeap=[2,3]
           minHeap.size() > maxHeap.size() → move 2 to maxHeap → maxHeap=[2,1], minHeap=[3]

findMedian(): maxHeap.size() > minHeap.size() → maxHeap.peek() = 2 ✓
```

**Edge Cases:**
- ☐ Single element → median is that element
- ☐ Two elements → average
- ☐ All same elements → median is that element
- ☐ Negative numbers → works correctly

🎯 **Likely Follow-ups:**
- **Q:** How would you handle a sliding window median?
  **A:** Same two-heap approach, but you also need to remove elements leaving the window. Since PriorityQueue.remove() is O(n), use lazy deletion: mark elements as removed, and when they appear at the top during poll, skip them. Or use two TreeSets (which support O(log n) removal).
- **Q:** What's the time complexity?
  **A:** addNum: O(log n) (three heap operations). findMedian: O(1). Space: O(n).

---

### Pattern 4: Lazy Deletion

**Instead of removing elements from the heap (O(n) search), mark them as invalid and skip them when they appear at the top during poll.**

**When to recognize it:** Need to remove specific elements from a heap, but `PriorityQueue.remove(Object)` is O(n).

```java
// Used in Dijkstra's algorithm — skip outdated entries
while (!pq.isEmpty()) {
    int[] curr = pq.poll();
    int dist = curr[0], node = curr[1];
    if (dist > shortestDist[node]) continue; // this entry is outdated — skip
    // process node...
}
```

💡 **Intuition:** Instead of surgically removing an element from the middle of the heap (expensive), just leave it there. When it eventually reaches the top, check if it's still valid. If not, discard it and poll the next one. This trades a small amount of extra space and time for avoiding the O(n) removal.

---

### Pattern 5: Heap for Scheduling / Simulation

**Use a heap to track resource availability — the root tells you when the next resource becomes free.**

```java
// LC 253: Meeting Rooms II [🔥 Must Do]
// Minimum number of conference rooms required
public int minMeetingRooms(int[][] intervals) {
    Arrays.sort(intervals, Comparator.comparingInt(a -> a[0])); // sort by start time
    PriorityQueue<Integer> endTimes = new PriorityQueue<>(); // min-heap of room end times

    for (int[] interval : intervals) {
        if (!endTimes.isEmpty() && endTimes.peek() <= interval[0]) {
            endTimes.poll(); // earliest-ending room is free → reuse it
        }
        endTimes.offer(interval[1]); // assign this meeting to a room
    }
    return endTimes.size(); // number of rooms in use = heap size
}
```

💡 **Intuition:** Each room in the heap is represented by its end time. When a new meeting starts, check if the earliest-ending room is free (end time ≤ start time). If yes, reuse it (poll and offer new end time). If no, allocate a new room (just offer). The heap size = number of rooms needed.

**Dry run:** `intervals = [[0,30],[5,10],[15,20]]`

```
Sort by start: [[0,30],[5,10],[15,20]]

[0,30]: heap empty → add 30. heap = [30]. rooms = 1.
[5,10]: peek=30 > 5 → can't reuse → add 10. heap = [10, 30]. rooms = 2.
[15,20]: peek=10 ≤ 15 → reuse! poll 10, add 20. heap = [20, 30]. rooms = 2.

Answer: 2 rooms ✓
```

---

### Pattern 6: Kth Smallest in Sorted Matrix / K-way Merge

**Start with the first element of each row (or just the first row). Poll the smallest, then add the next element from the same row.**

```java
// LC 378: Kth Smallest Element in a Sorted Matrix [🔥 Must Do]
public int kthSmallest(int[][] matrix, int k) {
    int n = matrix.length;
    // Min-heap: {value, row, col}
    PriorityQueue<int[]> pq = new PriorityQueue<>(Comparator.comparingInt(a -> a[0]));

    // Seed with first element of each row (or first min(n, k) rows)
    for (int i = 0; i < Math.min(n, k); i++) {
        pq.offer(new int[]{matrix[i][0], i, 0});
    }

    int result = 0;
    while (k-- > 0) {
        int[] curr = pq.poll();
        result = curr[0];
        int row = curr[1], col = curr[2];
        if (col + 1 < n) { // add next element from same row
            pq.offer(new int[]{matrix[row][col + 1], row, col + 1});
        }
    }
    return result;
}
```

💡 **Intuition:** Each row is a sorted stream. The heap merges k streams, always giving you the next smallest element across all streams. After polling k times, you have the kth smallest.

**Alternative — Binary Search:** Binary search on the value range [matrix[0][0], matrix[n-1][n-1]]. For each mid value, count how many elements ≤ mid (using the sorted property of rows and columns). O(n log(max-min)) time.


---

## 3. Patterns Summary Table

| # | Pattern | When to Use | Key Idea | Time | Space | Example |
|---|---------|------------|----------|------|-------|---------|
| 1 | Top-K | K largest/smallest/frequent | Heap of size k (opposite type) | O(n log k) | O(k) | Kth Largest (LC 215) |
| 2 | Merge K sorted | Merge multiple sorted streams | Min-heap of size k, one per stream | O(n log k) | O(k) | Merge K Lists (LC 23) |
| 3 | Two heaps | Median, middle element | Max-heap (left) + min-heap (right) | O(log n) add | O(n) | Find Median (LC 295) |
| 4 | Lazy deletion | Remove from heap efficiently | Skip outdated entries on poll | O(log n)* | O(n) | Dijkstra's algorithm |
| 5 | Scheduling | Task/meeting scheduling | Heap tracks resource end times | O(n log n) | O(n) | Meeting Rooms II (LC 253) |
| 6 | K-way merge | Kth in sorted matrix | Heap + expand next from same row/stream | O(k log k) | O(k) | Kth in Matrix (LC 378) |

**Pattern Selection Flowchart:**

```
Heap problem?
├── "K largest/smallest/frequent"? → Pattern 1: Top-K (min-heap of size k)
├── "Merge sorted streams"? → Pattern 2: K-way merge (min-heap of size k)
├── "Median" or "middle element"? → Pattern 3: Two heaps (max-heap + min-heap)
├── "Schedule/assign resources"? → Pattern 5: Scheduling (heap of end times)
├── "Kth in sorted matrix"? → Pattern 6: K-way merge or binary search
└── Need to remove from heap? → Pattern 4: Lazy deletion (skip on poll)
```

---

## 4. LeetCode Problem List (Must-Solve)

### Easy

| # | Problem Name | LC # | Pattern(s) | Why Important |
|---|-------------|------|-----------|---------------|
| 1 | Kth Largest Element in a Stream | 703 | Top-K | Min-heap of size k |
| 2 | Last Stone Weight | 1046 | Max-heap simulation | Basic heap usage |
| 3 | Relative Ranks | 506 | Heap / sort | Simple ranking |

### Medium

| # | Problem Name | LC # | Pattern(s) | Why Important |
|---|-------------|------|-----------|---------------|
| 1 | Kth Largest Element in an Array | 215 | Top-K | [🔥 Must Do] Heap vs quickselect |
| 2 | Top K Frequent Elements | 347 | Top-K + frequency | [🔥 Must Do] Heap vs bucket sort |
| 3 | K Closest Points to Origin | 973 | Top-K | Max-heap of size k |
| 4 | Find Median from Data Stream | 295 | Two heaps | [🔥 Must Do] Classic two-heap |
| 5 | Meeting Rooms II | 253 | Scheduling | [🔥 Must Do] Min-heap of end times |
| 6 | Task Scheduler | 621 | Greedy + heap | [🔥 Must Do] Max-heap for frequency |
| 7 | Reorganize String | 767 | Greedy + heap | Most frequent first |
| 8 | Kth Smallest Element in a Sorted Matrix | 378 | K-way merge | [🔥 Must Do] Heap or binary search |
| 9 | Sort Characters By Frequency | 451 | Heap / bucket sort | Frequency-based ordering |
| 10 | Ugly Number II | 264 | Min-heap | Generate in order |
| 11 | Find K Pairs with Smallest Sums | 373 | K-way merge | Expand from (0,0) |
| 12 | Furthest Building You Can Reach | 1642 | Min-heap (greedy) | [🔥 Must Do] Use ladders for biggest jumps |
| 13 | Seat Reservation Manager | 1845 | Min-heap | Smallest available |
| 14 | Process Tasks Using Servers | 1882 | Two heaps | Available + busy servers |
| 15 | Design Twitter | 355 | Merge K sorted | K-way merge of user feeds |

### Hard

| # | Problem Name | LC # | Pattern(s) | Why Important |
|---|-------------|------|-----------|---------------|
| 1 | Merge K Sorted Lists | 23 | Merge K | [🔥 Must Do] K-way merge |
| 2 | Sliding Window Median | 480 | Two heaps + window | Median with removals |
| 3 | Find Median from Data Stream | 295 | Two heaps | [🔥 Must Do] |
| 4 | IPO | 502 | Two heaps (greedy) | Max profit within capital |
| 5 | Smallest Range Covering Elements from K Lists | 632 | K-way merge + window | Track range while merging |
| 6 | Trapping Rain Water II | 407 | Min-heap (BFS) | 2D trapping water |
| 7 | The Skyline Problem | 218 | Max-heap + sweep line | [🔥 Must Do] Event-based processing |
| 8 | Course Schedule III | 630 | Greedy + max-heap | Replace longest course |

---

## 5. Interview Strategy

**When to use a heap:**
- "K largest/smallest" → heap of size k
- "Merge sorted" → min-heap of size k
- "Median" → two heaps
- "Schedule/assign resources" → heap tracks availability
- "Continuously process by priority" → heap as priority queue

**Communication tips:**

```
You: "I need the k largest elements. I'll use a min-heap of size k.
     The root is always the kth largest — anything smaller gets evicted.
     This gives me O(n log k) time and O(k) space, which is better than
     sorting when k is much smaller than n."

You: "For the median, I'll maintain two heaps: a max-heap for the smaller
     half and a min-heap for the larger half. The median is at the boundary.
     Each insertion is O(log n), and finding the median is O(1)."
```

**Common mistakes:**
- Using max-heap for k largest (should be min-heap of size k — counterintuitive!)
- Forgetting that Java's PriorityQueue is a min-heap by default
- Comparator overflow: `(a, b) -> a - b` overflows for large values → use `Integer.compare`
- Assuming PriorityQueue iteration is ordered (it's NOT — only `poll()` is ordered)
- Not considering bucket sort as O(n) alternative for frequency-based top-k
- Forgetting to handle the case where the heap is empty before calling `peek()` or `poll()`

💥 **What Can Go Wrong in Interviews:**

| Mistake | Impact | Prevention |
|---------|--------|------------|
| Max-heap for k largest | O(n log n) instead of O(n log k) | Remember: min-heap of size k, evict smallest |
| Comparator overflow | Wrong ordering, subtle bugs | Always use `Integer.compare` or `Comparator.comparingInt` |
| Iterate heap expecting order | Wrong output | Only `poll()` gives ordered results |
| Forget empty check | NullPointerException | Check `isEmpty()` before `peek()`/`poll()` |

---

## 6. Edge Cases & Pitfalls

**Heap edge cases:**
- ☐ k = 0 or k > n → handle before processing
- ☐ All elements equal → any k of them
- ☐ Single element → trivially the answer
- ☐ Negative numbers → comparators handle correctly, but overflow risk in subtraction
- ☐ Empty heap → `poll()` returns null, `peek()` returns null

**Java-specific pitfalls:**

```java
// PITFALL 1: PriorityQueue.remove(Object) is O(n)
PriorityQueue<Integer> pq = new PriorityQueue<>();
pq.remove(5); // O(n) linear search! Use lazy deletion instead.

// PITFALL 2: PriorityQueue with custom objects — need Comparable or Comparator
// Without either, ClassCastException at runtime
PriorityQueue<int[]> pq = new PriorityQueue<>(); // WRONG — int[] not Comparable
PriorityQueue<int[]> pq = new PriorityQueue<>(Comparator.comparingInt(a -> a[0])); // CORRECT

// PITFALL 3: Modifying elements after insertion
// PriorityQueue doesn't re-heapify when you modify an element's value
// The heap property may be violated → wrong results
// Solution: remove and re-insert, or use a different data structure

// PITFALL 4: toArray() doesn't return sorted order
Integer[] arr = pq.toArray(new Integer[0]); // NOT sorted!
// To get sorted: poll() repeatedly into a list
```

---

## 7. Connections to Other Topics

| This Pattern | Connects To | How |
|-------------|-------------|-----|
| Top-K | [01-dsa/11-sorting-searching.md](11-sorting-searching.md) | Quickselect is O(n) average alternative |
| Merge K sorted | [01-dsa/04-linked-lists.md](04-linked-lists.md) | Merge K sorted linked lists |
| Two heaps | [01-dsa/02-two-pointers-sliding-window.md](02-two-pointers-sliding-window.md) | Sliding window median |
| Heap + greedy | [01-dsa/08-greedy-backtracking.md](08-greedy-backtracking.md) | Heap provides "best available" for greedy decisions |
| Dijkstra | [01-dsa/06-graphs.md](06-graphs.md) | Min-heap drives Dijkstra's shortest path |
| Heap sort | [01-dsa/11-sorting-searching.md](11-sorting-searching.md) | O(n log n) in-place sort using heap |
| Scheduling | [02-system-design/problems/notification-system.md](../02-system-design/problems/notification-system.md) | Priority queues in task scheduling systems |
| Median | [07-cs-fundamentals/03-database-internals.md](../07-cs-fundamentals/03-database-internals.md) | Percentile computation in databases |
| PriorityQueue | [05-java/02-collections-internals.md](../05-java/02-collections-internals.md) | Java PriorityQueue implementation details |
| K-way merge | [06-tech-stack/01-kafka-deep-dive.md](../06-tech-stack/01-kafka-deep-dive.md) | Merging sorted partitions in stream processing |

---

## 8. Revision Checklist

**Java PriorityQueue:**
- [ ] Min-heap by default. Max-heap: `Comparator.reverseOrder()` or `Collections.reverseOrder()`
- [ ] `offer()` O(log n), `poll()` O(log n), `peek()` O(1), `remove(Object)` O(n)
- [ ] Use `Integer.compare(a, b)` not `a - b` for comparators (overflow safety)
- [ ] Iteration order is NOT guaranteed — only `poll()` returns elements in order
- [ ] `null` not allowed. Empty heap: `poll()` returns null, `peek()` returns null.
- [ ] Build heap from collection: `new PriorityQueue<>(collection)` — O(n)

**Patterns:**
- [ ] Top-K largest → min-heap of size k (evict smallest, root = kth largest)
- [ ] Top-K smallest → max-heap of size k (evict largest, root = kth smallest)
- [ ] Merge K sorted → min-heap, one element per stream, poll smallest, add next from same stream
- [ ] Median → max-heap (left/smaller half) + min-heap (right/larger half), balance sizes
- [ ] Scheduling → sort by start time, min-heap of end times, reuse room if peek ≤ start
- [ ] Lazy deletion → skip outdated entries when they reach the top during poll

**Critical details:**
- [ ] Min-heap for k LARGEST (counterintuitive — the root is the kth largest, the "gatekeeper")
- [ ] Two-heap median: add to maxHeap → move max to minHeap → rebalance sizes
- [ ] Build heap is O(n), not O(n log n) — bottom-up heapify
- [ ] Bucket sort is O(n) alternative for frequency-based top-k problems
- [ ] Quickselect is O(n) average for kth element (but O(n²) worst case)

**Top 8 must-solve:**
1. Kth Largest Element (LC 215) — Top-K with min-heap
2. Top K Frequent Elements (LC 347) — Frequency + heap or bucket sort
3. Find Median from Data Stream (LC 295) — Two-heap median
4. Merge K Sorted Lists (LC 23) — K-way merge
5. Meeting Rooms II (LC 253) — Scheduling with min-heap
6. Task Scheduler (LC 621) — Greedy + max-heap
7. Kth Smallest in Sorted Matrix (LC 378) — K-way merge or binary search
8. The Skyline Problem (LC 218) — Max-heap + sweep line

---

## 📋 Suggested New Documents

### 1. Quickselect & Selection Algorithms
- **Placement**: `01-dsa/12-selection-algorithms.md`
- **Why needed**: Quickselect (O(n) average kth element), median of medians (O(n) worst case), and introselect are important alternatives to heap-based approaches. They appear in interviews as follow-ups to top-k problems.
- **Key subtopics**: Quickselect algorithm, Lomuto vs Hoare partition, median of medians for worst-case O(n), randomized selection, comparison with heap approach
