> ✅ **[CORE] — Must-do for SDE-2 interviews.**

# Dynamic Programming

## 1. Foundation

**Dynamic Programming is an optimization technique that solves problems by breaking them into overlapping subproblems, solving each subproblem once, and storing the result — turning exponential brute force into polynomial time.**

Many problems have overlapping subproblems — the same computation is repeated many times in a recursive solution. DP eliminates this redundancy by storing results of subproblems, reducing exponential time to polynomial.

💡 **Intuition:** Imagine you're calculating the 50th Fibonacci number. The naive recursive approach computes `fib(48)` twice, `fib(47)` three times, `fib(46)` five times... and `fib(1)` about 2⁵⁰ times. That's like re-reading the same book chapter every time someone asks you about it. DP is like taking notes — compute each value once, write it down, and look it up when needed.

**When to use DP** [🔥 Must Know]:
1. **Optimal substructure:** The optimal solution to the problem contains optimal solutions to subproblems
2. **Overlapping subproblems:** The same subproblems are solved multiple times

**DP signals in problem statements:**
- "Minimum/maximum cost/profit/count"
- "How many ways to..."
- "Is it possible to..."
- "Longest/shortest subsequence/substring"
- "Can you reach...?"
- "Partition into subsets with property X"

**Two approaches:**

| Approach | Direction | Implementation | Pros | Cons |
|----------|-----------|---------------|------|------|
| Top-down (memoization) | Start from original problem, recurse down | Recursion + cache (HashMap or array) | Intuitive, only computes needed states | Recursion overhead, stack overflow risk |
| Bottom-up (tabulation) | Start from base cases, build up | Iterative + DP array | No recursion overhead, can optimize space | Must figure out iteration order |

💡 **Intuition — Top-down vs Bottom-up:**
- **Top-down:** "I don't know the answer to the big problem, so let me ask smaller problems." Like a manager delegating work — you start at the top and break it down.
- **Bottom-up:** "I know the answers to the smallest problems, so let me build up to the big one." Like building a wall — you start with the foundation and work up brick by brick.

In interviews, start with top-down (easier to think about), then convert to bottom-up if the interviewer asks for optimization.

**The DP framework (apply to EVERY problem)** [🔥 Must Know]:

1. **Define the state:** What does `dp[i]` (or `dp[i][j]`) represent? This is the hardest and most important step.
2. **Find the recurrence:** How does `dp[i]` relate to smaller subproblems?
3. **Identify base cases:** What are the trivial cases where you know the answer directly?
4. **Determine iteration order:** Which states must be computed first? (Bottom-up only)
5. **Optimize space** (if possible): Do you only need the previous row/state?

⚙️ **Under the Hood — How to Define the State:**
The state must capture ALL information needed to make the optimal decision at each step. If your recurrence doesn't work, you probably need more dimensions:
- Can't decide without knowing which items are used? → Add item dimension: `dp[i][...]`
- Can't decide without knowing remaining capacity? → Add capacity dimension: `dp[...][w]`
- Can't decide without knowing previous action? → Add state dimension: `dp[...][state]`

**Example — Fibonacci (to illustrate all four approaches):**

```java
// 1. Naive recursion — O(2^n) — overlapping subproblems
int fib(int n) {
    if (n <= 1) return n;
    return fib(n - 1) + fib(n - 2); // fib(3) computed MANY times
}

// 2. Top-down memoization — O(n) time, O(n) space
int[] memo;
int fib(int n) {
    if (n <= 1) return n;
    if (memo[n] != 0) return memo[n]; // already computed? return cached result
    return memo[n] = fib(n - 1) + fib(n - 2);
}

// 3. Bottom-up tabulation — O(n) time, O(n) space
int fib(int n) {
    if (n <= 1) return n;
    int[] dp = new int[n + 1];
    dp[0] = 0; dp[1] = 1;
    for (int i = 2; i <= n; i++) dp[i] = dp[i-1] + dp[i-2]; // build up from base cases
    return dp[n];
}

// 4. Space-optimized — O(n) time, O(1) space
int fib(int n) {
    if (n <= 1) return n;
    int prev2 = 0, prev1 = 1; // only need last two values
    for (int i = 2; i <= n; i++) {
        int curr = prev1 + prev2;
        prev2 = prev1;
        prev1 = curr;
    }
    return prev1;
}
```

```
Recursion tree for fib(5) — showing overlapping subproblems:

                    fib(5)
                   /      \
              fib(4)      fib(3)      ← fib(3) computed TWICE
             /    \       /    \
         fib(3)  fib(2) fib(2) fib(1) ← fib(2) computed THREE times
        /    \
    fib(2)  fib(1)

With memoization: each fib(k) computed only ONCE → O(n) total
```

🎯 **Likely Follow-ups:**
- **Q:** When would you prefer top-down over bottom-up?
  **A:** When (1) not all states are needed (sparse problems — top-down only computes reachable states), (2) the problem is easier to think about recursively, or (3) the iteration order for bottom-up is complex (e.g., interval DP).
- **Q:** When would you prefer bottom-up?
  **A:** When (1) you need space optimization (rolling array), (2) the recursion depth might cause stack overflow, or (3) you want to avoid function call overhead for performance-critical code.
- **Q:** How do you convert top-down to bottom-up?
  **A:** (1) The memo array becomes the DP table. (2) Base cases become initial values. (3) The recursive calls become loop iterations. (4) The iteration order is the reverse of the recursion order — compute dependencies before dependents.

> 🔗 **See Also:** [01-dsa/08-greedy-backtracking.md](08-greedy-backtracking.md) — greedy is sometimes a special case of DP where the locally optimal choice is globally optimal. [01-dsa/06-graphs.md](06-graphs.md) Pattern 3 — DP on DAGs uses topological sort to determine iteration order.

---

## 2. Core Patterns

### Pattern 1: 1D DP — Linear Sequence [🔥 Must Know]

**Process elements one at a time, making an optimal decision at each step based on previous results.**

**When to recognize it:** Problem involves a linear sequence (array, string) and asks for optimal value considering elements one at a time.

**State:** `dp[i]` = answer considering the first `i` elements (or ending at index `i`).

💡 **Intuition:** At each position, you have a choice (take or skip, jump 1 or 2 steps, etc.). The optimal answer at position `i` depends on the optimal answers at earlier positions. You're building the answer left to right, one element at a time.

**Example — LC 198: House Robber** [🔥 Must Do]

> Can't rob adjacent houses. Maximize total.

```java
public int rob(int[] nums) {
    int n = nums.length;
    if (n == 1) return nums[0];
    int prev2 = 0, prev1 = nums[0]; // prev2 = dp[i-2], prev1 = dp[i-1]
    for (int i = 1; i < n; i++) {
        int curr = Math.max(prev1, prev2 + nums[i]); // skip house i OR rob it
        prev2 = prev1;
        prev1 = curr;
    }
    return prev1;
}
```

**Recurrence:** `dp[i] = max(dp[i-1], dp[i-2] + nums[i])`
- `dp[i-1]`: skip house i (best we can do without it)
- `dp[i-2] + nums[i]`: rob house i (must skip i-1, so use dp[i-2])

**Dry run:** `nums = [2, 7, 9, 3, 1]`

```
i=0: prev2=0, prev1=2
i=1: curr = max(2, 0+7) = 7.  prev2=2, prev1=7
i=2: curr = max(7, 2+9) = 11. prev2=7, prev1=11
i=3: curr = max(11, 7+3) = 11. prev2=11, prev1=11
i=4: curr = max(11, 11+1) = 12. prev2=11, prev1=12

Answer: 12 (rob houses 0, 2, 4: 2+9+1=12)
```

**Example — LC 53: Maximum Subarray (Kadane's Algorithm)** [🔥 Must Do]

```java
public int maxSubArray(int[] nums) {
    int maxSum = nums[0], currSum = nums[0];
    for (int i = 1; i < nums.length; i++) {
        currSum = Math.max(nums[i], currSum + nums[i]); // start fresh or extend
        maxSum = Math.max(maxSum, currSum);
    }
    return maxSum;
}
```

💡 **Intuition — Kadane's:** At each position, you decide: "Is it better to extend the current subarray or start a new one here?" If the running sum is negative, starting fresh is always better — a negative prefix can only hurt.

**Example — LC 139: Word Break** [🔥 Must Do]

```java
public boolean wordBreak(String s, List<String> wordDict) {
    Set<String> words = new HashSet<>(wordDict);
    int n = s.length();
    boolean[] dp = new boolean[n + 1]; // dp[i] = can s[0..i-1] be segmented?
    dp[0] = true; // empty string can be segmented

    for (int i = 1; i <= n; i++) {
        for (int j = 0; j < i; j++) {
            if (dp[j] && words.contains(s.substring(j, i))) {
                dp[i] = true;
                break; // found one valid segmentation, no need to check more
            }
        }
    }
    return dp[n];
}
```

**Edge Cases:**
- ☐ Single element → return that element (house robber, max subarray)
- ☐ All negative numbers → Kadane's still works (picks the least negative)
- ☐ All zeros → return 0
- ☐ Circular array (House Robber II) → run twice: skip first house, skip last house

🎯 **Likely Follow-ups:**
- **Q:** How do you handle the circular variant (House Robber II)?
  **A:** Run House Robber twice: once on `nums[0..n-2]` (skip last), once on `nums[1..n-1]` (skip first). Take the max. This handles the constraint that first and last houses are adjacent.
- **Q:** Can Kadane's algorithm find the actual subarray, not just the sum?
  **A:** Yes — track the start index. When `currSum` resets (start fresh), update start to current index. When `maxSum` updates, record start and end indices.

---

### Pattern 2: 0/1 Knapsack [🔥 Must Know]

**Each item can be used at most once. For each item, decide: include it or exclude it. The key insight is iterating capacity in REVERSE to prevent using an item twice.**

**When to recognize it:** "Given items with weight/value, maximize value within capacity", "partition into two subsets", "target sum with subset".

💡 **Intuition:** Imagine packing a backpack for a hike. Each item has a weight and a value. You can either take an item or leave it (0/1 — no fractions). For each item, you ask: "Is my backpack better with or without this item?" The answer depends on what's already in the backpack — that's the subproblem.

**State:** `dp[i][w]` = max value using first `i` items with capacity `w`.

**Recurrence:** `dp[i][w] = max(dp[i-1][w], dp[i-1][w-weight[i]] + value[i])`
- `dp[i-1][w]`: skip item i
- `dp[i-1][w-weight[i]] + value[i]`: take item i (need capacity for it)

**Space optimization:** Since each row only depends on the previous row, use 1D array and iterate capacity in REVERSE.

```java
// 0/1 Knapsack — space optimized
public int knapsack(int[] weights, int[] values, int capacity) {
    int[] dp = new int[capacity + 1];
    for (int i = 0; i < weights.length; i++) {
        for (int w = capacity; w >= weights[i]; w--) { // REVERSE to avoid using item twice
            dp[w] = Math.max(dp[w], dp[w - weights[i]] + values[i]);
        }
    }
    return dp[capacity];
}
```

⚙️ **Under the Hood — Why Reverse Iteration Prevents Reuse:**

```
Forward iteration (WRONG for 0/1):
  Item: weight=3, value=4. dp = [0, 0, 0, 0, 0, 0, 0]
  w=3: dp[3] = max(0, dp[0]+4) = 4    → dp = [0, 0, 0, 4, 0, 0, 0]
  w=6: dp[6] = max(0, dp[3]+4) = 8    → WRONG! dp[3] already includes this item!
  We used the item TWICE (at w=3 and w=6).

Reverse iteration (CORRECT for 0/1):
  w=6: dp[6] = max(0, dp[3]+4) = 4    → dp[3] is still 0 (from previous row)
  w=3: dp[3] = max(0, dp[0]+4) = 4    → dp = [0, 0, 0, 4, 0, 0, 4]
  Each item used at most once ✓
```

**Example — LC 416: Partition Equal Subset Sum** [🔥 Must Do]

> Can we partition array into two subsets with equal sum?

```java
public boolean canPartition(int[] nums) {
    int total = 0;
    for (int n : nums) total += n;
    if (total % 2 != 0) return false; // odd sum → impossible

    int target = total / 2;
    boolean[] dp = new boolean[target + 1]; // dp[j] = can we make sum j?
    dp[0] = true; // empty subset has sum 0

    for (int num : nums) {
        for (int j = target; j >= num; j--) { // reverse: 0/1 knapsack
            dp[j] = dp[j] || dp[j - num]; // either already achievable, or achievable by adding num
        }
    }
    return dp[target];
}
```

**Dry run:** `nums = [1, 5, 11, 5]`, total = 22, target = 11

```
Initial: dp = [T, F, F, F, F, F, F, F, F, F, F, F]

num=1:  dp[1] = dp[1] || dp[0] = T
        dp = [T, T, F, F, F, F, F, F, F, F, F, F]

num=5:  dp[6] = dp[6] || dp[1] = T
        dp[5] = dp[5] || dp[0] = T
        dp = [T, T, F, F, F, T, T, F, F, F, F, F]

num=11: dp[11] = dp[11] || dp[0] = T  ← FOUND!
        dp = [T, T, F, F, F, T, T, F, F, F, F, T]

Return dp[11] = true ✓ (subset {11} and {1,5,5})
```

**Edge Cases:**
- ☐ Odd total sum → immediately return false
- ☐ Single element → can't partition (unless it's 0)
- ☐ All elements equal → partition possible if count is even
- ☐ Element larger than target → skip it (can't include)

🎯 **Likely Follow-ups:**
- **Q:** What if you need to find the actual subset, not just whether it's possible?
  **A:** Use a 2D DP table `dp[i][j]` and backtrack: if `dp[i][j]` is true and `dp[i-1][j]` is false, then item `i` was included. Walk backwards to reconstruct the subset.
- **Q:** What's the time complexity?
  **A:** O(n × target) where target = sum/2. This is pseudo-polynomial — polynomial in the value of the input, not the size. If sum is very large (e.g., 10⁹), this approach is too slow.
- **Q:** How does this relate to the NP-complete subset sum problem?
  **A:** Subset sum is NP-complete in general. The DP solution is pseudo-polynomial — it's efficient when the target sum is small relative to the input size. For very large sums, you'd need approximation algorithms.

---

### Pattern 3: Unbounded Knapsack

**Same as 0/1 knapsack, but items can be used unlimited times. The key difference: iterate capacity FORWARD (not reverse) to allow reuse.**

**When to recognize it:** Same as 0/1 knapsack but items can be used unlimited times. "Coin change", "cutting rod", "perfect squares".

```java
// LC 322: Coin Change [🔥 Must Do]
// Minimum number of coins to make amount
public int coinChange(int[] coins, int amount) {
    int[] dp = new int[amount + 1];
    Arrays.fill(dp, amount + 1); // "infinity" — use amount+1 (impossible to need more coins)
    dp[0] = 0; // 0 coins needed for amount 0

    for (int i = 1; i <= amount; i++) {
        for (int coin : coins) {
            if (coin <= i) {
                dp[i] = Math.min(dp[i], dp[i - coin] + 1); // use this coin + solve remaining
            }
        }
    }
    return dp[amount] > amount ? -1 : dp[amount];
}
```

⚠️ **Common Pitfall — Why `amount + 1` instead of `Integer.MAX_VALUE`:**
If you use `Integer.MAX_VALUE`, then `dp[i - coin] + 1` overflows to `Integer.MIN_VALUE`, giving wrong results. Using `amount + 1` is safe because you can never need more than `amount` coins (worst case: all coins are 1).

**LC 518: Coin Change II (count combinations):**

```java
public int change(int amount, int[] coins) {
    int[] dp = new int[amount + 1];
    dp[0] = 1; // one way to make amount 0: use no coins
    for (int coin : coins) {           // outer loop: coins
        for (int j = coin; j <= amount; j++) { // forward: unbounded (can reuse coin)
            dp[j] += dp[j - coin];
        }
    }
    return dp[amount];
}
```

⚙️ **Under the Hood — Loop Order for Combinations vs Permutations:**

```
Combinations (each set counted once): coins outer, amount inner
  coins = [1, 2], amount = 3
  Process coin=1: dp = [1, 1, 1, 1]  (only using 1s: {1,1,1})
  Process coin=2: dp = [1, 1, 2, 2]  (add ways using 2: {1,1,1}, {1,2})
  Answer: 2 combinations ✓

Permutations (order matters): amount outer, coins inner
  coins = [1, 2], amount = 3
  i=1: dp[1] = dp[0]+1 = 1  ({1})
  i=2: dp[2] = dp[1]+dp[0] = 2  ({1,1}, {2})
  i=3: dp[3] = dp[2]+dp[1] = 3  ({1,1,1}, {1,2}, {2,1})
  Answer: 3 permutations (includes {1,2} and {2,1} as different)
```

**Why coins-outer gives combinations:** By processing one coin at a time, we ensure that coin 1 is always considered before coin 2. So {1,2} is counted but {2,1} is not — we've imposed an ordering that eliminates duplicates.

🎯 **Likely Follow-ups:**
- **Q:** What if coins can only be used a limited number of times (bounded knapsack)?
  **A:** For each coin with limit `k`, you can either (1) treat it as `k` separate 0/1 items, or (2) use binary representation: split into items of size 1, 2, 4, ..., 2^j, remainder. This reduces the number of items from `k` to `log(k)`.
- **Q:** How do you reconstruct which coins were used?
  **A:** Track `parent[i]` = the coin used to reach amount `i`. Then backtrack from `parent[amount]` to reconstruct the solution.

---

### Pattern 4: Longest Common Subsequence (LCS) / 2D String DP [🔥 Must Know]

**Compare two strings character by character. If characters match, extend the previous diagonal result. If not, take the best of skipping either character.**

**When to recognize it:** Two strings/sequences, find longest common subsequence, edit distance, or interleaving.

**State:** `dp[i][j]` = answer for `s1[0..i-1]` and `s2[0..j-1]`.

💡 **Intuition:** Imagine aligning two DNA sequences. At each position, you either match the characters (great, extend the alignment) or skip one character from either sequence (try to find a better alignment later). The DP table explores all possible alignments efficiently.

```java
// LC 1143: Longest Common Subsequence [🔥 Must Do]
public int longestCommonSubsequence(String text1, String text2) {
    int m = text1.length(), n = text2.length();
    int[][] dp = new int[m + 1][n + 1]; // dp[0][*] and dp[*][0] are 0 (empty string)

    for (int i = 1; i <= m; i++) {
        for (int j = 1; j <= n; j++) {
            if (text1.charAt(i - 1) == text2.charAt(j - 1)) {
                dp[i][j] = dp[i - 1][j - 1] + 1; // characters match → extend diagonal
            } else {
                dp[i][j] = Math.max(dp[i - 1][j], dp[i][j - 1]); // skip one character
            }
        }
    }
    return dp[m][n];
}
```

**Dry run:** `text1 = "abcde"`, `text2 = "ace"`

```
    ""  a  c  e
""   0  0  0  0
a    0  1  1  1
b    0  1  1  1
c    0  1  2  2
d    0  1  2  2
e    0  1  2  3

LCS = 3 ("ace")
```

**Edit Distance (LC 72)** [🔥 Must Do]:

```java
public int minDistance(String word1, String word2) {
    int m = word1.length(), n = word2.length();
    int[][] dp = new int[m + 1][n + 1];

    for (int i = 0; i <= m; i++) dp[i][0] = i; // delete all chars from word1
    for (int j = 0; j <= n; j++) dp[0][j] = j; // insert all chars of word2

    for (int i = 1; i <= m; i++) {
        for (int j = 1; j <= n; j++) {
            if (word1.charAt(i - 1) == word2.charAt(j - 1)) {
                dp[i][j] = dp[i - 1][j - 1]; // characters match → no operation
            } else {
                dp[i][j] = 1 + Math.min(dp[i-1][j-1], // replace
                                Math.min(dp[i-1][j],    // delete from word1
                                         dp[i][j-1]));  // insert into word1
            }
        }
    }
    return dp[m][n];
}
```

⚙️ **Under the Hood — Three Operations Visualized:**

```
word1 = "horse", word2 = "ros"

dp[i-1][j-1] → Replace: change word1[i] to word2[j], then solve rest
dp[i-1][j]   → Delete:  remove word1[i], then match word1[0..i-2] with word2[0..j-1]
dp[i][j-1]   → Insert:  insert word2[j] into word1, then match word1[0..i-1] with word2[0..j-2]

Each operation costs 1, so we take the minimum.
```

🎯 **Likely Follow-ups:**
- **Q:** Can you optimize LCS to O(min(m,n)) space?
  **A:** Yes — since each row only depends on the previous row, use two 1D arrays (or one array with a variable for the diagonal). Always make the shorter string the "column" dimension.
- **Q:** How do you reconstruct the actual LCS, not just its length?
  **A:** Backtrack from `dp[m][n]`: if characters match, include it and go diagonal. If not, go in the direction of the larger value (up or left).
- **Q:** What's the relationship between LCS and edit distance?
  **A:** If you only allow insertions and deletions (no replacements), the edit distance = `m + n - 2 * LCS(s1, s2)`. With replacements, it's more complex.

> 🔗 **See Also:** [01-dsa/01-arrays-strings-hashing.md](01-arrays-strings-hashing.md) for string manipulation patterns. [02-system-design/problems/search-autocomplete.md](../02-system-design/problems/search-autocomplete.md) — edit distance is used for fuzzy matching in search.

---

### Pattern 5: Longest Increasing Subsequence (LIS)

**Find the longest subsequence where each element is strictly greater than the previous. The O(n²) DP is straightforward; the O(n log n) patience sorting approach is what interviewers want to see.**

**When to recognize it:** "Longest increasing/decreasing subsequence", "maximum number of envelopes", "longest chain".

**O(n²) DP:**

```java
// LC 300: Longest Increasing Subsequence [🔥 Must Do]
public int lengthOfLIS(int[] nums) {
    int n = nums.length;
    int[] dp = new int[n]; // dp[i] = LIS ending at index i
    Arrays.fill(dp, 1);    // every element is a subsequence of length 1
    int maxLen = 1;

    for (int i = 1; i < n; i++) {
        for (int j = 0; j < i; j++) {
            if (nums[j] < nums[i]) {
                dp[i] = Math.max(dp[i], dp[j] + 1); // extend j's subsequence with i
            }
        }
        maxLen = Math.max(maxLen, dp[i]);
    }
    return maxLen;
}
```

**O(n log n) with patience sorting** [🔥 Must Know]:

```java
public int lengthOfLIS(int[] nums) {
    List<Integer> tails = new ArrayList<>(); // tails[i] = smallest tail of IS of length i+1

    for (int num : nums) {
        int pos = Collections.binarySearch(tails, num);
        if (pos < 0) pos = -(pos + 1); // insertion point
        if (pos == tails.size()) tails.add(num);  // extends longest subsequence
        else tails.set(pos, num);                  // replaces with smaller tail
    }
    return tails.size();
}
```

💡 **Intuition — Patience Sorting:** Imagine playing solitaire. You place cards in piles: each card goes on the leftmost pile whose top card is ≥ the new card. If no such pile exists, start a new pile. The number of piles = LIS length. The `tails` array tracks the top card of each pile.

**Dry run:** `nums = [10, 9, 2, 5, 3, 7, 101, 18]`

```
10:  tails = [10]           (new pile)
9:   tails = [9]            (replace 10 with 9 — smaller tail for length 1)
2:   tails = [2]            (replace 9 with 2)
5:   tails = [2, 5]         (new pile — extends to length 2)
3:   tails = [2, 3]         (replace 5 with 3 — smaller tail for length 2)
7:   tails = [2, 3, 7]      (new pile — extends to length 3)
101: tails = [2, 3, 7, 101] (new pile — extends to length 4)
18:  tails = [2, 3, 7, 18]  (replace 101 with 18)

LIS length = 4 (e.g., [2, 3, 7, 101] or [2, 3, 7, 18])
```

⚠️ **Common Pitfall:** The `tails` array does NOT contain the actual LIS — it contains the smallest possible tail for each length. To reconstruct the actual LIS, you need to track parent pointers.

**Edge Cases:**
- ☐ Single element → LIS = 1
- ☐ Already sorted (increasing) → LIS = n
- ☐ Already sorted (decreasing) → LIS = 1
- ☐ All elements equal → LIS = 1 (strictly increasing)
- ☐ Duplicates → `Collections.binarySearch` finds exact match, replaces in place (correct for strict)

🎯 **Likely Follow-ups:**
- **Q:** How do you find the actual LIS, not just its length?
  **A:** Maintain a `parent` array where `parent[i]` = index of the previous element in the LIS ending at `i`. After finding the length, backtrack from the last element.
- **Q:** What about longest non-decreasing subsequence (allowing equal elements)?
  **A:** Change the binary search to find the first element strictly greater than `num` (use `upperBound` instead of `lowerBound`). In Java: use `Collections.binarySearch` and adjust for duplicates.
- **Q:** How does this extend to 2D (Russian Doll Envelopes)?
  **A:** Sort by width ascending, then by height DESCENDING (for same width). Then find LIS on heights. The descending sort for same width prevents using two envelopes with the same width.

---

### Pattern 6: DP on Grid

**Each cell's value depends on its neighbors (usually top and left). Process row by row, left to right.**

**When to recognize it:** 2D grid, find min/max path cost, number of paths, or unique paths.

```java
// LC 62: Unique Paths — space optimized to 1D
public int uniquePaths(int m, int n) {
    int[] dp = new int[n];
    Arrays.fill(dp, 1); // first row: all 1s (only one way to reach any cell in first row)
    for (int i = 1; i < m; i++) {
        for (int j = 1; j < n; j++) {
            dp[j] += dp[j - 1]; // dp[j] (from above) + dp[j-1] (from left)
        }
    }
    return dp[n - 1];
}
```

**LC 221: Maximal Square** [🔥 Must Do]:

```java
public int maximalSquare(char[][] matrix) {
    int m = matrix.length, n = matrix[0].length;
    int[][] dp = new int[m][n]; // dp[i][j] = side length of largest square ending at (i,j)
    int maxSide = 0;

    for (int i = 0; i < m; i++) {
        for (int j = 0; j < n; j++) {
            if (matrix[i][j] == '1') {
                if (i == 0 || j == 0) dp[i][j] = 1; // first row/col: max square is 1
                else dp[i][j] = Math.min(dp[i-1][j], Math.min(dp[i][j-1], dp[i-1][j-1])) + 1;
                maxSide = Math.max(maxSide, dp[i][j]);
            }
        }
    }
    return maxSide * maxSide; // area
}
```

💡 **Intuition — Maximal Square Recurrence:** A square of side `k` ending at `(i,j)` requires squares of side `k-1` ending at `(i-1,j)`, `(i,j-1)`, and `(i-1,j-1)`. The minimum of these three determines the largest square that can end at `(i,j)`. Think of it as: the square is limited by its weakest corner.

```
If dp values are:    Then dp[i][j] = min(2, 3, 2) + 1 = 3
  ... 2 3 ...
  ... 2 ? ...        The 3×3 square ending at ? is valid because
                     all three neighbors support at least a 2×2 square.
```

---

### Pattern 7: Interval DP

**Solve problems on intervals [i..j] by trying every possible split point k, combining the results of [i..k] and [k..j].**

**When to recognize it:** "Burst balloons", "matrix chain multiplication", "minimum cost to merge stones" — problems where you combine adjacent intervals.

**State:** `dp[i][j]` = answer for the subarray/interval `[i..j]`.

**Iteration:** Enumerate interval length (small to large), then start point, then split point.

💡 **Intuition:** Think of merging piles of stones. You can only merge adjacent piles. The cost depends on which piles you merge first. Interval DP tries every possible "last merge" and picks the cheapest.

```java
// LC 312: Burst Balloons [🔥 Must Do]
public int maxCoins(int[] nums) {
    int n = nums.length;
    int[] arr = new int[n + 2]; // pad with 1s at boundaries
    arr[0] = arr[n + 1] = 1;
    for (int i = 0; i < n; i++) arr[i + 1] = nums[i];

    int[][] dp = new int[n + 2][n + 2];
    // dp[i][j] = max coins from bursting all balloons in (i, j) exclusive

    for (int len = 1; len <= n; len++) {           // interval length
        for (int i = 0; i + len + 1 <= n + 1; i++) { // start point
            int j = i + len + 1;                      // end point
            for (int k = i + 1; k < j; k++) {         // k = LAST balloon to burst in (i,j)
                dp[i][j] = Math.max(dp[i][j],
                    dp[i][k] + dp[k][j] + arr[i] * arr[k] * arr[j]);
            }
        }
    }
    return dp[0][n + 1];
}
```

⚙️ **Under the Hood — "Last to Burst" Trick:**
The key insight is thinking about which balloon is burst LAST in the interval, not first. If balloon `k` is the last one burst in interval `(i, j)`, then at that point, only balloons `i` and `j` are its neighbors (everything else is already burst). So the coins from bursting `k` last = `arr[i] * arr[k] * arr[j]`. The subproblems `dp[i][k]` and `dp[k][j]` are independent because `k` hasn't been burst yet when they're solved.

---

### Pattern 8: State Machine DP

**Model the problem as a finite state machine where each state represents a condition (holding stock, in cooldown, etc.) and transitions happen at each time step.**

**When to recognize it:** "Buy and sell stock with constraints" — problems with multiple states (holding, not holding, cooldown).

💡 **Intuition:** Think of yourself as being in one of several "modes" at each day. In the stock problem: you're either holding a stock, just sold (cooldown), or resting. Each day, you transition between modes based on your action (buy, sell, rest). The DP tracks the best profit in each mode.

```java
// LC 309: Best Time to Buy and Sell Stock with Cooldown [🔥 Must Do]
public int maxProfit(int[] prices) {
    int n = prices.length;
    int held = -prices[0]; // holding stock (bought today or before)
    int sold = 0;          // just sold (entering cooldown)
    int rest = 0;          // not holding, not in cooldown (free to buy)

    for (int i = 1; i < n; i++) {
        int newHeld = Math.max(held, rest - prices[i]);  // keep holding OR buy today
        int newSold = held + prices[i];                   // sell today
        int newRest = Math.max(rest, sold);               // continue resting OR exit cooldown
        held = newHeld; sold = newSold; rest = newRest;
    }
    return Math.max(sold, rest); // best is either just sold or resting
}
```

```
State machine diagram:

  ┌──────────┐    sell     ┌──────────┐   cooldown   ┌──────────┐
  │  HELD    │ ──────────→ │   SOLD   │ ──────────→  │   REST   │
  │ (holding)│             │(cooldown)│               │  (free)  │
  └──────────┘             └──────────┘               └──────────┘
       ↑  │                                                │  ↑
       │  └── hold ──────────────────────────────────────┘  │
       │                        buy                         │
       └────────────────────────────────────────────────────┘
                              rest
```

**Generalized stock problems:**

| Problem | States | Key Constraint |
|---------|--------|---------------|
| Buy/Sell I (LC 121) | One transaction max | Track min price |
| Buy/Sell II (LC 122) | Unlimited transactions | Greedy: buy every valley, sell every peak |
| Buy/Sell III (LC 123) | At most 2 transactions | 4 states: buy1, sell1, buy2, sell2 |
| Buy/Sell IV (LC 188) | At most k transactions | 2k states: buy[j], sell[j] for j=1..k |
| With Cooldown (LC 309) | Cooldown after sell | 3 states: held, sold, rest |
| With Fee (LC 714) | Transaction fee | 2 states: held, cash. Subtract fee on sell. |

🎯 **Likely Follow-ups:**
- **Q:** How do you handle "at most k transactions"?
  **A:** Use `buy[j]` and `sell[j]` for j = 1 to k. `buy[j] = max(buy[j], sell[j-1] - price)`, `sell[j] = max(sell[j], buy[j] + price)`. When k ≥ n/2, it degenerates to unlimited transactions (use greedy).


---

## 3. Patterns Summary Table

| # | Pattern | When to Use | State | Time | Space | Example |
|---|---------|------------|-------|------|-------|---------|
| 1 | 1D Linear | Sequence, rob houses, climb stairs | dp[i] = answer for first i | O(n) | O(1)* | House Robber (LC 198) |
| 2 | 0/1 Knapsack | Subset sum, partition, target | dp[w] = achievable with capacity w | O(n×W) | O(W) | Partition Equal Subset (LC 416) |
| 3 | Unbounded Knapsack | Coin change, unlimited items | dp[w] = min/count for amount w | O(n×W) | O(W) | Coin Change (LC 322) |
| 4 | LCS / 2D String | Two strings, edit distance | dp[i][j] = answer for s1[0..i], s2[0..j] | O(m×n) | O(m×n)* | Edit Distance (LC 72) |
| 5 | LIS | Longest increasing subsequence | dp[i] = LIS ending at i | O(n log n) | O(n) | LIS (LC 300) |
| 6 | Grid DP | Paths, min cost on grid | dp[i][j] = answer at cell (i,j) | O(m×n) | O(n)* | Unique Paths (LC 62) |
| 7 | Interval DP | Merge/burst intervals | dp[i][j] = answer for interval [i,j] | O(n³) | O(n²) | Burst Balloons (LC 312) |
| 8 | State Machine | Stock problems with states | Multiple variables per step | O(n) | O(1) | Stock Cooldown (LC 309) |

*after space optimization

**Pattern Selection Flowchart:**

```
DP problem?
├── Linear sequence (1D)?
│   ├── Take/skip decision → Pattern 1: 1D Linear (House Robber)
│   ├── Subset with target sum → Pattern 2: 0/1 Knapsack
│   ├── Unlimited items → Pattern 3: Unbounded Knapsack
│   ├── Longest increasing → Pattern 5: LIS
│   └── Multiple states per step → Pattern 8: State Machine
├── Two strings?
│   └── Pattern 4: LCS / 2D String DP
├── 2D grid?
│   └── Pattern 6: Grid DP
└── Combine intervals?
    └── Pattern 7: Interval DP
```

---

## 4. LeetCode Problem List (Must-Solve)

### Easy

| # | Problem Name | LC # | Pattern(s) | Why Important |
|---|-------------|------|-----------|---------------|
| 1 | Climbing Stairs | 70 | 1D Linear | [🔥 Must Do] Fibonacci variant |
| 2 | Min Cost Climbing Stairs | 746 | 1D Linear | Cost variant of climbing |
| 3 | House Robber | 198 | 1D Linear | [🔥 Must Do] Skip/take pattern |
| 4 | Maximum Subarray | 53 | Kadane's | [🔥 Must Do] Kadane's algorithm |
| 5 | Best Time to Buy and Sell Stock | 121 | Single pass | Track min price |
| 6 | Pascal's Triangle | 118 | Grid DP | Simple 2D construction |
| 7 | Counting Bits | 338 | Bit DP | dp[i] = dp[i>>1] + (i&1) |
| 8 | Is Subsequence | 392 | Two pointers / DP | Simple matching |

### Medium

| # | Problem Name | LC # | Pattern(s) | Why Important |
|---|-------------|------|-----------|---------------|
| 1 | House Robber II | 213 | 1D Linear (circular) | [🔥 Must Do] Run twice: skip first or last |
| 2 | Coin Change | 322 | Unbounded Knapsack | [🔥 Must Do] Classic unbounded |
| 3 | Coin Change II | 518 | Unbounded Knapsack | [🔥 Must Do] Count combinations |
| 4 | Longest Increasing Subsequence | 300 | LIS | [🔥 Must Do] O(n log n) solution |
| 5 | Longest Common Subsequence | 1143 | LCS | [🔥 Must Do] Classic 2D DP |
| 6 | Edit Distance | 72 | 2D String DP | [🔥 Must Do] Three operations |
| 7 | Partition Equal Subset Sum | 416 | 0/1 Knapsack | [🔥 Must Do] Subset sum |
| 8 | Target Sum | 494 | 0/1 Knapsack | Count ways to reach target |
| 9 | Unique Paths | 62 | Grid DP | [🔥 Must Do] Basic grid DP |
| 10 | Minimum Path Sum | 64 | Grid DP | Grid with costs |
| 11 | Decode Ways | 91 | 1D Linear | [🔥 Must Do] String decoding |
| 12 | Word Break | 139 | 1D DP + HashSet | [🔥 Must Do] Dictionary matching |
| 13 | Longest Palindromic Subsequence | 516 | 2D DP | Reverse + LCS |
| 14 | Palindromic Substrings | 647 | 2D DP / expand | Count palindromes |
| 15 | Maximum Product Subarray | 152 | 1D (track min & max) | [🔥 Must Do] Negative handling |
| 16 | Jump Game | 55 | Greedy / DP | Can you reach the end? |
| 17 | Jump Game II | 45 | Greedy / DP | Min jumps to reach end |
| 18 | Best Time to Buy and Sell Stock with Cooldown | 309 | State Machine | [🔥 Must Do] Three states |
| 19 | Best Time to Buy and Sell Stock with Transaction Fee | 714 | State Machine | Two states + fee |
| 20 | Interleaving String | 97 | 2D DP | Two strings interleave |
| 21 | Ones and Zeroes | 474 | 2D Knapsack | Two constraints |
| 22 | Longest String Chain | 1048 | LIS variant | Sort + DP |
| 23 | Number of Longest Increasing Subsequence | 673 | LIS + counting | Track count alongside length |
| 24 | Maximal Square | 221 | Grid DP | [🔥 Must Do] dp[i][j] = min(top, left, diag) + 1 |
| 25 | Triangle | 120 | Grid DP (bottom-up) | Bottom-up on triangle |
| 26 | Perfect Squares | 279 | Unbounded Knapsack | Min squares summing to n |
| 27 | Combination Sum IV | 377 | Unbounded (permutations) | Amount outer loop |
| 28 | Delete Operation for Two Strings | 583 | LCS variant | LCS → min deletions |
| 29 | Distinct Subsequences | 115 | 2D String DP | Count subsequences |
| 30 | Minimum Cost for Tickets | 983 | 1D DP | Three ticket types |

### Hard

| # | Problem Name | LC # | Pattern(s) | Why Important |
|---|-------------|------|-----------|---------------|
| 1 | Burst Balloons | 312 | Interval DP | [🔥 Must Do] Classic interval DP |
| 2 | Longest Valid Parentheses | 32 | 1D DP / Stack | DP or stack approach |
| 3 | Regular Expression Matching | 10 | 2D String DP | [🔥 Must Do] Wildcard matching |
| 4 | Wildcard Matching | 44 | 2D String DP | Simpler than regex |
| 5 | Best Time to Buy and Sell Stock III | 123 | State Machine | At most 2 transactions |
| 6 | Best Time to Buy and Sell Stock IV | 188 | State Machine | At most k transactions |
| 7 | Palindrome Partitioning II | 132 | 1D DP + palindrome check | Min cuts |
| 8 | Word Break II | 140 | DP + backtracking | All valid sentences |
| 9 | Russian Doll Envelopes | 354 | LIS (2D) | Sort + LIS on second dim |
| 10 | Minimum Difficulty of a Job Schedule | 1335 | Interval DP | Partition into d days |
| 11 | Dungeon Game | 174 | Grid DP (reverse) | Bottom-right to top-left |
| 12 | Maximal Rectangle | 85 | Histogram + DP | Row-by-row histogram |
| 13 | Distinct Subsequences | 115 | 2D String DP | Count matching subsequences |
| 14 | Cherry Pickup | 741 | 3D DP | Two paths simultaneously |
| 15 | Frog Jump | 403 | DP + HashMap | State = (stone, last jump) |

---

## 5. Interview Strategy

**How to approach a DP problem in an interview:**

1. **Recognize it's DP.** Look for optimization (min/max), counting, or feasibility on sequences/grids. If brute force is exponential and subproblems overlap → DP.
2. **Start with brute force recursion.** Draw the recursion tree. Identify overlapping subproblems. This shows the interviewer your thought process.
3. **Define the state clearly.** Say it out loud: "dp[i] represents the maximum profit considering the first i houses."
4. **Write the recurrence.** Express dp[i] in terms of smaller subproblems. Explain WHY.
5. **Identify base cases.** What are the trivial answers?
6. **Code top-down first** (easier to get right), then convert to bottom-up if asked.
7. **Optimize space** if possible (rolling array, two variables).

**Communication template:**
> "I'll define dp[i] as [meaning]. The recurrence is dp[i] = [formula] because [reasoning]. The base case is dp[0] = [value]. I'll iterate from [start] to [end]. Time is O([complexity]), space is O([complexity])."

**Sample dialogue:**
```
You: "This looks like a DP problem because we're asked for the minimum cost,
     and at each step we have choices that affect future options.

     Let me start with brute force: at each step, I can take 1 or 2 stairs.
     That gives me a recursion tree with overlapping subproblems — fib(3) is
     computed multiple times.

     I'll define dp[i] = minimum cost to reach step i. The recurrence is
     dp[i] = min(dp[i-1] + cost[i-1], dp[i-2] + cost[i-2]) because I can
     arrive from one step below or two steps below.

     Base cases: dp[0] = 0, dp[1] = 0 (starting positions are free).
     I only need the last two values, so I can optimize to O(1) space."
```

**Common mistakes:**
- Wrong state definition (too few dimensions → can't capture all info needed for the decision)
- Wrong base case (off-by-one, missing the empty case)
- Wrong iteration order (bottom-up must compute dependencies first)
- Off-by-one in indices (especially with 1-indexed dp arrays for string problems)
- Not considering negative numbers (affects knapsack, product problems)
- Forgetting to handle the empty case (dp[0] is often a special case)
- Using `Integer.MAX_VALUE` as infinity → overflow when adding 1

💥 **What Can Go Wrong in Interviews:**

| Mistake | Impact | Prevention |
|---------|--------|------------|
| Can't define the state | Stuck, can't proceed | Practice: for each problem, write "dp[i] means..." before coding |
| Wrong recurrence | Wrong answer | Verify with a small example (n=3 or 4) before coding |
| Wrong base case | Off-by-one errors | Think: "What's the answer for the smallest possible input?" |
| Wrong loop direction | Uses item twice (knapsack) | 0/1 = reverse, unbounded = forward |
| Integer overflow | Wrong answer for large inputs | Use `amount + 1` instead of `MAX_VALUE` for infinity |
| Forget space optimization | Interviewer asks for it | After coding, mention: "I can optimize space to O(n) / O(1) by..." |

---

## 6. Edge Cases & Pitfalls

**General DP edge cases:**
- ☐ Empty input → usually return 0 or true (base case)
- ☐ Single element → often trivial
- ☐ All negative numbers → affects max subarray, max product
- ☐ Zero in product problems → resets the product
- ☐ Very large values → integer overflow (use `long`)
- ☐ Knapsack with capacity 0 → dp[0] = 0 or true
- ☐ Coin change with amount 0 → answer is 0 coins (not impossible)

**Java-specific pitfalls:**

```java
// PITFALL 1: Integer overflow with MAX_VALUE
int[] dp = new int[n];
Arrays.fill(dp, Integer.MAX_VALUE);
dp[i] = dp[i - coin] + 1; // if dp[i-coin] is MAX_VALUE, this OVERFLOWS to MIN_VALUE!
// FIX: use amount + 1 as "infinity", or check before adding:
if (dp[i - coin] != Integer.MAX_VALUE) dp[i] = Math.min(dp[i], dp[i - coin] + 1);

// PITFALL 2: 2D array initialization
int[][] dp = new int[m + 1][n + 1]; // all zeros by default ✓
boolean[][] dp = new boolean[m + 1][n + 1]; // all false by default ✓
// But if you need -1 or MAX_VALUE, you must fill each row:
for (int[] row : dp) Arrays.fill(row, -1);

// PITFALL 3: Modifying input array as DP table
// Works for min path sum (modify grid in-place), but mention it:
// "I'm using the input grid as my DP table to save space. In production,
//  I'd use a separate array to preserve the original data."

// PITFALL 4: String DP indexing
// dp[i][j] corresponds to s1[0..i-1] and s2[0..j-1] (1-indexed DP, 0-indexed string)
// dp[0][*] and dp[*][0] are base cases (empty string)
// Access string chars with s.charAt(i - 1), not s.charAt(i)
```

---

## 7. Connections to Other Topics

| This Pattern | Connects To | How |
|-------------|-------------|-----|
| 1D DP | [01-dsa/08-greedy-backtracking.md](08-greedy-backtracking.md) | Some DP problems have greedy solutions (jump game, activity selection) |
| Knapsack | [01-dsa/08-greedy-backtracking.md](08-greedy-backtracking.md) | Knapsack is optimized subset enumeration; backtracking explores all subsets |
| LCS / Edit Distance | [01-dsa/01-arrays-strings-hashing.md](01-arrays-strings-hashing.md) | String manipulation, diff algorithms |
| LIS | [01-dsa/11-sorting-searching.md](11-sorting-searching.md) | O(n log n) LIS uses binary search |
| Grid DP | [01-dsa/06-graphs.md](06-graphs.md) | Grid DP = shortest path in a DAG (edges only go right/down) |
| Interval DP | Divide and conquer | Split interval at every point, combine results |
| State machine | [05-java/03-concurrency-multithreading.md](../05-java/03-concurrency-multithreading.md) | Finite state machines model thread states |
| Tree DP | [01-dsa/05-trees.md](05-trees.md) | DP on tree structure (house robber III, diameter) |
| DP on DAG | [01-dsa/06-graphs.md](06-graphs.md) | Process nodes in topological order for DP |
| Prefix sum | [01-dsa/01-arrays-strings-hashing.md](01-arrays-strings-hashing.md) | Prefix sum is a 1D DP concept |
| Knapsack | [02-system-design/05-estimation-math.md](../02-system-design/05-estimation-math.md) | Resource allocation problems in system design |
| Edit distance | [02-system-design/problems/search-autocomplete.md](../02-system-design/problems/search-autocomplete.md) | Fuzzy matching, spell correction |

---

## 8. Revision Checklist

**DP framework (apply to every problem):**
- [ ] Define state: what does dp[i] (or dp[i][j]) represent?
- [ ] Recurrence: how does dp[i] relate to smaller subproblems?
- [ ] Base cases: what are the trivial answers?
- [ ] Iteration order: which states must be computed first?
- [ ] Space optimization: can you use 1D instead of 2D? Two variables instead of 1D?

**Pattern recognition:**
- [ ] "Min/max cost" + sequence → 1D DP
- [ ] "Subset sum" / "partition" / "target" → 0/1 Knapsack (reverse loop)
- [ ] "Unlimited items" / "coin change" → Unbounded Knapsack (forward loop)
- [ ] Two strings → 2D DP (LCS / edit distance)
- [ ] "Longest increasing" → LIS (O(n log n) with binary search)
- [ ] Grid paths → Grid DP
- [ ] "Burst/merge intervals" → Interval DP (O(n³))
- [ ] "Buy/sell stock with constraints" → State Machine DP
- [ ] "How many ways" + order matters → Permutations (amount outer)
- [ ] "How many ways" + order doesn't matter → Combinations (items outer)

**Key recurrences to memorize:**
- [ ] House Robber: `dp[i] = max(dp[i-1], dp[i-2] + nums[i])`
- [ ] Kadane's: `currSum = max(nums[i], currSum + nums[i])`
- [ ] Coin Change (min): `dp[i] = min(dp[i], dp[i-coin] + 1)` for each coin
- [ ] Coin Change II (count): `dp[j] += dp[j - coin]` (coins outer for combinations)
- [ ] LCS: match → `dp[i-1][j-1]+1`, no match → `max(dp[i-1][j], dp[i][j-1])`
- [ ] Edit Distance: match → `dp[i-1][j-1]`, no match → `1 + min(replace, delete, insert)`
- [ ] LIS (binary search): maintain `tails` array, binary search for insertion point
- [ ] 0/1 Knapsack: reverse loop. Unbounded: forward loop.
- [ ] Maximal Square: `dp[i][j] = min(top, left, diag) + 1`
- [ ] Burst Balloons: `dp[i][j] = max(dp[i][k] + dp[k][j] + arr[i]*arr[k]*arr[j])` for k in (i,j)

**Critical details:**
- [ ] 0/1 Knapsack: iterate capacity in REVERSE (prevents item reuse)
- [ ] Unbounded Knapsack: iterate capacity FORWARD (allows item reuse)
- [ ] Combinations: items outer loop. Permutations: amount outer loop.
- [ ] Use `amount + 1` as infinity, NOT `Integer.MAX_VALUE` (overflow risk)
- [ ] String DP: `dp[i][j]` uses 1-indexed, access string with `charAt(i-1)`
- [ ] LIS `tails` array is NOT the actual LIS — it's the smallest tails per length
- [ ] Interval DP: iterate by length (small to large), then start, then split point
- [ ] State machine: draw the state diagram first, then code transitions

**Top 12 must-solve:**
1. House Robber (LC 198) [Medium] — 1D skip/take
2. Coin Change (LC 322) [Medium] — Unbounded knapsack
3. Longest Common Subsequence (LC 1143) [Medium] — 2D string DP
4. Edit Distance (LC 72) [Medium] — Three operations
5. Longest Increasing Subsequence (LC 300) [Medium] — O(n log n) patience sorting
6. Partition Equal Subset Sum (LC 416) [Medium] — 0/1 knapsack
7. Word Break (LC 139) [Medium] — 1D DP + dictionary
8. Maximum Subarray / Kadane's (LC 53) [Medium] — Running sum decision
9. Unique Paths (LC 62) [Medium] — Grid DP
10. Decode Ways (LC 91) [Medium] — 1D string DP
11. Maximal Square (LC 221) [Medium] — Grid DP with min of 3 neighbors
12. Burst Balloons (LC 312) [Hard] — Interval DP

---

## 📋 Suggested New Documents

### 1. DP on Trees
- **Placement**: `01-dsa/12-dp-on-trees.md`
- **Why needed**: Tree DP (House Robber III, Binary Tree Maximum Path Sum, tree diameter, tree coloring) is a distinct pattern that combines tree traversal with DP. Currently split between the trees doc and this doc without dedicated coverage.
- **Key subtopics**: Rerooting technique, tree DP with states (rob/not-rob), tree diameter as DP, subtree aggregation, tree knapsack

### 2. Bitmask DP
- **Placement**: `01-dsa/12-bitmask-dp.md`
- **Why needed**: Problems like "Shortest Path Visiting All Nodes" (LC 847), "Partition to K Equal Sum Subsets" (LC 698), and Traveling Salesman use bitmasks to represent subsets in DP states. This is a distinct and frequently tested pattern at SDE-2 level.
- **Key subtopics**: Bitmask basics for subset representation, TSP with bitmask DP, assignment problems, subset enumeration with bitmasks, profile DP
