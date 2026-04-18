# Design Patterns

## 1. What & Why

**Design patterns are reusable solutions to common software design problems — they give you a shared vocabulary and proven approaches for structuring code.**

For SDE-2 interviews, you need to know the most common patterns, when to apply them, and how they relate to SOLID principles. You won't be asked "implement the Observer pattern" directly — instead, your LLD solution should naturally use the right patterns.

💡 **Intuition — Patterns as Building Blocks:** Just as an architect uses standard elements (arches, columns, beams) to build different buildings, a software engineer uses patterns (Strategy, Observer, Factory) to build different systems. The pattern isn't the solution — it's a tool you apply when the problem fits.

**How patterns map to SOLID:**
- Strategy → OCP + DIP (new algorithms without modifying client)
- Observer → OCP (new observers without modifying subject)
- Factory → DIP (decouple creation from usage)
- Decorator → OCP (add behavior without modifying class)
- State → OCP (new states without modifying context)

> 🔗 **See Also:** [04-lld/01-solid-principles.md](01-solid-principles.md) for the principles these patterns implement.

## 2. Core Concepts

### Creational Patterns

**Singleton** [🔥 Must Know]: Ensure a class has only one instance globally.

💡 **When to use:** Database connection pool, logger, configuration manager — resources that should be shared, not duplicated.

```java
// Thread-safe Singleton (double-checked locking)
public class DatabaseConnection {
    private static volatile DatabaseConnection instance; // volatile prevents instruction reordering
    private DatabaseConnection() {} // private constructor prevents external instantiation
    
    public static DatabaseConnection getInstance() {
        if (instance == null) {                          // first check (no lock)
            synchronized (DatabaseConnection.class) {    // lock only when needed
                if (instance == null) {                  // second check (with lock)
                    instance = new DatabaseConnection();
                }
            }
        }
        return instance;
    }
}

// Modern Java: enum singleton (simplest, thread-safe, serialization-safe)
public enum DatabaseConnection {
    INSTANCE;
    public void query(String sql) { /* ... */ }
}
// Usage: DatabaseConnection.INSTANCE.query("SELECT ...");
```

⚠️ **Common Pitfall:** Singleton makes testing hard (global state, can't mock easily). In modern Java, prefer dependency injection (Spring `@Bean` with default singleton scope) over the classic Singleton pattern.

**Factory Method** [🔥 Must Know]: Create objects without specifying the exact class — the factory decides which class to instantiate based on input.

💡 **When to use:** When the exact type of object depends on runtime conditions (user input, configuration, environment).

```java
interface Notification { void send(String message); }
class EmailNotification implements Notification { public void send(String msg) { /* email */ } }
class SMSNotification implements Notification { public void send(String msg) { /* SMS */ } }
class PushNotification implements Notification { public void send(String msg) { /* push */ } }

class NotificationFactory {
    static Notification create(String channel) {
        return switch (channel) {
            case "email" -> new EmailNotification();
            case "sms" -> new SMSNotification();
            case "push" -> new PushNotification();
            default -> throw new IllegalArgumentException("Unknown channel: " + channel);
        };
    }
}
// Client code doesn't know about concrete classes — only the interface
Notification n = NotificationFactory.create("email");
n.send("Hello!");
```

**Builder** [🔥 Must Know]: Construct complex objects step by step with a fluent API.

💡 **When to use:** When a class has many parameters (especially optional ones). Avoids telescoping constructors and makes code readable.

```java
public class HttpRequest {
    private final String url;
    private final String method;
    private final Map<String, String> headers;
    private final String body;
    private final int timeout;

    private HttpRequest(Builder b) {
        this.url = b.url; this.method = b.method;
        this.headers = b.headers; this.body = b.body; this.timeout = b.timeout;
    }

    static class Builder {
        private final String url;          // required
        private String method = "GET";     // optional with default
        private Map<String, String> headers = new HashMap<>();
        private String body;
        private int timeout = 30000;

        Builder(String url) { this.url = url; }
        Builder method(String m) { method = m; return this; }
        Builder header(String k, String v) { headers.put(k, v); return this; }
        Builder body(String b) { body = b; return this; }
        Builder timeout(int t) { timeout = t; return this; }
        HttpRequest build() { return new HttpRequest(this); }
    }
}
// Usage: new HttpRequest.Builder("https://api.example.com")
//            .method("POST").header("Content-Type", "application/json")
//            .body("{\"key\":\"value\"}").timeout(5000).build();
```

**Java examples:** `StringBuilder`, `Stream.builder()`, Lombok `@Builder`.

### Structural Patterns

**Decorator** [🔥 Must Know]: Add behavior to objects dynamically by wrapping them — same interface, enhanced functionality.

💡 **When to use:** When you need to add features (logging, encryption, compression) to an object without modifying its class. Multiple decorators can be stacked.

```java
interface DataSource { String readData(); void writeData(String data); }

class FileDataSource implements DataSource {
    public String readData() { return readFromFile(); }
    public void writeData(String data) { writeToFile(data); }
}

// Decorator: adds encryption
class EncryptionDecorator implements DataSource {
    private final DataSource wrapped;
    EncryptionDecorator(DataSource source) { this.wrapped = source; }
    public String readData() { return decrypt(wrapped.readData()); }
    public void writeData(String data) { wrapped.writeData(encrypt(data)); }
}

// Decorator: adds compression
class CompressionDecorator implements DataSource {
    private final DataSource wrapped;
    CompressionDecorator(DataSource source) { this.wrapped = source; }
    public String readData() { return decompress(wrapped.readData()); }
    public void writeData(String data) { wrapped.writeData(compress(data)); }
}

// Stack decorators: file → compress → encrypt
DataSource source = new EncryptionDecorator(
                      new CompressionDecorator(
                        new FileDataSource("data.txt")));
source.writeData("secret"); // encrypts, then compresses, then writes to file
```

**Java examples:** `BufferedInputStream(new FileInputStream(...))`, `Collections.synchronizedList(...)`, `Collections.unmodifiableList(...)`.

**Adapter**: Convert one interface to another so incompatible classes can work together.

```java
// Legacy system returns XML, but our code expects JSON
interface JsonParser { String toJson(String data); }

class XmlToJsonAdapter implements JsonParser {
    private final LegacyXmlParser xmlParser = new LegacyXmlParser();
    public String toJson(String data) {
        String xml = xmlParser.parse(data);
        return convertXmlToJson(xml); // adapt XML output to JSON
    }
}
```

**Proxy**: Control access to an object — lazy loading, access control, logging, caching.

**Facade**: Simplified interface to a complex subsystem (e.g., a `PaymentFacade` that coordinates payment gateway, fraud check, and ledger).

### Behavioral Patterns

**Strategy** [🔥 Must Know]: Define a family of algorithms as separate classes, make them interchangeable at runtime.

💡 **When to use:** When you have multiple ways to do something (sort, pay, validate) and want to switch between them without changing the client code. This is OCP + DIP in action.

```java
// Strategy interface
interface PaymentStrategy { void pay(double amount); }

// Concrete strategies
class CreditCardPayment implements PaymentStrategy {
    public void pay(double amount) { /* charge credit card */ }
}
class UPIPayment implements PaymentStrategy {
    public void pay(double amount) { /* process UPI payment */ }
}
class WalletPayment implements PaymentStrategy {
    public void pay(double amount) { /* deduct from wallet */ }
}

// Context: uses a strategy without knowing which one
class PaymentProcessor {
    private PaymentStrategy strategy;
    PaymentProcessor(PaymentStrategy strategy) { this.strategy = strategy; }
    void processPayment(double amount) { strategy.pay(amount); }
    void setStrategy(PaymentStrategy s) { this.strategy = s; } // can change at runtime
}

// Usage:
PaymentProcessor processor = new PaymentProcessor(new CreditCardPayment());
processor.processPayment(100.0);
processor.setStrategy(new UPIPayment()); // switch strategy at runtime
processor.processPayment(50.0);
```

**Java examples:** `Comparator` (sorting strategy), `Runnable`/`Callable` (execution strategy).

**Observer** [🔥 Must Know]: When one object (subject) changes state, all registered observers are notified automatically.

💡 **When to use:** Event systems, pub-sub, UI updates, notification systems — any time multiple objects need to react to a change.

```java
// Observer interface
interface EventListener { void onEvent(String eventType, Object data); }

// Subject (event manager)
class EventManager {
    private final Map<String, List<EventListener>> listeners = new HashMap<>();

    void subscribe(String eventType, EventListener listener) {
        listeners.computeIfAbsent(eventType, k -> new ArrayList<>()).add(listener);
    }

    void unsubscribe(String eventType, EventListener listener) {
        listeners.getOrDefault(eventType, List.of()).remove(listener);
    }

    void publish(String eventType, Object data) {
        listeners.getOrDefault(eventType, List.of())
                 .forEach(l -> l.onEvent(eventType, data));
    }
}

// Concrete observers
class EmailAlert implements EventListener {
    public void onEvent(String type, Object data) { /* send email */ }
}
class LoggingListener implements EventListener {
    public void onEvent(String type, Object data) { /* log event */ }
}
```

**Java examples:** `PropertyChangeListener`, Kafka consumers, Spring `@EventListener`.

**State** [🔥 Must Know]: Object changes behavior when its internal state changes — like a state machine where each state is a separate class.

```java
interface OrderState {
    void next(Order order);
    void cancel(Order order);
}

class PendingState implements OrderState {
    public void next(Order order) { order.setState(new ProcessingState()); }
    public void cancel(Order order) { order.setState(new CancelledState()); }
}

class ProcessingState implements OrderState {
    public void next(Order order) { order.setState(new ShippedState()); }
    public void cancel(Order order) { /* can't cancel once processing */ throw new IllegalStateException(); }
}
```

💡 **When to use:** Vending machines, order workflows, elevator systems, traffic lights — any entity with distinct states and transitions.

**Command**: Encapsulate a request as an object — enables undo/redo, queuing, logging.

**Template Method**: Define algorithm skeleton in base class, let subclasses override specific steps.

## 3. Comparison Tables

| Pattern | Type | Problem It Solves | SOLID Principle | Java Example |
|---------|------|------------------|-----------------|--------------|
| Singleton | Creational | One global instance | — | `Runtime.getRuntime()` |
| Factory | Creational | Decouple creation from usage | DIP | `Calendar.getInstance()` |
| Builder | Creational | Complex object construction | — | `StringBuilder`, Lombok `@Builder` |
| Strategy | Behavioral | Interchangeable algorithms | OCP + DIP | `Comparator`, payment methods |
| Observer | Behavioral | Event notification | OCP | `PropertyChangeListener`, Kafka |
| Decorator | Structural | Add behavior dynamically | OCP | `BufferedInputStream` wrapping |
| Adapter | Structural | Interface compatibility | — | `Arrays.asList()` |
| State | Behavioral | State-dependent behavior | OCP | Order workflow, vending machine |
| Command | Behavioral | Encapsulate requests | SRP | Undo/redo, task queues |

**Pattern Selection Guide:**

```
Need to create objects without specifying class? → Factory
Need complex object with many params? → Builder
Need one global instance? → Singleton (or DI scope)
Need interchangeable algorithms? → Strategy
Need to react to state changes? → Observer
Need to add behavior without modifying class? → Decorator
Need to adapt incompatible interfaces? → Adapter
Need state-dependent behavior? → State
Need undo/redo or command queuing? → Command
```

## 4. Must-Know Interview Questions

1. [🔥 Must Know] **Q:** What design patterns have you used? **A:** Strategy (payment methods in our payment service), Observer (event-driven notifications), Builder (complex request objects), Factory (creating different notification types).
2. [🔥 Must Know] **Q:** Explain Strategy pattern. **A:** Define algorithms as separate classes implementing a common interface. Client chooses at runtime. Example: PaymentStrategy with CreditCard, UPI, Wallet implementations.
3. [🔥 Must Know] **Q:** Factory vs Builder? **A:** Factory: choose ONE of several types at creation time. Builder: construct ONE complex object step by step with many optional parameters.
4. [🔥 Must Know] **Q:** Observer pattern? **A:** One-to-many dependency. Subject maintains a list of observers. On state change, notifies all. Used in event systems, pub-sub, UI frameworks.
5. **Q:** Adapter vs Decorator? **A:** Adapter changes the INTERFACE (makes incompatible things work together). Decorator adds BEHAVIOR while keeping the same interface.
6. **Q:** When would you use State pattern? **A:** When an object's behavior depends on its state and transitions between states. Example: Order (Pending → Processing → Shipped → Delivered), Vending Machine, Elevator.

🎯 **Likely Follow-ups:**
- **Q:** How do you decide which pattern to use?
  **A:** Start from the problem, not the pattern. If you have multiple algorithms → Strategy. If you need to notify multiple objects → Observer. If object creation is complex → Factory/Builder. Don't force patterns — use them when the problem naturally fits.
- **Q:** Can you combine patterns?
  **A:** Yes, commonly. A Factory might create Strategy objects. An Observer might use the Command pattern to encapsulate notifications. The Decorator pattern is often combined with Factory (create decorated objects).

## 5. Revision Checklist

- [ ] Singleton: one instance, double-checked locking or enum. Prefer DI over classic singleton.
- [ ] Factory: create objects without specifying exact class. Decouples creation from usage.
- [ ] Builder: step-by-step construction, fluent API, for complex objects with many optional params.
- [ ] Strategy: interchangeable algorithms via interface. OCP + DIP. Example: Comparator, payment methods.
- [ ] Observer: subject notifies observers on state change. One-to-many. Example: event systems, Kafka.
- [ ] Decorator: wrap object to add behavior, same interface. Stackable. Example: InputStream wrappers.
- [ ] State: behavior changes with internal state. Each state is a class. Example: order workflow.
- [ ] Adapter: convert one interface to another. Example: legacy XML to JSON.
- [ ] Command: encapsulate request as object. Enables undo/redo, queuing.
- [ ] Know when to use each and real-world Java examples.
- [ ] Patterns implement SOLID: Strategy=OCP+DIP, Observer=OCP, Factory=DIP, Decorator=OCP.

> 🔗 **See Also:** All LLD problem files in [04-lld/problems/](problems/) use these patterns extensively. [05-java/05-java8-to-21-features.md](../05-java/05-java8-to-21-features.md) for functional interfaces that simplify Strategy and Observer patterns.
