# System Design — API Design

## 1. Prerequisites
- [00-prerequisites.md](./00-prerequisites.md) — REST, gRPC, WebSocket overview
- This document covers API design patterns used in Phase 3 of every system design interview

## 2. Core Concepts

### REST API Design [🔥 Must Know]

**REST is the default API style for public-facing services — it uses HTTP methods as verbs, URLs as nouns (resources), and standard status codes for responses.**

**REST principles:**
- **Stateless:** Each request contains all info needed. Server doesn't store session state between requests.
- **Resource-based:** URLs represent resources (nouns), not actions (verbs).
- **HTTP methods as verbs:** GET (read), POST (create), PUT (replace), PATCH (partial update), DELETE (remove).
- **Uniform interface:** Consistent URL patterns, standard HTTP status codes, self-descriptive messages.

💡 **Intuition — REST as CRUD on Resources:** Think of REST as a library catalog system. Each book is a "resource" with a URL (`/books/123`). You can GET (read) a book, POST (add) a new book, PUT (replace) a book's info, PATCH (update) just the title, or DELETE (remove) a book. The URL identifies WHAT, the HTTP method identifies the ACTION.

**URL design best practices:**

```
GET    /api/v1/users              → List users (with pagination)
GET    /api/v1/users/{id}         → Get user by ID
POST   /api/v1/users              → Create user
PUT    /api/v1/users/{id}         → Replace entire user object
PATCH  /api/v1/users/{id}         → Partial update (e.g., just the name)
DELETE /api/v1/users/{id}         → Delete user

GET    /api/v1/users/{id}/orders  → List user's orders (nested resource)
POST   /api/v1/users/{id}/orders  → Create order for user
```

**Rules:**
- Use nouns, not verbs: `/users` not `/getUsers` or `/createUser`
- Use plural: `/users` not `/user`
- Use kebab-case: `/user-profiles` not `/userProfiles`
- Version your API: `/api/v1/...`
- Use query params for filtering/sorting: `/users?status=active&sort=-created_at`
- Nest resources for relationships: `/users/{id}/orders` (orders belong to user)
- Limit nesting to 2 levels: `/users/{id}/orders/{orderId}` is fine, deeper is confusing

**HTTP Status Codes** [🔥 Must Know]:

| Code | Meaning | When to Use |
|------|---------|-------------|
| 200 | OK | Successful GET, PUT, PATCH |
| 201 | Created | Successful POST (include Location header with new resource URL) |
| 202 | Accepted | Request accepted for async processing (not yet completed) |
| 204 | No Content | Successful DELETE (no body in response) |
| 400 | Bad Request | Invalid input, validation error |
| 401 | Unauthorized | Not authenticated (missing or invalid token) |
| 403 | Forbidden | Authenticated but not authorized (don't have permission) |
| 404 | Not Found | Resource doesn't exist |
| 409 | Conflict | Duplicate resource, optimistic locking version conflict |
| 429 | Too Many Requests | Rate limited (include Retry-After header) |
| 500 | Internal Server Error | Server bug (never expose stack traces to client) |
| 503 | Service Unavailable | Server overloaded or in maintenance |

💡 **Intuition — 401 vs 403:** 401 means "I don't know who you are" (not authenticated). 403 means "I know who you are, but you're not allowed" (not authorized). A common mistake is returning 401 for authorization failures.

**Idempotency of HTTP methods** [🔥 Must Know]:

| Method | Idempotent? | Safe? | Notes |
|--------|------------|-------|-------|
| GET | Yes | Yes | Read-only, no side effects |
| PUT | Yes | No | Replace entire resource — same result on retry |
| DELETE | Yes | No | Deleting twice = same result (resource gone) |
| PATCH | Not guaranteed | No | Depends on implementation |
| POST | No | No | Creating twice = two resources (use idempotency key) |

⚠️ **Common Pitfall — POST is NOT idempotent:** If a client retries a POST (e.g., network timeout), it might create a duplicate resource. Solution: require an idempotency key in the request header. Server checks if this key was already processed.

**Pagination** [🔥 Must Know]:

| Type | How | Pros | Cons |
|------|-----|------|------|
| Offset-based | `?page=2&limit=20` or `?offset=20&limit=20` | Simple, can jump to any page | Slow for large offsets (DB skips rows), inconsistent with concurrent inserts/deletes |
| Cursor-based | `?cursor=eyJpZCI6MTIzfQ&limit=20` | Consistent results, fast (uses index), handles concurrent changes | Can't jump to arbitrary page, cursor is opaque |
| Keyset-based | `?after_id=123&limit=20` | Fast (WHERE id > 123 LIMIT 20), uses index | Same as cursor but transparent |

💡 **Intuition — Why Cursor-Based is Better for Large Datasets:**
Offset-based: `SELECT * FROM posts ORDER BY id OFFSET 1000000 LIMIT 20` — the DB must scan and skip 1 million rows. Slow.
Cursor-based: `SELECT * FROM posts WHERE id > 1000000 ORDER BY id LIMIT 20` — the DB uses the index to jump directly to id 1000000. Fast.

```
Cursor-based pagination response:
{
  "data": [...],
  "pagination": {
    "next_cursor": "eyJpZCI6MTIzfQ==",  // Base64 encoded {id: 123}
    "has_more": true
  }
}
```

🎯 **Likely Follow-ups:**
- **Q:** How do you handle pagination when items are being inserted concurrently?
  **A:** Offset-based breaks: if a new item is inserted on page 1 while you're reading page 2, you'll see a duplicate or miss an item. Cursor-based is stable: "give me items after this cursor" always returns the correct next batch regardless of insertions.
- **Q:** How do you implement cursor-based pagination with sorting?
  **A:** The cursor encodes the sort key + unique ID. For `ORDER BY created_at DESC, id DESC`, the cursor is `{created_at: "2024-01-15", id: 456}`. The query becomes `WHERE (created_at, id) < ('2024-01-15', 456) ORDER BY created_at DESC, id DESC LIMIT 20`.

### Authentication & Authorization [🔥 Must Know]

| Method | How | Stateless? | Use Case |
|--------|-----|-----------|----------|
| API Key | Key in header (`X-API-Key: abc123`) | Yes | Simple server-to-server, public APIs |
| JWT | Signed token in `Authorization: Bearer <token>` | Yes | Microservices, SPAs, mobile apps |
| OAuth 2.0 | Token-based delegation (authorization code flow) | Yes | Third-party access ("Login with Google") |
| Session cookie | Server stores session, client sends cookie | No | Traditional web apps |

**JWT structure** [🔥 Must Know]: `header.payload.signature` (Base64url encoded, separated by dots)

```
Header:    {"alg": "HS256", "typ": "JWT"}
Payload:   {"user_id": 123, "role": "admin", "exp": 1700000000}
Signature: HMAC-SHA256(base64(header) + "." + base64(payload), secret_key)

Token: eyJhbGciOiJIUzI1NiJ9.eyJ1c2VyX2lkIjoxMjN9.abc123signature

Server validates by:
1. Decode header and payload (Base64)
2. Recompute signature using the secret key
3. Compare with the signature in the token
4. Check expiry (exp claim)
No database lookup needed → stateless authentication
```

💡 **Intuition — Why JWT is Stateless:** With session cookies, the server must store session data (in memory or Redis) and look it up on every request. With JWT, all the user info is IN the token itself. The server just verifies the signature — no database/cache lookup. This is why JWT scales well in microservices (any service can verify the token independently).

⚠️ **Common Pitfall — JWT Revocation:** JWTs can't be revoked before expiry (they're stateless — there's no server-side session to invalidate). Solutions: short expiry (15 min) + refresh tokens, or maintain a blacklist of revoked tokens (but this adds state).

### gRPC

**Use gRPC for internal microservice communication where performance and type safety matter.**

| Feature | REST | gRPC |
|---------|------|------|
| Format | JSON (text, ~2-10x larger) | Protobuf (binary, compact) |
| Contract | OpenAPI/Swagger (optional) | `.proto` file (required, strongly typed) |
| Streaming | No native support | Unary, server-streaming, client-streaming, bidirectional |
| HTTP version | HTTP/1.1 (usually) | HTTP/2 (multiplexing, header compression) |
| Code generation | Manual or tools | Automatic from `.proto` file |
| Browser support | Native | Requires gRPC-Web proxy |
| Best for | Public APIs, web clients | Internal microservices, high-throughput |

### GraphQL

**Use GraphQL when clients need flexible queries — the client specifies exactly which fields it needs, avoiding over-fetching and under-fetching.**

```graphql
# Client requests exactly what it needs:
query {
  user(id: 123) {
    name
    email
    orders(last: 5) {
      id
      total
    }
  }
}
# No over-fetching (only requested fields returned)
# No under-fetching (nested data in one request)
```

| Aspect | REST | GraphQL |
|--------|------|---------|
| Endpoints | Multiple (`/users`, `/orders`) | Single (`/graphql`) |
| Data fetching | Fixed response shape | Client specifies fields |
| Over-fetching | Common (returns all fields) | None (only requested fields) |
| Under-fetching | Common (need multiple requests) | None (nested queries) |
| Caching | Easy (HTTP caching by URL) | Hard (POST requests, dynamic queries) |
| Best for | Simple CRUD, public APIs | Mobile apps, complex UIs with varying data needs |

### Webhooks

**Webhooks are server-to-server push notifications — when an event occurs, the source sends an HTTP POST to a registered callback URL.**

```
1. Client registers webhook: POST /webhooks { "url": "https://myapp.com/callback", "events": ["payment.completed"] }
2. Event occurs: payment is completed
3. Source sends: POST https://myapp.com/callback { "event": "payment.completed", "data": {...} }
4. Client responds: 200 OK (or source retries)
```

**Must handle:** Retries (with exponential backoff), idempotency (same event delivered twice), signature verification (HMAC to verify sender), timeout (respond quickly, process async).

### API Rate Limiting

**Include rate limit info in response headers so clients can self-throttle:**

```
HTTP/1.1 200 OK
X-RateLimit-Limit: 100        # max requests per window
X-RateLimit-Remaining: 45     # remaining in current window
X-RateLimit-Reset: 1625097600 # when window resets (Unix timestamp)

HTTP/1.1 429 Too Many Requests
Retry-After: 30               # seconds to wait before retrying
```

### API Versioning Strategies

| Strategy | Example | Pros | Cons |
|----------|---------|------|------|
| URL path | `/api/v1/users` | Clear, easy to route, easy to test | URL changes |
| Header | `Accept: application/vnd.api.v1+json` | Clean URLs | Hidden, harder to test/discover |
| Query param | `/api/users?version=1` | Simple | Easy to forget, pollutes query string |

URL path versioning is most common and recommended for its clarity.

> 🔗 **See Also:** [02-system-design/problems/url-shortener.md](problems/url-shortener.md) for a complete API design example. [06-tech-stack/04-spring-boot.md](../06-tech-stack/04-spring-boot.md) for implementing REST APIs in Spring Boot.

## 3. Comparison Tables

| Protocol | Format | Performance | Browser Support | Streaming | Best For |
|----------|--------|-------------|-----------------|-----------|----------|
| REST | JSON | Good | Excellent | No | Public APIs, CRUD, web clients |
| gRPC | Protobuf | Excellent | Limited | Yes (4 types) | Internal microservices |
| GraphQL | JSON | Good | Excellent | Subscriptions | Flexible client queries, mobile |
| WebSocket | Binary/Text | Excellent | Good | Full-duplex | Real-time bidirectional |
| Webhooks | JSON | N/A | N/A | Push only | Event notifications, integrations |

## 4. How This Shows Up in Interviews

**In system design interviews, API design is Phase 3.** You should:
1. Define 3-5 key endpoints with HTTP methods
2. Specify request/response format (JSON fields with types)
3. Mention authentication method and why
4. Discuss pagination strategy (cursor-based for feeds, offset for admin panels)
5. Note any idempotency requirements (POST with idempotency key for payments)

**Example — URL Shortener API:**
```
POST /api/v1/urls
  Headers: Authorization: Bearer <jwt>, X-Idempotency-Key: <uuid>
  Request:  { "long_url": "https://example.com/very/long/path", "custom_alias": "my-link", "ttl_hours": 720 }
  Response: { "short_url": "https://short.ly/abc123", "long_url": "...", "created_at": "...", "expires_at": "..." }
  Status: 201 Created

GET /{short_code}
  Response: 301 Moved Permanently (Location: https://example.com/very/long/path)
  (301 for permanent redirect — browsers cache it. 302 for temporary — browsers don't cache.)

GET /api/v1/urls/{short_code}/stats
  Response: { "total_clicks": 1234, "created_at": "...", "top_referrers": [...], "clicks_by_day": [...] }
  Status: 200 OK
```

## 5. Deep Dive Questions

1. [🔥 Must Know] **Design a RESTful API for a social media platform.** — Users, posts, comments, likes, feed.
2. [🔥 Must Know] **PUT vs PATCH — when to use which?** — PUT replaces entire resource, PATCH updates specific fields.
3. [🔥 Must Know] **Cursor-based vs offset-based pagination.** — Performance, consistency, use cases.
4. **How does JWT authentication work?** — Structure, signing, verification, stateless.
5. [🔥 Must Know] **When would you use gRPC over REST?** — Internal services, performance, streaming, type safety.
6. **Which HTTP methods are idempotent?** — GET, PUT, DELETE yes. POST no. PATCH depends.
7. **How do you version an API?** — URL path (recommended), header, query param.
8. **What is HATEOAS?** — Hypermedia links in responses for discoverability. Rarely used in practice.
9. [🔥 Must Know] **How do you handle API rate limiting?** — Token bucket, headers, 429 response.
10. **What is the N+1 problem in GraphQL?** — Nested query triggers N DB queries. Fix: DataLoader (batching).

## 6. Revision Checklist

- [ ] REST: resource-based URLs (nouns), HTTP verbs (GET/POST/PUT/PATCH/DELETE), stateless, standard status codes
- [ ] Status codes: 200 OK, 201 Created, 204 No Content, 400 Bad Request, 401 Unauthorized, 403 Forbidden, 404 Not Found, 429 Rate Limited, 500 Server Error
- [ ] Pagination: cursor-based for large/real-time datasets, offset for simple/admin use
- [ ] Auth: JWT (stateless, microservices), OAuth 2.0 (third-party), API key (simple server-to-server)
- [ ] JWT: header.payload.signature, stateless verification, short expiry + refresh token
- [ ] gRPC: protobuf (binary), HTTP/2, streaming, internal services
- [ ] Idempotent methods: GET, PUT, DELETE. POST is NOT idempotent → use idempotency key.
- [ ] Versioning: URL path (`/api/v1/`) is most common and recommended
- [ ] Rate limiting: 429 status, X-RateLimit-* headers, Retry-After header
- [ ] Webhooks: server push via HTTP POST, retries, signature verification, idempotency

---

## 📋 Suggested New Documents

### 1. API Gateway & Service Mesh
- **Placement**: `02-system-design/06-api-gateway-service-mesh.md`
- **Why needed**: API gateways (Kong, AWS API Gateway) and service meshes (Istio, Envoy) handle cross-cutting concerns (auth, rate limiting, routing, observability) and are frequently discussed in system design interviews but not covered in any existing file.
- **Key subtopics**: API gateway patterns (routing, auth, rate limiting, transformation), service mesh architecture (sidecar proxy), service discovery, circuit breaking at the mesh level, mTLS
