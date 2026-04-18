# Concurrency & Multithreading

## 1. What & Why

**Concurrency is the ability to handle multiple tasks at the same time — it's essential for utilizing multi-core CPUs, handling I/O without blocking, and building responsive applications. Java has the richest concurrency support of any mainstream language, and it's heavily tested in SDE-2 interviews.**

💡 **Intuition — Concurrency vs Parallelism:** Concurrency is about DEALING with multiple things at once (structure). Parallelism is about DOING multiple things at once (execution). A single-core CPU can be concurrent (time-slicing between threads) but not parallel. A multi-core CPU can be both. Java's concurrency primitives handle both cases.

> 🔗 **See Also:** [05-java/01-core-java.md](01-core-java.md) for Java fundamentals. [05-java/04-jvm-internals-gc.md](04-jvm-internals-gc.md) for thread stack memory. [06-tech-stack/04-spring-boot.md](../06-tech-stack/04-spring-boot.md) for concurrency in Spring Boot applications.

## 2. Core Concepts

### Thread Creation
```java
// 1. Extend Thread
class MyThread extends Thread { public void run() { /* work */ } }

// 2. Implement Runnable (preferred — allows extending other classes)
Runnable task = () -> { /* work */ };
new Thread(task).start();

// 3. Implement Callable (returns result, can throw checked exceptions)
Callable<Integer> callable = () -> { return 42; };
ExecutorService executor = Executors.newFixedThreadPool(4);
Future<Integer> future = executor.submit(callable);
int result = future.get(); // blocks until done
```

### Thread Lifecycle
```
NEW → (start()) → RUNNABLE → (scheduler) → RUNNING → (complete) → TERMINATED
                      ↕ (wait/sleep/block)
                   WAITING / TIMED_WAITING / BLOCKED
```

### synchronized Keyword [🔥 Must Know]
```java
// Method-level: locks on `this` (instance) or Class object (static)
synchronized void increment() { count++; }

// Block-level: locks on specified object (more granular)
synchronized (lockObject) { count++; }
```

**What synchronized does:**
1. Mutual exclusion: only one thread holds the lock
2. Memory visibility: changes made inside synchronized block are visible to other threads that synchronize on the same lock

### volatile Keyword [🔥 Must Know]
- Guarantees visibility: reads/writes go directly to main memory (not CPU cache)
- Does NOT guarantee atomicity: `volatile int count; count++` is NOT thread-safe (read-modify-write)
- Use for: flags (`volatile boolean running = true`), double-checked locking

⚙️ **Under the Hood — Why `volatile count++` is NOT Thread-Safe:**

```
count++ is actually THREE operations:
  1. READ count from memory (value = 5)
  2. INCREMENT in CPU register (value = 6)
  3. WRITE back to memory (count = 6)

Thread A: READ 5 → INCREMENT → (context switch before WRITE)
Thread B: READ 5 → INCREMENT → WRITE 6
Thread A: (resumes) → WRITE 6

Result: count = 6 (should be 7!) — lost update.

volatile ensures each READ/WRITE goes to main memory,
but it can't make the three-step read-modify-write atomic.
Solution: use AtomicInteger.incrementAndGet() (CAS-based, truly atomic).
```

### Java Memory Model (JMM) [🔥 Must Know]
- Each thread has its own CPU cache (working memory)
- Without synchronization, threads may see stale values
- **Happens-before relationship:** If action A happens-before B, then A's effects are visible to B
  - Unlock → Lock on same monitor
  - Write to volatile → Read of same volatile
  - Thread.start() → first action in started thread
  - Last action in thread → Thread.join() return

### Locks (java.util.concurrent.locks)

```java
ReentrantLock lock = new ReentrantLock();
lock.lock();
try {
    // critical section
} finally {
    lock.unlock(); // ALWAYS in finally
}
```

**ReentrantLock vs synchronized:**

| Feature | synchronized | ReentrantLock |
|---------|-------------|---------------|
| Syntax | Keyword | API (lock/unlock) |
| Fairness | No | Optional (fair=true) |
| Try lock | No | `tryLock()` with timeout |
| Interruptible | No | `lockInterruptibly()` |
| Condition variables | `wait()/notify()` | `Condition` objects (multiple) |
| Performance | Similar (Java 6+) | Similar |

### ExecutorService [🔥 Must Know]
```java
// Fixed thread pool — most common
ExecutorService executor = Executors.newFixedThreadPool(Runtime.getRuntime().availableProcessors());

// Submit tasks
Future<String> future = executor.submit(() -> "result");
executor.execute(() -> { /* fire and forget */ });

// Shutdown
executor.shutdown(); // no new tasks, finish existing
executor.awaitTermination(60, TimeUnit.SECONDS);
```

**Thread pool types:**
- `newFixedThreadPool(n)`: Fixed n threads. Best for CPU-bound tasks.
- `newCachedThreadPool()`: Creates threads as needed, reuses idle ones. Best for short-lived I/O tasks.
- `newSingleThreadExecutor()`: Single thread. Guarantees sequential execution.
- `newScheduledThreadPool(n)`: For delayed/periodic tasks.

### CompletableFuture (Java 8+) [🔥 Must Know]
```java
CompletableFuture.supplyAsync(() -> fetchData())
    .thenApply(data -> process(data))
    .thenAccept(result -> save(result))
    .exceptionally(ex -> { log(ex); return null; });

// Combine multiple futures
CompletableFuture.allOf(future1, future2, future3).join();
```

### Common Concurrency Utilities

| Class | Purpose |
|-------|---------|
| `CountDownLatch` | Wait for N events to complete |
| `CyclicBarrier` | N threads wait for each other at a barrier |
| `Semaphore` | Limit concurrent access to a resource |
| `AtomicInteger/Long` | Lock-free atomic operations (CAS) |
| `ConcurrentHashMap` | Thread-safe map |
| `BlockingQueue` | Producer-consumer pattern |
| `ReadWriteLock` | Multiple readers OR one writer |

### Producer-Consumer Pattern [🔥 Must Know]
```java
BlockingQueue<Task> queue = new LinkedBlockingQueue<>(100);

// Producer
executor.submit(() -> {
    while (running) {
        queue.put(produceTask()); // blocks if full
    }
});

// Consumer
executor.submit(() -> {
    while (running) {
        Task task = queue.take(); // blocks if empty
        process(task);
    }
});
```

### Deadlock [🔥 Must Know]

**Two or more threads are blocked forever, each waiting for a lock held by the other.**

💡 **Intuition — The Dining Philosophers:** Five philosophers sit at a round table. Each needs two forks to eat. If every philosopher picks up the left fork simultaneously, they all wait for the right fork forever — deadlock.

**Four conditions (ALL must hold for deadlock):**
1. **Mutual exclusion:** Resource can only be held by one thread
2. **Hold and wait:** Thread holds one resource while waiting for another
3. **No preemption:** Resources can't be forcibly taken from a thread
4. **Circular wait:** Thread A waits for B, B waits for C, C waits for A

```java
// DEADLOCK example:
Thread 1: lock(A) → lock(B)  // holds A, waits for B
Thread 2: lock(B) → lock(A)  // holds B, waits for A → DEADLOCK!

// FIX: always acquire locks in the same order
Thread 1: lock(A) → lock(B)
Thread 2: lock(A) → lock(B)  // same order → no circular wait
```

**Prevention:** Always acquire locks in the same order. Use `tryLock()` with timeout. Avoid nested locks. Use higher-level concurrency utilities (ExecutorService, BlockingQueue) instead of raw locks.

### Thread Safety Strategies
1. **Immutability:** Immutable objects are inherently thread-safe
2. **Synchronization:** `synchronized`, `Lock`
3. **Atomic variables:** `AtomicInteger`, `AtomicReference`
4. **Thread-local:** `ThreadLocal<T>` — each thread has its own copy
5. **Concurrent collections:** `ConcurrentHashMap`, `CopyOnWriteArrayList`

## 5. Must-Know Interview Questions

1. [🔥 Must Know] **Q:** What is the difference between `synchronized` and `volatile`? **A:** `synchronized` provides mutual exclusion AND visibility. `volatile` provides only visibility (no atomicity). Use volatile for simple flags, synchronized for compound operations.

2. [🔥 Must Know] **Q:** What is a deadlock? How do you prevent it? **A:** Two threads each holding a lock the other needs. Prevent by: consistent lock ordering, tryLock with timeout, avoiding nested locks.

3. [🔥 Must Know] **Q:** Explain the Java Memory Model. **A:** Each thread has a local cache. Without synchronization, threads may see stale values. The JMM defines happens-before relationships that guarantee visibility.

4. [🔥 Must Know] **Q:** What is CompletableFuture? **A:** Asynchronous computation that can be chained (thenApply, thenCompose), combined (allOf, anyOf), and handle errors (exceptionally). Replaces callback hell.

### CompletableFuture Patterns [🔥 Must Know]

```java
// Basic chain: supplyAsync → thenApply → thenAccept
CompletableFuture.supplyAsync(() -> fetchUser(userId))     // runs in ForkJoinPool
    .thenApply(user -> enrichWithOrders(user))              // transform result
    .thenAccept(user -> sendEmail(user))                    // consume result (void)
    .exceptionally(ex -> { log.error("Failed", ex); return null; }); // handle errors

// thenApply vs thenCompose:
// thenApply: transform value (like map). Function returns T.
// thenCompose: chain async operations (like flatMap). Function returns CompletableFuture<T>.

// thenApply (synchronous transformation):
CompletableFuture<String> name = getUserAsync(id).thenApply(user -> user.getName());

// thenCompose (chain another async call):
CompletableFuture<List<Order>> orders = getUserAsync(id)
    .thenCompose(user -> getOrdersAsync(user.getId())); // returns CF, not CF<CF>

// Combine two independent futures:
CompletableFuture<User> userFuture = getUserAsync(id);
CompletableFuture<List<Order>> ordersFuture = getOrdersAsync(id);

CompletableFuture<UserProfile> profile = userFuture.thenCombine(ordersFuture,
    (user, orders) -> new UserProfile(user, orders)); // runs when BOTH complete

// Wait for ALL futures:
CompletableFuture<Void> all = CompletableFuture.allOf(future1, future2, future3);
all.thenRun(() -> log.info("All tasks complete"));

// Wait for ANY (first to complete):
CompletableFuture<Object> any = CompletableFuture.anyOf(future1, future2, future3);

// Timeout (Java 9+):
getUserAsync(id)
    .orTimeout(2, TimeUnit.SECONDS)           // throws TimeoutException after 2s
    .completeOnTimeout(defaultUser, 2, TimeUnit.SECONDS); // return default after 2s

// Error handling:
CompletableFuture.supplyAsync(() -> riskyOperation())
    .exceptionally(ex -> fallbackValue)        // recover from exception
    .handle((result, ex) -> {                  // handle both success and failure
        if (ex != null) return fallbackValue;
        return transform(result);
    });
```

**CompletableFuture cheat sheet:**

| Method | Input → Output | Analogy | Use When |
|--------|---------------|---------|----------|
| `thenApply` | T → U | map | Synchronous transformation |
| `thenCompose` | T → CF\<U\> | flatMap | Chain another async call |
| `thenCombine` | (T, U) → V | zip | Combine two independent results |
| `thenAccept` | T → void | forEach | Consume result, no return |
| `allOf` | CF\<?\>... → CF\<Void\> | Promise.all | Wait for all to complete |
| `anyOf` | CF\<?\>... → CF\<Object\> | Promise.race | First to complete wins |
| `exceptionally` | Throwable → T | catch | Recover from exception |
| `handle` | (T, Throwable) → U | try-catch-finally | Handle both success and failure |

### Practice Exercise: Thread-Safe Bounded Blocking Queue

```java
// Implement a blocking queue that blocks on put() when full and take() when empty
public class BoundedBlockingQueue<T> {
    private final Queue<T> queue = new LinkedList<>();
    private final int capacity;
    private final ReentrantLock lock = new ReentrantLock();
    private final Condition notFull = lock.newCondition();
    private final Condition notEmpty = lock.newCondition();

    public BoundedBlockingQueue(int capacity) { this.capacity = capacity; }

    public void put(T item) throws InterruptedException {
        lock.lock();
        try {
            while (queue.size() == capacity) notFull.await(); // block until space available
            queue.offer(item);
            notEmpty.signal(); // wake up a waiting consumer
        } finally { lock.unlock(); }
    }

    public T take() throws InterruptedException {
        lock.lock();
        try {
            while (queue.isEmpty()) notEmpty.await(); // block until item available
            T item = queue.poll();
            notFull.signal(); // wake up a waiting producer
            return item;
        } finally { lock.unlock(); }
    }
}
```

5. [🔥 Must Know] **Q:** Thread pool types and when to use each? **A:** Fixed: CPU-bound (cores count). Cached: short I/O tasks. Single: sequential processing. Scheduled: periodic tasks.

## 7. Revision Checklist
- [ ] synchronized: mutual exclusion + visibility, locks on object/class
- [ ] volatile: visibility only, no atomicity, use for flags
- [ ] JMM: happens-before, thread-local cache, need synchronization for visibility
- [ ] ReentrantLock: tryLock, fairness, interruptible, multiple conditions
- [ ] ExecutorService: fixed (CPU), cached (I/O), single, scheduled
- [ ] CompletableFuture: supplyAsync → thenApply → thenAccept → exceptionally
- [ ] Deadlock: 4 conditions, prevent with consistent lock ordering
- [ ] Producer-consumer: BlockingQueue (put blocks if full, take blocks if empty)
- [ ] Atomic: CAS-based, lock-free (AtomicInteger, AtomicReference)
