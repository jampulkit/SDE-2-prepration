# Operating Systems

## 1. What & Why

**OS manages hardware resources and provides abstractions (processes, threads, memory, files) for applications. Interview questions test understanding of concurrency, memory management, and scheduling, concepts that directly affect how your Java applications perform.**

💡 **Why OS matters for a Java backend engineer:** When your Spring Boot service is slow, it might be because of context switching (too many threads), page faults (not enough memory), or I/O blocking (synchronous calls). Understanding OS concepts helps you diagnose and fix these issues.

> 🔗 **See Also:** [05-java/03-concurrency-multithreading.md](../05-java/03-concurrency-multithreading.md) for Java's threading model built on OS threads. [05-java/04-jvm-internals-gc.md](../05-java/04-jvm-internals-gc.md) for JVM memory management (built on OS virtual memory).

## 2. Core Concepts

### Process vs Thread [🔥 Must Know]

| Feature | Process | Thread |
|---------|---------|--------|
| Memory | Own address space | Shared address space |
| Creation | Heavy (fork, copy page tables) | Light (share parent's address space) |
| Communication | IPC (pipes, sockets, shared memory) | Shared memory (direct, need synchronization) |
| Crash impact | Isolated (one process crash doesn't affect others) | Can crash entire process |
| Context switch | Expensive (TLB flush, page table swap) | Cheaper (same address space, no TLB flush) |
| Use case | Isolation (browser tabs, microservices) | Parallelism within one app (web server threads) |

⚙️ **Under the Hood, Context Switch Cost:**

```
Process context switch:
  1. Save CPU registers (program counter, stack pointer, general registers)
  2. Save process state (open files, signal handlers)
  3. Flush TLB (Translation Lookaside Buffer) — EXPENSIVE
  4. Switch page tables (new virtual address space)
  5. Load new process state + registers
  Cost: ~1-10 microseconds. TLB flush causes cache misses on resume.

Thread context switch (same process):
  1. Save CPU registers
  2. Switch stack pointer
  3. NO TLB flush (same address space)
  4. NO page table switch
  Cost: ~0.1-1 microseconds. Much cheaper.

Java implication: 1000 threads in a JVM = 1000 OS threads.
  Too many threads → excessive context switching → CPU spends more time switching than working.
  Rule of thumb: thread pool size = number of CPU cores (for CPU-bound work)
                                  = cores * (1 + wait_time/compute_time) (for I/O-bound work)
```

### Process States

```
NEW → READY → (scheduled by CPU) → RUNNING → (complete) → TERMINATED
                    ↕ (I/O wait / sleep / lock)
                 WAITING/BLOCKED

RUNNING → READY: preempted (time slice expired, higher priority process arrived)
RUNNING → WAITING: process requests I/O or waits for lock
WAITING → READY: I/O complete or lock acquired
```

### CPU Scheduling [🔥 Must Know]

| Algorithm | Type | How It Works | Pros | Cons |
|-----------|------|-------------|------|------|
| FCFS | Non-preemptive | First come, first served | Simple | Convoy effect (short jobs wait behind long) |
| SJF | Non-preemptive | Shortest job runs first | Optimal average wait time | Starvation of long jobs, need to predict job length |
| Round Robin | Preemptive | Each process gets a time quantum (10-100ms) | Fair, no starvation | Context switch overhead, poor for I/O-bound |
| Priority | Preemptive | Highest priority runs first | Important tasks first | Starvation (solve with aging) |
| Multilevel Feedback Queue | Preemptive | Multiple queues with different priorities and time quanta | Adaptive, good for mixed workloads | Complex to tune |

⚙️ **Under the Hood, Round Robin with Gantt Chart:**

```
Processes: P1(burst=10), P2(burst=4), P3(burst=7)
Time quantum: 4ms

Timeline:
  |--P1--|--P2--|--P3--|--P1--|--P3--|--P1--|
  0      4      8     12     16     19     21

P1: runs 4ms, preempted (6ms remaining)
P2: runs 4ms, completes
P3: runs 4ms, preempted (3ms remaining)
P1: runs 4ms, preempted (2ms remaining)
P3: runs 3ms, completes
P1: runs 2ms, completes

Completion times: P2=8, P3=19, P1=21
Average turnaround: (21+8+19)/3 = 16ms
Average wait: (11+4+12)/3 = 9ms
```

**Linux uses CFS (Completely Fair Scheduler):** assigns each process a "virtual runtime." The process with the lowest virtual runtime runs next. Uses a red-black tree for O(log n) scheduling decisions.

### Memory Management [🔥 Must Know]

**Virtual Memory:** Each process has its own virtual address space (0 to 2⁶⁴ in 64-bit systems). The MMU (Memory Management Unit) translates virtual addresses to physical addresses using page tables.

💡 **Intuition:** Virtual memory is like giving every process its own private apartment building with numbered rooms. Two processes can both have "room 100" but they map to different physical locations. The OS is the building manager that maintains the mapping.

**Paging:** Memory divided into fixed-size pages (typically 4KB). Page table maps virtual page number → physical frame number. TLB (Translation Lookaside Buffer) caches recent translations for speed.

```
Virtual address: [Page Number | Offset]
  Page Number → look up in page table → Physical Frame Number
  Physical address = Frame Number * Page Size + Offset

Example (4KB pages):
  Virtual address: 0x12345
  Page number: 0x12 (18), Offset: 0x345 (837)
  Page table[18] = Frame 42
  Physical address: 42 * 4096 + 837 = 172869

TLB: cache of recent page table entries
  TLB hit: 1 ns (fast, no memory access for translation)
  TLB miss: 10-100 ns (must walk page table in memory)
  TLB flush on process switch: why process context switches are expensive
```

**Page Replacement Algorithms:**

| Algorithm | How | Pros | Cons |
|-----------|-----|------|------|
| **LRU** | Evict least recently used page | Good approximation of optimal | Expensive to implement exactly (need timestamp per access) |
| **Clock (Second Chance)** | Circular list with reference bit. Skip pages with bit=1 (clear it). Evict first page with bit=0. | Approximates LRU cheaply | Not as accurate as true LRU |
| **FIFO** | Evict oldest page | Simple | Belady's anomaly (more frames can cause more faults) |
| **Optimal** | Evict page not used for longest time in future | Provably optimal | Impossible (requires future knowledge). Benchmark only. |

⚙️ **Under the Hood, LRU Page Replacement Example:**

```
Page references: 7, 0, 1, 2, 0, 3, 0, 4
Frames: 3

Step 1: [7, _, _] → page fault (load 7)
Step 2: [7, 0, _] → page fault (load 0)
Step 3: [7, 0, 1] → page fault (load 1)
Step 4: [2, 0, 1] → page fault (evict 7, LRU. Load 2)
Step 5: [2, 0, 1] → hit (0 is in memory)
Step 6: [2, 0, 3] → page fault (evict 1, LRU. Load 3)
Step 7: [2, 0, 3] → hit (0 is in memory)
Step 8: [4, 0, 3] → page fault (evict 2, LRU. Load 4)

Total page faults: 6
```

**Thrashing:** When a process doesn't have enough frames, it page-faults constantly. The OS spends more time swapping pages than executing instructions. CPU utilization drops. Solution: reduce degree of multiprogramming (run fewer processes) or add more RAM.

### Deadlock [🔥 Must Know]

**Four necessary conditions (ALL must hold):**
1. **Mutual exclusion:** resource can only be held by one process
2. **Hold and wait:** process holds resources while waiting for others
3. **No preemption:** resources can't be forcibly taken away
4. **Circular wait:** P1 waits for P2, P2 waits for P1

**Prevention (break any one condition):**

| Condition | How to Break | Trade-off |
|-----------|-------------|-----------|
| Hold and wait | Request all resources at once | Low resource utilization |
| No preemption | Allow OS to preempt resources | Complex, may cause inconsistency |
| Circular wait | Impose ordering on lock acquisition | Requires global ordering discipline |

**Circular wait prevention is most practical:** always acquire locks in the same order. If Lock A < Lock B, always acquire A before B. No cycle possible.

```java
// DEADLOCK-PRONE:
Thread 1: lock(A) → lock(B)
Thread 2: lock(B) → lock(A)  // opposite order → circular wait possible

// SAFE:
Thread 1: lock(A) → lock(B)  // always A before B
Thread 2: lock(A) → lock(B)  // same order → no circular wait
```

### Synchronization Primitives

**Producer-Consumer Problem (Bounded Buffer)** [🔥 Must Know]:

```java
// Semaphore-based solution
Semaphore empty = new Semaphore(BUFFER_SIZE); // tracks empty slots
Semaphore full = new Semaphore(0);            // tracks filled slots
Semaphore mutex = new Semaphore(1);           // mutual exclusion

// Producer
void produce(Item item) {
    empty.acquire();    // wait for empty slot
    mutex.acquire();    // enter critical section
    buffer.add(item);
    mutex.release();    // exit critical section
    full.release();     // signal: one more filled slot
}

// Consumer
Item consume() {
    full.acquire();     // wait for filled slot
    mutex.acquire();    // enter critical section
    Item item = buffer.remove();
    mutex.release();    // exit critical section
    empty.release();    // signal: one more empty slot
    return item;
}
```

**Reader-Writer Problem:**

```
Multiple readers can read simultaneously (no conflict).
Writers need exclusive access (no other readers or writers).

Solution: ReadWriteLock
  reader.lock()   → allows concurrent readers, blocks if writer active
  writer.lock()   → exclusive access, blocks all readers and other writers

Java: ReentrantReadWriteLock
  - Read lock: shared (multiple threads can hold simultaneously)
  - Write lock: exclusive (only one thread, no readers allowed)
```

### Inter-Process Communication (IPC)

| Mechanism | Speed | Direction | Use Case |
|-----------|-------|-----------|----------|
| **Pipe** | Medium | Unidirectional | Parent-child communication |
| **Named Pipe (FIFO)** | Medium | Unidirectional | Unrelated processes |
| **Message Queue** | Medium | Bidirectional | Structured messages between processes |
| **Shared Memory** | Fastest | Bidirectional | High-throughput data sharing (needs synchronization) |
| **Socket** | Varies | Bidirectional | Network communication (also local via Unix sockets) |
| **Signal** | Fast | Unidirectional | Notifications (SIGTERM, SIGKILL) |

### File Systems

- **Inode:** Metadata (permissions, size, timestamps, block pointers). Filename stored in directory entry, not inode.
- **Journaling:** Write changes to a journal before applying. Prevents corruption on crash. (ext4, NTFS)
- **Copy-on-Write (COW):** Don't modify data in place. Write new copy, update pointer. Used by ZFS, Btrfs.

### Linux Debugging Commands [🔥 Must Know]

| Command | What It Does | When to Use |
|---------|-------------|-------------|
| `top` / `htop` | CPU, memory usage per process | "Which process is eating CPU?" |
| `ps aux` | List all processes | "Is my service running?" |
| `free -h` | Memory usage (total, used, free, cached) | "Is the system out of memory?" |
| `df -h` | Disk usage per filesystem | "Is the disk full?" |
| `netstat -tlnp` / `ss -tlnp` | Open ports and listening services | "Is my service listening on port 8080?" |
| `strace -p <pid>` | System calls made by a process | "Why is my process stuck?" (often: blocked on I/O) |
| `lsof -p <pid>` | Open files/sockets by a process | "What files/connections does my service have open?" |
| `jstack <pid>` | Java thread dump | "Where are my Java threads stuck?" (deadlock detection) |
| `jmap -heap <pid>` | Java heap usage | "How much heap is my JVM using?" |
| `dmesg` | Kernel messages | "Was my process OOM-killed?" |
| `vmstat 1` | Virtual memory stats every 1 second | "Is the system swapping?" (si/so columns) |
| `iostat -x 1` | Disk I/O stats | "Is disk I/O the bottleneck?" |

## 3. Must-Know Interview Questions

1. [🔥 Must Know] **Q:** Process vs Thread? **A:** Process has own memory space, threads share memory within a process. Threads are lighter, faster to create, but a crash in one thread can affect all threads in the process.
2. [🔥 Must Know] **Q:** What is virtual memory? **A:** Abstraction that gives each process its own address space. Uses paging to map virtual addresses to physical memory. Allows running programs larger than physical RAM.
3. [🔥 Must Know] **Q:** What is a deadlock? **A:** Two or more processes waiting for each other's resources. Four conditions must hold. Prevent by breaking any condition (usually: consistent lock ordering).
4. [🔥 Must Know] **Q:** What is a context switch? **A:** Saving state of current process/thread and loading state of next one. Involves saving registers, program counter, stack pointer. Expensive for processes (TLB flush), cheaper for threads (same address space).
5. [🔥 Must Know] **Q:** Explain paging and page faults. **A:** Memory divided into pages (4KB). Page table maps virtual → physical. Page fault: requested page not in RAM → OS loads from disk. Too many page faults = thrashing.
6. [🔥 Must Know] **Q:** What is the difference between mutex and semaphore? **A:** Mutex: binary lock, only the owner can unlock. Semaphore: counter, any thread can signal. Mutex for mutual exclusion. Semaphore for signaling (producer-consumer) or limiting concurrency.
7. **Q:** What is a zombie process? **A:** A process that has finished execution but its parent hasn't called wait() to read its exit status. It occupies a PID but no resources. Fix: parent calls wait(), or use SIGCHLD handler.
8. **Q:** What is the difference between fork() and exec()? **A:** fork() creates a copy of the current process (child). exec() replaces the current process image with a new program. Typical pattern: fork() then exec() in the child to run a new program.

## 4. Revision Checklist

- [ ] Process: own memory, heavy context switch (TLB flush). Thread: shared memory, light switch.
- [ ] Virtual memory: page table maps virtual → physical. TLB caches translations. Page fault loads from disk.
- [ ] Scheduling: RR (fair, time quantum), SJF (optimal avg wait), Priority (important first, aging prevents starvation)
- [ ] Linux CFS: red-black tree, lowest virtual runtime runs next
- [ ] Page replacement: LRU (best practical), Clock (approximates LRU), FIFO (simple, Belady's anomaly)
- [ ] Thrashing: too many page faults, CPU utilization drops. Fix: fewer processes or more RAM.
- [ ] Deadlock: 4 conditions (mutual exclusion, hold-and-wait, no preemption, circular wait). Prevent by ordering locks.
- [ ] Producer-consumer: semaphores (empty, full, mutex). Reader-writer: ReadWriteLock.
- [ ] IPC: pipes (unidirectional), shared memory (fastest, needs sync), sockets (network)
- [ ] Linux debugging: top (CPU), free (memory), jstack (Java threads), strace (system calls), netstat (ports)

> 🔗 **See Also:** [05-java/03-concurrency-multithreading.md](../05-java/03-concurrency-multithreading.md) for Java's threading model. [05-java/04-jvm-internals-gc.md](../05-java/04-jvm-internals-gc.md) for JVM memory management.
