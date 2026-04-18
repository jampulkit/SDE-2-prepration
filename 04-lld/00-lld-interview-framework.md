# LLD Interview Framework

## 1. What Interviewers Evaluate at SDE-2

**LLD interviews test your ability to design clean, extensible, maintainable object-oriented systems. At SDE-2 level, interviewers expect you to naturally apply SOLID principles and design patterns without being prompted.**

| Criteria | SDE-1 | SDE-2 |
|----------|-------|-------|
| Class design | Basic classes with fields and methods | Clean abstractions, proper encapsulation |
| SOLID | Knows the acronym | Applies naturally (Strategy for varying behavior, Factory for creation) |
| Design patterns | Can name a few | Uses the right pattern for the right problem |
| Concurrency | Not expected | Thread safety for shared resources, race condition awareness |
| Extensibility | Not evaluated | "How would you add feature X?" should require zero changes to existing code |
| Trade-offs | Not expected | Articulates trade-offs between approaches |

## 2. The 5-Step Framework

### Step 1: Clarify Requirements (3-5 min)

Ask about scope, actors, core use cases, and constraints.

```
"Before I start designing, let me clarify the requirements."

Questions to ask:
- Who are the actors? (User, Admin, System)
- What are the core use cases? (List 4-6 main actions)
- What is NOT in scope? (Payments? Analytics? Notifications?)
- Scale: how many concurrent users/requests?
- Any real-time requirements?
```

### Step 2: Identify Entities and Actors (3-5 min)

List the core objects (nouns from requirements) and their relationships.

```
Parking Lot example:
  Entities: ParkingLot, ParkingFloor, ParkingSpot, Vehicle, Ticket, Payment
  Actors: Driver, Admin, System
  
  Relationships:
    ParkingLot 1──* ParkingFloor 1──* ParkingSpot
    Vehicle *──1 Ticket *──1 Payment
    ParkingSpot has-a SpotType (MOTORCYCLE, COMPACT, LARGE)
    Vehicle is-a hierarchy: Car, Motorcycle, Truck
```

### Step 3: Define Class Diagram (5-10 min)

Draw classes with key fields and methods. Use ASCII for speed.

```
+------------------+       +------------------+
| ParkingLot       |       | ParkingFloor     |
|------------------|       |------------------|
| - floors: List   |1────*| - spots: List    |
| + parkVehicle()  |       | + findSpot()     |
| + unparkVehicle()|       +------------------+
+------------------+              |1
                                  |
                                  *
                           +------------------+
                           | ParkingSpot      |
                           |------------------|
                           | - type: SpotType |
                           | - vehicle: Vehicle|
                           | + isAvailable()  |
                           | + park(Vehicle)  |
                           +------------------+
```

### Step 4: Apply Design Patterns (5-10 min)

Identify where patterns solve real problems (don't force patterns).

| Problem | Pattern | Example |
|---------|---------|---------|
| Multiple algorithms for same task | Strategy | Pricing strategies (hourly, daily, weekend) |
| Object creation depends on input | Factory | Create vehicle from type string |
| One-to-many notifications | Observer | Notify displays when spot status changes |
| Object with many optional fields | Builder | Complex configuration objects |
| State-dependent behavior | State | Order lifecycle (CREATED → PAID → SHIPPED) |
| Add behavior without modifying class | Decorator | Add logging, caching to a service |
| Single shared instance | Singleton | ParkingLot instance (use sparingly) |

### Step 5: Handle Concurrency and Edge Cases (5 min)

```
Concurrency:
- What if two drivers try to park in the same spot simultaneously?
  → Synchronize spot allocation (ConcurrentHashMap, synchronized block)
- What if payment fails after ticket is issued?
  → State machine: ticket stays in ACTIVE state until payment confirmed

Edge cases:
- Parking lot is full → return null or throw ParkingFullException
- Vehicle type doesn't fit any available spot → return appropriate error
- Ticket already used for exit → reject duplicate exit
```

## 3. Common Mistakes

| Mistake | Why It's Bad | Fix |
|---------|-------------|-----|
| God class (one class does everything) | Violates SRP, hard to extend | Split into focused classes |
| `if/else` chains for types | Violates OCP, must modify for new types | Use polymorphism or Strategy |
| Public fields | Breaks encapsulation | Private fields + getters, immutable where possible |
| No interfaces | Tight coupling, hard to test | Program to interfaces, inject dependencies |
| Ignoring concurrency | Race conditions in production | Identify shared mutable state, synchronize |
| Over-engineering | Too many patterns, too many abstractions | Apply patterns only when they solve a real problem |

## 4. How to Draw Class Diagrams Quickly (ASCII)

```
Inheritance (is-a):        Composition (has-a):       Interface:
  Vehicle                    ParkingLot                 <<interface>>
    ^                          |                        PricingStrategy
    |                          | 1                      + calculate(hours): double
  +---+---+                    |
  |       |                    * 
 Car   Truck               ParkingFloor
```

**Symbols:**
- `1──*` : one-to-many
- `1──1` : one-to-one
- `^` or `extends` : inheritance
- `<<interface>>` : interface
- `+` : public, `-` : private, `#` : protected

## 5. Time Allocation (35-45 min)

| Phase | Time | What to Deliver |
|-------|------|----------------|
| Requirements | 3-5 min | List of use cases, actors, scope |
| Entities | 3-5 min | Entity list with relationships |
| Class diagram | 5-10 min | ASCII diagram with key fields/methods |
| Design patterns | 5-10 min | Identify and apply 2-3 patterns |
| Implementation | 10-15 min | Core classes in Java (not all, focus on interesting parts) |
| Concurrency + edge cases | 5 min | Thread safety, error handling |

## 6. Revision Checklist

- [ ] 5 steps: requirements → entities → class diagram → patterns → concurrency
- [ ] SDE-2: naturally apply SOLID, articulate trade-offs, handle concurrency
- [ ] Strategy for varying algorithms, Factory for creation, Observer for notifications, State for lifecycle
- [ ] Don't force patterns. Apply only when they solve a real problem.
- [ ] Identify shared mutable state and synchronize it.
- [ ] Program to interfaces, not implementations. Constructor injection for dependencies.
- [ ] Common mistakes: god class, if/else chains, public fields, no interfaces

> 🔗 **See Also:** [04-lld/01-solid-principles.md](01-solid-principles.md) for SOLID with examples. [04-lld/02-design-patterns.md](02-design-patterns.md) for pattern implementations.
