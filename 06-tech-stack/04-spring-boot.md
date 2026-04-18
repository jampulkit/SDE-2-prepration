# Spring Boot

## 1. What & Why

**Spring Boot is the de facto standard for building Java backend services. It simplifies Spring with auto-configuration, embedded servers, and opinionated defaults — letting you focus on business logic instead of boilerplate. As a Java backend engineer, this is your primary framework.**

💡 **Intuition — Why Spring Boot Over Plain Spring:** Plain Spring requires extensive XML/Java configuration (datasource, transaction manager, web server, security). Spring Boot auto-configures all of this based on your classpath. Add `spring-boot-starter-web` → you get an embedded Tomcat, Jackson for JSON, and Spring MVC configured automatically. Add `spring-boot-starter-data-jpa` → you get Hibernate, connection pooling, and transaction management.

> 🔗 **See Also:** [04-lld/01-solid-principles.md](../04-lld/01-solid-principles.md) for DIP (Spring Boot IS dependency injection). [05-java/01-core-java.md](../05-java/01-core-java.md) for Java fundamentals used in Spring. [02-system-design/04-api-design.md](../02-system-design/04-api-design.md) for REST API design patterns implemented in Spring.

## 2. Core Concepts

### Key Annotations [🔥 Must Know]
```java
@SpringBootApplication  // = @Configuration + @EnableAutoConfiguration + @ComponentScan
@RestController          // = @Controller + @ResponseBody
@Service                 // Business logic layer
@Repository              // Data access layer (translates DB exceptions)
@Component               // Generic Spring-managed bean
@Autowired               // Dependency injection (prefer constructor injection)
@Value("${property}")    // Inject config value
@Configuration           // Java-based config class
@Bean                    // Method produces a Spring-managed bean
```

### Dependency Injection [🔥 Must Know]
```java
@Service
public class OrderService {
    private final OrderRepository repository;
    private final PaymentService paymentService;

    // Constructor injection (preferred — immutable, testable)
    public OrderService(OrderRepository repository, PaymentService paymentService) {
        this.repository = repository;
        this.paymentService = paymentService;
    }
}
```

### Bean Scopes
- `singleton` (default): one instance per Spring container
- `prototype`: new instance per injection point
- `request`: one per HTTP request (web apps)
- `session`: one per HTTP session (web apps)

### Bean Lifecycle [🔥 Must Know]

```
1. Instantiation: Spring creates the bean (constructor call)
2. Populate properties: inject dependencies (@Autowired, constructor args)
3. BeanNameAware, BeanFactoryAware: set bean name, factory reference
4. @PostConstruct: custom initialization logic (runs AFTER injection)
5. InitializingBean.afterPropertiesSet(): alternative to @PostConstruct
6. Bean is READY — application uses it
7. @PreDestroy: cleanup logic (close connections, release resources)
8. DisposableBean.destroy(): alternative to @PreDestroy

Common use:
  @PostConstruct → warm up cache, validate config, start background tasks
  @PreDestroy → close DB connections, flush buffers, shutdown executors
```

```java
@Service
public class CacheService {
    private Map<String, Object> cache;
    
    @PostConstruct
    public void init() {
        cache = new ConcurrentHashMap<>();
        loadCacheFromDB(); // warm up cache on startup
    }
    
    @PreDestroy
    public void cleanup() {
        cache.clear();
        log.info("Cache cleared on shutdown");
    }
}
```

### How @Transactional Works [🔥 Must Know]

**Spring uses AOP proxies to wrap @Transactional methods. The proxy starts a transaction before the method, commits on success, and rolls back on exception.**

```
Call flow:
  Caller → [Spring Proxy] → Actual Bean Method
                ↓
           1. Get DB connection from pool
           2. BEGIN TRANSACTION
           3. Call actual method
           4. If success: COMMIT
           5. If RuntimeException: ROLLBACK
           6. Return connection to pool
```

⚠️ **Common Pitfall, Self-Invocation:**

```java
@Service
public class OrderService {
    
    @Transactional
    public void processOrder(Order order) {
        saveOrder(order);
        sendNotification(order); // calling another method in SAME class
    }
    
    @Transactional(propagation = Propagation.REQUIRES_NEW)
    public void sendNotification(Order order) {
        // THIS DOES NOT GET ITS OWN TRANSACTION!
        // Self-invocation bypasses the proxy → @Transactional is ignored
    }
}

// Fix: inject self, or extract to a separate service
@Service
public class OrderService {
    private final NotificationService notificationService; // separate bean
    
    @Transactional
    public void processOrder(Order order) {
        saveOrder(order);
        notificationService.sendNotification(order); // goes through proxy ✓
    }
}
```

**@Transactional attributes:**

| Attribute | Default | What It Does |
|-----------|---------|-------------|
| `propagation` | REQUIRED | Join existing transaction or create new |
| `isolation` | DEFAULT (DB default) | Transaction isolation level |
| `readOnly` | false | Hint for optimization (no dirty checking) |
| `rollbackFor` | RuntimeException | Which exceptions trigger rollback |
| `timeout` | -1 (no timeout) | Max seconds before timeout |

### @Async (Asynchronous Execution)

```java
@Configuration
@EnableAsync
public class AsyncConfig {
    @Bean
    public Executor taskExecutor() {
        ThreadPoolTaskExecutor executor = new ThreadPoolTaskExecutor();
        executor.setCorePoolSize(5);
        executor.setMaxPoolSize(10);
        executor.setQueueCapacity(100);
        executor.setThreadNamePrefix("async-");
        return executor;
    }
}

@Service
public class EmailService {
    @Async
    public CompletableFuture<Void> sendEmail(String to, String body) {
        // runs in a separate thread from the task executor
        emailClient.send(to, body);
        return CompletableFuture.completedFuture(null);
    }
}
```

⚠️ **Common Pitfall:** @Async has the same self-invocation problem as @Transactional. Calling an @Async method from within the same class bypasses the proxy and runs synchronously.

### Spring Boot Actuator [🔥 Must Know]

```yaml
# application.yml
management:
  endpoints:
    web:
      exposure:
        include: health, metrics, info, prometheus
  endpoint:
    health:
      show-details: always
```

| Endpoint | What | Use For |
|----------|------|---------|
| `/actuator/health` | Application health status | Kubernetes liveness/readiness probes |
| `/actuator/metrics` | JVM, HTTP, custom metrics | Monitoring dashboards |
| `/actuator/prometheus` | Metrics in Prometheus format | Prometheus scraping |
| `/actuator/info` | Build info, git commit | Deployment verification |

### REST API with Spring Boot
```java
@RestController
@RequestMapping("/api/v1/users")
public class UserController {
    private final UserService userService;

    @GetMapping("/{id}")
    public ResponseEntity<User> getUser(@PathVariable Long id) {
        return userService.findById(id)
            .map(ResponseEntity::ok)
            .orElse(ResponseEntity.notFound().build());
    }

    @PostMapping
    public ResponseEntity<User> createUser(@Valid @RequestBody CreateUserRequest request) {
        User user = userService.create(request);
        return ResponseEntity.status(HttpStatus.CREATED).body(user);
    }
}
```

### Spring Data JPA
```java
@Entity
@Table(name = "users")
public class User {
    @Id @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;
    private String name;
    @Column(unique = true)
    private String email;
}

public interface UserRepository extends JpaRepository<User, Long> {
    Optional<User> findByEmail(String email);
    List<User> findByNameContaining(String name);
}
```

### Exception Handling
```java
@RestControllerAdvice
public class GlobalExceptionHandler {
    @ExceptionHandler(ResourceNotFoundException.class)
    public ResponseEntity<ErrorResponse> handleNotFound(ResourceNotFoundException ex) {
        return ResponseEntity.status(404).body(new ErrorResponse(ex.getMessage()));
    }
}
```

### Profiles & Configuration
```yaml
# application.yml
spring:
  profiles:
    active: dev
---
spring.config.activate.on-profile: dev
server.port: 8080
---
spring.config.activate.on-profile: prod
server.port: 80
```

## 8. Must-Know Interview Questions

1. [🔥 Must Know] **Q:** What is Spring Boot auto-configuration? **A:** Automatically configures beans based on classpath dependencies. E.g., if H2 is on classpath, auto-configures an in-memory database. Driven by `@Conditional` annotations (e.g., `@ConditionalOnClass`, `@ConditionalOnMissingBean`).
2. [🔥 Must Know] **Q:** What is the difference between @Component, @Service, @Repository? **A:** Functionally similar (all are Spring beans). Semantic difference: @Service for business logic, @Repository for data access (adds exception translation). @Component is generic.
3. [🔥 Must Know] **Q:** Constructor vs field injection? **A:** Constructor: preferred — immutable, required dependencies explicit, easy to test. Field: convenient but harder to test, hides dependencies.
4. [🔥 Must Know] **Q:** What is Spring Boot Actuator? **A:** Production-ready features: health checks, metrics, info endpoints. `/actuator/health`, `/actuator/metrics`.
5. [🔥 Must Know] **Q:** Why does @Transactional not work on private methods or self-invocation? **A:** Spring uses AOP proxies. Private methods can't be proxied. Self-invocation (`this.method()`) bypasses the proxy — the call goes directly to the target object, not through the proxy.
6. [🔥 Must Know] **Q:** What is the N+1 query problem and how do you fix it? **A:** 1 query for parent + N queries for children. Fix: `JOIN FETCH` in JPQL, `@EntityGraph`, or `@BatchSize` annotation.
7. [🔥 Must Know] **Q:** How does Spring Boot handle connection pooling? **A:** HikariCP is the default. Maintains a pool of reusable DB connections. Key settings: `maximum-pool-size` (default 10), `connection-timeout`, `max-lifetime`.
8. [🔥 Must Know] **Q:** Explain @Transactional propagation levels. **A:** REQUIRED (default): join existing or create new. REQUIRES_NEW: always create new (suspend existing). NESTED: savepoint within existing. SUPPORTS: use existing if available, else non-transactional.
9. [🔥 Must Know] **Q:** How do you handle exceptions in Spring Boot REST APIs? **A:** `@RestControllerAdvice` + `@ExceptionHandler` for global handling. Return proper HTTP status codes and error response bodies.
10. [🔥 Must Know] **Q:** What is the request lifecycle in Spring MVC? **A:** Request → DispatcherServlet → HandlerMapping (find controller) → HandlerAdapter → Controller method → ViewResolver (or @ResponseBody → HttpMessageConverter for JSON) → Response.

## Additional Deep-Dive Topics

### @Transactional Propagation Levels [🔥 Must Know]

```java
// REQUIRED (default): join existing transaction, or create new if none exists
@Transactional(propagation = Propagation.REQUIRED)
public void methodA() { ... }

// REQUIRES_NEW: ALWAYS create a new transaction. Suspend the existing one.
// Use case: audit logging that must persist even if outer transaction rolls back
@Transactional(propagation = Propagation.REQUIRES_NEW)
public void auditLog(String action) { ... }

// NESTED: create a savepoint within existing transaction. Rollback to savepoint on failure.
// Use case: partial rollback — try something, if it fails, continue with rest
@Transactional(propagation = Propagation.NESTED)
public void tryOptionalStep() { ... }

// SUPPORTS: use existing transaction if available, else run non-transactional
// MANDATORY: MUST run within existing transaction, throw exception if none
// NOT_SUPPORTED: suspend existing transaction, run non-transactional
// NEVER: throw exception if a transaction exists
```

**When to use what:**

| Propagation | Use Case |
|-------------|----------|
| REQUIRED | Default for most service methods |
| REQUIRES_NEW | Audit logs, notifications that must persist regardless of outer tx |
| NESTED | Try optional step, rollback just that step on failure |
| SUPPORTS | Read-only methods that can work with or without tx |

### Rollback Rules

```java
// By default: rollback on RuntimeException (unchecked), NOT on checked exceptions
@Transactional(rollbackFor = Exception.class)  // rollback on ALL exceptions
@Transactional(rollbackFor = {PaymentException.class, InventoryException.class})
@Transactional(noRollbackFor = EmailException.class)  // don't rollback for email failures
```

### Spring Security Basics [🔥 Must Know]

```java
@Configuration
@EnableWebSecurity
public class SecurityConfig {

    @Bean
    public SecurityFilterChain filterChain(HttpSecurity http) throws Exception {
        http
            .csrf(csrf -> csrf.disable())  // disable for REST APIs
            .authorizeHttpRequests(auth -> auth
                .requestMatchers("/api/public/**").permitAll()
                .requestMatchers("/api/admin/**").hasRole("ADMIN")
                .anyRequest().authenticated()
            )
            .sessionManagement(s -> s.sessionCreationPolicy(SessionCreationPolicy.STATELESS))
            .addFilterBefore(jwtFilter, UsernamePasswordAuthenticationFilter.class);
        return http.build();
    }
}

// JWT filter: extract token from Authorization header, validate, set SecurityContext
@Component
public class JwtAuthFilter extends OncePerRequestFilter {
    @Override
    protected void doFilterInternal(HttpServletRequest req, HttpServletResponse res,
                                     FilterChain chain) throws ServletException, IOException {
        String token = extractToken(req);  // from "Bearer <token>" header
        if (token != null && jwtUtil.validate(token)) {
            String username = jwtUtil.getUsername(token);
            var auth = new UsernamePasswordAuthenticationToken(username, null, authorities);
            SecurityContextHolder.getContext().setAuthentication(auth);
        }
        chain.doFilter(req, res);
    }
}
```

**Request flow with security:**
```
Request → Security Filter Chain → JWT Filter (validate token)
  → Authorization (check roles) → Controller → Service → Response
```

### HikariCP Connection Pooling [🔥 Must Know]

```yaml
# application.yml
spring:
  datasource:
    hikari:
      maximum-pool-size: 20       # max concurrent connections
      minimum-idle: 5             # keep 5 idle connections ready
      connection-timeout: 30000   # 30s max wait for connection
      idle-timeout: 600000        # 10min before idle connection is closed
      max-lifetime: 1800000       # 30min max connection lifetime
      leak-detection-threshold: 60000  # warn if connection not returned in 60s
```

**Sizing rule of thumb:**
```
pool_size = (core_count * 2) + effective_spindle_count
For SSD: pool_size ≈ 10-20
For most apps: 20 is a good default

Too small → requests wait for connections (connection-timeout errors)
Too large → DB overwhelmed with connections (context switching, memory)
```

### Testing [🔥 Must Know]

```java
// Unit test (mock dependencies)
@ExtendWith(MockitoExtension.class)
class OrderServiceTest {
    @Mock private OrderRepository orderRepo;
    @Mock private PaymentService paymentService;
    @InjectMocks private OrderService orderService;

    @Test
    void shouldCreateOrder() {
        when(orderRepo.save(any())).thenReturn(new Order(1L, "CREATED"));
        Order result = orderService.create(new CreateOrderRequest(...));
        assertEquals("CREATED", result.getStatus());
        verify(paymentService, never()).charge(any()); // not called yet
    }
}

// Integration test (real Spring context, test DB)
@SpringBootTest
@AutoConfigureMockMvc
class OrderControllerIT {
    @Autowired private MockMvc mockMvc;

    @Test
    void shouldReturn201OnCreate() throws Exception {
        mockMvc.perform(post("/api/v1/orders")
                .contentType(MediaType.APPLICATION_JSON)
                .content("{\"product_id\": 1, \"quantity\": 2}"))
            .andExpect(status().isCreated())
            .andExpect(jsonPath("$.status").value("CREATED"));
    }
}

// Slice tests (load only relevant part of context)
@WebMvcTest(OrderController.class)     // only web layer, mock services
@DataJpaTest                            // only JPA layer, in-memory DB
```

| Test Type | Annotation | What It Loads | Speed |
|-----------|-----------|---------------|-------|
| Unit | `@ExtendWith(MockitoExtension.class)` | Nothing (pure Java) | Fastest |
| Web slice | `@WebMvcTest` | Controllers + filters only | Fast |
| JPA slice | `@DataJpaTest` | Repositories + in-memory DB | Medium |
| Full integration | `@SpringBootTest` | Entire context | Slowest |

## 9. Revision Checklist
- [ ] @SpringBootApplication = @Configuration + @EnableAutoConfiguration + @ComponentScan
- [ ] Constructor injection preferred (immutable, testable)
- [ ] Bean scopes: singleton (default), prototype, request, session
- [ ] Spring Data JPA: extend JpaRepository, method name queries
- [ ] @RestControllerAdvice for global exception handling
- [ ] Profiles: application-{profile}.yml, spring.profiles.active
- [ ] Actuator: /health, /metrics, /info
