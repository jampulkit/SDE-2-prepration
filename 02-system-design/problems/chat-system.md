# Design: Chat System

## 1. Problem Statement & Scope

**Design a real-time chat system like WhatsApp, Slack, or Facebook Messenger that supports 1:1 messaging, group chats, online presence, and message history.**

**Clarifying questions to ask:**
- 1:1 and group chat? → Both. Max group size: 500.
- Message types? → Text initially, images/files as extension
- Online status and read receipts? → Yes
- Message history? → Persistent, searchable
- End-to-end encryption? → Out of scope for initial design
- How many concurrent users? → ~10M online at any time

💡 **Why this is a great interview problem:** It tests real-time communication (WebSocket), write-heavy database design (Cassandra), presence tracking (Redis), message ordering, and the fan-out problem for group chats. Every component has meaningful trade-offs.

## 2. Requirements

**Functional:**
- Send/receive messages in real-time (1:1 and group)
- Group chat (create, add/remove members, up to 500 members)
- Online/offline status (presence)
- Read receipts (delivered, read)
- Message history (persistent, paginated)
- Push notifications for offline users (APNs, FCM)

**Non-functional:**
- < 100ms message delivery (sender to receiver) for online users
- 99.99% availability (chat must always work)
- Message ordering per conversation (messages appear in sent order)
- At-least-once delivery (no lost messages, duplicates handled by client)
- Eventual consistency for presence (a few seconds delay is OK)

**Estimation:**
```
50M DAU, 40 messages/user/day = 2B messages/day
Write QPS: 2B / 86,400 ≈ 24,000 QPS. Peak: ~60,000 QPS.
  → Very write-heavy! Need Cassandra or sharded DB.

Message size: ~200 bytes (text + metadata)
Storage/day: 2B × 200 bytes = 400 GB/day
Storage/year: 400 GB × 365 = 146 TB/year
Storage/5 years: ~730 TB → need sharding + tiered storage

Concurrent WebSocket connections: ~10M (20% of DAU online at peak)
Memory per connection: ~10 KB
Total connection memory: 10M × 10 KB = 100 GB → ~100 servers (1GB each for connections)

Bandwidth: 60,000 QPS × 200 bytes = 12 MB/s (manageable)
```

## 3. High-Level Design

**API:**
- **WebSocket:** Real-time messaging (send, receive, typing indicators, presence)
- **REST:** User management, group management, message history, file upload

```
WebSocket events:
  Client → Server: { "type": "send_message", "conversation_id": "...", "content": "Hello!" }
  Server → Client: { "type": "new_message", "conversation_id": "...", "sender": "...", "content": "Hello!" }
  Server → Client: { "type": "presence_update", "user_id": "...", "status": "online" }
  Server → Client: { "type": "read_receipt", "conversation_id": "...", "reader": "...", "last_read": "msg_id" }

REST endpoints:
  GET /api/v1/conversations/{id}/messages?cursor=...&limit=50  (message history)
  POST /api/v1/conversations  (create group)
  POST /api/v1/conversations/{id}/members  (add member)
```

**Architecture:**
```
┌────────┐  WebSocket  ┌──────────────┐     ┌─────────┐
│ Client │◄───────────►│ Chat Server  │────►│  Kafka  │
└────────┘             │ (stateful -  │     │(message │
                       │  holds WS    │     │ routing)│
                       │  connections)│     └────┬────┘
                       └──────┬───────┘          │
                              │            ┌─────┴──────┐
                       ┌──────┴───────┐    │ Chat Server│──► Client B
                       │   Redis      │    │ (delivers  │
                       │ (presence +  │    │  to B's WS)│
                       │  user→server │    └────────────┘
                       │  mapping)    │
                       └──────────────┘
                              │
                       ┌──────┴───────┐
                       │  Cassandra   │ (message store)
                       └──────────────┘
```

**Data Model (Cassandra)** [🔥 Must Know]:

```sql
-- Messages table: partition by conversation, ordered by time
messages (
  conversation_id UUID,      -- PARTITION KEY (all messages for a conversation on same node)
  created_at      TIMESTAMP, -- CLUSTERING KEY (messages sorted by time within partition)
  message_id      UUID,      -- unique message ID (for deduplication)
  sender_id       BIGINT,
  content         TEXT,
  type            TEXT,      -- 'text', 'image', 'file'
  PRIMARY KEY (conversation_id, created_at)
) WITH CLUSTERING ORDER BY (created_at DESC); -- newest first for pagination
```

💡 **Intuition — Why Cassandra?** Chat messages are write-heavy (24K QPS), time-ordered, and accessed by conversation. Cassandra's LSM tree handles high writes efficiently. Partitioning by `conversation_id` keeps all messages for a conversation on the same node → fast reads for message history. Clustering by `created_at` gives automatic time ordering.

## 4. Deep Dive

**1:1 message flow** [🔥 Must Know]:

```
1. User A sends message via WebSocket to Chat Server 1
2. Chat Server 1:
   a. Validate message (auth, rate limit, content)
   b. Generate message_id (UUID) and timestamp
   c. Write to Kafka (partition key = conversation_id → ordering guaranteed)
   d. Return ack to User A ("message sent")
3. Kafka consumer:
   a. Write message to Cassandra (persistent storage)
   b. Look up User B's chat server in Redis (user→server mapping)
   c. If User B is ONLINE: forward message to User B's chat server → deliver via WebSocket
   d. If User B is OFFLINE: send push notification (APNs for iOS, FCM for Android)
4. User B receives message via WebSocket (or push notification)
5. User B's client sends read receipt → propagated back to User A
```

**Group messaging — Fan-out strategy:**

| Strategy | How | Pros | Cons | Best For |
|----------|-----|------|------|----------|
| Fan-out on write | Write message once to Kafka, deliver to each member's chat server | Simple, fast delivery | Expensive for large groups (500 members = 500 deliveries) | Small groups (< 500) |
| Fan-out on read | Write message once, members pull when they open the conversation | Efficient for large groups | Slower (pull-based), more complex | Large groups, channels |

For groups up to 500 members, fan-out on write is fine. For Slack-like channels with 10K+ members, fan-out on read is better.

```
Group message flow (fan-out on write):
1. User A sends to group G (100 members)
2. Write message to Cassandra (once, under conversation_id = G)
3. For each member of G:
   a. Look up member's chat server in Redis
   b. If online: deliver via WebSocket
   c. If offline: queue push notification
4. Total: 1 DB write + 100 deliveries (acceptable for groups ≤ 500)
```

**Presence (online/offline status)** [🔥 Must Know]:

```
Implementation with Redis:
  - Client sends heartbeat every 30 seconds via WebSocket
  - Chat server updates Redis: SET user:{user_id}:presence "online" EX 60
  - If no heartbeat for 60 seconds → key expires → user is offline
  - Presence changes published via Redis Pub/Sub to interested users

Why not update on every WebSocket connect/disconnect?
  - Disconnects are unreliable (network drops don't trigger clean disconnect)
  - Heartbeat is more reliable — if heartbeat stops, user is definitely offline
```

**User-to-server mapping:**
Each user's WebSocket connects to one chat server. Redis stores `user_id → chat_server_id`. When delivering a message, look up which server the recipient is connected to, then forward the message to that server.

```
Redis: user:123 → chat-server-7
       user:456 → chat-server-3

Delivering message to user 456:
  1. Look up Redis: user:456 → chat-server-3
  2. Send message to chat-server-3 (internal RPC or Kafka)
  3. chat-server-3 pushes to user 456's WebSocket
```

**Message ordering:** Kafka partition by `conversation_id` guarantees ordering within a conversation. Cassandra's clustering key on `created_at` maintains order in storage. Client-side: sort by timestamp, use message_id for deduplication.

💥 **What Can Go Wrong:**

| Problem | Impact | Solution |
|---------|--------|---------|
| Chat server crashes | Users lose WebSocket connection | Client auto-reconnects to another server. Fetch missed messages from Cassandra. |
| Message delivered but not persisted | Message lost on server crash | Write to Kafka first (durable), then persist. Kafka is the source of truth. |
| Duplicate messages | User sees same message twice | Client deduplicates by message_id. Server uses idempotent writes. |
| Hot conversation (viral group) | One Cassandra partition overloaded | Partition by conversation_id + time bucket (e.g., daily). |
| Presence flapping | User appears online/offline rapidly | Debounce: only publish status change after stable for 10 seconds. |

🎯 **Likely Follow-ups:**
- **Q:** How do you handle message delivery to a user who was offline and comes back online?
  **A:** On reconnect, client sends its last received message_id. Server queries Cassandra for all messages in the user's conversations after that message_id. This is the "catch-up" mechanism.
- **Q:** How do you handle typing indicators?
  **A:** Ephemeral WebSocket events — don't persist. When User A starts typing, send a "typing" event to User B's chat server. No Kafka, no Cassandra. If it's lost, no big deal.
- **Q:** How does end-to-end encryption work?
  **A:** Signal Protocol: each user has a public/private key pair. Messages are encrypted with the recipient's public key. The server never sees plaintext — it just stores and forwards encrypted blobs. Key exchange happens via a separate key server.

## 5. Advanced / Follow-ups
- **End-to-end encryption:** Signal protocol, key exchange, forward secrecy
- **Multi-device sync:** Each device has its own WebSocket. Messages delivered to all devices. Last-read sync across devices.
- **Message search:** Elasticsearch index on message content (only for non-E2E-encrypted messages)
- **File sharing:** Upload to S3, store S3 URL in message. Thumbnail generation via async worker.
- **Message reactions:** Store as a map `{emoji: [user_ids]}` within the message document.

## 6. Common Mistakes

| Weak Answer | Strong Answer |
|-------------|---------------|
| "Use REST polling for messages" | "WebSocket for real-time delivery, with long polling as fallback for environments that don't support WebSocket" |
| "Store messages in MySQL" | "Cassandra for write-heavy workload (24K QPS), partitioned by conversation_id, clustered by timestamp" |
| "Check DB for online status" | "Redis with heartbeat + TTL for presence. Pub/Sub for status change notifications." |
| No offline handling | "Push notifications via APNs/FCM for offline users. Catch-up on reconnect via last message_id." |

## 7. Interviewer's Evaluation Criteria

| Criteria | What They Look For |
|----------|-------------------|
| Real-time protocol | WebSocket (not polling), with fallback strategy |
| Database choice | Write-optimized (Cassandra), justified with QPS numbers |
| Message routing | User→server mapping in Redis, Kafka for ordering |
| Presence | Heartbeat + TTL in Redis, not DB polling |
| Group chat | Fan-out strategy with trade-offs |
| Offline handling | Push notifications + catch-up on reconnect |
| Ordering | Kafka partition by conversation, Cassandra clustering key |

## 7. How I'd Present This in 45 Minutes

```
[0-5 min] Requirements:
"I'll design a real-time chat system. 1:1 and group chat (up to 500 members).
Text messages, online presence, read receipts, message history.
50M DAU, 2B messages/day, < 100ms delivery for online users."

[5-10 min] Estimation:
"Write QPS: 24K, peak 60K. Very write-heavy, need Cassandra or sharded DB.
Storage: 400GB/day, 146TB/year. Concurrent WebSocket connections: ~10M.
Memory for connections: 100GB across ~100 servers."

[10-20 min] High-Level Design:
"WebSocket for real-time messaging. REST for history and group management.
Chat servers hold WebSocket connections. Kafka for message routing between servers.
Cassandra for message storage (partition by conversation_id, cluster by timestamp)."

[20-40 min] Deep Dive:
"Message flow: sender → chat server → Kafka → recipient's chat server → WebSocket → recipient.
If recipient offline: store in Cassandra, send push notification via APNs/FCM.
Presence: heartbeat every 30s to Redis. Subscribe to presence changes via pub/sub.
Group messages: fan-out to all members via Kafka. For large groups, batch delivery."

[40-45 min] Wrap-up:
"Monitoring: message delivery latency p99, WebSocket connection count, Kafka consumer lag.
Failure: if chat server crashes, clients reconnect to another server, fetch missed messages.
Extensions: end-to-end encryption, message reactions, file/image sharing via S3 + presigned URLs."
```

## 7b. Common Mistakes to Avoid

| Mistake | Why It's Wrong | What to Do Instead |
|---------|---------------|-------------------|
| Using HTTP polling instead of WebSocket | Wastes bandwidth, adds latency, doesn't scale | WebSocket for real-time, long polling as fallback |
| Storing messages in a relational DB | Can't handle 60K writes/sec, poor partition support | Use Cassandra (write-optimized, partition by conversation) |
| Not handling offline message delivery | Users miss messages when offline | Store undelivered messages, send push notification, deliver on reconnect |
| Single chat server (no horizontal scaling) | Can't handle 10M concurrent connections | Multiple chat servers + Kafka for cross-server message routing |
| Ignoring message ordering | Messages appear out of order | Kafka partition by conversation_id guarantees per-conversation order |

## 8. Revision Checklist

- [ ] WebSocket for real-time, REST for history/management, long polling as fallback
- [ ] Cassandra: partition by conversation_id, cluster by created_at DESC
- [ ] Redis: presence (heartbeat + TTL), user→server mapping
- [ ] Kafka: message routing, partition by conversation_id for ordering
- [ ] Push notifications (APNs/FCM) for offline users
- [ ] Group chat: fan-out on write for small groups (≤ 500), fan-out on read for large channels
- [ ] Message ordering: Kafka partition + Cassandra clustering key + client-side dedup by message_id
- [ ] Catch-up on reconnect: client sends last message_id, server fetches newer messages
- [ ] Estimation: 50M DAU, 24K write QPS, 400 GB/day, 10M concurrent connections

> 🔗 **See Also:** [02-system-design/00-prerequisites.md](../00-prerequisites.md) for WebSocket vs SSE vs long polling. [06-tech-stack/01-kafka-deep-dive.md](../../06-tech-stack/01-kafka-deep-dive.md) for Kafka ordering guarantees. [06-tech-stack/02-redis-deep-dive.md](../../06-tech-stack/02-redis-deep-dive.md) for Redis Pub/Sub and TTL patterns.

---

## 9. Interviewer Deep-Dive Questions

1. **"User is on 3 devices (phone, tablet, laptop). How do you sync?"**
   → Each device has its own WebSocket connection. Redis stores `user_id → [server1, server2, server3]`. Message delivered to ALL connected servers. Read receipts synced: when one device reads, broadcast "read" event to other devices.

2. **"Chat server crashes with 50K active connections. What happens?"**
   → Clients detect disconnect (WebSocket close event or heartbeat timeout). Auto-reconnect to another server via load balancer. On reconnect, client sends `last_received_message_id`. Server fetches missed messages from Cassandra. Redis user→server mapping updated.

3. **"10K-member group chat. Someone sends a message. Walk me through delivery."**
   → Don't fan-out to 10K WebSockets individually. Instead: publish to a Kafka topic for that group. Each chat server subscribes and delivers to its locally connected members. For offline members: batch push notifications (don't send 10K individual pushes — send "New message in Group X").

4. **"Messages arrive out of order due to network delays."**
   → Each message has a server-assigned timestamp + sequence number per conversation. Client sorts by sequence number. If a gap is detected (received seq 5, then seq 7), client requests seq 6 from server. Kafka partition by conversation_id guarantees server-side ordering.

5. **"How do you implement 'last seen' and typing indicators?"**
   → Last seen: update Redis on every user action (message sent, app opened). TTL = 5 min. Typing: ephemeral WebSocket event — NOT persisted. Send "typing" to the other participant's chat server. Auto-expire after 3 seconds of no keystrokes.

6. **"How would you implement message search?"**
   → Elasticsearch index on message content. Index on write (async via Kafka consumer). Search API: query ES with user's conversation filter. NOT possible with E2E encryption (server can't read content).

7. **"How does end-to-end encryption change the architecture?"**
   → Server stores encrypted blobs — can't read, search, or moderate content. Key exchange via Signal Protocol (X3DH + Double Ratchet). Each device has its own key pair. Group E2E: sender encrypts message N times (once per member's public key). Server is just a relay.

## 10. Failure Matrix

| Component Down | Impact | Mitigation |
|---|---|---|
| Chat server | 50K users disconnected | Auto-reconnect to another server. Fetch missed messages from Cassandra. |
| Redis (presence) | Can't determine who's online | Degrade gracefully: show "last seen" from DB. Presence is non-critical. |
| Cassandra | Can't persist or retrieve messages | Messages buffered in Kafka. Deliver via WebSocket (real-time still works). Persist when Cassandra recovers. |
| Kafka | Messages can't route between servers | Fallback: direct server-to-server RPC for delivery. Lose ordering guarantees temporarily. |
