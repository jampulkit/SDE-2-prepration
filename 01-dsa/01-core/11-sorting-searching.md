> ✅ **[CORE] — Must-do for SDE-2 interviews.**

# Sorting & Searching

## 1. Foundation

### Sorting Algorithms

**Sorting is the most fundamental algorithmic operation — it enables binary search, simplifies duplicate detection, and is a preprocessing step for countless problems. Knowing which algorithm Java uses and why is a common interview question.**

Interviewers test whether you understand trade-offs (stability, in-place, worst case). Java's built-in sort uses different algorithms depending on the type — knowing which and why matters.

💡 **Intuition — Why So Many Sorting Algorithms?** No single sorting algorithm is best in all situations. Merge sort guarantees O(n log n) but needs O(n) extra space. Quicksort is fastest in practice (cache-friendly) but has O(n²) worst case. Counting sort is O(n) but only works for small integer ranges. The "best" algorithm depends on your constraints.

**Sorting algorithms comparison** [🔥 Must Know]:

| Algorithm | Best | Average | Worst | Space | Stable | In-Place | Notes |
|-----------|------|---------|-------|-------|--------|----------|-------|
| Bubble Sort | O(n) | O(n²) | O(n²) | O(1) | Yes | Yes | Never use. Educational only. |
| Selection Sort | O(n²) | O(n²) | O(n²) | O(1) | No | Yes | Never use. |
| Insertion Sort | O(n) | O(n²) | O(n²) | O(1) | Yes | Yes | Good for small/nearly sorted arrays. Used inside TimSort. |
| Merge Sort | O(n log n) | O(n log n) | O(n log n) | O(n) | Yes | No | Guaranteed O(n log n). Best for linked lists. |
| Quick Sort | O(n log n) | O(n log n) | O(n²) | O(log n) | No | Yes | Fastest in practice (cache-friendly). |
| Heap Sort | O(n log n) | O(n log n) | O(n log n) | O(1) | No | Yes | Guaranteed O(n log n), in-place. Poor cache performance. |
| Counting Sort | O(n+k) | O(n+k) | O(n+k) | O(k) | Yes | No | k = range of values. Non-comparison. |
| Radix Sort | O(d(n+k)) | O(d(n+k)) | O(d(n+k)) | O(n+k) | Yes | No | d = digits. Non-comparison. |
| Bucket Sort | O(n+k) | O(n+k) | O(n²) | O(n+k) | Yes | No | Uniform distribution. Non-comparison. |

**Java's built-in sorting** [🔥 Must Know]:

| Method | Algorithm | Time (worst) | Stable | Used For |
|--------|-----------|-------------|--------|----------|
| `Arrays.sort(int[])` | Dual-Pivot Quicksort | O(n²) | No | Primitives |
| `Arrays.sort(Object[])` | TimSort | O(n log n) | Yes | Objects |
| `Collections.sort()` | TimSort | O(n log n) | Yes | Lists |

⚙️ **Under the Hood — Why Different Algorithms for Primitives vs Objects?**
- **Primitives** don't have identity — two `int` values of 5 are indistinguishable. Stability doesn't matter. Quicksort is faster in practice due to cache locality (elements are contiguous in memory).
- **Objects** have identity — two `Person` objects with the same name might be different objects. Stability matters (equal elements maintain relative order). TimSort guarantees stability and is adaptive (O(n) for nearly sorted data).

⚙️ **Under the Hood — TimSort:**
TimSort is a hybrid of merge sort and insertion sort. It:
1. Divides the array into "runs" (naturally sorted subsequences)
2. Extends short runs using insertion sort (efficient for small arrays)
3. Merges runs using a modified merge sort with a merge stack
4. Exploits existing order — nearly sorted arrays are sorted in O(n)

This is why `Collections.sort()` on an already-sorted list is O(n), not O(n log n).

**Merge Sort implementation** (know this — used for linked list sorting and inversion counting):

```java
public void mergeSort(int[] arr, int[] temp, int left, int right) {
    if (left >= right) return;
    int mid = left + (right - left) / 2;
    mergeSort(arr, temp, left, mid);
    mergeSort(arr, temp, mid + 1, right);
    merge(arr, temp, left, mid, right);
}

private void merge(int[] arr, int[] temp, int left, int mid, int right) {
    System.arraycopy(arr, left, temp, left, right - left + 1);
    int i = left, j = mid + 1, k = left;
    while (i <= mid && j <= right) {
        arr[k++] = temp[i] <= temp[j] ? temp[i++] : temp[j++]; // <= for stability
    }
    while (i <= mid) arr[k++] = temp[i++]; // copy remaining left half
    // right half already in place — no need to copy
}
```

**Quick Sort partition (Lomuto scheme):**

```java
private int partition(int[] arr, int low, int high) {
    int pivot = arr[high]; // choose last element as pivot
    int i = low;           // i tracks the boundary of "less than pivot"
    for (int j = low; j < high; j++) {
        if (arr[j] < pivot) {
            swap(arr, i, j); // move smaller element to left partition
            i++;
        }
    }
    swap(arr, i, high); // place pivot in its correct position
    return i;            // pivot's final index
}
```

💡 **Intuition — Quicksort Partition:** The partition divides the array into three regions: elements < pivot, the pivot itself, and elements ≥ pivot. After partition, the pivot is in its final sorted position. Recurse on the two halves.

🎯 **Likely Follow-ups:**
- **Q:** Why is quicksort faster than merge sort in practice despite the same O(n log n) average?
  **A:** Cache locality. Quicksort works in-place on a contiguous array — the CPU cache loads nearby elements automatically. Merge sort copies data to a temporary array, causing cache misses. The constant factor in quicksort is ~2-3x smaller.
- **Q:** How do you avoid quicksort's O(n²) worst case?
  **A:** Use randomized pivot selection (pick a random element, swap with last, then partition). This makes the worst case extremely unlikely. Java's Dual-Pivot Quicksort also uses insertion sort for small subarrays (< 47 elements).
- **Q:** When would you use merge sort over quicksort?
  **A:** (1) When stability is required. (2) For linked lists (no random access needed, merge is natural). (3) When guaranteed O(n log n) worst case is needed. (4) For external sorting (data doesn't fit in memory).

> 🔗 **See Also:** [01-dsa/04-linked-lists.md](04-linked-lists.md) for merge sort on linked lists. [01-dsa/09-heap-priority-queue.md](09-heap-priority-queue.md) for heap sort.

### Binary Search

**Binary search halves the search space at each step, reducing O(n) linear search to O(log n) on sorted data. It's also used on the "answer space" for optimization problems.**

💡 **Intuition:** Binary search is like the number guessing game. "I'm thinking of a number between 1 and 100." You guess 50. "Too high." Now you know it's between 1 and 49. You guess 25. "Too low." Now it's between 26 and 49. Each guess eliminates half the possibilities. After ~7 guesses, you find the number (log₂(100) ≈ 7).

**The two templates you need** [🔥 Must Know]:

**Template 1: Find exact target** — `while (left <= right)`

```java
int binarySearch(int[] nums, int target) {
    int left = 0, right = nums.length - 1;
    while (left <= right) {                    // search space: [left, right]
        int mid = left + (right - left) / 2;   // prevent overflow
        if (nums[mid] == target) return mid;
        else if (nums[mid] < target) left = mid + 1;
        else right = mid - 1;
    }
    return -1; // not found
}
```

**Template 2: Find boundary (leftmost/rightmost)** — `while (left < right)` [🔥 Must Know]

```java
// Lower bound: first index where nums[i] >= target
int lowerBound(int[] nums, int target) {
    int left = 0, right = nums.length; // right = nums.length (not nums.length - 1)
    while (left < right) {
        int mid = left + (right - left) / 2;
        if (nums[mid] < target) left = mid + 1; // too small, search right
        else right = mid;                         // could be the answer, search left
    }
    return left; // first index where nums[i] >= target
}

// Upper bound: first index where nums[i] > target
int upperBound(int[] nums, int target) {
    int left = 0, right = nums.length;
    while (left < right) {
        int mid = left + (right - left) / 2;
        if (nums[mid] <= target) left = mid + 1; // still ≤ target, search right
        else right = mid;
    }
    return left; // first index where nums[i] > target
}
```

⚙️ **Under the Hood — Template 1 vs Template 2:**

```
Template 1: while (left <= right)
  - Search space: [left, right] (inclusive both ends)
  - Terminates when left > right (empty search space)
  - Use for: finding exact target
  - left and right move past mid: left = mid + 1, right = mid - 1

Template 2: while (left < right)
  - Search space: [left, right) (left inclusive, right exclusive)
  - Terminates when left == right (single candidate)
  - Use for: finding boundaries (first/last occurrence, insertion point)
  - right = mid (not mid - 1) because mid could be the answer
```

**Why `left + (right - left) / 2` instead of `(left + right) / 2`:** Prevents integer overflow when `left + right > Integer.MAX_VALUE`. Example: left = 2 billion, right = 2 billion → left + right overflows.

🎯 **Likely Follow-ups:**
- **Q:** How do you decide between Template 1 and Template 2?
  **A:** Template 1 for exact match (return as soon as found). Template 2 for boundary search (need to find the first/last occurrence — can't stop at the first match, must continue searching).
- **Q:** What's the relationship between binary search and two pointers?
  **A:** Binary search is a special case of two pointers where one pointer (mid) is always at the center of the search space, and you eliminate half the space each step.

---

## 2. Core Patterns

### Pattern 1: Standard Binary Search

```java
// LC 704: Binary Search [🔥 Must Do]
public int search(int[] nums, int target) {
    int left = 0, right = nums.length - 1;
    while (left <= right) {
        int mid = left + (right - left) / 2;
        if (nums[mid] == target) return mid;
        else if (nums[mid] < target) left = mid + 1;
        else right = mid - 1;
    }
    return -1;
}
```

---

### Pattern 2: Binary Search on Rotated Array [🔥 Must Know]

**In a rotated sorted array, at least one half is always sorted. Determine which half is sorted, check if the target is in that half, and search accordingly.**

**When to recognize it:** Sorted array that has been rotated. One half is always sorted.

```java
// LC 33: Search in Rotated Sorted Array [🔥 Must Do]
public int search(int[] nums, int target) {
    int left = 0, right = nums.length - 1;
    while (left <= right) {
        int mid = left + (right - left) / 2;
        if (nums[mid] == target) return mid;

        if (nums[left] <= nums[mid]) { // LEFT half is sorted
            if (target >= nums[left] && target < nums[mid]) right = mid - 1; // target in sorted left
            else left = mid + 1; // target in unsorted right
        } else { // RIGHT half is sorted
            if (target > nums[mid] && target <= nums[right]) left = mid + 1; // target in sorted right
            else right = mid - 1; // target in unsorted left
        }
    }
    return -1;
}
```

💡 **Intuition:** At any mid point in a rotated array, one half is perfectly sorted and the other contains the rotation point. Check if the target falls within the sorted half's range. If yes, search there. If no, search the other half.

```
Original: [1, 2, 3, 4, 5, 6, 7]
Rotated:  [4, 5, 6, 7, 1, 2, 3]
                    ↑ mid
          [sorted ] [  sorted  ]
          
If target=2: left half [4,5,6,7] is sorted. 2 not in [4,7] → search right.
If target=5: left half [4,5,6,7] is sorted. 5 in [4,7] → search left.
```

**Find minimum in rotated array (LC 153):**

```java
public int findMin(int[] nums) {
    int left = 0, right = nums.length - 1;
    while (left < right) {
        int mid = left + (right - left) / 2;
        if (nums[mid] > nums[right]) left = mid + 1; // min is in right half
        else right = mid; // min could be mid or in left half
    }
    return nums[left];
}
```

**Edge Cases:**
- ☐ Not rotated (sorted normally) → works correctly (left half always sorted)
- ☐ Rotated by 1 → works correctly
- ☐ Single element → return it
- ☐ Duplicates (LC 81) → worst case O(n) when all elements equal except one

🎯 **Likely Follow-ups:**
- **Q:** What if there are duplicates?
  **A:** When `nums[left] == nums[mid] == nums[right]`, you can't determine which half is sorted. Shrink both ends: `left++; right--`. This makes worst case O(n) but average is still O(log n).

---

### Pattern 3: Binary Search on Answer [🔥 Must Know]

**Instead of searching for a target in an array, search for the optimal answer in a range [min, max]. At each candidate answer, check if it's feasible.**

**When to recognize it:** "Minimum maximum" or "maximum minimum" — optimization problems where you can binary search on the answer and check feasibility.

💡 **Intuition:** Instead of asking "what's the answer?", ask "is X a valid answer?" for different values of X. If you can answer this yes/no question efficiently, and the answers form a monotonic pattern (all yes then all no, or vice versa), you can binary search on X.

```
Example: "What's the minimum eating speed to finish all bananas in h hours?"

Speed:    1  2  3  4  5  6  7  8  9  10
Feasible: N  N  N  Y  Y  Y  Y  Y  Y  Y
                    ↑ first feasible = answer

Binary search finds this boundary in O(log(max_speed)) checks.
Each check takes O(n) to verify → total O(n log R).
```

**Template:**

```java
int left = MIN_POSSIBLE_ANSWER, right = MAX_POSSIBLE_ANSWER;
while (left < right) {
    int mid = left + (right - left) / 2;
    if (isFeasible(mid)) right = mid;   // mid works, try smaller (minimize)
    else left = mid + 1;                 // mid doesn't work, need larger
}
return left; // smallest feasible answer
```

```java
// LC 875: Koko Eating Bananas [🔥 Must Do]
public int minEatingSpeed(int[] piles, int h) {
    int left = 1, right = Arrays.stream(piles).max().getAsInt();
    while (left < right) {
        int mid = left + (right - left) / 2;
        if (canFinish(piles, mid, h)) right = mid; // can finish at this speed, try slower
        else left = mid + 1;                         // too slow, need faster
    }
    return left;
}

private boolean canFinish(int[] piles, int speed, int h) {
    int hours = 0;
    for (int pile : piles) hours += (pile + speed - 1) / speed; // ceil division
    return hours <= h;
}
```

**Dry run:** `piles = [3, 6, 7, 11]`, h = 8

```
left=1, right=11

mid=6: hours = ceil(3/6)+ceil(6/6)+ceil(7/6)+ceil(11/6) = 1+1+2+2 = 6 ≤ 8 → feasible. right=6
mid=3: hours = 1+2+3+4 = 10 > 8 → not feasible. left=4
mid=5: hours = 1+2+2+3 = 8 ≤ 8 → feasible. right=5
mid=4: hours = 1+2+2+3 = 8 ≤ 8 → feasible. right=4
left=4 == right=4 → answer = 4 ✓
```

**Other "binary search on answer" problems:**

| Problem | Search Range | Feasibility Check |
|---------|-------------|-------------------|
| Koko Eating Bananas (LC 875) | [1, max(piles)] | Can finish in h hours at speed mid? |
| Split Array Largest Sum (LC 410) | [max(nums), sum(nums)] | Can split into ≤ m subarrays with max sum ≤ mid? |
| Capacity To Ship (LC 1011) | [max(weights), sum(weights)] | Can ship in d days with capacity mid? |
| Magnetic Force (LC 1552) | [1, max_dist] | Can place balls with min distance ≥ mid? |

🎯 **Likely Follow-ups:**
- **Q:** How do you determine the search range?
  **A:** The minimum possible answer is usually the smallest meaningful value (e.g., 1 for speed, max element for split array). The maximum is the largest meaningful value (e.g., max pile for speed, total sum for split array).
- **Q:** What if you need to maximize instead of minimize?
  **A:** Flip the logic: `if (isFeasible(mid)) left = mid + 1; else right = mid;` and return `left - 1`. Or equivalently, search for the last feasible value.

---

### Pattern 4: Search in 2D Matrix

```java
// LC 74: Search a 2D Matrix [🔥 Must Do]
// Treat the 2D matrix as a 1D sorted array
public boolean searchMatrix(int[][] matrix, int target) {
    int m = matrix.length, n = matrix[0].length;
    int left = 0, right = m * n - 1;
    while (left <= right) {
        int mid = left + (right - left) / 2;
        int val = matrix[mid / n][mid % n]; // convert 1D index to 2D coordinates
        if (val == target) return true;
        else if (val < target) left = mid + 1;
        else right = mid - 1;
    }
    return false;
}

// LC 240: Search a 2D Matrix II [🔥 Must Do]
// Each row and column sorted independently — use staircase search
public boolean searchMatrix(int[][] matrix, int target) {
    int row = 0, col = matrix[0].length - 1; // start from TOP-RIGHT corner
    while (row < matrix.length && col >= 0) {
        if (matrix[row][col] == target) return true;
        else if (matrix[row][col] > target) col--;  // too big, go left
        else row++;                                    // too small, go down
    }
    return false;
}
```

💡 **Intuition — Staircase Search (LC 240):** Starting from the top-right corner, you can always eliminate either a row or a column. If the current value is too big, move left (eliminate the column). If too small, move down (eliminate the row). This gives O(m + n) time.

---

### Pattern 5: Find First/Last Position (Boundary Search)

```java
// LC 34: Find First and Last Position of Element in Sorted Array [🔥 Must Do]
public int[] searchRange(int[] nums, int target) {
    return new int[]{findFirst(nums, target), findLast(nums, target)};
}

private int findFirst(int[] nums, int target) {
    int left = 0, right = nums.length - 1, result = -1;
    while (left <= right) {
        int mid = left + (right - left) / 2;
        if (nums[mid] == target) { result = mid; right = mid - 1; } // found, but keep searching LEFT
        else if (nums[mid] < target) left = mid + 1;
        else right = mid - 1;
    }
    return result;
}

private int findLast(int[] nums, int target) {
    int left = 0, right = nums.length - 1, result = -1;
    while (left <= right) {
        int mid = left + (right - left) / 2;
        if (nums[mid] == target) { result = mid; left = mid + 1; } // found, but keep searching RIGHT
        else if (nums[mid] < target) left = mid + 1;
        else right = mid - 1;
    }
    return result;
}
```

---

### Pattern 6: Merge Sort Applications (Counting During Merge)

**Use the merge step to count relationships between elements from different halves — inversions, reverse pairs, range sums.**

```java
// Count inversions: pairs (i, j) where i < j but nums[i] > nums[j]
int count = 0;

private void mergeCount(int[] arr, int[] temp, int left, int mid, int right) {
    int i = left, j = mid + 1, k = left;
    while (i <= mid && j <= right) {
        if (arr[i] <= arr[j]) {
            temp[k++] = arr[i++];
        } else {
            count += (mid - i + 1); // ALL remaining in left half form inversions with arr[j]
            temp[k++] = arr[j++];
        }
    }
    while (i <= mid) temp[k++] = arr[i++];
    while (j <= right) temp[k++] = arr[j++];
    System.arraycopy(temp, left, arr, left, right - left + 1);
}
```

💡 **Intuition:** During merge, both halves are sorted. When `arr[j] < arr[i]`, ALL elements from `i` to `mid` in the left half are greater than `arr[j]` (because the left half is sorted). So we can count `mid - i + 1` inversions at once, instead of checking each pair individually.


---

## 3. Patterns Summary Table

| # | Pattern | When to Use | Key Idea | Time | Space | Example |
|---|---------|------------|----------|------|-------|---------|
| 1 | Standard binary search | Find target in sorted array | left ≤ right, mid comparison | O(log n) | O(1) | Binary Search (LC 704) |
| 2 | Rotated array | Sorted + rotated | One half always sorted, check target range | O(log n) | O(1) | Search Rotated (LC 33) |
| 3 | Binary search on answer | Min-max optimization | Search answer space, check feasibility | O(n log R) | O(1) | Koko Bananas (LC 875) |
| 4 | 2D matrix search | Sorted matrix | Flatten to 1D or staircase from top-right | O(log(mn)) or O(m+n) | O(1) | Search Matrix (LC 74) |
| 5 | Boundary search | First/last occurrence | Continue searching after finding target | O(log n) | O(1) | First Last Position (LC 34) |
| 6 | Merge sort counting | Count inversions, pairs | Count during merge step | O(n log n) | O(n) | Count Inversions |

**Pattern Selection Flowchart:**

```
Searching problem?
├── Array sorted? → Standard binary search (Template 1 or 2)
│   ├── Find exact target → Template 1: while (left <= right)
│   ├── Find boundary (first/last) → Template 2: while (left < right)
│   └── Array rotated → Identify sorted half, search accordingly
├── 2D matrix sorted? → Flatten to 1D or staircase search
├── Optimization (min-max)? → Binary search on answer + feasibility check
└── Count pairs/inversions? → Merge sort with counting during merge
```

---

## 4. LeetCode Problem List (Must-Solve)

### Easy

| # | Problem Name | LC # | Pattern(s) | Why Important |
|---|-------------|------|-----------|---------------|
| 1 | Binary Search | 704 | Standard | [🔥 Must Do] Template |
| 2 | Search Insert Position | 35 | Lower bound | [🔥 Must Do] Insertion point |
| 3 | First Bad Version | 278 | Boundary | Binary search on predicate |
| 4 | Sqrt(x) | 69 | BS on answer | Integer square root |
| 5 | Valid Perfect Square | 367 | BS on answer | Similar to sqrt |
| 6 | Guess Number Higher or Lower | 374 | Standard | API-based binary search |
| 7 | Merge Sorted Array | 88 | Merge | [🔥 Must Do] Merge in-place from end |
| 8 | Sort an Array | 912 | Merge/Quick sort | Implement sorting |

### Medium

| # | Problem Name | LC # | Pattern(s) | Why Important |
|---|-------------|------|-----------|---------------|
| 1 | Search in Rotated Sorted Array | 33 | Rotated | [🔥 Must Do] Classic rotated search |
| 2 | Find Minimum in Rotated Sorted Array | 153 | Rotated | [🔥 Must Do] Find pivot |
| 3 | Search a 2D Matrix | 74 | 2D search | [🔥 Must Do] Flatten to 1D |
| 4 | Search a 2D Matrix II | 240 | Staircase | [🔥 Must Do] Top-right start |
| 5 | Find First and Last Position | 34 | Boundary | [🔥 Must Do] Two binary searches |
| 6 | Koko Eating Bananas | 875 | BS on answer | [🔥 Must Do] Classic BS on answer |
| 7 | Capacity To Ship Packages | 1011 | BS on answer | [🔥 Must Do] Feasibility check |
| 8 | Split Array Largest Sum | 410 | BS on answer | [🔥 Must Do] Minimize maximum |
| 9 | Find Peak Element | 162 | Modified BS | Gradient-based search |
| 10 | Time Based Key-Value Store | 981 | BS on timestamps | TreeMap or binary search |
| 11 | Sort Colors | 75 | Dutch National Flag | [🔥 Must Do] Three-way partition |
| 12 | Sort List | 148 | Merge sort | Merge sort on linked list |
| 13 | Largest Number | 179 | Custom sort | Custom comparator |
| 14 | H-Index | 274 | Counting sort / BS | Sort + scan |
| 15 | Minimum Number of Days to Make m Bouquets | 1482 | BS on answer | Feasibility check |
| 16 | Single Element in a Sorted Array | 540 | Modified BS | Even/odd index pairing |
| 17 | Search in Rotated Sorted Array II | 81 | Rotated + duplicates | Handle duplicates |
| 18 | Find the Duplicate Number | 287 | Binary search / Floyd's | [🔥 Must Do] BS on value range |
| 19 | Magnetic Force Between Two Balls | 1552 | BS on answer | Maximize minimum distance |
| 20 | Successful Pairs of Spells and Potions | 2300 | Sort + BS | Binary search per query |

### Hard

| # | Problem Name | LC # | Pattern(s) | Why Important |
|---|-------------|------|-----------|---------------|
| 1 | Median of Two Sorted Arrays | 4 | Binary search | [🔥 Must Do] Partition-based BS |
| 2 | Count of Smaller Numbers After Self | 315 | Merge sort | Inversion counting variant |
| 3 | Count of Range Sum | 327 | Merge sort + prefix sum | Range counting |
| 4 | Reverse Pairs | 493 | Merge sort | Modified merge count |
| 5 | Nth Magical Number | 878 | BS + math | LCM-based counting |
| 6 | Find in Mountain Array | 1095 | Three binary searches | Peak + two searches |
| 7 | Kth Smallest Number in Multiplication Table | 668 | BS on answer | Count ≤ mid per row |

---

## 5. Interview Strategy

**Binary search decision tree:**

```
Is the array sorted?
├── YES → Standard binary search or boundary search
├── Rotated → Identify sorted half, search accordingly
└── NO → Can you binary search on the answer?
    ├── "Minimize the maximum" → BS on answer, feasibility = can split with max ≤ mid
    ├── "Maximize the minimum" → BS on answer, feasibility = can place with min ≥ mid
    └── Can you sort first? → Sort + binary search
```

**Communication tips:**

```
You: "The array is sorted, so I'll use binary search. I need the first occurrence,
     so I'll use the boundary template — when I find the target, I continue
     searching left instead of returning immediately."

You: "This is a 'minimize the maximum' problem. I'll binary search on the answer.
     For each candidate answer mid, I check if it's feasible by greedily splitting
     the array. If feasible, I try smaller. If not, I try larger."
```

**Common mistakes:**
- Off-by-one: `left <= right` vs `left < right` — depends on the template
- `mid = (left + right) / 2` overflow — always use `left + (right - left) / 2`
- Infinite loop: not moving `left` or `right` past `mid` (especially `right = mid` without `left < right`)
- Wrong half in rotated array (forgetting `=` in `nums[left] <= nums[mid]`)
- Binary search on answer: wrong bounds (too tight misses answer, too loose wastes time)
- Ceil division: `(a + b - 1) / b` not `a / b + 1` (the latter is wrong when `a % b == 0`)

💥 **What Can Go Wrong in Interviews:**

| Mistake | Impact | Prevention |
|---------|--------|------------|
| Wrong template (≤ vs <) | Infinite loop or wrong answer | Template 1 for exact, Template 2 for boundary |
| Mid overflow | Wrong mid value | Always `left + (right - left) / 2` |
| Wrong half in rotated | Search wrong direction | Draw the array, identify which half is sorted |
| BS on answer: wrong range | Miss the answer | Use widest possible range, narrow with feasibility |
| Forget to handle not-found | Return wrong value | Check if result is valid after binary search |

---

## 6. Edge Cases & Pitfalls

**Binary search edge cases:**
- ☐ Empty array → return -1 or 0
- ☐ Single element → check if it matches
- ☐ Target not in array → return insertion point or -1
- ☐ All elements equal → boundary search still works
- ☐ Duplicates in rotated array → worst case O(n)
- ☐ Integer overflow in mid calculation → use `left + (right - left) / 2`

**Sorting edge cases:**
- ☐ Empty array → already sorted
- ☐ Single element → already sorted
- ☐ Already sorted → O(n) for TimSort, O(n²) for naive quicksort
- ☐ Reverse sorted → worst case for some algorithms
- ☐ All elements equal → should be O(n) for good implementations

**Java-specific pitfalls:**

```java
// PITFALL 1: Arrays.sort stability
int[] arr = {3, 1, 2};
Arrays.sort(arr); // Dual-Pivot Quicksort — NOT stable for primitives

Integer[] arr = {3, 1, 2};
Arrays.sort(arr); // TimSort — stable for objects

// PITFALL 2: Custom comparator for arrays
// Can't use Arrays.sort(int[], Comparator) — primitives don't support Comparator
// Must use Integer[] or convert to List<Integer>

// PITFALL 3: Collections.binarySearch requires sorted list
List<Integer> list = Arrays.asList(3, 1, 2);
Collections.binarySearch(list, 2); // WRONG — list not sorted! Undefined behavior.

// PITFALL 4: Comparator overflow (again)
Arrays.sort(intervals, (a, b) -> a[0] - b[0]); // OVERFLOW for large values
Arrays.sort(intervals, Comparator.comparingInt(a -> a[0])); // SAFE
```

---

## 7. Connections to Other Topics

| This Pattern | Connects To | How |
|-------------|-------------|-----|
| Binary search | [01-dsa/02-two-pointers-sliding-window.md](02-two-pointers-sliding-window.md) | BS is a special case of two pointers (halving search space) |
| BS on answer | [01-dsa/08-greedy-backtracking.md](08-greedy-backtracking.md) | Feasibility check is often a greedy algorithm |
| Merge sort | [01-dsa/04-linked-lists.md](04-linked-lists.md) | Optimal sort for linked lists (no random access needed) |
| Counting sort | [01-dsa/01-arrays-strings-hashing.md](01-arrays-strings-hashing.md) | Frequency-based sorting, bucket sort for top-k |
| Quick sort partition | [01-dsa/09-heap-priority-queue.md](09-heap-priority-queue.md) | Quickselect uses partition for kth element |
| Merge sort counting | [01-dsa/07-dynamic-programming.md](07-dynamic-programming.md) | Divide and conquer with counting |
| TimSort | [05-java/02-collections-internals.md](../05-java/02-collections-internals.md) | Java's sorting implementation details |
| Binary search | [01-dsa/05-trees.md](05-trees.md) | BST search is binary search on a tree structure |
| Sorting | [02-system-design/01-fundamentals.md](../02-system-design/01-fundamentals.md) | External sort for large datasets in system design |

---

## 8. Revision Checklist

**Sorting:**
- [ ] Java primitives: Dual-Pivot Quicksort (NOT stable, O(n²) worst)
- [ ] Java objects: TimSort (stable, O(n log n) worst, O(n) for nearly sorted)
- [ ] Merge sort: O(n log n), stable, O(n) space — best for linked lists and guaranteed worst case
- [ ] Quick sort: O(n log n) average, O(n²) worst, in-place, cache-friendly — fastest in practice
- [ ] Counting sort: O(n+k), non-comparison, for small integer range k
- [ ] Heap sort: O(n log n), in-place, not stable — rarely used directly

**Binary search templates:**
- [ ] Template 1 (exact match): `while (left <= right)`, return mid when found, `left = mid+1` / `right = mid-1`
- [ ] Template 2 (boundary): `while (left < right)`, `right = mid` (could be answer), `left = mid+1`
- [ ] Lower bound: first index where `nums[i] >= target`
- [ ] Upper bound: first index where `nums[i] > target`
- [ ] BS on answer: `[min, max]` range, check `isFeasible(mid)`, minimize or maximize

**Key formulas:**
- [ ] `mid = left + (right - left) / 2` — prevent overflow
- [ ] Ceil division: `(a + b - 1) / b` (not `a / b + 1`)
- [ ] 2D → 1D: `row = idx / cols`, `col = idx % cols`
- [ ] 1D → 2D: `idx = row * cols + col`

**Critical details:**
- [ ] Template 1: search space `[left, right]` inclusive. Template 2: `[left, right)` half-open.
- [ ] Rotated array: `nums[left] <= nums[mid]` means left half is sorted (include `=` for single element)
- [ ] BS on answer: feasibility check is usually O(n) greedy scan
- [ ] Staircase search (LC 240): start from top-right, O(m+n)
- [ ] Merge sort counting: when `arr[j] < arr[i]`, count `mid - i + 1` inversions at once
- [ ] Use `Integer.compare` or `Comparator.comparingInt` for safe comparators

**Top 10 must-solve:**
1. Binary Search (LC 704) [Easy] — Template 1
2. Search in Rotated Sorted Array (LC 33) [Medium] — Rotated search
3. Find First and Last Position (LC 34) [Medium] — Boundary search
4. Koko Eating Bananas (LC 875) [Medium] — BS on answer
5. Search a 2D Matrix (LC 74) [Medium] — Flatten to 1D
6. Find Minimum in Rotated Array (LC 153) [Medium] — Find pivot
7. Median of Two Sorted Arrays (LC 4) [Hard] — Hardest BS problem
8. Split Array Largest Sum (LC 410) [Hard] — Minimize maximum
9. Find the Duplicate Number (LC 287) [Medium] — BS on value range
10. Capacity To Ship Packages (LC 1011) [Medium] — BS on answer

---

## 📋 Suggested New Documents

### 1. Advanced Binary Search Patterns
- **Placement**: `01-dsa/12-advanced-binary-search.md`
- **Why needed**: Median of Two Sorted Arrays (LC 4), binary search on floating point, ternary search for unimodal functions, and fractional binary search are advanced patterns that deserve dedicated coverage beyond the basics here.
- **Key subtopics**: Partition-based median of two sorted arrays, floating-point binary search, ternary search, interactive binary search problems, binary search on trees (BST operations)
