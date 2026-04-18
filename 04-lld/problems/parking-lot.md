# LLD: Parking Lot

## 1. Problem Statement
Design an object-oriented parking lot system.

💡 **Why this is the #1 LLD interview problem:** It's simple enough to design in 35 minutes but tests all SOLID principles, design patterns (Strategy, Factory), and OOP fundamentals. Every interviewer knows this problem — your answer is directly compared against hundreds of other candidates.

**Clarifying questions:** Multiple floors? → Yes. Vehicle types? → Motorcycle, Car, Truck. Payment? → Hourly rate. Entry/exit gates? → Multiple.

## 2. Requirements
- Park/unpark vehicles of different sizes
- Track available spots per floor and type
- Calculate parking fee based on duration
- Multiple entry/exit points

## 3. Entities & Relationships
```
ParkingLot 1──* ParkingFloor 1──* ParkingSpot
ParkingSpot *──1 SpotType (MOTORCYCLE, COMPACT, LARGE)
Vehicle (abstract) <── Car, Motorcycle, Truck
ParkingTicket: vehicle, spot, entryTime, exitTime, fee
```

## 4. Design Patterns Used
- **Strategy:** Different pricing strategies (hourly, daily, weekend) — swap pricing without changing ParkingLot (OCP + DIP)
- **Singleton:** ParkingLot instance (one lot per system)
- **Factory:** Create appropriate ParkingSpot based on vehicle type (decouple creation)

💡 **Intuition — Why Strategy for Pricing:** If you hardcode `fee = hours * 2.0` in ParkingLot, adding weekend pricing means modifying ParkingLot (violates OCP). With Strategy, you create `WeekendPricing implements PricingStrategy` and inject it — zero changes to existing code.

🎯 **Likely Follow-ups:**
- **Q:** How would you handle concurrent park/unpark?
  **A:** Use `ConcurrentHashMap` for active tickets (already done). For spot allocation, use `synchronized` on the floor or spot level, or use `AtomicReference` for the spot's vehicle field.
- **Q:** How would you add a reservation system?
  **A:** New `ReservationService` with `reserve(spotType, startTime, endTime)`. Store reservations in a map. When parking, check if the spot is reserved. This is a new feature — no changes to existing classes (OCP).
- **Q:** How would you handle a full parking lot?
  **A:** Return null or throw a custom `ParkingFullException`. Optionally: maintain a waitlist, notify when a spot opens (Observer pattern).

> 🔗 **See Also:** [04-lld/01-solid-principles.md](../01-solid-principles.md) for SOLID principles applied here. [04-lld/02-design-patterns.md](../02-design-patterns.md) for Strategy and Factory patterns.

## 5. Complete Java Implementation

```java
enum VehicleType { MOTORCYCLE, CAR, TRUCK }
enum SpotType { MOTORCYCLE, COMPACT, LARGE }

abstract class Vehicle {
    private String licensePlate;
    private VehicleType type;
    Vehicle(String plate, VehicleType type) { this.licensePlate = plate; this.type = type; }
    String getLicensePlate() { return licensePlate; }
    VehicleType getType() { return type; }
}
class Car extends Vehicle { Car(String plate) { super(plate, VehicleType.CAR); } }
class Motorcycle extends Vehicle { Motorcycle(String plate) { super(plate, VehicleType.MOTORCYCLE); } }
class Truck extends Vehicle { Truck(String plate) { super(plate, VehicleType.TRUCK); } }

class ParkingSpot {
    private final int id;
    private final SpotType type;
    private Vehicle currentVehicle;

    ParkingSpot(int id, SpotType type) { this.id = id; this.type = type; }
    boolean isAvailable() { return currentVehicle == null; }
    boolean canFit(Vehicle v) {
        return isAvailable() && switch (v.getType()) {
            case MOTORCYCLE -> true; // fits anywhere
            case CAR -> type != SpotType.MOTORCYCLE;
            case TRUCK -> type == SpotType.LARGE;
        };
    }
    void park(Vehicle v) { this.currentVehicle = v; }
    void unpark() { this.currentVehicle = null; }
    int getId() { return id; }
    SpotType getType() { return type; }
}

class ParkingFloor {
    private final int floorNumber;
    private final List<ParkingSpot> spots;

    ParkingFloor(int floorNumber, List<ParkingSpot> spots) {
        this.floorNumber = floorNumber;
        this.spots = spots;
    }

    ParkingSpot findSpot(Vehicle vehicle) {
        return spots.stream().filter(s -> s.canFit(vehicle)).findFirst().orElse(null);
    }
}

class ParkingTicket {
    private final String ticketId;
    private final Vehicle vehicle;
    private final ParkingSpot spot;
    private final LocalDateTime entryTime;
    private LocalDateTime exitTime;

    ParkingTicket(Vehicle vehicle, ParkingSpot spot) {
        this.ticketId = UUID.randomUUID().toString();
        this.vehicle = vehicle;
        this.spot = spot;
        this.entryTime = LocalDateTime.now();
    }

    double calculateFee(PricingStrategy strategy) {
        this.exitTime = LocalDateTime.now();
        long hours = Duration.between(entryTime, exitTime).toHours() + 1;
        return strategy.calculate(hours, vehicle.getType());
    }
}

interface PricingStrategy {
    double calculate(long hours, VehicleType type);
}

class HourlyPricing implements PricingStrategy {
    private static final Map<VehicleType, Double> RATES = Map.of(
        VehicleType.MOTORCYCLE, 1.0, VehicleType.CAR, 2.0, VehicleType.TRUCK, 3.0);
    public double calculate(long hours, VehicleType type) { return hours * RATES.get(type); }
}

class ParkingLot {
    private final List<ParkingFloor> floors;
    private final Map<String, ParkingTicket> activeTickets = new ConcurrentHashMap<>();
    private final PricingStrategy pricingStrategy;

    ParkingLot(List<ParkingFloor> floors, PricingStrategy strategy) {
        this.floors = floors;
        this.pricingStrategy = strategy;
    }

    ParkingTicket parkVehicle(Vehicle vehicle) {
        for (ParkingFloor floor : floors) {
            ParkingSpot spot = floor.findSpot(vehicle);
            if (spot != null) {
                spot.park(vehicle);
                ParkingTicket ticket = new ParkingTicket(vehicle, spot);
                activeTickets.put(vehicle.getLicensePlate(), ticket);
                return ticket;
            }
        }
        throw new RuntimeException("No available spot");
    }

    double unparkVehicle(String licensePlate) {
        ParkingTicket ticket = activeTickets.remove(licensePlate);
        if (ticket == null) throw new RuntimeException("Vehicle not found");
        double fee = ticket.calculateFee(pricingStrategy);
        ticket.getSpot().unpark();
        return fee;
    }
}
```

## 6. How to Extend
- Add EV charging spots → new SpotType, no existing code changes (OCP)
- Add valet parking → new ParkingStrategy
- Add reservation system → ReservationService with time slots

## 7. Common Mistakes
- Not using enums for vehicle/spot types
- Tight coupling between ParkingLot and pricing logic
- Not handling thread safety for concurrent park/unpark
- Missing the vehicle-to-spot size mapping

## 8. Walkthrough Script (35 min)
1. (5 min) Clarify requirements, list entities
2. (5 min) Draw class diagram, explain relationships
3. (15 min) Code core classes: Vehicle hierarchy, ParkingSpot, ParkingLot
4. (5 min) Add PricingStrategy (show OCP)
5. (5 min) Discuss extensions, thread safety, edge cases
