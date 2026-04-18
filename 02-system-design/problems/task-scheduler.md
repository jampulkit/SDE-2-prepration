# Design: Distributed Task Scheduler

## 1. Problem Statement & Scope

**Design a distributed task scheduler (like cron at scale) that reliably executes millions of scheduled and recurring tasks across a cluster of workers — with at-least-once execution, priority support, and retry on failure.**

**Clarifying questions to ask:**
- One-time or recurring tasks? → Both
- How many tasks? → 100M scheduled tasks, 10M executions/day
- Latency tolerance? → Execute within 5 seconds of scheduled time
- Task duration? → Seconds to minutes (not long-running batch jobs)
- Priorities? → Yes, high/medium/low

💡 **Why this is asked at Amazon:** Amazon runs millions of scheduled tasks internally (order timeouts, payment retries, SLA checks, report generation). This tests: distributed coordination, at-least-once execution, priority queues, and failure handling.

## 2. Requirements

**Functional:**
- Schedule one-time tasks (execute at specific time)
- Schedule recurring tasks (cron expression: every hour, daily at 9 AM)
- Cancel/update scheduled tasks
- Priority levels (high tasks execute before low)
- Task execution status tracking (PENDING, RUNNING, SUCCESS, FAILED)
- Retry failed tasks with exponential backoff

**Non-functional:**
- At-least-once execution (no missed tasks, duplicates handled by idempotency)
- Execute within 5 seconds of scheduled time
- 99.99% availability
- Horizontally scalable (add workers to handle more tasks)
- No single point of failure

**Estimation:**
```
100M scheduled tasks in the system
10M executions/day → ~115 tasks/sec average, ~500/sec peak
Task metadata: ~500 bytes each → 100M × 500B = 50 GB (fits in one DB)
```

## 3. High-Level Design

```
┌──────────┐    ┌───────────────┐    ┌──────────────┐    ┌──────────────┐
│ Client   │───→│ Task API      │───→│ Task Store   │    │ Workers      │
│ (create, │    │ (CRUD tasks)  │    │ (PostgreSQL) │    │ (execute     │
│  cancel) │    └───────────────┘    └──────┬───────┘    │  tasks)      │
└──────────┘                                │            └──────┬───────┘
                                    ┌───────┴───────┐          │
                                    │ Scheduler     │          │
                                    │ (poll due     │──Kafka──→│
                                    │  tasks, enq)  │          │
                                    └───────────────┘          │
                                                        ┌──────┴───────┐
                                                        │ DLQ          │
                                                        │ (failed      │
                                                        │  after retry)│
                                                        └──────────────┘
```

**API:**
```
POST /api/v1/tasks
  Body: { "type": "SEND_EMAIL", "payload": {...}, "scheduled_at": "2024-03-15T09:00:00Z",
          "cron": "0 9 * * *", "priority": "HIGH", "max_retries": 3 }
  Response: { "task_id": "uuid", "status": "SCHEDULED" }

DELETE /api/v1/tasks/{task_id}
GET /api/v1/tasks/{task_id}
```

**Data Model:**
```sql
tasks (
    task_id         UUID PRIMARY KEY,
    type            VARCHAR(50) NOT NULL,      -- SEND_EMAIL, PAYMENT_RETRY, etc.
    payload         JSONB NOT NULL,            -- task-specific data
    status          VARCHAR(20) NOT NULL,      -- SCHEDULED, QUEUED, RUNNING, SUCCESS, FAILED
    priority        INT DEFAULT 5,             -- 1=highest, 10=lowest
    scheduled_at    TIMESTAMP NOT NULL,        -- next execution time
    cron_expr       VARCHAR(100),              -- NULL for one-time tasks
    max_retries     INT DEFAULT 3,
    retry_count     INT DEFAULT 0,
    locked_by       VARCHAR(100),              -- which scheduler instance owns it
    locked_at       TIMESTAMP,                 -- when it was locked
    created_at      TIMESTAMP NOT NULL,
    updated_at      TIMESTAMP NOT NULL
)
-- Index: (status, scheduled_at) for polling due tasks
-- Index: (status, priority, scheduled_at) for priority-based polling
```

## 4. Deep Dive

### Scheduler: Polling Due Tasks [🔥 Must Know]

```sql
-- Atomic poll: find due tasks and lock them in one query
UPDATE tasks
SET status = 'QUEUED', locked_by = 'scheduler-1', locked_at = NOW()
WHERE task_id IN (
    SELECT task_id FROM tasks
    WHERE status = 'SCHEDULED' AND scheduled_at <= NOW()
    ORDER BY priority ASC, scheduled_at ASC
    LIMIT 100
    FOR UPDATE SKIP LOCKED    -- skip tasks locked by other scheduler instances
)
RETURNING *;
```

**Why `SKIP LOCKED`:** Multiple scheduler instances poll concurrently. Without `SKIP LOCKED`, they'd block each other. With it, each instance grabs a different batch — no contention.

**Polling interval:** Every 1-2 seconds. Trade-off: shorter = lower latency, higher DB load.

### Worker Execution Flow

```
1. Worker consumes task from Kafka (priority topic)
2. Update status: QUEUED → RUNNING
3. Execute task (call the appropriate handler based on task.type)
4. On success:
   - Update status: RUNNING → SUCCESS
   - If recurring (cron_expr != null): compute next_scheduled_at, insert new task
5. On failure:
   - If retry_count < max_retries:
     Update status: RUNNING → SCHEDULED
     Set scheduled_at = NOW() + backoff(retry_count)  -- exponential backoff
     Increment retry_count
   - Else: RUNNING → FAILED, move to DLQ
6. Commit Kafka offset
```

### Preventing Duplicate Execution [🔥 Must Know]

```
Problem: scheduler polls task, enqueues to Kafka, crashes before marking as QUEUED.
  On restart: polls same task again → duplicate execution.

Solutions:
1. Lock with timeout: locked_at + 5 min = lock expiry. If scheduler crashes,
   lock expires, another scheduler picks it up. Task handler must be IDEMPOTENT.

2. Kafka transactional producer: atomically write to Kafka + update DB status.
   If either fails, both roll back.

3. Idempotency key: each task execution has a unique key (task_id + attempt_number).
   Worker checks before executing. If already processed, skip.
```

### Priority Queues

```
Option 1: Separate Kafka topics per priority
  kafka-tasks-high, kafka-tasks-medium, kafka-tasks-low
  Workers consume from high first, then medium, then low.

Option 2: Single topic, workers sort locally
  Less isolation but simpler. High-priority tasks may wait behind low-priority.

Option 1 is better — guarantees high-priority tasks are processed first.
```

### Recurring Tasks (Cron)

```
On task SUCCESS (if cron_expr is set):
  1. Parse cron expression: "0 9 * * *" → next run = tomorrow 9:00 AM
  2. Insert new task: same type/payload, scheduled_at = next run time
  3. Original task stays as SUCCESS (audit trail)

Cron parsing library: quartz CronExpression (Java), or store pre-computed next_run.
```

### Scaling

```
Bottleneck: DB polling at high scale (100K tasks/sec due)

Solutions:
1. Partition by time: separate tables for each hour/day. Poll only current partition.
2. Redis sorted set as scheduling layer:
   ZADD scheduled_tasks <timestamp> <task_id>
   ZRANGEBYSCORE scheduled_tasks 0 <now> LIMIT 100
   Much faster than DB polling. DB is source of truth, Redis is scheduling index.
3. Multiple scheduler instances with SKIP LOCKED (horizontal scaling).
```

## 5. Interviewer Deep-Dive Questions

1. **"What if a worker crashes mid-execution?"**
   → Task stays in RUNNING. Heartbeat mechanism: worker sends heartbeat every 30s. If no heartbeat for 2 min, scheduler marks task as SCHEDULED (retry). Alternatively: lock timeout — if RUNNING for > task_timeout, reset to SCHEDULED.

2. **"How do you handle clock skew across scheduler instances?"**
   → Use DB server time (`NOW()`) for all scheduling decisions, not local clock. All schedulers query the same DB, so they see the same time.

3. **"Task takes 10 minutes but timeout is 5 minutes. What happens?"**
   → Task is marked as failed (timeout). Worker may still be running it. Solution: worker checks if task is still RUNNING before committing result. If status changed (reset by scheduler), discard result. Use a lease/version to detect stale executions.

4. **"How do you handle 1M tasks all scheduled for the same second (midnight cron)?"**
   → Stagger: add random jitter (0-60s) to scheduled_at for recurring tasks. Priority queue: process high-priority first. Scale workers horizontally. Kafka absorbs the burst.

5. **"How is this different from a message queue with delayed delivery?"**
   → Task scheduler: persistent, queryable (cancel/update), recurring, priority. Message queue delay: fire-and-forget, no cancel, no recurring. SQS delay = max 15 min. Task scheduler = arbitrary future time.

## 6. Failure Matrix

| Component Down | Impact | Mitigation |
|---|---|---|
| PostgreSQL | Can't poll or update tasks | DB replicas. Tasks in Kafka still execute. New scheduling paused. |
| Kafka | Can't enqueue tasks to workers | Scheduler retries enqueue. Tasks stay QUEUED in DB. |
| Scheduler instance | Some tasks not polled on time | Multiple instances with SKIP LOCKED. Others pick up the slack. |
| Worker | Tasks not executed | Kafka rebalances partitions to other workers. Lock timeout resets stuck tasks. |

## 7. Revision Checklist

- [ ] Poll with `FOR UPDATE SKIP LOCKED` for concurrent schedulers
- [ ] At-least-once: lock timeout + idempotent task handlers
- [ ] Priority: separate Kafka topics per priority level
- [ ] Recurring: parse cron, insert next task on success
- [ ] Retry: exponential backoff, DLQ after max_retries
- [ ] Scale: Redis sorted set as scheduling index, multiple scheduler instances
- [ ] Estimation: 115 tasks/sec, 50 GB metadata, fits single DB
