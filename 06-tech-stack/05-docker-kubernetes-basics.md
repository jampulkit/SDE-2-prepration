# Docker & Kubernetes Basics

## 1. What & Why

**Docker packages your application with all its dependencies into a portable container. Kubernetes orchestrates those containers at scale — handling deployment, scaling, self-healing, and service discovery. Together, they're the foundation of modern cloud-native deployment.**

💡 **Intuition — Why Containers?** Before Docker: "It works on my machine but not in production" (different OS, different Java version, different library versions). With Docker: your app runs in the exact same environment everywhere — your laptop, CI/CD, staging, production. The container IS the deployment unit.

💡 **Intuition — Why Kubernetes?** Docker runs one container on one machine. But in production, you have hundreds of containers across dozens of machines. Kubernetes answers: Which machine runs which container? What if a container crashes? How do containers find each other? How do you roll out updates without downtime?

> 🔗 **See Also:** [02-system-design/01-fundamentals.md](../02-system-design/01-fundamentals.md) for scaling patterns (horizontal scaling = more containers). [06-tech-stack/04-spring-boot.md](04-spring-boot.md) for building Spring Boot apps that run in containers.

## 2. Docker Core Concepts

**Image:** Read-only template with application + dependencies. Built from Dockerfile.
**Container:** Running instance of an image. Isolated process with its own filesystem, network.
**Dockerfile:**
```dockerfile
FROM openjdk:21-slim
WORKDIR /app
COPY target/myapp.jar app.jar
EXPOSE 8080
ENTRYPOINT ["java", "-jar", "app.jar"]
```

**Multi-stage Dockerfile** [🔥 Must Know] (smaller image, no build tools in production):
```dockerfile
# Stage 1: Build
FROM maven:3.9-eclipse-temurin-21 AS build
WORKDIR /app
COPY pom.xml .
RUN mvn dependency:go-offline          # cache dependencies
COPY src ./src
RUN mvn package -DskipTests

# Stage 2: Run (only JRE, no Maven/source code)
FROM eclipse-temurin:21-jre-alpine
WORKDIR /app
COPY --from=build /app/target/myapp.jar app.jar
EXPOSE 8080
ENTRYPOINT ["java", "-jar", "app.jar"]

# Result: ~200MB image instead of ~800MB (no Maven, no source, no JDK)
```

**Key commands:**
```bash
docker build -t myapp:1.0 .
docker run -d -p 8080:8080 myapp:1.0
docker ps                    # list running containers
docker logs <container_id>
docker exec -it <id> /bin/sh # shell into container
docker-compose up -d         # multi-container setup
```

**Docker Compose:** Define multi-container apps in `docker-compose.yml`:
```yaml
services:
  app:
    build: .
    ports: ["8080:8080"]
    depends_on: [db, redis]
  db:
    image: postgres:15
    environment:
      POSTGRES_DB: mydb
  redis:
    image: redis:7
```

## 3. Kubernetes Core Concepts [🔥 Must Know]

**Pod:** Smallest deployable unit. One or more containers sharing network/storage.
**Deployment:** Manages pod replicas, rolling updates, rollbacks.
**Service:** Stable network endpoint for pods (ClusterIP, NodePort, LoadBalancer).
**Ingress:** HTTP routing rules (path-based, host-based) to services.
**ConfigMap / Secret:** External configuration and sensitive data.
**Namespace:** Logical isolation within a cluster.

**Key resources:**
```yaml
# Deployment with health checks, resource limits
apiVersion: apps/v1
kind: Deployment
metadata:
  name: myapp
spec:
  replicas: 3
  selector:
    matchLabels:
      app: myapp
  template:
    metadata:
      labels:
        app: myapp
    spec:
      containers:
      - name: myapp
        image: myapp:1.0
        ports:
        - containerPort: 8080
        resources:
          requests: { cpu: "250m", memory: "256Mi" }   # minimum guaranteed
          limits: { cpu: "500m", memory: "512Mi" }     # maximum allowed
        livenessProbe:          # restart container if this fails
          httpGet:
            path: /actuator/health/liveness
            port: 8080
          initialDelaySeconds: 30
          periodSeconds: 10
        readinessProbe:         # remove from service if this fails
          httpGet:
            path: /actuator/health/readiness
            port: 8080
          initialDelaySeconds: 10
          periodSeconds: 5
        env:
        - name: SPRING_PROFILES_ACTIVE
          value: "prod"
        - name: DB_PASSWORD
          valueFrom:
            secretKeyRef:
              name: db-credentials
              key: password
---
# Service
apiVersion: v1
kind: Service
metadata:
  name: myapp-service
spec:
  selector:
    app: myapp
  ports:
  - port: 80
    targetPort: 8080
  type: LoadBalancer
---
# Horizontal Pod Autoscaler
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: myapp-hpa
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: myapp
  minReplicas: 3
  maxReplicas: 20
  metrics:
  - type: Resource
    resource:
      name: cpu
      target:
        type: Utilization
        averageUtilization: 70    # scale up when avg CPU > 70%
```

**Health checks explained** [🔥 Must Know]:

| Probe | Question | On Failure | Example |
|-------|----------|-----------|---------|
| **Liveness** | "Is the process alive?" | Restart container | App is deadlocked, infinite loop |
| **Readiness** | "Can it handle requests?" | Remove from Service (no traffic) | DB connection lost, warming up cache |
| **Startup** | "Has it finished starting?" | Don't check liveness yet | Slow-starting apps (loading large models) |

**Resource requests vs limits:**

```
requests: guaranteed minimum. Kubernetes uses this for scheduling.
  "This pod needs at least 250m CPU and 256Mi memory to run."
  Scheduler places pod on a node with enough free requested resources.

limits: maximum allowed. Container is throttled (CPU) or killed (memory) if exceeded.
  "This pod can use at most 500m CPU and 512Mi memory."
  CPU: throttled (slowed down). Memory: OOMKilled (container restarted).

Best practice:
  Set requests = typical usage (for accurate scheduling)
  Set limits = peak usage (prevent runaway containers)
  Memory limit should be >= JVM max heap (-Xmx) + overhead (~256Mi)
```

**Service types:**

| Type | Scope | How | Use Case |
|------|-------|-----|----------|
| ClusterIP | Internal only | Virtual IP inside cluster | Service-to-service communication |
| NodePort | External via node IP | Opens port 30000-32767 on every node | Development, testing |
| LoadBalancer | External via cloud LB | Provisions cloud load balancer (AWS ALB/NLB) | Production external traffic |

**ConfigMaps and Secrets:**

```yaml
# ConfigMap: non-sensitive configuration
apiVersion: v1
kind: ConfigMap
metadata:
  name: app-config
data:
  CACHE_TTL: "300"
  LOG_LEVEL: "INFO"

# Secret: sensitive data (base64 encoded, encrypted at rest in etcd)
apiVersion: v1
kind: Secret
metadata:
  name: db-credentials
type: Opaque
data:
  username: cG9zdGdyZXM=    # base64("postgres")
  password: c2VjcmV0MTIz    # base64("secret123")
```

**Key commands:**
```bash
kubectl get pods
kubectl describe pod <name>
kubectl logs <pod-name>
kubectl apply -f deployment.yaml
kubectl scale deployment myapp --replicas=5
kubectl rollout status deployment/myapp
```

## 8. Must-Know Interview Questions

1. [🔥 Must Know] **Q:** What is a container? How is it different from a VM? **A:** Container shares host OS kernel, lightweight (MB), starts in seconds. VM has its own OS, heavy (GB), starts in minutes. Containers provide process isolation, not hardware isolation.
2. [🔥 Must Know] **Q:** What is a Kubernetes Pod? **A:** Smallest deployable unit. One or more containers sharing network namespace and storage volumes. Usually one container per pod.
3. [🔥 Must Know] **Q:** How does Kubernetes handle scaling? **A:** Horizontal Pod Autoscaler (HPA) scales pods based on CPU/memory metrics. Deployment manages replica count. Cluster Autoscaler adds/removes nodes.
4. **Q:** What is a Kubernetes Service? **A:** Stable network endpoint for a set of pods. Provides load balancing and service discovery. Types: ClusterIP (internal), NodePort (external port), LoadBalancer (cloud LB).

## 9. Revision Checklist
- [ ] Docker: image (template) → container (running instance)
- [ ] Dockerfile: FROM, COPY, RUN, EXPOSE, ENTRYPOINT
- [ ] K8s Pod: smallest unit, one+ containers, shared network
- [ ] K8s Deployment: manages replicas, rolling updates
- [ ] K8s Service: stable endpoint, load balancing (ClusterIP, NodePort, LoadBalancer)
- [ ] Container vs VM: shared kernel vs own OS, lightweight vs heavy
- [ ] HPA: auto-scale pods based on metrics
