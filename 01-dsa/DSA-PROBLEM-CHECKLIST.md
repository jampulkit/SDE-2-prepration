# DSA Problem Checklist — With Interviewer Follow-ups & Variations

> Sorted by topic → difficulty. Each problem has follow-up questions an interviewer will ask.
> Use: ☐ = not done, ☑ = solved, ⭐ = revisit

---

## 1. Arrays, Strings & Hashing

### Easy
| # | Problem | LC | Pattern | Status |
|---|---------|-----|---------|--------|
| 1 | Two Sum | 1 | HashMap | ☐ |
| 2 | Valid Anagram | 242 | Frequency Count | ☐ |
| 3 | Contains Duplicate | 217 | HashSet / Sort | ☐ |

**Follow-ups & Variations:**
- **Two Sum →** "What if array is sorted?" → Two pointers O(1) space. "What if there are multiple pairs?" → Return all. "Three Sum?" → Fix one, two-pointer on rest (LC 15). "Four Sum?" → Reduce to two-sum with pairs. "What if input is a stream?" → Store in HashMap, check each new element.
- **Valid Anagram →** "What if inputs are Unicode?" → HashMap instead of int[26]. "Check if two huge files are anagrams?" → Stream both, single freq map. "What about case-insensitive?" → toLowerCase first. "What if you need to find all anagrams in a string?" → Sliding window (LC 438).
- **Contains Duplicate →** "Within distance k?" → Sliding window HashSet of size k (LC 219). "Within distance k AND value diff ≤ t?" → TreeSet with floor/ceiling (LC 220). "What if memory is limited?" → Sort first O(1) space, or bloom filter for probabilistic check.

### Medium
| # | Problem | LC | Pattern | Status |
|---|---------|-----|---------|--------|
| 4 | Group Anagrams | 49 | Grouping/Bucketing | ☐ |
| 5 | Subarray Sum Equals K | 560 | Prefix Sum + HashMap | ☐ |
| 6 | Longest Consecutive Sequence | 128 | HashSet | ☐ |
| 7 | Encode and Decode Strings | 271 | String Manipulation | ☐ |

**Follow-ups & Variations:**
- **Group Anagrams →** "What key would you use?" → Sorted string or frequency string. "Which is faster?" → Frequency string avoids O(k log k) sort per word. "How would you do this in a distributed system (billions of strings)?" → MapReduce: map emits (sorted_key, word), reduce collects. "What if strings are very long?" → Hash the frequency array instead of converting to string.
- **Subarray Sum Equals K →** "Find the actual subarray, not just count?" → Store first index instead of count. "Subarrays of length ≥ 2?" → Delay adding to map by one step (LC 523). "Sum divisible by K?" → Use `((sum % k) + k) % k` as key — watch negative modulo in Java! "What if all elements are positive?" → Sliding window is simpler. "Longest subarray with sum K?" → Store first occurrence of each prefix sum.
- **Longest Consecutive Sequence →** "Prove it's O(n)?" → Each element visited at most twice (once in outer loop, once in while). "Return the actual sequence?" → Track start of longest. "What if duplicates exist?" → HashSet deduplicates automatically. "Distributed version?" → Sort + merge across partitions.
- **Encode/Decode Strings →** "What delimiter would you use?" → Length-prefix: `"4#word"` avoids delimiter collision. "What if strings contain any character?" → Length-prefix is the only safe approach. "How does HTTP chunked transfer encoding work?" → Same idea: length + data.

---

## 2. Two Pointers & Sliding Window

### Easy
| # | Problem | LC | Pattern | Status |
|---|---------|-----|---------|--------|
| 8 | Remove Duplicates from Sorted Array | 26 | Same-direction | ☐ |
| 9 | Move Zeroes | 283 | Same-direction | ☐ |

**Follow-ups & Variations:**
- **Remove Duplicates →** "Allow at most 2 duplicates?" → LC 80: compare with `nums[slow - 2]`. "What if array is unsorted?" → Use HashSet, but loses O(1) space. "Remove specific value in-place?" → LC 27.
- **Move Zeroes →** "Minimize writes?" → Track write pointer, only write non-zeros, fill rest with 0. "Move to front instead of end?" → Reverse iteration. "What if order doesn't matter?" → Swap with end pointer (faster).

### Medium
| # | Problem | LC | Pattern | Status |
|---|---------|-----|---------|--------|
| 10 | Container With Most Water | 11 | Opposite Two Pointers | ☐ |
| 11 | 3Sum | 15 | Sort + Two Pointers | ☐ |
| 12 | Sort Colors | 75 | Dutch National Flag | ☐ |
| 13 | Find All Anagrams in a String | 438 | Fixed Sliding Window | ☐ |
| 14 | Longest Substring Without Repeating Characters | 3 | Variable Sliding Window | ☐ |
| 15 | Longest Repeating Character Replacement | 424 | Variable Sliding Window | ☐ |
| 16 | Minimum Window Substring | 76 | Min Window | ☐ |
| 17 | Longest Palindromic Substring | 5 | Expand from Center | ☐ |
| 18 | Subarrays with K Different Integers | 992 | Exactly K = AtMost(K) - AtMost(K-1) | ☐ |
| 19 | Minimum Size Subarray Sum | 209 | Variable Sliding Window | ☐ |

### Hard
| # | Problem | LC | Pattern | Status |
|---|---------|-----|---------|--------|
| 20 | Sliding Window Maximum | 239 | Monotonic Deque | ☐ |

**Follow-ups & Variations:**
- **Container With Most Water →** "Prove the greedy works?" → Moving the shorter line is the only way to potentially increase area; moving the taller line can only decrease or maintain. "What if lines have width?" → Different problem, needs different approach. "3D version (trapping rain water)?" → LC 42 uses stack or two-pointer.
- **3Sum →** "How do you handle duplicates?" → Skip duplicate values for all three pointers. "4Sum?" → Add one more outer loop (LC 18). "Closest to target?" → Track min diff (LC 16). "Count triplets instead of listing?" → Modify to count. "What if array is too large for memory?" → External sort + two-pointer.
- **Sort Colors →** "What if 4 colors?" → Two-pass: partition around 1, then partition right half around 2. "K colors?" → Counting sort O(n+k). "Why not just use counting sort for 3?" → Dutch National Flag is in-place single-pass, counting sort needs two passes.
- **Longest Substring Without Repeating →** "What data structure for the window?" → HashMap (char → last index) for O(1) jump. "What if we need longest with at most K distinct?" → LC 340, same template. "What about Unicode?" → HashMap handles it. "Longest with all unique AND length ≥ K?" → Add length check.
- **Longest Repeating Character Replacement →** "Why don't we shrink maxFreq when window shrinks?" → We don't need to — the window only grows when we find a better maxFreq. Old maxFreq gives a valid lower bound. "What if we can replace with any char, not just the minority?" → Same problem, same solution.
- **Minimum Window Substring →** "What if T has duplicates?" → Frequency map handles it — need at least that many of each char. "What if we need smallest window containing all unique chars of T?" → Same approach, just deduplicate T first. "Return all minimum windows?" → Track all windows with min length.
- **Sliding Window Maximum →** "Why monotonic deque?" → Maintains decreasing order; front is always the max. "Can you do it with two stacks?" → Yes, using a max-stack approach. "What about sliding window minimum?" → Same idea, maintain increasing deque. "Online version (stream)?" → Same deque approach works.
- **Subarrays with K Different Integers →** "Why exactly(K) = atMost(K) - atMost(K-1)?" → atMost(K) counts subarrays with 1,2,...,K distinct. Subtracting atMost(K-1) removes those with <K. "Can you do it in one pass?" → Yes but much harder — track two pointers for the valid range.

---

## 3. Stacks & Queues

### Easy
| # | Problem | LC | Pattern | Status |
|---|---------|-----|---------|--------|
| 21 | Valid Parentheses | 20 | Matching Brackets | ☐ |
| 22 | Min Stack | 155 | Auxiliary State | ☐ |
| 23 | Implement Queue using Stacks | 232 | Stack Simulation | ☐ |

**Follow-ups & Variations:**
- **Valid Parentheses →** "What if string has non-bracket characters?" → Ignore them. "What about wildcard `*` that can be any bracket or empty?" → LC 678, greedy with two counters (low/high). "Minimum insertions to make valid?" → LC 1541. "Longest valid parentheses substring?" → LC 32, stack or DP. "Generate all valid combinations of N pairs?" → Backtracking (LC 22).
- **Min Stack →** "Can you do it with O(1) extra space?" → Store `2*val - min` when pushing a new minimum; decode on pop. "Max Stack with popMax()?" → LC 716, use TreeMap + doubly linked list. "What about a Min Queue?" → Use two stacks (each with min tracking) to simulate queue.
- **Implement Queue using Stacks →** "Amortized O(1) per operation — prove it?" → Each element pushed/popped at most twice total. "Implement Stack using Queues?" → LC 225, push is O(n) or pop is O(n). "Which is used in practice?" → BFS uses queue, DFS uses stack (or recursion).

### Medium
| # | Problem | LC | Pattern | Status |
|---|---------|-----|---------|--------|
| 24 | Daily Temperatures | 739 | Monotonic Stack | ☐ |
| 25 | Evaluate Reverse Polish Notation | 150 | Expression Eval | ☐ |
| 26 | Decode String | 394 | Nested Stack | ☐ |
| 27 | Basic Calculator | 224 | Expression Eval | ☐ |

### Hard
| # | Problem | LC | Pattern | Status |
|---|---------|-----|---------|--------|
| 28 | Largest Rectangle in Histogram | 84 | Monotonic Stack | ☐ |

**Follow-ups & Variations:**
- **Daily Temperatures →** "Next greater element in a circular array?" → LC 503, iterate twice (2n). "Previous greater element?" → Iterate left to right with decreasing stack. "Next smaller element?" → Increasing stack instead. "Count of days until warmer for each?" → Same problem, stack stores indices.
- **Evaluate RPN →** "Convert infix to postfix (Shunting Yard)?" → Use operator stack with precedence. "Handle unary minus?" → Treat as `(0 - x)`. "What about function calls like `max(a, b)`?" → Push function name on stack, pop args on `)`.
- **Decode String →** "What if nesting is very deep (stack overflow)?" → Use iterative stack instead of recursion. "What if encoding is different, like run-length?" → Adapt the parsing. "Encode a string (reverse operation)?" → Find repeated patterns, much harder.
- **Largest Rectangle in Histogram →** "Maximal rectangle in a binary matrix?" → LC 85, treat each row as histogram base, apply LC 84 per row. "Trapping rain water?" → LC 42, similar stack approach or two-pointer. "What's the intuition for the stack approach?" → For each bar, find the nearest shorter bar on left and right — that defines the rectangle width.

---

## 4. Linked Lists

### Easy
| # | Problem | LC | Pattern | Status |
|---|---------|-----|---------|--------|
| 29 | Middle of Linked List | 876 | Fast/Slow | ☐ |
| 30 | Reverse Linked List | 206 | Reverse | ☐ |
| 31 | Merge Two Sorted Lists | 21 | Merge | ☐ |
| 32 | Linked List Cycle | 141 | Fast/Slow | ☐ |
| 33 | Intersection of Two Linked Lists | 160 | Two Pointers | ☐ |

**Follow-ups & Variations:**
- **Reverse Linked List →** "Reverse iteratively AND recursively?" → Must know both. "Reverse in groups of K?" → LC 25 (hard). "Reverse between positions m and n?" → LC 92. "What if it's a doubly linked list?" → Swap prev/next pointers. "Why is iterative preferred in production?" → No stack overflow risk for long lists.
- **Linked List Cycle →** "Find the start of the cycle?" → LC 142, Floyd's: when fast and slow meet, reset one to head, move both at speed 1. "Prove why this works mathematically?" → Let a = distance to cycle start, b = meeting point in cycle, c = cycle length. slow travels a+b, fast travels a+b+c. Since fast = 2×slow: a+b+c = 2(a+b), so c = a+b, meaning a = c-b (remaining cycle distance). "What if you can't modify the list?" → Floyd's doesn't modify it.
- **Merge Two Sorted Lists →** "Merge K sorted lists?" → LC 23, min-heap of K heads, O(N log K). "Merge sort on linked list?" → LC 148, find middle + merge. "Why is merge sort preferred over quicksort for linked lists?" → No random access needed, merge is natural for linked lists.
- **Intersection of Two Linked Lists →** "Prove the two-pointer approach works?" → Pointer A travels lenA + lenB, pointer B travels lenB + lenA — same total distance, so they meet at intersection. "What if there's no intersection?" → Both reach null at the same time. "Can you do it with a HashSet?" → Yes, O(n) space. "What if lists have cycles?" → Much harder — need to detect cycles first.

### Medium
| # | Problem | LC | Pattern | Status |
|---|---------|-----|---------|--------|
| 34 | Linked List Cycle II | 142 | Floyd's Algorithm | ☐ |
| 35 | Remove Nth Node From End | 19 | Two Pointers with Gap | ☐ |
| 36 | Reorder List | 143 | Find Middle + Reverse + Merge | ☐ |
| 37 | Palindrome Linked List | 234 | Fast/Slow + Reverse | ☐ |

**Follow-ups & Variations:**
- **Remove Nth From End →** "Can you do it in one pass?" → Yes, two pointers with N gap. "What if N > list length?" → Edge case — clarify with interviewer. "What if it's a doubly linked list?" → Traverse from end directly. "Remove all nodes with value X?" → LC 203, use dummy head.
- **Reorder List →** "Why find middle, reverse second half, merge?" → It's the only O(1) space approach. "Can you do it with a stack?" → Yes, push all nodes, pop to interleave — O(n) space. "What if the list is doubly linked?" → Two pointers from both ends, much simpler.
- **Palindrome Linked List →** "Can you check without modifying the list?" → Use a stack for first half, compare with second half. Or use recursion (implicit stack). "What if it's a doubly linked list?" → Two pointers from both ends. "Restore the list after checking?" → Reverse the second half back after comparison.

---

## 5. Trees

### Easy
| # | Problem | LC | Pattern | Status |
|---|---------|-----|---------|--------|
| 38 | Maximum Depth of Binary Tree | 104 | DFS | ☐ |
| 39 | Invert Binary Tree | 226 | DFS | ☐ |
| 40 | Same Tree / Subtree of Another Tree | 100/572 | DFS | ☐ |

**Follow-ups & Variations:**
- **Maximum Depth →** "Iterative?" → BFS, count levels. "Minimum depth?" → LC 111, BFS is better (stops at first leaf). "What about N-ary tree?" → Same DFS, iterate over children list.
- **Invert Binary Tree →** "Iterative?" → BFS/DFS with stack, swap children at each node. "What if it's a BST — is the result still a BST?" → No, it becomes a reverse-BST (right < root < left).

### Medium
| # | Problem | LC | Pattern | Status |
|---|---------|-----|---------|--------|
| 41 | Diameter of Binary Tree | 543 | DFS + Global Max | ☐ |
| 42 | Validate BST | 98 | Inorder / Range Check | ☐ |
| 43 | Kth Smallest in BST | 230 | Inorder Traversal | ☐ |
| 44 | Path Sum II | 113 | DFS + Backtracking | ☐ |
| 45 | Path Sum III | 437 | Prefix Sum on Tree | ☐ |
| 46 | Construct from Preorder + Inorder | 105 | Recursive Build | ☐ |
| 47 | Lowest Common Ancestor | 236 | DFS | ☐ |
| 48 | Binary Tree Right Side View | 199 | BFS Level Order | ☐ |
| 49 | Implement Trie | 208 | Trie | ☐ |

### Hard
| # | Problem | LC | Pattern | Status |
|---|---------|-----|---------|--------|
| 50 | Binary Tree Maximum Path Sum | 124 | DFS + Global Max | ☐ |
| 51 | Serialize/Deserialize Binary Tree | 297 | BFS or Preorder | ☐ |

**Follow-ups & Variations:**
- **Diameter →** "What if edges have weights?" → Track weighted path sum instead of count. "Diameter of N-ary tree?" → Track top-2 child heights. "Longest path in a graph (not tree)?" → BFS from any node, then BFS from farthest — works for trees only.
- **Validate BST →** "What if duplicates are allowed?" → Clarify: left ≤ root < right or left < root ≤ right. "Can you do it iteratively?" → Inorder traversal with stack, check each value > previous. "What if nodes have parent pointers?" → Follow parent to validate range.
- **Kth Smallest in BST →** "What if the BST is modified frequently (insert/delete)?" → Augment each node with subtree size — O(log n) for kth element. "What if K changes frequently?" → Same augmented BST. "Kth largest?" → Reverse inorder (right, root, left).
- **Path Sum III →** "Why prefix sum on tree?" → Same as subarray sum = K, but on root-to-node paths. "What if paths can go between any two nodes (not just root-to-leaf)?" → LC 124 approach. "How do you handle the backtracking of the prefix map?" → Remove current prefix sum from map after DFS returns (undo).
- **LCA →** "What if it's a BST?" → LC 235, use BST property: if both < root go left, both > root go right, else root is LCA. "What if nodes have parent pointers?" → Like intersection of two linked lists. "LCA of K nodes?" → Find LCA of first two, then LCA of result with third, etc. "What if one node might not exist in tree?" → Two-pass: first verify both exist, then find LCA.
- **Trie →** "How would you implement autocomplete?" → DFS from prefix node, collect all words. "Wildcard search (`.` matches any)?" → LC 211, DFS trying all children for `.`. "Memory optimization?" → Compressed trie (radix tree) — merge single-child chains. "How is Trie used in IP routing?" → Longest prefix match on binary trie.
- **Maximum Path Sum →** "Why return single-side to parent?" → A path through parent can only use one branch from each child. "What if all values are negative?" → Algorithm handles it — picks the least negative. "What if we need the actual path?" → Track nodes during DFS, store best path globally.
- **Serialize/Deserialize →** "BFS vs preorder — which is better?" → BFS preserves level structure, preorder is simpler to implement. "How would you compress it?" → Use null markers efficiently, or level-order with implicit indexing. "What format would you use in production?" → Protocol Buffers or JSON with null markers. "How does this relate to file system serialization?" → Same tree serialization concept.

---

## 6. Graphs

### Medium
| # | Problem | LC | Pattern | Status |
|---|---------|-----|---------|--------|
| 52 | Number of Islands | 200 | DFS/BFS on Grid | ☐ |
| 53 | Rotting Oranges | 994 | Multi-source BFS | ☐ |
| 54 | Course Schedule II | 210 | Topological Sort | ☐ |
| 55 | Redundant Connection | 684 | Union-Find | ☐ |
| 56 | Network Delay Time | 743 | Dijkstra | ☐ |
| 57 | Is Graph Bipartite | 785 | BFS/DFS Coloring | ☐ |
| 58 | Clone Graph | 133 | DFS + HashMap | ☐ |
| 59 | Pacific Atlantic Water Flow | 417 | Multi-source DFS | ☐ |

### Hard
| # | Problem | LC | Pattern | Status |
|---|---------|-----|---------|--------|
| 60 | Min Cost to Connect All Points | 1584 | MST (Prim/Kruskal) | ☐ |
| 61 | Word Ladder | 127 | BFS | ☐ |

**Follow-ups & Variations:**
- **Number of Islands →** "Count distinct island shapes?" → Serialize DFS path, use HashSet. "Max area island?" → LC 695, track size during DFS. "Number of islands in a stream (online)?" → Union-Find, process cells one by one. "What if the grid is too large for memory?" → Divide into chunks, merge borders with Union-Find. "Surrounded regions (flip O to X)?" → LC 130, DFS from borders first.
- **Rotting Oranges →** "What if some cells are walls?" → Skip walls in BFS. "What if rotting takes different times per direction?" → Dijkstra instead of BFS. "Walls and Gates (distance to nearest gate)?" → LC 286, same multi-source BFS. "What's the difference between multi-source BFS and running BFS from each source?" → Multi-source is O(V+E), per-source is O(V×(V+E)).
- **Course Schedule →** "Just detect if cycle exists (no ordering)?" → LC 207, same approach but only return true/false. "Find all possible orderings?" → Backtracking on topological sort. "Longest path in DAG (parallel courses)?" → LC 2050, DP on topological order. "What if courses have prerequisites AND corequisites?" → Model as different edge types. "How does this relate to build systems?" → Make/Gradle use topological sort for compilation order.
- **Redundant Connection →** "What if it's a directed graph?" → LC 685, much harder — need to handle two cases (extra parent or cycle). "Find ALL redundant edges?" → Remove edges one by one, check connectivity. "What if we want minimum weight redundant edge?" → Process edges by weight, return first that creates cycle.
- **Network Delay Time →** "What if edges have negative weights?" → Bellman-Ford O(VE). "Detect negative cycle?" → Run Bellman-Ford V times, if still relaxing → negative cycle. "Shortest path between all pairs?" → Floyd-Warshall O(V³). "What if graph is unweighted?" → BFS is simpler and faster. "A* search?" → Dijkstra + heuristic (admissible heuristic guarantees optimality).
- **Bipartite →** "What's the application?" → Graph coloring, matching problems, conflict detection. "Can you check bipartiteness with Union-Find?" → Yes, union neighbors' neighbors. "What if graph is directed?" → Bipartiteness is defined for undirected; for directed, check if underlying undirected graph is bipartite.
- **Word Ladder →** "Bidirectional BFS?" → Start from both ends, meet in middle — reduces search space from O(b^d) to O(b^(d/2)). "Find all shortest transformation sequences?" → LC 126 (hard), BFS + DFS backtracking. "What if dictionary is huge?" → Use wildcard patterns: `h*t` matches `hot`, `hat`, etc. Build adjacency via pattern map.

---

## 7. Dynamic Programming

### Easy
| # | Problem | LC | Pattern | Status |
|---|---------|-----|---------|--------|
| 62 | Climbing Stairs | 70 | 1D Linear | ☐ |
| 63 | House Robber | 198 | 1D Linear | ☐ |
| 64 | Maximum Subarray (Kadane's) | 53 | 1D Linear | ☐ |

**Follow-ups & Variations:**
- **Climbing Stairs →** "What if you can take 1, 2, or 3 steps?" → `dp[i] = dp[i-1] + dp[i-2] + dp[i-3]`. "What if step costs vary?" → LC 746 Min Cost Climbing Stairs. "What if certain steps are broken?" → Skip those in recurrence. "Can you solve in O(log n)?" → Matrix exponentiation on the Fibonacci recurrence.
- **House Robber →** "Circular arrangement (first and last are adjacent)?" → LC 213, run twice: skip first OR skip last. "On a binary tree?" → LC 337, DFS returning [rob, notRob] pair. "What if houses have alarm systems that trigger after K consecutive robs?" → Extend state to track consecutive count.
- **Kadane's →** "Return the actual subarray?" → Track start index (reset when starting fresh) and end index (when maxSum updates). "Maximum circular subarray?" → LC 918, answer = max(kadane, totalSum - minSubarray). Edge case: all negative → don't use circular. "Maximum product subarray?" → LC 152, track both max and min (negative × negative = positive). "At most K transactions (stock)?" → State machine DP.

### Medium
| # | Problem | LC | Pattern | Status |
|---|---------|-----|---------|--------|
| 65 | Word Break | 139 | 1D DP | ☐ |
| 66 | Partition Equal Subset Sum | 416 | 0/1 Knapsack | ☐ |
| 67 | Coin Change | 322 | Unbounded Knapsack | ☐ |
| 68 | Coin Change II (count ways) | 518 | Unbounded Knapsack | ☐ |
| 69 | Longest Common Subsequence | 1143 | 2D String DP | ☐ |
| 70 | Edit Distance | 72 | 2D String DP | ☐ |
| 71 | Longest Increasing Subsequence | 300 | LIS | ☐ |
| 72 | Unique Paths | 62 | Grid DP | ☐ |
| 73 | Maximal Square | 221 | Grid DP | ☐ |
| 74 | Best Time to Buy/Sell Stock with Cooldown | 309 | State Machine DP | ☐ |

### Hard
| # | Problem | LC | Pattern | Status |
|---|---------|-----|---------|--------|
| 75 | Burst Balloons | 312 | Interval DP | ☐ |

**Follow-ups & Variations:**
- **Word Break →** "Return all possible sentences?" → LC 140, backtracking + memoization. "What if dictionary is huge?" → Build a Trie from dictionary, match prefixes. "What if words can overlap?" → Different problem — greedy won't work, need DP.
- **Partition Equal Subset Sum →** "Partition into K equal subsets?" → LC 698, backtracking with bitmask. "Find the partition that minimizes difference?" → LC 1049, knapsack to find closest to sum/2. "What if elements can be negative?" → Offset all values to make positive, adjust target.
- **Coin Change →** "Why `amount + 1` instead of `Integer.MAX_VALUE`?" → Overflow: `MAX_VALUE + 1` wraps to `MIN_VALUE`. "Reconstruct which coins were used?" → Track `parent[i]` = coin used to reach amount i. "What if coins have limited supply?" → Bounded knapsack. "Fewest coins with exactly K coins?" → 2D DP: `dp[amount][coins_used]`.
- **LCS →** "Reconstruct the actual subsequence?" → Backtrack from `dp[m][n]`: match → go diagonal + include char; else → go toward larger value. "Longest common substring (contiguous)?" → Reset to 0 on mismatch instead of taking max. "LCS of 3 strings?" → 3D DP table. "Space optimization?" → O(min(m,n)) using rolling array.
- **Edit Distance →** "Only insertions and deletions (no replace)?" → Edit distance = m + n - 2×LCS. "What if operations have different costs?" → Use costs in the min() calculation. "How is this used in practice?" → Spell checkers, DNA sequence alignment, diff tools. "Fuzzy string matching in search?" → Compute edit distance, return results within threshold.
- **LIS →** "O(n log n) solution?" → Patience sorting with binary search on tails array. "Return the actual subsequence?" → Track parent pointers during binary search. "Russian Doll Envelopes (2D)?" → LC 354, sort by width asc then height desc, LIS on heights. "Longest non-decreasing?" → Use upper_bound instead of lower_bound in binary search. "Number of LIS?" → LC 673, track count[] alongside length[].
- **Stock with Cooldown →** "Without cooldown?" → LC 122, greedy (buy every valley, sell every peak). "With transaction fee?" → LC 714, same state machine, subtract fee on sell. "At most K transactions?" → LC 188, add transaction count to state. "At most 2 transactions?" → LC 123, special case of K=2 with 4 states.
- **Burst Balloons →** "Why think about LAST balloon to burst?" → Makes subproblems independent — left and right intervals don't interact. "Matrix chain multiplication?" → Same interval DP pattern. "Minimum cost to merge stones?" → LC 1000, interval DP with constraint on merge size.

---

## 8. Greedy & Backtracking

### Medium
| # | Problem | LC | Pattern | Status |
|---|---------|-----|---------|--------|
| 76 | Non-overlapping Intervals | 435 | Greedy Interval | ☐ |
| 77 | Jump Game | 55 | Greedy Reach | ☐ |
| 78 | Jump Game II | 45 | Greedy Reach | ☐ |
| 79 | Task Scheduler | 621 | Greedy Scheduling | ☐ |
| 80 | Subsets | 78 | Backtracking | ☐ |
| 81 | Permutations | 46 | Backtracking | ☐ |
| 82 | Combination Sum | 39 | Backtracking | ☐ |
| 83 | Word Search | 79 | Grid Backtracking | ☐ |

### Hard
| # | Problem | LC | Pattern | Status |
|---|---------|-----|---------|--------|
| 84 | N-Queens | 51 | Constraint Backtracking | ☐ |

**Follow-ups & Variations:**
- **Non-overlapping Intervals →** "Sort by start or end?" → End time — greedy proof: earliest end leaves most room. "Merge intervals instead of removing?" → LC 56, sort by start. "Insert into non-overlapping set?" → LC 57. "Minimum number of meeting rooms?" → LC 253, sweep line or min-heap.
- **Jump Game →** "Minimum jumps?" → LC 45, greedy BFS-like approach. "What if you can jump backward too?" → BFS on index graph. "What if jump costs vary?" → Dijkstra or DP. "Can you reach from any position to any other?" → Check if max reach covers all positions.
- **Task Scheduler →** "Why is the answer `max(tasks.length, (maxFreq-1)*(n+1) + countOfMax)`?" → Arrange most frequent tasks first with gaps, fill gaps with others. "What if tasks have dependencies?" → Topological sort + scheduling. "What if tasks have different durations?" → Weighted scheduling, much harder.
- **Subsets →** "Subsets with duplicates?" → LC 90, sort first, skip duplicates at same level. "Subsets of size K?" → Add size constraint to backtracking. "Power set iteratively?" → Bit manipulation: iterate 0 to 2^n-1, each bit = include/exclude. "How many subsets?" → 2^n. "Sum of all subset sums?" → Each element appears in 2^(n-1) subsets.
- **Permutations →** "With duplicates?" → LC 47, sort + skip same value at same position. "Next permutation?" → LC 31, find rightmost ascent, swap, reverse suffix. "Kth permutation?" → LC 60, factorial number system. "Count permutations with constraints?" → DP with bitmask.
- **Combination Sum →** "Each number used once?" → LC 40, sort + skip duplicates. "Exactly K numbers?" → LC 216. "Combinations of size K from 1..N?" → LC 77. "What if candidates include negatives?" → Need to add a depth limit to prevent infinite recursion.
- **Word Search →** "Find all words in board?" → LC 212 (hard), Trie + backtracking. "Why not use visited set instead of modifying board?" → Modifying board is O(1) space; visited set is O(m×n). "Can you use DP?" → No, because paths can't revisit cells — backtracking is necessary.
- **N-Queens →** "How many solutions for N=8?" → 92. "Return just the count?" → Same backtracking, increment counter instead of storing. "N-Queens II with additional constraints (no three in a line)?" → Add diagonal/anti-diagonal checks. "Sudoku solver?" → LC 37, same constraint backtracking pattern.

---

## 9. Heap / Priority Queue

### Medium
| # | Problem | LC | Pattern | Status |
|---|---------|-----|---------|--------|
| 85 | Kth Largest Element | 215 | Heap / Quickselect | ☐ |
| 86 | Top K Frequent Elements | 347 | Heap + HashMap | ☐ |
| 87 | Meeting Rooms II | 253 | Min-Heap | ☐ |
| 88 | Kth Smallest in Sorted Matrix | 378 | K-way Merge Heap | ☐ |

### Hard
| # | Problem | LC | Pattern | Status |
|---|---------|-----|---------|--------|
| 89 | Find Median from Data Stream | 295 | Two Heaps | ☐ |
| 90 | Merge K Sorted Lists | 23 | Min-Heap | ☐ |

**Follow-ups & Variations:**
- **Kth Largest →** "Heap vs Quickselect?" → Heap: O(n log k), always works. Quickselect: O(n) average, O(n²) worst. "In a stream?" → Maintain min-heap of size K, each new element: if > heap top, replace. "Kth smallest?" → Max-heap of size K, or min-heap of all elements. "Median?" → Two heaps (LC 295).
- **Top K Frequent →** "Can you do better than O(n log k)?" → Bucket sort: index = frequency, O(n). "Top K in a stream?" → Count-Min Sketch for approximate frequency + heap. "Top K across distributed systems?" → Each node computes local top-K, merge at coordinator. "What if K changes?" → Recompute or maintain sorted structure.
- **Meeting Rooms II →** "Sweep line vs heap approach?" → Sweep line: O(n log n), simpler. Heap: O(n log n), more intuitive. "What if meetings have priorities?" → Schedule high-priority first, preempt if needed. "Find the actual room assignments?" → Track which meetings go to which room in the heap.
- **Find Median from Data Stream →** "Why two heaps?" → Max-heap for lower half, min-heap for upper half. Median = top of max-heap (odd) or average of both tops (even). "What if we need to remove elements too?" → Lazy deletion with a HashSet of removed elements. "Sliding window median?" → LC 480, two heaps + lazy deletion. "What if data is sorted?" → Just track middle pointer.
- **Merge K Sorted Lists →** "Time complexity?" → O(N log K) where N = total nodes, K = number of lists. "Divide and conquer approach?" → Merge pairs recursively, same complexity. "What if lists are on different machines?" → External merge sort — same K-way merge with disk I/O.

---

## 10. Bit Manipulation

| # | Problem | LC | Pattern | Status |
|---|---------|-----|---------|--------|
| 91 | Single Number | 136 | XOR | ☐ |
| 92 | Number of 1 Bits | 191 | Bit Counting | ☐ |
| 93 | Sum of Two Integers | 371 | Bit Math | ☐ |
| 94 | Counting Bits | 338 | DP + Bits | ☐ |
| 95 | Reverse Bits | 190 | Bit Manipulation | ☐ |

**Follow-ups & Variations:**
- **Single Number →** "Two elements appear once, rest twice?" → LC 260, XOR all → find a set bit → partition into two groups by that bit → XOR each group. "One element appears once, rest three times?" → LC 137, count bits modulo 3. "Missing number in 0..n?" → XOR all indices with all values, or sum formula.
- **Number of 1 Bits →** "Why `n & (n-1)` clears lowest set bit?" → `n-1` flips all bits from lowest set bit rightward. AND with n clears that bit. "Count bits for all numbers 0 to n?" → LC 338, `dp[i] = dp[i >> 1] + (i & 1)` or `dp[i] = dp[i & (i-1)] + 1`. "Hamming distance between two numbers?" → XOR them, count 1-bits.
- **Sum Without +/- →** "How does it work?" → XOR = sum without carry, AND << 1 = carry. Repeat until carry is 0. "What about subtraction?" → Add the two's complement. "Multiply without *?" → Russian peasant multiplication (shift + add).

---

## 11. Binary Search

| # | Problem | LC | Pattern | Status |
|---|---------|-----|---------|--------|
| 96 | Binary Search | 704 | Standard | ☐ |
| 97 | Search in Rotated Sorted Array | 33 | Modified BS | ☐ |
| 98 | Koko Eating Bananas | 875 | BS on Answer | ☐ |
| 99 | Search a 2D Matrix | 74 | BS on Flattened | ☐ |
| 100 | Search a 2D Matrix II | 240 | Staircase Search | ☐ |
| 101 | Find First and Last Position | 34 | Boundary BS | ☐ |

**Follow-ups & Variations:**
- **Search in Rotated Array →** "With duplicates?" → LC 81, worst case O(n) when all elements are same. "Find the rotation point (minimum)?" → LC 153/154. "How many times was array rotated?" → Index of minimum element. "Search in a rotated sorted linked list?" → Find pivot first, then binary search on correct half.
- **BS on Answer (Koko) →** "How do you identify BS-on-answer problems?" → When asked "minimum X such that condition is satisfied" and condition is monotonic. "Split array largest sum?" → LC 410, BS on answer. "Capacity to ship packages?" → LC 1011, same pattern. "Magnetic force between balls?" → LC 1552. "Key insight?" → Binary search on the answer space, check feasibility with a greedy/linear scan.
- **Search 2D Matrix II →** "Why start from top-right?" → Each step eliminates a row or column. "Can you use binary search per row?" → Yes, O(m log n), but staircase is O(m+n). "What if matrix is sorted row-wise only?" → Binary search per row, O(m log n).
- **Find First and Last Position →** "Why two separate binary searches?" → One finds leftmost (go left on match), one finds rightmost (go right on match). "Count occurrences?" → rightIdx - leftIdx + 1. "What if element doesn't exist?" → Both searches return -1.

---

## 12. String Matching

| # | Problem | LC | Pattern | Status |
|---|---------|-----|---------|--------|
| 102 | Longest Duplicate Substring | 1044 | Rabin-Karp + BS | ☐ |
| 103 | Shortest Palindrome | 214 | KMP | ☐ |

**Follow-ups & Variations:**
- **Rabin-Karp →** "How do you handle hash collisions?" → Double hashing (two different bases/mods) or verify match with actual string comparison. "Why rolling hash?" → Recompute hash in O(1) by removing first char and adding new char. "What base and mod to use?" → Large prime mod (10^9+7), base = 31 or 26. "How is this used in plagiarism detection?" → Hash all K-grams, compare sets.
- **KMP →** "What is the failure function?" → `fail[i]` = length of longest proper prefix of pattern[0..i] that is also a suffix. "Time to build failure function?" → O(m). "When is KMP better than Rabin-Karp?" → KMP has no hash collisions, guaranteed O(n+m). Rabin-Karp is simpler and better for multi-pattern search.

---

## 13. Intervals

| # | Problem | LC | Pattern | Status |
|---|---------|-----|---------|--------|
| 104 | Merge Intervals | 56 | Sort + Merge | ☐ |
| 105 | Insert Interval | 57 | Three-phase | ☐ |
| 106 | Non-overlapping Intervals | 435 | Greedy | ☐ |
| 107 | Meeting Rooms II | 253 | Sweep Line / Heap | ☐ |
| 108 | Interval List Intersections | 986 | Two Pointers | ☐ |

**Follow-ups & Variations:**
- **Merge Intervals →** "What if intervals are coming in a stream?" → Maintain a sorted set (TreeMap), merge on insert. "Merge in O(n) without sorting?" → Only if already sorted. "What if intervals have labels/IDs?" → Track which intervals merged into which.
- **Insert Interval →** "What if you need to insert multiple intervals?" → Merge all new intervals first, then merge with existing. "What's the time complexity?" → O(n) for sorted input. "Can you do it in-place?" → Yes, but shifting is O(n) anyway.
- **Meeting Rooms →** "Can you attend all meetings (no overlap)?" → LC 252, sort by start, check adjacent pairs. "Minimum rooms?" → LC 253. "Assign specific rooms to minimize switches?" → Graph coloring variant. "What if meetings have priorities?" → Schedule high-priority first, preempt lower.

---

## 14. Math Techniques

| # | Problem | LC | Pattern | Status |
|---|---------|-----|---------|--------|
| 109 | Majority Element | 169 | Boyer-Moore Voting | ☐ |
| 110 | Pow(x, n) | 50 | Fast Exponentiation | ☐ |
| 111 | Count Primes | 204 | Sieve of Eratosthenes | ☐ |
| 112 | Shuffle an Array | 384 | Fisher-Yates | ☐ |
| 113 | Random Pick with Weight | 528 | Prefix Sum + BS | ☐ |

**Follow-ups & Variations:**
- **Majority Element →** "Element appearing > n/3 times?" → LC 229, Boyer-Moore with TWO candidates. "Prove Boyer-Moore correctness?" → The majority element survives all cancellations because it has more than n/2 votes. "What if no majority exists?" → Second pass to verify count. "In a stream?" → Same algorithm works, O(1) space.
- **Pow(x, n) →** "Why not just multiply n times?" → O(n) vs O(log n). "Handle negative n?" → `pow(x, -n) = 1/pow(x, n)`. Watch `n = Integer.MIN_VALUE` — negate overflows! Use long. "Modular exponentiation?" → Same algorithm, take mod at each step. Used in RSA encryption.
- **Fisher-Yates →** "Prove each permutation is equally likely?" → At step i, element i is swapped with any of positions [i, n-1] with equal probability 1/(n-i). Product of all probabilities = 1/n!. "Reservoir sampling for stream?" → LC 382, keep item with probability 1/k when seeing kth element. "Weighted random selection?" → Prefix sum + binary search (LC 528).

---

## 15. Advanced Topics ⚠️ [OPTIONAL — Rarely Asked at SDE-2]

> These are competitive programming topics. Skip unless targeting Google L5+ or you've mastered everything above.

| # | Problem | LC | Pattern | Status |
|---|---------|-----|---------|--------|
| 114 | Sum of Subarray Minimums | 907 | Monotonic Stack + Contribution | ☐ |
| 115 | Sliding Window Maximum | 239 | Monotonic Deque | ☐ |
| 116 | Shortest Subarray with Sum ≥ K (negatives) | 862 | Prefix Sum + Deque | ☐ |
| 117 | House Robber III | 337 | DP on Trees | ☐ |
| 118 | Binary Tree Cameras | 968 | Greedy on Trees | ☐ |
| 119 | Shortest Path Visiting All Nodes | 847 | BFS + Bitmask | ☐ |
| 120 | Partition to K Equal Sum Subsets | 698 | Bitmask DP | ☐ |
| 121 | The Skyline Problem | 218 | Sweep Line + Heap | ☐ |

**Follow-ups (if asked):**
- **Monotonic Stack Contribution →** "Why does each element contribute to exactly the subarrays where it's the min/max?" → Count subarrays where element is min: left boundary × right boundary. "How to handle duplicates?" → Use strict < on one side, ≤ on the other to avoid double counting.
- **Bitmask DP →** "When is bitmask DP applicable?" → n ≤ 20 (2^20 ≈ 1M states). "TSP?" → `dp[mask][i]` = min cost visiting cities in mask, ending at i. O(2^n × n²). "Can you optimize with meet-in-the-middle?" → Split into two halves, enumerate 2^(n/2) each, combine.

---

## Quick Reference — Pattern Decision Tree

```
What does the problem ask for?
│
├─ "Find pair/triplet with target sum"
│   ├─ Array sorted? → Two Pointers
│   └─ Unsorted? → HashMap (Two Sum pattern)
│
├─ "Subarray with property X"
│   ├─ All positive + contiguous? → Sliding Window
│   ├─ Has negatives + sum = K? → Prefix Sum + HashMap
│   └─ Max/min in window? → Monotonic Deque
│
├─ "Substring with property X"
│   ├─ Fixed length? → Fixed Sliding Window
│   └─ Variable length? → Variable Sliding Window + HashMap
│
├─ "Next greater/smaller element"
│   └─ Monotonic Stack
│
├─ "Shortest path / minimum steps"
│   ├─ Unweighted? → BFS
│   ├─ Weighted (non-negative)? → Dijkstra
│   └─ Weighted (negative)? → Bellman-Ford
│
├─ "Connected components / union"
│   ├─ Static graph? → DFS
│   └─ Dynamic (edges added)? → Union-Find
│
├─ "Ordering with dependencies"
│   └─ Topological Sort (Kahn's BFS)
│
├─ "Number of ways / optimal value"
│   ├─ Choices at each step? → DP
│   ├─ Items with weight/value? → Knapsack DP
│   ├─ Two strings? → 2D DP (LCS/Edit Distance)
│   └─ Intervals [i..j]? → Interval DP
│
├─ "Generate all combinations/permutations"
│   └─ Backtracking
│
├─ "Top K / Kth element"
│   ├─ Static? → Quickselect O(n) avg
│   └─ Stream? → Min-heap of size K
│
├─ "Median in stream"
│   └─ Two Heaps (max-heap + min-heap)
│
├─ "Minimum X such that condition holds"
│   └─ Binary Search on Answer
│
├─ "Overlapping intervals"
│   ├─ Merge? → Sort by start
│   ├─ Count overlaps? → Sweep line
│   └─ Remove minimum? → Greedy (sort by end)
│
├─ "Tree path / subtree property"
│   └─ DFS (postorder for bottom-up, preorder for top-down)
│
└─ "Find unique / missing / duplicate"
    ├─ XOR trick? → Bit Manipulation
    └─ Frequency? → HashMap / int[]
```

---

---

## 16. Missing High-Frequency (Add These!)

> These are Blind 75 / NeetCode 150 staples that were missing from the original sheet.

| # | Problem | LC | Pattern | Status |
|---|---------|-----|---------|--------|
| 122 | Valid Palindrome | 125 | Two Pointers | ☐ |
| 123 | Product of Array Except Self | 238 | Prefix/Suffix Product | ☐ |
| 124 | Trapping Rain Water | 42 | Two Pointers / Stack | ☐ |
| 125 | Set Matrix Zeroes | 73 | In-place Marking | ☐ |
| 126 | Rotate Image | 48 | Matrix Transpose + Reverse | ☐ |
| 127 | Spiral Matrix | 54 | Simulation | ☐ |
| 128 | LRU Cache | 146 | HashMap + Doubly Linked List | ☐ |
| 129 | Longest Substring with At Most K Distinct | 340 | Sliding Window | ☐ |
| 130 | Letter Combinations of Phone Number | 17 | Backtracking | ☐ |
| 131 | Generate Parentheses | 22 | Backtracking | ☐ |
| 132 | House Robber II (Circular) | 213 | DP | ☐ |
| 133 | Maximum Product Subarray | 152 | DP (track min & max) | ☐ |
| 134 | Surrounded Regions | 130 | DFS from Border | ☐ |
| 135 | Max Area of Island | 695 | DFS on Grid | ☐ |

**Follow-ups & Variations:**
- **Product of Array Except Self →** "Without division?" → Left prefix product × right suffix product. "With division?" → Total product / self, but handle zeros. "What if there are multiple zeros?" → All products are 0 except if exactly one zero. "In O(1) extra space?" → Use output array as left prefix, single variable for right.
- **Trapping Rain Water →** "Two-pointer approach?" → Track leftMax and rightMax, process from the smaller side. "Stack approach?" → Monotonic decreasing stack, compute water on pop. "2D version (trapping rain water on a grid)?" → LC 407, BFS with min-heap from borders. "What's the relationship with Largest Rectangle in Histogram?" → Both use monotonic stack, but different formulations.
- **LRU Cache →** "Why HashMap + doubly linked list?" → HashMap gives O(1) lookup, DLL gives O(1) remove/insert at ends. "LFU Cache?" → LC 460, HashMap + frequency buckets (each bucket is a DLL). "Thread-safe LRU?" → ConcurrentHashMap + synchronized DLL, or `LinkedHashMap` with `removeEldestEntry`. "What eviction policy would you use for a CDN?" → LRU for general, LFU for hot content, TTL for time-sensitive.
- **Generate Parentheses →** "How many valid combinations for N pairs?" → Catalan number: C(n) = (2n)! / ((n+1)! × n!). "Can you generate iteratively?" → Yes, BFS approach building strings level by level. "What about generating all valid bracket sequences with multiple types?" → Backtracking with a stack to validate.
- **Maximum Product Subarray →** "Why track both min and max?" → Negative × negative = positive, so today's min can become tomorrow's max. "What if array has zeros?" → Reset both min and max to current element. "Return the actual subarray?" → Track indices like Kadane's.
- **Surrounded Regions →** "Why DFS from borders?" → Border-connected O's can't be surrounded. Mark them, then flip everything else. "What if grid is huge?" → Union-Find with a virtual border node.

---

## Stats

- **Total problems: 135**
- **Core (must-do for SDE-2): 1-113 + 122-135** (128 problems)
- **Advanced (optional): 114-121** (7 problems)
- **Estimated prep time: 5-6 weeks** (3-4 problems/day)

## Suggested Order

1. Arrays/Strings/Hashing (foundation for everything)
2. Two Pointers & Sliding Window (builds on arrays)
3. Stacks & Queues (monotonic stack is high-frequency)
4. Linked Lists (quick wins, pattern-heavy)
5. Trees (DFS/BFS foundation for graphs)
6. Graphs (builds on trees + BFS/DFS)
7. Dynamic Programming (hardest, needs most time)
8. Greedy & Backtracking (often combined with other topics)
9. Heap (top-K pattern is very common)
10. Binary Search (BS on answer is underrated)
11. Intervals, Bit Manipulation, Math (fill gaps)
