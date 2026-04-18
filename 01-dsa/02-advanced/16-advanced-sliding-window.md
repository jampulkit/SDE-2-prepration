> ⚠️ **[OPTIONAL] — Rarely asked at SDE-2 interviews. Skip unless you've mastered files 00-14.**

# Advanced Sliding Window Techniques

## 1. Foundation

**Advanced sliding window handles cases where basic sliding window breaks: negative numbers in sum problems, "exactly K" counting, and multi-constraint windows.**

💡 **Intuition:** Basic sliding window works when expanding the window makes the constraint "worse" and shrinking makes it "better" (monotonic property). With negative numbers, adding an element can decrease the sum, breaking this monotonicity. Advanced techniques restore the ability to reason about the window by using prefix sums, monotonic deques, or algebraic decomposition (exactly K = atMost K - atMost K-1).

**When basic sliding window fails:**

| Scenario | Why It Fails | Solution |
|----------|-------------|----------|
| Negative numbers in sum | Adding element can decrease sum (non-monotonic) | Prefix sum + monotonic deque |
| "Exactly K distinct" | Can't shrink to exactly K (might skip valid windows) | atMost(K) - atMost(K-1) |
| Multiple constraints | Shrinking fixes one constraint but breaks another | Multi-pointer or combine techniques |
| Fixed bounds (min and max) | Window validity depends on positions of specific values | Track last positions of bounds |

> 🔗 **See Also:** [01-dsa/02-two-pointers-sliding-window.md](02-two-pointers-sliding-window.md) for basic sliding window. [01-dsa/15-monotonic-stack-queue.md](15-monotonic-stack-queue.md) for monotonic deque fundamentals.

---

## 2. Core Patterns

### Pattern 1: Prefix Sum + Monotonic Deque (Negative Numbers) [🔥 Must Know]

**When the array has negative numbers, basic sliding window can't determine when to shrink. Use prefix sums to convert subarray sums into differences, then use a monotonic deque to find the optimal start index.**

💡 **Intuition:** Subarray sum `nums[i..j] = prefix[j+1] - prefix[i]`. We want the shortest subarray where this difference >= k. For each j, we want the largest i (closest to j) where `prefix[i] <= prefix[j+1] - k`. A monotonic increasing deque of prefix sum indices lets us find this in O(1) amortized.

```java
// LC 862: Shortest Subarray with Sum at Least K (with negative numbers!)
// Time: O(n), Space: O(n)
public int shortestSubarray(int[] nums, int k) {
    int n = nums.length;
    long[] prefix = new long[n + 1];
    for (int i = 0; i < n; i++) prefix[i + 1] = prefix[i] + nums[i];
    
    Deque<Integer> deque = new ArrayDeque<>(); // increasing deque of prefix sum indices
    int minLen = Integer.MAX_VALUE;
    
    for (int i = 0; i <= n; i++) {
        // Check: can we form a valid subarray ending here?
        while (!deque.isEmpty() && prefix[i] - prefix[deque.peekFirst()] >= k) {
            minLen = Math.min(minLen, i - deque.pollFirst()); // pollFirst: this start won't be better for future j
        }
        // Maintain increasing order: remove larger prefix sums from back
        while (!deque.isEmpty() && prefix[i] <= prefix[deque.peekLast()]) {
            deque.pollLast(); // current prefix is smaller, so it's a better start candidate
        }
        deque.offerLast(i);
    }
    return minLen == Integer.MAX_VALUE ? -1 : minLen;
}
```

⚙️ **Under the Hood, Why We Poll from Front and Back:**

```
prefix = [0, 1, -2, 3, 5, 2, 8], k = 4

i=0: deque=[0]                    prefix[0]=0
i=1: deque=[0,1]                  prefix[1]=1
i=2: prefix[2]=-2 < prefix[1]=1  → pop 1 from back. deque=[0,2]
     (prefix[2] is a better start than prefix[1] because it's smaller)
i=3: prefix[3]=3. Check front: 3-0=3 < 4. deque=[0,2,3]
i=4: prefix[4]=5. Check front: 5-0=5 >= 4! minLen=4. Poll 0.
     Check front: 5-(-2)=7 >= 4! minLen=2. Poll 2.
     Check front: 5-3=2 < 4. Stop. deque=[3,4]
i=5: prefix[5]=2 < prefix[4]=5 → pop 4. 2 < 3 → pop 3. deque=[5]
i=6: prefix[6]=8. Check front: 8-2=6 >= 4! minLen=1. Poll 5. deque=[6]

Answer: 1 (subarray [8] at index 5... wait, let me recheck)
Actually the subarray from index 5 to 5 has sum nums[5]=2, not 8.
prefix[6]-prefix[5] = 8-2 = 6 >= 4. Length = 6-5 = 1. ✓ (subarray is just nums[5]... 
no, prefix[6]=8, prefix[5]=2, so sum of nums[5]=prefix[6]-prefix[5]=6. But nums[5]=2? 
Let me recompute: nums=[1,-3,5,2,-3,6], prefix=[0,1,-2,3,5,2,8]. 
prefix[6]-prefix[5]=8-2=6, length=1, that's nums[5]=6. ✓)

Key insights:
- Poll from FRONT: once a start index satisfies the condition, no future j will give a shorter subarray with this start (j only increases).
- Poll from BACK: if prefix[i] <= prefix[back], then i is a strictly better start candidate (smaller prefix, later index = shorter subarray).
```

⚠️ **Common Pitfall:** Using basic sliding window for this problem. With negative numbers, shrinking the window from the left might increase the sum (removing a negative element), so the standard "shrink when sum >= k" approach doesn't work.

🎯 **Likely Follow-ups:**
- **Q:** Why can't we just use a TreeMap instead of a monotonic deque?
  **A:** You could use a TreeMap to find the optimal start index in O(log n) per step, giving O(n log n) total. The monotonic deque gives O(n) because each element is pushed and popped at most once. For competitive programming, the deque approach is preferred.
- **Q:** What if we want the longest (not shortest) subarray with sum >= k?
  **A:** Different problem. Use prefix sums and for each j, find the smallest i where `prefix[j] - prefix[i] >= k`. This requires a different deque strategy or binary search on a sorted structure.

---

### Pattern 2: Exactly K = AtMost(K) - AtMost(K-1) [🔥 Must Know]

**To count subarrays/substrings with exactly K distinct elements, decompose into: atMost(K) - atMost(K-1).**

💡 **Intuition:** Counting "exactly K" directly is hard because the sliding window can't tell when to shrink (shrinking might go from K to K-1 distinct, skipping valid windows). But "at most K" is easy with standard sliding window. And "exactly K" = "at most K" - "at most K-1".

```java
// LC 992: Subarrays with K Different Integers
// Time: O(n), Space: O(n)
public int subarraysWithKDistinct(int[] nums, int k) {
    return atMost(nums, k) - atMost(nums, k - 1);
}

private int atMost(int[] nums, int k) {
    Map<Integer, Integer> freq = new HashMap<>();
    int left = 0, count = 0;
    for (int right = 0; right < nums.length; right++) {
        freq.merge(nums[right], 1, Integer::sum);
        while (freq.size() > k) { // shrink until at most k distinct
            int val = freq.merge(nums[left], -1, Integer::sum);
            if (val == 0) freq.remove(nums[left]);
            left++;
        }
        count += right - left + 1; // all subarrays ending at right with at most k distinct
    }
    return count;
}
```

⚙️ **Under the Hood, Why `count += right - left + 1`:**

```
Window [left, right] has at most K distinct elements.
All subarrays ending at 'right' that start at any index in [left, right] are valid.
That's (right - left + 1) subarrays.

Example: nums = [1,2,1,2,3], k=2
  atMost(2): windows and counts
    right=0: [1]         → 1 subarray
    right=1: [1,2]       → 2 subarrays
    right=2: [1,2,1]     → 3 subarrays
    right=3: [1,2,1,2]   → 4 subarrays
    right=4: [2,1,2,3] has 3 distinct → shrink to [2,3] → 2 subarrays
  Total atMost(2) = 1+2+3+4+2 = 12

  atMost(1): only single-element windows or consecutive same elements
  Total atMost(1) = 5 (each single element)

  Exactly 2 = 12 - 5 = 7 ✓
```

🎯 **Likely Follow-ups:**
- **Q:** Can this technique work for "exactly K" with other constraints (not just distinct count)?
  **A:** Yes. Any constraint where "at most K" is solvable with sliding window can use this decomposition. Examples: subarrays with exactly K odd numbers, substrings with exactly K vowels.

---

### Pattern 3: Count Subarrays with Fixed Bounds [🔥 Must Know]

**Count subarrays where the minimum equals minK and maximum equals maxK.**

```java
// LC 2444: Count Subarrays With Fixed Bounds
// Time: O(n), Space: O(1)
public long countSubarrays(int[] nums, int minK, int maxK) {
    long count = 0;
    int lastMin = -1, lastMax = -1, lastBad = -1;
    for (int i = 0; i < nums.length; i++) {
        if (nums[i] < minK || nums[i] > maxK) lastBad = i; // out of bounds: reset
        if (nums[i] == minK) lastMin = i;
        if (nums[i] == maxK) lastMax = i;
        // Valid subarrays end at i and start anywhere in [lastBad+1, min(lastMin, lastMax)]
        count += Math.max(0, Math.min(lastMin, lastMax) - lastBad);
    }
    return count;
}
```

💡 **Intuition:** For each position i, track the last position where minK appeared, where maxK appeared, and where an out-of-bounds element appeared. A valid subarray must include both lastMin and lastMax, and must not include lastBad. The number of valid start positions is `min(lastMin, lastMax) - lastBad` (if positive).

---

## 3. Complexity Summary

| Pattern | Time | Space | Key Insight |
|---------|------|-------|-------------|
| Prefix Sum + Monotonic Deque | O(n) | O(n) | Convert sums to prefix differences, deque finds optimal start |
| Exactly K = atMost(K) - atMost(K-1) | O(n) | O(n) | Decompose hard counting into two easy sliding windows |
| Fixed Bounds | O(n) | O(1) | Track last positions of min, max, and out-of-bounds |

---

## 4. Revision Checklist

- [ ] Negative numbers break basic sliding window (sum not monotonic when shrinking)
- [ ] Prefix sum + monotonic deque: O(n) for shortest subarray with sum >= K
- [ ] Deque maintains increasing prefix sums. Poll front when valid. Poll back when current is smaller.
- [ ] Exactly K = atMost(K) - atMost(K-1) for "exactly K distinct" problems
- [ ] atMost(K) counts `right - left + 1` subarrays at each step
- [ ] Fixed bounds: track lastMin, lastMax, lastBad. Valid starts = min(lastMin, lastMax) - lastBad
- [ ] All advanced sliding window patterns are O(n) time

**Top 5 must-solve:**
1. Shortest Subarray with Sum at Least K (LC 862) [Hard] - Prefix sum + monotonic deque
2. Subarrays with K Different Integers (LC 992) [Hard] - atMost(K) - atMost(K-1)
3. Count Subarrays With Fixed Bounds (LC 2444) [Hard] - Track last positions
4. Max Value of Equation (LC 1499) [Hard] - Monotonic deque optimization
5. Count Number of Nice Subarrays (LC 1248) [Medium] - Exactly K odd = atMost(K) - atMost(K-1)

> 🔗 **See Also:** [01-dsa/02-two-pointers-sliding-window.md](02-two-pointers-sliding-window.md) for basic sliding window. [01-dsa/15-monotonic-stack-queue.md](15-monotonic-stack-queue.md) for monotonic deque fundamentals.
