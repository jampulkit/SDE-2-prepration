> ✅ **[CORE] — Must-do for SDE-2 interviews.**

# Mathematical Techniques for Interviews

## 1. Foundation

**Math-based problems test number theory, combinatorics, probability, and clever tricks. They often have elegant O(1) or O(n) solutions that replace brute force.**

💡 **Intuition:** Math problems in interviews are not about complex formulas. They test whether you can spot a mathematical property that simplifies the problem. Boyer-Moore uses cancellation. Reservoir sampling uses probability. Modular arithmetic prevents overflow. The pattern is always the same: a brute force approach exists, but a mathematical insight makes it faster or uses less space.

**When math techniques appear:**
- "Find the element that appears more than n/2 times" → Boyer-Moore voting
- "Return result modulo 10⁹+7" → Modular arithmetic
- "Pick a random element from a stream" → Reservoir sampling
- "Count primes" or "GCD/LCM" → Number theory
- "Shuffle an array uniformly" → Fisher-Yates

**Complexity overview:**

| Technique | Time | Space | Key Insight |
|-----------|------|-------|-------------|
| Boyer-Moore Voting | O(n) | O(1) | Majority element survives cancellation |
| GCD (Euclidean) | O(log(min(a,b))) | O(1) | Repeated modulo reduces to 0 |
| Fast Exponentiation | O(log n) | O(1) | Square the base, halve the exponent |
| Sieve of Eratosthenes | O(n log log n) | O(n) | Mark multiples starting from i² |
| Reservoir Sampling | O(n) | O(k) | Each element has equal probability k/n |
| Fisher-Yates Shuffle | O(n) | O(1) | Each permutation equally likely |

> 🔗 **See Also:** [01-dsa/10-bit-manipulation.md](10-bit-manipulation.md) for XOR tricks. [02-system-design/05-estimation-math.md](../02-system-design/05-estimation-math.md) for estimation math.

---

## 2. Core Patterns

### Pattern 1: Boyer-Moore Voting Algorithm [🔥 Must Know]

**Find the majority element (appears more than n/2 times) in O(n) time and O(1) space.**

💡 **Intuition:** Imagine a room full of people, each holding a card with a number. People pair up: if two people have different numbers, both leave the room. After everyone has paired up, whoever is left must be the majority (because the majority has more than half the cards, it can't be fully cancelled out).

```java
// LC 169: Majority Element — O(n) time, O(1) space
public int majorityElement(int[] nums) {
    int candidate = 0, count = 0;
    for (int num : nums) {
        if (count == 0) candidate = num; // new candidate
        count += (num == candidate) ? 1 : -1; // same = +1, different = -1 (cancellation)
    }
    return candidate; // guaranteed majority exists
}
```

⚙️ **Under the Hood, Why Boyer-Moore Works:**

```
Array: [2, 2, 1, 1, 1, 2, 2]

Step 1: candidate=2, count=1
Step 2: candidate=2, count=2  (2 matches)
Step 3: candidate=2, count=1  (1 cancels one 2)
Step 4: candidate=2, count=0  (1 cancels another 2)
Step 5: candidate=1, count=1  (count was 0, new candidate)
Step 6: candidate=1, count=0  (2 cancels the 1)
Step 7: candidate=2, count=1  (count was 0, new candidate)

Result: 2 (correct! 2 appears 4 times out of 7)

Key insight: the majority element appears > n/2 times.
Even if every other element "cancels" one occurrence, the majority still has leftover.
```

**Extension: elements appearing more than n/3 times (LC 229):**

```java
// At most 2 elements can appear more than n/3 times
// Use TWO candidates with TWO counters
public List<Integer> majorityElementII(int[] nums) {
    int c1 = 0, c2 = 0, count1 = 0, count2 = 0;
    for (int num : nums) {
        if (num == c1) count1++;
        else if (num == c2) count2++;
        else if (count1 == 0) { c1 = num; count1 = 1; }
        else if (count2 == 0) { c2 = num; count2 = 1; }
        else { count1--; count2--; } // cancel one of each
    }
    // Verify: count actual occurrences (candidates are not guaranteed)
    List<Integer> result = new ArrayList<>();
    count1 = 0; count2 = 0;
    for (int num : nums) {
        if (num == c1) count1++;
        else if (num == c2) count2++;
    }
    if (count1 > nums.length / 3) result.add(c1);
    if (count2 > nums.length / 3) result.add(c2);
    return result;
}
```

⚠️ **Common Pitfall:** For the n/3 version, you MUST verify the candidates in a second pass. Unlike the n/2 version (where the majority is guaranteed), the n/3 version can produce false candidates.

🎯 **Likely Follow-ups:**
- **Q:** What if no majority element exists?
  **A:** Boyer-Moore still produces a candidate, but it might be wrong. Add a verification pass that counts the candidate's actual occurrences. If count <= n/2, no majority exists.
- **Q:** Can this be extended to n/k?
  **A:** Yes. Use k-1 candidates with k-1 counters. At most k-1 elements can appear more than n/k times. Always verify with a second pass.

---

### Pattern 2: GCD / LCM [🔥 Must Know]

```java
// Euclidean algorithm: O(log(min(a,b)))
int gcd(int a, int b) { return b == 0 ? a : gcd(b, a % b); }
int lcm(int a, int b) { return a / gcd(a, b) * b; } // divide FIRST to avoid overflow
```

⚙️ **Under the Hood, Euclidean Algorithm Step by Step:**

```
gcd(48, 18):
  48 % 18 = 12 → gcd(18, 12)
  18 % 12 = 6  → gcd(12, 6)
  12 % 6  = 0  → gcd(6, 0) → return 6

Why it works: gcd(a, b) = gcd(b, a % b) because any common divisor of a and b
also divides (a % b). The remainder shrinks each step, converging to 0.

Time: O(log(min(a,b))) — the remainder at least halves every two steps (Fibonacci worst case).
```

**GCD of an array:**

```java
int gcdArray(int[] nums) {
    int result = nums[0];
    for (int i = 1; i < nums.length; i++) result = gcd(result, nums[i]);
    return result;
}
```

🎯 **Likely Follow-ups:**
- **Q:** Why divide first in LCM calculation?
  **A:** `a * b` can overflow even if the result fits in an int. `a / gcd(a,b) * b` divides first, keeping intermediate values smaller. Example: a=2*10⁹, b=3*10⁹, gcd=10⁹. `a*b` overflows, but `a/gcd * b` = 2 * 3*10⁹ = 6*10⁹ (fits in long).

---

### Pattern 3: Modular Arithmetic [🔥 Must Know]

**When the problem says "return result modulo 10⁹+7", you need modular arithmetic to prevent overflow.**

💡 **Intuition:** Modular arithmetic is like clock arithmetic. On a 12-hour clock, 10 + 5 = 3 (mod 12). In programming, we use mod 10⁹+7 to keep numbers in the int/long range while preserving the mathematical relationships.

```java
long MOD = 1_000_000_007;

// Rules:
// (a + b) % MOD = ((a % MOD) + (b % MOD)) % MOD
// (a * b) % MOD = ((a % MOD) * (b % MOD)) % MOD
// (a - b) % MOD = ((a % MOD) - (b % MOD) + MOD) % MOD  // add MOD for negative
// Division: multiply by modular inverse instead
```

**Fast exponentiation (binary exponentiation):**

```java
// O(log n) — compute base^exp % mod
// LC 50: Pow(x, n)
long power(long base, long exp, long mod) {
    long result = 1;
    base %= mod;
    while (exp > 0) {
        if ((exp & 1) == 1) result = result * base % mod; // odd exponent: multiply
        base = base * base % mod; // square the base
        exp >>= 1; // halve the exponent
    }
    return result;
}
```

⚙️ **Under the Hood, Fast Exponentiation:**

```
Compute 3^13:
  13 in binary = 1101
  3^13 = 3^8 * 3^4 * 3^1

  exp=13 (1101): odd → result *= 3 = 3.     base = 3² = 9.    exp=6
  exp=6  (0110): even.                        base = 9² = 81.   exp=3
  exp=3  (0011): odd → result *= 81 = 243.   base = 81² = 6561. exp=1
  exp=1  (0001): odd → result *= 6561 = 1594323. Done.

  3^13 = 1594323 ✓. Only 4 multiplications instead of 12.
```

**Modular inverse (for division):**

```java
// a / b mod p = a * b^(-1) mod p
// b^(-1) mod p = b^(p-2) mod p (Fermat's little theorem, p must be prime)
long modInverse(long b, long mod) {
    return power(b, mod - 2, mod);
}

// Example: (a / b) % MOD
long result = a % MOD * modInverse(b, MOD) % MOD;
```

⚠️ **Common Pitfall:** Forgetting to add MOD when subtracting. `(a - b) % MOD` can be negative in Java. Always use `((a - b) % MOD + MOD) % MOD`.

🎯 **Likely Follow-ups:**
- **Q:** Why is MOD = 10⁹+7 specifically?
  **A:** It is prime (required for Fermat's little theorem), fits in a 32-bit int, and `(10⁹+7)² < 2⁶³` so two mod values can be multiplied in a long without overflow.
- **Q:** When can you NOT use Fermat's little theorem for modular inverse?
  **A:** When MOD is not prime. In that case, use the extended Euclidean algorithm instead.

---

### Pattern 4: Reservoir Sampling [🔥 Must Know]

**Select k items uniformly at random from a stream of unknown size, using O(k) space.**

💡 **Intuition:** For k=1, when you see the ith element, replace the current selection with probability 1/i. After seeing all n elements, each element had probability 1/n of being selected. The math works because: P(element i is final selection) = (1/i) * (i/(i+1)) * ((i+1)/(i+2)) * ... * ((n-1)/n) = 1/n. Each "survival" probability telescopes.

```java
// LC 382: Linked List Random Node — O(n) time, O(1) space
Random rand = new Random();
public int getRandom(ListNode head) {
    int result = head.val, i = 1;
    ListNode curr = head.next;
    while (curr != null) {
        i++;
        if (rand.nextInt(i) == 0) result = curr.val; // probability 1/i
        curr = curr.next;
    }
    return result;
}
```

⚙️ **Under the Hood, Proof of Uniformity:**

```
Stream: [A, B, C, D]  (n=4, k=1)

P(A is selected):
  Selected at step 1: 1/1 = 1
  Survives step 2: 1/2 (not replaced)
  Survives step 3: 2/3
  Survives step 4: 3/4
  Total: 1 * 1/2 * 2/3 * 3/4 = 1/4 ✓

P(B is selected):
  Selected at step 2: 1/2
  Survives step 3: 2/3
  Survives step 4: 3/4
  Total: 1/2 * 2/3 * 3/4 = 1/4 ✓

P(C is selected): 1/3 * 3/4 = 1/4 ✓
P(D is selected): 1/4 ✓

Each element has exactly 1/n probability. Uniform!
```

---

### Pattern 5: Fisher-Yates Shuffle [🔥 Must Know]

**Generate a uniformly random permutation in O(n) time and O(1) extra space.**

```java
// LC 384: Shuffle an Array
public int[] shuffle(int[] nums) {
    int[] arr = nums.clone();
    Random rand = new Random();
    for (int i = arr.length - 1; i > 0; i--) {
        int j = rand.nextInt(i + 1); // random index in [0, i] inclusive
        int temp = arr[i]; arr[i] = arr[j]; arr[j] = temp;
    }
    return arr;
}
```

⚠️ **Common Pitfall:** Using `rand.nextInt(arr.length)` instead of `rand.nextInt(i + 1)`. The former does NOT produce a uniform distribution. Each element must be swapped with a random element from the unshuffled portion only.

⚙️ **Under the Hood, Why Fisher-Yates is Uniform:**

```
For array of size n:
  Step 1: pick random from [0, n-1] → n choices
  Step 2: pick random from [0, n-2] → n-1 choices
  ...
  Step n-1: pick random from [0, 1] → 2 choices

Total permutations generated: n * (n-1) * ... * 2 * 1 = n!
Each permutation is equally likely (1/n! probability).
```

---

### Pattern 6: Sieve of Eratosthenes [🔥 Must Know]

**Find all primes up to n in O(n log log n) time.**

```java
// LC 204: Count Primes less than n
public int countPrimes(int n) {
    boolean[] notPrime = new boolean[n];
    int count = 0;
    for (int i = 2; i < n; i++) {
        if (!notPrime[i]) {
            count++;
            // Mark multiples starting from i² (smaller multiples already marked)
            for (long j = (long) i * i; j < n; j += i) {
                notPrime[(int) j] = true;
            }
        }
    }
    return count;
}
```

⚙️ **Under the Hood, Why Start from i²:**

```
When marking multiples of prime p:
  p*2 already marked by 2
  p*3 already marked by 3
  ...
  p*(p-1) already marked by some smaller prime
  p*p is the FIRST multiple not yet marked

Example for p=5:
  5*2=10 (marked by 2), 5*3=15 (marked by 3), 5*4=20 (marked by 2)
  5*5=25 ← first unmarked multiple. Start here.

This optimization reduces work from O(n log n) to O(n log log n).
```

⚠️ **Common Pitfall:** Using `int j = i * i` instead of `long j = (long) i * i`. When i is large (e.g., 46341), i*i overflows int (46341² = 2,147,488,281 > Integer.MAX_VALUE). Cast to long first.

---

### Pattern 7: Random Pick with Weight (Prefix Sum + Binary Search)

```java
// LC 528: Pick index with probability proportional to weight
// Preprocessing: O(n). Each pick: O(log n).
class Solution {
    int[] prefix;
    Random rand = new Random();
    
    public Solution(int[] w) {
        prefix = new int[w.length];
        prefix[0] = w[0];
        for (int i = 1; i < w.length; i++) prefix[i] = prefix[i - 1] + w[i];
    }
    
    public int pickIndex() {
        int target = rand.nextInt(prefix[prefix.length - 1]) + 1; // [1, totalWeight]
        // Binary search for leftmost index where prefix[i] >= target
        int lo = 0, hi = prefix.length - 1;
        while (lo < hi) {
            int mid = lo + (hi - lo) / 2;
            if (prefix[mid] < target) lo = mid + 1;
            else hi = mid;
        }
        return lo;
    }
}
```

💡 **Intuition:** Build a number line where each index occupies a segment proportional to its weight. Pick a random point on the line. Binary search to find which segment it falls in.

---

## 3. Complexity Summary

| Technique | Time | Space | When to Use |
|-----------|------|-------|-------------|
| Boyer-Moore Voting | O(n) | O(1) | Majority element (>n/2 or >n/k) |
| GCD (Euclidean) | O(log min(a,b)) | O(1) | GCD, LCM, fraction simplification |
| Fast Exponentiation | O(log n) | O(1) | Power, modular inverse |
| Sieve of Eratosthenes | O(n log log n) | O(n) | All primes up to n |
| Reservoir Sampling | O(n) | O(k) | Random selection from stream |
| Fisher-Yates | O(n) | O(1) | Uniform random permutation |
| Prefix Sum + Binary Search | O(n) + O(log n) | O(n) | Weighted random selection |

---

## 4. Revision Checklist

- [ ] Boyer-Moore: candidate + count, cancel different elements, O(n) time O(1) space
- [ ] Boyer-Moore n/3: two candidates, two counters, MUST verify in second pass
- [ ] GCD: Euclidean `gcd(a,b) = gcd(b, a%b)`, base case b==0. LCM = a/gcd*b (divide first!)
- [ ] Modular arithmetic: add MOD for subtraction, use long for multiplication
- [ ] Fast power: square base, halve exponent, multiply when odd bit. O(log n)
- [ ] Modular inverse: `a^(p-2) mod p` (Fermat's, p must be prime)
- [ ] MOD = 10⁹+7: prime, fits in int, square fits in long
- [ ] Reservoir sampling: replace with probability 1/i for ith element. Each has 1/n probability.
- [ ] Fisher-Yates: swap with random from [0, i], NOT [0, n). O(n), uniform.
- [ ] Sieve: mark multiples from i² (not 2*i). Cast to long to avoid overflow.
- [ ] Weighted random: prefix sum + binary search for target in [1, totalWeight]

**Top 5 must-solve:**
1. Majority Element (LC 169) [Easy] - Boyer-Moore voting
2. Pow(x, n) (LC 50) [Medium] - Fast exponentiation with negative exponent handling
3. Count Primes (LC 204) [Medium] - Sieve of Eratosthenes
4. Random Pick with Weight (LC 528) [Medium] - Prefix sum + binary search
5. Majority Element II (LC 229) [Medium] - Boyer-Moore with two candidates

> 🔗 **See Also:** [01-dsa/10-bit-manipulation.md](10-bit-manipulation.md) for XOR tricks. [02-system-design/05-estimation-math.md](../02-system-design/05-estimation-math.md) for estimation math. [01-dsa/11-sorting-searching.md](11-sorting-searching.md) for binary search patterns used in weighted random.
