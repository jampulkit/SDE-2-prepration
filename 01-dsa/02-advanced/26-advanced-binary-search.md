> ⚠️ **[OPTIONAL] — Rarely asked at SDE-2 interviews. Skip unless you've mastered files 00-14.**

# Advanced Binary Search Patterns

## 1. Foundation

**Advanced binary search goes beyond searching sorted arrays — it includes searching on floating-point values, partition-based median finding, and ternary search for unimodal functions.**

## 2. Core Patterns

### Median of Two Sorted Arrays [🔥 Must Do]

```java
// LC 4: O(log(min(m,n))) — binary search on partition position
public double findMedianSortedArrays(int[] nums1, int[] nums2) {
    if (nums1.length > nums2.length) return findMedianSortedArrays(nums2, nums1);
    int m = nums1.length, n = nums2.length;
    int lo = 0, hi = m;
    
    while (lo <= hi) {
        int i = (lo + hi) / 2;       // partition in nums1
        int j = (m + n + 1) / 2 - i; // partition in nums2
        
        int maxLeft1 = (i == 0) ? Integer.MIN_VALUE : nums1[i - 1];
        int minRight1 = (i == m) ? Integer.MAX_VALUE : nums1[i];
        int maxLeft2 = (j == 0) ? Integer.MIN_VALUE : nums2[j - 1];
        int minRight2 = (j == n) ? Integer.MAX_VALUE : nums2[j];
        
        if (maxLeft1 <= minRight2 && maxLeft2 <= minRight1) {
            if ((m + n) % 2 == 0)
                return (Math.max(maxLeft1, maxLeft2) + Math.min(minRight1, minRight2)) / 2.0;
            return Math.max(maxLeft1, maxLeft2);
        } else if (maxLeft1 > minRight2) hi = i - 1;
        else lo = i + 1;
    }
    throw new IllegalArgumentException();
}
```

💡 **Intuition:** We're looking for a partition that splits both arrays into left and right halves such that all left elements ≤ all right elements. Binary search on the partition position in the smaller array. The partition in the larger array is determined by the total half-size.

### Floating-Point Binary Search

```java
// Find square root with precision
double sqrt(double x, double eps) {
    double lo = 0, hi = Math.max(1, x);
    while (hi - lo > eps) {
        double mid = (lo + hi) / 2;
        if (mid * mid < x) lo = mid;
        else hi = mid;
    }
    return (lo + hi) / 2;
}
```

### Find Peak Element (Mountain Array)

```java
// LC 162: O(log n) — gradient-based binary search
public int findPeakElement(int[] nums) {
    int lo = 0, hi = nums.length - 1;
    while (lo < hi) {
        int mid = lo + (hi - lo) / 2;
        if (nums[mid] < nums[mid + 1]) lo = mid + 1; // ascending → peak is right
        else hi = mid; // descending → peak is left (or mid)
    }
    return lo;
}
```

## 3. LeetCode Problem List

| # | Problem | LC # | Pattern | Why Important |
|---|---------|------|---------|---------------|
| 1 | Median of Two Sorted Arrays | 4 | Partition BS | [🔥 Must Do] |
| 2 | Find Peak Element | 162 | Gradient BS | [🔥 Must Do] |
| 3 | Find in Mountain Array | 1095 | Peak + two BS | |
| 4 | Single Element in Sorted Array | 540 | Even/odd index BS | |
| 5 | Find the Duplicate Number | 287 | BS on value range | [🔥 Must Do] |

🎯 **Likely Follow-ups:**
- **Q:** Why is the median of two sorted arrays O(log(min(m,n))) and not O(log(m+n))?
  **A:** We binary search on the partition position in the SMALLER array only. The partition in the larger array is determined by the constraint that both halves must have equal size. Searching the smaller array gives O(log(min(m,n))).
- **Q:** How do you handle floating-point binary search precision?
  **A:** Use `while (hi - lo > 1e-7)` or run a fixed number of iterations (100 iterations gives precision of 2^(-100), which is more than enough). Avoid `while (lo < hi)` since floating-point comparison can loop forever.

---

**Top 5 must-solve:**
1. Median of Two Sorted Arrays (LC 4) [Hard] - Partition binary search on smaller array
2. Find Peak Element (LC 162) [Medium] - Gradient-based binary search
3. Find the Duplicate Number (LC 287) [Medium] - Binary search on value range
4. Single Element in Sorted Array (LC 540) [Medium] - Even/odd index binary search
5. Find in Mountain Array (LC 1095) [Hard] - Find peak + two binary searches

---

## 5. Revision Checklist
- [ ] Median of two sorted arrays: binary search on partition in smaller array, O(log(min(m,n)))
- [ ] Floating-point BS: `while (hi - lo > eps)`, no integer rounding issues
- [ ] Peak element: compare `nums[mid]` with `nums[mid+1]`, go toward ascending side
- [ ] BS on value range: search [1, n] for duplicate number, count elements ≤ mid

> 🔗 **See Also:** [01-dsa/11-sorting-searching.md](11-sorting-searching.md) for basic binary search templates.
