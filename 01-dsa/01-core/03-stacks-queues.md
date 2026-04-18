> ✅ **[CORE] — Must-do for SDE-2 interviews.**

# Stacks & Queues

## 1. Foundation

### Stack

**A stack is a "last-in, first-out" container — like a stack of plates, you can only add or remove from the top. This makes it perfect for tracking nested structures, undoing operations, and any problem where the most recent item matters most.**

A stack models "last-in, first-out" (LIFO) behavior — the most recently added element is the first to be removed. This naturally maps to problems involving nesting (parentheses), backtracking (undo), and maintaining a history of decisions.

💡 **Intuition:** Think of the browser back button. Every page you visit gets "pushed" onto a history stack. When you click back, the most recent page gets "popped" off. You can't go back to the first page without going through all the pages in between — that's LIFO.

**Real-world analogies:** Browser back button, undo/redo in editors, function call stack (recursion), expression evaluation, syntax parsing.

**Internal workings in Java:**

| Class | Backing Structure | Thread-safe | Recommended |
|-------|------------------|-------------|-------------|
| `Stack<E>` | `Vector` (dynamic array) | Yes (synchronized) | ❌ Legacy — don't use |
| `ArrayDeque<E>` | Circular array | No | ✅ Use this |
| `LinkedList<E>` | Doubly-linked list | No | ✅ OK, but ArrayDeque is faster |

**Always use `ArrayDeque` as a stack** [🔥 Must Know]:
```java
Deque<Integer> stack = new ArrayDeque<>();
stack.push(1);      // addFirst — adds to top
stack.pop();        // removeFirst — removes from top
stack.peek();       // peekFirst — views top without removing
stack.isEmpty();    // check if empty BEFORE pop/peek
stack.size();
```

**Why not `Stack<E>`:** It extends `Vector`, which synchronizes every operation — unnecessary overhead in single-threaded code. It also allows random access (`get(i)`), which violates stack semantics and can lead to bugs.

⚙️ **Under the Hood — ArrayDeque as a Circular Buffer:**
ArrayDeque uses a circular array with `head` and `tail` pointers. When used as a stack, `push` decrements `head` (wrapping around) and `pop` increments `head`. This avoids shifting elements — every operation is O(1).

```
ArrayDeque internal state after push(1), push(2), push(3):

Array:  [_, _, _, _, _, _, _, _, _, _, _, _, _, 3, 2, 1]
                                                ↑        ↑
                                               head     tail
         (capacity = 16, head wraps around from 0 to 15)

push(4): head moves to 12
Array:  [_, _, _, _, _, _, _, _, _, _, _, _, 4, 3, 2, 1]
                                             ↑
                                            head

pop(): returns 4, head moves to 13
```

The circular design means both stack (LIFO) and queue (FIFO) operations are O(1) without any element shifting.

**Operations complexity:**

| Operation | ArrayDeque | LinkedList | Stack (legacy) |
|-----------|-----------|------------|----------------|
| push (top) | O(1) amortized | O(1) | O(1) amortized |
| pop (top) | O(1) | O(1) | O(1) |
| peek (top) | O(1) | O(1) | O(1) |
| search | O(n) | O(n) | O(n) |
| Memory | Compact (array, cache-friendly) | Higher (node objects + pointers) | Same as array |

| Approach | Pros | Cons | Best When |
|----------|------|------|-----------|
| `ArrayDeque` | Cache-friendly, no node overhead, fastest | No null elements, no random access | Default choice (almost always) |
| `LinkedList` | Allows null, implements List interface | Node overhead, poor cache locality | Need List operations too |
| `Stack` (legacy) | Familiar API | Synchronized overhead, allows random access | Never — use ArrayDeque |

🎯 **Likely Follow-ups:**
- **Q:** Why is ArrayDeque faster than LinkedList for stack operations?
  **A:** ArrayDeque stores elements in a contiguous array — CPU cache prefetching loads nearby elements automatically. LinkedList nodes are scattered across the heap, causing cache misses on every access. For stack operations, this difference can be 2-3x in practice.
- **Q:** What happens when ArrayDeque's internal array is full?
  **A:** It doubles in size (allocates a new array of 2× capacity and copies elements). This is amortized O(1) — same analysis as ArrayList growth.

### Queue

**A queue is a "first-in, first-out" container — like a line at a coffee shop, the first person in line gets served first.**

A queue models "first-in, first-out" (FIFO) behavior. Used for BFS, task scheduling, buffering, and any scenario where processing order matters.

💡 **Intuition:** Think of a print queue. Documents are printed in the order they were submitted. The first document submitted is the first one printed. New documents join at the back of the line.

**Java Queue implementations:**

| Class | Type | Backing | Use Case |
|-------|------|---------|----------|
| `ArrayDeque<E>` | FIFO queue | Circular array | General-purpose queue ✅ |
| `LinkedList<E>` | FIFO queue | Doubly-linked list | When you also need list operations |
| `PriorityQueue<E>` | Priority queue | Binary heap | Min/max element access |
| `LinkedBlockingQueue` | Blocking queue | Linked nodes | Producer-consumer (concurrency) |
| `ConcurrentLinkedQueue` | Lock-free queue | Linked nodes (CAS) | High-throughput concurrent access |

**Always use `ArrayDeque` as a queue** [🔥 Must Know]:
```java
Deque<Integer> queue = new ArrayDeque<>();
queue.offer(1);     // addLast — enqueue at back
queue.poll();       // removeFirst — dequeue from front
queue.peek();       // peekFirst — view front without removing
queue.isEmpty();
```

⚠️ **Common Pitfall — offer/poll vs add/remove:**

```java
Deque<Integer> deque = new ArrayDeque<>();

// Safe methods (return null/false on failure):
deque.offer(1);    // returns true
deque.poll();      // returns null if empty
deque.peek();      // returns null if empty

// Unsafe methods (throw exception on failure):
deque.add(1);      // throws IllegalStateException if capacity-restricted and full
deque.remove();    // throws NoSuchElementException if empty
deque.element();   // throws NoSuchElementException if empty

// RULE: Always use offer/poll/peek in interview code — safer and cleaner
```

> 🔗 **See Also:** [05-java/02-collections-internals.md](../05-java/02-collections-internals.md) for deeper Queue/Deque implementation details. [06-tech-stack/01-kafka-deep-dive.md](../06-tech-stack/01-kafka-deep-dive.md) for message queues in distributed systems.

### Deque (Double-Ended Queue)

**A deque supports insertion and removal at both ends in O(1) — it can act as both a stack and a queue, and is essential for monotonic deque problems.**

```java
Deque<Integer> deque = new ArrayDeque<>();
deque.offerFirst(1);  // add to front (stack push)
deque.offerLast(2);   // add to back (queue enqueue)
deque.pollFirst();    // remove from front (queue dequeue / stack pop)
deque.pollLast();     // remove from back
deque.peekFirst();    // view front
deque.peekLast();     // view back
```

```
Deque operations visualization:

        pollFirst()  ←  [front | ... | ... | back]  ←  offerLast()
        offerFirst() →  [front | ... | ... | back]  →  pollLast()

As Stack: offerFirst + pollFirst (or push + pop)
As Queue: offerLast + pollFirst (or offer + poll)
```


---

## 2. Core Patterns

### Pattern 1: Matching Parentheses / Brackets [🔥 Must Know]

**Push opening brackets onto a stack; when you see a closing bracket, pop and check if it matches — if the stack is empty at the end, the expression is balanced.**

**When to recognize it:** Problem involves balanced brackets, nested structures, or matching pairs (open/close).

💡 **Intuition:** Imagine you're reading a book with nested footnotes. Each opening footnote marker `[` means "remember where I was." Each closing `]` means "go back to where I was." A stack naturally tracks these "remember" points in the correct order — the most recent opening bracket must be closed first.

**Approach:**
1. Push opening brackets onto stack
2. On closing bracket, check if top of stack matches
3. At end, stack must be empty (no unmatched opening brackets)

```java
// LC 20: Valid Parentheses [🔥 Must Do]
public boolean isValid(String s) {
    Deque<Character> stack = new ArrayDeque<>();
    Map<Character, Character> pairs = Map.of(')', '(', ']', '[', '}', '{');

    for (char c : s.toCharArray()) {
        if (pairs.containsValue(c)) {  // opening bracket
            stack.push(c);
        } else {                        // closing bracket
            if (stack.isEmpty() || stack.pop() != pairs.get(c)) return false;
        }
    }
    return stack.isEmpty(); // no unmatched opening brackets
}
```

**Dry run:** `s = "({[]})"`

```
c='(': push → stack: ['(']
c='{': push → stack: ['(', '{']
c='[': push → stack: ['(', '{', '[']
c=']': pop '[', matches ']' ✓ → stack: ['(', '{']
c='}': pop '{', matches '}' ✓ → stack: ['(']
c=')': pop '(', matches ')' ✓ → stack: []
Stack empty → return true ✓
```

**Dry run (invalid):** `s = "([)]"`

```
c='(': push → stack: ['(']
c='[': push → stack: ['(', '[']
c=')': pop '[', but '[' ≠ '(' for ')' → return false ✗
```

**Variations:**

| Problem | Twist | Key Idea |
|---------|-------|----------|
| Min removals to make valid (LC 1249) | Track indices of unmatched brackets | Stack stores indices, not characters |
| Longest valid parentheses (LC 32) | Find longest valid substring | Stack stores indices; push -1 as base |
| Score of parentheses (LC 856) | `()` = 1, `(A)` = 2*A, `AB` = A+B | Stack tracks depth/score |
| Remove outermost parentheses (LC 1021) | Strip outermost layer | Depth counter instead of stack |

**Edge Cases:**
- ☐ Empty string → return true (vacuously balanced)
- ☐ Single character → always false (no matching pair)
- ☐ Only opening brackets `"((("` → stack not empty → false
- ☐ Only closing brackets `")))"` → stack empty on first pop → false
- ☐ Correct brackets but wrong order `"([)]"` → mismatch on pop → false

🎯 **Likely Follow-ups:**
- **Q:** How would you find the minimum number of brackets to remove to make the string valid?
  **A:** Use a stack to track unmatched brackets. Push indices of `(` onto the stack. On `)`, if stack is empty or top isn't `(`, push the `)` index. At the end, stack size = number of removals needed. (LC 1249)
- **Q:** What about handling multiple bracket types with priorities (like in math expressions)?
  **A:** Same stack approach, but you also need to check that brackets are properly nested — `({)}` is invalid even though counts match. The stack naturally enforces proper nesting.
- **Q:** How would you handle this for a very long string that doesn't fit in memory?
  **A:** Stream the characters. You only need the stack (max depth = nesting depth, usually much smaller than string length). For simple `()` only, you can use a counter instead of a stack — O(1) space.

---

### Pattern 2: Monotonic Stack [🔥 Must Know]

**Maintain a stack where elements are in sorted order (increasing or decreasing). When a new element breaks the order, pop elements — each popped element has found its "answer" (the element that caused the pop).**

**When to recognize it:** "Next greater element", "next smaller element", "previous greater/smaller", or any problem where you need to find the nearest element satisfying a comparison in one direction.

💡 **Intuition:** Imagine you're standing in a line of people of different heights, all facing right. Each person wants to know: "Who is the first person taller than me to my right?" The tallest person so far blocks the view of everyone shorter behind them. A monotonic stack is like this line — when a tall person arrives, all shorter people in front of them get their answer (the tall person), and they leave the line.

**Core idea:** Maintain a stack where elements are in monotonic order (increasing or decreasing). When a new element violates the order, pop elements — each popped element has found its "answer" (the new element).

**Four variants:**

| Find | Stack Order | Pop When | What Popped Element Learns |
|------|------------|----------|---------------------------|
| Next Greater (right) | Decreasing (top is smallest) | `nums[i] > stack.peek()` | "nums[i] is my next greater" |
| Next Smaller (right) | Increasing (top is largest) | `nums[i] < stack.peek()` | "nums[i] is my next smaller" |
| Previous Greater (left) | Decreasing | `nums[i] >= stack.peek()` | "stack.peek() after pop is my prev greater" |
| Previous Smaller (left) | Increasing | `nums[i] <= stack.peek()` | "stack.peek() after pop is my prev smaller" |

⚙️ **Under the Hood — Why Monotonic Stack is O(n):**
Despite the inner `while` loop, each element is pushed onto the stack exactly once and popped at most once. Total push operations: n. Total pop operations: at most n. Total work: O(2n) = O(n). This is the same amortized argument as sliding window.

**Java code template — Next Greater Element:**

```java
// For each element, find the next element to its right that is greater
public int[] nextGreaterElement(int[] nums) {
    int n = nums.length;
    int[] result = new int[n];
    Arrays.fill(result, -1);                    // default: no greater element found
    Deque<Integer> stack = new ArrayDeque<>();   // stores INDICES (not values)

    for (int i = 0; i < n; i++) {
        // Pop all elements smaller than current — they found their next greater
        while (!stack.isEmpty() && nums[i] > nums[stack.peek()]) {
            result[stack.pop()] = nums[i];
        }
        stack.push(i);
    }
    // Elements remaining in stack have no next greater element (result stays -1)
    return result;
}
```

**Why store indices, not values:** You often need the index to compute distances (e.g., "how many days until warmer temperature") or to write results to the correct position.

**Example walkthrough — LC 739: Daily Temperatures** [🔥 Must Do]

> Given `temperatures = [73,74,75,71,69,72,76,73]`, return how many days you have to wait for a warmer temperature.

```java
public int[] dailyTemperatures(int[] temperatures) {
    int n = temperatures.length;
    int[] result = new int[n];
    Deque<Integer> stack = new ArrayDeque<>(); // decreasing stack of indices

    for (int i = 0; i < n; i++) {
        while (!stack.isEmpty() && temperatures[i] > temperatures[stack.peek()]) {
            int prevDay = stack.pop();
            result[prevDay] = i - prevDay; // distance = current day - previous day
        }
        stack.push(i);
    }
    return result;
    // Elements left in stack → no warmer day → result stays 0
}
```

**Dry run:** `[73, 74, 75, 71, 69, 72, 76, 73]`

```
i=0 (73): stack=[] → push 0 → stack=[0]
i=1 (74): 74>73 → pop 0, result[0]=1-0=1 → push 1 → stack=[1]
i=2 (75): 75>74 → pop 1, result[1]=2-1=1 → push 2 → stack=[2]
i=3 (71): 71<75 → push 3 → stack=[2,3]
i=4 (69): 69<71 → push 4 → stack=[2,3,4]
i=5 (72): 72>69 → pop 4, result[4]=5-4=1
          72>71 → pop 3, result[3]=5-3=2
          72<75 → stop → push 5 → stack=[2,5]
i=6 (76): 76>72 → pop 5, result[5]=6-5=1
          76>75 → pop 2, result[2]=6-2=4
          stack empty → push 6 → stack=[6]
i=7 (73): 73<76 → push 7 → stack=[6,7]

Remaining in stack: indices 6,7 → result stays 0 (no warmer day)
Result: [1, 1, 4, 2, 1, 1, 0, 0] ✓
```

**Complexity:** O(n) time (each element pushed and popped at most once), O(n) space.

**Circular array variant (LC 503: Next Greater Element II):**
For circular arrays, iterate through the array twice (indices 0 to 2n-1), using `i % n` to wrap around:

```java
public int[] nextGreaterElements(int[] nums) {
    int n = nums.length;
    int[] result = new int[n];
    Arrays.fill(result, -1);
    Deque<Integer> stack = new ArrayDeque<>();

    for (int i = 0; i < 2 * n; i++) {  // iterate twice for circular
        while (!stack.isEmpty() && nums[i % n] > nums[stack.peek()]) {
            result[stack.pop()] = nums[i % n];
        }
        if (i < n) stack.push(i); // only push in first pass
    }
    return result;
}
```

🎯 **Likely Follow-ups:**
- **Q:** How would you find the previous greater element instead of next greater?
  **A:** Same decreasing stack, but instead of recording what the popped element found, record what the current element sees as the stack top AFTER popping smaller elements. The remaining top is the previous greater element.
- **Q:** What if you need both next greater AND previous greater for each element?
  **A:** Run the monotonic stack twice — once left-to-right (next greater) and once right-to-left (previous greater). Or use a single pass where the stack top after popping gives the previous greater, and the current element gives the next greater for popped elements.
- **Q:** How does this relate to the "Sum of Subarray Minimums" problem?
  **A:** For each element, find how many subarrays it's the minimum of. Use monotonic stack to find the previous smaller and next smaller element. The element at index `i` is the minimum of `(i - prevSmaller) × (nextSmaller - i)` subarrays. This is the "contribution technique."

> 🔗 **See Also:** [01-dsa/02-two-pointers-sliding-window.md](02-two-pointers-sliding-window.md) Pattern 6 for monotonic deque (sliding window max/min — extends monotonic stack with front removal).

---

### Pattern 3: Stack for Expression Evaluation

**Use a stack to evaluate mathematical expressions — push operands, and when you encounter an operator, pop operands, compute, and push the result back.**

**When to recognize it:** Evaluate arithmetic expressions, reverse Polish notation, or implement a calculator.

💡 **Intuition:** When you evaluate `3 + 4 × 2`, you can't just go left to right because `×` has higher precedence. A stack lets you "defer" the `+` operation until you've resolved the `×`. In postfix notation (RPN), the order is already resolved — you just push numbers and compute when you see an operator.

**Sub-pattern 3a: Reverse Polish Notation (Postfix)**

```java
// LC 150: Evaluate Reverse Polish Notation [🔥 Must Do]
public int evalRPN(String[] tokens) {
    Deque<Integer> stack = new ArrayDeque<>();
    Set<String> ops = Set.of("+", "-", "*", "/");

    for (String token : tokens) {
        if (ops.contains(token)) {
            int b = stack.pop(), a = stack.pop(); // b is second operand, a is first
            switch (token) {
                case "+" -> stack.push(a + b);
                case "-" -> stack.push(a - b);
                case "*" -> stack.push(a * b);
                case "/" -> stack.push(a / b); // truncates toward zero in Java
            }
        } else {
            stack.push(Integer.parseInt(token));
        }
    }
    return stack.pop();
}
```

**Dry run:** `tokens = ["2", "1", "+", "3", "*"]` → equivalent to `(2 + 1) * 3 = 9`

```
"2": push 2 → stack: [2]
"1": push 1 → stack: [2, 1]
"+": pop 1, pop 2, push 2+1=3 → stack: [3]
"3": push 3 → stack: [3, 3]
"*": pop 3, pop 3, push 3*3=9 → stack: [9]
Return 9 ✓
```

⚠️ **Common Pitfall — Operand Order:**
`a - b` and `a / b` are not commutative. The first popped value is `b` (second operand), the second popped is `a` (first operand). Getting this backwards gives wrong results for subtraction and division.

**Sub-pattern 3b: Basic Calculator (with parentheses)**

```java
// LC 224: Basic Calculator — handles +, -, (, )
public int calculate(String s) {
    Deque<Integer> stack = new ArrayDeque<>();
    int result = 0, num = 0, sign = 1;

    for (char c : s.toCharArray()) {
        if (Character.isDigit(c)) {
            num = num * 10 + (c - '0');          // build multi-digit number
        } else if (c == '+' || c == '-') {
            result += sign * num;                 // apply previous number
            num = 0;
            sign = (c == '+') ? 1 : -1;          // update sign for next number
        } else if (c == '(') {
            stack.push(result);                   // save current result
            stack.push(sign);                     // save current sign
            result = 0;                           // reset for sub-expression
            sign = 1;
        } else if (c == ')') {
            result += sign * num;                 // apply last number in sub-expression
            num = 0;
            result *= stack.pop();                // apply sign before '('
            result += stack.pop();                // add result before '('
        }
        // spaces are ignored (no else needed)
    }
    return result + sign * num; // don't forget the last number
}
```

**Dry run:** `s = "1 + (2 - 3)"`

```
'1': num=1
'+': result=0+1*1=1, num=0, sign=1
'(': push result=1, push sign=1. result=0, sign=1
'2': num=2
'-': result=0+1*2=2, num=0, sign=-1
'3': num=3
')': result=2+(-1)*3=-1. Pop sign=1, result=-1*1=-1. Pop prev=1, result=1+(-1)=0
End: result + sign*num = 0 + 1*0 = 0

Wait, that's wrong. Let me re-trace:
'1': num=1
' ': skip
'+': result += 1*1 = 1, num=0, sign=1
' ': skip
'(': push(1), push(1), result=0, sign=1
'2': num=2
' ': skip
'-': result += 1*2 = 2, num=0, sign=-1
' ': skip
'3': num=3
')': result += (-1)*3 = 2-3 = -1, num=0
     sign_before_paren = pop() = 1
     result_before_paren = pop() = 1
     result = result_before_paren + sign_before_paren * result = 1 + 1*(-1) = 0
End: 0 + 1*0 = 0 ✓  (1 + (2-3) = 1 + (-1) = 0)
```

**Edge Cases:**
- ☐ Multi-digit numbers `"123"` → build with `num = num * 10 + digit`
- ☐ Leading spaces → skip non-digit, non-operator characters
- ☐ Negative numbers `"(-1)"` → handled by sign tracking
- ☐ Nested parentheses `"((1+2))"` → stack handles arbitrary nesting depth
- ☐ No parentheses `"1+2-3"` → works without ever pushing to stack

🎯 **Likely Follow-ups:**
- **Q:** How would you handle multiplication and division (operator precedence)?
  **A:** For Basic Calculator II (LC 227), process `*` and `/` immediately (they have higher precedence), but defer `+` and `-` by pushing them onto the stack. At the end, sum everything in the stack.
- **Q:** How would you convert infix to postfix (Shunting Yard algorithm)?
  **A:** Use an operator stack. Push operators, but before pushing, pop operators with higher or equal precedence to the output. Parentheses control precedence boundaries. This is the classic Dijkstra algorithm.

---

### Pattern 4: Stack for Histogram / Trapping Water

**Use an increasing stack to find the largest rectangle in a histogram — when a shorter bar arrives, pop taller bars and compute the area they can form.**

**When to recognize it:** Problems involving bars, heights, or areas where you need to find the largest rectangle or trapped water.

💡 **Intuition:** Imagine bars of different heights side by side. For each bar, the widest rectangle it can be part of extends left and right until it hits a shorter bar. The monotonic stack efficiently finds these boundaries: when a bar is popped, the current bar is its right boundary, and the new stack top is its left boundary.

```java
// LC 84: Largest Rectangle in Histogram [🔥 Must Do]
public int largestRectangleArea(int[] heights) {
    Deque<Integer> stack = new ArrayDeque<>(); // increasing stack of indices
    int maxArea = 0;
    int n = heights.length;

    for (int i = 0; i <= n; i++) {
        int currentHeight = (i == n) ? 0 : heights[i]; // sentinel at end forces cleanup
        while (!stack.isEmpty() && currentHeight < heights[stack.peek()]) {
            int height = heights[stack.pop()];          // height of the bar being evaluated
            int width = stack.isEmpty() ? i : i - stack.peek() - 1; // width it can span
            maxArea = Math.max(maxArea, height * width);
        }
        stack.push(i);
    }
    return maxArea;
}
```

⚙️ **Under the Hood — Width Calculation:**
When we pop index `j` at position `i`:
- Right boundary: `i` (the first shorter bar to the right)
- Left boundary: `stack.peek()` after popping (the first shorter bar to the left)
- Width: `i - stack.peek() - 1`
- If stack is empty after popping: the bar extends all the way to the left edge → width = `i`

```
heights = [2, 1, 5, 6, 2, 3]

Stack trace:
i=0 (h=2): push 0 → stack=[0]
i=1 (h=1): 1<2 → pop 0, height=2, width=1 (stack empty → width=i=1), area=2
           push 1 → stack=[1]
i=2 (h=5): push 2 → stack=[1,2]
i=3 (h=6): push 3 → stack=[1,2,3]
i=4 (h=2): 2<6 → pop 3, height=6, width=4-2-1=1, area=6
           2<5 → pop 2, height=5, width=4-1-1=2, area=10 ← MAX
           2≥1 → stop, push 4 → stack=[1,4]
i=5 (h=3): push 5 → stack=[1,4,5]
i=6 (sentinel h=0):
           0<3 → pop 5, height=3, width=6-4-1=1, area=3
           0<2 → pop 4, height=2, width=6-1-1=4, area=8
           0<1 → pop 1, height=1, width=6 (stack empty), area=6

maxArea = 10 ✓
```

**The sentinel trick:** Adding a virtual bar of height 0 at the end (`i == n`) forces all remaining bars to be popped, avoiding a separate cleanup loop. This is a clean way to handle the "remaining elements in stack" problem.

**Extension — LC 85: Maximal Rectangle** [🔥 Must Do]:
Build a histogram for each row of a binary matrix, then apply the largest rectangle algorithm:

```java
public int maximalRectangle(char[][] matrix) {
    if (matrix.length == 0) return 0;
    int cols = matrix[0].length;
    int[] heights = new int[cols];
    int maxArea = 0;

    for (char[] row : matrix) {
        for (int j = 0; j < cols; j++) {
            heights[j] = (row[j] == '1') ? heights[j] + 1 : 0; // build histogram
        }
        maxArea = Math.max(maxArea, largestRectangleArea(heights));
    }
    return maxArea;
}
```

**Complexity:** O(n) time per histogram, O(rows × cols) total for maximal rectangle. O(n) space.

**Edge Cases:**
- ☐ All bars same height → rectangle = height × n
- ☐ Strictly increasing → largest is last bar's height × 1 or a wider shorter bar
- ☐ Strictly decreasing → all bars popped immediately, widest bar wins
- ☐ Single bar → area = height
- ☐ All zeros → area = 0

🎯 **Likely Follow-ups:**
- **Q:** Can you solve this without a stack?
  **A:** Yes — for each bar, binary search or precompute the left and right boundaries (first shorter bar). But the stack approach is cleaner and O(n).
- **Q:** How does this extend to 2D (maximal rectangle in a binary matrix)?
  **A:** Treat each row as the base of a histogram. For each row, compute the height of consecutive 1s above it. Then apply the 1D histogram algorithm. Total: O(rows × cols).
- **Q:** How would you solve Trapping Rain Water with a stack?
  **A:** Use an increasing stack. When a taller bar arrives, pop shorter bars — the trapped water between the popped bar and the current bar (bounded by the new stack top) can be computed. This gives O(n) time, O(n) space.

> 🔗 **See Also:** [01-dsa/02-two-pointers-sliding-window.md](02-two-pointers-sliding-window.md) for the two-pointer approach to Trapping Rain Water (O(1) space). [01-dsa/07-dynamic-programming.md](07-dynamic-programming.md) for DP-based approaches to maximal rectangle.

---

### Pattern 5: Queue for BFS / Level-Order Processing

**Use a queue to process elements level by level — enqueue children, dequeue parents, and use `levelSize` to separate levels.**

**When to recognize it:** Process elements level by level, or explore neighbors in order (BFS).

💡 **Intuition:** BFS is like ripples in a pond. You drop a stone (start node), and the ripple expands outward one ring at a time. The queue ensures you process all nodes at distance 1 before any node at distance 2, and so on.

```java
// BFS template (used extensively in Trees and Graphs docs)
public void bfs(TreeNode root) {
    if (root == null) return;
    Deque<TreeNode> queue = new ArrayDeque<>();
    queue.offer(root);

    while (!queue.isEmpty()) {
        int levelSize = queue.size(); // CRITICAL: capture size before processing
        for (int i = 0; i < levelSize; i++) {
            TreeNode node = queue.poll();
            // process node
            if (node.left != null) queue.offer(node.left);
            if (node.right != null) queue.offer(node.right);
        }
        // one level fully processed here
    }
}
```

**Why `levelSize` matters:** Capturing `queue.size()` before the inner loop lets you process exactly one level per outer iteration. Without it, newly added children would be processed in the same iteration, mixing levels.

```
Tree:       1
          /   \
         2     3
        / \     \
       4   5     6

Queue state during BFS:
Start:     [1]                    levelSize=1
Level 0:   process 1, add 2,3 → [2, 3]     levelSize=2
Level 1:   process 2, add 4,5 → [3, 4, 5]
           process 3, add 6   → [4, 5, 6]  levelSize=3
Level 2:   process 4,5,6      → []
```

**Edge Cases:**
- ☐ Empty tree (null root) → return empty result
- ☐ Single node → one level with one element
- ☐ Skewed tree (all left or all right) → each level has one node
- ☐ Complete binary tree → levels double in size

🎯 **Likely Follow-ups:**
- **Q:** Can you do BFS without a queue?
  **A:** You can use two lists (current level and next level), swapping them after each level. But a queue with `levelSize` is cleaner and more memory-efficient.
- **Q:** What's the space complexity of BFS?
  **A:** O(w) where w is the maximum width of the tree. For a complete binary tree, the last level has ~n/2 nodes, so space is O(n). For a skewed tree, it's O(1).

> 🔗 **See Also:** [01-dsa/05-trees.md](05-trees.md) for tree BFS problems. [01-dsa/06-graphs.md](06-graphs.md) for graph BFS (shortest path in unweighted graphs).

---

### Pattern 6: Stack for Decoding / Flattening Nested Structures

**Use two stacks — one for counts and one for strings — to decode nested patterns like `3[a2[c]]` from the inside out.**

**When to recognize it:** Nested encoding like `3[a2[c]]`, nested lists, or recursive structures that need to be flattened.

💡 **Intuition:** When you see `[`, you're entering a new nesting level — save your current work and start fresh. When you see `]`, you're exiting — take what you built, repeat it, and append it to the saved work. The stack remembers your work at each nesting level.

```java
// LC 394: Decode String [🔥 Must Do]
public String decodeString(String s) {
    Deque<StringBuilder> strStack = new ArrayDeque<>();   // saved strings at each level
    Deque<Integer> countStack = new ArrayDeque<>();       // repeat counts
    StringBuilder current = new StringBuilder();           // current string being built
    int k = 0;                                             // current repeat count

    for (char c : s.toCharArray()) {
        if (Character.isDigit(c)) {
            k = k * 10 + (c - '0');           // build multi-digit number
        } else if (c == '[') {
            countStack.push(k);               // save repeat count
            strStack.push(current);           // save current string
            current = new StringBuilder();    // start fresh for inner content
            k = 0;
        } else if (c == ']') {
            int repeat = countStack.pop();
            StringBuilder decoded = strStack.pop();          // restore outer string
            decoded.append(String.valueOf(current).repeat(repeat)); // append repeated inner
            current = decoded;                                // continue building
        } else {
            current.append(c);                // regular character
        }
    }
    return current.toString();
}
```

**Dry run:** `s = "3[a2[c]]"`

```
'3': k=3
'[': push k=3, push current="". current="", k=0
'a': current="a"
'2': k=2
'[': push k=2, push current="a". current="", k=0
'c': current="c"
']': repeat=pop()=2, outer=pop()="a". outer="a"+"cc"="acc". current="acc"
']': repeat=pop()=3, outer=pop()="". outer=""+"accaccacc"="accaccacc". current="accaccacc"

Result: "accaccacc" ✓
```

**Edge Cases:**
- ☐ No nesting `"abc"` → no brackets, just return the string
- ☐ Multi-digit count `"100[a]"` → build k with `k * 10 + digit`
- ☐ Deeply nested `"2[a3[b2[c]]]"` → stack handles arbitrary depth
- ☐ Adjacent encoded sections `"2[a]3[b]"` → process sequentially

---

### Pattern 7: Min Stack / Stack with Auxiliary State

**Maintain a parallel stack that tracks the minimum at each level — every push/pop keeps both stacks in sync, giving O(1) min access.**

**When to recognize it:** Need O(1) access to min/max element in a stack at all times.

💡 **Intuition:** The trick is that the minimum can only change when you push or pop. When you push a new element, the new minimum is either the element itself or the previous minimum (whichever is smaller). When you pop, the minimum reverts to whatever it was before that element was pushed. A parallel stack remembers the minimum at each "snapshot" of the stack.

```java
// LC 155: Min Stack [🔥 Must Do]
class MinStack {
    private Deque<Integer> stack = new ArrayDeque<>();
    private Deque<Integer> minStack = new ArrayDeque<>(); // tracks min at each level

    public void push(int val) {
        stack.push(val);
        // Push the new minimum: either val or the current min (whichever is smaller)
        minStack.push(minStack.isEmpty() ? val : Math.min(val, minStack.peek()));
    }

    public void pop() {
        stack.pop();
        minStack.pop(); // keep in sync
    }

    public int top() { return stack.peek(); }
    public int getMin() { return minStack.peek(); } // O(1)!
}
```

**Dry run:** push(5), push(3), push(7), getMin(), pop(), getMin()

```
push(5): stack=[5], minStack=[5]
push(3): stack=[5,3], minStack=[5,3]  (min(3,5)=3)
push(7): stack=[5,3,7], minStack=[5,3,3]  (min(7,3)=3)
getMin(): minStack.peek() = 3 ✓
pop():    stack=[5,3], minStack=[5,3]
getMin(): minStack.peek() = 3 ✓
pop():    stack=[5], minStack=[5]
getMin(): minStack.peek() = 5 ✓
```

**Space optimization:** Instead of a full parallel stack, only push to minStack when the new value is ≤ current min. On pop, only pop minStack if the popped value equals the current min. This saves space when the minimum rarely changes.

```java
// Space-optimized MinStack
public void push(int val) {
    stack.push(val);
    if (minStack.isEmpty() || val <= minStack.peek()) {
        minStack.push(val); // only push if new min or equal
    }
}

public void pop() {
    if (stack.pop().equals(minStack.peek())) {
        minStack.pop(); // only pop if we're removing the current min
    }
}
```

⚠️ **Common Pitfall:** Use `.equals()` not `==` for the comparison in the optimized version, because `stack.pop()` returns `Integer` (boxed), and `==` fails for values outside [-128, 127].

🎯 **Likely Follow-ups:**
- **Q:** How would you implement a Max Stack with O(1) push, pop, top, peekMax, and popMax?
  **A:** `popMax` is the hard part — you can't just pop from the top. Use a TreeMap (sorted by value) alongside the stack, with a lazy deletion approach. Or use a doubly-linked list + TreeMap for O(log n) popMax.
- **Q:** Can you implement MinStack with O(1) space (no auxiliary stack)?
  **A:** Yes — store `2 * val - min` when val < min (encodes both the value and the previous min). On pop, if the stored value < min, the actual value was `min` and the previous min was `2 * min - stored`. This is clever but fragile with integer overflow.

---

### Pattern 8: Implement One Using the Other

**Use two stacks to implement a queue — one for input, one for output. Transfer elements lazily from input to output only when output is empty.**

**When to recognize it:** "Implement queue using stacks" or "implement stack using queues" — tests understanding of both data structures.

```java
// LC 232: Implement Queue using Stacks [🔥 Must Do]
class MyQueue {
    private Deque<Integer> inStack = new ArrayDeque<>();   // for push
    private Deque<Integer> outStack = new ArrayDeque<>();  // for pop/peek

    public void push(int x) { inStack.push(x); }

    public int pop() {
        if (outStack.isEmpty()) transfer(); // lazy transfer
        return outStack.pop();
    }

    public int peek() {
        if (outStack.isEmpty()) transfer();
        return outStack.peek();
    }

    public boolean empty() { return inStack.isEmpty() && outStack.isEmpty(); }

    private void transfer() {
        while (!inStack.isEmpty()) outStack.push(inStack.pop());
        // Reversing the order: LIFO → LIFO = FIFO!
    }
}
```

⚙️ **Under the Hood — Why This is Amortized O(1):**
Each element is moved from inStack to outStack at most once. If you perform n operations total, the total transfer work is at most n (each element transferred once). Spread across n operations → amortized O(1) per operation.

```
push(1), push(2), push(3):
  inStack: [3, 2, 1]  outStack: []

pop():
  outStack empty → transfer: inStack→outStack
  inStack: []  outStack: [1, 2, 3]
  pop from outStack → returns 1 ✓ (FIFO!)

push(4):
  inStack: [4]  outStack: [2, 3]

pop():
  outStack not empty → pop from outStack → returns 2 ✓

pop():
  outStack: [3] → pop → returns 3 ✓

pop():
  outStack empty → transfer: inStack [4] → outStack [4]
  pop → returns 4 ✓
```

**Edge Cases:**
- ☐ Pop/peek on empty queue → depends on problem constraints (usually guaranteed non-empty)
- ☐ Alternating push and pop → transfer happens frequently but still amortized O(1)
- ☐ Many pushes then many pops → one big transfer, then all pops are O(1)

🎯 **Likely Follow-ups:**
- **Q:** What's the worst-case time for a single pop operation?
  **A:** O(n) — when outStack is empty and inStack has n elements, all n must be transferred. But amortized over all operations, it's O(1).
- **Q:** How would you implement a stack using queues?
  **A:** Two approaches: (1) Make push O(n): after pushing to queue, rotate all previous elements behind it. (2) Make pop O(n): on pop, move all but the last element to the other queue. Approach 1 is more common.


---

## 3. Patterns Summary Table

| # | Pattern | When to Use | Key Idea | Time | Space | Example Problem |
|---|---------|------------|----------|------|-------|-----------------|
| 1 | Matching brackets | Balanced parentheses, nesting | Push open, pop on close, check match | O(n) | O(n) | Valid Parentheses (LC 20) |
| 2 | Monotonic stack | Next/previous greater/smaller | Maintain sorted stack, pop when violated | O(n) | O(n) | Daily Temperatures (LC 739) |
| 3 | Expression evaluation | Calculator, RPN, infix parsing | Operand stack + operator handling | O(n) | O(n) | Basic Calculator (LC 224) |
| 4 | Histogram / area | Largest rectangle, trapped water | Increasing stack, compute area on pop | O(n) | O(n) | Largest Rectangle (LC 84) |
| 5 | BFS with queue | Level-order, shortest path | Queue + levelSize for level separation | O(n) | O(w) | Binary Tree Level Order |
| 6 | Decode / flatten | Nested encoding, recursive structures | Two stacks: counts + strings | O(n×m) | O(n) | Decode String (LC 394) |
| 7 | Min/Max stack | O(1) min/max with stack ops | Parallel stack tracking min at each level | O(1) all | O(n) | Min Stack (LC 155) |
| 8 | Implement one with other | Queue↔Stack conversion | Two stacks for queue (lazy transfer) | O(1)* | O(n) | Queue using Stacks (LC 232) |

**Pattern Selection Flowchart:**

```
What does the problem involve?
├── Matching/balancing brackets? → Pattern 1: Matching Parentheses
├── "Next greater/smaller element"? → Pattern 2: Monotonic Stack
├── Evaluate expression / calculator? → Pattern 3: Expression Evaluation
├── Largest rectangle / area with bars? → Pattern 4: Histogram Stack
├── Level-by-level processing / BFS? → Pattern 5: Queue BFS
├── Decode nested encoding? → Pattern 6: Decode Stack
├── O(1) min/max access in stack? → Pattern 7: Min Stack
└── Implement stack↔queue? → Pattern 8: Cross-Implementation
```

---

## 4. LeetCode Problem List (Must-Solve)

### Easy

| # | Problem Name | LC # | Pattern(s) | Why Important |
|---|-------------|------|-----------|---------------|
| 1 | Valid Parentheses | 20 | Matching brackets | [🔥 Must Do] Fundamental stack problem |
| 2 | Min Stack | 155 | Auxiliary stack | [🔥 Must Do] O(1) min access |
| 3 | Implement Queue using Stacks | 232 | Cross-implementation | [🔥 Must Do] Amortized analysis |
| 4 | Implement Stack using Queues | 225 | Cross-implementation | Understand the cost trade-off |
| 5 | Next Greater Element I | 496 | Monotonic stack | Intro to monotonic stack |
| 6 | Baseball Game | 682 | Basic stack | Simple simulation |
| 7 | Backspace String Compare | 844 | Stack / two pointers | Two approaches |
| 8 | Remove All Adjacent Duplicates In String | 1047 | Stack | Stack-based string processing |
| 9 | Number of Recent Calls | 933 | Queue | Sliding window with queue |
| 10 | Moving Average from Data Stream | 346 | Queue (fixed window) | Queue as fixed-size buffer |

### Medium

| # | Problem Name | LC # | Pattern(s) | Why Important |
|---|-------------|------|-----------|---------------|
| 1 | Daily Temperatures | 739 | Monotonic stack | [🔥 Must Do] Classic next greater with distance |
| 2 | Evaluate Reverse Polish Notation | 150 | Expression evaluation | [🔥 Must Do] Postfix evaluation |
| 3 | Decode String | 394 | Nested decode | [🔥 Must Do] Two-stack nested processing |
| 4 | Largest Rectangle in Histogram | 84 | Histogram stack | [🔥 Must Do] Core histogram pattern |
| 5 | Online Stock Span | 901 | Monotonic stack | Previous greater element variant |
| 6 | Next Greater Element II | 503 | Monotonic stack + circular | Circular array trick (2n iterations) |
| 7 | Remove K Digits | 402 | Monotonic stack (greedy) | [🔥 Must Do] Build smallest number |
| 8 | Asteroid Collision | 735 | Stack simulation | Collision rules with stack |
| 9 | Basic Calculator II | 227 | Expression evaluation | Handle * / priority without parentheses |
| 10 | Simplify Path | 71 | Stack | Unix path simplification |
| 11 | Flatten Nested List Iterator | 341 | Stack | Lazy flattening with stack |
| 12 | Validate Stack Sequences | 946 | Stack simulation | Simulate push/pop sequence |
| 13 | Car Fleet | 853 | Monotonic stack / sort | [🔥 Must Do] Sort + stack for fleet merging |
| 14 | 132 Pattern | 456 | Monotonic stack | [🔥 Must Do] Reverse traversal, track second max |
| 15 | Remove Duplicate Letters | 316 | Monotonic stack + greedy | Smallest lexicographic result |
| 16 | Sum of Subarray Minimums | 907 | Monotonic stack | [🔥 Must Do] Contribution technique |
| 17 | Minimum Add to Make Parentheses Valid | 921 | Counter / stack | Count unmatched brackets |
| 18 | Score of Parentheses | 856 | Stack (depth tracking) | Nested scoring |
| 19 | Minimum Remove to Make Valid Parentheses | 1249 | Stack + index tracking | Mark invalid indices |
| 20 | Design Circular Queue | 622 | Array + pointers | Circular buffer implementation |
| 21 | Design Circular Deque | 641 | Array + pointers | Extension of circular queue |
| 22 | Exclusive Time of Functions | 636 | Stack | Function call stack simulation |
| 23 | Maximum Width Ramp | 962 | Monotonic stack | Decreasing stack + reverse scan |
| 24 | Maximal Rectangle | 85 | Histogram stack per row | [🔥 Must Do] Build histogram row by row |
| 25 | Trapping Rain Water | 42 | Stack / two pointers | [🔥 Must Do] Stack-based approach |

### Hard

| # | Problem Name | LC # | Pattern(s) | Why Important |
|---|-------------|------|-----------|---------------|
| 1 | Largest Rectangle in Histogram | 84 | Histogram stack | [🔥 Must Do] Foundation for maximal rectangle |
| 2 | Trapping Rain Water | 42 | Monotonic stack | Stack approach (vs two-pointer) |
| 3 | Basic Calculator | 224 | Expression + parentheses | [🔥 Must Do] Full calculator with nesting |
| 4 | Longest Valid Parentheses | 32 | Stack (index tracking) | [🔥 Must Do] Stack stores indices of unmatched |
| 5 | Maximum Frequency Stack | 895 | Stack of stacks | Frequency-based pop |
| 6 | Sum of Subarray Ranges | 2104 | Monotonic stack | Sum of max - sum of min |
| 7 | Number of Visible People in a Queue | 1944 | Monotonic stack | Decreasing stack with counting |
| 8 | Create Maximum Number | 321 | Monotonic stack + merge | Two-array max number |
| 9 | Stamping The Sequence | 936 | Reverse simulation + stack | Work backwards |
| 10 | Shortest Subarray with Sum at Least K | 862 | Monotonic deque + prefix sum | Deque for negative numbers |

---

## 5. Interview Strategy

**How to recognize a stack problem:**
- Keywords: "nested", "matching", "balanced", "innermost", "last seen", "undo", "reverse"
- "Next greater/smaller" → monotonic stack
- "Evaluate expression" → operand stack
- "Largest rectangle / area" → histogram stack pattern
- "Decode/flatten nested structure" → two stacks

**How to recognize a queue problem:**
- Keywords: "level by level", "order of arrival", "FIFO", "BFS", "shortest path"
- "Shortest path in unweighted graph" → BFS with queue
- "Sliding window max/min" → monotonic deque
- "Process in order" → queue

**Communication tips:**

```
You: "I'll use a stack because this problem has LIFO semantics — the most
     recent unmatched bracket is the one I need to match first."

You: "I'll maintain a monotonic decreasing stack. When I encounter an element
     larger than the top, I know the top has found its next greater element.
     Each element is pushed and popped at most once, so despite the inner
     while loop, the total time is O(n)."

You: "For the histogram problem, I'll use an increasing stack. When a shorter
     bar arrives, I pop taller bars — the popped bar's rectangle extends from
     the new stack top to the current position."
```

**Common mistakes:**
- Forgetting to check `stack.isEmpty()` before `peek()`/`pop()` → `NoSuchElementException`
- Using `Stack<E>` instead of `ArrayDeque<E>` → interviewer may comment on it
- In monotonic stack: confusing when to use increasing vs decreasing (think about what you're finding)
- In histogram: forgetting the sentinel (virtual bar of height 0 at the end)
- Not handling the remaining elements in the stack after the main loop
- In expression evaluation: wrong operand order for subtraction/division (`a - b` ≠ `b - a`)
- In Min Stack: using `==` instead of `.equals()` for Integer comparison

💥 **What Can Go Wrong in Interviews:**

| Mistake | Impact | Prevention |
|---------|--------|------------|
| Empty stack access | Runtime exception | Always check `isEmpty()` before `peek()`/`pop()` |
| Wrong monotonic direction | Completely wrong results | Ask: "Am I finding next GREATER or SMALLER?" |
| Missing sentinel in histogram | Incomplete results | Add virtual height-0 bar at end |
| Wrong operand order in RPN | Wrong calculation | Remember: first pop = second operand |
| Forgetting `levelSize` in BFS | Levels mixed together | Always capture `queue.size()` before inner loop |

---

## 6. Edge Cases & Pitfalls

**Stack edge cases:**
- ☐ Empty input string/array → return default (empty, 0, true)
- ☐ Single element → nothing to match/compare
- ☐ All elements in increasing order → nothing gets popped until the end (or sentinel)
- ☐ All elements in decreasing order → everything gets popped immediately
- ☐ Nested structures with max depth → stack size = n (worst case)

**Queue edge cases:**
- ☐ Empty queue operations → check before poll/peek
- ☐ Single element → trivial
- ☐ Circular queue: full vs empty → both have `front == rear` — use size counter or waste one slot

**Java-specific pitfalls:**

```java
// PITFALL 1: ArrayDeque does not allow null
Deque<Integer> deque = new ArrayDeque<>();
deque.push(null); // NullPointerException!
// Use LinkedList if you need null support (rare)

// PITFALL 2: Different exceptions for different methods
Deque<Integer> stack = new ArrayDeque<>();
stack.pop();    // NoSuchElementException (unsafe)
stack.poll();   // returns null (safe)
stack.peek();   // returns null if empty (safe)
stack.element(); // NoSuchElementException (unsafe)

// PITFALL 3: Character comparison from stack
Deque<Character> charStack = new ArrayDeque<>();
charStack.push('a');
char c = charStack.pop(); // auto-unboxing works
// But be careful with == for Character objects > 127

// PITFALL 4: Storing pairs in stack
// Java doesn't have a Pair class in standard library
// Options: int[] of size 2, or custom record
Deque<int[]> stack = new ArrayDeque<>();
stack.push(new int[]{index, value}); // works fine
// Or in Java 16+:
record Pair(int index, int value) {}
Deque<Pair> stack2 = new ArrayDeque<>();
```

---

## 7. Connections to Other Topics

| This Pattern | Connects To | How |
|-------------|-------------|-----|
| Monotonic stack | [01-dsa/02-two-pointers-sliding-window.md](02-two-pointers-sliding-window.md) | Monotonic deque = stack that also removes from front (sliding window max/min) |
| BFS queue | [01-dsa/05-trees.md](05-trees.md) | Level-order traversal, zigzag traversal, right side view |
| BFS queue | [01-dsa/06-graphs.md](06-graphs.md) | Shortest path in unweighted graphs, multi-source BFS |
| Expression evaluation | [01-dsa/05-trees.md](05-trees.md) | Expression trees are evaluated with stack or recursion |
| Histogram stack | [01-dsa/07-dynamic-programming.md](07-dynamic-programming.md) | Maximal rectangle uses histogram per row (DP builds heights, stack finds area) |
| Matching brackets | Recursion | Stack simulates the call stack in recursive solutions |
| Min Stack | [04-lld/problems/cache-lru-lfu.md](../04-lld/problems/cache-lru-lfu.md) | Auxiliary data structure pattern for O(1) operations |
| Stack for DFS | [01-dsa/06-graphs.md](06-graphs.md) | Iterative DFS uses an explicit stack instead of recursion |
| Queue design | [02-system-design/03-message-queues-event-driven.md](../02-system-design/03-message-queues-event-driven.md) | Message queues (Kafka, SQS) are distributed FIFO/priority queues |
| Circular queue | [05-java/02-collections-internals.md](../05-java/02-collections-internals.md) | ArrayDeque's circular buffer implementation |

---

## 8. Revision Checklist

**Data structures:**
- [ ] Use `ArrayDeque` for both stack and queue — never `Stack<E>` (legacy, synchronized)
- [ ] Stack: `push()`, `pop()`, `peek()` — all O(1), LIFO
- [ ] Queue: `offer()`, `poll()`, `peek()` — all O(1), FIFO
- [ ] Deque: operations at both ends — all O(1), can be stack or queue
- [ ] Use `offer/poll/peek` (safe, return null) not `add/remove/element` (throw exceptions)
- [ ] ArrayDeque: circular array, default capacity 16, doubles on resize, no nulls

**Patterns (one-line each):**
- [ ] Matching brackets → push open, pop on close, check match, stack empty at end
- [ ] Monotonic stack → maintain sorted order, pop when violated, popped element found its answer
- [ ] Next greater → decreasing stack; next smaller → increasing stack
- [ ] Expression evaluation → operand stack, handle operator precedence, watch operand order
- [ ] Histogram area → increasing stack, compute width on pop: `i - stack.peek() - 1`, use sentinel
- [ ] BFS → queue + `levelSize = queue.size()` for level separation
- [ ] Decode string → two stacks (counts + strings), save on `[`, restore and repeat on `]`
- [ ] Min stack → parallel stack tracking min at each level, push `Math.min(val, currentMin)`
- [ ] Queue from stacks → two stacks (in/out), lazy transfer from in to out when out is empty

**Monotonic stack cheat sheet:**

| Find | Stack Type | Pop Condition | What You Learn |
|------|-----------|---------------|----------------|
| Next Greater (right) | Decreasing | `nums[i] > top` | Popped element's next greater = nums[i] |
| Next Smaller (right) | Increasing | `nums[i] < top` | Popped element's next smaller = nums[i] |
| Previous Greater (left) | Decreasing | `nums[i] >= top` | Current element's prev greater = new top |
| Previous Smaller (left) | Increasing | `nums[i] <= top` | Current element's prev smaller = new top |

**Critical details:**
- [ ] Monotonic stack is O(n) despite inner while loop — each element pushed/popped at most once
- [ ] Histogram sentinel: add virtual height-0 bar at end to force cleanup
- [ ] Width in histogram: `stack.isEmpty() ? i : i - stack.peek() - 1`
- [ ] BFS `levelSize`: capture `queue.size()` BEFORE the inner loop
- [ ] RPN operand order: first pop = second operand (`b`), second pop = first operand (`a`)
- [ ] Min Stack optimization: only push to minStack when `val <= currentMin`
- [ ] Queue from stacks: amortized O(1) — each element transferred at most once

**Top 10 must-solve before interview:**
1. Valid Parentheses (LC 20) [Easy] — Matching brackets
2. Min Stack (LC 155) [Medium] — Auxiliary stack for O(1) min
3. Daily Temperatures (LC 739) [Medium] — Monotonic stack with distance
4. Largest Rectangle in Histogram (LC 84) [Hard] — Histogram stack pattern
5. Evaluate Reverse Polish Notation (LC 150) [Medium] — Postfix evaluation
6. Decode String (LC 394) [Medium] — Two-stack nested decoding
7. Implement Queue using Stacks (LC 232) [Easy] — Amortized O(1) analysis
8. Trapping Rain Water — stack approach (LC 42) [Hard] — Alternative to two pointers
9. Basic Calculator (LC 224) [Hard] — Full calculator with parentheses
10. Longest Valid Parentheses (LC 32) [Hard] — Stack stores indices

---

## 📋 Suggested New Documents

### 1. Monotonic Stack & Monotonic Queue Deep Dive
- **Placement**: `01-dsa/12-monotonic-stack-queue.md`
- **Why needed**: The monotonic stack pattern appears in this doc and the sliding window doc, but advanced applications (contribution technique for sum of subarray mins/maxs, stock span, largest rectangle variants, monotonic queue for deque-based problems) deserve dedicated coverage.
- **Key subtopics**: Contribution technique (LC 907, 2104), next greater/smaller in all 4 directions, circular array handling, monotonic deque for sliding window problems, stack-based approaches vs DP for rectangle problems

### 2. Design Problems Using Stacks & Queues
- **Placement**: `04-lld/problems/stack-queue-designs.md`
- **Why needed**: Several LLD-style problems use stacks/queues as core data structures: browser history (stack), task scheduler (queue), undo/redo system (two stacks), expression parser. These bridge DSA and LLD.
- **Key subtopics**: Browser history with forward/back, undo/redo with command pattern, task scheduler with priority queue, expression parser/compiler
