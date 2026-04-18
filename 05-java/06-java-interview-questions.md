# Java Interview Questions — Rapid Fire

## Comprehensive Q&A organized by topic. Study these for quick recall before interviews.

💡 **How to use this document:** Read through once to identify gaps. Then use it as a flashcard deck — cover the answer, try to answer from memory, check. Focus on [🔥 Must Know] questions first. For deeper understanding, follow the cross-references to the detailed topic documents.

> 🔗 **Detailed coverage:** [05-java/01-core-java.md](01-core-java.md), [05-java/02-collections-internals.md](02-collections-internals.md), [05-java/03-concurrency-multithreading.md](03-concurrency-multithreading.md), [05-java/04-jvm-internals-gc.md](04-jvm-internals-gc.md), [05-java/05-java8-to-21-features.md](05-java8-to-21-features.md).

### Core Java

1. [🔥 Must Know] **Q:** `==` vs `.equals()`? **A:** `==` compares references. `.equals()` compares content (if overridden). Always use `.equals()` for objects.

2. [🔥 Must Know] **Q:** Why is String immutable? **A:** Security (class loading, network), thread safety, String pool optimization, hashCode caching.

3. [🔥 Must Know] **Q:** `final` vs `finally` vs `finalize`? **A:** `final`: constant/prevent override. `finally`: cleanup after try/catch. `finalize`: deprecated GC callback.

4. **Q:** What is autoboxing? **A:** Automatic conversion between primitives and wrappers (`int` ↔ `Integer`). Beware: `Integer` cache is -128 to 127.

5. [🔥 Must Know] **Q:** Checked vs unchecked exceptions? **A:** Checked: must declare/catch (IOException). Unchecked: RuntimeException subclasses (NullPointerException). Use checked for recoverable, unchecked for programming errors.

### Collections

6. [🔥 Must Know] **Q:** HashMap vs Hashtable? **A:** HashMap: not synchronized, allows null key/value. Hashtable: synchronized (legacy), no nulls. Use ConcurrentHashMap instead of Hashtable.

7. [🔥 Must Know] **Q:** How does HashMap handle collisions? **A:** Separate chaining. Linked list in bucket → red-black tree when ≥ 8 entries (Java 8+).

8. **Q:** Comparable vs Comparator? **A:** Comparable: natural ordering, class implements it (`compareTo`). Comparator: external ordering, separate class/lambda (`compare`).

9. [🔥 Must Know] **Q:** Iterator vs ListIterator? **A:** Iterator: forward only, works on all Collections. ListIterator: bidirectional, only for Lists, can add/set elements.

### Concurrency

10. [🔥 Must Know] **Q:** `synchronized` vs `ReentrantLock`? **A:** Both provide mutual exclusion. ReentrantLock adds: tryLock, fairness, interruptible lock, multiple conditions.

11. [🔥 Must Know] **Q:** `wait()` vs `sleep()`? **A:** `wait()`: releases lock, must be in synchronized block, woken by `notify()`. `sleep()`: doesn't release lock, static method, wakes after timeout.

12. [🔥 Must Know] **Q:** What is a thread pool? Why use it? **A:** Reuses threads instead of creating new ones. Reduces overhead, controls concurrency, prevents resource exhaustion.

13. **Q:** `Runnable` vs `Callable`? **A:** Runnable: no return value, no checked exceptions. Callable: returns value (Future), can throw checked exceptions.

14. [🔥 Must Know] **Q:** What is `volatile`? **A:** Guarantees visibility (reads/writes go to main memory). Does NOT guarantee atomicity. Use for flags, not compound operations.

### JVM

15. [🔥 Must Know] **Q:** Stack vs Heap? **A:** Stack: per thread, method frames, local variables, fast. Heap: shared, objects, GC-managed, slower.

16. [🔥 Must Know] **Q:** What is garbage collection? **A:** Automatic memory management. JVM identifies unreachable objects (mark from GC roots) and reclaims their memory (sweep/compact).

17. **Q:** What is a memory leak in Java? **A:** Objects referenced but no longer needed. Common: static collections, unclosed resources, ThreadLocal, listeners.

### Java 8+

18. [🔥 Must Know] **Q:** What is a functional interface? **A:** Interface with exactly one abstract method. Can be used as lambda target. Examples: Predicate, Function, Consumer, Supplier.

19. [🔥 Must Know] **Q:** `map()` vs `flatMap()` in streams? **A:** `map()`: one-to-one transformation. `flatMap()`: one-to-many, flattens nested streams. Example: `flatMap` on `List<List<String>>` → `Stream<String>`.

20. [🔥 Must Know] **Q:** What is Optional? **A:** Container that may or may not hold a value. Avoids NullPointerException. Use `orElse`, `map`, `ifPresent`. Never call `get()` without checking.

### Design

21. [🔥 Must Know] **Q:** What is dependency injection? **A:** Providing dependencies from outside rather than creating them internally. Enables testing (mocks), flexibility (swap implementations). Spring uses constructor/field injection.

22. **Q:** Singleton vs static class? **A:** Singleton: can implement interfaces, lazy initialization, can be mocked. Static: no instance, can't implement interfaces, harder to test.

23. [🔥 Must Know] **Q:** SOLID principles? **A:** Single Responsibility, Open/Closed, Liskov Substitution, Interface Segregation, Dependency Inversion. (See 04-lld/01-solid-principles.md for details.)

### Miscellaneous

24. **Q:** What is serialization? **A:** Converting object to byte stream (for storage/network). Implement `Serializable`. `transient` fields are skipped. `serialVersionUID` for version control.

25. **Q:** What is reflection? **A:** Inspect/modify classes, methods, fields at runtime. Used by frameworks (Spring, Hibernate). Slow, breaks encapsulation. Use sparingly.

26. [🔥 Must Know] **Q:** What is the diamond problem? **A:** Ambiguity when a class inherits from two classes with the same method. Java avoids it by allowing single class inheritance. Interfaces with default methods can cause it — resolved by overriding in the implementing class.

## Revision Checklist
- [ ] Review all [🔥 Must Know] questions above
- [ ] Practice explaining each in 30-60 seconds
- [ ] For each answer, have a follow-up ready
- [ ] Know real-world examples from your work experience
