# AWS Services — Interview Perspective

> Not a tutorial. This is "when would you use X vs Y?" for system design interviews.

## Core Compute

| Service | What | When to Use in SD Interview |
|---------|------|----------------------------|
| **EC2** | Virtual machines | "We need full control over the server." Long-running services, custom runtimes. |
| **ECS/EKS** | Container orchestration | "We'll containerize with Docker, orchestrate with ECS (simpler) or EKS (Kubernetes)." Default for microservices. |
| **Lambda** | Serverless functions | Event-driven, short tasks (<15 min). Image processing, webhooks, cron jobs. NOT for: long-running, high-throughput, stateful. |
| **Fargate** | Serverless containers | ECS without managing EC2 instances. Good default when you don't need GPU or custom AMIs. |

**Interview tip:** "I'd deploy as containers on ECS/Fargate" is the safe default for any microservice. Use Lambda only for event-driven glue (S3 trigger → process image → write to DB).

## Storage

| Service | What | When |
|---------|------|------|
| **S3** | Object storage | Files, images, videos, backups, static assets. 99.999999999% durability. Always the answer for "where do you store files?" |
| **EBS** | Block storage (disk) | EC2 instance disk. Database storage. |
| **EFS** | Shared file system | Multiple EC2 instances need to read/write same files. |

**S3 tiers:** Standard (frequent access) → IA (infrequent) → Glacier (archive, minutes-hours retrieval) → Glacier Deep Archive (12-hour retrieval). Use lifecycle policies to auto-transition.

## Databases

| Service | Type | When |
|---------|------|------|
| **RDS** (PostgreSQL/MySQL) | Managed relational | ACID transactions, joins, complex queries. Payments, orders, user accounts. |
| **Aurora** | Enhanced RDS | 5x MySQL / 3x PostgreSQL performance. Auto-scaling read replicas. When RDS isn't enough. |
| **DynamoDB** | Key-value / document | High throughput, simple access patterns, auto-scaling. Session store, user profiles, gaming leaderboards. |
| **ElastiCache** (Redis/Memcached) | In-memory cache | Caching, session store, rate limiting, leaderboards. Redis for data structures, Memcached for simple caching. |
| **Redshift** | Data warehouse | Analytics, OLAP queries on huge datasets. NOT for transactional workloads. |
| **Neptune** | Graph database | Social networks, recommendation engines, fraud detection. |

**Interview decision tree:**
```
Need ACID + joins? → RDS/Aurora (PostgreSQL)
Simple key-value at scale? → DynamoDB
Full-text search? → OpenSearch (Elasticsearch)
Caching? → ElastiCache (Redis)
Analytics on huge data? → Redshift
Graph relationships? → Neptune
```

## Messaging & Streaming

| Service | What | When |
|---------|------|------|
| **SQS** | Message queue | Simple async task processing. Decouple services. Dead letter queue. |
| **SNS** | Pub/sub notifications | Fan-out: one message → multiple subscribers (SQS, Lambda, email, SMS). |
| **Kinesis** | Real-time streaming | High-throughput event streaming. Alternative to Kafka. Log aggregation, clickstream. |
| **MSK** | Managed Kafka | When you need Kafka specifically (replay, consumer groups, exactly-once). |
| **EventBridge** | Event bus | Event-driven architecture. Route events between AWS services with rules. |

**SQS vs Kafka/Kinesis:**
```
SQS: simple, no ordering (FIFO available), message deleted after consumption, no replay.
     Use for: task queues, job processing, simple decoupling.
Kafka/Kinesis: ordered per partition, retained, replayable, multiple consumer groups.
     Use for: event sourcing, stream processing, audit trail, high throughput.
```

## Networking & Content Delivery

| Service | What | When |
|---------|------|------|
| **CloudFront** | CDN | Static assets, images, videos. Cache at edge. Always use for media-heavy apps. |
| **Route 53** | DNS | Domain management, health checks, latency-based routing, failover. |
| **API Gateway** | Managed API gateway | REST/WebSocket APIs. Rate limiting, auth, throttling. Good for Lambda backends. |
| **ALB/NLB** | Load balancer | ALB: HTTP/HTTPS (path-based routing). NLB: TCP/UDP (ultra-low latency). |
| **VPC** | Virtual network | Isolate resources. Public/private subnets. Security groups. |

## Monitoring & Security

| Service | What | When |
|---------|------|------|
| **CloudWatch** | Metrics, logs, alarms | Default monitoring. Custom metrics. Log aggregation. Alerting. |
| **X-Ray** | Distributed tracing | Trace requests across microservices. Find latency bottlenecks. |
| **IAM** | Identity & access | Roles, policies, least-privilege access. Every AWS resource uses IAM. |
| **KMS** | Key management | Encrypt data at rest (S3, RDS, DynamoDB). Manage encryption keys. |
| **Secrets Manager** | Secret storage | DB passwords, API keys, tokens. Auto-rotation. |
| **WAF** | Web application firewall | Protect against SQL injection, XSS, DDoS at CloudFront/ALB level. |

## Common Architecture Patterns

### Web App (Default)
```
Route 53 → CloudFront (static) → ALB → ECS/Fargate → RDS + ElastiCache
```

### Event-Driven
```
API Gateway → Lambda → SQS → Lambda (processor) → DynamoDB
                    → SNS → fan-out to multiple SQS queues
```

### Real-Time Streaming
```
Producers → MSK (Kafka) → Lambda/ECS consumers → S3/DynamoDB/OpenSearch
```

### Media-Heavy (Instagram/YouTube)
```
Client → S3 (presigned URL upload) → Lambda (trigger) → MediaConvert (transcode)
  → S3 (output) → CloudFront (CDN) → Client
```

## Must-Know Interview Questions

1. **"SQS vs Kafka?"** → SQS: simple, managed, no replay. Kafka: ordered, replayable, high throughput, multiple consumers.
2. **"When would you use DynamoDB vs RDS?"** → DynamoDB: simple access patterns, massive scale, auto-scaling. RDS: complex queries, joins, ACID transactions.
3. **"How do you handle file uploads?"** → Presigned S3 URL. Client uploads directly to S3 (bypasses your servers). Lambda trigger for post-processing.
4. **"How do you secure inter-service communication?"** → VPC (private subnets), security groups, IAM roles (no hardcoded credentials), mTLS for service mesh.
5. **"How do you handle secrets?"** → Secrets Manager with auto-rotation. Never in code, env vars, or config files committed to git.
