# Design: Search Autocomplete

## 1. Problem Statement & Scope

**Design a typeahead/autocomplete system like Google search suggestions that returns the top 5 most relevant completions as the user types, updating in real-time.**

**Clarifying questions to ask:**
- How many suggestions? → Top 5
- Ranking criteria? → Popularity (search frequency), with recency boost
- How fresh should suggestions be? → New trending queries within 1 hour
- Personalized? → Global popularity initially, personalization as extension
- Multi-language? → English initially

💡 **Why this is a great interview problem:** It combines a classic data structure (Trie) with a real-time data pipeline (search log aggregation), client-side optimization (debouncing), and offline processing (trie building). It tests both DSA knowledge and system design thinking.

## 2. Requirements

**Functional:**
- Return top 5 suggestions as user types each character
- Ranked by popularity/relevance
- Update suggestions based on new search trends (within ~1 hour)
- Filter offensive/inappropriate suggestions

**Non-functional:**
- < 100ms latency (suggestions must feel instant)
- High availability (99.99%)
- Eventual consistency for suggestion updates (1-hour delay OK)

**Estimation:**
```
10M DAU, 10 searches/day, avg 4 prefix queries per search (typing "weather" → "w", "we", "wea", "weat")
Autocomplete requests: 10M × 10 × 4 = 400M/day
QPS: 400M / 86,400 ≈ 5,000 QPS. Peak: ~15,000 QPS.
  → Redis/in-memory trie handles this easily

Trie size: ~5M unique queries × avg 20 chars × overhead ≈ 500 MB
  → Fits in memory on a single server (or Redis)
```

## 3. High-Level Design

```
QUERY PATH (real-time, < 100ms):
  Client (debounced) → LB → Autocomplete Service → Trie Cache (in-memory/Redis)
                                                         ↑
UPDATE PATH (offline, hourly):                           │
  Search Logs → Kafka → Aggregation Service → Trie Builder → Trie Store
```

**Data structure: Trie with precomputed top-K** [🔥 Must Know]

```
Trie for queries: "tree", "try", "true", "trip"

        root
       /    \
      t      ...
      |
      r
     / \
    e   i
    |   |
    e   p
    ↓   ↓
  "tree" "trip"

At each node, store precomputed top-5 suggestions:
  node 'tr': top_suggestions = ["tree"(1000), "trip"(800), "true"(500), "try"(300), "truck"(200)]

Lookup "tr": traverse t→r, return precomputed suggestions. O(L) where L = prefix length.
No need to traverse all children — suggestions are precomputed!
```

💡 **Intuition — Why Precompute Top-K at Each Node:** Without precomputation, finding top-5 for prefix "tr" requires traversing ALL descendants of the "tr" node — potentially millions of queries. With precomputation, it's a single lookup at the "tr" node. The trade-off: more memory (store top-5 at every node) but O(L) query time instead of O(L + N) where N = number of descendants.

**Data Model:**
```sql
-- Aggregated search counts (updated hourly)
query_counts (
  query       VARCHAR PRIMARY KEY,
  count       BIGINT,
  time_window TIMESTAMP  -- hourly bucket
)

-- Trie stored in Redis (or in-memory)
-- Key: prefix, Value: JSON array of top-5 suggestions with scores
-- "tr" → [{"query":"tree","score":1000}, {"query":"trip","score":800}, ...]
```

## 4. Deep Dive

**Trie update pipeline (offline):**
```
1. User searches → search log written to Kafka
2. Aggregation Service: count query frequency per hour (MapReduce or Spark)
3. Trie Builder: construct new trie from aggregated counts
   - For each query, insert into trie
   - At each node, maintain top-5 by score (popularity + recency boost)
4. Deploy new trie:
   - Option A: Write to Redis, app servers read from Redis
   - Option B: Serialize trie, load into app server memory (blue-green swap)
5. Frequency: rebuild every 1 hour (or more frequently for trending)
```

**Client-side optimizations** [🔥 Must Know]:
```
1. Debounce: wait 200ms after last keystroke before sending request
   - User types "weather" fast → only sends request for "weat" or "weath"
   - Reduces QPS by 50-70%

2. Client-side caching: cache prefix → suggestions mapping
   - If user typed "app" and got suggestions, "appl" results are a subset
   - Client can filter locally without a server request

3. Pre-fetch: when user focuses on search box, pre-fetch popular prefixes

4. Cancel previous request: if user types fast, cancel in-flight request for old prefix
```

**Ranking formula:**
```
score = popularity_weight × log(search_count) + recency_weight × time_decay(last_searched)

Trending boost: if search count increased 10x in last hour, boost score significantly
Personalization: merge global top-5 with user's personal search history (weighted)
```

**Filtering:** Remove offensive/inappropriate suggestions during trie building (not at query time). Maintain a blocklist of terms. ML classifier for borderline cases.

💥 **What Can Go Wrong:**

| Problem | Impact | Solution |
|---------|--------|---------|
| Trie too large for memory | Can't serve suggestions | Shard trie by first 2 characters (26² = 676 shards) |
| Stale suggestions | Trending query not appearing | Reduce rebuild interval (15 min for trending), or real-time update layer |
| Offensive suggestions | PR disaster | Blocklist + ML classifier during trie build, human review for top queries |
| Typos in queries | Bad suggestions | Spell correction layer, or only include queries with > N occurrences |

🎯 **Likely Follow-ups:**
- **Q:** How do you handle real-time trending (e.g., breaking news)?
  **A:** Two-layer approach: (1) Base trie rebuilt hourly from aggregated data. (2) Real-time layer: streaming aggregation (Kafka Streams or Flink) updates a small "trending" trie every minute. At query time, merge results from both tries.
- **Q:** How do you handle multi-language?
  **A:** Separate trie per language. Detect user's language from browser settings or IP geolocation. Serve the appropriate trie.
- **Q:** How does Google handle billions of queries?
  **A:** Sharded tries across thousands of servers. Each shard handles a subset of prefixes. Aggressive caching at CDN and app level. ML-based ranking with hundreds of features.

## 5. Advanced / Follow-ups
- **Multi-language:** Separate trie per language, language detection
- **Trending queries:** Real-time streaming aggregation + base trie merge
- **A/B testing:** Test different ranking formulas, measure click-through rate
- **Personalization:** Merge global suggestions with user's search history
- **Spell correction:** Suggest corrections for misspelled prefixes (edit distance)

## 6. Common Mistakes

| Weak Answer | Strong Answer |
|-------------|---------------|
| "Search the database on every keystroke" | "Trie with precomputed top-K at each node, O(L) lookup" |
| "Rebuild trie on every search" | "Offline pipeline: aggregate hourly, rebuild trie, blue-green deploy" |
| No client optimization | "Debounce (200ms), client-side caching, cancel previous requests" |
| "Just use Elasticsearch" | "Elasticsearch for full search, but trie is faster for prefix completion (O(L) vs O(log N))" |

## 7. Interviewer's Evaluation Criteria

| Criteria | What They Look For |
|----------|-------------------|
| Data structure | Trie with precomputed top-K (not just basic trie) |
| Update pipeline | Offline aggregation + trie rebuild (not real-time DB queries) |
| Client optimization | Debouncing, caching, request cancellation |
| Ranking | Popularity + recency, not just frequency |
| Filtering | Offensive content removal during build |

## 7. How I'd Present This in 45 Minutes

```
[0-5 min] Requirements:
"Search autocomplete like Google search bar. Return top 5 suggestions as user types.
< 100ms latency. 10B queries/day. Suggestions updated daily from query logs."

[5-10 min] Estimation:
"QPS: ~115K (every keystroke triggers a request). With debouncing (200ms): ~40K QPS.
Trie size: 10M unique prefixes × 100 bytes = 1GB. Fits in memory."

[10-20 min] High-Level Design:
"Two paths: offline pipeline builds the trie, online service queries it.
Offline: query logs → MapReduce → count frequencies → build trie → deploy to servers.
Online: user types → debounce → query trie → return top 5 suggestions."

[20-40 min] Deep Dive:
"Trie with precomputed top-5 at each node. Lookup = O(prefix_length), not O(all_words).
Debouncing: client waits 200ms after last keystroke before sending request.
Trie update: build new trie offline, swap atomically (blue-green deployment).
Personalization: merge global top-5 with user's recent searches."

[40-45 min] Wrap-up:
"Monitoring: query latency p99, trie build time, suggestion click-through rate.
Failure: if trie server is down, return empty suggestions (graceful degradation).
Extensions: spell correction, trending queries boost, offensive content filtering."
```

## 7b. Common Mistakes to Avoid

| Mistake | Why It's Wrong | What to Do Instead |
|---------|---------------|-------------------|
| Querying DB on every keystroke | Way too slow, DB can't handle 115K QPS | Pre-built trie in memory, O(prefix_length) lookup |
| No debouncing | 5 keystrokes = 5 requests for "hello" | Client debounces: wait 200ms after last keystroke |
| Updating trie in real-time | Complex, race conditions, unnecessary | Offline batch rebuild (hourly/daily), atomic swap |
| Returning all matching words | Could be thousands of results | Precompute top-5 at each trie node |
| No filtering for offensive content | Suggesting inappropriate terms | Filter during trie build, not at query time |

## 8. Revision Checklist

- [ ] Trie with precomputed top-5 at each node → O(L) lookup
- [ ] Offline pipeline: search logs → Kafka → aggregation → trie builder → deploy
- [ ] Client: debounce (200ms), cache prefix results, cancel old requests
- [ ] Ranking: popularity (log count) + recency (time decay) + trending boost
- [ ] Filtering: blocklist + ML during trie build, not at query time
- [ ] Trie size: ~500 MB for 5M unique queries → fits in memory
- [ ] Update frequency: hourly for base, real-time layer for trending
- [ ] Estimation: 5K QPS, < 100ms latency, 500 MB trie

> 🔗 **See Also:** [01-dsa/05-trees.md](../../01-dsa/05-trees.md) Pattern 8 for Trie implementation. [06-tech-stack/01-kafka-deep-dive.md](../../06-tech-stack/01-kafka-deep-dive.md) for the aggregation pipeline.

---

## 9. Interviewer Deep-Dive Questions

1. **"How do you handle offensive/inappropriate suggestions?"**
   → Blocklist filter: maintain a set of banned terms. Before returning suggestions, filter against blocklist. ML classifier for new offensive patterns. Human review for edge cases. Remove from trie during hourly rebuild.

2. **"How do you personalize suggestions?"**
   → Two-tier: (1) Global trie with popular queries. (2) Per-user recent searches stored in Redis (list of last 20 searches). At query time: merge personal results (higher priority) with global results. Personal results shown first.

3. **"Trie doesn't fit in memory (500M unique queries)."**
   → Shard the trie by first character (26 shards for a-z). Or use a distributed trie across multiple nodes. Alternative: replace trie with Elasticsearch prefix queries (less optimal but simpler to scale).

4. **"How do you handle trending queries (sudden spike)?"**
   → Real-time counter in Redis (sliding window). If a query's frequency in the last hour exceeds threshold, boost its rank in suggestions. Separate "trending" trie rebuilt every 15 minutes from recent search logs.

5. **"Client-side optimization — how do you reduce requests?"**
   → Debounce: wait 200ms after last keystroke before sending request. Cache: store prefix→results in client memory (typing "app" then "appl" — "app" results already cached, filter client-side). Prefetch: on "app" response, server includes results for "appl", "apps", etc.

## 10. Failure Matrix

| Component Down | Impact | Mitigation |
|---|---|---|
| Trie service | No autocomplete suggestions | Client shows recent searches from local storage. Degrade gracefully. |
| Kafka (log pipeline) | Suggestions become stale | Trie still serves from last build. Rebuild when Kafka recovers. |
