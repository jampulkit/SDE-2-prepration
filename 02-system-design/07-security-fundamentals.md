# System Design — Security Fundamentals

## 1. Prerequisites
- [04-api-design.md](04-api-design.md) — authentication, JWT, OAuth

## 2. Core Concepts

### Authentication vs Authorization [🔥 Must Know]

| Concept | Question | Example | Implemented By |
|---------|----------|---------|---------------|
| **Authentication (AuthN)** | WHO are you? | Login with username/password, JWT token | Auth service, identity provider |
| **Authorization (AuthZ)** | WHAT can you do? | Admin can delete users, regular user can't | RBAC, ABAC, policy engine |

💡 **Intuition:** Authentication is checking your ID at the door. Authorization is checking whether your ID gives you access to the VIP section.

### JWT (JSON Web Token) [🔥 Must Know]

```
JWT structure: header.payload.signature (base64 encoded, dot-separated)

Header:  {"alg": "HS256", "typ": "JWT"}
Payload: {"user_id": "123", "role": "admin", "exp": 1700000000}
Signature: HMAC-SHA256(base64(header) + "." + base64(payload), secret_key)

eyJhbGciOiJIUzI1NiJ9.eyJ1c2VyX2lkIjoiMTIzIn0.signature_here
```

**JWT flow:**

```
1. Client: POST /login {username, password}
2. Server: validate credentials → generate JWT → return {access_token, refresh_token}
3. Client: GET /api/orders  Headers: Authorization: Bearer <access_token>
4. Server: verify JWT signature → extract user_id from payload → process request
   No database lookup needed! JWT is self-contained (stateless).
```

**JWT vs Session-based auth:**

| Aspect | JWT (Token-based) | Session (Cookie-based) |
|--------|-------------------|----------------------|
| State | Stateless (token contains all info) | Stateful (session stored on server) |
| Scalability | Easy (any server can verify) | Hard (need shared session store) |
| Revocation | Hard (can't invalidate until expiry) | Easy (delete session from store) |
| Storage | Client-side (localStorage or cookie) | Server-side (Redis, DB) |
| Best for | Microservices, APIs, mobile apps | Traditional web apps, SSR |

⚠️ **Common Pitfall:** Storing JWTs in localStorage is vulnerable to XSS attacks. Store in httpOnly cookies instead (not accessible via JavaScript).

**Token refresh flow:**

```
access_token: short-lived (15 min). Used for API calls.
refresh_token: long-lived (7 days). Used only to get new access_token.

1. Client calls API with expired access_token → 401 Unauthorized
2. Client calls POST /refresh {refresh_token}
3. Server validates refresh_token → issues new access_token
4. Client retries original request with new access_token

Why two tokens?
  - Short access_token limits damage if stolen (expires in 15 min)
  - Long refresh_token avoids forcing re-login every 15 min
  - Refresh_token can be revoked server-side (stored in DB)
```

### OAuth 2.0 / OpenID Connect [🔥 Must Know]

**OAuth 2.0 is for authorization (access to resources). OpenID Connect (OIDC) adds authentication (user identity) on top of OAuth.**

```
OAuth 2.0 Authorization Code Flow (most secure for web apps):

1. User clicks "Login with Google"
2. App redirects to Google: GET /authorize?client_id=...&redirect_uri=...&scope=email
3. User authenticates with Google, grants permission
4. Google redirects back: GET /callback?code=AUTH_CODE
5. App server exchanges code for tokens: POST /token { code, client_secret }
   (This happens server-to-server. Client secret never exposed to browser.)
6. Google returns: { access_token, refresh_token, id_token }
7. App uses access_token to call Google APIs on user's behalf

Key tokens:
  access_token: short-lived (15 min), used to access resources
  refresh_token: long-lived (days), used to get new access_token
  id_token (OIDC): JWT with user info (name, email), used for authentication
```

**OAuth 2.0 grant types:**

| Grant Type | Use Case | Security |
|-----------|----------|----------|
| Authorization Code | Web apps with backend | Most secure (code exchanged server-side) |
| Authorization Code + PKCE | Mobile/SPA (no client secret) | Secure (code verifier prevents interception) |
| Client Credentials | Service-to-service (no user) | Machine-to-machine only |
| Implicit (deprecated) | Old SPAs | Insecure (token in URL fragment) |

### Encryption [🔥 Must Know]

| Type | What | Algorithm | Use Case |
|------|------|-----------|----------|
| **Symmetric** | Same key encrypts and decrypts | AES-256 | Data at rest, fast |
| **Asymmetric** | Public key encrypts, private key decrypts | RSA-2048, Ed25519 | Key exchange, digital signatures |
| **Hashing** | One-way, can't reverse | SHA-256, bcrypt | Password storage, integrity checks |

**Encryption in practice:**

| Layer | What | How |
|-------|------|-----|
| **In transit** | Data moving over network | TLS 1.3 (HTTPS). All API communication. |
| **At rest** | Data stored on disk | AES-256. Database, S3, backups. AWS KMS for key management. |
| **End-to-end** | Only sender and receiver can read | Signal Protocol. Chat apps (WhatsApp). Server can't read messages. |

⚙️ **Under the Hood, TLS Handshake (simplified):**

```
Client → Server: "Hello, I support TLS 1.3, these cipher suites"
Server → Client: "Let's use TLS 1.3 with AES-256-GCM. Here's my certificate."
Client: Verifies certificate (checks CA chain, expiry, domain match)
Client → Server: Key exchange (Diffie-Hellman). Both derive shared secret.
Both: Use shared secret for symmetric encryption (AES-256-GCM)

After handshake: all data encrypted with symmetric key (fast).
Asymmetric crypto only used during handshake (slow, but only once).

TLS 1.3 improvement: 1-RTT handshake (vs 2-RTT in TLS 1.2).
  0-RTT resumption for returning clients (but vulnerable to replay attacks).
```

**Password storage** [🔥 Must Know]:

```
NEVER store plaintext passwords.
NEVER use MD5 or SHA-256 for passwords (too fast, vulnerable to brute force).

Use bcrypt (or scrypt, Argon2):
  - Intentionally slow (configurable work factor)
  - Built-in salt (prevents rainbow table attacks)
  - Work factor increases over time as hardware gets faster

Java:
  String hashed = BCrypt.hashpw(password, BCrypt.gensalt(12)); // 12 = work factor
  boolean match = BCrypt.checkpw(password, hashed);
```

### Authorization Models [🔥 Must Know]

| Model | How | Best For |
|-------|-----|----------|
| **RBAC** (Role-Based) | User → Role → Permissions. Admin role has delete permission. | Most applications |
| **ABAC** (Attribute-Based) | Rules based on attributes: "user.department == resource.department" | Fine-grained, dynamic |
| **ACL** (Access Control List) | Per-resource list of who can do what | File systems, simple cases |

```
RBAC example:
  Roles: ADMIN, MANAGER, USER
  Permissions: CREATE_ORDER, VIEW_ORDER, DELETE_ORDER, VIEW_REPORTS
  
  ADMIN: all permissions
  MANAGER: CREATE_ORDER, VIEW_ORDER, VIEW_REPORTS
  USER: CREATE_ORDER, VIEW_ORDER
  
  Check: if (user.roles.contains("ADMIN") || user.permissions.contains("DELETE_ORDER"))
```

### Rate Limiting and DDoS Protection

- **Rate limiting:** Token bucket / sliding window at API gateway (see [rate-limiter.md](problems/rate-limiter.md))
- **DDoS protection:** CDN-level filtering (CloudFlare, AWS Shield), IP blacklisting, CAPTCHA
- **WAF (Web Application Firewall):** Block SQL injection, XSS, known attack patterns
- **Bot detection:** Fingerprinting, behavioral analysis, CAPTCHA challenges

### OWASP Top 10 (Know the Top 5) [🔥 Must Know]

| # | Vulnerability | How It Works | Prevention |
|---|-------------|-------------|------------|
| 1 | **Injection** (SQL, NoSQL) | Attacker inserts malicious code in input | Parameterized queries, input validation, ORM |
| 2 | **Broken Authentication** | Weak passwords, no MFA, session fixation | MFA, secure session management, rate limit login |
| 3 | **Sensitive Data Exposure** | Unencrypted data, PII in logs | Encrypt at rest + in transit, don't log PII |
| 4 | **Broken Access Control** | User accesses another user's data | RBAC/ABAC, check ownership on every request |
| 5 | **Security Misconfiguration** | Default passwords, debug mode in prod | Secure defaults, automated security scanning |

⚙️ **Under the Hood, SQL Injection Example:**

```java
// VULNERABLE:
String query = "SELECT * FROM users WHERE name = '" + userInput + "'";
// If userInput = "'; DROP TABLE users; --"
// Query becomes: SELECT * FROM users WHERE name = ''; DROP TABLE users; --'
// Result: table deleted!

// SAFE: parameterized query
PreparedStatement stmt = conn.prepareStatement("SELECT * FROM users WHERE name = ?");
stmt.setString(1, userInput);
// userInput is treated as DATA, not SQL code. Injection impossible.
```

### API Security Checklist

```
1. Authentication: JWT with short expiry (15 min) + refresh tokens
2. Authorization: RBAC, check permissions on every endpoint
3. Transport: HTTPS everywhere (TLS 1.3), HSTS header
4. Input validation: validate all inputs, parameterized queries
5. Rate limiting: per-user and per-IP at API gateway
6. CORS: restrict allowed origins (don't use *)
7. Headers: X-Content-Type-Options, X-Frame-Options, CSP
8. Secrets: never in code, use environment variables or secret manager (AWS Secrets Manager)
9. Logging: log auth events, don't log passwords or tokens
10. Dependencies: scan for known vulnerabilities (Snyk, Dependabot)
```

🎯 **Likely Follow-ups:**
- **Q:** How do you handle JWT revocation?
  **A:** JWTs are stateless, so you can't revoke them directly. Options: (1) Short expiry (15 min) limits damage window. (2) Token blacklist in Redis (check on every request, but adds latency). (3) Token versioning: store a version counter per user in DB, include version in JWT, reject if version doesn't match.
- **Q:** How do you secure service-to-service communication?
  **A:** Mutual TLS (mTLS): both client and server present certificates. The service mesh (Istio) handles this automatically via sidecar proxies. Alternatively, use API keys or OAuth client credentials grant.
- **Q:** What is the difference between encryption and hashing?
  **A:** Encryption is reversible (you can decrypt with the key). Hashing is one-way (you can't recover the original). Use encryption for data you need to read later (credit card tokens). Use hashing for data you only need to verify (passwords).

### How This Shows Up in Interviews

**What to mention in system design (15 seconds):**
> "For authentication, I'll use JWT tokens with short expiry (15 min) and refresh tokens. All communication over HTTPS with TLS 1.3. Passwords hashed with bcrypt. API rate limiting at the gateway. Database encryption at rest with AES-256 via AWS KMS. For payment data, PCI DSS compliance with tokenization."

## 3. Revision Checklist
- [ ] AuthN (who) vs AuthZ (what). JWT for stateless auth. OAuth for third-party.
- [ ] JWT: header.payload.signature. Stateless, self-contained. Short expiry + refresh token.
- [ ] JWT storage: httpOnly cookie (not localStorage). Revocation: blacklist or token versioning.
- [ ] OAuth 2.0: authorization code flow (most secure). PKCE for mobile/SPA.
- [ ] Encryption: symmetric (AES-256, fast), asymmetric (RSA, key exchange), hashing (bcrypt, passwords)
- [ ] TLS 1.3: 1-RTT handshake, asymmetric for key exchange, symmetric for data
- [ ] Passwords: bcrypt with salt. Never MD5/SHA-256 (too fast).
- [ ] RBAC: user → role → permissions. ABAC: attribute-based rules.
- [ ] OWASP: SQL injection (parameterized queries), XSS (output encoding), CSRF (tokens)
- [ ] Rate limiting + DDoS protection at CDN/gateway level
- [ ] PCI DSS: tokenize card data, never store raw card numbers
- [ ] Service-to-service: mTLS or OAuth client credentials

> 🔗 **See Also:** [02-system-design/04-api-design.md](04-api-design.md) for JWT and API authentication. [02-system-design/problems/payment-system.md](problems/payment-system.md) for PCI DSS compliance. [02-system-design/11-api-gateway-service-mesh.md](11-api-gateway-service-mesh.md) for mTLS in service mesh.
