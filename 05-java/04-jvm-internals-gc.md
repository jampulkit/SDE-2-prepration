# JVM Internals & Garbage Collection

## 1. What & Why

**Understanding JVM internals helps you write performant code, debug memory issues (OutOfMemoryError, GC pauses), and answer the deep "under the hood" questions that SDE-2 interviewers love. When your production service has a memory leak or GC pause, this knowledge is what saves you.**

💡 **Intuition — Why JVM Knowledge Matters:** When your Spring Boot service suddenly slows down every 30 seconds, it's probably a Full GC pause. When it crashes with OutOfMemoryError, it's a memory leak (objects referenced but not needed). When startup is slow, it's class loading. JVM knowledge turns "I don't know why it's slow" into "the Old Gen is full, we need to tune the GC or fix the leak."

> 🔗 **See Also:** [05-java/03-concurrency-multithreading.md](03-concurrency-multithreading.md) for thread stack memory. [07-cs-fundamentals/01-operating-systems.md](../07-cs-fundamentals/01-operating-systems.md) for OS-level memory management (virtual memory, paging).

## 2. Core Concepts

### JVM Architecture [🔥 Must Know]
```
Source (.java) → Compiler (javac) → Bytecode (.class) → JVM → Machine Code

JVM Components:
├── Class Loader (loads .class files)
├── Runtime Data Areas
│   ├── Method Area (class metadata, static vars) — shared
│   ├── Heap (objects) — shared, GC managed
│   ├── Stack (per thread: frames with local vars, operand stack)
│   ├── PC Register (per thread: current instruction)
│   └── Native Method Stack (per thread: native method calls)
└── Execution Engine
    ├── Interpreter (line by line)
    ├── JIT Compiler (hot code → native)
    └── Garbage Collector
```

### Memory Areas

**Heap** (shared, GC-managed):
- **Young Generation:** Eden + Survivor spaces (S0, S1). New objects created here.
- **Old Generation (Tenured):** Long-lived objects promoted from Young Gen.
- **Metaspace** (Java 8+, replaces PermGen): Class metadata, method data. Uses native memory, auto-grows.

**Stack** (per thread):
- Each method call creates a stack frame
- Contains: local variables, operand stack, return address
- `StackOverflowError` when stack is full (deep recursion)
- Default stack size: ~512KB-1MB

### Garbage Collection [🔥 Must Know]

**How GC works:**
1. **Mark:** Traverse from GC roots (stack variables, static fields, JNI refs), mark all reachable objects
2. **Sweep:** Remove unmarked objects
3. **Compact:** (optional) Move surviving objects together to reduce fragmentation

**GC Roots:** Local variables, static fields, active threads, JNI references.

**Generational hypothesis:** Most objects die young. So GC focuses on Young Gen (minor GC, fast) and occasionally collects Old Gen (major/full GC, slow).

**Minor GC:** Collects Young Gen. Fast (milliseconds). Frequent.
**Major/Full GC:** Collects entire heap. Slow (can be seconds). Infrequent. Causes "stop-the-world" pauses.

### GC Algorithms [🔥 Must Know]

| GC | Type | Pause | Throughput | Use Case |
|----|------|-------|-----------|----------|
| Serial | Single-threaded | Long | Low | Small apps, single CPU |
| Parallel (Throughput) | Multi-threaded | Medium | High | Batch processing |
| G1 (Garbage First) | Region-based, concurrent | Low-medium | Good | **Default since Java 9** |
| ZGC | Concurrent, low-latency | < 10ms | Good | Large heaps, low latency |
| Shenandoah | Concurrent, low-latency | < 10ms | Good | Low latency |

**G1 GC** (default):
- Divides heap into equal-sized regions (~2048)
- Each region can be Eden, Survivor, Old, or Humongous (large objects)
- Collects regions with most garbage first ("Garbage First")
- Concurrent marking, incremental compaction
- Target pause time: `-XX:MaxGCPauseMillis=200` (default)

### JIT Compilation
- Interpreter runs bytecode line by line (slow)
- JIT compiler identifies "hot" methods (called frequently)
- Compiles hot methods to native machine code (fast)
- C1 compiler: quick compilation, moderate optimization
- C2 compiler: slower compilation, aggressive optimization
- Tiered compilation (default): C1 first, then C2 for hottest methods

### Common JVM Flags
```
-Xms512m          # Initial heap size
-Xmx4g            # Maximum heap size
-XX:+UseG1GC      # Use G1 GC
-XX:MaxGCPauseMillis=200  # Target GC pause
-XX:+HeapDumpOnOutOfMemoryError  # Dump heap on OOM
-XX:+PrintGCDetails  # GC logging
```

### Memory Leaks in Java [🔥 Must Know]

Java has GC, but memory leaks still happen when objects are referenced but no longer needed. Here are the most common patterns with code examples:

**1. Static collections that grow indefinitely:**
```java
// LEAK: static map grows forever, never cleared
public class EventCache {
    private static final Map<String, Event> cache = new HashMap<>();
    
    public void addEvent(Event e) {
        cache.put(e.getId(), e); // entries never removed!
    }
}
// Fix: use bounded cache (Guava Cache, Caffeine) with max size and TTL
```

**2. Unclosed resources (streams, connections):**
```java
// LEAK: connection never returned to pool if exception occurs
public User getUser(long id) {
    Connection conn = dataSource.getConnection();
    PreparedStatement stmt = conn.prepareStatement("SELECT * FROM users WHERE id = ?");
    // if exception here → connection leaked!
    ResultSet rs = stmt.executeQuery();
    return mapUser(rs);
}

// Fix: try-with-resources (auto-closes)
public User getUser(long id) {
    try (Connection conn = dataSource.getConnection();
         PreparedStatement stmt = conn.prepareStatement("SELECT * FROM users WHERE id = ?")) {
        stmt.setLong(1, id);
        try (ResultSet rs = stmt.executeQuery()) {
            return mapUser(rs);
        }
    }
}
```

**3. ThreadLocal not cleaned up:**
```java
// LEAK: in a thread pool, threads are reused. ThreadLocal values persist across requests.
private static final ThreadLocal<UserContext> context = new ThreadLocal<>();

public void handleRequest(Request req) {
    context.set(new UserContext(req.getUserId()));
    processRequest(req);
    // MISSING: context.remove() → UserContext stays in thread's map forever
    // In a thread pool with 200 threads, 200 UserContext objects leak
}

// Fix: always remove in finally block
public void handleRequest(Request req) {
    try {
        context.set(new UserContext(req.getUserId()));
        processRequest(req);
    } finally {
        context.remove(); // ALWAYS clean up
    }
}
```

**4. Inner class holding reference to outer class:**
```java
// LEAK: non-static inner class holds implicit reference to outer class
public class DataProcessor {
    private byte[] largeData = new byte[100_000_000]; // 100MB
    
    public Runnable createTask() {
        return new Runnable() { // anonymous inner class holds ref to DataProcessor
            public void run() { /* doesn't use largeData, but still holds ref */ }
        };
    }
}
// Fix: use static inner class or lambda (lambdas don't capture 'this' unless needed)
```

**5. Listeners/callbacks not deregistered:**
```java
// LEAK: listener registered but never removed
eventBus.register(this); // in constructor
// Object can't be GC'd because eventBus holds a reference to it
// Fix: deregister in cleanup/destroy method
```

### Diagnosing Memory Issues

| Tool | What It Does | Command |
|------|-------------|---------|
| `jmap -heap <pid>` | Show heap usage summary | Quick check: is heap full? |
| `jmap -histo <pid>` | Show object count by class | Which class has the most instances? |
| `jmap -dump:format=b,file=heap.hprof <pid>` | Full heap dump | Analyze in VisualVM or Eclipse MAT |
| `jstack <pid>` | Thread dump | Find deadlocks, blocked threads |
| `jstat -gc <pid> 1000` | GC stats every 1 second | Is GC running too frequently? |
| VisualVM | GUI: heap, threads, CPU profiling | Connect to running JVM for live analysis |
| Eclipse MAT | Analyze heap dumps | Find leak suspects, dominator tree |

**Diagnosis workflow:**
```
1. Symptom: OutOfMemoryError or increasing memory usage over time
2. Take heap dump: jmap -dump:format=b,file=heap.hprof <pid>
3. Open in Eclipse MAT → "Leak Suspects" report
4. Check dominator tree: which objects retain the most memory?
5. Find the root cause: static collection? unclosed resource? ThreadLocal?
6. Fix and verify: deploy fix, monitor memory over 24 hours
```

## 5. Must-Know Interview Questions

1. [🔥 Must Know] **Q:** Explain JVM memory areas. **A:** Heap (shared, objects, GC-managed), Stack (per thread, method frames), Metaspace (class metadata). Heap divided into Young Gen (Eden + Survivors) and Old Gen.

2. [🔥 Must Know] **Q:** How does garbage collection work? **A:** Mark reachable objects from GC roots, sweep unreachable, optionally compact. Generational: minor GC (Young Gen, fast, frequent) and major GC (full heap, slow, infrequent).

3. [🔥 Must Know] **Q:** What is G1 GC? **A:** Default GC since Java 9. Divides heap into regions, collects regions with most garbage first. Concurrent marking, targets configurable pause times. Good balance of throughput and latency.

4. [🔥 Must Know] **Q:** What causes OutOfMemoryError? **A:** Heap full (too many objects), Metaspace full (too many classes loaded), stack overflow (deep recursion), native memory exhausted.

5. [🔥 Must Know] **Q:** How can memory leaks happen in Java? **A:** Objects referenced but not needed: static collections, unclosed resources, ThreadLocal not removed, listener not deregistered.

6. **Q:** What is JIT compilation? **A:** JVM interprets bytecode initially, then JIT-compiles frequently executed ("hot") methods to native code for performance. Uses tiered compilation (C1 → C2).

## 7. Revision Checklist
- [ ] Heap: Young Gen (Eden + Survivors) + Old Gen + Metaspace
- [ ] Stack: per thread, method frames, local variables
- [ ] GC: mark (from roots) → sweep → compact
- [ ] Minor GC: Young Gen, fast. Major GC: full heap, slow.
- [ ] G1: region-based, concurrent, default since Java 9
- [ ] ZGC/Shenandoah: < 10ms pauses, large heaps
- [ ] JIT: interpreter → C1 (quick) → C2 (optimized) for hot methods
- [ ] Memory leaks: static collections, unclosed resources, ThreadLocal
- [ ] Key flags: -Xms, -Xmx, -XX:+UseG1GC, -XX:MaxGCPauseMillis
