# LLD: Elevator System

## 1. Problem Statement
Design an elevator system for a building with multiple elevators.

💡 **Why this is a top LLD problem:** It tests the State pattern (elevator states), Strategy pattern (scheduling algorithms), and concurrent request handling. The key challenge is the scheduling algorithm — how to efficiently assign requests to elevators.

🎯 **Key Follow-ups:** How do you handle peak hours (morning rush)? → Pre-position elevators at lobby. How do you handle VIP floors? → Priority queue for VIP requests. How do you handle fire emergency? → Override all elevators to ground floor.

> 🔗 **See Also:** [04-lld/02-design-patterns.md](../02-design-patterns.md) for State and Strategy patterns.

## 2. Requirements
- Multiple elevators, multiple floors
- Handle up/down requests from floors and floor requests from inside elevator
- Efficient scheduling (minimize wait time)
- Display current floor and direction

## 3. Entities & Relationships
```
Building 1──* Elevator
Elevator: currentFloor, direction, state, requestQueue
ElevatorController: manages all elevators, dispatches requests
Request: floor, direction (UP/DOWN)
```

## 4. Design Patterns Used
- **Strategy:** Elevator scheduling algorithm (SCAN, LOOK, nearest)
- **State:** Elevator states (IDLE, MOVING_UP, MOVING_DOWN, DOOR_OPEN)
- **Observer:** Notify display panels on floor/direction change

## 5. Complete Java Implementation

```java
enum Direction { UP, DOWN, IDLE }
enum ElevatorState { IDLE, MOVING, DOOR_OPEN }

class Request {
    final int floor;
    final Direction direction;
    Request(int floor, Direction direction) { this.floor = floor; this.direction = direction; }
}

class Elevator {
    private final int id;
    private int currentFloor = 0;
    private Direction direction = Direction.IDLE;
    private final TreeSet<Integer> upStops = new TreeSet<>();
    private final TreeSet<Integer> downStops = new TreeSet<>(Comparator.reverseOrder());

    Elevator(int id) { this.id = id; }

    void addStop(int floor) {
        if (floor > currentFloor) upStops.add(floor);
        else if (floor < currentFloor) downStops.add(floor);
    }

    void move() {
        if (direction == Direction.UP && !upStops.isEmpty()) {
            currentFloor = upStops.pollFirst();
        } else if (direction == Direction.DOWN && !downStops.isEmpty()) {
            currentFloor = downStops.pollFirst();
        } else if (!upStops.isEmpty()) {
            direction = Direction.UP;
            currentFloor = upStops.pollFirst();
        } else if (!downStops.isEmpty()) {
            direction = Direction.DOWN;
            currentFloor = downStops.pollFirst();
        } else {
            direction = Direction.IDLE;
        }
    }

    boolean isIdle() { return direction == Direction.IDLE; }
    int getCurrentFloor() { return currentFloor; }
    Direction getDirection() { return direction; }
    int getId() { return id; }
}

interface SchedulingStrategy {
    Elevator selectElevator(List<Elevator> elevators, Request request);
}

class NearestElevatorStrategy implements SchedulingStrategy {
    public Elevator selectElevator(List<Elevator> elevators, Request request) {
        return elevators.stream()
            .min(Comparator.comparingInt(e -> Math.abs(e.getCurrentFloor() - request.floor)))
            .orElseThrow();
    }
}

class ElevatorController {
    private final List<Elevator> elevators;
    private final SchedulingStrategy strategy;

    ElevatorController(int numElevators, SchedulingStrategy strategy) {
        this.elevators = new ArrayList<>();
        for (int i = 0; i < numElevators; i++) elevators.add(new Elevator(i));
        this.strategy = strategy;
    }

    void handleRequest(Request request) {
        Elevator elevator = strategy.selectElevator(elevators, request);
        elevator.addStop(request.floor);
    }

    void step() { elevators.forEach(Elevator::move); }
}
```

## 6. How to Extend
- Add weight limit → Elevator tracks current weight
- Add VIP elevator → Priority scheduling strategy
- Add emergency mode → Override all elevators to ground floor

## 7. Common Mistakes
- Not using a scheduling strategy (hardcoding FCFS)
- Not handling direction changes properly
- Missing the SCAN/LOOK algorithm concept

## 8. Walkthrough Script
1. (5 min) Requirements, entities
2. (5 min) Class diagram with Elevator, Controller, Strategy
3. (15 min) Code Elevator (with TreeSet for stops), Controller, Strategy
4. (5 min) Discuss SCAN algorithm, direction handling
5. (5 min) Extensions, edge cases


---

### Concurrency & Thread Safety

**Concurrent floor requests:**
```java
// Multiple people press buttons on different floors simultaneously.
// The request queue must be thread-safe.

class ElevatorController {
    private final PriorityBlockingQueue<Request> requests = new PriorityBlockingQueue<>();
    // PriorityBlockingQueue is thread-safe. Multiple threads can add requests concurrently.
    
    public void addRequest(Request request) {
        requests.offer(request); // thread-safe, non-blocking
        notifyElevator();
    }
}

// Elevator state transitions must be atomic:
class Elevator {
    private final ReentrantLock stateLock = new ReentrantLock();
    private ElevatorState state; // IDLE, MOVING_UP, MOVING_DOWN, DOOR_OPEN
    
    public void transitionTo(ElevatorState newState) {
        stateLock.lock();
        try {
            if (!isValidTransition(state, newState)) throw new IllegalStateException();
            this.state = newState;
        } finally {
            stateLock.unlock();
        }
    }
}
```
