# Design: File Storage System

## 1. Problem Statement & Scope

**Design a cloud file storage and sync system like Google Drive or Dropbox that allows users to upload, download, and sync files across multiple devices.**

**Clarifying questions to ask:**
- Max file size? → Up to 10GB (large video files)
- File types? → Any (documents, images, videos)
- Sync across devices? → Yes, real-time sync when online
- Sharing? → Yes, with view/edit permissions
- Version history? → Yes, keep last 30 versions
- Collaborative editing? → Out of scope (extension)

💡 **Why this is a great interview problem:** It tests block-level storage design, content-addressable deduplication, delta sync protocols, presigned URLs for direct upload, and conflict resolution. Every component has meaningful trade-offs.

## 2. Requirements

**Functional:**
- Upload/download files (up to 10GB)
- Sync files across multiple devices in real-time
- File/folder organization (create, move, rename, delete)
- Sharing with permissions (view, edit, owner)
- Version history (view and restore previous versions)
- Offline editing with sync on reconnect

**Non-functional:**
- High reliability (no data loss, 99.999999999% durability for stored files)
- Eventual consistency for sync (a few seconds delay is OK)
- Low latency for metadata operations (< 100ms)
- Upload/download speed limited by user's bandwidth, not our system
- Support files up to 10GB

**Estimation:**
```
50M registered users, 10M DAU
Average files per user: 200 files, average 500KB each
Total storage: 50M * 200 * 500KB = 5PB
Daily new uploads: 10M DAU * 2 files/day * 500KB = 10TB/day

Metadata QPS: 10M DAU * 20 metadata ops/day / 86400 ≈ 2,300 QPS
Upload QPS: 10M DAU * 2 uploads/day / 86400 ≈ 230 QPS
Download QPS: ~5x uploads ≈ 1,150 QPS

Block storage: 4MB blocks, 10TB/day / 4MB = 2.5M new blocks/day
With deduplication (~40% duplicate): 1.5M unique blocks/day
```

## 3. High-Level Design

**API:**
```
POST   /api/v1/files/upload/init    → {upload_id, presigned_urls[]}
PUT    /api/v1/files/upload/complete → {file_id, version}
GET    /api/v1/files/{id}/download   → {presigned_url}
GET    /api/v1/files/{id}/metadata   → {name, size, modified, versions[]}
POST   /api/v1/files/{id}/share      → {share_link}
GET    /api/v1/sync?since=timestamp  → {changes[]}
WebSocket /api/v1/sync/ws            → real-time change notifications
```

**Architecture:**

```
┌────────┐     ┌──────────────┐     ┌─────────────────┐
│ Client │────→│ API Server   │────→│ Metadata DB     │
│ (Sync  │     │ (auth, meta) │     │ (PostgreSQL)    │
│ Agent) │     └──────┬───────┘     │ files, blocks,  │
└───┬────┘            │             │ versions, shares│
    │          ┌──────┴───────┐     └─────────────────┘
    │          │ Notification │
    │          │ Service (WS) │     ┌─────────────────┐
    │          └──────────────┘     │ Message Queue   │
    │                               │ (Kafka)         │
    │     Presigned URL             │ sync events     │
    └──────────────────────────────→│                 │
              ┌─────────────────┐   └─────────────────┘
              │ Block Storage   │
              │ (S3)            │
              │ Content-addressed│
              │ 4MB blocks      │
              └─────────────────┘
```

## 4. Deep Dive

### Block-Level Sync [🔥 Must Know]

**Key insight: split files into fixed-size blocks (4MB), hash each block with SHA-256, and only upload/download changed blocks. This is what makes Dropbox fast.**

```
File "report.pdf" (12MB) split into blocks:
  Block 0: bytes[0..4MB]     → SHA-256 = "abc123"
  Block 1: bytes[4MB..8MB]   → SHA-256 = "def456"
  Block 2: bytes[8MB..12MB]  → SHA-256 = "ghi789"

File metadata: {name: "report.pdf", blocks: ["abc123", "def456", "ghi789"]}

User edits page 5 (changes bytes in Block 1 only):
  Block 0: unchanged          → SHA-256 = "abc123" (same)
  Block 1: modified           → SHA-256 = "xyz999" (new!)
  Block 2: unchanged          → SHA-256 = "ghi789" (same)

Delta sync: only upload Block 1 (4MB instead of 12MB = 67% bandwidth saved)
New version: {blocks: ["abc123", "xyz999", "ghi789"]}
Old version still accessible: {blocks: ["abc123", "def456", "ghi789"]}
```

### Content-Addressable Storage (Deduplication)

**Blocks are stored by their hash (content-addressed). If two users upload the same file, the blocks are stored only once.**

```
User A uploads "photo.jpg" → blocks: ["aaa", "bbb"]
User B uploads same "photo.jpg" → blocks: ["aaa", "bbb"]

Server checks: "aaa" already exists? Yes. "bbb" already exists? Yes.
Nothing to upload! Just create metadata pointing to existing blocks.

Storage saved: 100% for duplicate files.
Real-world dedup ratio: 30-50% across all users (common documents, libraries, etc.)

Reference counting:
  block "aaa": ref_count = 2 (User A + User B)
  When User A deletes file: ref_count = 1 (block kept)
  When User B deletes file: ref_count = 0 (block garbage collected)
```

### Upload Flow (Detailed)

```
1. Client splits file into 4MB blocks, computes SHA-256 for each
2. Client → Server: POST /upload/init {filename, block_hashes: ["abc", "def", "ghi"]}
3. Server checks which blocks already exist in storage
4. Server → Client: {upload_id, needed_blocks: ["def"], presigned_urls: {"def": "https://s3..."}}
   (blocks "abc" and "ghi" already exist, only "def" is new)
5. Client uploads "def" directly to S3 via presigned URL (bypasses app server)
6. Client → Server: POST /upload/complete {upload_id}
7. Server creates file metadata + version record
8. Server publishes sync event to Kafka
9. Notification service pushes event to user's other devices via WebSocket
```

**Why presigned URLs?**
- Client uploads directly to S3, not through the app server
- App server doesn't become a bottleneck for large file transfers
- S3 handles bandwidth, multipart upload, and retry natively
- Presigned URL expires after 15 minutes (security)

### Sync Protocol

```
Real-time sync (online):
  1. Device A uploads new version → server publishes event to Kafka
  2. Notification service sends WebSocket message to Device B
  3. Device B fetches new metadata → downloads only changed blocks → reconstructs file

Offline sync (reconnect):
  1. Device B comes online
  2. Device B → Server: GET /sync?since=last_sync_timestamp
  3. Server returns all changes since that timestamp
  4. Device B applies changes (download new blocks, delete removed files)
  5. Device B uploads any local changes made offline
  6. Conflict detection: if same file modified on both devices → conflict resolution
```

### Conflict Resolution

| Strategy | How | Pros | Cons | Used By |
|----------|-----|------|------|---------|
| Last-write-wins | Latest timestamp wins | Simple | Loses earlier changes | Simple file sync |
| Conflict copy | Keep both versions as separate files | No data loss | User must manually resolve | Dropbox |
| Merge | Auto-merge changes (for text files) | Best UX | Complex, not always possible | Google Docs (OT/CRDT) |

**Dropbox approach (recommended):**
```
Device A modifies "report.pdf" offline
Device B modifies "report.pdf" offline
Both come online:
  Server detects: base_version is the same, but changes are different
  Server keeps Device A's version as "report.pdf"
  Server saves Device B's version as "report (conflicted copy - Device B).pdf"
  User sees both files and manually resolves
```

### Data Model

```sql
-- Files and folders (tree structure)
files (
    id          UUID PRIMARY KEY,
    user_id     BIGINT NOT NULL,
    parent_id   UUID REFERENCES files(id),  -- folder hierarchy
    name        VARCHAR(255),
    is_folder   BOOLEAN DEFAULT FALSE,
    latest_version_id UUID,
    created_at  TIMESTAMP,
    updated_at  TIMESTAMP
);

-- Version history
file_versions (
    id          UUID PRIMARY KEY,
    file_id     UUID REFERENCES files(id),
    version_num INTEGER,
    size_bytes  BIGINT,
    block_hashes TEXT[],  -- ordered list of block hashes
    created_at  TIMESTAMP,
    created_by  BIGINT    -- user who made this version
);

-- Block storage metadata (actual blocks in S3)
blocks (
    hash        CHAR(64) PRIMARY KEY,  -- SHA-256 hash = content address
    size_bytes  INTEGER,
    ref_count   INTEGER DEFAULT 1,     -- garbage collect when 0
    s3_key      VARCHAR(255),
    created_at  TIMESTAMP
);

-- Sharing
shares (
    id          UUID PRIMARY KEY,
    file_id     UUID REFERENCES files(id),
    shared_with BIGINT,  -- user_id or NULL for link sharing
    permission  VARCHAR(10),  -- 'view', 'edit', 'owner'
    share_link  VARCHAR(255) UNIQUE,
    expires_at  TIMESTAMP
);
```

## 5. Bottlenecks & Trade-offs

| Bottleneck | Solution |
|-----------|----------|
| Large file upload fails midway | Multipart upload with resume. Track uploaded blocks. Retry only failed blocks. |
| Block storage grows unbounded | Reference counting + garbage collection. Delete blocks with ref_count=0. |
| Metadata DB becomes bottleneck | Read replicas for sync queries. Shard by user_id for writes. |
| S3 single-region outage | Cross-region replication (S3 CRR). Metadata DB also multi-region. |
| Sync storms (many devices update simultaneously) | Rate limit sync events per user. Batch small changes. |
| Hot files (viral shared file) | CDN for downloads. Presigned URLs with CDN distribution. |

## 5b. How I'd Present This in 45 Minutes

```
[0-5 min] Requirements:
"Cloud file storage like Dropbox. Upload/download up to 10GB. Sync across devices.
Sharing with permissions. Version history. 50M users, 10M DAU."

[5-10 min] Estimation:
"Metadata QPS: ~2300. Upload QPS: ~230. Storage: 10TB/day new uploads.
With dedup (~40%): 6TB/day unique blocks. Cache: metadata in Redis."

[10-20 min] High-Level Design:
"Key insight: block-level sync. Split files into 4MB blocks, hash each with SHA-256.
Only upload changed blocks. Dedup: same hash = same block stored once.
S3 for block storage. PostgreSQL for metadata. WebSocket for sync notifications."

[20-40 min] Deep Dive:
"Upload flow: client splits file → sends hashes → server says which are new → client uploads
new blocks via presigned S3 URLs → server creates version record.
Sync: WebSocket notification → client fetches new metadata → downloads changed blocks.
Conflict: if same file edited on two devices offline, create conflict copy (Dropbox approach)."

[40-45 min] Wrap-up:
"Monitoring: upload success rate, sync latency, dedup ratio, storage growth.
Failure: multipart upload with resume for large files. S3 cross-region replication.
Extensions: collaborative editing (OT/CRDT), search within files, activity log."
```

## 5c. Common Mistakes to Avoid

| Mistake | Why It's Wrong | What to Do Instead |
|---------|---------------|-------------------|
| Uploading entire file on every change | Wastes bandwidth, slow for large files | Block-level delta sync: only upload changed blocks |
| Uploading through the app server | App server becomes bottleneck for large files | Presigned S3 URLs for direct client-to-S3 upload |
| No deduplication | Same file uploaded by 100 users stored 100 times | Content-addressable storage: hash-based dedup |
| Last-write-wins for conflicts | Silently loses one user's changes | Conflict copy: keep both versions, let user resolve |
| No version history | Accidental deletion is permanent | Each version = list of block hashes. Old versions point to same blocks. |

## 6. Revision Checklist

- [ ] Block-level splitting (4MB) for delta sync. Only upload/download changed blocks.
- [ ] Content-addressable storage: blocks keyed by SHA-256 hash. Dedup = same hash, same block.
- [ ] Presigned URLs: client uploads directly to S3, bypassing app server bottleneck.
- [ ] Sync: WebSocket for real-time notifications, polling with timestamp for offline reconnect.
- [ ] Conflict resolution: conflict copy (Dropbox) or last-write-wins. OT/CRDT for collaborative editing.
- [ ] Version history: each version = ordered list of block hashes. Old versions point to same blocks.
- [ ] Reference counting for blocks. Garbage collect when ref_count = 0.
- [ ] Metadata in PostgreSQL (ACID for file operations). Blocks in S3 (11 nines durability).
- [ ] Upload flow: split → hash → check existing → upload new blocks → create version.

> 🔗 **See Also:** [02-system-design/02-database-choices.md](../02-database-choices.md) for storage choices. [02-system-design/09-consistency-patterns.md](../09-consistency-patterns.md) for sync consistency.

---

## 9. Interviewer Deep-Dive Questions

1. **"Two devices edit the same file offline. Both come online. How do you resolve?"**
   → Conflict detection: each edit has a version vector (device_id → version). If vectors are concurrent (neither dominates), it's a conflict. Resolution: (1) Last-writer-wins (simple, lossy). (2) Keep both versions, let user choose (Google Docs approach). (3) Operational Transform / CRDT for auto-merge (complex).

2. **"User uploads a 10GB video. Walk me through the upload."**
   → Chunked upload: split into 4MB blocks. Upload each block with a presigned S3 URL (direct to S3, bypasses our servers). Each block has a hash (SHA-256). Server tracks which blocks are uploaded. On completion: assemble blocks, verify hashes. Resume on failure: only re-upload missing blocks.

3. **"How do you deduplicate across users?"**
   → Content-addressable storage: block hash (SHA-256) is the storage key. Before uploading a block, check if hash already exists in block store. If yes: just add a reference (no upload needed). Saves ~40% storage for common files (OS files, popular documents).

4. **"How does delta sync work (only sync changes, not entire file)?"**
   → On file change: compute diff between old and new version at block level. Only upload changed blocks. Metadata update: new file version points to mix of old blocks (unchanged) + new blocks (changed). rsync algorithm: rolling hash to find matching blocks.

5. **"How do you handle versioning (30 versions per file)?"**
   → Each version is a list of block references. Blocks are immutable and shared across versions. Deleting an old version: remove the version record, but blocks are only garbage-collected when no version references them (reference counting).

## 10. Failure Matrix

| Component Down | Impact | Mitigation |
|---|---|---|
| S3 (block storage) | Can't upload or download files | S3 has 99.999999999% durability. Cross-region replication for DR. |
| Metadata DB | Can't resolve file paths or versions | DB replicas. Cache hot metadata in Redis. |
| Sync service | Devices don't sync | Queue changes locally. Sync when service recovers. |
