# System Design — API Gateway & Service Mesh

## 1. Prerequisites
- [04-api-design.md](04-api-design.md) — REST, gRPC, authentication
- [01-fundamentals.md](01-fundamentals.md) — load balancing, microservices

## 2. Core Concepts

### API Gateway [🔥 Must Know]

**A single entry point for all client requests that handles cross-cutting concerns: routing, authentication, rate limiting, SSL termination, request transformation, and monitoring.**

```
Without API Gateway:
  Client → Auth Service (authenticate)
  Client → Order Service (place order)
  Client → Payment Service (pay)
  Each service handles auth, rate limiting, logging independently — duplicated logic!

With API Gateway:
  Client → API Gateway → [auth, rate limit, log, route] → Order Service
                                                        → Payment Service
  Cross-cutting concerns handled ONCE at the gateway.
```

**What an API Gateway does:**

| Function | How | Why |
|----------|-----|-----|
| Routing | Route `/api/orders` to Order Service, `/api/users` to User Service | Single entry point |
| Authentication | Validate JWT/API key before forwarding | Don't duplicate auth in every service |
| Rate limiting | Token bucket per client | Protect backend services |
| SSL termination | Decrypt HTTPS at gateway, forward HTTP internally | Offload crypto from services |
| Request transformation | Convert REST to gRPC, aggregate multiple service calls | Backend flexibility |
| Monitoring | Log all requests, track latency, error rates | Centralized observability |
| Caching | Cache GET responses | Reduce backend load |

**Popular API Gateways:** AWS API Gateway, Kong, Nginx, Envoy, Spring Cloud Gateway.

### Service Mesh

**A dedicated infrastructure layer for service-to-service communication in microservices. Handles: load balancing, service discovery, encryption (mTLS), observability, and circuit breaking — without changing application code.**

```
Without service mesh:
  Service A → (HTTP, no encryption, manual service discovery) → Service B
  Each service implements retry, circuit breaker, tracing in code.

With service mesh (sidecar proxy):
  Service A → [Sidecar Proxy A] → (mTLS, load balanced, traced) → [Sidecar Proxy B] → Service B
  All networking logic in the sidecar. Application code is clean.
```

**Sidecar pattern:** Each service instance has a proxy (sidecar) running alongside it. All inbound/outbound traffic goes through the sidecar. The sidecar handles encryption, retry, circuit breaking, and telemetry.

**Popular service meshes:** Istio (with Envoy sidecars), Linkerd, AWS App Mesh.

### API Gateway vs Service Mesh

| Feature | API Gateway | Service Mesh |
|---------|------------|-------------|
| Position | Edge (client → backend) | Internal (service → service) |
| Traffic | North-south (external) | East-west (internal) |
| Auth | Client authentication (JWT, API key) | Service-to-service auth (mTLS) |
| Rate limiting | Per-client | Per-service |
| Best for | External API management | Internal microservice communication |

💡 **Intuition:** API Gateway is the front door (handles external clients). Service mesh is the internal hallway system (handles communication between rooms/services). Most production systems use BOTH.

### Service Discovery [🔥 Must Know]

**How does Service A find Service B's IP address when there are 50 instances of B running?**

| Approach | How | Pros | Cons | Example |
|----------|-----|------|------|---------|
| Client-side discovery | Client queries registry, picks an instance | No single point of failure | Client needs discovery logic | Netflix Eureka + Ribbon |
| Server-side discovery | Load balancer queries registry, routes request | Simple client | LB is a bottleneck | AWS ALB + ECS |
| DNS-based | Service name resolves to IP via DNS | Simple, universal | DNS caching delays updates | Kubernetes DNS, Consul DNS |

Kubernetes handles service discovery natively: `http://order-service:8080` resolves to a healthy pod via kube-dns.

⚙️ **Under the Hood, Kubernetes Service Discovery:**

```
1. Deployment creates 3 pods for order-service:
   Pod A: 10.0.1.5:8080
   Pod B: 10.0.1.6:8080
   Pod C: 10.0.1.7:8080

2. Kubernetes Service "order-service" gets a ClusterIP: 10.96.0.100
   kube-proxy sets up iptables rules to load-balance across pods

3. Another service calls http://order-service:8080
   → DNS resolves to 10.96.0.100 (ClusterIP)
   → iptables routes to one of the 3 pods (round-robin)

4. Pod C crashes. Kubernetes removes it from endpoints.
   → Traffic only goes to Pod A and Pod B.
   → No application code changes needed.
```

### Load Balancing Strategies

| Strategy | How | Best For |
|----------|-----|----------|
| Round Robin | Rotate through instances sequentially | Equal-capacity instances |
| Weighted Round Robin | More traffic to higher-capacity instances | Mixed instance sizes |
| Least Connections | Route to instance with fewest active connections | Variable request duration |
| Consistent Hashing | Hash request key to determine instance | Session affinity, caching |
| Random | Pick a random instance | Simple, surprisingly effective |

### API Gateway Patterns

**Backend for Frontend (BFF):**

```
Mobile app → Mobile BFF Gateway → (aggregates calls to 3 services, returns compact JSON)
Web app → Web BFF Gateway → (aggregates calls, returns rich JSON with more fields)
Third-party → Public API Gateway → (rate limited, versioned, different auth)

Why separate gateways?
  Mobile needs compact responses (bandwidth). Web needs rich responses.
  Public API needs strict rate limiting. Internal doesn't.
  Each BFF is optimized for its client.
```

**Request aggregation:**

```
Without aggregation (chatty client):
  Client → GET /user/123          (1 round trip)
  Client → GET /user/123/orders   (2nd round trip)
  Client → GET /user/123/reviews  (3rd round trip)
  Total: 3 round trips over the internet (slow on mobile)

With aggregation (API Gateway):
  Client → GET /user/123/profile  (1 round trip)
  Gateway internally calls: user-service, order-service, review-service (in parallel)
  Gateway combines responses → returns single JSON to client
  Total: 1 round trip over internet + 3 internal calls (fast)
```

🎯 **Likely Follow-ups:**
- **Q:** When do you NOT need an API gateway?
  **A:** For a monolith or a small number of services (2-3), an API gateway adds unnecessary complexity. A simple reverse proxy (Nginx) is enough. API gateways shine when you have 10+ microservices and need centralized cross-cutting concerns.
- **Q:** What is the difference between a reverse proxy and an API gateway?
  **A:** A reverse proxy (Nginx) handles routing, SSL termination, and load balancing. An API gateway does all of that PLUS authentication, rate limiting, request transformation, response aggregation, and API versioning. An API gateway is a reverse proxy with extra features.
- **Q:** How do you handle API gateway as a single point of failure?
  **A:** Deploy multiple gateway instances behind a load balancer (AWS ALB). Use health checks to remove unhealthy instances. The gateway itself should be stateless (auth tokens are self-contained JWTs, rate limit state is in Redis). Stateless gateways scale horizontally.
- **Q:** What is mTLS and why is it used in service meshes?
  **A:** Mutual TLS: both client and server present certificates (normal TLS only the server presents a certificate). This authenticates both sides of the connection. In a service mesh, the sidecar proxies handle mTLS automatically. No application code changes needed. This prevents unauthorized services from calling your service.

## 3. How This Shows Up in Interviews

**What to say:**
> "I'll use an API Gateway (Kong or AWS API Gateway) as the single entry point. It handles JWT authentication, rate limiting (100 req/min per user), and routes requests to the appropriate microservice. For internal service-to-service communication, I'll use gRPC with service discovery via Kubernetes DNS."

## 4. Revision Checklist
- [ ] API Gateway: single entry point, handles auth, rate limiting, routing, SSL termination
- [ ] Service mesh: sidecar proxies for service-to-service communication (mTLS, retry, tracing)
- [ ] API Gateway = north-south (external). Service mesh = east-west (internal).
- [ ] Service discovery: client-side (Eureka), server-side (ALB), DNS-based (Kubernetes)
- [ ] Popular: Kong/Nginx (gateway), Istio/Envoy (mesh), Kubernetes DNS (discovery)

> 🔗 **See Also:** [02-system-design/04-api-design.md](04-api-design.md) for REST/gRPC API design. [02-system-design/06-resilience-patterns.md](06-resilience-patterns.md) for circuit breakers in service mesh.
