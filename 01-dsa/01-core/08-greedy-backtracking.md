> ✅ **[CORE] — Must-do for SDE-2 interviews.**

# Greedy & Backtracking

## 1. Foundation

### Greedy

**A greedy algorithm makes the locally optimal choice at each step, hoping it leads to the globally optimal solution. When it works, it's simpler and faster than DP — but it doesn't always work.**

Some optimization problems have the property that making the locally optimal choice at each step leads to the globally optimal solution. When this works, greedy is simpler and faster than DP.

💡 **Intuition:** Imagine you're making change for $0.67 using US coins (25¢, 10¢, 5¢, 1¢). Greedy says: always pick the largest coin that fits. 25+25+10+5+1+1 = 6 coins. This happens to be optimal for US denominations. But for coins [1, 3, 4] and target 6, greedy picks 4+1+1 = 3 coins, while optimal is 3+3 = 2 coins. Greedy fails because the locally best choice (pick 4) blocks the globally best solution.

**When greedy works** [🔥 Must Know]:
1. **Greedy choice property:** A locally optimal choice leads to a globally optimal solution
2. **Optimal substructure:** Optimal solution contains optimal solutions to subproblems

**When greedy DOESN'T work:** When a locally optimal choice can lead to a globally suboptimal solution. Classic counterexample: coin change with denominations [1, 3, 4] and target 6 — greedy picks 4+1+1=3 coins, but optimal is 3+3=2 coins. When in doubt, use DP.

**How to verify greedy works:**
- **Exchange argument:** Show that swapping any non-greedy choice for the greedy choice doesn't worsen the solution
- **Recognize a known pattern:** Activity selection, Huffman coding, fractional knapsack
- **In interviews:** State your greedy strategy, explain why it works intuitively, and mention when it might fail

**Greedy vs DP — Decision Framework:**

| Signal | Greedy | DP |
|--------|--------|-----|
| Can prove local = global? | ✅ Use greedy | — |
| Counterexample exists? | ❌ Don't use | ✅ Use DP |
| Need to explore all options? | ❌ | ✅ |
| Problem has "minimum/maximum" + choices? | Try greedy first | Fall back to DP |

🎯 **Likely Follow-ups:**
- **Q:** How do you prove a greedy algorithm is correct?
  **A:** The standard technique is the "exchange argument": assume an optimal solution that differs from the greedy solution. Show that you can swap one non-greedy choice for the greedy choice without worsening the result. By induction, the greedy solution is optimal.
- **Q:** Can you give an example where greedy fails but DP works?
  **A:** 0/1 Knapsack. Greedy by value/weight ratio doesn't work because you can't take fractions. Example: items [(weight=10, value=60), (weight=20, value=100), (weight=30, value=120)], capacity=50. Greedy picks item 1 (ratio 6) + item 2 (ratio 5) = 160. Optimal is item 2 + item 3 = 220.

> 🔗 **See Also:** [01-dsa/07-dynamic-programming.md](07-dynamic-programming.md) — DP is the fallback when greedy doesn't work.

### Backtracking

**Backtracking is DFS with pruning — you explore all possible solutions by making choices, recursing, and undoing choices when they lead to dead ends.**

When you need to explore all possible solutions (combinations, permutations, subsets) or find a solution satisfying constraints (N-Queens, Sudoku). Backtracking is DFS with pruning — you abandon a path as soon as you know it can't lead to a valid solution.

💡 **Intuition:** Think of navigating a maze. At each fork, you pick a direction and keep going. If you hit a dead end, you backtrack to the last fork and try a different direction. You mark paths you've tried so you don't repeat them. Pruning is like having a map that tells you "this direction definitely leads to a dead end" — you skip it entirely.

**Backtracking = recursion + choice + undo:**
1. Make a choice
2. Recurse (explore consequences of that choice)
3. Undo the choice (backtrack — try the next option)

**Backtracking template** [🔥 Must Know]:

```java
void backtrack(List<List<Integer>> result, List<Integer> current, /* params */) {
    if (/* base case — found a valid/complete solution */) {
        result.add(new ArrayList<>(current)); // COPY current, don't add reference!
        return;
    }

    for (/* each candidate choice */) {
        if (/* pruning condition — skip invalid choices */) continue;

        current.add(choice);                                    // 1. CHOOSE
        backtrack(result, current, /* updated params */);       // 2. EXPLORE
        current.remove(current.size() - 1);                     // 3. UNCHOOSE
    }
}
```

⚠️ **Common Pitfall — Why `new ArrayList<>(current)`:** `current` is mutated throughout recursion. If you add the reference directly, all entries in `result` will point to the same (eventually empty) list. You must copy it.

```java
// WRONG — all entries in result point to the same list
result.add(current); // after backtracking completes, current is empty → all entries are []

// CORRECT — each entry is an independent copy
result.add(new ArrayList<>(current));
```

**Three types of backtracking problems:**

| Type | What You Generate | Start Index | Used Array | Example |
|------|------------------|-------------|------------|---------|
| Subsets | All subsets | `start` (avoid duplicates) | No | LC 78 |
| Permutations | All orderings | Always 0 | Yes (`used[]`) | LC 46 |
| Combinations | Subsets with constraint | `start` | No | LC 39 |

> 🔗 **See Also:** [01-dsa/06-graphs.md](06-graphs.md) Pattern 2 — DFS on graphs is the same concept as backtracking. [01-dsa/05-trees.md](05-trees.md) — tree DFS is backtracking without the "undo" step (tree structure means no revisiting).

---

## 2. Core Patterns

### Pattern 1: Greedy — Interval Scheduling [🔥 Must Know]

**Sort intervals by end time. Always pick the interval that ends earliest — this leaves the most room for future intervals.**

**When to recognize it:** "Maximum number of non-overlapping intervals", "minimum number of intervals to remove", "meeting rooms", "minimum arrows to burst balloons".

💡 **Intuition:** Imagine scheduling meetings in a conference room. You want to fit as many meetings as possible. The greedy strategy: always pick the meeting that ends earliest. Why? It frees up the room as soon as possible, maximizing the chance of fitting more meetings.

```java
// LC 435: Non-overlapping Intervals [🔥 Must Do]
// Minimum intervals to remove so the rest don't overlap
public int eraseOverlapIntervals(int[][] intervals) {
    Arrays.sort(intervals, (a, b) -> Integer.compare(a[1], b[1])); // sort by END time
    int count = 0, prevEnd = Integer.MIN_VALUE;

    for (int[] interval : intervals) {
        if (interval[0] >= prevEnd) {
            prevEnd = interval[1]; // no overlap → keep this interval
        } else {
            count++; // overlap → remove this one (it ends later, so it's worse)
        }
    }
    return count;
}
```

⚙️ **Under the Hood — Why Sort by End Time, Not Start Time:**

```
Intervals: [1,10], [2,3], [4,5], [6,7]

Sort by START time: [1,10], [2,3], [4,5], [6,7]
  Greedy picks [1,10] first → only 1 interval fits!

Sort by END time: [2,3], [4,5], [6,7], [1,10]
  Greedy picks [2,3], then [4,5], then [6,7] → 3 intervals fit! ✓

Sorting by end time ensures we always leave the maximum remaining time.
```

**Dry run:** `intervals = [[1,2],[2,3],[3,4],[1,3]]`

```
Sort by end: [[1,2],[2,3],[1,3],[3,4]]
prevEnd = -∞

[1,2]: 1 >= -∞ → keep. prevEnd = 2. count = 0.
[2,3]: 2 >= 2 → keep. prevEnd = 3. count = 0.
[1,3]: 1 < 3 → overlap → remove. count = 1.
[3,4]: 3 >= 3 → keep. prevEnd = 4. count = 1.

Answer: 1 (remove [1,3])
```

**Edge Cases:**
- ☐ No intervals → return 0
- ☐ All intervals overlap → remove all but one
- ☐ No overlaps → remove 0
- ☐ Intervals touching at endpoints `[1,2],[2,3]` → NOT overlapping (start >= prevEnd)

🎯 **Likely Follow-ups:**
- **Q:** What if you need to find the maximum number of non-overlapping intervals (not minimum removals)?
  **A:** Same algorithm — the number of intervals you keep = total - removals. Or equivalently, count the intervals you keep (when `interval[0] >= prevEnd`).
- **Q:** What if intervals have weights and you want maximum weight non-overlapping set?
  **A:** That's the Weighted Job Scheduling problem — greedy doesn't work. Use DP: sort by end time, for each interval binary search for the latest non-overlapping interval, `dp[i] = max(dp[i-1], weight[i] + dp[j])`.
- **Q:** Why not sort by start time?
  **A:** Sorting by start time and picking the earliest start doesn't work because a long interval starting early blocks many short intervals. Sorting by end time ensures we always pick the interval that "gets out of the way" fastest.

---

### Pattern 2: Greedy — Jump Game / Reach

**Track the farthest index you can reach. If you ever find yourself at an index beyond your reach, you're stuck.**

```java
// LC 55: Jump Game [🔥 Must Do]
public boolean canJump(int[] nums) {
    int maxReach = 0;
    for (int i = 0; i < nums.length; i++) {
        if (i > maxReach) return false;          // can't reach this index
        maxReach = Math.max(maxReach, i + nums[i]); // update farthest reachable
    }
    return true; // reached the end
}
```

💡 **Intuition:** Imagine you're hopping across stepping stones. At each stone, you can see how far you can jump. You keep track of the farthest stone you can reach. If you're standing on a stone that's beyond your reach... well, you can't be standing there. Game over.

```java
// LC 45: Jump Game II — minimum jumps [🔥 Must Do]
public int jump(int[] nums) {
    int jumps = 0, currEnd = 0, farthest = 0;
    for (int i = 0; i < nums.length - 1; i++) {
        farthest = Math.max(farthest, i + nums[i]); // track farthest from current "level"
        if (i == currEnd) { // reached the end of current jump's range → must jump
            jumps++;
            currEnd = farthest; // new range after jumping
        }
    }
    return jumps;
}
```

⚙️ **Under the Hood — Jump Game II is BFS in Disguise:**
Think of it as BFS where each "level" is the range of indices reachable with the current number of jumps. `currEnd` marks the end of the current level. `farthest` tracks the end of the next level. When you reach `currEnd`, you "jump" to the next level.

```
nums = [2, 3, 1, 1, 4]

Level 0: index 0.           currEnd=0, farthest=2
  Jump! jumps=1, currEnd=2
Level 1: indices 1-2.       farthest=max(1+3, 2+1)=4
  i=2==currEnd → Jump! jumps=2, currEnd=4
Level 2: indices 3-4.       Reached end!

Answer: 2 jumps
```

---

### Pattern 3: Greedy — Task Scheduling / Assignments

**Count frequencies, then use the most frequent element to determine the minimum time.**

```java
// LC 621: Task Scheduler [🔥 Must Do]
public int leastInterval(char[] tasks, int n) {
    int[] freq = new int[26];
    for (char t : tasks) freq[t - 'A']++;
    int maxFreq = Arrays.stream(freq).max().getAsInt();
    int maxCount = (int) Arrays.stream(freq).filter(f -> f == maxFreq).count();

    // (maxFreq - 1) full groups of (n + 1) slots + maxCount tasks in last group
    int minSlots = (maxFreq - 1) * (n + 1) + maxCount;
    return Math.max(minSlots, tasks.length); // can't be less than total tasks
}
```

💡 **Intuition — The Frame Approach:**

```
Tasks: A=3, B=3, C=1, n=2 (cooldown of 2 between same tasks)

Build a frame based on the most frequent task:
  A _ _ | A _ _ | A
  ↑ maxFreq-1 groups of (n+1) slots, plus last group

Fill in other tasks:
  A B _ | A B _ | A B
  A B C | A B _ | A B

minSlots = (3-1) * (2+1) + 2 = 8
Total tasks = 7
Answer = max(8, 7) = 8

If we had many tasks and few idle slots, answer = total tasks (no idle needed).
```

**Edge Cases:**
- ☐ n = 0 → no cooldown, answer = total tasks
- ☐ All tasks the same → `(freq - 1) * (n + 1) + 1`
- ☐ Many distinct tasks → no idle time needed, answer = total tasks

---

### Pattern 4: Backtracking — Subsets [🔥 Must Know]

**At each position, choose to include or exclude the element. Every node in the recursion tree is a valid subset.**

```java
// LC 78: Subsets [🔥 Must Do]
public List<List<Integer>> subsets(int[] nums) {
    List<List<Integer>> result = new ArrayList<>();
    backtrack(result, new ArrayList<>(), nums, 0);
    return result;
}

private void backtrack(List<List<Integer>> result, List<Integer> current, int[] nums, int start) {
    result.add(new ArrayList<>(current)); // every state is a valid subset

    for (int i = start; i < nums.length; i++) {
        current.add(nums[i]);                          // choose
        backtrack(result, current, nums, i + 1);       // explore (i+1: no reuse)
        current.remove(current.size() - 1);            // unchoose
    }
}
```

**Recursion tree for `nums = [1, 2, 3]`:**

```
                        []
                /        |        \
             [1]        [2]       [3]
           /    \        |
        [1,2]  [1,3]   [2,3]
          |
       [1,2,3]

Result: [], [1], [1,2], [1,2,3], [1,3], [2], [2,3], [3]  (8 = 2³ subsets)
```

**Subsets II (with duplicates — LC 90):**

```java
public List<List<Integer>> subsetsWithDup(int[] nums) {
    Arrays.sort(nums); // MUST sort to group duplicates together
    List<List<Integer>> result = new ArrayList<>();
    backtrack(result, new ArrayList<>(), nums, 0);
    return result;
}

private void backtrack(List<List<Integer>> result, List<Integer> current, int[] nums, int start) {
    result.add(new ArrayList<>(current));
    for (int i = start; i < nums.length; i++) {
        if (i > start && nums[i] == nums[i - 1]) continue; // skip duplicates at same level
        current.add(nums[i]);
        backtrack(result, current, nums, i + 1);
        current.remove(current.size() - 1);
    }
}
```

⚙️ **Under the Hood — Why `i > start` (not `i > 0`) for Duplicate Skipping:**
We only skip duplicates at the same recursion level (same `start`). `i > start` means "this is not the first choice at this level." If `nums[i] == nums[i-1]` and `i > start`, we've already explored a branch with this value at this level — skip it. But if `i == start`, this is the first time we're considering this value at this level — include it.

---

### Pattern 5: Backtracking — Permutations [🔥 Must Know]

**Try every element at every position. Use a `used[]` array to track which elements are already in the current permutation.**

```java
// LC 46: Permutations [🔥 Must Do]
public List<List<Integer>> permute(int[] nums) {
    List<List<Integer>> result = new ArrayList<>();
    backtrack(result, new ArrayList<>(), nums, new boolean[nums.length]);
    return result;
}

private void backtrack(List<List<Integer>> result, List<Integer> current,
                       int[] nums, boolean[] used) {
    if (current.size() == nums.length) {
        result.add(new ArrayList<>(current)); // complete permutation
        return;
    }
    for (int i = 0; i < nums.length; i++) { // start from 0 (not start!)
        if (used[i]) continue;               // skip already-used elements
        used[i] = true;
        current.add(nums[i]);
        backtrack(result, current, nums, used);
        current.remove(current.size() - 1);
        used[i] = false;                     // backtrack
    }
}
```

**Key difference from subsets:**

| | Subsets | Permutations |
|---|--------|-------------|
| Loop starts at | `start` (only elements after current) | `0` (any unused element) |
| Tracking | `start` index | `used[]` boolean array |
| Base case | Every node is valid | Only when `current.size() == n` |
| Count | 2ⁿ | n! |

**Permutations II (with duplicates — LC 47):**

```java
// Sort first, then skip: if nums[i] == nums[i-1] and !used[i-1], skip
Arrays.sort(nums);
// In the loop:
if (i > 0 && nums[i] == nums[i - 1] && !used[i - 1]) continue;
```

💡 **Intuition — Why `!used[i-1]`:** We want to ensure that among duplicate elements, they're always used in order (first occurrence before second). If `nums[i-1]` is NOT used and `nums[i] == nums[i-1]`, it means we're trying to use the second duplicate before the first — skip it.

---

### Pattern 6: Backtracking — Combinations / Combination Sum

**Like subsets, but with a target constraint. Stop early (prune) when the remaining sum goes negative.**

```java
// LC 39: Combination Sum [🔥 Must Do]
// Unlimited use of each candidate
public List<List<Integer>> combinationSum(int[] candidates, int target) {
    List<List<Integer>> result = new ArrayList<>();
    backtrack(result, new ArrayList<>(), candidates, target, 0);
    return result;
}

private void backtrack(List<List<Integer>> result, List<Integer> current,
                       int[] candidates, int remaining, int start) {
    if (remaining == 0) { result.add(new ArrayList<>(current)); return; } // found valid combo
    if (remaining < 0) return; // pruning: overshot the target

    for (int i = start; i < candidates.length; i++) {
        current.add(candidates[i]);
        backtrack(result, current, candidates, remaining - candidates[i], i); // i (not i+1): reuse allowed
        current.remove(current.size() - 1);
    }
}
```

**Combination Sum II (LC 40):** Each number used once → pass `i + 1` instead of `i`, and skip duplicates with `if (i > start && candidates[i] == candidates[i-1]) continue`.

**Optimization — Sort + Early Termination:**

```java
Arrays.sort(candidates); // sort ascending
// In the loop:
if (candidates[i] > remaining) break; // all remaining candidates are too large → stop
```

---

### Pattern 7: Backtracking — Grid / Board Problems

**DFS on a grid with backtracking — mark cells as visited, explore all directions, then unmark.**

```java
// LC 79: Word Search [🔥 Must Do]
public boolean exist(char[][] board, String word) {
    for (int r = 0; r < board.length; r++)
        for (int c = 0; c < board[0].length; c++)
            if (dfs(board, word, r, c, 0)) return true;
    return false;
}

private boolean dfs(char[][] board, String word, int r, int c, int idx) {
    if (idx == word.length()) return true; // found complete word
    if (r < 0 || r >= board.length || c < 0 || c >= board[0].length
        || board[r][c] != word.charAt(idx)) return false; // out of bounds or mismatch

    char temp = board[r][c];
    board[r][c] = '#'; // mark visited (backtracking: will restore later)

    boolean found = dfs(board, word, r+1, c, idx+1) || dfs(board, word, r-1, c, idx+1)
                 || dfs(board, word, r, c+1, idx+1) || dfs(board, word, r, c-1, idx+1);

    board[r][c] = temp; // RESTORE (backtrack) — critical for other paths
    return found;
}
```

💡 **Intuition — Why Backtrack (Restore) on Grid:** Unlike Number of Islands (where we permanently mark cells), Word Search needs to try multiple paths. A cell used in one failed path might be needed for a successful path starting from a different position. So we must restore it after exploring.

**Complexity:** O(m × n × 4^L) where L = word length. Each cell can branch into 4 directions, up to L levels deep.

---

### Pattern 8: Backtracking — Constraint Satisfaction

**Place elements one at a time, validate constraints after each placement, and backtrack if constraints are violated.**

```java
// LC 51: N-Queens [🔥 Must Do]
public List<List<String>> solveNQueens(int n) {
    List<List<String>> result = new ArrayList<>();
    char[][] board = new char[n][n];
    for (char[] row : board) Arrays.fill(row, '.');
    backtrack(result, board, 0, n);
    return result;
}

private void backtrack(List<List<String>> result, char[][] board, int row, int n) {
    if (row == n) { // placed all queens successfully
        List<String> snapshot = new ArrayList<>();
        for (char[] r : board) snapshot.add(new String(r));
        result.add(snapshot);
        return;
    }
    for (int col = 0; col < n; col++) {
        if (isValid(board, row, col, n)) {
            board[row][col] = 'Q';                    // place queen
            backtrack(result, board, row + 1, n);     // try next row
            board[row][col] = '.';                    // remove queen (backtrack)
        }
    }
}

private boolean isValid(char[][] board, int row, int col, int n) {
    for (int i = 0; i < row; i++) {
        if (board[i][col] == 'Q') return false;                          // same column
        if (col - (row - i) >= 0 && board[i][col - (row - i)] == 'Q') return false; // left diagonal
        if (col + (row - i) < n && board[i][col + (row - i)] == 'Q') return false;  // right diagonal
    }
    return true;
}
```

⚙️ **Under the Hood — O(1) Validity Check Optimization:**
Instead of scanning all previous rows, use boolean arrays:

```java
boolean[] cols = new boolean[n];        // columns with queens
boolean[] diag1 = new boolean[2 * n];  // main diagonals (row - col + n)
boolean[] diag2 = new boolean[2 * n];  // anti-diagonals (row + col)

// Check: !cols[col] && !diag1[row - col + n] && !diag2[row + col]
// Place: set all three to true
// Remove: set all three to false
```

This reduces validity check from O(n) to O(1), making the overall algorithm faster.

🎯 **Likely Follow-ups:**
- **Q:** How many solutions does N-Queens have for n=8?
  **A:** 92 distinct solutions. The number grows roughly factorially but with heavy pruning.
- **Q:** Can you solve N-Queens without backtracking?
  **A:** For finding ONE solution, there are constructive algorithms for n ≥ 4. But for finding ALL solutions, backtracking is the standard approach.


---

## 3. Patterns Summary Table

| # | Pattern | When to Use | Key Idea | Time | Space | Example |
|---|---------|------------|----------|------|-------|---------|
| 1 | Interval scheduling | Non-overlapping intervals | Sort by end time, pick earliest ending | O(n log n) | O(1) | Non-overlapping (LC 435) |
| 2 | Jump/reach | Can reach end? Min jumps? | Track farthest reachable index | O(n) | O(1) | Jump Game (LC 55) |
| 3 | Task scheduling | Min time with cooldown | Frequency-based frame formula | O(n) | O(1) | Task Scheduler (LC 621) |
| 4 | Subsets | All subsets | Backtrack from `start` index, every node is valid | O(2ⁿ) | O(n) | Subsets (LC 78) |
| 5 | Permutations | All orderings | Backtrack from 0 with `used[]` array | O(n!) | O(n) | Permutations (LC 46) |
| 6 | Combinations | Subsets with target sum | Backtrack with remaining, prune when < 0 | O(2ⁿ) | O(n) | Combination Sum (LC 39) |
| 7 | Grid backtracking | Word search, path finding | DFS + mark/unmark visited cells | O(m×n×4^L) | O(L) | Word Search (LC 79) |
| 8 | Constraint satisfaction | N-Queens, Sudoku | Place + validate + backtrack | O(n!) | O(n²) | N-Queens (LC 51) |

**Pattern Selection Flowchart:**

```
Optimization problem?
├── Can prove local optimal = global optimal? → GREEDY
│   ├── Intervals? → Sort by end time
│   ├── Reachability? → Track max reach
│   └── Scheduling? → Frequency-based formula
└── Need to explore all solutions? → BACKTRACKING
    ├── All subsets? → Pattern 4 (start index, every node valid)
    ├── All permutations? → Pattern 5 (used[] array, complete when size=n)
    ├── Combinations with target? → Pattern 6 (remaining sum, prune < 0)
    ├── Grid search? → Pattern 7 (mark/unmark, 4 directions)
    └── Constraint satisfaction? → Pattern 8 (place, validate, backtrack)
```

---

## 4. LeetCode Problem List (Must-Solve)

### Easy

| # | Problem Name | LC # | Pattern(s) | Why Important |
|---|-------------|------|-----------|---------------|
| 1 | Assign Cookies | 455 | Greedy (sort + match) | Simplest greedy |
| 2 | Lemonade Change | 860 | Greedy (make change) | Greedy decision at each step |
| 3 | Maximum Units on a Truck | 1710 | Greedy (sort by value) | Fractional knapsack idea |
| 4 | Best Time to Buy and Sell Stock II | 122 | Greedy | Collect all positive diffs |

### Medium

| # | Problem Name | LC # | Pattern(s) | Why Important |
|---|-------------|------|-----------|---------------|
| 1 | Subsets | 78 | Backtracking | [🔥 Must Do] Foundation for all backtracking |
| 2 | Subsets II | 90 | Backtracking + dedup | Duplicate handling |
| 3 | Permutations | 46 | Backtracking | [🔥 Must Do] Permutation template |
| 4 | Permutations II | 47 | Backtracking + dedup | Duplicate permutations |
| 5 | Combination Sum | 39 | Backtracking | [🔥 Must Do] Unlimited reuse |
| 6 | Combination Sum II | 40 | Backtracking + dedup | Each number once |
| 7 | Combinations | 77 | Backtracking | Choose k from n |
| 8 | Word Search | 79 | Grid backtracking | [🔥 Must Do] Grid DFS + backtrack |
| 9 | Palindrome Partitioning | 131 | Backtracking | [🔥 Must Do] Partition into palindromes |
| 10 | Letter Combinations of a Phone Number | 17 | Backtracking | [🔥 Must Do] Multi-choice per digit |
| 11 | Generate Parentheses | 22 | Backtracking | [🔥 Must Do] Open/close count constraint |
| 12 | Restore IP Addresses | 93 | Backtracking | Partition string into valid IPs |
| 13 | Non-overlapping Intervals | 435 | Greedy (interval) | [🔥 Must Do] Sort by end time |
| 14 | Jump Game | 55 | Greedy | [🔥 Must Do] Max reach |
| 15 | Jump Game II | 45 | Greedy | [🔥 Must Do] BFS-like jumps |
| 16 | Task Scheduler | 621 | Greedy | [🔥 Must Do] Frequency formula |
| 17 | Gas Station | 134 | Greedy | [🔥 Must Do] Circular greedy |
| 18 | Partition Labels | 763 | Greedy | [🔥 Must Do] Last occurrence tracking |
| 19 | Minimum Number of Arrows to Burst Balloons | 452 | Greedy (interval) | Overlapping intervals |
| 20 | Hand of Straights | 846 | Greedy + TreeMap | Consecutive groups |
| 21 | Reorganize String | 767 | Greedy + heap | Most frequent first |
| 22 | Boats to Save People | 881 | Greedy + two pointers | Pair heaviest with lightest |
| 23 | Maximum Subarray | 53 | Greedy (Kadane's) | [🔥 Must Do] Reset or extend |
| 24 | Valid Parenthesis String | 678 | Greedy (range tracking) | Track min/max open count |
| 25 | Minimum Deletions to Make Character Frequencies Unique | 1647 | Greedy | Frequency adjustment |

### Hard

| # | Problem Name | LC # | Pattern(s) | Why Important |
|---|-------------|------|-----------|---------------|
| 1 | N-Queens | 51 | Constraint backtracking | [🔥 Must Do] Classic constraint satisfaction |
| 2 | N-Queens II | 52 | Constraint backtracking | Count solutions |
| 3 | Sudoku Solver | 37 | Constraint backtracking | [🔥 Must Do] Full constraint propagation |
| 4 | Word Search II | 212 | Trie + backtracking | Trie-guided grid search |
| 5 | Candy | 135 | Greedy (two-pass) | Left-to-right + right-to-left |
| 6 | IPO | 502 | Greedy + two heaps | Maximize capital |
| 7 | Minimum Interval to Include Each Query | 1851 | Greedy + sort + heap | Sweep line |
| 8 | Course Schedule III | 630 | Greedy + heap | Sort by deadline, replace longest |
| 9 | Patching Array | 330 | Greedy | Extend reachable range |
| 10 | Expression Add Operators | 282 | Backtracking | Insert +, -, * between digits |

---

## 5. Interview Strategy

**Greedy vs DP — how to decide:**
- If greedy works, it's always simpler and faster. Try greedy first.
- If you can't prove greedy works (or find a counterexample), use DP.
- Common greedy patterns: sort + scan, always pick the best available, exchange argument.

**Backtracking — how to communicate:**
1. "This problem asks for all valid [subsets/permutations/combinations], so I'll use backtracking."
2. "At each step, I have [N] choices. I'll try each, recurse, and undo."
3. "I'll prune by [condition] to avoid exploring invalid paths."
4. State the time complexity: "There are [2ⁿ/n!/C(n,k)] possible solutions, so the time is O([complexity])."

**Common mistakes:**
- Greedy: not explaining why it works (state your reasoning even if informal)
- Backtracking: forgetting to undo the choice (the "backtrack" step)
- Backtracking: adding `current` directly to result instead of a copy (`new ArrayList<>(current)`)
- Duplicate handling: forgetting to sort before skipping duplicates
- Permutations vs subsets: using `start` index for permutations (wrong) or `used[]` for subsets (unnecessary)
- Grid backtracking: forgetting to restore the cell after exploring (unlike Number of Islands where you permanently mark)

💥 **What Can Go Wrong in Interviews:**

| Mistake | Impact | Prevention |
|---------|--------|------------|
| Greedy without justification | Interviewer questions correctness | State: "This works because [exchange argument / known pattern]" |
| Forget to backtrack | Wrong results, missing solutions | Template: choose → explore → UNCHOOSE |
| Add reference instead of copy | All results are empty lists | Always `new ArrayList<>(current)` |
| Wrong duplicate skip condition | Duplicate or missing results | Sort first, use `i > start && nums[i] == nums[i-1]` |
| Permutation with start index | Missing permutations | Permutations: loop from 0 with `used[]` |

---

## 6. Edge Cases & Pitfalls

**Greedy edge cases:**
- ☐ Empty input → return 0 or empty
- ☐ All intervals overlap → keep only one
- ☐ Single element → trivially optimal
- ☐ Ties (multiple elements with same value) → usually doesn't matter, but verify

**Backtracking edge cases:**
- ☐ Empty input → return `[[]]` for subsets, `[]` for permutations
- ☐ Duplicates in input → sort + skip (Subsets II, Permutations II, Combination Sum II)
- ☐ Very large search space → ensure pruning is effective (sort + early termination)
- ☐ Stack overflow for deep recursion (n > 10⁴) → rare for backtracking (usually n ≤ 20)
- ☐ Target = 0 in combination sum → empty combination is valid

**Java-specific pitfalls:**

```java
// PITFALL 1: Forgetting to copy the list
result.add(current);                    // WRONG — reference, will be empty later
result.add(new ArrayList<>(current));   // CORRECT — independent copy

// PITFALL 2: remove() with int vs Integer
List<Integer> list = new ArrayList<>(Arrays.asList(1, 2, 3));
list.remove(1);           // removes element at INDEX 1 (value 2), not value 1!
list.remove(Integer.valueOf(1)); // removes first occurrence of VALUE 1

// In backtracking, always use:
current.remove(current.size() - 1); // remove last element (by index)

// PITFALL 3: Integer.compare vs subtraction for comparator
Arrays.sort(intervals, (a, b) -> a[1] - b[1]); // OVERFLOW risk for large values!
Arrays.sort(intervals, (a, b) -> Integer.compare(a[1], b[1])); // SAFE
```

---

## 7. Connections to Other Topics

| This Pattern | Connects To | How |
|-------------|-------------|-----|
| Greedy intervals | [01-dsa/11-sorting-searching.md](11-sorting-searching.md) | Sort is preprocessing for most greedy problems |
| Greedy + heap | [01-dsa/09-heap-priority-queue.md](09-heap-priority-queue.md) | Many greedy problems use heaps for "best available" selection |
| Backtracking subsets | [01-dsa/10-bit-manipulation.md](10-bit-manipulation.md) | Subsets can be generated with bitmasks (2ⁿ iterations) |
| Backtracking on grid | [01-dsa/06-graphs.md](06-graphs.md) | Same DFS traversal, different domain |
| Backtracking + pruning | Constraint programming | N-Queens, Sudoku are classic CSP problems |
| Greedy vs DP | [01-dsa/07-dynamic-programming.md](07-dynamic-programming.md) | Greedy is a special case of DP where local = global optimal |
| Combination Sum | [01-dsa/07-dynamic-programming.md](07-dynamic-programming.md) | Counting combinations → DP (coin change II). Listing all → backtracking. |
| Word Search + Trie | [01-dsa/05-trees.md](05-trees.md) | Word Search II uses Trie to prune the search space |
| Interval greedy | [02-system-design/problems/notification-system.md](../02-system-design/problems/notification-system.md) | Rate limiting and scheduling in system design |

---

## 8. Revision Checklist

**Greedy patterns:**
- [ ] Interval scheduling: sort by END time, pick non-overlapping. Why end? Leaves most room.
- [ ] Jump game: track `maxReach`. If `i > maxReach`, stuck. Jump Game II = BFS levels.
- [ ] Task scheduler: `(maxFreq - 1) * (n + 1) + maxCount`. Max with total tasks.
- [ ] Kadane's: `currSum = max(nums[i], currSum + nums[i])`. Reset or extend.
- [ ] Gas station: if total gas ≥ total cost, solution exists. Start where running deficit resets to 0.
- [ ] Partition labels: track last occurrence of each char. Extend partition end to max last occurrence.

**Backtracking templates:**
- [ ] Subsets: loop from `start`, add current at every node, recurse with `i + 1`
- [ ] Permutations: loop from `0`, use `used[]` array, base case when `size == n`
- [ ] Combinations: loop from `start`, prune when `remaining < 0`, recurse with `i` (reuse) or `i + 1` (no reuse)
- [ ] Duplicate handling: SORT first + `if (i > start && nums[i] == nums[i-1]) continue`
- [ ] Grid: mark visited (`board[r][c] = '#'`), recurse 4 directions, RESTORE (`board[r][c] = temp`)
- [ ] Constraint: place, validate, recurse, REMOVE (N-Queens: place queen, check column + diagonals)

**Critical details:**
- [ ] Always `new ArrayList<>(current)` when adding to result — never add the reference
- [ ] Subsets: every node is a valid result. Permutations: only complete arrangements.
- [ ] Combination Sum: `i` for reuse, `i + 1` for no reuse
- [ ] Permutations II duplicate skip: `i > 0 && nums[i] == nums[i-1] && !used[i-1]`
- [ ] Grid backtracking: MUST restore cell (unlike Number of Islands which permanently marks)
- [ ] N-Queens optimization: boolean arrays for columns, diag1 (row-col+n), diag2 (row+col)

**Complexity:**
- [ ] Subsets: O(2ⁿ × n) — 2ⁿ subsets, each takes O(n) to copy
- [ ] Permutations: O(n! × n) — n! permutations, each takes O(n) to copy
- [ ] Combinations (k from n): O(C(n,k) × k)
- [ ] N-Queens: O(n!) with pruning
- [ ] Word Search: O(m × n × 4^L) where L = word length
- [ ] Interval scheduling: O(n log n) for sorting

**Top 10 must-solve:**
1. Subsets (LC 78) — Backtracking foundation
2. Permutations (LC 46) — Permutation template
3. Combination Sum (LC 39) — Combination with reuse
4. Generate Parentheses (LC 22) — Constraint-based backtracking
5. Word Search (LC 79) — Grid backtracking
6. N-Queens (LC 51) — Constraint satisfaction
7. Non-overlapping Intervals (LC 435) — Greedy interval scheduling
8. Jump Game (LC 55) — Greedy reachability
9. Task Scheduler (LC 621) — Greedy frequency formula
10. Partition Labels (LC 763) — Greedy last occurrence

---

## 📋 Suggested New Documents

### 1. Sweep Line Algorithm
- **Placement**: `01-dsa/12-sweep-line.md`
- **Why needed**: Sweep line problems (meeting rooms II, skyline problem, interval intersection) are a distinct pattern that combines sorting with event processing. Currently scattered across greedy and interval problems without dedicated coverage.
- **Key subtopics**: Event-based sweep line, meeting rooms II (min heap), skyline problem, rectangle area union, interval intersection/union
