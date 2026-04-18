# Core Java

## 1. What & Why

**Core Java covers the language fundamentals that every Java developer must know deeply — OOP, memory model, exception handling, generics, and the type system. As a 4-year Java backend engineer, interviewers expect you to explain these concepts with precision and depth.**

These aren't "beginner" topics — interviewers probe deep. "What is polymorphism?" is a warm-up. "How does the JVM resolve method calls at runtime?" is the real question. This document covers both levels.

## 2. Core Concepts

### OOP Pillars [🔥 Must Know]

**Encapsulation:** Bundle data + methods together, hide internals behind access modifiers.

| Modifier | Class | Package | Subclass | World |
|----------|-------|---------|----------|-------|
| `private` | ✅ | ❌ | ❌ | ❌ |
| default (package-private) | ✅ | ✅ | ❌ | ❌ |
| `protected` | ✅ | ✅ | ✅ | ❌ |
| `public` | ✅ | ✅ | ✅ | ✅ |

**Inheritance:** `extends` for classes (single inheritance only), `implements` for interfaces (multiple). Java doesn't support multiple class inheritance to avoid the diamond problem.

**Polymorphism** [🔥 Must Know]:
- **Compile-time (overloading):** Same method name, different parameter types/count. Resolved at compile time by the compiler.
- **Runtime (overriding):** Subclass provides specific implementation of a parent method. Resolved at runtime via the virtual method table (vtable).

⚙️ **Under the Hood — How Runtime Polymorphism Works:**
```java
Animal animal = new Dog(); // reference type: Animal, object type: Dog
animal.speak(); // which speak() is called?

// JVM looks at the ACTUAL object type (Dog), not the reference type (Animal)
// It finds Dog's vtable → looks up speak() → calls Dog.speak()
// This is called "dynamic dispatch" or "late binding"
```

**Abstraction:** Hide complexity, expose only what's necessary.
- **Abstract class:** Partial implementation. Can have state (fields), constructors, concrete methods.
- **Interface:** Pure contract (since Java 8: can have `default` and `static` methods too).

### Abstract Class vs Interface [🔥 Frequently Asked]

| Feature | Abstract Class | Interface |
|---------|---------------|-----------|
| Methods | Abstract + concrete | Abstract + default + static + private (Java 9+) |
| Fields | Instance variables (any type) | Only `public static final` constants |
| Constructor | Yes | No |
| Inheritance | Single (`extends`) | Multiple (`implements`) |
| Access modifiers | Any | `public` (methods default to public) |
| Use when | Shared state/behavior among related classes ("is-a") | Define a capability for unrelated classes ("can-do") |

💡 **Intuition — When to Use Which:**
- "A Dog IS AN Animal" → abstract class (shared state like `name`, `age`)
- "A Dog CAN BE Serializable" → interface (capability, unrelated to class hierarchy)
- Since Java 8, interfaces can have default methods, blurring the line. Rule of thumb: if you need state (fields), use abstract class. If you need multiple inheritance of behavior, use interfaces.

🎯 **Likely Follow-ups:**
- **Q:** Can an abstract class have a constructor if you can't instantiate it?
  **A:** Yes — the constructor is called by subclass constructors via `super()`. It initializes the abstract class's fields. You can't call `new AbstractClass()` directly, but subclasses use it.
- **Q:** What are default methods in interfaces? Why were they added?
  **A:** Added in Java 8 to allow adding methods to interfaces without breaking existing implementations. Example: `List.sort()` was added as a default method — all existing List implementations got it for free.

### `equals()` and `hashCode()` [🔥 Must Know]

**Contract (violating this breaks HashMap/HashSet):**
- If `a.equals(b)` is `true` → `a.hashCode() == b.hashCode()` MUST be `true`
- If `a.hashCode() == b.hashCode()` → `a.equals(b)` may or may not be `true` (hash collision)
- If you override `equals()`, you MUST override `hashCode()`

```java
public class Employee {
    private final String name;
    private final int id;

    @Override
    public boolean equals(Object o) {
        if (this == o) return true;                          // same reference
        if (o == null || getClass() != o.getClass()) return false; // null or different class
        Employee e = (Employee) o;
        return id == e.id && Objects.equals(name, e.name);   // compare fields
    }

    @Override
    public int hashCode() {
        return Objects.hash(name, id); // consistent with equals
    }
}
```

⚠️ **Common Pitfall — What Happens If You Only Override equals():**
```java
Employee e1 = new Employee("Alice", 1);
Employee e2 = new Employee("Alice", 1);
e1.equals(e2); // true (we overrode equals)

Set<Employee> set = new HashSet<>();
set.add(e1);
set.contains(e2); // FALSE! Because hashCode() uses default (memory address)
// e1 and e2 have different hashCodes → HashSet looks in different bucket → not found
```

### Immutability [🔥 Must Know]

**How to create an immutable class:**
1. Declare class `final` (prevent subclassing that could add mutability)
2. All fields `private final`
3. No setters
4. Deep copy mutable fields in constructor and getters
5. Or use `record` (Java 16+): `record Point(int x, int y) {}`

```java
// Immutable class (manual)
public final class Money {
    private final BigDecimal amount;
    private final String currency;
    private final Date createdAt; // Date is mutable!

    public Money(BigDecimal amount, String currency, Date createdAt) {
        this.amount = amount;
        this.currency = currency;
        this.createdAt = new Date(createdAt.getTime()); // defensive copy!
    }

    public Date getCreatedAt() {
        return new Date(createdAt.getTime()); // defensive copy on return!
    }
    // No setters. BigDecimal and String are already immutable.
}

// Immutable class (Java 16+ record — much simpler)
public record Money(BigDecimal amount, String currency) {}
// Automatically: final class, private final fields, constructor, equals, hashCode, toString
```

**Why immutability matters:**
- Thread-safe without synchronization (no shared mutable state)
- Safe as HashMap keys (hashCode never changes)
- Easier to reason about (no unexpected state changes)
- Enables caching (String pool, Integer cache)

### Exception Handling

```
Throwable
├── Error (JVM-level, don't catch)
│   ├── OutOfMemoryError
│   ├── StackOverflowError
│   └── ...
└── Exception
    ├── Checked (must declare/catch)
    │   ├── IOException
    │   ├── SQLException
    │   └── ...
    └── RuntimeException (unchecked, optional to catch)
        ├── NullPointerException
        ├── IllegalArgumentException
        ├── IndexOutOfBoundsException
        └── ...
```

**Best practices:**
- Catch specific exceptions, not `Exception` or `Throwable`
- Use try-with-resources for `AutoCloseable` resources (files, connections, streams)
- Don't use exceptions for flow control (expensive — creates stack trace)
- Custom exceptions for domain-specific errors: `class InsufficientBalanceException extends RuntimeException`
- Prefer unchecked exceptions for programming errors, checked for recoverable conditions

```java
// Try-with-resources (Java 7+) — auto-closes resources
try (var conn = dataSource.getConnection();
     var stmt = conn.prepareStatement("SELECT * FROM users")) {
    // use conn and stmt
} catch (SQLException e) {
    log.error("Database error", e);
    throw new ServiceException("Failed to fetch users", e); // wrap and rethrow
}
// conn and stmt are automatically closed, even if exception occurs
```

### Generics [🔥 Must Know]

**Type erasure:** Generic type info is removed at compile time for backward compatibility. `List<String>` becomes `List<Object>` at runtime.

```java
// At compile time:
List<String> strings = new ArrayList<>();
strings.add("hello");
String s = strings.get(0); // compiler inserts cast

// At runtime (after erasure):
List strings = new ArrayList();
strings.add("hello");
String s = (String) strings.get(0); // explicit cast inserted by compiler
```

**Consequences of type erasure:**
- Can't do `new T()` (T is erased, JVM doesn't know the type)
- Can't do `instanceof List<String>` (generic info gone at runtime)
- Can't create generic arrays: `new T[10]` is illegal
- Can't overload by generic type: `void process(List<String>)` and `void process(List<Integer>)` have the same erasure

**Wildcards and PECS** [🔥 Must Know]:

```java
// ? extends T (upper bound) — PRODUCER: read from it, can't write
List<? extends Number> numbers = new ArrayList<Integer>();
Number n = numbers.get(0); // OK — read as Number
numbers.add(1);            // COMPILE ERROR — can't add (might be List<Double>)

// ? super T (lower bound) — CONSUMER: write to it, can't read (as T)
List<? super Integer> ints = new ArrayList<Number>();
ints.add(1);               // OK — can add Integer
Integer i = ints.get(0);   // COMPILE ERROR — might return Number or Object
Object o = ints.get(0);    // OK — can read as Object

// PECS: Producer Extends, Consumer Super
// Collections.copy(dest, src):
//   src is a PRODUCER (we read from it) → ? extends T
//   dest is a CONSUMER (we write to it) → ? super T
```

### `String`, `StringBuilder`, `StringBuffer`

| Feature | String | StringBuilder | StringBuffer |
|---------|--------|--------------|-------------|
| Mutability | Immutable | Mutable | Mutable |
| Thread-safe | Yes (immutable) | No | Yes (synchronized) |
| Performance | Slow for concatenation | Fast | Slower than StringBuilder |
| Use when | Most cases | String building in loops | Multi-threaded string building (rare) |

### Pass by Value [🔥 Must Know]

**Java is ALWAYS pass by value.** For objects, the reference (pointer) is copied — you can modify the object's state but can't reassign the caller's variable.

```java
void changeValue(int x) { x = 10; }       // doesn't affect caller's variable
void changeObject(List<String> list) {
    list.add("hello");                      // MODIFIES the original list (same object)
    list = new ArrayList<>();               // does NOT affect caller's variable (local reassignment)
}
```

> 🔗 **See Also:** [05-java/02-collections-internals.md](02-collections-internals.md) for HashMap/ArrayList internals. [05-java/03-concurrency-multithreading.md](03-concurrency-multithreading.md) for thread safety and immutability. [05-java/04-jvm-internals-gc.md](04-jvm-internals-gc.md) for memory model and garbage collection.

## 5. Must-Know Interview Questions

1. [🔥 Must Know] **Q:** `==` vs `.equals()`? **A:** `==` compares references (same object in memory). `.equals()` compares content (if overridden). For primitives, `==` compares values. For wrapper types (Integer, String), always use `.equals()`.

2. [🔥 Must Know] **Q:** Why is String immutable? **A:** (1) Thread safety — immutable objects are inherently thread-safe. (2) String pool — interning only works if strings can't change. (3) Security — strings used for class loading, network connections, file paths. (4) HashCode caching — computed once, cached.

3. [🔥 Must Know] **Q:** Abstract class vs interface? **A:** Abstract class: shared state (fields) + behavior, single inheritance. Interface: contract/capability, multiple inheritance, no state (only constants). Since Java 8, interfaces can have default methods. Use abstract class for "is-a" with shared state, interface for "can-do".

4. [🔥 Must Know] **Q:** Explain generics and type erasure. **A:** Generics provide compile-time type safety. Type erasure removes generic info at runtime for backward compatibility with pre-generics code. Consequences: can't do `new T()`, `instanceof List<String>`, or generic arrays.

5. [🔥 Must Know] **Q:** hashCode/equals contract? **A:** Equal objects MUST have equal hash codes. Override both or neither. Violating this breaks HashMap/HashSet (object goes to wrong bucket, can't be found).

6. [🔥 Must Know] **Q:** Pass by value or reference? **A:** Always pass by value. For objects, the reference is copied. You can modify the object's state through the copy, but reassigning the parameter doesn't affect the caller's variable.

7. **Q:** Checked vs unchecked exceptions? **A:** Checked: must be declared/caught, for recoverable conditions (IOException). Unchecked: extend RuntimeException, for programming errors (NullPointerException). Modern practice: prefer unchecked.

8. [🔥 Must Know] **Q:** How to create an immutable class? **A:** Final class, private final fields, no setters, defensive copies of mutable fields. Or use Java records (Java 16+).

9. **Q:** What is PECS? **A:** Producer Extends, Consumer Super. Use `? extends T` when reading from a collection (producer), `? super T` when writing to it (consumer).

10. **Q:** What is the diamond problem? **A:** If class C extends both A and B, and both have a method `foo()`, which `foo()` does C inherit? Java avoids this by allowing single class inheritance only. With interfaces (Java 8+ default methods), if two interfaces have the same default method, the implementing class must override it.

## 7. Revision Checklist

- [ ] OOP: encapsulation (access modifiers), inheritance (single class, multiple interface), polymorphism (overloading=compile-time, overriding=runtime), abstraction
- [ ] `==` vs `.equals()`: reference vs content. Always `.equals()` for objects.
- [ ] String: immutable, pool, backed by byte[] (Java 9+), use StringBuilder in loops
- [ ] hashCode/equals contract: equal objects → equal hash codes. Override both or neither.
- [ ] Generics: type erasure at runtime, can't `new T()` or `instanceof List<String>`. PECS: Producer Extends, Consumer Super.
- [ ] Immutability: final class, private final fields, no setters, defensive copies. Or records (Java 16+).
- [ ] Exceptions: checked (must handle, recoverable) vs unchecked (RuntimeException, programming errors). Try-with-resources for AutoCloseable.
- [ ] Pass by value always. Object references are copied — can modify object, can't reassign caller's variable.
- [ ] Abstract class: state + behavior, single inheritance. Interface: contract, multiple inheritance, default methods (Java 8+).
- [ ] Integer cache: -128 to 127. Always use `.equals()` for wrapper types.
