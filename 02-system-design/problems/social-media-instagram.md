# Design: Social Media (Instagram)

## 1. Problem Statement & Scope

**Design a media-heavy social media platform like Instagram that supports photo/video uploads, a personalized feed, stories, likes/comments, and follow relationships.**

**Clarifying questions to ask:**
- Media types? → Photos and short videos (up to 60 seconds)
- Feed algorithm? → Ranked (not purely chronological)
- Stories? → Yes, 24-hour TTL
- Direct messaging? → Out of scope (see chat-system.md)
- Scale? → 500M DAU

## 2. Requirements

**Functional:**
- Upload photos/videos with captions
- Follow/unfollow users
- Personalized feed (posts from followed users, ranked)
- Stories (24-hour ephemeral content)
- Like, comment, share
- Explore/discover page

**Non-functional:**
- Feed load: < 500ms p99
- Upload: < 5s for photos, < 30s for videos
- 99.9% availability
- Eventual consistency for feed (a few seconds delay is OK)
- Strong consistency for follow/unfollow (immediate effect)

**Estimation:**
```
500M DAU, 20 feed loads/day = 10B feed requests/day
Feed QPS: 10B / 86400 ≈ 115K QPS. Peak: ~350K QPS.
  → Heavy caching required. Pre-compute feeds.

Uploads: 50M photos/day + 5M videos/day
Upload QPS: 55M / 86400 ≈ 640 QPS. Manageable.

Storage:
  Photos: 50M/day × 2MB (multiple resolutions) = 100TB/day
  Videos: 5M/day × 50MB (multiple resolutions) = 250TB/day
  Total: ~350TB/day. ~130PB/year. Object storage (S3).

Follow graph: 500M users × 200 avg following = 100B edges
  → Graph database or sharded adjacency list
```

## 3. High-Level Design

```
UPLOAD PATH:
  Client → Upload Service → S3 (raw) → Kafka → Processing Workers
                                                  ├→ Image: resize (thumbnail, medium, full)
                                                  └→ Video: transcode (multiple resolutions)
                                               → S3 (processed) → CDN
                                               → Update metadata DB
                                               → Fan-out to followers' feeds

FEED PATH:
  Client → API Gateway → Feed Service → Pre-computed Feed (Redis/Cassandra)
                                       → Merge with real-time updates
                                       → Return ranked feed

SOCIAL GRAPH:
  Follow Service → Graph DB or sharded adjacency list (PostgreSQL/Redis)
```

## 4. Deep Dive

### Media Upload Pipeline

```
Photo upload:
  1. Client uploads to Upload Service (or directly to S3 via presigned URL)
  2. Upload Service stores raw photo in S3
  3. Publishes "photo_uploaded" event to Kafka
  4. Image Processing Worker:
     a. Generate thumbnail (150×150)
     b. Generate medium (600×600)
     c. Generate full resolution (1080×1080)
     d. Strip EXIF data (privacy)
     e. Upload all versions to S3
  5. Update post metadata in DB (status = PUBLISHED, image_urls)
  6. Trigger fan-out to followers' feeds

Video upload:
  Same flow but with transcoding (FFmpeg):
  - 240p, 480p, 720p, 1080p
  - Generate thumbnail from first frame
  - HLS segments for adaptive streaming
  Processing time: 30s-5min depending on length
```

### Feed Generation [🔥 Must Know]

**The celebrity problem: a user with 100M followers posts. Do you write to 100M feeds?**

| Approach | How | Pros | Cons |
|----------|-----|------|------|
| **Pull (fan-out on read)** | On feed load, query all followed users' posts, merge, rank | No write amplification | Slow for users following many people |
| **Push (fan-out on write)** | On post, write to all followers' feed caches | Fast feed reads | Massive write amplification for celebrities |
| **Hybrid (recommended)** | Push for normal users, pull for celebrities | Balanced | More complex |

```
Hybrid approach (Instagram/Twitter):

Celebrity threshold: users with > 100K followers

Normal user posts:
  1. Fan-out on write: push post ID to each follower's feed cache (Redis list)
  2. Each follower's feed: sorted list of post IDs, capped at 500
  3. Feed load: read from cache, fetch post details, return

Celebrity posts:
  1. Do NOT fan-out (100M writes is too expensive)
  2. On feed load: merge cached feed + pull latest posts from followed celebrities
  3. Rank merged results by score (recency, engagement, relationship)

Feed ranking score:
  score = recency_weight × time_decay
        + engagement_weight × (likes + comments)
        + relationship_weight × interaction_frequency
        + content_type_weight × (photo vs video vs story)
```

### Stories (24-Hour Ephemeral Content)

```
Storage:
  stories:{user_id} → Redis sorted set (score = upload_timestamp)
  TTL: 24 hours (Redis handles expiry automatically)

Feed:
  1. Get list of followed users
  2. For each: check if stories:{user_id} exists in Redis
  3. Return users with active stories, sorted by recency
  4. Client fetches individual story media from CDN

Optimization:
  - Pre-compute "users with active stories" set per follower
  - Update this set when a story is posted or expires
  - Feed load: one Redis lookup instead of N
```

### Social Graph (Follow Relationships)

```sql
-- Adjacency list in PostgreSQL (sharded by follower_id)
follows (
    follower_id  BIGINT,
    followee_id  BIGINT,
    created_at   TIMESTAMP,
    PRIMARY KEY (follower_id, followee_id)
);
-- Index on (followee_id) for "who follows me?" queries

-- Queries:
-- "Who do I follow?" → WHERE follower_id = me (partition key, fast)
-- "Who follows me?" → WHERE followee_id = me (secondary index)
-- "Does A follow B?" → WHERE follower_id = A AND followee_id = B (primary key, O(1))
-- "Mutual friends?" → INTERSECT of A's following and B's following
```

**For very large scale:** use a graph database (Neo4j) or a dedicated graph service with in-memory adjacency lists.

### Explore / Discovery Page

```
Explore page shows content from users you DON'T follow, personalized to your interests.

Approach:
  1. Collaborative filtering: "Users similar to you liked these posts"
  2. Content-based: posts with similar hashtags/categories to what you engage with
  3. Trending: posts with high engagement velocity (likes/hour)
  
  Pre-compute candidate posts hourly (batch ML pipeline).
  Rank in real-time based on user's recent activity.
  Cache top candidates per user segment in Redis.
```

### Data Model

```sql
users (
    id          BIGINT PRIMARY KEY,
    username    VARCHAR(30) UNIQUE,
    bio         TEXT,
    avatar_url  VARCHAR(255),
    follower_count  INTEGER DEFAULT 0,
    following_count INTEGER DEFAULT 0,
    is_celebrity    BOOLEAN DEFAULT FALSE  -- > 100K followers
);

posts (
    id          BIGINT PRIMARY KEY,  -- Snowflake ID (time-ordered)
    user_id     BIGINT,
    caption     TEXT,
    media_urls  JSONB,  -- [{type: "photo", url: "...", thumbnail_url: "..."}]
    like_count  INTEGER DEFAULT 0,
    comment_count INTEGER DEFAULT 0,
    created_at  TIMESTAMP
);
-- Index: (user_id, created_at DESC) for user's profile page

likes (
    user_id     BIGINT,
    post_id     BIGINT,
    created_at  TIMESTAMP,
    PRIMARY KEY (user_id, post_id)
);
-- "Did I like this post?" → O(1) lookup

comments (
    id          BIGINT PRIMARY KEY,
    post_id     BIGINT,
    user_id     BIGINT,
    content     TEXT,
    created_at  TIMESTAMP
);
-- Index: (post_id, created_at) for loading comments on a post
```

## 5. Bottlenecks & Trade-offs

| Bottleneck | Solution |
|-----------|----------|
| Feed generation for 500M DAU | Hybrid fan-out: push for normal users, pull for celebrities |
| 350TB/day media storage | S3 with lifecycle policies (hot → cold). CDN for serving. |
| Celebrity post fan-out | Don't fan-out. Pull on feed load. Cache celebrity posts separately. |
| Like count accuracy | Approximate: Redis INCR (fast). Exact: periodic DB sync. |
| Story expiry | Redis TTL (automatic). No manual cleanup needed. |
| Feed ranking | Pre-compute features offline. Rank in real-time with lightweight model. |

## 6. Revision Checklist

- [ ] Upload: presigned URL → S3 → Kafka → resize/transcode workers → S3 → CDN.
- [ ] Feed: hybrid fan-out. Push for normal users (< 100K followers). Pull for celebrities.
- [ ] Feed ranking: recency + engagement + relationship + content type.
- [ ] Stories: Redis sorted set with 24h TTL. Pre-compute "users with stories" set.
- [ ] Social graph: adjacency list sharded by follower_id. Secondary index on followee_id.
- [ ] Celebrity problem: don't fan-out for celebrities. Merge on read.
- [ ] Like count: Redis INCR for speed, periodic sync to DB for durability.
- [ ] Explore: collaborative filtering + trending + content-based. Pre-compute candidates.
- [ ] Media storage: S3 (multiple resolutions) + CDN. ~350TB/day.

> 🔗 **See Also:** [02-system-design/problems/news-feed.md](news-feed.md) for feed generation deep dive. [02-system-design/problems/video-streaming.md](video-streaming.md) for video transcoding pipeline. [02-system-design/problems/chat-system.md](chat-system.md) for direct messaging.

---

## 9. Interviewer Deep-Dive Questions

1. **"How do you rank Stories (the top bar)?"**
   → Rank by: recency (newer first), relationship strength (frequent interactions), completion rate (did user watch this person's stories before?). ML model predicts "probability of watching." Stories expire after 24 hours — TTL in Redis or Cassandra.

2. **"How does the Explore/Discover page work?"**
   → Candidate generation: collaborative filtering ("users like you liked these posts"). Ranking: ML model scores each candidate by predicted engagement. Diversity: ensure mix of content types (photos, videos, reels). Personalization: user's interest graph (topics they engage with).

3. **"How do you handle content moderation at scale (500M DAU)?"**
   → Multi-layer: (1) Upload-time: ML classifiers for NSFW, violence, hate speech. (2) Viral detection: if post gets rapid engagement, re-check with higher-accuracy model. (3) User reports: queue for human review. (4) Appeal process. Automated moderation handles 95%+.

4. **"How do you store and serve images at 100TB/day?"**
   → Upload: client → presigned S3 URL → S3. Processing: resize to multiple resolutions (thumbnail, medium, full), generate WebP/AVIF variants. Storage: S3 with lifecycle policies (move old images to Glacier). Serving: CDN (CloudFront) with aggressive caching. Total: ~130PB/year.

5. **"Follow graph: 500M users × 200 avg following = 100B edges. How do you store it?"**
   → Adjacency list in sharded MySQL/Cassandra. Partition by user_id. `followers(user_id, follower_id)` and `following(user_id, followee_id)` — two tables for bidirectional queries. Cache hot users' follower lists in Redis. For "mutual friends": intersection of two follower sets.

## 10. Failure Matrix

| Component Down | Impact | Mitigation |
|---|---|---|
| CDN | Images don't load | Multi-CDN. Serve lower-resolution from origin as fallback. |
| Feed service | Can't load feed | Serve cached feed (stale but available). Show "pull to refresh" when recovered. |
| Upload pipeline | Can't post new content | Queue uploads. Process when recovered. Show "posting..." state to user. |
