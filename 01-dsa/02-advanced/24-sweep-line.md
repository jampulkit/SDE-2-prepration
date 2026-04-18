> ⚠️ **[OPTIONAL] — Rarely asked at SDE-2 interviews. Skip unless you've mastered files 00-14.**

# Sweep Line Algorithm

## 1. Foundation

**The sweep line technique processes events (start/end of intervals) in sorted order, maintaining a running state. It turns 2D interval problems into 1D event processing.**

💡 **Intuition:** Imagine a timeline where meetings start and end. Instead of checking every minute, you only care about the moments when something CHANGES — a meeting starts or ends. Sort these events by time, process them left to right, and track the current state (number of ongoing meetings).

## 2. Core Patterns

### Meeting Rooms II (Count Overlapping Intervals) [🔥 Must Know]

```java
// LC 253: Minimum number of meeting rooms
// Approach 1: Sweep line with events
public int minMeetingRooms(int[][] intervals) {
    List<int[]> events = new ArrayList<>();
    for (int[] interval : intervals) {
        events.add(new int[]{interval[0], 1});  // start: +1 room needed
        events.add(new int[]{interval[1], -1}); // end: -1 room freed
    }
    events.sort((a, b) -> a[0] != b[0] ? a[0] - b[0] : a[1] - b[1]); // sort by time, ends before starts
    
    int rooms = 0, maxRooms = 0;
    for (int[] event : events) {
        rooms += event[1];
        maxRooms = Math.max(maxRooms, rooms);
    }
    return maxRooms;
}

// Approach 2: Sort starts and ends separately
public int minMeetingRooms2(int[][] intervals) {
    int[] starts = new int[intervals.length], ends = new int[intervals.length];
    for (int i = 0; i < intervals.length; i++) {
        starts[i] = intervals[i][0];
        ends[i] = intervals[i][1];
    }
    Arrays.sort(starts);
    Arrays.sort(ends);
    
    int rooms = 0, endPtr = 0;
    for (int start : starts) {
        if (start < ends[endPtr]) rooms++; // overlap: need new room
        else endPtr++;                      // no overlap: reuse room
    }
    return rooms;
}
```

### The Skyline Problem [🔥 Must Do]

```java
// LC 218: The Skyline Problem
public List<List<Integer>> getSkyline(int[][] buildings) {
    List<int[]> events = new ArrayList<>();
    for (int[] b : buildings) {
        events.add(new int[]{b[0], -b[2]}); // start: negative height (for sorting)
        events.add(new int[]{b[1], b[2]});  // end: positive height
    }
    events.sort((a, b) -> a[0] != b[0] ? a[0] - b[0] : a[1] - b[1]);
    
    TreeMap<Integer, Integer> heights = new TreeMap<>(Collections.reverseOrder());
    heights.put(0, 1); // ground level
    int prevMax = 0;
    List<List<Integer>> result = new ArrayList<>();
    
    for (int[] event : events) {
        if (event[1] < 0) { // building start
            heights.merge(-event[1], 1, Integer::sum);
        } else { // building end
            heights.merge(event[1], -1, Integer::sum);
            if (heights.get(event[1]) == 0) heights.remove(event[1]);
        }
        int currMax = heights.firstKey();
        if (currMax != prevMax) {
            result.add(List.of(event[0], currMax));
            prevMax = currMax;
        }
    }
    return result;
}
```

### Interval Intersection / Union

```java
// LC 986: Interval List Intersections
public int[][] intervalIntersection(int[][] A, int[][] B) {
    List<int[]> result = new ArrayList<>();
    int i = 0, j = 0;
    while (i < A.length && j < B.length) {
        int lo = Math.max(A[i][0], B[j][0]);
        int hi = Math.min(A[i][1], B[j][1]);
        if (lo <= hi) result.add(new int[]{lo, hi});
        if (A[i][1] < B[j][1]) i++; else j++;
    }
    return result.toArray(new int[0][]);
}
```

## 3. LeetCode Problem List

| # | Problem | LC # | Pattern | Why Important |
|---|---------|------|---------|---------------|
| 1 | Meeting Rooms II | 253 | Sweep line / heap | [🔥 Must Do] |
| 2 | The Skyline Problem | 218 | Sweep line + TreeMap | [🔥 Must Do] |
| 3 | Merge Intervals | 56 | Sort + merge | [🔥 Must Do] |
| 4 | Insert Interval | 57 | Three-phase merge | |
| 5 | Non-overlapping Intervals | 435 | Greedy (sort by end) | [🔥 Must Do] |
| 6 | Interval List Intersections | 986 | Two pointers | |
| 7 | My Calendar I/II/III | 729/731/732 | Sweep line / TreeMap | |
| 8 | Employee Free Time | 759 | Merge + sweep | |
| 9 | Minimum Arrows to Burst Balloons | 452 | Greedy intervals | |
| 10 | Car Pooling | 1094 | Sweep line | |

🎯 **Likely Follow-ups:**
- **Q:** What is the difference between sweep line and merge intervals?
  **A:** Merge intervals combines overlapping intervals into one. Sweep line processes events (starts and ends) to answer questions like "how many intervals overlap at any point?" or "what is the maximum height at each x-coordinate?" Sweep line is more general.
- **Q:** How does the Skyline Problem use sweep line?
  **A:** Create events for building starts (add height to active set) and ends (remove height). At each x-coordinate, the answer is the maximum height in the active set. Use a TreeMap (or max-heap with lazy deletion) to track active heights. Output changes when the max height changes.

---

**Top 5 must-solve:**
1. Meeting Rooms II (LC 253) [Medium] - Sweep line or min-heap for max overlap
2. The Skyline Problem (LC 218) [Hard] - Sweep line + TreeMap for max height tracking
3. Non-overlapping Intervals (LC 435) [Medium] - Greedy sort by end
4. Car Pooling (LC 1094) [Medium] - Sweep line with capacity constraint
5. My Calendar III (LC 732) [Hard] - Sweep line for max concurrent bookings

---

## 5. Revision Checklist

- [ ] Sweep line: convert intervals to events (start=+1, end=-1), sort by time, process left to right
- [ ] Meeting rooms: count overlapping intervals = max concurrent events
- [ ] Skyline: events + max-heap (TreeMap) for current max height, output when max changes
- [ ] Merge intervals: sort by start, merge overlapping
- [ ] Interval intersection: two pointers, advance the one that ends first

> 🔗 **See Also:** [01-dsa/08-greedy-backtracking.md](08-greedy-backtracking.md) Pattern 1 for greedy interval scheduling. [01-dsa/09-heap-priority-queue.md](09-heap-priority-queue.md) Pattern 5 for heap-based scheduling.
