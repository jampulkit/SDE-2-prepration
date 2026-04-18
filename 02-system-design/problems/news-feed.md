# Design: News Feed

## 1. Problem Statement & Scope

**Design a social media news feed like Facebook's News Feed or Twitter's timeline — a personalized, ranked stream of posts from people you follow.**

**Clarifying questions to ask:**
- Chronological or ranked? → Ranked (relevance + recency)
- Celebrity accounts (millions of followers)? → Yes, must handle
- Average friends/followers? → 500, max 5000 for regular users, millions for celebrities
- Media types? → Text, images, videos, links
- Real-time updates? → Nice to have, not required for initial design

💡 **Why this is a top interview problem:** The news feed is the core of every social platform. It tests the fan-out problem (the most important trade-off in social systems), caching strategy, ranking, and handling the celebrity/hotspot problem. Facebook, Twitter, and Instagram all solve this differently.

## 2. Requirements

**Functional:**
- Publish posts (text, images, videos)
- View personalized feed (ranked by relevance + recency)
- Like/comment on posts
- Follow/unfollow users
- Pagination (infinite scroll)

**Non-functional:**
- Feed generation < 200ms (p99)
- High availability (99.99%)
- Eventual consistency OK (a new post appearing 1-2 seconds late is acceptable)
- Feed should feel "fresh" (not stale for more than a few seconds)

**Estimation:**
```
300M DAU, 5 feed refreshes/day = 1.5B feed reads/day
Read QPS: 1.5B / 86,400 ≈ 17,000 QPS. Peak: ~50,000 QPS.
  → Need heavy caching (Redis handles this easily)

1M new posts/day → Write QPS: ~12 QPS (low)
  → But fan-out amplifies this: 12 QPS × 500 avg followers = 6,000 fan-out writes/sec

Feed cache per user: ~1000 post IDs × 8 bytes = 8 KB per user
Total cache: 300M users × 8 KB = 2.4 TB → Redis cluster needed
```

## 3. High-Level Design

**The Fan-Out Problem** [🔥 Must Know]:

When User A publishes a post, how do their 500 followers see it in their feeds?

| Approach | How | Pros | Cons |
|----------|-----|------|------|
| Fan-out on write (push) | On post, immediately write post_id to all followers' feed caches | Fast reads (feed is pre-computed) | Slow for celebrities (10M writes per post), wasted work for inactive users |
| Fan-out on read (pull) | On feed open, fetch latest posts from all followees, merge and rank | No wasted work, fast writes | Slow reads (must query N followees), hard to rank in real-time |
| **Hybrid (best)** | Push for regular users (< 10K followers), pull for celebrities at read time | Fast reads + handles celebrities | More complex, merge logic needed |

💡 **Intuition — Why Hybrid Wins:**
- Regular user posts to 500 followers → 500 Redis writes. Fast, manageable.
- Celebrity posts to 10M followers → 10M Redis writes. Takes minutes, wastes resources for inactive followers.
- Hybrid: push regular posts immediately, pull celebrity posts when the user opens their feed. Merge both at read time.

```
Hybrid fan-out flow:

POST (regular user, 500 followers):
  1. Write post to Post Storage (DB)
  2. Fan-out Service: fetch 500 follower IDs
  3. For each follower: ZADD feed:{follower_id} {timestamp} {post_id} in Redis
  4. Done in ~50ms (500 Redis writes)

POST (celebrity, 10M followers):
  1. Write post to Post Storage (DB)
  2. NO fan-out. Post stays in celebrity's post list.

FEED READ:
  1. Fetch pre-computed feed from Redis (regular posts) → O(1)
  2. Fetch latest posts from followed celebrities (pull) → query each celebrity's post list
  3. Merge both lists, rank, return top N
  4. Total: < 200ms
```

**Architecture:**
```
┌────────┐    ┌──────────┐    ┌──────────────┐    ┌─────────────────┐
│ Client │───→│ API/LB   │───→│ Post Service │───→│ Fan-out Service │
└────────┘    └──────────┘    └──────┬───────┘    └────────┬────────┘
                                     │                      │
                              ┌──────┴───────┐    ┌────────┴────────┐
                              │ Post Storage │    │ Feed Cache      │
                              │ (MySQL/Cass) │    │ (Redis sorted   │
                              └──────────────┘    │  sets per user) │
                                                  └────────┬────────┘
                                                           │
┌────────┐    ┌──────────┐    ┌──────────────┐            │
│ Client │───→│ API/LB   │───→│ Feed Service │────────────┘
└────────┘    └──────────┘    │ (merge +     │
                              │  rank)       │
                              └──────────────┘
```

**Data Model:**
```sql
-- Post storage (MySQL or Cassandra)
posts (
  post_id     BIGINT PRIMARY KEY,
  user_id     BIGINT INDEX,
  content     TEXT,
  media_urls  JSON,
  created_at  TIMESTAMP INDEX,
  like_count  INT DEFAULT 0,
  comment_count INT DEFAULT 0
)

-- Social graph (MySQL or graph DB)
follows (
  follower_id  BIGINT,
  followee_id  BIGINT,
  created_at   TIMESTAMP,
  PRIMARY KEY (follower_id, followee_id)
)
-- Index on followee_id for "get all followers of user X"

-- Feed cache (Redis sorted sets)
-- Key: feed:{user_id}
-- Members: post_ids, scored by timestamp (or ranking score)
-- ZRANGEBYSCORE for pagination, ZADD for adding new posts
-- Limit to 1000 most recent posts per user (ZREMRANGEBYRANK to trim)
```

## 4. Deep Dive

**Fan-out on write (detailed):**
```
1. User A publishes post P
2. Post Service: write P to Post Storage, get post_id
3. Post Service → Kafka topic "new-posts" (async)
4. Fan-out Workers consume from Kafka:
   a. Fetch User A's follower list (from follows table or cache)
   b. For each follower F:
      - ZADD feed:{F} {timestamp} {post_id} in Redis
      - ZREMRANGEBYRANK feed:{F} 0 -1001 (keep only latest 1000)
   c. If User A has > 10K followers: skip fan-out (celebrity)
5. Fan-out is async — User A gets immediate response
```

**Feed retrieval (detailed):**
```
1. Client: GET /api/v1/feed?cursor=...&limit=20
2. Feed Service:
   a. Fetch from Redis: ZREVRANGEBYSCORE feed:{user_id} +inf {cursor} LIMIT 0 20
   b. Fetch celebrity posts: for each followed celebrity, get latest posts
   c. Merge both lists by ranking score
   d. Hydrate: fetch full post objects (content, media, author info) from Post Storage/cache
   e. Return ranked, hydrated feed with next cursor
```

**Ranking** [🔥 Must Know]:
Simple ranking: `score = recency_weight × time_decay + engagement_weight × (likes + comments) + affinity_weight × user_interaction_history`

In production (Facebook, Instagram): ML model trained on user engagement data. Features include recency, engagement, content type, author affinity, user's past behavior. But for interviews, a simple weighted formula is sufficient.

**Celebrity problem — the key trade-off:**

| Followers | Strategy | Fan-out Cost | Read Cost |
|-----------|----------|-------------|-----------|
| < 1K | Push (fan-out on write) | 1K Redis writes | O(1) read from cache |
| 1K - 10K | Push | 10K Redis writes (~10ms) | O(1) read |
| 10K - 1M | Pull (fan-out on read) | 0 | Query celebrity's post list |
| > 1M | Pull + CDN cache | 0 | Cached at CDN/edge |

💥 **What Can Go Wrong:**

| Problem | Impact | Solution |
|---------|--------|---------|
| Celebrity posts → 10M fan-out writes | Fan-out takes minutes, Redis overloaded | Hybrid: pull for celebrities, push for regular |
| Feed cache cold start (new user) | Empty feed on first load | Pre-compute feed on follow, or pull on first load |
| Stale feed | User sees old posts after refresh | Short TTL on cache, or invalidate on new post |
| Hot post (viral) | Millions of reads for one post | Cache post object in Redis, CDN for media |
| Unfollow consistency | User unfollows but still sees posts | Remove post_ids from feed cache on unfollow (async) |

🎯 **Likely Follow-ups:**
- **Q:** How does Facebook's News Feed ranking work?
  **A:** ML model with hundreds of features: recency, engagement (likes, comments, shares), content type (video > image > text), author affinity (how often you interact with this person), user's past behavior. The model predicts "probability of engagement" for each candidate post and ranks by that score.
- **Q:** How do you handle real-time feed updates (new posts appearing without refresh)?
  **A:** WebSocket or SSE: when a new post is fan-out to a user's feed, also push a notification via WebSocket. Client inserts the new post at the top of the feed without a full refresh.
- **Q:** How do you handle feed for a user who follows 5000 people?
  **A:** Pre-compute the feed (fan-out on write for non-celebrities). At read time, merge with celebrity posts. The Redis sorted set already has the top 1000 posts ranked — just fetch the top 20 for the first page.

## 5. Advanced / Follow-ups
- **ML ranking pipeline:** Feature extraction → model inference → re-ranking. Batch (offline) + real-time (online) features.
- **Real-time updates:** WebSocket push for new posts, typing indicators, live comments.
- **Content moderation:** ML-based content classification, human review queue, report mechanism.
- **Multi-region:** Feed cache per region, cross-region replication for post storage.
- **Ads integration:** Insert sponsored posts into the feed at specific positions.

## 6. Common Mistakes

| Weak Answer | Strong Answer |
|-------------|---------------|
| "Fan-out on write for everyone" | "Hybrid: push for regular users, pull for celebrities. Celebrity fan-out is too expensive (10M writes per post)." |
| "Fan-out on read for everyone" | "Pull is too slow for feed reads (must query 500 followees). Push pre-computes the feed for fast reads." |
| "Store feed in MySQL" | "Redis sorted sets for feed cache — O(log n) insert, O(log n + k) range query. MySQL for persistent post storage." |
| No ranking discussion | "Simple ranking: weighted score of recency + engagement + affinity. In production, ML model." |

## 7. Interviewer's Evaluation Criteria

| Criteria | What They Look For |
|----------|-------------------|
| Fan-out strategy | Hybrid approach with clear trade-offs |
| Celebrity handling | Pull for celebrities, push for regular users |
| Data structures | Redis sorted sets for feed cache |
| Ranking | At least a simple formula; bonus for mentioning ML |
| Pagination | Cursor-based (not offset) |
| Async processing | Fan-out via Kafka workers, not synchronous |

## 7. How I'd Present This in 45 Minutes

```
[0-5 min] Requirements:
"I'll design a news feed system. Users see posts from people they follow, ranked by relevance.
500M DAU, 10B feed loads/day. Feed load < 500ms. Eventual consistency is fine."

[5-10 min] Estimation:
"Feed QPS: 115K, peak 350K. Need pre-computed feeds.
Average user follows 200 people. Celebrity users have 10M+ followers.
Post storage: 1B posts/day × 1KB = 1TB/day."

[10-20 min] High-Level Design:
"Hybrid fan-out: push for normal users, pull for celebrities.
On post: fan-out to followers' feed caches (Redis lists, capped at 500 post IDs).
On feed load: read from cache, merge with celebrity posts, rank, return top 50."

[20-40 min] Deep Dive:
"Fan-out service: on new post, get follower list, push post_id to each follower's feed in Redis.
Celebrity threshold: > 10K followers. Don't fan-out for celebrities.
Feed ranking: score = recency × engagement × relationship_strength.
Feed cache: Redis sorted set per user, score = ranking score, trim to 500 entries."

[40-45 min] Wrap-up:
"Monitoring: feed generation latency, fan-out lag, cache hit rate.
Failure: if Redis is down, fall back to pull-based feed (query followed users' posts).
Extensions: ads injection, content moderation, A/B testing different ranking algorithms."
```

## 7b. Common Mistakes to Avoid

| Mistake | Why It's Wrong | What to Do Instead |
|---------|---------------|-------------------|
| Pure push (fan-out on write) for all users | Celebrity with 10M followers = 10M writes per post | Hybrid: push for normal, pull for celebrities |
| Pure pull (fan-out on read) for all users | Feed load queries 200+ users' posts, too slow | Pre-compute feeds, pull only for celebrity posts |
| Not capping feed cache size | Memory grows unbounded | Cap at 500-1000 post IDs per user, trim oldest |
| Chronological feed only | Misses relevant older posts, poor engagement | Rank by recency + engagement + relationship |
| Synchronous fan-out | Post creation takes seconds (blocking on 10K writes) | Async fan-out via Kafka workers |

## 8. Revision Checklist

- [ ] Hybrid fan-out: push for regular (< 10K followers), pull for celebrities
- [ ] Redis sorted set for feed cache: ZADD, ZREVRANGEBYSCORE, limit to 1000 posts
- [ ] Cursor-based pagination (not offset)
- [ ] Ranking: recency + engagement + affinity (simple formula for interviews)
- [ ] Fan-out is async (Kafka → workers → Redis)
- [ ] Celebrity problem: don't fan-out for > 10K followers, pull at read time
- [ ] Feed read: merge pre-computed (Redis) + celebrity posts (pull) → rank → return
- [ ] Estimation: 300M DAU, 17K read QPS, 12 write QPS, 2.4 TB feed cache

> 🔗 **See Also:** [02-system-design/03-message-queues-event-driven.md](../03-message-queues-event-driven.md) for Kafka-based async fan-out. [06-tech-stack/02-redis-deep-dive.md](../../06-tech-stack/02-redis-deep-dive.md) for Redis sorted sets. [02-system-design/problems/notification-system.md](notification-system.md) for push notification patterns.

---

## 9. Interviewer Deep-Dive Questions

1. **"Celebrity with 50M followers posts during peak hour. Walk me through what happens."**
   → We do NOT fan-out for celebrities (>10K followers). The post is written to Post Storage only. When a follower opens their feed, we pull the celebrity's latest posts at read time and merge with the pre-computed feed from Redis. This avoids 50M Redis writes.

2. **"How do you handle content moderation in real-time?"**
   → On post creation: run through ML classifier (text: toxicity model, image: NSFW detector). If confidence > threshold: auto-remove. If borderline: flag for human review, show with warning. Async pipeline via Kafka — don't block post creation. User can appeal.

3. **"User unfollows someone. How quickly do their posts disappear from the feed?"**
   → Async: publish unfollow event → worker removes that user's post_ids from the follower's Redis feed cache. Takes seconds. For immediate UX: client-side filter (hide posts from unfollowed user until cache is updated).

4. **"How do you handle feed for a brand new user with 0 followers?"**
   → Cold start problem. Show trending/popular posts. Recommend accounts to follow based on interests (onboarding survey). As they follow people, gradually transition to personalized feed. Pre-compute a "default feed" for new users.

5. **"How do you A/B test different ranking algorithms?"**
   → Route users to experiment groups (user_id % 100). Each group gets a different ranking model. Measure engagement metrics (time spent, likes, comments, shares). Use statistical significance testing before rolling out winner.

6. **"Feed pagination — why cursor-based over offset-based?"**
   → Offset breaks when new posts are inserted (user sees duplicates or misses posts). Cursor = last seen post_id or timestamp. `WHERE created_at < cursor ORDER BY created_at DESC LIMIT 20`. Consistent results even with concurrent inserts.

## 10. Failure Matrix

| Component Down | Impact | Mitigation |
|---|---|---|
| Redis (feed cache) | Feed reads hit DB directly — very slow at 115K QPS | Fallback: pull-based feed (query followed users' recent posts). Degraded but functional. |
| Kafka (fan-out) | New posts not distributed to feeds | Posts still saved to DB. Feeds become stale. Catch-up job when Kafka recovers. |
| Elasticsearch (search) | Can't search posts | Search is non-critical. Show "search unavailable" message. |
| Ranking service | Can't rank feed | Fallback to chronological ordering. |
