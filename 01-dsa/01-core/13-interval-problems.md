> ✅ **[CORE] — Must-do for SDE-2 interviews.**

# Interval Problems

## 1. Foundation

**Interval problems involve ranges [start, end], covering merging, inserting, scheduling, and finding overlaps. The key technique: sort by start (or end) time, then process linearly.**

💡 **Intuition:** Think of intervals as time blocks on a calendar. Most interval problems boil down to: sort the blocks, then scan left to right making decisions. The sorting step converts a 2D problem (start AND end) into a 1D scan. The decision at each step depends on the pattern: merge overlapping blocks, count simultaneous blocks, or pick the maximum non-overlapping set.

**When to sort by start vs end:**

| Sort By | When | Why | Example |
|---------|------|-----|---------|
| Start time | Merging, inserting, intersecting | You process intervals in the order they begin, merging as you go | Merge Intervals (LC 56) |
| End time | Greedy scheduling (max non-overlapping) | Picking the earliest-ending interval leaves the most room for future intervals | Non-overlapping Intervals (LC 435) |
| Start time, then sweep | Counting overlaps, min resources | Events (start=+1, end=-1) processed in time order | Meeting Rooms II (LC 253) |

⚙️ **Under the Hood, Why Sorting Makes Interval Problems Linear:**

```
Unsorted intervals: [3,6], [1,4], [8,10], [2,5]
  To check all overlaps: compare every pair → O(n²)

Sorted by start: [1,4], [2,5], [3,6], [8,10]
  Now overlaps are ADJACENT. Just compare each interval with the previous one → O(n)
  
  [1,4] and [2,5]: 2 <= 4 → overlap! Merge to [1,5]
  [1,5] and [3,6]: 3 <= 5 → overlap! Merge to [1,6]
  [1,6] and [8,10]: 8 > 6 → no overlap. New interval.
  
  Result: [1,6], [8,10]. Done in O(n) after O(n log n) sort.
```

**Overlap detection cheat sheet** [🔥 Must Know]:

```
Two intervals [a, b] and [c, d] (where a <= c after sorting by start):

Overlap:     a <= c <= b     (c starts before b ends)
             [a=====b]
                [c=====d]

No overlap:  b < c           (gap between them)
             [a=====b]
                        [c=====d]

Touching:    b == c          (depends on problem: sometimes overlap, sometimes not)
             [a=====b]
                     [c=====d]

General overlap check (unsorted): max(a,c) <= min(b,d)
```

> 🔗 **See Also:** [01-dsa/24-sweep-line.md](24-sweep-line.md) for sweep line technique. [01-dsa/08-greedy-backtracking.md](08-greedy-backtracking.md) Pattern 1 for interval scheduling greedy proofs.

---

## 2. Core Patterns

### Pattern 1: Merge Intervals [🔥 Must Do]

**Sort by start. Scan left to right. If the current interval overlaps with the last merged interval, extend the end. Otherwise, start a new merged interval.**

```java
// LC 56: sort by start, merge overlapping
// Time: O(n log n) for sort + O(n) scan = O(n log n)
// Space: O(n) for result (O(log n) for sort if in-place)
public int[][] merge(int[][] intervals) {
    Arrays.sort(intervals, Comparator.comparingInt(a -> a[0]));
    List<int[]> result = new ArrayList<>();
    result.add(intervals[0]);
    for (int i = 1; i < intervals.length; i++) {
        int[] last = result.get(result.size() - 1);
        if (intervals[i][0] <= last[1]) {
            last[1] = Math.max(last[1], intervals[i][1]); // merge: extend end
        } else {
            result.add(intervals[i]); // no overlap: new interval
        }
    }
    return result.toArray(new int[0][]);
}
```

⚠️ **Common Pitfall:** Using `last[1] = intervals[i][1]` instead of `Math.max(last[1], intervals[i][1])`. This fails when the current interval is completely contained within the last one. Example: [1,10] and [2,5]. The merged result should be [1,10], not [1,5].

🎯 **Likely Follow-ups:**
- **Q:** What if intervals are already sorted?
  **A:** Skip the sort. The merge scan is O(n). This matters when intervals arrive in sorted order from a stream.
- **Q:** How would you merge intervals in a stream (online)?
  **A:** Use a TreeMap or balanced BST keyed by start time. On each new interval, find overlapping intervals using floor/ceiling queries, merge them, and insert the result. O(log n + k) per insertion where k is the number of merged intervals.

---

### Pattern 2: Insert Interval [🔥 Must Do]

**Three phases: collect intervals before the new one, merge overlapping intervals with the new one, collect intervals after.**

```java
// LC 57: three phases — before, overlapping, after
// Time: O(n), Space: O(n)
public int[][] insert(int[][] intervals, int[] newInterval) {
    List<int[]> result = new ArrayList<>();
    int i = 0, n = intervals.length;
    
    // Phase 1: all intervals ending before newInterval starts
    while (i < n && intervals[i][1] < newInterval[0]) result.add(intervals[i++]);
    
    // Phase 2: all intervals overlapping with newInterval — merge
    while (i < n && intervals[i][0] <= newInterval[1]) {
        newInterval[0] = Math.min(newInterval[0], intervals[i][0]);
        newInterval[1] = Math.max(newInterval[1], intervals[i][1]);
        i++;
    }
    result.add(newInterval);
    
    // Phase 3: all intervals starting after newInterval ends
    while (i < n) result.add(intervals[i++]);
    
    return result.toArray(new int[0][]);
}
```

💡 **Intuition:** Think of sliding a new block into a sorted row of blocks. Everything to the left that doesn't touch it stays. Everything that overlaps gets absorbed into the new block. Everything to the right stays.

---

### Pattern 3: Max Non-Overlapping Intervals (Greedy) [🔥 Must Know]

**Sort by END time. Greedily pick the interval that ends earliest. Skip any interval that overlaps with the last picked one.**

💡 **Intuition:** Picking the earliest-ending interval is optimal because it "uses up" the least amount of the timeline, leaving the most room for future intervals. This is the classic activity selection problem.

```java
// LC 435: Minimum number of intervals to REMOVE for non-overlapping
// Equivalent: find max non-overlapping set, remove the rest
// Time: O(n log n), Space: O(1)
public int eraseOverlapIntervals(int[][] intervals) {
    Arrays.sort(intervals, Comparator.comparingInt(a -> a[1])); // sort by END
    int count = 1, end = intervals[0][1]; // pick first (earliest end)
    for (int i = 1; i < intervals.length; i++) {
        if (intervals[i][0] >= end) { // no overlap with last picked
            count++;
            end = intervals[i][1];
        }
        // else: skip (overlaps with last picked)
    }
    return intervals.length - count; // remove = total - kept
}
```

⚙️ **Under the Hood, Why Sort by End, Not Start:**

```
Intervals: [1,100], [2,3], [4,5], [6,7]

Sort by START: [1,100], [2,3], [4,5], [6,7]
  Greedy picks [1,100] first → blocks everything else → only 1 interval kept

Sort by END: [2,3], [4,5], [6,7], [1,100]
  Greedy picks [2,3] → then [4,5] → then [6,7] → 3 intervals kept (optimal!)

Sorting by end ensures we never "waste" timeline space with a long interval
when shorter ones could fit.
```

🎯 **Likely Follow-ups:**
- **Q:** How do you prove the greedy approach is optimal?
  **A:** Exchange argument. Assume an optimal solution that doesn't pick the earliest-ending interval. Swap it with the earliest-ending one. The new solution is at least as good (the earliest-ending interval frees up at least as much space). By induction, the greedy solution is optimal.
- **Q:** What if intervals have weights and you want maximum total weight?
  **A:** Greedy doesn't work. Use DP: sort by end, for each interval binary search for the latest non-overlapping interval, `dp[i] = max(dp[i-1], weight[i] + dp[j])` where j is the latest non-overlapping. This is the Weighted Job Scheduling problem. Time: O(n log n).

---

### Pattern 4: Meeting Rooms / Count Overlapping (Sweep Line or Heap) [🔥 Must Know]

**Approach 1: Sweep line. Create +1 events at start times and -1 events at end times. Sort and scan.**

```java
// LC 253: Minimum meeting rooms = max simultaneous meetings
// Time: O(n log n), Space: O(n)
public int minMeetingRooms(int[][] intervals) {
    List<int[]> events = new ArrayList<>();
    for (int[] interval : intervals) {
        events.add(new int[]{interval[0], 1});  // meeting starts: +1 room
        events.add(new int[]{interval[1], -1}); // meeting ends: -1 room
    }
    // Sort by time. If same time, process ends (-1) before starts (+1)
    events.sort((a, b) -> a[0] != b[0] ? a[0] - b[0] : a[1] - b[1]);
    
    int rooms = 0, maxRooms = 0;
    for (int[] event : events) {
        rooms += event[1];
        maxRooms = Math.max(maxRooms, rooms);
    }
    return maxRooms;
}
```

**Approach 2: Min-heap of end times.**

```java
// Alternative: min-heap tracks earliest ending meeting
// Time: O(n log n), Space: O(n)
public int minMeetingRooms2(int[][] intervals) {
    Arrays.sort(intervals, Comparator.comparingInt(a -> a[0]));
    PriorityQueue<Integer> heap = new PriorityQueue<>(); // min-heap of end times
    for (int[] interval : intervals) {
        if (!heap.isEmpty() && heap.peek() <= interval[0]) {
            heap.poll(); // reuse room (earliest meeting ended before this one starts)
        }
        heap.offer(interval[1]); // allocate room
    }
    return heap.size(); // rooms still in use = max simultaneous
}
```

💡 **Intuition for heap approach:** Each element in the heap represents an active meeting room. When a new meeting starts, check if the earliest-ending room is free (heap.peek() <= start). If yes, reuse it (poll + offer). If no, allocate a new room (just offer). The heap size at the end equals the max rooms needed.

| Approach | Time | Space | Pros | Cons |
|----------|------|-------|------|------|
| Sweep line | O(n log n) | O(n) | Clean, generalizes to weighted problems | Creates 2n events |
| Min-heap | O(n log n) | O(n) | Intuitive "room allocation" model | Slightly more code |
| Sort starts + ends separately | O(n log n) | O(n) | Simplest code | Less intuitive |

---

### Pattern 5: Interval Intersections (Two Pointers) [🔥 Must Do]

**Given two sorted interval lists, find all intersections using two pointers.**

```java
// LC 986: Interval List Intersections
// Time: O(m + n), Space: O(1) excluding output
public int[][] intervalIntersection(int[][] A, int[][] B) {
    List<int[]> result = new ArrayList<>();
    int i = 0, j = 0;
    while (i < A.length && j < B.length) {
        int lo = Math.max(A[i][0], B[j][0]); // intersection start
        int hi = Math.min(A[i][1], B[j][1]); // intersection end
        if (lo <= hi) result.add(new int[]{lo, hi}); // valid intersection
        
        // Advance the pointer with the earlier end time
        if (A[i][1] < B[j][1]) i++;
        else j++;
    }
    return result.toArray(new int[0][]);
}
```

💡 **Intuition:** Two intervals intersect if and only if `max(start1, start2) <= min(end1, end2)`. After processing, advance the pointer whose interval ends first, because that interval can't intersect with anything else in the other list.

---

### Pattern 6: Weighted Job Scheduling (DP + Binary Search)

**When intervals have weights/profits and you want maximum total weight without overlaps.**

```java
// Sort by end time. dp[i] = max profit considering first i jobs.
// For each job, either skip it or take it (+ best non-overlapping previous job).
// Time: O(n log n), Space: O(n)
public int jobScheduling(int[] startTime, int[] endTime, int[] profit) {
    int n = startTime.length;
    int[][] jobs = new int[n][3];
    for (int i = 0; i < n; i++) jobs[i] = new int[]{startTime[i], endTime[i], profit[i]};
    Arrays.sort(jobs, Comparator.comparingInt(a -> a[1])); // sort by end time
    
    int[] dp = new int[n];
    dp[0] = jobs[0][2];
    for (int i = 1; i < n; i++) {
        int include = jobs[i][2]; // profit of taking this job
        int j = binarySearchLatest(jobs, i); // latest job that ends before this one starts
        if (j != -1) include += dp[j];
        dp[i] = Math.max(dp[i - 1], include); // skip or take
    }
    return dp[n - 1];
}

// Binary search: find latest job ending at or before jobs[i].start
private int binarySearchLatest(int[][] jobs, int i) {
    int lo = 0, hi = i - 1, target = jobs[i][0];
    while (lo <= hi) {
        int mid = lo + (hi - lo) / 2;
        if (jobs[mid][1] <= target) lo = mid + 1;
        else hi = mid - 1;
    }
    return hi; // -1 if no such job exists
}
```

🎯 **Likely Follow-ups:**
- **Q:** What is the difference between this and the unweighted version?
  **A:** Unweighted (activity selection) uses greedy because all intervals have equal value, so picking the most intervals is optimal. Weighted requires DP because a single high-value interval might be worth more than multiple low-value ones.
- **Q:** Can this be solved with a greedy approach?
  **A:** No. Greedy fails because a locally optimal choice (pick the highest-profit job) might block multiple jobs whose combined profit is higher.

---

## 3. Complexity Summary

| Pattern | Time | Space | Key Technique |
|---------|------|-------|---------------|
| Merge Intervals | O(n log n) | O(n) | Sort by start, extend end |
| Insert Interval | O(n) | O(n) | Three-phase scan |
| Max Non-Overlapping | O(n log n) | O(1) | Sort by end, greedy |
| Meeting Rooms (count) | O(n log n) | O(n) | Sweep line or min-heap |
| Interval Intersections | O(m+n) | O(1) | Two pointers, advance earlier end |
| Weighted Job Scheduling | O(n log n) | O(n) | Sort by end, DP + binary search |

---

## 4. Revision Checklist

- [ ] Merge: sort by start, extend `last[1] = max(last[1], curr[1])` if overlap
- [ ] Insert: three phases (before, merge overlapping, after)
- [ ] Max non-overlapping: sort by END time, greedy pick earliest-ending
- [ ] Meeting rooms: sweep line (+1 at start, -1 at end) or min-heap of end times
- [ ] Interval intersection: `max(start1, start2) <= min(end1, end2)` means overlap
- [ ] Two sorted interval lists: two pointers, advance the one with earlier end
- [ ] Weighted scheduling: sort by end, DP with binary search for latest non-overlapping
- [ ] Overlap check: `max(a.start, b.start) <= min(a.end, b.end)`
- [ ] Greedy proof: exchange argument (earliest-ending frees most space)

**Top 5 must-solve:**
1. Merge Intervals (LC 56) [Medium] - Sort by start + merge overlapping
2. Non-overlapping Intervals (LC 435) [Medium] - Sort by end + greedy
3. Meeting Rooms II (LC 253) [Medium] - Sweep line or min-heap
4. Interval List Intersections (LC 986) [Medium] - Two pointers on sorted lists
5. Maximum Profit in Job Scheduling (LC 1235) [Hard] - DP + binary search

> 🔗 **See Also:** [01-dsa/24-sweep-line.md](24-sweep-line.md) for sweep line deep dive. [01-dsa/08-greedy-backtracking.md](08-greedy-backtracking.md) Pattern 1 for interval scheduling greedy proofs. [01-dsa/07-dynamic-programming.md](07-dynamic-programming.md) for DP fundamentals used in weighted scheduling.
