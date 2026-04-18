> ✅ **[CORE] — Must-do for SDE-2 interviews.**

# Two Pointers & Sliding Window

## 1. Foundation

### Two Pointers

**Two pointers is a technique where you use two index variables to scan an array from different positions or directions, eliminating the need for nested loops and turning O(n²) into O(n).**

Many array/string problems have an O(n²) brute force that checks all pairs. Two pointers reduce this to O(n) by exploiting structure — usually sorted order or some monotonic property — to eliminate impossible pairs without checking them.

💡 **Intuition:** Imagine you're looking for two books on a sorted shelf whose combined page count equals 500. Brute force: pick every pair of books and add their pages. Smart way: put one finger on the thinnest book (left) and one on the thickest (right). If the sum is too small, move left finger right (pick a thicker book). If too large, move right finger left (pick a thinner book). You never need to check all pairs because the sorted order tells you which direction to move.

**Core idea:** Instead of two nested loops (i from 0→n, j from i+1→n), maintain two pointers that move toward each other (or in the same direction) based on a condition. Each pointer moves at most n times → O(n) total.

**Three flavors of two pointers:**

| Flavor | Pointer Movement | When to Use | Example |
|--------|-----------------|-------------|---------|
| Opposite direction | left→ ←right | Sorted array, palindrome check, pair sum | Two Sum II, Container With Most Water |
| Same direction (fast/slow) | slow→ fast→ | Cycle detection, remove duplicates, partition | Remove Duplicates, Linked List Cycle |
| Same direction (sliding window) | left→ right→ | Subarray/substring with constraint | Min Window Substring, Longest Substring |

**When two pointers work:**
- Input is sorted (or can be sorted without losing information)
- You need to find pairs/triplets satisfying a condition
- You need to partition or rearrange elements in-place
- There's a monotonic relationship: moving one pointer in a direction always increases/decreases some quantity

**When two pointers DON'T work:**
- You need indices from the original (unsorted) array (use HashMap instead — see Two Sum LC 1)
- No monotonic property to exploit
- Problem requires checking all subarrays of all sizes without a shrinkable constraint

⚙️ **Under the Hood — Why Two Pointers is O(n), Not O(n²):**

```
Brute force (all pairs):
  for i = 0 to n:
    for j = i+1 to n:     ← n*(n-1)/2 iterations = O(n²)
      check(i, j)

Two pointers:
  left = 0, right = n-1
  while left < right:      ← at most n iterations total
    if condition:
      left++               ← left moves right at most n times
    else:
      right--              ← right moves left at most n times

Total pointer movements: at most 2n = O(n)
```

The key insight: each pointer moves in only one direction and never backtracks. This is what makes it linear.

🎯 **Likely Follow-ups:**
- **Q:** Can two pointers work on unsorted arrays?
  **A:** Yes, for same-direction patterns (fast/slow for partitioning, sliding window). But opposite-direction pair-finding requires sorted order or a monotonic property. If you need original indices, use a HashMap instead.
- **Q:** How do you prove two pointers doesn't miss valid pairs?
  **A:** By contradiction. Assume there's a valid pair (i, j) that we skip. At some point, left ≤ i and right ≥ j. If sum < target, we move left right — but since the array is sorted, all pairs with the current left are too small, so skipping them is safe. Same logic for moving right left.

> 🔗 **See Also:** [01-dsa/01-arrays-strings-hashing.md](01-arrays-strings-hashing.md) for HashMap-based pair finding when indices matter. [01-dsa/04-linked-lists.md](04-linked-lists.md) for fast/slow pointer cycle detection.

### Sliding Window

**A sliding window is a contiguous subarray/substring that you expand and shrink efficiently — instead of recomputing from scratch for every position, you add one element and remove one, turning O(n×k) into O(n).**

A sliding window is a specialized two-pointer technique for problems about contiguous subarrays or substrings. Instead of recomputing from scratch for every subarray, you "slide" a window by adding one element on the right and removing one on the left.

💡 **Intuition:** Imagine you're looking through a physical window on a train. As the train moves forward, new scenery appears on the right side and old scenery disappears on the left. You don't need to look at the entire landscape again — you just note what's new and what's gone. That's exactly how a sliding window processes data.

**Two types:**

| Type | Window Size | How It Works | Example |
|------|------------|--------------|---------|
| Fixed-size | Given (k) | Window always has exactly k elements. Slide right, add new, remove leftmost. | Max sum subarray of size k |
| Variable-size | Dynamic | Expand right until constraint violated, then shrink from left until valid again. | Longest substring without repeating chars |

**The variable-size window template is the most important pattern in this topic.** [🔥 Must Know]

**Why sliding window is O(n):** Each element is added to the window at most once (when right moves) and removed at most once (when left moves). Total operations: at most 2n → O(n).

```
Visualization of sliding window movement:

Array: [2, 1, 5, 1, 3, 2]    Window size k=3

Step 1: [2, 1, 5] 1, 3, 2    sum=8
Step 2:  2 [1, 5, 1] 3, 2    sum=8-2+1=7  (removed 2, added 1)
Step 3:  2, 1 [5, 1, 3] 2    sum=7-1+3=9  (removed 1, added 3)
Step 4:  2, 1, 5 [1, 3, 2]   sum=9-5+2=6  (removed 5, added 2)

Each step: O(1) work. Total: O(n).
Without sliding window: recompute sum for each window = O(n×k).
```

**Java data structures commonly used with sliding window:**
- `int[]` frequency array — when characters are lowercase English letters (26 slots)
- `HashMap<Character, Integer>` — when character set is large or unknown
- `Deque<Integer>` (monotonic deque) — for sliding window min/max problems
- Running sum/product variable — for numeric windows

⚙️ **Under the Hood — When Sliding Window Breaks:**
Sliding window relies on a monotonic property: expanding the window makes the constraint "worse" (or at least not better), and shrinking makes it "better." This is why:
- It works for sum of positive numbers (adding increases sum, removing decreases it)
- It works for count of distinct characters (adding can only increase count, removing can decrease it)
- It FAILS for sum with negative numbers (adding a negative number decreases the sum — shrinking from left might also decrease it, breaking the monotonic assumption)
- It FAILS for product when zeros are involved (multiplying by zero resets everything)

For problems where the monotonic property doesn't hold, use prefix sum + HashMap or prefix sum + monotonic deque instead.

> 🔗 **See Also:** [01-dsa/01-arrays-strings-hashing.md](01-arrays-strings-hashing.md) Pattern 4 (Prefix Sum + HashMap) for subarray sum problems with negative numbers.


---

## 2. Core Patterns

### Pattern 1: Opposite-Direction Two Pointers (Sorted Array) [🔥 Must Know]

**Place one pointer at the start and one at the end of a sorted array, then move them toward each other based on whether the current sum is too small or too large.**

**When to recognize it:** Array is sorted (or you can sort it). Problem asks for a pair with a target sum, or to maximize/minimize some function of two elements.

**Approach:**
1. Sort the array (if not already sorted)
2. Place `left` at start, `right` at end
3. If `sum < target` → move `left` right (increase sum)
4. If `sum > target` → move `right` left (decrease sum)
5. If `sum == target` → found it

**Why it works:** In a sorted array, moving `left` right can only increase the sum, and moving `right` left can only decrease it. This monotonic property guarantees we don't miss any valid pair.

```
Proof by elimination:

Sorted array: [1, 3, 5, 7, 9, 11]   target = 12

left=0(1), right=5(11): sum=12 ✓ Found!

But what if target=10?
left=0(1), right=5(11): sum=12 > 10 → right-- (11 is too big for ANY left pointer)
left=0(1), right=4(9):  sum=10 ✓ Found!

Key insight: when sum > target, we know nums[right] + nums[ANY left >= current left]
is also > target. So we can safely eliminate nums[right] from consideration.
```

**Java code template:**

```java
// Two Sum II — Input Array Is Sorted (LC 167)
public int[] twoSum(int[] numbers, int target) {
    int left = 0, right = numbers.length - 1;
    while (left < right) {
        int sum = numbers[left] + numbers[right];
        if (sum == target) return new int[]{left + 1, right + 1}; // 1-indexed
        else if (sum < target) left++;   // need larger sum → move left right
        else right--;                     // need smaller sum → move right left
    }
    return new int[]{}; // no solution (shouldn't happen per problem constraints)
}
```

**Variations:**
- **3Sum (LC 15):** Fix one element, two-pointer on the rest. Skip duplicates.
- **3Sum Closest (LC 16):** Same structure, track closest sum instead of exact match.
- **4Sum (LC 18):** Fix two elements, two-pointer on the rest. Generalized k-sum.
- **Container With Most Water (LC 11):** Move the pointer with the shorter height (greedy — moving the taller one can never increase area).

**Example walkthrough — LC 11: Container With Most Water** [🔥 Must Do]

> Given heights `[1,8,6,2,5,4,8,3,7]`, find two lines that form a container holding the most water.

```java
public int maxArea(int[] height) {
    int left = 0, right = height.length - 1;
    int maxWater = 0;
    while (left < right) {
        int water = Math.min(height[left], height[right]) * (right - left);
        maxWater = Math.max(maxWater, water);
        // Move the shorter line — moving the taller one can NEVER increase area
        // because width decreases and height is still limited by the shorter line
        if (height[left] < height[right]) left++;
        else right--;
    }
    return maxWater;
}
```

💡 **Intuition — Why move the shorter line?**
Area = min(left_height, right_height) × width. When we move any pointer, width decreases by 1. If we move the taller line, the min height can only stay the same or decrease → area definitely decreases. If we move the shorter line, the min height might increase → area might increase. So moving the shorter line is the only move that has a chance of improving the answer.

**Dry run:** `height = [1,8,6,2,5,4,8,3,7]`

```
left=0(1), right=8(7): water=min(1,7)×8=8.   1<7 → left++
left=1(8), right=8(7): water=min(8,7)×7=49.  8>7 → right--
left=1(8), right=7(3): water=min(8,3)×6=18.  8>3 → right--
left=1(8), right=6(8): water=min(8,8)×5=40.  8==8 → either works, left++
left=2(6), right=6(8): water=min(6,8)×4=24.  6<8 → left++
left=3(2), right=6(8): water=min(2,8)×3=6.   2<8 → left++
left=4(5), right=6(8): water=min(5,8)×2=10.  5<8 → left++
left=5(4), right=6(8): water=min(4,8)×1=4.   left++
left=6, right=6: stop.

Max water = 49 (between indices 1 and 8)
```

**Example walkthrough — LC 15: 3Sum** [🔥 Must Do]

> Find all unique triplets in `[-1, 0, 1, 2, -1, -4]` that sum to 0.

```java
public List<List<Integer>> threeSum(int[] nums) {
    Arrays.sort(nums); // [-4, -1, -1, 0, 1, 2]
    List<List<Integer>> result = new ArrayList<>();

    for (int i = 0; i < nums.length - 2; i++) {
        if (i > 0 && nums[i] == nums[i - 1]) continue; // skip duplicate i

        int left = i + 1, right = nums.length - 1;
        while (left < right) {
            int sum = nums[i] + nums[left] + nums[right];
            if (sum < 0) {
                left++;
            } else if (sum > 0) {
                right--;
            } else {
                result.add(List.of(nums[i], nums[left], nums[right]));
                left++;
                right--;
                while (left < right && nums[left] == nums[left - 1]) left++;   // skip dup left
                while (left < right && nums[right] == nums[right + 1]) right--; // skip dup right
            }
        }
    }
    return result;
}
```

**Dry run:** sorted = `[-4, -1, -1, 0, 1, 2]`

```
i=0 (nums[i]=-4): left=1, right=5
  sum = -4 + -1 + 2 = -3 < 0 → left++
  sum = -4 + -1 + 2 = -3 < 0 → left++
  sum = -4 + 0 + 2 = -2 < 0 → left++
  sum = -4 + 1 + 2 = -1 < 0 → left++
  left=5 >= right=5 → stop. No triplet with -4.

i=1 (nums[i]=-1): left=2, right=5
  sum = -1 + -1 + 2 = 0 → FOUND [-1, -1, 2]. left=3, right=4.
  sum = -1 + 0 + 1 = 0 → FOUND [-1, 0, 1]. left=4, right=3. Stop.

i=2: nums[2]==-1 == nums[1]==-1 → skip (duplicate i)

Result: [[-1,-1,2], [-1,0,1]]
```

**Duplicate handling is the hardest part.** Three places to skip:
1. Skip duplicate `i` values → `if (i > 0 && nums[i] == nums[i-1]) continue`
2. Skip duplicate `left` values after finding a triplet → `while (nums[left] == nums[left-1]) left++`
3. Skip duplicate `right` values after finding a triplet → `while (nums[right] == nums[right+1]) right--`

**Complexity:** O(n²) time (sort is O(n log n), dominated by the nested loop), O(1) extra space (ignoring output).

**Edge Cases:**
- ☐ Array with fewer than 3 elements → return empty
- ☐ All zeros `[0,0,0,0]` → one triplet `[0,0,0]`
- ☐ No valid triplet → return empty list
- ☐ All positive or all negative → no triplet sums to 0 (early exit: if `nums[i] > 0`, break)
- ☐ Integer overflow → for 4Sum with large values, cast to `long`

🎯 **Likely Follow-ups:**
- **Q:** Can you solve 3Sum in O(n²) without sorting?
  **A:** You could use a HashSet for the inner loop (fix i, for each j check if `-(nums[i]+nums[j])` is in the set), but handling duplicates becomes much harder. Sorting + two pointers is cleaner and preferred.
- **Q:** How would you generalize to k-Sum?
  **A:** Recursion: k-Sum reduces to (k-1)-Sum by fixing one element. Base case is 2Sum with two pointers. Time: O(n^(k-1)).
- **Q:** What if you need the count of triplets, not the actual triplets?
  **A:** Same approach, but when you find a match, count how many duplicates exist on both sides and multiply. Or use the "count pairs" technique with sorted arrays.

---

### Pattern 2: Same-Direction Two Pointers (Fast/Slow)

**Use a slow pointer to mark where the next valid element should go, and a fast pointer to scan through all elements — this lets you rearrange arrays in-place in O(n) time and O(1) space.**

**When to recognize it:** Remove duplicates in-place, partition array, or detect cycles.

💡 **Intuition:** Think of it like a teacher grading papers. The "fast" hand flips through every paper. The "slow" hand stacks the good ones in a neat pile. The fast hand examines each paper once; the slow hand only moves when it receives a good paper.

**Approach:**
- `slow` marks the position where the next valid element should go
- `fast` scans through all elements
- When `fast` finds a valid element, copy it to `slow` and advance `slow`

**Java code template:**

```java
// LC 26: Remove Duplicates from Sorted Array
public int removeDuplicates(int[] nums) {
    if (nums.length == 0) return 0;
    int slow = 1; // slow points to next write position
    for (int fast = 1; fast < nums.length; fast++) {
        if (nums[fast] != nums[fast - 1]) { // found a new unique element
            nums[slow++] = nums[fast];       // write it at slow position
        }
    }
    return slow; // number of unique elements
}
```

**Dry run:** `nums = [1, 1, 2, 2, 3]`

```
Initial: slow=1, fast=1
fast=1: nums[1]=1 == nums[0]=1 → skip
fast=2: nums[2]=2 != nums[1]=1 → nums[1]=2, slow=2. Array: [1,2,2,2,3]
fast=3: nums[3]=2 == nums[2]=2 → skip
fast=4: nums[4]=3 != nums[3]=2 → nums[2]=3, slow=3. Array: [1,2,3,2,3]
Return 3. First 3 elements: [1,2,3]
```

**Variations:**

| Problem | Condition for "valid" | Notes |
|---------|----------------------|-------|
| Remove Duplicates (LC 26) | `nums[fast] != nums[fast-1]` | Keep first occurrence |
| Remove Duplicates II (LC 80) | `nums[fast] != nums[slow-2]` | Allow at most 2 of each |
| Remove Element (LC 27) | `nums[fast] != val` | Skip target value |
| Move Zeroes (LC 283) | `nums[fast] != 0` | Non-zeros to front, fill rest with 0 |

```java
// LC 283: Move Zeroes — elegant version
public void moveZeroes(int[] nums) {
    int slow = 0;
    for (int fast = 0; fast < nums.length; fast++) {
        if (nums[fast] != 0) {
            // Swap instead of overwrite — handles the "fill zeros" automatically
            int temp = nums[slow];
            nums[slow] = nums[fast];
            nums[fast] = temp;
            slow++;
        }
    }
}
```

**Example walkthrough — LC 75: Sort Colors (Dutch National Flag)** [🔥 Must Do]

> Sort array containing only 0, 1, 2 in-place in one pass.

💡 **Intuition:** Imagine three buckets labeled 0, 1, 2. You scan through the array with a pointer (`mid`). When you see a 0, throw it to the left bucket. When you see a 2, throw it to the right bucket. When you see a 1, leave it in place. The `low` and `high` pointers track where the next 0 and 2 should go.

```java
public void sortColors(int[] nums) {
    int low = 0, mid = 0, high = nums.length - 1;
    // Invariant: 
    //   [0..low-1]     = all 0s
    //   [low..mid-1]   = all 1s
    //   [mid..high]    = unexamined
    //   [high+1..n-1]  = all 2s
    while (mid <= high) {
        if (nums[mid] == 0) {
            swap(nums, low++, mid++); // 0 goes to left region
        } else if (nums[mid] == 1) {
            mid++;                     // 1 stays in middle
        } else { // nums[mid] == 2
            swap(nums, mid, high--);   // 2 goes to right region
            // DON'T advance mid — swapped element needs inspection
        }
    }
}

private void swap(int[] nums, int i, int j) {
    int temp = nums[i]; nums[i] = nums[j]; nums[j] = temp;
}
```

⚙️ **Under the Hood — Why `mid` doesn't advance when swapping with `high`:**
When we swap `nums[mid]` with `nums[high]`, the element that comes from `high` is unexamined — it could be 0, 1, or 2. We need to check it before moving on. But when swapping with `low`, the element from `low` is already examined (it's in the `[low..mid-1]` region, which contains only 1s), so we can safely advance both `low` and `mid`.

**Dry run:** `nums = [2, 0, 2, 1, 1, 0]`

```
low=0, mid=0, high=5: nums=[2,0,2,1,1,0]
  mid=0, nums[0]=2 → swap(0,5), high=4: [0,0,2,1,1,2] mid stays at 0
  mid=0, nums[0]=0 → swap(0,0), low=1, mid=1: [0,0,2,1,1,2]
  mid=1, nums[1]=0 → swap(1,1), low=2, mid=2: [0,0,2,1,1,2]
  mid=2, nums[2]=2 → swap(2,4), high=3: [0,0,1,1,2,2] mid stays at 2
  mid=2, nums[2]=1 → mid=3: [0,0,1,1,2,2]
  mid=3, nums[3]=1 → mid=4: [0,0,1,1,2,2]
  mid=4 > high=3 → stop

Result: [0,0,1,1,2,2] ✓
```

**Edge Cases:**
- ☐ All same color `[1,1,1]` → no swaps needed
- ☐ Already sorted `[0,0,1,1,2,2]` → works correctly
- ☐ Reverse sorted `[2,2,1,1,0,0]` → works correctly
- ☐ Single element → trivially sorted
- ☐ Two elements → at most one swap

🎯 **Likely Follow-ups:**
- **Q:** Can you do this with counting sort instead?
  **A:** Yes — count 0s, 1s, 2s in first pass, then overwrite array in second pass. But that's two passes. The Dutch National Flag does it in one pass, which is the point of the problem.
- **Q:** How does this relate to quicksort?
  **A:** The DNF partition is exactly the three-way partition used in quicksort to handle duplicate pivot elements. It partitions the array into elements < pivot, == pivot, and > pivot in one pass.
- **Q:** Can you generalize to k colors?
  **A:** For k colors, you'd need k-1 pointers or multiple passes. The one-pass approach only works cleanly for 3 values.

> 🔗 **See Also:** [01-dsa/11-sorting-searching.md](11-sorting-searching.md) for quicksort's partition step. [01-dsa/04-linked-lists.md](04-linked-lists.md) for fast/slow pointer cycle detection (Floyd's algorithm).

---

### Pattern 3: Fixed-Size Sliding Window

**When the window size is given (k), build the initial window, then slide it one position at a time — adding the new right element and removing the old left element.**

**When to recognize it:** Problem explicitly gives window size k, or asks about subarrays/substrings of exact length k.

💡 **Intuition:** Think of a magnifying glass of fixed width sliding across a page of text. At each position, you can see exactly k characters. To move to the next position, one character enters on the right and one exits on the left. You don't re-read the entire window — you just update based on what changed.

**Approach:**
1. Build the initial window of size k (process first k elements)
2. Slide: add element at `right`, remove element at `left`, update answer
3. Window always has exactly k elements

**Java code template:**

```java
// Maximum sum subarray of size k
public int maxSumSubarray(int[] nums, int k) {
    // Step 1: Build initial window
    int windowSum = 0;
    for (int i = 0; i < k; i++) windowSum += nums[i];

    // Step 2: Slide the window
    int maxSum = windowSum;
    for (int i = k; i < nums.length; i++) {
        windowSum += nums[i] - nums[i - k]; // add right, remove left
        maxSum = Math.max(maxSum, windowSum);
    }
    return maxSum;
}
```

**Dry run:** `nums = [2, 1, 5, 1, 3, 2]`, `k = 3`

```
Initial window: [2, 1, 5] → sum = 8, maxSum = 8
Slide to [1, 5, 1]: sum = 8 - 2 + 1 = 7, maxSum = 8
Slide to [5, 1, 3]: sum = 7 - 1 + 3 = 9, maxSum = 9
Slide to [1, 3, 2]: sum = 9 - 5 + 2 = 6, maxSum = 9
Answer: 9
```

**Variations:**
- **Max/min sum of size k** → track running sum
- **Average of subarrays of size k** → running sum / k
- **Find all anagrams (LC 438)** → fixed window of pattern length, compare frequency arrays
- **Sliding window maximum (LC 239)** → monotonic deque (see Pattern 6)
- **Permutation in String (LC 567)** → fixed window, frequency match
- **Maximum points from cards (LC 1423)** → inverse: find min sum subarray of size n-k

**Example walkthrough — LC 438: Find All Anagrams in a String** [🔥 Must Do]

> Given `s = "cbaebabacd"`, `p = "abc"`, find all start indices of p's anagrams in s.

```java
public List<Integer> findAnagrams(String s, String p) {
    List<Integer> result = new ArrayList<>();
    if (s.length() < p.length()) return result;

    int[] pCount = new int[26], sCount = new int[26];
    for (char c : p.toCharArray()) pCount[c - 'a']++;

    for (int i = 0; i < s.length(); i++) {
        sCount[s.charAt(i) - 'a']++;                      // add right element
        if (i >= p.length()) {
            sCount[s.charAt(i - p.length()) - 'a']--;      // remove left element
        }
        if (Arrays.equals(sCount, pCount)) {               // check if window is anagram
            result.add(i - p.length() + 1);
        }
    }
    return result;
}
```

**Complexity:** O(n × 26) = O(n) time (comparing two 26-element arrays is O(26) = O(1)), O(1) space.

⚙️ **Under the Hood — Optimized Anagram Check with `matches` Counter:**
Instead of comparing arrays every iteration (26 comparisons), maintain a `matches` counter:

```java
public List<Integer> findAnagrams(String s, String p) {
    List<Integer> result = new ArrayList<>();
    if (s.length() < p.length()) return result;

    int[] pCount = new int[26], sCount = new int[26];
    for (char c : p.toCharArray()) pCount[c - 'a']++;

    int matches = 0;
    // Count initial matches (characters with count 0 in both arrays match)
    for (int i = 0; i < 26; i++) {
        if (pCount[i] == 0) matches++; // both are 0 → they match
    }

    for (int i = 0; i < s.length(); i++) {
        // Add right character
        int idx = s.charAt(i) - 'a';
        sCount[idx]++;
        if (sCount[idx] == pCount[idx]) matches++;
        else if (sCount[idx] == pCount[idx] + 1) matches--; // was matching, now isn't

        // Remove left character (when window exceeds size)
        if (i >= p.length()) {
            idx = s.charAt(i - p.length()) - 'a';
            sCount[idx]--;
            if (sCount[idx] == pCount[idx]) matches++;
            else if (sCount[idx] == pCount[idx] - 1) matches--;
        }

        if (matches == 26) result.add(i - p.length() + 1);
    }
    return result;
}
```

This makes each step O(1) instead of O(26). For large alphabets (Unicode), this optimization matters more.

**Edge Cases:**
- ☐ `s` shorter than `p` → no anagrams possible
- ☐ `s` equals `p` → one anagram at index 0
- ☐ `p` has repeated characters → frequency array handles this naturally
- ☐ No anagrams exist → return empty list

🎯 **Likely Follow-ups:**
- **Q:** What if the character set is Unicode instead of lowercase English?
  **A:** Replace `int[26]` with `HashMap<Character, Integer>`. The `matches` optimization still works — track how many distinct characters have matching counts.
- **Q:** Can you find anagrams in a stream (characters arriving one at a time)?
  **A:** Yes — the sliding window approach naturally handles streaming. Maintain the window state and check after each new character arrives.

---

### Pattern 4: Variable-Size Sliding Window [🔥 Must Know]

**Expand the window by moving right, shrink it by moving left when the constraint is violated — this finds the longest or shortest valid subarray in O(n).**

**When to recognize it:** Problem asks for the longest/shortest subarray or substring satisfying some constraint (e.g., at most k distinct characters, sum ≥ target, no repeating characters).

**This is the single most important pattern in this document.**

💡 **Intuition:** Imagine you're stretching a rubber band across an array. You keep stretching it to the right as long as the constraint holds. The moment it breaks (constraint violated), you release from the left until it's valid again. At each valid state, you measure the band's length and track the maximum (or minimum).

**The template:**

```java
// Generic variable-size sliding window — MEMORIZE THIS
public int slidingWindow(String s /* or int[] nums */) {
    int left = 0, result = 0;
    // state: HashMap, frequency array, running sum, etc.

    for (int right = 0; right < s.length(); right++) {
        // 1. EXPAND: add s.charAt(right) to window state

        // 2. SHRINK: while window is INVALID, remove s.charAt(left) and move left
        while (/* window is invalid */) {
            // remove s.charAt(left) from window state
            left++;
        }

        // 3. UPDATE: window [left..right] is now valid — update result
        result = Math.max(result, right - left + 1); // for "longest"
        // result = Math.min(result, right - left + 1); // for "shortest" (see Pattern 5)
    }
    return result;
}
```

**Critical insight — longest vs shortest:**

| Goal | When to shrink | When to update result |
|------|---------------|----------------------|
| Longest valid window | Shrink when invalid | After shrinking (window is valid) |
| Shortest valid window | Shrink while valid | During shrinking (each valid state) |

**Example walkthrough — LC 3: Longest Substring Without Repeating Characters** [🔥 Must Do]

> Given `s = "abcabcbb"`, find the length of the longest substring without repeating characters.

```java
public int lengthOfLongestSubstring(String s) {
    Map<Character, Integer> lastIndex = new HashMap<>(); // char → last seen index
    int left = 0, maxLen = 0;

    for (int right = 0; right < s.length(); right++) {
        char c = s.charAt(right);
        // If c was seen before AND its last position is within current window
        if (lastIndex.containsKey(c) && lastIndex.get(c) >= left) {
            left = lastIndex.get(c) + 1; // jump left past the duplicate
        }
        lastIndex.put(c, right);
        maxLen = Math.max(maxLen, right - left + 1);
    }
    return maxLen;
}
```

**Why `lastIndex.get(c) >= left` is critical:**

```
s = "abba"

Without the >= left check:
right=0 'a': lastIndex={a:0}, left=0, window="a", len=1
right=1 'b': lastIndex={a:0,b:1}, left=0, window="ab", len=2
right=2 'b': b seen at 1, left=2, lastIndex={a:0,b:2}, window="b", len=1
right=3 'a': a seen at 0, left=1 ← WRONG! left goes BACKWARD from 2 to 1!

With the >= left check:
right=3 'a': a seen at 0, but 0 < left(2) → a is outside window, ignore.
             left stays at 2, window="ba", len=2 ✓
```

**Dry run:** `s = "abcabcbb"`

| right | char | lastIndex (after) | left | window | maxLen |
|-------|------|-------------------|------|--------|--------|
| 0 | a | {a:0} | 0 | "a" | 1 |
| 1 | b | {a:0,b:1} | 0 | "ab" | 2 |
| 2 | c | {a:0,b:1,c:2} | 0 | "abc" | 3 |
| 3 | a | {a:3,b:1,c:2} | 1 | "bca" | 3 |
| 4 | b | {a:3,b:4,c:2} | 2 | "cab" | 3 |
| 5 | c | {a:3,b:4,c:5} | 3 | "abc" | 3 |
| 6 | b | {a:3,b:6,c:5} | 5 | "cb" | 3 |
| 7 | b | {a:3,b:7,c:5} | 7 | "b" | 3 |

Answer: 3 ("abc").

**Example walkthrough — LC 424: Longest Repeating Character Replacement** [🔥 Must Do]

> Given `s = "AABABBA"`, `k = 1`, find the length of the longest substring where you can replace at most k characters to make all characters the same.

```java
public int characterReplacement(String s, int k) {
    int[] count = new int[26];
    int left = 0, maxFreq = 0, maxLen = 0;

    for (int right = 0; right < s.length(); right++) {
        count[s.charAt(right) - 'A']++;
        maxFreq = Math.max(maxFreq, count[s.charAt(right) - 'A']);

        // Window is invalid if: (window size) - (most frequent char count) > k
        // This means we need to replace more than k characters
        while ((right - left + 1) - maxFreq > k) {
            count[s.charAt(left) - 'A']--;
            left++;
        }

        maxLen = Math.max(maxLen, right - left + 1);
    }
    return maxLen;
}
```

💡 **Intuition — Window validity condition:**
In a window of size `w`, the most frequent character appears `maxFreq` times. The remaining `w - maxFreq` characters need to be replaced. If `w - maxFreq > k`, we can't make the window all one character with k replacements → invalid.

⚙️ **Under the Hood — Why we don't decrease `maxFreq` when shrinking:**
When we shrink the window, `maxFreq` might become stale (the actual max frequency in the window might be less). But that's OK! A stale `maxFreq` only makes the window appear "more valid" than it is, which means we might not shrink enough. But since we're looking for the LONGEST window, keeping a potentially larger `maxFreq` can only help — it never causes us to miss a longer valid window. This is a subtle but important optimization.

**Edge Cases:**
- ☐ Empty string → return 0
- ☐ All same characters → entire string is the answer
- ☐ k = 0 → find longest run of same character
- ☐ k ≥ string length → entire string (replace everything)
- ☐ Single character → return 1

🎯 **Likely Follow-ups:**
- **Q:** Why is the variable-size window O(n) and not O(n²)?
  **A:** The `right` pointer moves from 0 to n-1 (n steps). The `left` pointer also moves from 0 to at most n-1 (n steps total across all iterations). Each element is added once and removed at most once. Total work: O(2n) = O(n).
- **Q:** What if the problem asks for "exactly k distinct characters" instead of "at most k"?
  **A:** Use the `atMost(k) - atMost(k-1)` trick (see Pattern 8 below). Direct sliding window doesn't work for "exactly k" because shrinking might skip valid windows.
- **Q:** Can you use sliding window when the array has negative numbers?
  **A:** Not for sum-based problems. With negatives, adding an element might decrease the sum, breaking the monotonic property. Use prefix sum + HashMap instead.

---

### Pattern 5: Minimum Window / Shortest Subarray [🔥 Must Know]

**Expand right until the window is valid, then shrink left while it stays valid — recording the answer at each valid state to find the shortest.**

**When to recognize it:** Find the shortest/minimum subarray or substring that satisfies a condition.

**Key difference from "longest" pattern:** In "longest", we shrink only when invalid. In "shortest", we shrink while still valid, recording the answer at each valid state.

```
Longest:  expand → shrink UNTIL valid → record
Shortest: expand → record → shrink WHILE valid → record at each step
```

**Example walkthrough — LC 76: Minimum Window Substring** [🔥 Must Do]

> Given `s = "ADOBECODEBANC"`, `t = "ABC"`, find the minimum window in s that contains all characters of t.

```java
public String minWindow(String s, String t) {
    if (s.length() < t.length()) return "";

    // Count characters needed from t
    Map<Character, Integer> need = new HashMap<>();
    for (char c : t.toCharArray()) need.merge(c, 1, Integer::sum);

    int required = need.size(); // number of UNIQUE chars we need to satisfy
    int formed = 0;             // number of unique chars currently satisfied
    Map<Character, Integer> window = new HashMap<>();

    int left = 0, minLen = Integer.MAX_VALUE, minStart = 0;

    for (int right = 0; right < s.length(); right++) {
        // EXPAND: add right character to window
        char c = s.charAt(right);
        window.merge(c, 1, Integer::sum);

        // Check if this character's requirement is now met
        if (need.containsKey(c) && window.get(c).intValue() == need.get(c).intValue()) {
            formed++;
        }

        // SHRINK: while window is valid, try to minimize
        while (formed == required) {
            // Record current valid window
            if (right - left + 1 < minLen) {
                minLen = right - left + 1;
                minStart = left;
            }

            // Remove left character
            char leftChar = s.charAt(left);
            window.merge(leftChar, -1, Integer::sum);
            if (need.containsKey(leftChar) && window.get(leftChar) < need.get(leftChar)) {
                formed--; // this character is no longer satisfied
            }
            left++;
        }
    }
    return minLen == Integer.MAX_VALUE ? "" : s.substring(minStart, minStart + minLen);
}
```

⚙️ **Under the Hood — Why `formed` counter instead of comparing maps:**
Comparing two HashMaps is O(k) where k = distinct characters in t. The `formed` counter makes the validity check O(1). We only increment `formed` when a character's count in the window EXACTLY reaches the required count, and decrement when it drops below. This avoids rechecking all characters every iteration.

**Dry run:** `s = "ADOBECODEBANC"`, `t = "ABC"`

```
need = {A:1, B:1, C:1}, required = 3

right=0 'A': window={A:1}, formed=1 (A satisfied)
right=1 'D': window={A:1,D:1}, formed=1
right=2 'O': window={A:1,D:1,O:1}, formed=1
right=3 'B': window={A:1,D:1,O:1,B:1}, formed=2 (B satisfied)
right=4 'E': window={...,E:1}, formed=2
right=5 'C': window={...,C:1}, formed=3 ← ALL SATISFIED!
  Shrink: window="ADOBEC" len=6, minLen=6, minStart=0
    Remove 'A': formed=2 → stop shrinking
right=6 'O': formed=2
right=7 'D': formed=2
right=8 'E': formed=2
right=9 'B': formed=2
right=10 'A': window={A:1,...}, formed=3 ← ALL SATISFIED!
  Shrink: window="DOBECODEBA" → too long
    Remove 'D': still valid → "OBECODEBA" len=9
    Remove 'O': still valid → "BECODEBA" len=8
    Remove 'B': formed=2 → stop. Recorded len=8? No, minLen still 6.
    Wait — let me re-trace more carefully...
right=11 'N': formed=2
right=12 'C': window={...,C:1}, formed=3 ← ALL SATISFIED!
  Shrink: window="BANC" len=4, minLen=4, minStart=9 ← NEW MINIMUM!
    Remove 'B': formed=2 → stop

Answer: "BANC" (length 4, starting at index 9)
```

**Complexity:** O(n) time (each character added/removed at most once), O(k) space where k = distinct characters in t.

⚠️ **Common Pitfall — Using `.intValue()` for Integer comparison:**

```java
// WRONG — may fail for counts > 127 due to Integer caching
if (window.get(c) == need.get(c)) { ... }

// CORRECT — always use .intValue() or .equals()
if (window.get(c).intValue() == need.get(c).intValue()) { ... }
```

**Edge Cases:**
- ☐ `t` longer than `s` → return ""
- ☐ `t` has duplicate characters (e.g., "AAB") → need count ≥ 2 for 'A'
- ☐ No valid window exists → return ""
- ☐ Entire `s` is the minimum window → works correctly
- ☐ `t` is a single character → find first occurrence

🎯 **Likely Follow-ups:**
- **Q:** Can you do this in O(n) with O(1) space?
  **A:** If the character set is fixed (e.g., ASCII), you can use `int[128]` instead of HashMap — that's O(1) space in terms of input size. But the algorithm is still O(n) time.
- **Q:** What if you need to find all minimum windows, not just one?
  **A:** Track all windows with length equal to `minLen`. After finding the first minimum, continue sliding — any subsequent window with the same length is also a minimum window.
- **Q:** How would you handle this for a stream of characters?
  **A:** The sliding window approach naturally handles streaming. Maintain the window state and check validity after each new character. You'd need to buffer characters for the window.

> 🔗 **See Also:** [01-dsa/01-arrays-strings-hashing.md](01-arrays-strings-hashing.md) Pattern 1 (Frequency Counting) for the frequency map technique used inside this window.

---

### Pattern 6: Sliding Window with Monotonic Deque

**Use a deque that maintains elements in sorted order (decreasing for max, increasing for min) to find the maximum or minimum of every window of size k in O(n) total.**

**When to recognize it:** Sliding window maximum/minimum — need the max or min of every window of size k.

💡 **Intuition:** Imagine a line of people entering a room through a door (right side) and leaving through another door (left side). You always want to know who's the tallest person currently in the room. Instead of measuring everyone each time, you maintain a "VIP line" — when a new person enters, anyone shorter than them will never be the tallest (the new person will outlast them in the room), so you remove them from the VIP line. The front of the VIP line is always the tallest person in the room.

**Why a deque:** A regular approach recomputes max for each window in O(k) → total O(nk). A monotonic deque maintains elements in decreasing order (for max) so the front is always the current max. Elements are added/removed in amortized O(1).

**How the monotonic deque works (for max):**
1. Before adding `nums[i]`, remove all elements from the back that are ≤ `nums[i]` (they can never be the max while `nums[i]` is in the window)
2. Add `nums[i]` to the back
3. If the front element is outside the window (index ≤ i-k), remove it
4. The front of the deque is the current window max

**Store indices, not values** — so you can check if the front is still within the window.

```java
// LC 239: Sliding Window Maximum [🔥 Must Do]
public int[] maxSlidingWindow(int[] nums, int k) {
    int n = nums.length;
    int[] result = new int[n - k + 1];
    Deque<Integer> deque = new ArrayDeque<>(); // stores INDICES, not values

    for (int i = 0; i < n; i++) {
        // Step 1: Remove elements outside the window from front
        while (!deque.isEmpty() && deque.peekFirst() <= i - k) {
            deque.pollFirst();
        }

        // Step 2: Remove smaller elements from back (they're useless)
        // nums[i] is bigger, and it entered later, so it will outlast them
        while (!deque.isEmpty() && nums[deque.peekLast()] <= nums[i]) {
            deque.pollLast();
        }

        // Step 3: Add current index
        deque.offerLast(i);

        // Step 4: Record result (once we have a full window)
        if (i >= k - 1) {
            result[i - k + 1] = nums[deque.peekFirst()]; // front = max
        }
    }
    return result;
}
```

**Dry run:** `nums = [1,3,-1,-3,5,3,6,7]`, `k = 3`

```
i=0, nums[0]=1:
  Deque: [] → remove nothing → add 0 → [0]
  Window not full yet.

i=1, nums[1]=3:
  Deque: [0] → nums[0]=1 ≤ 3 → remove 0 → [] → add 1 → [1]
  Window not full yet.

i=2, nums[2]=-1:
  Deque: [1] → nums[1]=3 > -1 → keep → add 2 → [1, 2]
  Window [1,3,-1]: max = nums[deque.front] = nums[1] = 3 ✓

i=3, nums[3]=-3:
  Deque: [1, 2] → nums[2]=-1 > -3 → keep → add 3 → [1, 2, 3]
  Window [3,-1,-3]: max = nums[1] = 3 ✓

i=4, nums[4]=5:
  Deque: [1, 2, 3] → front=1, 1 ≤ 4-3=1 → remove 1 → [2, 3]
  → nums[3]=-3 ≤ 5 → remove 3 → [2]
  → nums[2]=-1 ≤ 5 → remove 2 → []
  → add 4 → [4]
  Window [-1,-3,5]: max = nums[4] = 5 ✓

i=5, nums[5]=3:
  Deque: [4] → nums[4]=5 > 3 → keep → add 5 → [4, 5]
  Window [-3,5,3]: max = nums[4] = 5 ✓

i=6, nums[6]=6:
  Deque: [4, 5] → nums[5]=3 ≤ 6 → remove 5 → [4]
  → nums[4]=5 ≤ 6 → remove 4 → [] → add 6 → [6]
  Window [5,3,6]: max = nums[6] = 6 ✓

i=7, nums[7]=7:
  Deque: [6] → nums[6]=6 ≤ 7 → remove 6 → [] → add 7 → [7]
  Window [3,6,7]: max = nums[7] = 7 ✓

Result: [3, 3, 5, 5, 6, 7] ✓
```

**Complexity:** O(n) time (each element enters and leaves the deque at most once), O(k) space.

| Approach | Time | Space | Notes |
|----------|------|-------|-------|
| Brute force (scan each window) | O(nk) | O(1) | Too slow for large k |
| Monotonic deque | O(n) | O(k) | Optimal |
| Two heaps | O(n log k) | O(k) | Works but slower |
| Segment tree | O(n log n) | O(n) | Overkill |

⚙️ **Under the Hood — Monotonic Deque Invariant:**
The deque always maintains indices in decreasing order of their values. This means:
- `nums[deque[0]] ≥ nums[deque[1]] ≥ ... ≥ nums[deque[last]]`
- The front is always the maximum in the current window
- When a new element is larger than the back, we remove the back because it can never be the answer — the new element is both larger AND will stay in the window longer

**Edge Cases:**
- ☐ k = 1 → result is the array itself
- ☐ k = n → result is a single element (the global max)
- ☐ All elements equal → deque always has one element
- ☐ Strictly decreasing array → deque fills up to size k
- ☐ Strictly increasing array → deque always has one element (latest)

🎯 **Likely Follow-ups:**
- **Q:** How would you find the sliding window minimum?
  **A:** Same algorithm, but remove elements from the back that are ≥ `nums[i]` (instead of ≤). The front of the deque is the minimum.
- **Q:** Can you use this for a variable-size window?
  **A:** Yes — the monotonic deque works with any window. For variable-size, you'd remove from the front when the element's index is < `left` (instead of ≤ `i-k`).
- **Q:** What's the relationship between monotonic deque and monotonic stack?
  **A:** A monotonic stack only removes from one end (top). A monotonic deque removes from both ends — the front for expired elements, the back for dominated elements. The deque is a generalization of the stack.

> 🔗 **See Also:** [01-dsa/03-stacks-queues.md](03-stacks-queues.md) for monotonic stack patterns (next greater element, etc.).

---

### Pattern 7: Two Pointers for Palindromes

**For each possible center in the string, expand outward while characters match — this finds all palindromic substrings in O(n²) time and O(1) space.**

**When to recognize it:** Problem involves palindromes — checking, finding, or counting them.

💡 **Intuition:** A palindrome reads the same forwards and backwards. Instead of checking every possible substring (O(n³)), notice that every palindrome has a center. For odd-length palindromes, the center is a single character. For even-length, it's between two characters. From each center, expand outward as long as characters match. Total centers: 2n - 1.

**Approach — Expand Around Center:**
- For each possible center (single character or between two characters), expand outward while characters match
- Total centers: 2n - 1 (n single + n-1 between pairs)

```java
// LC 5: Longest Palindromic Substring [🔥 Must Do]
public String longestPalindrome(String s) {
    int start = 0, maxLen = 0;
    for (int i = 0; i < s.length(); i++) {
        int len1 = expand(s, i, i);     // odd-length palindrome (center = single char)
        int len2 = expand(s, i, i + 1); // even-length palindrome (center = between chars)
        int len = Math.max(len1, len2);
        if (len > maxLen) {
            maxLen = len;
            start = i - (len - 1) / 2; // calculate start index from center and length
        }
    }
    return s.substring(start, start + maxLen);
}

private int expand(String s, int left, int right) {
    while (left >= 0 && right < s.length() && s.charAt(left) == s.charAt(right)) {
        left--;   // expand left
        right++;  // expand right
    }
    return right - left - 1; // length of palindrome (right and left are one past the ends)
}
```

**Dry run:** `s = "babad"`

```
i=0 'b': expand(0,0)="b" len=1, expand(0,1) b≠a len=0. Best=1
i=1 'a': expand(1,1)="a" len=1, then "bab" len=3. expand(1,2) a≠b len=0. Best=3, start=0
i=2 'b': expand(2,2)="b" len=1, then "aba" len=3. expand(2,3) b≠a len=0. Best=3
i=3 'a': expand(3,3)="a" len=1. expand(3,4) a≠d len=0. Best=3
i=4 'd': expand(4,4)="d" len=1. Best=3

Answer: "bab" (or "aba" — both valid, we return the first found)
```

**Complexity:** O(n²) time (n centers × up to n expansion each), O(1) space.

| Approach | Time | Space | Notes |
|----------|------|-------|-------|
| Brute force (check all substrings) | O(n³) | O(1) | Check each substring + verify palindrome |
| Expand around center | O(n²) | O(1) | Optimal for interviews |
| Dynamic Programming | O(n²) | O(n²) | `dp[i][j]` = is s[i..j] palindrome |
| Manacher's algorithm | O(n) | O(n) | Rarely asked, complex to implement |

**Counting all palindromic substrings (LC 647):**

```java
public int countSubstrings(String s) {
    int count = 0;
    for (int i = 0; i < s.length(); i++) {
        count += countPalindromes(s, i, i);     // odd-length
        count += countPalindromes(s, i, i + 1); // even-length
    }
    return count;
}

private int countPalindromes(String s, int left, int right) {
    int count = 0;
    while (left >= 0 && right < s.length() && s.charAt(left) == s.charAt(right)) {
        count++; // each expansion finds a new palindrome
        left--;
        right++;
    }
    return count;
}
```

**Edge Cases:**
- ☐ Single character → always a palindrome
- ☐ All same characters "aaaa" → every substring is a palindrome
- ☐ No palindrome longer than 1 → return any single character
- ☐ Even-length palindrome "abba" → caught by `expand(i, i+1)`
- ☐ Entire string is a palindrome → expand from center reaches both ends

🎯 **Likely Follow-ups:**
- **Q:** Can you solve this in O(n)?
  **A:** Yes, Manacher's algorithm. It reuses information from previously computed palindromes to avoid redundant expansion. But it's complex and rarely asked in interviews — expand around center is the expected approach.
- **Q:** How would you find the longest palindromic subsequence (not substring)?
  **A:** That's a DP problem, not two pointers. `dp[i][j]` = length of longest palindromic subsequence in `s[i..j]`. See the DP document.

> 🔗 **See Also:** [01-dsa/07-dynamic-programming.md](07-dynamic-programming.md) for DP-based palindrome solutions (longest palindromic subsequence).

---

### Pattern 8: Subarray with Target Sum (Positive Numbers) & The "Exactly K" Trick

**When all numbers are positive, sliding window works for sum-based problems because adding always increases the sum and removing always decreases it.**

**When to recognize it:** Find shortest/longest subarray with sum ≥ target, and all numbers are positive (or non-negative).

**Why positivity matters:** With all positive numbers, adding an element always increases the sum and removing always decreases it — this monotonic property makes sliding window valid. With negative numbers, you need prefix sum + HashMap or prefix sum + monotonic deque.

```java
// LC 209: Minimum Size Subarray Sum
public int minSubArrayLen(int target, int[] nums) {
    int left = 0, sum = 0, minLen = Integer.MAX_VALUE;
    for (int right = 0; right < nums.length; right++) {
        sum += nums[right];                          // expand
        while (sum >= target) {                       // shrink while valid
            minLen = Math.min(minLen, right - left + 1);
            sum -= nums[left++];                      // remove left
        }
    }
    return minLen == Integer.MAX_VALUE ? 0 : minLen;
}
```

**Complexity:** O(n) time, O(1) space.

**The "Exactly K" Trick** [🔥 Must Know]:

Many problems ask for subarrays with exactly k distinct elements (or exactly k of something). Direct sliding window doesn't work for "exactly k" because shrinking might skip valid windows. The trick:

```
exactly(k) = atMost(k) - atMost(k - 1)
```

💡 **Intuition:** The set of subarrays with at most k distinct elements includes subarrays with 0, 1, 2, ..., k distinct elements. The set with at most k-1 includes 0, 1, ..., k-1. Subtracting gives us exactly those with k.

```java
// LC 992: Subarrays with K Different Integers [🔥 Must Do]
public int subarraysWithKDistinct(int[] nums, int k) {
    return atMost(nums, k) - atMost(nums, k - 1);
}

private int atMost(int[] nums, int k) {
    Map<Integer, Integer> count = new HashMap<>();
    int left = 0, result = 0;
    for (int right = 0; right < nums.length; right++) {
        count.merge(nums[right], 1, Integer::sum);

        while (count.size() > k) { // more than k distinct → shrink
            int leftVal = nums[left];
            count.merge(leftVal, -1, Integer::sum);
            if (count.get(leftVal) == 0) count.remove(leftVal);
            left++;
        }

        result += right - left + 1; // all subarrays ending at right with ≤ k distinct
    }
    return result;
}
```

⚙️ **Under the Hood — Why `result += right - left + 1`?**
After shrinking, the window `[left..right]` has at most k distinct elements. Every subarray ending at `right` that starts at any index from `left` to `right` also has at most k distinct elements (because it's a subset of the valid window). There are `right - left + 1` such subarrays.

**Edge Cases:**
- ☐ k = 0 → no subarrays (atMost(0) = 0 for non-empty arrays)
- ☐ k > number of distinct elements → all subarrays are valid
- ☐ All elements the same → atMost(1) = n*(n+1)/2, atMost(0) = 0, exactly(1) = n*(n+1)/2
- ☐ Array of length 1 → exactly(1) = 1

🎯 **Likely Follow-ups:**
- **Q:** Why can't you use a direct sliding window for "exactly k"?
  **A:** When you find a valid window with exactly k distinct elements and try to shrink, you might reduce to k-1 distinct elements, making it invalid. But there might be other valid windows between the old and new left positions that you'd miss. The atMost trick avoids this by counting inclusively.
- **Q:** What about "exactly k" for sum problems?
  **A:** Same trick: `exactlySum(k) = atMostSum(k) - atMostSum(k-1)`. But this only works when all elements are non-negative (so the monotonic property holds for atMost).


---

## 3. Patterns Summary Table

| # | Pattern | When to Use | Key Idea | Time | Space | Example Problem |
|---|---------|------------|----------|------|-------|-----------------|
| 1 | Opposite-direction (sorted) | Pair sum, container, triplets | left→ ←right, move based on sum comparison | O(n) | O(1) | 3Sum (LC 15) |
| 2 | Same-direction (fast/slow) | Remove duplicates, partition, cycle | slow=write pos, fast=scanner | O(n) | O(1) | Sort Colors (LC 75) |
| 3 | Fixed-size window | Subarray of exact size k | Slide: add right, remove left | O(n) | O(1) | Find All Anagrams (LC 438) |
| 4 | Variable-size window (longest) | Longest subarray/substring with constraint | Expand right, shrink left when invalid | O(n) | O(k) | Longest Substring No Repeat (LC 3) |
| 5 | Variable-size window (shortest) | Minimum window with constraint | Expand until valid, shrink while valid | O(n) | O(k) | Min Window Substring (LC 76) |
| 6 | Monotonic deque window | Sliding window max/min | Deque maintains decreasing/increasing order | O(n) | O(k) | Sliding Window Maximum (LC 239) |
| 7 | Expand around center | Palindromes | Try each center, expand outward | O(n²) | O(1) | Longest Palindromic Substring (LC 5) |
| 8 | Positive sum window + Exactly K | Subarray sum ≥ target / exactly k distinct | Shrink while valid; exactly(k) = atMost(k) - atMost(k-1) | O(n) | O(1) | Subarrays with K Distinct (LC 992) |

**Pattern Selection Flowchart:**

```
Problem involves contiguous subarray/substring?
├── YES → Window size given (k)?
│   ├── YES → Pattern 3: Fixed-size window
│   │   └── Need max/min of each window? → Pattern 6: Monotonic deque
│   └── NO → What are you optimizing?
│       ├── Longest valid → Pattern 4: Variable window (expand, shrink when invalid)
│       ├── Shortest valid → Pattern 5: Variable window (expand, shrink while valid)
│       └── Exactly K of something → Pattern 8: atMost(k) - atMost(k-1)
├── NO → Array sorted or can be sorted?
│   ├── YES → Need pair/triplet? → Pattern 1: Opposite-direction
│   └── NO → Need in-place rearrangement? → Pattern 2: Fast/slow
└── Palindrome problem? → Pattern 7: Expand around center
```

---

## 4. LeetCode Problem List (Must-Solve)

### Easy

| # | Problem Name | LC # | Pattern(s) | Why Important |
|---|-------------|------|-----------|---------------|
| 1 | Valid Palindrome | 125 | Opposite-direction | [🔥 Must Do] Basic two-pointer palindrome check |
| 2 | Remove Duplicates from Sorted Array | 26 | Fast/slow | In-place modification fundamental |
| 3 | Remove Element | 27 | Fast/slow | Simplest partition problem |
| 4 | Move Zeroes | 283 | Fast/slow | [🔥 Must Do] Partition variant |
| 5 | Squares of a Sorted Array | 977 | Opposite-direction | Merge from both ends |
| 6 | Is Subsequence | 392 | Same-direction | Two pointers on two arrays |
| 7 | Reverse String | 344 | Opposite-direction | In-place swap |
| 8 | Merge Sorted Array | 88 | Opposite-direction (from end) | [🔥 Must Do] Merge in-place from right |
| 9 | Palindrome Number | 9 | Two pointers / math | Reverse half the number |
| 10 | Backspace String Compare | 844 | Reverse two pointers | O(1) space with reverse traversal |

### Medium

| # | Problem Name | LC # | Pattern(s) | Why Important |
|---|-------------|------|-----------|---------------|
| 1 | 3Sum | 15 | Opposite + sort | [🔥 Must Do] Duplicate handling is the challenge |
| 2 | Container With Most Water | 11 | Opposite-direction | [🔥 Must Do] Greedy pointer movement proof |
| 3 | Longest Substring Without Repeating Characters | 3 | Variable window | [🔥 Must Do] Classic variable window |
| 4 | Minimum Window Substring | 76 | Variable window (shortest) | [🔥 Must Do] Hardest sliding window pattern |
| 5 | Minimum Size Subarray Sum | 209 | Window + positive sums | [🔥 Must Do] Shrink while valid |
| 6 | Find All Anagrams in a String | 438 | Fixed window | [🔥 Must Do] Frequency comparison |
| 7 | Permutation in String | 567 | Fixed window | Same as 438, return boolean |
| 8 | Longest Repeating Character Replacement | 424 | Variable window | [🔥 Must Do] Window validity: len - maxFreq ≤ k |
| 9 | Fruit Into Baskets | 904 | Variable window | At most 2 distinct elements |
| 10 | Max Consecutive Ones III | 1004 | Variable window | At most k zeros in window |
| 11 | Subarray Product Less Than K | 713 | Variable window | Product-based window |
| 12 | Sort Colors | 75 | Three pointers (DNF) | [🔥 Must Do] Dutch National Flag |
| 13 | Two Sum II - Input Array Is Sorted | 167 | Opposite-direction | Sorted array pair finding |
| 14 | 3Sum Closest | 16 | Opposite + sort | Track closest sum |
| 15 | 4Sum | 18 | Opposite + sort | Generalized k-sum |
| 16 | Remove Duplicates from Sorted Array II | 80 | Fast/slow | Allow at most 2 duplicates |
| 17 | Trapping Rain Water | 42 | Opposite-direction / stack | [🔥 Must Do] Two-pointer O(1) space approach |
| 18 | Longest Palindromic Substring | 5 | Expand around center | [🔥 Must Do] O(n²) expand approach |
| 19 | Palindromic Substrings | 647 | Expand around center | Count all palindromes |
| 20 | Boats to Save People | 881 | Opposite-direction + sort | Greedy pairing |
| 21 | Number of Subsequences That Satisfy the Given Sum Condition | 1498 | Opposite + sort + math | Power of 2 counting |
| 22 | Get Equal Substrings Within Budget | 1208 | Variable window | Cost-based window |
| 23 | Grumpy Bookstore Owner | 1052 | Fixed window | Maximize gain in window |
| 24 | Maximum Points You Can Obtain from Cards | 1423 | Fixed window (inverse) | Min subarray of size n-k |
| 25 | Frequency of the Most Frequent Element | 1838 | Variable window + sort | Operations budget window |
| 26 | Count Number of Nice Subarrays | 1248 | Variable window / prefix sum | Exactly k → atMost(k) - atMost(k-1) |
| 27 | Subarrays with K Different Integers | 992 | Variable window (exactly k) | [🔥 Must Do] atMost(k) - atMost(k-1) trick |
| 28 | Max Number of Vowels in a Substring of Given Length | 1456 | Fixed window | Simple fixed window |
| 29 | Rotate Array | 189 | Three reverses | Reverse trick |
| 30 | Next Permutation | 31 | Two pointers + scan | [🔥 Must Do] Algorithm to memorize |

### Hard

| # | Problem Name | LC # | Pattern(s) | Why Important |
|---|-------------|------|-----------|---------------|
| 1 | Sliding Window Maximum | 239 | Monotonic deque | [🔥 Must Do] Core monotonic deque pattern |
| 2 | Minimum Window Substring | 76 | Variable window (shortest) | [🔥 Must Do] Already in medium — hard-level execution |
| 3 | Substring with Concatenation of All Words | 30 | Fixed window + HashMap | Multi-word sliding window |
| 4 | Longest Substring with At Most K Distinct Characters | 340 | Variable window | Premium — generalized distinct count |
| 5 | Shortest Subarray with Sum at Least K | 862 | Prefix sum + monotonic deque | [🔥 Must Do] Negative numbers break basic window |
| 6 | Minimum Number of K Consecutive Bit Flips | 995 | Sliding window + greedy | Deferred flip tracking |
| 7 | Count Subarrays With Fixed Bounds | 2444 | Variable window | Track last positions of min/max |
| 8 | Sliding Window Median | 480 | Two heaps + window | Median maintenance |
| 9 | Max Value of Equation | 1499 | Monotonic deque | Deque optimization of pair selection |
| 10 | Minimum Window Subsequence | 727 | Two pointers (forward + backward) | Premium — subsequence in window |


---

## 5. Interview Strategy

**Decision tree for choosing the right approach:**

```
Is the array sorted (or can you sort it)?
├── YES → Do you need original indices?
│   ├── YES → Use HashMap (not two pointers)
│   └── NO → Use opposite-direction two pointers
└── NO → Is it about a contiguous subarray/substring?
    ├── YES → Is the window size fixed?
    │   ├── YES → Fixed-size sliding window
    │   │   └── Need max/min per window? → Monotonic deque
    │   └── NO → Variable-size sliding window
    │       ├── "Longest" → expand right, shrink when invalid
    │       ├── "Shortest" → expand until valid, shrink while valid
    │       └── "Exactly K" → atMost(k) - atMost(k-1)
    └── NO → Is it about in-place modification?
        ├── YES → Fast/slow pointers
        └── NO → Consider other approaches (HashMap, sorting)
```

**How to communicate in an interview:**

```
You: "I notice the array is sorted, so I can use two pointers from both ends.
     The key insight is that if the sum is too small, I move the left pointer
     right to increase it, and if too large, I move the right pointer left.
     This gives me O(n) instead of the O(n²) brute force."

You: "This is a subarray problem with a constraint on distinct characters.
     I'll use a variable-size sliding window. I expand the right pointer to
     include more characters, and when I have too many distinct characters,
     I shrink from the left. The window is always the longest valid subarray
     ending at the current right position."
```

**Time management for sliding window problems (45-minute interview):**

| Phase | Time | What to Do |
|-------|------|------------|
| Understand | 3 min | Identify: fixed or variable window? Longest or shortest? What's the constraint? |
| Approach | 5 min | State brute force (O(n²) or O(n×k)), explain why sliding window works (monotonic property) |
| Code | 20 min | Write the template, fill in expand/shrink/update logic |
| Test | 10 min | Trace through example, verify left pointer never goes past right |
| Discuss | 7 min | Complexity analysis, edge cases, follow-ups |

**Common mistakes:**
- Using sliding window when numbers can be negative (sum is not monotonic — window shrinking doesn't guarantee sum decreases)
- Forgetting to handle the `left > right` case in opposite-direction pointers
- Not skipping duplicates in 3Sum/4Sum → getting duplicate triplets
- In variable window: updating result at the wrong place (before vs after shrinking)
- In monotonic deque: storing values instead of indices (can't check if element is in window)
- In minimum window: forgetting to shrink while valid (only shrinking once misses shorter windows)
- Using `==` instead of `.equals()` or `.intValue()` for Integer comparison in HashMap values

💥 **What Can Go Wrong in Interviews:**

| Mistake | Impact | Prevention |
|---------|--------|------------|
| Wrong window type (fixed vs variable) | Completely wrong approach | Ask: "Is the window size given or do I need to find it?" |
| Sliding window with negatives | Algorithm doesn't converge | Check: "Are all numbers positive?" If not, use prefix sum |
| Missing duplicate handling in 3Sum | Wrong answer, looks careless | Practice the 3 skip locations until automatic |
| Off-by-one in window boundaries | Subtle bugs, hard to debug | Use `right - left + 1` for window size, trace with small example |
| Not initializing `minLen = MAX_VALUE` | Returns 0 instead of "no answer" | Always initialize to extreme value for min/max tracking |

---

## 6. Edge Cases & Pitfalls

**Two pointers edge cases:**
- ☐ Array of length 0 or 1 → handle before main loop
- ☐ All elements identical → duplicate skipping logic must handle this
- ☐ No valid pair exists → return empty/default
- ☐ Integer overflow: `nums[left] + nums[right]` can overflow `int` → use `(long)nums[left] + nums[right]`
- ☐ Sorted in descending order → reverse or adjust pointer logic

**Sliding window edge cases:**
- ☐ Window size k > array length → no valid window, return 0 or empty
- ☐ Empty string/array → return 0
- ☐ All characters the same → window might be entire string
- ☐ Target/constraint is 0 or negative → check if problem allows this
- ☐ Single-element window is valid → ensure left can equal right

**Java-specific pitfalls:**

```java
// PITFALL 1: Integer comparison in HashMap
Map<Character, Integer> map = new HashMap<>();
map.put('a', 200);
map.put('b', 200);
// WRONG: may return false for values > 127
if (map.get('a') == map.get('b')) { ... }
// CORRECT:
if (map.get('a').intValue() == map.get('b').intValue()) { ... }
// ALSO CORRECT:
if (map.get('a').equals(map.get('b'))) { ... }

// PITFALL 2: ArrayDeque doesn't allow null
Deque<Integer> deque = new ArrayDeque<>();
deque.offer(null); // throws NullPointerException!
// Use LinkedList if you need null support (rare in practice)

// PITFALL 3: Deque method naming confusion
// offer/poll/peek = return null on failure (preferred)
// add/remove/element = throw exception on failure
deque.offerLast(x);   // preferred
deque.pollFirst();     // preferred
deque.peekFirst();     // preferred

// PITFALL 4: String charAt vs toCharArray
// charAt(i) is O(1) — no allocation
// toCharArray() is O(n) — creates new array
// For sliding window, use charAt(i) to avoid unnecessary allocation
```

---

## 7. Connections to Other Topics

| This Pattern | Connects To | How |
|-------------|-------------|-----|
| Two pointers on sorted array | [01-dsa/11-sorting-searching.md](11-sorting-searching.md) | Binary search is "one pointer + halving"; both exploit sorted order |
| Sliding window | [01-dsa/01-arrays-strings-hashing.md](01-arrays-strings-hashing.md) | Prefix Sum + HashMap replaces sliding window when negatives present |
| Monotonic deque | [01-dsa/03-stacks-queues.md](03-stacks-queues.md) | Monotonic deque is a generalization of monotonic stack |
| Fast/slow pointers | [01-dsa/04-linked-lists.md](04-linked-lists.md) | Floyd's cycle detection uses same-direction pointers on linked lists |
| Variable window | [01-dsa/03-stacks-queues.md](03-stacks-queues.md) | Queue/Deque often maintains window state |
| Expand around center | [01-dsa/07-dynamic-programming.md](07-dynamic-programming.md) | Palindrome problems also solvable with DP (longest palindromic subsequence) |
| Two pointers partition | [01-dsa/11-sorting-searching.md](11-sorting-searching.md) | Dutch National Flag is quicksort's three-way partition step |
| Window frequency counting | [01-dsa/01-arrays-strings-hashing.md](01-arrays-strings-hashing.md) | Frequency maps from arrays doc used inside windows |
| Sliding window on strings | [02-system-design/problems/rate-limiter.md](../02-system-design/problems/rate-limiter.md) | Sliding window rate limiting uses the same concept |
| Trapping Rain Water | [01-dsa/03-stacks-queues.md](03-stacks-queues.md) | Stack-based approach is an alternative to two pointers |

---

## 8. Revision Checklist

**Two Pointer types:**
- [ ] Opposite-direction: sorted array, pair sum, container → left=0, right=n-1, move based on comparison
- [ ] Same-direction (fast/slow): remove duplicates, partition → slow=write position, fast=scanner
- [ ] Three pointers (DNF): sort 0/1/2 → low, mid, high. Don't advance mid when swapping with high.

**Sliding Window types:**
- [ ] Fixed-size: window always k elements → slide by adding right, removing left
- [ ] Variable (longest): expand right, shrink left when invalid, update after shrink
- [ ] Variable (shortest): expand until valid, shrink while valid, update during shrink
- [ ] Monotonic deque: window max/min → deque stores INDICES in decreasing/increasing order
- [ ] Exactly K: `exactly(k) = atMost(k) - atMost(k-1)`

**Key templates to memorize:**
- [ ] 3Sum: sort + fix one + two pointers + 3 duplicate skips (i, left, right)
- [ ] Variable window: `for right { expand; while(invalid) { shrink; left++; } update; }`
- [ ] Min window substring: `formed` counter for O(1) validity check
- [ ] Monotonic deque: remove expired front, remove dominated back, add current, read front
- [ ] Container with most water: move the shorter line (greedy proof)
- [ ] Expand around center: try each of 2n-1 centers, expand while chars match

**Critical details:**
- [ ] Sliding window only works when monotonic property holds (positive numbers for sum, bounded distinct for count)
- [ ] For negative numbers in sum problems → use prefix sum + HashMap or prefix sum + monotonic deque
- [ ] `formed` counter in min window substring → O(1) validity check instead of O(k) map comparison
- [ ] In LC 424 (character replacement), `maxFreq` doesn't need to decrease — stale value is safe for "longest" problems
- [ ] `lastIndex.get(c) >= left` check in LC 3 — prevents left pointer from going backward
- [ ] Use `.intValue()` or `.equals()` for Integer comparison in HashMap (not `==`)

**Complexity:**
- [ ] All two-pointer patterns: O(n) time, O(1) space
- [ ] Sliding window: O(n) time, O(k) space (k = window state size)
- [ ] Monotonic deque: O(n) time, O(k) space
- [ ] Expand around center: O(n²) time, O(1) space
- [ ] 3Sum: O(n²) time, O(1) space (after sorting)

**When NOT to use sliding window:**
- [ ] Negative numbers in sum problems (sum not monotonic)
- [ ] Need all subarrays, not just longest/shortest
- [ ] No contiguous constraint (subsequence, not subarray)
- [ ] Window validity depends on global state, not just window contents

**Top 10 must-solve before interview:**
1. 3Sum (LC 15) [Medium] — Opposite direction + duplicate handling
2. Container With Most Water (LC 11) [Medium] — Greedy pointer movement
3. Longest Substring Without Repeating Characters (LC 3) [Medium] — Variable window
4. Minimum Window Substring (LC 76) [Hard] — Shortest window with formed counter
5. Sliding Window Maximum (LC 239) [Hard] — Monotonic deque
6. Sort Colors (LC 75) [Medium] — Dutch National Flag three-way partition
7. Longest Repeating Character Replacement (LC 424) [Medium] — Window validity condition
8. Find All Anagrams in a String (LC 438) [Medium] — Fixed window with frequency match
9. Trapping Rain Water (LC 42) [Hard] — Two-pointer O(1) space
10. Longest Palindromic Substring (LC 5) [Medium] — Expand around center

---

## 📋 Suggested New Documents

### 1. Monotonic Stack & Monotonic Queue Deep Dive
- **Placement**: `01-dsa/12-monotonic-stack-queue.md`
- **Why needed**: Monotonic deque is introduced here but the monotonic stack pattern (next greater element, stock span, largest rectangle in histogram) is a distinct and frequently tested pattern family not fully covered in the stacks doc.
- **Key subtopics**: Next greater/smaller element, daily temperatures, largest rectangle in histogram, stock span problem, trapping rain water (stack approach), monotonic queue for sliding window problems

### 2. Advanced Sliding Window Techniques
- **Placement**: `01-dsa/12-advanced-sliding-window.md`
- **Why needed**: Problems like "Shortest Subarray with Sum at Least K" (LC 862) combine prefix sum with monotonic deque — a technique that doesn't fit cleanly into basic sliding window or basic prefix sum. Multi-pointer windows and "contribution counting" are also advanced patterns.
- **Key subtopics**: Prefix sum + monotonic deque for negative numbers, multi-pointer sliding window, contribution counting technique, sliding window on trees/graphs
