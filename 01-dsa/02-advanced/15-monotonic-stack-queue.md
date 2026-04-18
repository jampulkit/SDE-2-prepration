> ⚠️ **[OPTIONAL] — Rarely asked at SDE-2 interviews. Skip unless you've mastered files 00-14.**

# Monotonic Stack & Monotonic Queue — Deep Dive

## 1. Foundation

**A monotonic stack/queue maintains elements in sorted order (increasing or decreasing). When a new element violates the order, elements are popped — each popped element has found its "answer." This enables O(n) solutions for "next greater/smaller" and "sliding window min/max" problems.**

💡 **Intuition:** A monotonic decreasing stack is like a line of people sorted by height (tallest at bottom). When a taller person arrives, everyone shorter leaves the line — they've found someone taller than them. The new person joins the line. At any point, the line is sorted by height.

## 2. Core Patterns

### Next Greater / Smaller Element (4 Variants)

```java
// Next Greater Element (right) — decreasing stack
public int[] nextGreater(int[] nums) {
    int n = nums.length;
    int[] result = new int[n];
    Arrays.fill(result, -1);
    Deque<Integer> stack = new ArrayDeque<>(); // stores indices
    for (int i = 0; i < n; i++) {
        while (!stack.isEmpty() && nums[i] > nums[stack.peek()]) {
            result[stack.pop()] = nums[i];
        }
        stack.push(i);
    }
    return result;
}

// Previous Smaller Element (left) — increasing stack
public int[] prevSmaller(int[] nums) {
    int n = nums.length;
    int[] result = new int[n];
    Arrays.fill(result, -1);
    Deque<Integer> stack = new ArrayDeque<>();
    for (int i = 0; i < n; i++) {
        while (!stack.isEmpty() && nums[stack.peek()] >= nums[i]) {
            stack.pop();
        }
        result[i] = stack.isEmpty() ? -1 : stack.peek(); // current top is prev smaller
        stack.push(i);
    }
    return result;
}
```

| Find | Stack Type | Pop When | What You Learn |
|------|-----------|----------|----------------|
| Next Greater (right) | Decreasing | `nums[i] > top` | Popped element's next greater = nums[i] |
| Next Smaller (right) | Increasing | `nums[i] < top` | Popped element's next smaller = nums[i] |
| Previous Greater (left) | Decreasing | `nums[i] >= top` | Current element's prev greater = new top |
| Previous Smaller (left) | Increasing | `nums[i] <= top` | Current element's prev smaller = new top |

### Contribution Technique [🔥 Must Know]

**For "Sum of Subarray Minimums" (LC 907): for each element, count how many subarrays it's the minimum of.**

```java
// LC 907: Sum of Subarray Minimums
public int sumSubarrayMins(int[] arr) {
    int n = arr.length, MOD = 1_000_000_007;
    int[] left = new int[n];  // distance to previous smaller (or equal)
    int[] right = new int[n]; // distance to next strictly smaller
    Deque<Integer> stack = new ArrayDeque<>();
    
    // Previous smaller or equal
    for (int i = 0; i < n; i++) {
        while (!stack.isEmpty() && arr[stack.peek()] >= arr[i]) stack.pop();
        left[i] = stack.isEmpty() ? i + 1 : i - stack.peek();
        stack.push(i);
    }
    
    stack.clear();
    // Next strictly smaller
    for (int i = n - 1; i >= 0; i--) {
        while (!stack.isEmpty() && arr[stack.peek()] > arr[i]) stack.pop();
        right[i] = stack.isEmpty() ? n - i : stack.peek() - i;
        stack.push(i);
    }
    
    long sum = 0;
    for (int i = 0; i < n; i++) {
        sum = (sum + (long) arr[i] * left[i] % MOD * right[i]) % MOD;
    }
    return (int) sum;
}
```

💡 **Intuition:** Element at index `i` is the minimum of `left[i] × right[i]` subarrays. `left[i]` = number of consecutive elements to the left that are ≥ arr[i]. `right[i]` = number to the right that are > arr[i]. The product gives the count of subarrays where arr[i] is the minimum.

### Sliding Window Maximum/Minimum (Monotonic Deque)

```java
// LC 239: Sliding Window Maximum — O(n)
public int[] maxSlidingWindow(int[] nums, int k) {
    int n = nums.length;
    int[] result = new int[n - k + 1];
    Deque<Integer> deque = new ArrayDeque<>(); // decreasing deque of indices
    
    for (int i = 0; i < n; i++) {
        while (!deque.isEmpty() && deque.peekFirst() <= i - k) deque.pollFirst(); // remove expired
        while (!deque.isEmpty() && nums[deque.peekLast()] <= nums[i]) deque.pollLast(); // remove smaller
        deque.offerLast(i);
        if (i >= k - 1) result[i - k + 1] = nums[deque.peekFirst()];
    }
    return result;
}
```

### Largest Rectangle in Histogram

```java
// LC 84: O(n) using increasing stack
public int largestRectangleArea(int[] heights) {
    Deque<Integer> stack = new ArrayDeque<>();
    int maxArea = 0, n = heights.length;
    for (int i = 0; i <= n; i++) {
        int h = (i == n) ? 0 : heights[i];
        while (!stack.isEmpty() && h < heights[stack.peek()]) {
            int height = heights[stack.pop()];
            int width = stack.isEmpty() ? i : i - stack.peek() - 1;
            maxArea = Math.max(maxArea, height * width);
        }
        stack.push(i);
    }
    return maxArea;
}
```

🎯 **Likely Follow-ups:**
- **Q:** Why is monotonic stack O(n) and not O(n²) even though there's a while loop inside a for loop?
  **A:** Each element is pushed onto the stack exactly once and popped at most once. Total push operations = n, total pop operations <= n. So the inner while loop across ALL iterations of the outer for loop does at most n pops total. This is amortized O(n).
- **Q:** When do you use a monotonic stack vs a monotonic deque?
  **A:** Stack: when you only need to look backward (next/previous greater/smaller). Deque: when you need sliding window min/max, because you need to remove expired elements from the front AND dominated elements from the back.
- **Q:** How do you handle duplicates in the contribution technique?
  **A:** Use strict inequality on one side and non-strict on the other. For "Sum of Subarray Minimums", use `>=` for previous smaller (left boundary) and `>` for next smaller (right boundary). This ensures each subarray is counted exactly once.

---

## 3. Complexity Summary

| Pattern | Time | Space | Key Insight |
|---------|------|-------|-------------|
| Next Greater/Smaller | O(n) | O(n) | Each element pushed and popped at most once |
| Contribution Technique | O(n) | O(n) | Count subarrays where element is min/max |
| Largest Rectangle in Histogram | O(n) | O(n) | Increasing stack, width from stack indices |
| Sliding Window Maximum | O(n) | O(k) | Monotonic deque, remove expired from front |
| Remove K Digits | O(n) | O(n) | Greedy: remove larger digits from left |

---

## 4. LeetCode Problem List

| # | Problem | LC # | Difficulty | Pattern |
|---|---------|------|-----------|---------|
| 1 | Daily Temperatures | 739 | Medium | Next greater with distance [🔥 Must Do] |
| 2 | Next Greater Element I/II | 496/503 | Easy/Medium | Basic monotonic stack [🔥 Must Do] |
| 3 | Largest Rectangle in Histogram | 84 | Hard | Increasing stack [🔥 Must Do] |
| 4 | Maximal Rectangle | 85 | Hard | Histogram per row [🔥 Must Do] |
| 5 | Trapping Rain Water | 42 | Hard | Stack approach [🔥 Must Do] |
| 6 | Sliding Window Maximum | 239 | Hard | Monotonic deque [🔥 Must Do] |
| 7 | Sum of Subarray Minimums | 907 | Medium | Contribution technique [🔥 Must Do] |
| 8 | Sum of Subarray Ranges | 2104 | Medium | Sum of max - sum of min |
| 9 | Remove K Digits | 402 | Medium | Greedy monotonic stack [🔥 Must Do] |
| 10 | 132 Pattern | 456 | Medium | Reverse decreasing stack |
| 11 | Online Stock Span | 901 | Medium | Previous greater |
| 12 | Car Fleet | 853 | Medium | Sort + stack |
| 13 | Shortest Subarray with Sum >= K | 862 | Hard | Monotonic deque + prefix sum |

**Top 5 must-solve:**
1. Largest Rectangle in Histogram (LC 84) [Hard] - Increasing stack, foundation for many problems
2. Sliding Window Maximum (LC 239) [Hard] - Monotonic deque
3. Sum of Subarray Minimums (LC 907) [Medium] - Contribution technique
4. Daily Temperatures (LC 739) [Medium] - Next greater element with distance
5. Trapping Rain Water (LC 42) [Hard] - Stack or two-pointer approach

---

## 5. Revision Checklist

- [ ] Monotonic stack: O(n) — each element pushed/popped at most once
- [ ] Next greater: decreasing stack. Next smaller: increasing stack.
- [ ] Store INDICES not values (need distance calculations)
- [ ] Contribution technique: element is min of `left[i] × right[i]` subarrays
- [ ] Monotonic deque: remove expired from front, remove dominated from back
- [ ] Histogram: increasing stack, width = `i - stack.peek() - 1`, sentinel at end
- [ ] Circular array: iterate 2n, use `i % n`

> 🔗 **See Also:** [01-dsa/03-stacks-queues.md](03-stacks-queues.md) Pattern 2 for basic monotonic stack. [01-dsa/02-two-pointers-sliding-window.md](02-two-pointers-sliding-window.md) Pattern 6 for sliding window with deque.
