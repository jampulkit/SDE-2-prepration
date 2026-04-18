# Mock Interview Practice — System Design

## How to Use

Set a 45-minute timer. Use a whiteboard or blank paper. Talk out loud. Follow the 5-phase framework. After each session, compare your design against the corresponding problem doc.

---

## Session 1: URL Shortener (45 min)

**Timer checkpoints:**
- 0:00-5:00 — Requirements and estimation
- 5:00-10:00 — Back-of-envelope math (QPS, storage, cache size)
- 10:00-20:00 — High-level design (API, data model, architecture diagram)
- 20:00-40:00 — Deep dive (key generation, caching, analytics pipeline)
- 40:00-45:00 — Monitoring, failure handling, extensions

**What the interviewer evaluates at each phase:**
- Requirements: can you scope the problem and ask the right questions?
- Estimation: can you reason about scale with numbers?
- High-level: can you design a working system?
- Deep dive: can you handle complexity and articulate trade-offs?
- Wrap-up: do you think about production concerns?

**After completing:** Compare with [02-system-design/problems/url-shortener.md](../02-system-design/problems/url-shortener.md)

---

## Session 2: Chat System (45 min)

**Focus areas:** WebSocket vs polling, message storage (Cassandra), presence tracking, group chat fan-out, offline message delivery.

**After completing:** Compare with [02-system-design/problems/chat-system.md](../02-system-design/problems/chat-system.md)

---

## Session 3: E-Commerce System (45 min)

**Focus areas:** Product catalog caching, checkout saga, inventory management (prevent overselling), flash sale handling, payment idempotency.

**After completing:** Compare with [02-system-design/problems/e-commerce-system.md](../02-system-design/problems/e-commerce-system.md)

---

## Self-Evaluation Rubric

| Criteria | Strong | Weak |
|----------|--------|------|
| Requirements | Asked 5+ clarifying questions, defined scope | Jumped straight to design |
| Estimation | Calculated QPS, storage, cache with math | Skipped or hand-waved numbers |
| High-level | Clear diagram, API, data model | Missing components, no diagram |
| Deep dive | Discussed 2-3 trade-offs with reasoning | Surface-level, no trade-offs |
| Wrap-up | Mentioned monitoring, failure modes | Forgot production concerns |
| Communication | Drove the conversation, checked in with "interviewer" | Silent coding, no explanation |
