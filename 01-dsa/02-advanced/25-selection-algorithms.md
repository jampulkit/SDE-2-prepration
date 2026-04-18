> ⚠️ **[OPTIONAL] — Rarely asked at SDE-2 interviews. Skip unless you've mastered files 00-14.**

# Quickselect & Selection Algorithms

## 1. Foundation

**Quickselect finds the kth smallest/largest element in O(n) average time without sorting the entire array — it's the optimal alternative to heap-based top-K when you only need one element.**

## 2. Core Pattern

### Quickselect [🔥 Must Know]

```java
// LC 215: Kth Largest Element — O(n) average, O(n²) worst
public int findKthLargest(int[] nums, int k) {
    int target = nums.length - k; // kth largest = (n-k)th smallest
    return quickselect(nums, 0, nums.length - 1, target);
}

private int quickselect(int[] nums, int lo, int hi, int target) {
    int pivot = partition(nums, lo, hi);
    if (pivot == target) return nums[pivot];
    if (pivot < target) return quickselect(nums, pivot + 1, hi, target);
    return quickselect(nums, lo, pivot - 1, target);
}

private int partition(int[] nums, int lo, int hi) {
    int pivotIdx = lo + new Random().nextInt(hi - lo + 1); // random pivot
    swap(nums, pivotIdx, hi);
    int pivot = nums[hi], i = lo;
    for (int j = lo; j < hi; j++) {
        if (nums[j] < pivot) swap(nums, i++, j);
    }
    swap(nums, i, hi);
    return i;
}
```

| Approach | Time (avg) | Time (worst) | Space | Notes |
|----------|-----------|-------------|-------|-------|
| Sort + index | O(n log n) | O(n log n) | O(1) | Simple but slow |
| Min-heap of size k | O(n log k) | O(n log k) | O(k) | Good when k << n |
| Quickselect | O(n) | O(n²) | O(1) | Fastest average, random pivot |
| Median of medians | O(n) | O(n) | O(1) | Guaranteed linear (complex) |

**Random pivot** makes worst case extremely unlikely (probability of O(n²) is negligible).

🎯 **Likely Follow-ups:**
- **Q:** When should you use quickselect vs a heap for kth largest?
  **A:** Quickselect for one-shot queries on a static array (O(n) average). Heap of size k for streaming data or when k is much smaller than n (O(n log k)). If you need the top-k elements (not just the kth), heap returns them all.
- **Q:** How do you handle duplicates in quickselect?
  **A:** Use 3-way partition (Dutch National Flag): elements < pivot, elements = pivot, elements > pivot. If the kth element falls in the "equal" partition, return the pivot immediately. This also improves performance on arrays with many duplicates.

---

**Top 5 must-solve:**
1. Kth Largest Element in an Array (LC 215) [Medium] - Quickselect with random pivot
2. Top K Frequent Elements (LC 347) [Medium] - Bucket sort or min-heap of size k
3. K Closest Points to Origin (LC 973) [Medium] - Quickselect on distance
4. Wiggle Sort II (LC 324) [Medium] - Quickselect for median + 3-way partition
5. Find Median from Data Stream (LC 295) [Hard] - Two heaps (not quickselect, but related)

---

## 4. Revision Checklist
- [ ] Quickselect: partition like quicksort, but only recurse into ONE half. O(n) average.
- [ ] Random pivot prevents worst case. Median of medians guarantees O(n) but complex.
- [ ] kth largest = (n-k)th smallest in 0-indexed.
- [ ] Use heap when k is small and data is streaming. Use quickselect for one-shot queries.

> 🔗 **See Also:** [01-dsa/09-heap-priority-queue.md](09-heap-priority-queue.md) for heap-based top-K. [01-dsa/11-sorting-searching.md](11-sorting-searching.md) for quicksort partition.
