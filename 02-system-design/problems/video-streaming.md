# Design: Video Streaming

## 1. Problem Statement & Scope

**Design a video streaming platform like YouTube or Netflix that handles video upload, transcoding, and adaptive bitrate streaming to millions of concurrent viewers.**

## 2. Requirements
**Functional:** Upload videos (up to 10GB), stream with adaptive bitrate, search and discovery, recommendations, comments/likes, channels/subscriptions.

**Non-functional:** Low buffering (< 200ms start time), global availability, millions of concurrent viewers, cost-effective storage.

**Estimation:**
```
1B DAU, average 5 videos/day, average video length 5 min

Streaming:
  Concurrent viewers (peak): ~100M (10% of DAU at peak hour)
  Average bitrate: 5 Mbps (720p)
  Peak bandwidth: 100M * 5 Mbps = 500 Tbps (served by CDN, not origin)
  Origin bandwidth (5% cache miss): 25 Tbps

Uploads:
  100M new videos/month ≈ 40 uploads/sec
  Average raw video: 500MB
  Daily raw upload: 100M/30 * 500MB ≈ 1.7PB/day
  After transcoding (5 resolutions): ~5x raw ≈ 8.5PB/day
  Monthly storage growth: ~250PB (before dedup and lifecycle policies)

Metadata:
  Video metadata QPS: 1B DAU * 20 ops/day / 86400 ≈ 230K QPS (read-heavy, cacheable)
```

## 3. High-Level Design

```
UPLOAD PATH (async):
  Client → Upload Service → S3 (raw) → Kafka → Transcoding Workers → S3 (transcoded) → CDN

STREAMING PATH (real-time):
  Client → CDN (edge, 95%+ traffic) → Origin (S3)

METADATA PATH:
  Client → API Server → Metadata DB (MySQL) + Search (Elasticsearch)
```

**Key concepts:**

**Adaptive Bitrate Streaming (ABR)** [🔥 Must Know]: Video encoded at multiple resolutions (240p, 480p, 720p, 1080p, 4K). Client dynamically switches based on bandwidth. Protocols: HLS (Apple, most common), DASH (standard).

```
How ABR works:
  1. Video split into 2-10 second segments
  2. Each segment encoded at multiple bitrates/resolutions
  3. Client downloads manifest file (list of segments + available qualities)
  4. Client measures bandwidth, picks appropriate quality for next segment
  5. If bandwidth drops mid-stream: switch to lower quality (no buffering)
  6. If bandwidth improves: switch to higher quality (better experience)

Segment structure:
  video_123/
    manifest.m3u8 (HLS) or manifest.mpd (DASH)
    240p/  segment_001.ts, segment_002.ts, ...
    480p/  segment_001.ts, segment_002.ts, ...
    720p/  segment_001.ts, segment_002.ts, ...
    1080p/ segment_001.ts, segment_002.ts, ...
```

**Transcoding pipeline** [🔥 Must Know]:
```
1. User uploads raw video to S3 (via presigned URL)
2. Upload Service publishes "video_uploaded" event to Kafka
3. Transcoding Workers consume event:
   a. Download raw video from S3
   b. Split into segments (2-10 seconds each)
   c. Encode each segment at multiple resolutions (FFmpeg)
   d. Generate thumbnails (multiple sizes)
   e. Upload transcoded segments + thumbnails to S3
4. Update metadata DB: video status = "ready"
5. CDN pulls segments on first viewer request (pull CDN)

Optimization: parallelize transcoding
  - Split video into chunks → transcode chunks in parallel → merge
  - Use GPU instances for faster encoding (10x faster than CPU)
  - Spot/preemptible instances for cost savings (transcoding is fault-tolerant)
```

## 4. Deep Dive

**CDN is critical** [🔥 Must Know]: Videos are large (MB per segment). Serving from origin for every viewer would be impossibly expensive and slow. CDN caches segments at edge servers worldwide. Popular videos are cached everywhere. Long-tail videos: CDN fetches from origin on first request, caches for subsequent viewers.

```
Without CDN: 1M concurrent viewers × 5 Mbps = 5 Tbps from origin → impossible
With CDN: 95% served from edge → origin handles only 50K viewers = 250 Gbps → manageable
```

**Storage optimization:**
- Hot storage (S3 Standard): popular/recent videos
- Cold storage (S3 Glacier): old/unpopular videos (accessed < 1 time/month)
- Lifecycle policy: move to cold after 90 days of low access
- Delete lowest-quality encodings for old videos (keep 480p, delete 240p)

**Live streaming (extension):**
```
Different architecture from VOD (Video on Demand):
  Broadcaster → RTMP ingest server → Transcoding (real-time) → HLS/DASH segments → CDN → Viewers

Latency target: 5-30 seconds (standard), 1-5 seconds (low-latency HLS)
Challenge: can't pre-transcode (video is live), segments must be generated in real-time
```

**DRM (Digital Rights Management):**
```
For paid content (Netflix, Disney+):
  1. Video segments encrypted with AES-128 (each segment has a unique key)
  2. Keys stored in a license server (Widevine, FairPlay, PlayReady)
  3. Client requests license → server checks subscription → returns decryption key
  4. Client decrypts and plays segment
  
  Three major DRM systems:
    Widevine (Google) — Chrome, Android
    FairPlay (Apple) — Safari, iOS
    PlayReady (Microsoft) — Edge, Xbox
  
  For cross-platform: encrypt once, use CENC (Common Encryption) standard
```

💥 **What Can Go Wrong:**

| Problem | Impact | Solution |
|---------|--------|---------|
| Transcoding backlog | Videos take hours to become available | Auto-scale transcoding workers, priority queue for popular creators |
| CDN cache miss storm | Origin overloaded when new popular video released | Pre-warm CDN (push to edge before release), origin scaling |
| Copyright content | Legal issues | Content ID system (fingerprint matching), DMCA takedown process |
| Video too large | Upload fails, storage expensive | Client-side compression before upload, max file size limit |

🎯 **Likely Follow-ups:**
- **Q:** How does Netflix handle 200M+ subscribers streaming simultaneously?
  **A:** Netflix uses Open Connect — their own CDN with servers placed inside ISP networks. Popular content is pre-positioned on these servers. 95%+ of traffic never leaves the ISP's network.
- **Q:** How do you handle video recommendations?
  **A:** Collaborative filtering (users who watched X also watched Y) + content-based (similar genre, actors). Deep learning models trained on watch history, search queries, and engagement signals.

## 5. How I'd Present This in 45 Minutes

```
[0-5 min] Requirements:
"Video streaming platform like YouTube. Upload, transcode, adaptive bitrate streaming.
1B DAU, 100M uploads/month. Low buffering, global availability."

[5-10 min] Estimation:
"Concurrent viewers at peak: 100M. Bandwidth: 500 Tbps (served by CDN, not origin).
Uploads: ~640 QPS. Storage: 350TB/day (multiple resolutions). Need tiered storage."

[10-20 min] High-Level Design:
"Two separate paths: upload (async) and streaming (real-time).
Upload: client → S3 (raw) → Kafka → transcoding workers → S3 (transcoded) → CDN.
Streaming: client → CDN (95%+ cache hit) → origin S3.
Metadata: MySQL + Elasticsearch for search."

[20-40 min] Deep Dive:
"Adaptive bitrate: video split into 2-10s segments, each at multiple resolutions.
Client downloads manifest (HLS/DASH), picks quality based on bandwidth.
Transcoding: parallelize by splitting video into chunks, GPU instances, spot pricing.
CDN is critical: without it, 100M viewers × 5Mbps = impossible from origin."

[40-45 min] Wrap-up:
"Monitoring: buffering rate, CDN cache hit rate, transcoding queue depth.
Failure: CDN cache miss storm on viral video → pre-warm CDN for scheduled releases.
Extensions: live streaming (RTMP ingest → real-time transcode), DRM for paid content."
```

## 5b. Common Mistakes to Avoid

| Mistake | Why It's Wrong | What to Do Instead |
|---------|---------------|-------------------|
| Serving video from origin servers | Can't handle 100M concurrent viewers | CDN serves 95%+ of traffic from edge |
| Single resolution encoding | Poor experience on slow connections, wastes bandwidth on mobile | Adaptive bitrate: multiple resolutions, client switches dynamically |
| Synchronous transcoding | User waits minutes for video to be available | Async: upload → Kafka → workers. Notify when ready. |
| No storage tiering | Old videos cost same as popular ones | Hot (S3 Standard) for popular, cold (Glacier) for old/unpopular |
| Transcoding on CPU only | 10x slower than GPU, higher cost at scale | GPU instances for transcoding, spot/preemptible for cost savings |

## 5c. Checklist

- [ ] Adaptive bitrate streaming: HLS/DASH, multiple resolutions, client switches based on bandwidth
- [ ] Async transcoding pipeline: upload → Kafka → workers (FFmpeg) → S3 → CDN
- [ ] CDN serves 95%+ of video traffic (edge caching)
- [ ] Object storage (S3) for video segments, SQL for metadata
- [ ] Separate upload and streaming paths (different scaling needs)
- [ ] Storage tiers: hot (S3 Standard) for popular, cold (Glacier) for old
- [ ] Presigned URLs for direct upload to S3
- [ ] Parallel transcoding: split video into chunks, transcode in parallel
- [ ] Live streaming: RTMP ingest → real-time transcoding → HLS segments → CDN

> 🔗 **See Also:** [02-system-design/00-prerequisites.md](../00-prerequisites.md) for CDN concepts. [02-system-design/03-message-queues-event-driven.md](../03-message-queues-event-driven.md) for Kafka-based async pipeline.

---

## 9. Interviewer Deep-Dive Questions

1. **"How does adaptive bitrate switching work on the client?"**
   → Client downloads a manifest file (HLS: `.m3u8`, DASH: `.mpd`) listing all available quality levels. Client measures download speed of each segment. If bandwidth drops: switch to lower quality on next segment. If bandwidth improves: gradually step up. Buffer: maintain 30-60 seconds ahead to absorb fluctuations.

2. **"Live streaming vs VOD — what changes architecturally?"**
   → VOD: pre-transcoded, cached at CDN, simple. Live: real-time transcoding pipeline (RTMP ingest → transcoder → HLS/DASH segments → CDN). Latency target: 5-30 seconds for standard live, <1 second for ultra-low-latency (WebRTC). CDN cache TTL = segment duration (2-6 seconds).

3. **"How do you handle a viral video (100M views in an hour)?"**
   → CDN handles 95%+ of traffic. Origin is barely touched. CDN auto-scales. If CDN cache miss rate spikes: pre-warm CDN by pushing segments to edge nodes proactively. For metadata: cache in Redis, serve from cache.

4. **"How does the transcoding pipeline work?"**
   → Upload raw video to S3. Publish "transcode" event to Kafka. Transcoding workers (FFmpeg) pull from S3, encode to multiple resolutions (240p, 480p, 720p, 1080p, 4K) and codecs (H.264, H.265, VP9, AV1). Each resolution split into 2-6 second segments. Upload segments to S3. Update metadata DB. Notify CDN.

5. **"CDN cache invalidation — video is updated/deleted. How do you purge?"**
   → CDN purge API (CloudFront invalidation). For updates: use versioned URLs (`/video/123/v2/segment_001.ts`) — old URLs naturally expire. For takedowns (copyright): immediate purge + block at origin.

## 10. Failure Matrix

| Component Down | Impact | Mitigation |
|---|---|---|
| CDN | All streaming traffic hits origin — origin can't handle it | Multi-CDN strategy (CloudFront + Akamai). DNS failover. |
| Transcoding workers | New uploads not processed | Queue in Kafka. Process when workers recover. Existing videos unaffected. |
| Origin (S3) | CDN cache misses fail | S3 cross-region replication. CDN serves stale content (better than nothing). |
