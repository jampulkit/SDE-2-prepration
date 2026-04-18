> ✅ **[CORE] — Must-do for SDE-2 interviews.**

# String Matching Algorithms

## 1. Foundation

**String matching algorithms find occurrences of a pattern within a text efficiently, going beyond the naive O(n*m) approach to O(n+m) using preprocessing.**

💡 **Intuition:** The naive approach compares the pattern at every position in the text. When a mismatch occurs, it starts over from the next position, wasting all the information gained from partial matches. Smart algorithms (KMP, Rabin-Karp) remember what they've already matched to avoid redundant comparisons.

**When these appear in interviews:** Hard string problems (LC 28, 214, 1044), plagiarism detection, DNA sequence matching, and as building blocks for more complex problems.

**Choosing the right algorithm:**

| Scenario | Best Algorithm | Why |
|----------|---------------|-----|
| Single pattern, guaranteed O(n+m) | KMP | No worst-case degradation, deterministic |
| Multiple patterns in same text | Rabin-Karp | Compute hash for each pattern, check all in one pass |
| Longest duplicate substring | Rabin-Karp + Binary Search | Rolling hash enables O(1) window slide |
| Pattern matching + string analysis | Z-Algorithm | Z-array gives extra structural info |
| Short pattern, simple code | Naive | Good enough when m is small (m < 5) |

⚙️ **Under the Hood, Why Naive is O(n*m):**

```
Text:    "AAAAAAAAAB"  (n=10)
Pattern: "AAAAB"       (m=5)

Position 0: AAAAA vs AAAAB → match 4 chars, fail at 5th. Wasted 4 comparisons.
Position 1: AAAAA vs AAAAB → match 4 chars, fail at 5th. Wasted 4 again.
Position 2: AAAAA vs AAAAB → same thing.
...
Position 5: AAAAB vs AAAAB → match! But we did ~25 comparisons to get here.

The problem: after a partial match of length k, naive resets BOTH pointers.
KMP resets only the pattern pointer (using LPS), keeping the text pointer moving forward.
```

> 🔗 **See Also:** [01-dsa/01-arrays-strings-hashing.md](01-arrays-strings-hashing.md) for basic string patterns. [01-dsa/05-trees.md](05-trees.md) Pattern 8 for Trie-based string matching.

---

## 2. Core Patterns

### Pattern 1: Rabin-Karp (Rolling Hash) [🔥 Must Know]

**Use a hash function that can be updated in O(1) when the window slides. If hashes match, verify with actual comparison.**

💡 **Intuition:** Instead of comparing characters one by one, compute a "fingerprint" (hash) of the pattern and each window of the text. Comparing two numbers is O(1). The trick is updating the hash in O(1) when the window slides, instead of recomputing from scratch.

```java
// Rabin-Karp: find pattern in text
public int rabinKarp(String text, String pattern) {
    int n = text.length(), m = pattern.length();
    if (m > n) return -1;
    long BASE = 31, MOD = 1_000_000_007;
    
    // Compute hash of pattern and first window
    long patHash = 0, winHash = 0, power = 1;
    for (int i = 0; i < m; i++) {
        patHash = (patHash * BASE + pattern.charAt(i)) % MOD;
        winHash = (winHash * BASE + text.charAt(i)) % MOD;
        if (i > 0) power = (power * BASE) % MOD;
    }
    
    for (int i = 0; i <= n - m; i++) {
        if (winHash == patHash && text.substring(i, i + m).equals(pattern)) {
            return i; // found match
        }
        // Slide window: remove leftmost char, add next char
        if (i < n - m) {
            winHash = (winHash - text.charAt(i) * power % MOD + MOD) % MOD;
            winHash = (winHash * BASE + text.charAt(i + m)) % MOD;
        }
    }
    return -1;
}
```

⚙️ **Under the Hood, Rolling Hash Math:**

```
Hash of "ABC" with BASE=31:
  hash = A*31² + B*31¹ + C*31⁰

Slide window from "ABC" to "BCD":
  Remove A: hash = hash - A*31²
  Shift left: hash = hash * 31
  Add D: hash = hash + D
  Result: B*31² + C*31¹ + D*31⁰

This is O(1) per slide. Total: O(n) for all windows.

Why MOD? Without it, hash values overflow. MOD keeps values in range.
Why verify on match? Hash collisions exist. Two different strings can have the same hash.
  Probability of collision with one MOD: ~1/10⁹. With double hashing: ~1/10¹⁸.
```

**Double hashing to reduce collisions:**

```java
// Use two different (BASE, MOD) pairs
// Only verify when BOTH hashes match
long BASE1 = 31, MOD1 = 1_000_000_007;
long BASE2 = 37, MOD2 = 1_000_000_009;
// Collision probability drops from 1/10⁹ to 1/10¹⁸
```

| Aspect | Single Hash | Double Hash |
|--------|------------|-------------|
| Collision probability | ~1/10⁹ | ~1/10¹⁸ |
| Speed | Faster | ~2x slower |
| When to use | Most problems | When n is large (>10⁶) or correctness is critical |

**Complexity:**

| Operation | Time | Space |
|-----------|------|-------|
| Preprocessing (hash pattern) | O(m) | O(1) |
| Search (average) | O(n) | O(1) |
| Search (worst, many collisions) | O(n*m) | O(1) |
| Total (average) | O(n+m) | O(1) |

🎯 **Likely Follow-ups:**
- **Q:** When does Rabin-Karp degrade to O(n*m)?
  **A:** When every window produces a hash collision with the pattern. This happens with pathological inputs like text="AAAA...A" and pattern="AAAA...B". Every window's hash matches, forcing a full character comparison each time. Double hashing makes this practically impossible.
- **Q:** How would you search for multiple patterns simultaneously?
  **A:** Compute the hash of each pattern. Store them in a HashSet. For each window, check if the window hash exists in the set. This is O(n*k) average where k is the number of patterns, compared to O(n*m*k) for naive.
- **Q:** Why not just use KMP instead of Rabin-Karp?
  **A:** Rabin-Karp is better for: (1) multiple pattern search, (2) 2D pattern matching, (3) longest duplicate substring (binary search on length + rolling hash). KMP is better when you need guaranteed O(n+m) for a single pattern.

---

### Pattern 2: KMP (Knuth-Morris-Pratt) [🔥 Must Know]

**Precompute a "failure function" (longest proper prefix that is also a suffix) so that on mismatch, you skip ahead instead of starting over.**

💡 **Intuition:** When you're matching "ABCABD" against text and you match "ABCAB" but fail at 'D', you don't need to start over. You already know the last two characters matched are "AB", which is also a prefix of the pattern. So jump to position 2 in the pattern (after "AB") and continue from there. The LPS array tells you exactly where to jump.

```java
// KMP: O(n+m) guaranteed
public int kmp(String text, String pattern) {
    int[] lps = buildLPS(pattern); // Longest Proper Prefix which is also Suffix
    int i = 0, j = 0; // i = text pointer, j = pattern pointer
    
    while (i < text.length()) {
        if (text.charAt(i) == pattern.charAt(j)) {
            i++; j++;
            if (j == pattern.length()) return i - j; // found match
        } else if (j > 0) {
            j = lps[j - 1]; // skip ahead using failure function (don't reset i!)
        } else {
            i++;
        }
    }
    return -1;
}

private int[] buildLPS(String pattern) {
    int[] lps = new int[pattern.length()];
    int len = 0, i = 1;
    while (i < pattern.length()) {
        if (pattern.charAt(i) == pattern.charAt(len)) {
            lps[i++] = ++len;
        } else if (len > 0) {
            len = lps[len - 1]; // fall back
        } else {
            lps[i++] = 0;
        }
    }
    return lps;
}
```

⚙️ **Under the Hood, LPS Array Construction Step by Step:**

```
Pattern: "ABCABD"
Index:    0 1 2 3 4 5

i=1, len=0: 'B' vs 'A' → mismatch, len=0 → lps[1]=0, i=2
i=2, len=0: 'C' vs 'A' → mismatch, len=0 → lps[2]=0, i=3
i=3, len=0: 'A' vs 'A' → match! len=1, lps[3]=1, i=4
i=4, len=1: 'B' vs 'B' → match! len=2, lps[4]=2, i=5
i=5, len=2: 'D' vs 'C' → mismatch, len>0 → len=lps[1]=0
i=5, len=0: 'D' vs 'A' → mismatch, len=0 → lps[5]=0, i=6

LPS = [0, 0, 0, 1, 2, 0]

Meaning: at position 4, the longest prefix that's also a suffix is "AB" (length 2).
So if we fail at position 5, we jump back to position 2 (not 0!).
```

⚙️ **Under the Hood, KMP Search Walkthrough:**

```
Text:    "ABCABCABD"
Pattern: "ABCABD"
LPS:     [0,0,0,1,2,0]

i=0,j=0: A=A ✓ → i=1,j=1
i=1,j=1: B=B ✓ → i=2,j=2
i=2,j=2: C=C ✓ → i=3,j=3
i=3,j=3: A=A ✓ → i=4,j=4
i=4,j=4: B=B ✓ → i=5,j=5
i=5,j=5: C≠D ✗ → j=lps[4]=2 (skip! we know "AB" already matches)
i=5,j=2: C=C ✓ → i=6,j=3
i=6,j=3: A=A ✓ → i=7,j=4
i=7,j=4: B=B ✓ → i=8,j=5
i=8,j=5: D=D ✓ → j=6 = pattern.length → FOUND at index 8-6=2

Key: text pointer i NEVER moves backward. Only j resets (using LPS).
This guarantees O(n+m).
```

**KMP for finding ALL occurrences:**

```java
public List<Integer> kmpAll(String text, String pattern) {
    int[] lps = buildLPS(pattern);
    List<Integer> result = new ArrayList<>();
    int i = 0, j = 0;
    while (i < text.length()) {
        if (text.charAt(i) == pattern.charAt(j)) {
            i++; j++;
            if (j == pattern.length()) {
                result.add(i - j); // found one occurrence
                j = lps[j - 1];   // continue searching (don't reset to 0!)
            }
        } else if (j > 0) {
            j = lps[j - 1];
        } else {
            i++;
        }
    }
    return result;
}
```

**Complexity:**

| Operation | Time | Space |
|-----------|------|-------|
| Build LPS array | O(m) | O(m) |
| Search | O(n) | O(1) |
| Total | O(n+m) | O(m) |

🎯 **Likely Follow-ups:**
- **Q:** How do you use KMP to check if a string is a rotation of another?
  **A:** String B is a rotation of A if and only if B exists in A+A. Example: "CDAB" is a rotation of "ABCD" because "CDAB" appears in "ABCDABCD". Use KMP to search for B in A+A. Time: O(n).
- **Q:** How does the LPS array help find the shortest repeating unit of a string?
  **A:** If `n % (n - lps[n-1]) == 0`, the string is made of repeating units of length `n - lps[n-1]`. Example: "ABCABC" has lps[5]=3, so repeating unit length = 6-3 = 3 ("ABC"). This solves LC 459 (Repeated Substring Pattern).
- **Q:** What is the space complexity of KMP vs Rabin-Karp?
  **A:** KMP uses O(m) for the LPS array. Rabin-Karp uses O(1) extra space (just hash values). For very long patterns, Rabin-Karp is more space-efficient.

---

### Pattern 3: Z-Algorithm [🔥 Must Know]

**Compute Z-array where Z[i] = length of the longest substring starting at i that matches a prefix of the string.**

💡 **Intuition:** The Z-array answers the question: "for each position i, how many characters starting at i match the beginning of the string?" This is useful for pattern matching (concatenate pattern + "$" + text, then find positions where Z[i] equals the pattern length) and for string analysis problems.

```java
public int[] zFunction(String s) {
    int n = s.length();
    int[] z = new int[n];
    int l = 0, r = 0; // [l, r) is the rightmost Z-box
    for (int i = 1; i < n; i++) {
        if (i < r) z[i] = Math.min(r - i, z[i - l]); // reuse previous computation
        while (i + z[i] < n && s.charAt(z[i]) == s.charAt(i + z[i])) z[i]++;
        if (i + z[i] > r) { l = i; r = i + z[i]; } // extend Z-box
    }
    return z;
}

// String matching using Z-algorithm
public int zMatch(String text, String pattern) {
    String combined = pattern + "$" + text; // $ is a character not in either string
    int[] z = zFunction(combined);
    int m = pattern.length();
    for (int i = m + 1; i < combined.length(); i++) {
        if (z[i] == m) return i - m - 1; // found pattern at this position in text
    }
    return -1;
}
```

⚙️ **Under the Hood, Z-Array Example:**

```
String: "AABXAAB"
Index:   0123456

Z[0] = undefined (by convention, 0 or not computed)
Z[1]: compare s[1..] "ABXAAB" with s[0..] "AABXAAB" → 'A'='A', 'B'≠'A' → Z[1]=1
Z[2]: 'B' vs 'A' → Z[2]=0
Z[3]: 'X' vs 'A' → Z[3]=0
Z[4]: 'A'='A', 'A'='A', 'B'='B' → Z[4]=3 (but stop: "AABXAAB" prefix matches 3 chars)
Z[5]: reuse Z[1] since 5 is inside Z-box [4,7) → Z[5]=1
Z[6]: 'B' vs 'A' → Z[6]=0

Z = [-, 1, 0, 0, 3, 1, 0]

For pattern matching "AAB" in "XAABXAAB":
  Combined: "AAB$XAABXAAB"
  Z-array:  [-, 0, 0, 0, 0, 3, 0, 0, 0, 3, 0, 0]
  Z[i]==3 at positions 5 and 9 → pattern found at text positions 1 and 5
```

**Complexity:**

| Operation | Time | Space |
|-----------|------|-------|
| Build Z-array | O(n) | O(n) |
| Pattern matching | O(n+m) | O(n+m) |

**Z-Algorithm vs KMP:**

| Aspect | KMP | Z-Algorithm |
|--------|-----|-------------|
| Preprocessing | LPS array (O(m) space) | Z-array (O(n+m) space) |
| Conceptual difficulty | Harder (LPS fallback logic) | Easier (direct prefix comparison) |
| Applications beyond matching | Repeated substring, string periodicity | Prefix matching, string compression |
| Interview preference | More commonly asked | Good alternative, sometimes cleaner |

🎯 **Likely Follow-ups:**
- **Q:** When would you prefer Z-algorithm over KMP?
  **A:** When you need to know the match length at every position (not just "does it match?"). The Z-array gives richer information. Also, some people find Z-algorithm easier to implement correctly under interview pressure.
- **Q:** Can Z-algorithm solve the "shortest palindrome" problem?
  **A:** Yes. For string s, compute Z-array of reverse(s) + "$" + s. Find the longest suffix of s that is a palindrome prefix. This gives the same result as the KMP approach for LC 214.

---

## 3. Application Patterns

### Longest Duplicate Substring (Binary Search + Rabin-Karp) [🔥 Must Do]

```java
// LC 1044: O(n log n) average
public String longestDupSubstring(String s) {
    int lo = 1, hi = s.length() - 1;
    String result = "";
    while (lo <= hi) {
        int mid = lo + (hi - lo) / 2;
        String dup = findDuplicate(s, mid); // check if duplicate of length mid exists
        if (dup != null) {
            result = dup;
            lo = mid + 1; // try longer
        } else {
            hi = mid - 1; // try shorter
        }
    }
    return result;
}

private String findDuplicate(String s, int len) {
    long BASE = 31, MOD = 1_000_000_007;
    long hash = 0, power = 1;
    for (int i = 0; i < len; i++) {
        hash = (hash * BASE + s.charAt(i)) % MOD;
        if (i > 0) power = power * BASE % MOD;
    }
    Map<Long, List<Integer>> seen = new HashMap<>();
    seen.computeIfAbsent(hash, k -> new ArrayList<>()).add(0);
    for (int i = 1; i + len <= s.length(); i++) {
        hash = (hash - s.charAt(i - 1) * power % MOD + MOD) % MOD;
        hash = (hash * BASE + s.charAt(i + len - 1)) % MOD;
        List<Integer> indices = seen.get(hash);
        if (indices != null) {
            String candidate = s.substring(i, i + len);
            for (int idx : indices) {
                if (s.substring(idx, idx + len).equals(candidate)) return candidate;
            }
        }
        seen.computeIfAbsent(hash, k -> new ArrayList<>()).add(i);
    }
    return null;
}
```

**Complexity:** O(n log n) average (binary search on length * O(n) hash computation per length).

### Shortest Palindrome (KMP Application) [🔥 Must Do]

```java
// LC 214: Find shortest palindrome by adding characters to the front
// Key insight: find the longest palindromic PREFIX of s
// Concatenate s + "#" + reverse(s), build LPS. Last LPS value = longest palindromic prefix.
public String shortestPalindrome(String s) {
    String rev = new StringBuilder(s).reverse().toString();
    String combined = s + "#" + rev; // "#" prevents overlap
    int[] lps = buildLPS(combined);
    int palLen = lps[combined.length() - 1]; // longest palindromic prefix length
    return rev.substring(0, s.length() - palLen) + s;
}
```

**Why this works:** The LPS of the combined string tells us the longest prefix of s that equals a suffix of reverse(s). That prefix is a palindrome. We prepend the remaining characters (reversed) to make the whole string a palindrome.

---

## 4. Patterns Summary Table

| Algorithm | Preprocessing | Search | Total | Worst Case | Space | Best For |
|-----------|-------------|--------|-------|-----------|-------|----------|
| Naive | O(1) | O(n*m) | O(n*m) | O(n*m) | O(1) | Short patterns, simple code |
| Rabin-Karp | O(m) | O(n) avg | O(n+m) avg | O(n*m) | O(1) | Multiple patterns, rolling hash |
| KMP | O(m) | O(n) | O(n+m) | O(n+m) | O(m) | Single pattern, guaranteed linear |
| Z-Algorithm | O(n+m) | O(n+m) | O(n+m) | O(n+m) | O(n+m) | Pattern matching, string analysis |

---

## 5. Revision Checklist

- [ ] Rabin-Karp: rolling hash, O(n+m) average, slide window by removing left char and adding right
- [ ] KMP: LPS array (longest prefix = suffix), O(n+m) guaranteed, skip ahead on mismatch
- [ ] Z-Algorithm: Z[i] = longest match with prefix starting at i, O(n+m)
- [ ] Rabin-Karp for multiple patterns, KMP for single pattern guaranteed
- [ ] Rolling hash formula: `hash = (hash - leftChar * power) * BASE + rightChar`, all mod MOD
- [ ] Use double hashing (two BASE/MOD pairs) to reduce collision probability to ~1/10¹⁸
- [ ] KMP rotation check: B is rotation of A if B found in A+A
- [ ] KMP repeating unit: if `n % (n - lps[n-1]) == 0`, repeating unit length = `n - lps[n-1]`
- [ ] Longest duplicate substring: binary search on length + Rabin-Karp = O(n log n)
- [ ] Shortest palindrome: s + "#" + reverse(s), LPS of combined gives longest palindromic prefix

**Top 5 must-solve:**
1. Find the Index of First Occurrence (LC 28) [Easy] - KMP / Z basic application
2. Repeated Substring Pattern (LC 459) [Easy] - LPS array property
3. Shortest Palindrome (LC 214) [Hard] - KMP on s + "#" + reverse(s)
4. Longest Duplicate Substring (LC 1044) [Hard] - Binary search + Rabin-Karp rolling hash
5. Longest Happy Prefix (LC 1392) [Hard] - Direct LPS array application

> 🔗 **See Also:** [01-dsa/01-arrays-strings-hashing.md](01-arrays-strings-hashing.md) for basic string patterns. [01-dsa/05-trees.md](05-trees.md) Pattern 8 for Trie-based string matching.
