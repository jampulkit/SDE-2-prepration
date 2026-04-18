> ✅ **[CORE] — Must-do for SDE-2 interviews.**

# Bit Manipulation

## 1. Foundation

**Bit manipulation works directly on the binary representation of numbers, enabling O(1) operations that would otherwise require loops — it's used for space optimization (bitmasks as sets), mathematical tricks, and finding unique/missing elements.**

Bit operations work directly on binary representations, enabling O(1) operations that would otherwise require loops. Used for space optimization (bitmasks as sets), mathematical tricks, and low-level system programming.

💡 **Intuition:** Every integer is stored as a sequence of 0s and 1s in memory. Bit manipulation lets you operate on these bits directly — like having a row of light switches where you can flip, check, or combine them in specific patterns. XOR is the star of interview problems: it cancels out duplicates (`a ^ a = 0`) and preserves uniques (`a ^ 0 = a`).

**Binary representation in Java** [🔥 Must Know]:
- `int`: 32 bits, signed (two's complement). Range: -2³¹ to 2³¹-1 (~±2.1 billion)
- `long`: 64 bits, signed. Range: -2⁶³ to 2⁶³-1
- Negative numbers: two's complement. `-1` = `11111111 11111111 11111111 11111111` (all 1s)
- `Integer.toBinaryString(n)` — view binary representation (doesn't show leading zeros)

⚙️ **Under the Hood — Two's Complement:**

```
Positive 5:  00000000 00000000 00000000 00000101
Negative -5: 11111111 11111111 11111111 11111011

To get -5: flip all bits of 5 (NOT), then add 1:
  ~5 = 11111111 11111111 11111111 11111010
  +1 = 11111111 11111111 11111111 11111011 = -5

Why two's complement? Addition works the same for positive and negative numbers.
The CPU doesn't need separate circuits for subtraction — it just adds the negative.
```

**Bitwise operators:**

| Operator | Symbol | Example (5=101, 3=011) | Result | Mnemonic |
|----------|--------|------------------------|--------|----------|
| AND | `&` | `101 & 011` | `001` (1) | Both bits must be 1 |
| OR | `\|` | `101 \| 011` | `111` (7) | Either bit can be 1 |
| XOR | `^` | `101 ^ 011` | `110` (6) | Bits must differ |
| NOT | `~` | `~101` | `...11111010` (-6) | Flip all bits |
| Left shift | `<<` | `101 << 1` | `1010` (10) | Multiply by 2 |
| Right shift (signed) | `>>` | `101 >> 1` | `10` (2) | Divide by 2 (preserves sign) |
| Right shift (unsigned) | `>>>` | `-1 >>> 1` | `01111...1` (MAX_VALUE) | Divide by 2 (fills with 0) |

**Essential bit tricks** [🔥 Must Know]:

| Trick | Code | What It Does | Why It Works |
|-------|------|-------------|-------------|
| Check if bit i is set | `(n >> i) & 1` | Returns 1 if bit i is 1 | Shift bit i to position 0, mask with 1 |
| Set bit i | `n \| (1 << i)` | Sets bit i to 1 | OR with a mask that has only bit i set |
| Clear bit i | `n & ~(1 << i)` | Sets bit i to 0 | AND with a mask that has all bits except i |
| Toggle bit i | `n ^ (1 << i)` | Flips bit i | XOR: 1^1=0, 0^1=1 |
| Check power of 2 | `n > 0 && (n & (n-1)) == 0` | True if exactly one bit set | n-1 flips all bits below the single set bit |
| Clear lowest set bit | `n & (n - 1)` | Turns off rightmost 1 | n-1 borrows from the lowest 1, flipping it and all lower bits |
| Isolate lowest set bit | `n & (-n)` | Keeps only rightmost 1 | -n = ~n + 1, which flips all bits above lowest 1 |
| Check even/odd | `n & 1` | 0 = even, 1 = odd | Last bit determines parity |

⚙️ **Under the Hood — Why `n & (n-1)` Clears the Lowest Set Bit:**

```
n   = 12 = 1100
n-1 = 11 = 1011  (borrowing flips the lowest 1 and all bits below it)
n & (n-1) = 1000 = 8  (lowest set bit cleared!)

n   = 10 = 1010
n-1 =  9 = 1001
n & (n-1) = 1000 = 8

This is Brian Kernighan's trick — used to count set bits in O(number of set bits) time.
```

**XOR properties** [🔥 Must Know]:
- `a ^ a = 0` (self-cancellation — duplicates cancel out)
- `a ^ 0 = a` (identity — XOR with 0 preserves the value)
- `a ^ b = b ^ a` (commutative)
- `(a ^ b) ^ c = a ^ (b ^ c)` (associative)

These properties make XOR perfect for "find the unique element" problems: XOR all elements, pairs cancel to 0, leaving the unique one.

**Java utility methods:**
```java
Integer.bitCount(n)                  // number of 1-bits (popcount) — O(1) hardware instruction
Integer.highestOneBit(n)             // value of highest set bit (e.g., 12→8)
Integer.lowestOneBit(n)              // value of lowest set bit (e.g., 12→4)
Integer.numberOfLeadingZeros(n)      // zeros before first 1 from left
Integer.numberOfTrailingZeros(n)     // zeros after last 1 from right
Integer.reverse(n)                   // reverse all 32 bits
```

🎯 **Likely Follow-ups:**
- **Q:** What's the difference between `>>` and `>>>`?
  **A:** `>>` is signed right shift — it fills the leftmost bits with the sign bit (0 for positive, 1 for negative). `>>>` is unsigned right shift — it always fills with 0. For positive numbers, they're identical. For negative numbers, `>>>` turns them positive.
- **Q:** Why does `1 << 31` give a negative number in Java?
  **A:** `1 << 31` sets the sign bit, giving `Integer.MIN_VALUE` = -2³¹. Java's `int` is signed, so the highest bit is the sign bit. Use `1L << 31` for a positive long value.

> 🔗 **See Also:** [05-java/01-core-java.md](../05-java/01-core-java.md) for Java primitive types and their binary representations.

---

## 2. Core Patterns

### Pattern 1: XOR for Finding Unique Elements [🔥 Must Know]

**XOR all elements together — duplicates cancel out (a^a=0), leaving only the unique element.**

**When to recognize it:** "Every element appears twice except one", "find the single number", "missing number."

💡 **Intuition:** XOR is like a light switch. Flipping it twice returns to the original state (a^a=0). If you XOR all numbers in an array where every number appears twice except one, all the pairs cancel out, leaving just the unique number.

```java
// LC 136: Single Number [🔥 Must Do]
public int singleNumber(int[] nums) {
    int result = 0;
    for (int n : nums) result ^= n; // pairs cancel: a^a=0, leaving the unique
    return result;
}
```

**Dry run:** `nums = [4, 1, 2, 1, 2]`

```
result = 0
0 ^ 4 = 4
4 ^ 1 = 5  (100 ^ 001 = 101)
5 ^ 2 = 7  (101 ^ 010 = 111)
7 ^ 1 = 6  (111 ^ 001 = 110)  ← first 1 cancels
6 ^ 2 = 4  (110 ^ 010 = 100)  ← first 2 cancels

Result: 4 ✓ (the unique element)
```

**LC 268: Missing Number — XOR approach:**
```java
public int missingNumber(int[] nums) {
    int xor = nums.length; // start with n (the missing range is 0 to n)
    for (int i = 0; i < nums.length; i++) {
        xor ^= i ^ nums[i]; // XOR index and value — matching pairs cancel
    }
    return xor;
}
```

💡 **Intuition:** XOR all indices (0 to n) with all values. Every number that appears in both the index range and the array cancels out. The one that's in the index range but NOT in the array survives — that's the missing number.

**LC 260: Single Number III — Two unique elements** [🔥 Must Do]:

```java
public int[] singleNumber(int[] nums) {
    // Step 1: XOR all → gives xor of the two unique numbers (a ^ b)
    int xor = 0;
    for (int n : nums) xor ^= n;

    // Step 2: Find any bit where a and b differ (use lowest set bit)
    int diffBit = xor & (-xor); // isolate lowest set bit

    // Step 3: Split into two groups based on that bit, XOR each group
    int a = 0, b = 0;
    for (int n : nums) {
        if ((n & diffBit) == 0) a ^= n; // group where that bit is 0
        else b ^= n;                     // group where that bit is 1
    }
    return new int[]{a, b};
}
```

⚙️ **Under the Hood — Why Splitting by a Differing Bit Works:**
After XOR-ing all elements, we get `a ^ b` (the two unique numbers XOR'd together). Any set bit in this result means `a` and `b` differ at that position. By splitting all numbers into two groups based on that bit, `a` and `b` end up in different groups. Within each group, all other numbers still appear in pairs (they go to the same group regardless of which unique number they match). So XOR-ing each group gives us `a` and `b` separately.

**Edge Cases:**
- ☐ Single element array → that element is the answer (for Single Number)
- ☐ Missing number is 0 → XOR still works (0 ^ anything = anything)
- ☐ Missing number is n → XOR with n at the start handles this
- ☐ Negative numbers → XOR works on all integers (two's complement)

🎯 **Likely Follow-ups:**
- **Q:** What if every element appears 3 times except one?
  **A:** Count bits: for each bit position, sum the bits across all numbers. If the sum % 3 ≠ 0, the unique number has a 1 at that position. Or use the state machine approach (ones/twos variables).
- **Q:** Can you find the missing number without XOR?
  **A:** Yes — sum formula: `expected = n*(n+1)/2`, `actual = sum(nums)`, `missing = expected - actual`. But this can overflow for large n. XOR doesn't have overflow issues.

---

### Pattern 2: Counting Bits

**Use `n & (n-1)` to clear the lowest set bit one at a time — the number of iterations equals the number of set bits.**

```java
// LC 191: Number of 1 Bits (Hamming Weight) [🔥 Must Do]
public int hammingWeight(int n) {
    int count = 0;
    while (n != 0) {
        n &= (n - 1); // clear lowest set bit (Brian Kernighan's trick)
        count++;
    }
    return count;
}
// Or simply: return Integer.bitCount(n);
```

```java
// LC 338: Counting Bits — count 1-bits for every number 0 to n
public int[] countBits(int n) {
    int[] dp = new int[n + 1];
    for (int i = 1; i <= n; i++) {
        dp[i] = dp[i >> 1] + (i & 1); // dp[i/2] + last bit
        // Alternative: dp[i] = dp[i & (i-1)] + 1; // clear lowest bit + 1
    }
    return dp;
}
```

---

### Pattern 3: Bitmask as Set (Subset Enumeration)

**Represent a subset of n elements as an n-bit integer — bit i is 1 if element i is included. This enables O(1) set operations (union, intersection, membership).**

**When to recognize it:** Need to represent subsets of a small set (n ≤ 20). Each bit represents whether an element is included.

💡 **Intuition:** A bitmask is a compact way to represent a set. For a set of 5 elements {A, B, C, D, E}, the bitmask `10110` means {B, C, E} are included. Set operations become bit operations: union = OR, intersection = AND, membership = check bit.

```java
// Enumerate all subsets of {0, 1, ..., n-1}
for (int mask = 0; mask < (1 << n); mask++) {
    // mask represents a subset
    for (int i = 0; i < n; i++) {
        if ((mask >> i & 1) == 1) {
            // element i is in this subset
        }
    }
}

// Enumerate all subsets of a given mask (including empty set)
for (int sub = mask; sub > 0; sub = (sub - 1) & mask) {
    // sub is a non-empty subset of mask
}
// Don't forget to handle sub = 0 (empty subset) separately if needed
```

**Bitmask DP** — used when state is a subset:
```java
// Traveling Salesman Problem (TSP) — O(2^n × n²)
// dp[mask][i] = min cost to visit all cities in mask, ending at city i
int[][] dp = new int[1 << n][n];
// Base: dp[1 << start][start] = 0
// Transition: dp[mask | (1 << j)][j] = min(dp[mask][i] + dist[i][j]) for all i in mask
```

---

### Pattern 4: Bit Manipulation Math

**Implement arithmetic operations using only bit operations — XOR gives sum without carry, AND gives carry positions.**

```java
// LC 371: Sum of Two Integers (without + or -) [🔥 Must Do]
public int getSum(int a, int b) {
    while (b != 0) {
        int carry = (a & b) << 1; // carry: where both bits are 1, shifted left
        a = a ^ b;                 // sum without carry: XOR
        b = carry;                 // add carry in next iteration
    }
    return a;
}
```

💡 **Intuition:** Binary addition works like decimal addition. `1 + 1 = 10` (sum=0, carry=1). XOR gives the sum bits (without carry). AND gives the carry bits (where both are 1). Shift carry left (it goes to the next position). Repeat until no carry remains.

```
a = 5 (101), b = 3 (011):
  Iteration 1: carry = (101 & 011) << 1 = 001 << 1 = 010
                a = 101 ^ 011 = 110, b = 010
  Iteration 2: carry = (110 & 010) << 1 = 010 << 1 = 100
                a = 110 ^ 010 = 100, b = 100
  Iteration 3: carry = (100 & 100) << 1 = 100 << 1 = 1000
                a = 100 ^ 100 = 000, b = 1000
  Iteration 4: carry = (000 & 1000) << 1 = 0
                a = 000 ^ 1000 = 1000 = 8, b = 0 → STOP

Result: 8 = 5 + 3 ✓
```

---

### Pattern 5: Reverse / Rotate Bits

```java
// LC 190: Reverse Bits
public int reverseBits(int n) {
    int result = 0;
    for (int i = 0; i < 32; i++) {
        result = (result << 1) | (n & 1); // shift result left, add lowest bit of n
        n >>= 1;                           // shift n right
    }
    return result;
}
```

---

## 3. Patterns Summary Table

| # | Pattern | When to Use | Key Idea | Time | Space | Example |
|---|---------|------------|----------|------|-------|---------|
| 1 | XOR unique | Find single/missing element | a^a=0, a^0=a | O(n) | O(1) | Single Number (LC 136) |
| 2 | Counting bits | Count set bits, hamming distance | n&(n-1) clears lowest bit | O(k) k=set bits | O(1) | Number of 1 Bits (LC 191) |
| 3 | Bitmask as set | Subset enumeration, bitmask DP | Bit i = element i included | O(2ⁿ) | O(2ⁿ) | Subsets, TSP |
| 4 | Bit math | Add/multiply without operators | XOR=sum, AND<<1=carry | O(32) | O(1) | Sum of Two Integers (LC 371) |
| 5 | Reverse bits | Reverse/rotate binary | Shift and OR bit by bit | O(32) | O(1) | Reverse Bits (LC 190) |

---

## 4. LeetCode Problem List (Must-Solve)

### Easy

| # | Problem Name | LC # | Pattern(s) | Why Important |
|---|-------------|------|-----------|---------------|
| 1 | Single Number | 136 | XOR | [🔥 Must Do] XOR fundamentals |
| 2 | Number of 1 Bits | 191 | Counting bits | [🔥 Must Do] Brian Kernighan's trick |
| 3 | Counting Bits | 338 | DP + bits | DP relation with bits |
| 4 | Reverse Bits | 190 | Reverse | Bit-by-bit reversal |
| 5 | Missing Number | 268 | XOR / math | [🔥 Must Do] Multiple approaches |
| 6 | Power of Two | 231 | n & (n-1) | Single bit check |
| 7 | Hamming Distance | 461 | XOR + count | XOR then count bits |
| 8 | Add Binary | 67 | Bit addition | String-based binary add |

### Medium

| # | Problem Name | LC # | Pattern(s) | Why Important |
|---|-------------|------|-----------|---------------|
| 1 | Single Number II | 137 | Bit counting / state machine | Every element 3 times except one |
| 2 | Single Number III | 260 | XOR + split | [🔥 Must Do] Two unique elements |
| 3 | Sum of Two Integers | 371 | Bit math | [🔥 Must Do] Add without + |
| 4 | Divide Two Integers | 29 | Bit shifting | Divide without / |
| 5 | Bitwise AND of Numbers Range | 201 | Common prefix | [🔥 Must Do] Find common prefix |
| 6 | Subsets | 78 | Bitmask enumeration | Bitmask approach to subsets |
| 7 | Gray Code | 89 | Bit pattern | `i ^ (i >> 1)` |
| 8 | UTF-8 Validation | 393 | Bit checking | Validate byte patterns |
| 9 | Maximum XOR of Two Numbers in Array | 421 | Trie + XOR | Bit-by-bit trie |
| 10 | Minimum Flips to Make a OR b Equal to c | 1318 | Bit comparison | Per-bit analysis |

### Hard

| # | Problem Name | LC # | Pattern(s) | Why Important |
|---|-------------|------|-----------|---------------|
| 1 | Shortest Path Visiting All Nodes | 847 | BFS + bitmask | State = (node, visited mask) |
| 2 | Find the Shortest Superstring | 943 | Bitmask DP | TSP variant |
| 3 | Number of Valid Words for Each Puzzle | 1178 | Bitmask + subset enumeration | Subset iteration trick |

---

## 5. Interview Strategy

**When to think about bits:**
- "Without using extra space" → XOR might help
- "Without using +, -, *, /" → bit operations
- "Power of 2" → `n & (n-1) == 0`
- "Subsets of small set (n ≤ 20)" → bitmask
- "Find unique/missing element" → XOR
- "Count something per bit position" → iterate 32 bits

**Common mistakes:**
- Forgetting that Java `int` is signed — `>>` preserves sign bit, `>>>` doesn't
- Operator precedence: `&` and `|` have LOWER precedence than `==`. Always use parentheses: `(n & 1) == 0`
- Left shifting beyond 31 bits for `int`: `1 << 32 == 1` in Java (shift amount is mod 32)
- `1 << 31` is `Integer.MIN_VALUE` (negative), not 2³¹. Use `1L << 31` for positive.
- Forgetting `n > 0` check in power-of-2: `0 & (0-1) == 0` but 0 is not a power of 2

---

## 6. Edge Cases & Pitfalls

- ☐ `n = 0` → no bits set, bitCount = 0, not power of 2
- ☐ `n = Integer.MIN_VALUE` → only sign bit set, `n & (n-1) == 0` but it's negative
- ☐ `n = -1` → all 32 bits set, bitCount = 32
- ☐ Negative numbers with right shift: `>>` fills with 1s, `>>>` fills with 0s
- ☐ Overflow when shifting: `1 << 32 == 1` in Java (shift amount mod 32)

---

## 7. Connections to Other Topics

| This Pattern | Connects To | How |
|-------------|-------------|-----|
| Bitmask subsets | [01-dsa/08-greedy-backtracking.md](08-greedy-backtracking.md) | Alternative to recursive subset generation |
| Bitmask DP | [01-dsa/07-dynamic-programming.md](07-dynamic-programming.md) | State compression for small sets (TSP, assignment) |
| XOR | [01-dsa/01-arrays-strings-hashing.md](01-arrays-strings-hashing.md) | XOR for finding missing/duplicate elements |
| Bit counting | [05-java/01-core-java.md](../05-java/01-core-java.md) | Java primitive types and binary representation |
| BFS + bitmask | [01-dsa/06-graphs.md](06-graphs.md) | State-space search with visited set as bitmask |
| Bitwise operations | [07-cs-fundamentals/01-operating-systems.md](../07-cs-fundamentals/01-operating-systems.md) | File permissions, memory management use bit flags |

---

## 8. Revision Checklist

**Essential operations:**
- [ ] `n & (n-1)` — clear lowest set bit (Brian Kernighan's trick)
- [ ] `n & (-n)` — isolate lowest set bit
- [ ] `n & 1` — check odd/even (last bit)
- [ ] `(n >> i) & 1` — check if bit i is set
- [ ] `n | (1 << i)` — set bit i to 1
- [ ] `n & ~(1 << i)` — clear bit i to 0
- [ ] `n ^ (1 << i)` — toggle bit i
- [ ] `n > 0 && (n & (n-1)) == 0` — check power of 2

**XOR properties:**
- [ ] `a ^ a = 0` (self-cancellation), `a ^ 0 = a` (identity)
- [ ] Commutative and associative → order doesn't matter
- [ ] XOR all elements: pairs cancel, unique survives

**Java specifics:**
- [ ] `>>` = signed right shift (preserves sign), `>>>` = unsigned (fills with 0)
- [ ] `Integer.bitCount(n)` for popcount — O(1) hardware instruction
- [ ] Operator precedence: `(n & 1) == 0` needs parentheses! `&` < `==`
- [ ] `1 << 31` = `Integer.MIN_VALUE` (negative). Use `1L << 31` for positive long.
- [ ] Shift amount is mod 32 for int, mod 64 for long: `1 << 32 == 1`

**Top 5 must-solve:**
1. Single Number (LC 136) [Easy] — XOR all elements
2. Number of 1 Bits (LC 191) [Easy] — Brian Kernighan's n&(n-1)
3. Missing Number (LC 268) [Easy] — XOR indices with values
4. Sum of Two Integers (LC 371) [Medium] — XOR for sum, AND<<1 for carry
5. Single Number III (LC 260) [Medium] — Split by differing bit

---

## 📋 Suggested New Documents

### 1. Bitmask DP Deep Dive
- **Placement**: `01-dsa/12-bitmask-dp.md`
- **Why needed**: TSP, assignment problems, "Shortest Path Visiting All Nodes" (LC 847), and "Partition to K Equal Sum Subsets" (LC 698) use bitmask DP extensively. The bitmask-as-set concept is introduced here but the DP applications deserve dedicated coverage.
- **Key subtopics**: TSP with bitmask DP, subset sum with bitmask, profile DP, Hamiltonian path problems, state compression techniques
