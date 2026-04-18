# SOLID Principles

## 1. What & Why

**SOLID principles are five design principles that make software maintainable, extensible, and testable. They're the foundation of good object-oriented design and the first thing interviewers evaluate in LLD rounds.**

💡 **Intuition — Why SOLID Matters:** Without SOLID, code becomes a tangled mess where changing one thing breaks five others. SOLID principles create code that's like LEGO blocks — each piece has a clear purpose, pieces connect through standard interfaces, and you can add new pieces without breaking existing ones.

**In interviews:** You won't be asked "explain SOLID" directly. Instead, interviewers evaluate whether your LLD solution naturally follows these principles. A parking lot design that uses `if (vehicleType == "car")` everywhere violates OCP. An elevator system where one class handles everything violates SRP. Knowing SOLID means your designs are clean by default.

## 2. Core Concepts

### S — Single Responsibility Principle (SRP) [🔥 Must Know]

**A class should have only one reason to change — it should do one thing and do it well.**

💡 **Intuition:** If a class handles user authentication AND sends emails AND saves to the database, a change to the email format requires modifying the same class that handles authentication. These are unrelated concerns — they should be in separate classes.

```java
// BAD: UserService handles auth, email, and persistence (3 reasons to change)
class UserService {
    void authenticate(String user, String pass) { /* auth logic */ }
    void sendWelcomeEmail(String to) { /* email logic */ }
    void saveToDatabase(User user) { /* DB logic */ }
}
// Change email provider? Modify UserService.
// Change database? Modify UserService.
// Change auth logic? Modify UserService.
// All changes touch the same class → high risk of breaking unrelated features.

// GOOD: Each class has one responsibility (one reason to change)
class AuthService { void authenticate(String user, String pass) { /* auth only */ } }
class EmailService { void sendEmail(String to, String body) { /* email only */ } }
class UserRepository { void save(User user) { /* persistence only */ } }
```

**How to spot SRP violations:** If you can describe a class with "AND" — "this class authenticates users AND sends emails AND saves to DB" — it probably violates SRP.

### O — Open/Closed Principle (OCP) [🔥 Must Know]

**Open for extension, closed for modification — add new behavior by writing new code, not by changing existing code.**

💡 **Intuition:** Every time you modify existing code to add a feature, you risk breaking something that already works. OCP says: design your code so that new features are added by creating new classes/implementations, not by editing existing ones. Interfaces and abstract classes are the key tools.

```java
// BAD: Adding a new shape requires modifying AreaCalculator
class AreaCalculator {
    double calculate(Object shape) {
        if (shape instanceof Circle c) return Math.PI * c.radius * c.radius;
        if (shape instanceof Rectangle r) return r.width * r.height;
        // Adding Triangle? Must modify THIS method. Violates OCP.
    }
}

// GOOD: New shapes extend without modifying existing code
interface Shape { double area(); }

class Circle implements Shape {
    double radius;
    public double area() { return Math.PI * radius * radius; }
}

class Rectangle implements Shape {
    double width, height;
    public double area() { return width * height; }
}

// Adding Triangle: just implement Shape. ZERO changes to existing code.
class Triangle implements Shape {
    double base, height;
    public double area() { return 0.5 * base * height; }
}

// AreaCalculator works with ANY shape — past, present, and future
class AreaCalculator {
    double totalArea(List<Shape> shapes) {
        return shapes.stream().mapToDouble(Shape::area).sum();
    }
}
```

**How to spot OCP violations:** `if/else` chains or `switch` statements that check types. Every new type requires modifying the chain.

### L — Liskov Substitution Principle (LSP) [🔥 Must Know]

**Subtypes must be substitutable for their base types without breaking the program's correctness.**

💡 **Intuition:** If your code works with a `Bird` object, it should work with any subclass of `Bird` — `Sparrow`, `Eagle`, `Penguin`. But if `Penguin` throws an exception when you call `fly()`, it violates LSP because code expecting a `Bird` to fly will break.

```java
// BAD: Square violates LSP when substituted for Rectangle
class Rectangle {
    protected int width, height;
    void setWidth(int w) { width = w; }
    void setHeight(int h) { height = h; }
    int area() { return width * height; }
}

class Square extends Rectangle {
    // Square overrides to keep width == height
    void setWidth(int w) { width = height = w; }
    void setHeight(int h) { width = height = h; }
}

// This code works for Rectangle but BREAKS for Square:
void resize(Rectangle r) {
    r.setWidth(5);
    r.setHeight(10);
    assert r.area() == 50; // FAILS for Square! area = 100 (10×10)
}

// GOOD: Don't make Square extend Rectangle. Use a common interface.
interface Shape { double area(); }
class Rectangle implements Shape { /* width, height, area = w*h */ }
class Square implements Shape { /* side, area = side*side */ }
```

**How to spot LSP violations:** Subclass overrides a method to throw an exception, do nothing, or change the expected behavior. If you need to check `instanceof` before calling a method, LSP is likely violated.

### I — Interface Segregation Principle (ISP)

**Clients should not be forced to depend on interfaces they don't use. Split fat interfaces into smaller, focused ones.**

```java
// BAD: SimplePrinter is forced to implement fax() and scan() — it can't do those!
interface Machine { void print(); void scan(); void fax(); }
class SimplePrinter implements Machine {
    public void print() { /* works */ }
    public void scan() { throw new UnsupportedOperationException(); } // forced to implement!
    public void fax() { throw new UnsupportedOperationException(); }  // forced to implement!
}

// GOOD: Segregated interfaces — each class implements only what it can do
interface Printer { void print(); }
interface Scanner { void scan(); }
interface Fax { void fax(); }

class SimplePrinter implements Printer {
    public void print() { /* works */ }
    // No scan() or fax() — not forced to implement what it can't do
}

class MultiFunctionPrinter implements Printer, Scanner, Fax {
    public void print() { /* works */ }
    public void scan() { /* works */ }
    public void fax() { /* works */ }
}
```

**How to spot ISP violations:** Classes implementing methods that throw `UnsupportedOperationException` or have empty bodies.

### D — Dependency Inversion Principle (DIP) [🔥 Must Know]

**High-level modules should not depend on low-level modules. Both should depend on abstractions (interfaces).**

💡 **Intuition:** Your business logic (OrderService) shouldn't know or care whether data is stored in MySQL, MongoDB, or a file. It should depend on an abstract `OrderRepository` interface. The specific implementation (MySQLOrderRepository) is injected at runtime. This makes testing easy (inject a mock) and swapping implementations trivial.

```java
// BAD: OrderService directly depends on MySQL (tight coupling)
class OrderService {
    private MySQLDatabase db = new MySQLDatabase(); // hard-coded dependency
    void createOrder(Order order) { db.insert(order); }
}
// Can't test without a real MySQL database!
// Can't switch to MongoDB without modifying OrderService!

// GOOD: Depend on abstraction, inject implementation
interface OrderRepository { void save(Order order); Order findById(String id); }

class OrderService {
    private final OrderRepository repository; // depends on abstraction
    OrderService(OrderRepository repository) { this.repository = repository; } // injected!
    void createOrder(Order order) { repository.save(order); }
}

class MySQLOrderRepository implements OrderRepository { /* MySQL-specific */ }
class MongoOrderRepository implements OrderRepository { /* MongoDB-specific */ }
class InMemoryOrderRepository implements OrderRepository { /* for testing */ }

// Usage:
OrderService service = new OrderService(new MySQLOrderRepository()); // production
OrderService testService = new OrderService(new InMemoryOrderRepository()); // testing
```

**Dependency Injection (DI)** is the practical implementation of DIP. Spring Boot's `@Autowired` is DI in action.

🎯 **Likely Follow-ups:**
- **Q:** What's the difference between DIP and DI?
  **A:** DIP is the principle (depend on abstractions). DI is the technique (inject dependencies from outside). DIP tells you WHAT to do; DI tells you HOW.
- **Q:** How does Spring implement DI?
  **A:** Spring's IoC container creates objects and injects dependencies via constructor injection (`@Autowired`), setter injection, or field injection. Constructor injection is preferred (immutable, explicit dependencies).

## 3. Advanced Topics

**Composition over inheritance** [🔥 Must Know]:
Prefer composing objects (has-a) over class hierarchies (is-a). Inheritance creates tight coupling — changing the base class affects all subclasses. Composition is more flexible — swap behaviors at runtime.

```java
// Inheritance (fragile):
class Duck extends Bird { void fly() { /* duck flying */ } }
class RubberDuck extends Duck { void fly() { /* can't fly! */ } } // LSP violation

// Composition (flexible):
interface FlyBehavior { void fly(); }
class CanFly implements FlyBehavior { public void fly() { /* flying */ } }
class CantFly implements FlyBehavior { public void fly() { /* do nothing */ } }

class Duck {
    private FlyBehavior flyBehavior; // composed, not inherited
    Duck(FlyBehavior fb) { this.flyBehavior = fb; }
    void fly() { flyBehavior.fly(); }
}
// RubberDuck = new Duck(new CantFly()); — no inheritance needed!
```

**Tell, Don't Ask:** Objects should perform actions, not expose state for others to act on.
```java
// BAD (Ask): if (account.getBalance() > amount) account.setBalance(account.getBalance() - amount);
// GOOD (Tell): account.withdraw(amount); // account handles its own logic
```

**Law of Demeter:** Only talk to immediate friends. Don't chain: `order.getCustomer().getAddress().getCity()`. Instead: `order.getShippingCity()`.

> 🔗 **See Also:** [04-lld/02-design-patterns.md](02-design-patterns.md) for patterns that implement SOLID (Strategy = OCP+DIP, Observer = OCP, Factory = DIP). [06-tech-stack/04-spring-boot.md](../06-tech-stack/04-spring-boot.md) for DI in Spring Boot.

## 4. Comparison Tables

| Principle | One-liner | Violation Smell | Fix |
|-----------|-----------|-----------------|-----|
| SRP | One reason to change | God class, "and" in description | Split into focused classes |
| OCP | Extend without modifying | if/else type chains, switch on type | Use interfaces + polymorphism |
| LSP | Subtypes are substitutable | Override throws exception, instanceof checks | Redesign hierarchy, use composition |
| ISP | No fat interfaces | UnsupportedOperationException, empty methods | Split into smaller interfaces |
| DIP | Depend on abstractions | `new ConcreteClass()` in business logic | Constructor injection, interfaces |

## 5. Must-Know Interview Questions

1. [🔥 Must Know] **Q:** Explain SOLID with examples. **A:** One sentence per principle with a code smell and fix (use examples above).
2. [🔥 Must Know] **Q:** What is OCP? **A:** Open for extension, closed for modification. Use interfaces so new behavior = new class, not modified existing class.
3. [🔥 Must Know] **Q:** What is Dependency Injection? **A:** A form of DIP where dependencies are provided (injected) rather than created internally. Enables testing (mock) and flexibility (swap implementations).
4. **Q:** Give an LSP violation example. **A:** Square extending Rectangle — setWidth on Square changes height too, breaking Rectangle's contract.
5. [🔥 Must Know] **Q:** Why composition over inheritance? **A:** Inheritance = tight coupling, fragile hierarchies. Composition = flexible, swap behaviors at runtime, no LSP issues.
6. **Q:** How do you apply SOLID in a real project? **A:** SRP: separate services (auth, email, persistence). OCP: strategy pattern for varying behavior. DIP: repository interfaces, constructor injection. ISP: role-specific interfaces.

## 6. Hands-On Exercises
1. Refactor a God class (UserManager handling auth, profile, notifications) into SRP-compliant classes.
2. Design a notification system using OCP — support email, SMS, push without modifying existing code.
3. Implement a payment processor using DIP — abstract PaymentGateway with Stripe and PayPal implementations.

## 7. Revision Checklist
- [ ] SRP: one class, one responsibility, one reason to change. Smell: "and" in class description.
- [ ] OCP: extend via interfaces/polymorphism, don't modify existing code. Smell: if/else type chains.
- [ ] LSP: subtypes must honor base type's contract. Smell: instanceof checks, overrides that throw.
- [ ] ISP: small, focused interfaces. Smell: UnsupportedOperationException in implementations.
- [ ] DIP: depend on abstractions (interfaces), inject dependencies. Smell: `new ConcreteClass()` in business logic.
- [ ] Composition > inheritance: has-a over is-a, swap behaviors at runtime.
- [ ] Tell, Don't Ask: objects perform actions, don't expose state.
- [ ] Law of Demeter: don't chain method calls on returned objects.
