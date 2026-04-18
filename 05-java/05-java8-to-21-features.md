# Java 8 to 21 Features

## 1. What & Why

**Modern Java has evolved significantly since Java 8. Interviewers expect SDE-2 candidates to know features beyond Java 8 and use them idiomatically — streams, Optional, records, sealed classes, pattern matching. Using modern Java shows you're current and write clean, expressive code.**

💡 **Intuition — Why Modern Java Features Matter:** Java 8 was revolutionary (lambdas, streams). But Java 9-21 added equally important features: records (immutable data classes in one line), sealed classes (controlled inheritance), pattern matching (cleaner instanceof), text blocks (multi-line strings), and virtual threads (lightweight concurrency). Using these in interviews shows maturity.

> 🔗 **See Also:** [05-java/01-core-java.md](01-core-java.md) for Java fundamentals. [05-java/03-concurrency-multithreading.md](03-concurrency-multithreading.md) for CompletableFuture (Java 8) and virtual threads (Java 21).

## 2. Core Concepts

### Java 8 (2014) — The Big One [🔥 Must Know]

**Lambda Expressions:**
```java
// Before: anonymous inner class
Comparator<String> comp = new Comparator<>() {
    public int compare(String a, String b) { return a.length() - b.length(); }
};
// After: lambda
Comparator<String> comp = (a, b) -> a.length() - b.length();
```

**Functional Interfaces:** Interface with exactly one abstract method. `@FunctionalInterface` annotation.
- `Predicate<T>`: T → boolean
- `Function<T,R>`: T → R
- `Consumer<T>`: T → void
- `Supplier<T>`: () → T
- `BiFunction<T,U,R>`: (T, U) → R

**Stream API** [🔥 Must Know]:
```java
List<String> names = people.stream()
    .filter(p -> p.getAge() > 18)
    .map(Person::getName)
    .sorted()
    .distinct()
    .collect(Collectors.toList());

// Common collectors
Collectors.toList(), toSet(), toMap(), groupingBy(), partitioningBy(), joining()

// Parallel streams (use cautiously)
list.parallelStream().filter(...).collect(...)
```

**Optional** [🔥 Must Know]:
```java
Optional<String> name = Optional.ofNullable(getName());
String result = name.orElse("default");
String result2 = name.orElseThrow(() -> new RuntimeException("not found"));
name.ifPresent(n -> System.out.println(n));
name.map(String::toUpperCase).orElse("");
```

**Method References:** `Class::method` — shorthand for lambdas.
```java
list.forEach(System.out::println);  // instance method reference
list.stream().map(String::toUpperCase);  // unbound method reference
```

**Default Methods in Interfaces:** Interfaces can have method implementations.

**Date/Time API:** `LocalDate`, `LocalTime`, `LocalDateTime`, `ZonedDateTime`, `Duration`, `Period`. Immutable, thread-safe. Replaces `Date`/`Calendar`.

### Java 9-10

- **Modules (JPMS):** Module system for encapsulation (`module-info.java`)
- **`var` (Java 10):** Local variable type inference: `var list = new ArrayList<String>();`
- **Collection factory methods:** `List.of(1,2,3)`, `Set.of("a","b")`, `Map.of("k","v")`
- **Stream improvements:** `takeWhile()`, `dropWhile()`, `ofNullable()`
- **Optional improvements:** `ifPresentOrElse()`, `or()`, `stream()`

### Java 11 (LTS)
- **String methods:** `isBlank()`, `strip()`, `lines()`, `repeat(n)`
- **`var` in lambdas:** `(var x, var y) -> x + y`
- **`HttpClient`:** Modern HTTP client (replaces `HttpURLConnection`)
- **`Files.readString()` / `writeString()`**

### Java 14-16
- **Records (Java 16)** [🔥 Must Know]:
```java
record Point(int x, int y) {}
// Auto-generates: constructor, getters (x(), y()), equals, hashCode, toString
// Immutable, final class
```

- **Pattern Matching for instanceof (Java 16):**
```java
if (obj instanceof String s) {
    System.out.println(s.length()); // s already cast
}
```

- **Sealed Classes (Java 17):**
```java
sealed interface Shape permits Circle, Rectangle, Triangle {}
record Circle(double radius) implements Shape {}
// Only permitted classes can implement Shape
```

- **Text Blocks (Java 15):**
```java
String json = """
    {
        "name": "Alice",
        "age": 30
    }
    """;
```

### Java 17 (LTS) [🔥 Must Know]
- Sealed classes
- Pattern matching for instanceof
- Records
- Text blocks
- All features from 9-16 stabilized

### Java 21 (LTS)
- **Virtual Threads (Project Loom)** [🔥 Must Know]:
```java
// Lightweight threads managed by JVM, not OS
Thread.startVirtualThread(() -> { /* task */ });

// With executor
try (var executor = Executors.newVirtualThreadPerTaskExecutor()) {
    executor.submit(() -> handleRequest());
}
// Can create millions of virtual threads (vs thousands of platform threads)
```

- **Pattern Matching for switch:**
```java
String describe(Object obj) {
    return switch (obj) {
        case Integer i -> "Integer: " + i;
        case String s -> "String: " + s;
        case null -> "null";
        default -> "Unknown";
    };
}
```

- **Sequenced Collections:** `SequencedCollection`, `SequencedSet`, `SequencedMap` with `getFirst()`, `getLast()`, `reversed()`.

## 5. Must-Know Interview Questions

1. [🔥 Must Know] **Q:** What are the key features of Java 8? **A:** Lambdas, Stream API, Optional, functional interfaces, default methods, Date/Time API, method references.

2. [🔥 Must Know] **Q:** What is a Stream? How is it different from a Collection? **A:** Stream is a pipeline of operations on data, not a data structure. Lazy evaluation, can be parallel, consumed once. Collection stores data, eager, reusable.

3. [🔥 Must Know] **Q:** What are Records? **A:** Immutable data carriers (Java 16+). Auto-generate constructor, getters, equals, hashCode, toString. Replace boilerplate POJOs.

4. [🔥 Must Know] **Q:** What are Virtual Threads? **A:** Lightweight threads (Java 21) managed by JVM. Can create millions (vs thousands of OS threads). Ideal for I/O-bound workloads. Use `Executors.newVirtualThreadPerTaskExecutor()`.

5. **Q:** What is `var`? **A:** Local variable type inference (Java 10). Compiler infers type. Only for local variables, not fields or method parameters.

## 7. Revision Checklist
- [ ] Java 8: lambdas, streams, Optional, functional interfaces, default methods
- [ ] Java 10: `var` for local variables
- [ ] Java 11: String methods (isBlank, strip), HttpClient
- [ ] Java 16: records, pattern matching instanceof
- [ ] Java 17: sealed classes, text blocks (LTS)
- [ ] Java 21: virtual threads, pattern matching switch, sequenced collections (LTS)
- [ ] Stream: filter → map → sorted → collect. Lazy, consumed once.
- [ ] Optional: orElse, orElseThrow, map, ifPresent. Never use get() without isPresent().
- [ ] Records: immutable, auto-generated methods, replace POJOs
- [ ] Virtual threads: millions possible, ideal for I/O-bound, not CPU-bound
