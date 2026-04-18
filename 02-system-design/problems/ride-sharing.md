# Design: Ride-Sharing System

## 1. Problem Statement & Scope

**Design a ride-sharing platform like Uber or Ola that matches riders with nearby drivers, calculates fares, and tracks trips in real-time.**

**Clarifying questions to ask:**
- Ride types? → Standard, premium, shared (pool)
- Real-time tracking? → Yes, driver location updated every 3-5 seconds
- Surge pricing? → Yes, based on demand/supply ratio
- Payment? → In-app (card, wallet, UPI). Post-trip charge.
- ETA? → Show estimated arrival time before and during trip

## 2. Requirements

**Functional:**
- Rider requests a ride (pickup, destination)
- System matches rider with nearest available driver
- Driver accepts/rejects ride request
- Real-time trip tracking (rider sees driver on map)
- Fare calculation (distance, time, surge multiplier)
- Payment processing (post-trip)
- Rating system (rider rates driver and vice versa)

**Non-functional:**
- Match rider to driver in < 5 seconds
- Location updates: every 3-5 seconds per active driver
- 99.9% availability
- Support 1M concurrent active trips

**Estimation:**
```
20M DAU, 10M rides/day
Active drivers at peak: 500K
Location updates: 500K drivers × 1 update/4 sec = 125K updates/sec
  → Write-heavy for location data. Need geospatial index.

Ride requests: 10M / 86400 ≈ 120 QPS. Peak: ~500 QPS.
  → Moderate. Matching is the hard part, not QPS.

Trip data: 10M rides × 2KB = 20GB/day. Manageable.
```

## 3. High-Level Design

```
┌──────────┐     ┌──────────────┐     ┌─────────────────┐
│  Rider   │────→│  API Gateway │────→│  Ride Service    │
│  App     │     └──────┬───────┘     │  (request, match │
└──────────┘            │             │   fare, status)  │
                        │             └────────┬─────────┘
┌──────────┐            │                      │
│  Driver  │────→───────┘             ┌────────┴─────────┐
│  App     │                          │  Location Service │
└──────────┘                          │  (geospatial      │
                                      │   index, tracking)│
                                      └────────┬─────────┘
                                               │
                                      ┌────────┴─────────┐
                                      │  Redis (driver    │
                                      │  locations,       │
                                      │  geospatial)      │
                                      └──────────────────┘
                                      
                                      ┌──────────────────┐
                                      │  Kafka            │
                                      │  (trip events,    │
                                      │   location stream)│
                                      └──────────────────┘
                                               │
                              ┌────────────────┼────────────────┐
                              │                │                │
                     ┌────────┴───┐   ┌────────┴───┐   ┌───────┴────┐
                     │ Payment    │   │ Notification│   │ Analytics  │
                     │ Service    │   │ Service     │   │ Service    │
                     └────────────┘   └────────────┘   └────────────┘
```

## 4. Deep Dive

### Location Service & Geospatial Index [🔥 Must Know]

**Problem: given a rider's location, find the nearest available drivers within 5km. With 500K active drivers, scanning all of them is too slow.**

```
Solution: Geospatial indexing

Option 1: Redis GEO (recommended for simplicity)
  GEOADD drivers:available 77.5946 12.9716 "driver_123"
  GEORADIUS drivers:available 77.5946 12.9716 5 km COUNT 10 ASC
  → Returns 10 nearest drivers within 5km, sorted by distance.
  Redis GEO uses a sorted set with geohash encoding. O(log n + k).

Option 2: QuadTree (in-memory, custom)
  Recursively divide 2D space into 4 quadrants.
  Each leaf node contains drivers in that area.
  Search: find the leaf containing rider, expand to neighboring leaves.
  
Option 3: S2 Geometry (Google's approach)
  Map Earth's surface to cells at different levels.
  Level 12 cell ≈ 3.3km². Level 14 ≈ 0.8km².
  Store driver's cell ID. Query: find drivers in same cell + neighboring cells.
  Used by Uber (H3 hexagonal grid, similar concept).

Driver location updates (every 4 seconds):
  Driver app → WebSocket → Location Service → Redis GEOADD
  125K updates/sec → Redis handles this easily (single-threaded, 100K+ ops/sec)
  Also publish to Kafka for trip tracking and analytics.
```

### Ride Matching Algorithm [🔥 Must Know]

```
Simple matching (Uber's early approach):
  1. Rider requests ride at (lat, lng)
  2. Find K nearest available drivers (Redis GEORADIUS, K=10)
  3. Filter: driver's vehicle matches ride type, driver is not already matched
  4. Send ride request to nearest driver
  5. Driver has 15 seconds to accept
  6. If rejected/timeout → send to next nearest driver
  7. If all K reject → expand radius, try again
  8. If still no match → notify rider "no drivers available"

Advanced matching (batch matching):
  Every 2 seconds, collect all pending ride requests.
  Run optimization: minimize total wait time across all riders.
  This is a bipartite matching problem (riders ↔ drivers).
  Uber uses this for UberPool (shared rides).
```

### Trip State Machine

```
REQUESTED → DRIVER_ASSIGNED → DRIVER_EN_ROUTE → DRIVER_ARRIVED 
         → TRIP_STARTED → TRIP_COMPLETED → PAYMENT_PROCESSED
              ↓                                    ↓
         CANCELLED_BY_RIDER                   PAYMENT_FAILED
         CANCELLED_BY_DRIVER

Each transition:
  1. Update trip status in DB
  2. Publish event to Kafka
  3. Push real-time update to rider and driver via WebSocket
```

### Fare Calculation

```java
public class FareCalculator {
    public Fare calculate(Trip trip) {
        double distance = trip.getDistanceKm();
        double duration = trip.getDurationMinutes();
        double surgeMultiplier = getSurgeMultiplier(trip.getPickupLocation());
        
        double baseFare = 50.0;  // base charge
        double distanceFare = distance * 12.0;  // per km rate
        double timeFare = duration * 2.0;  // per minute rate
        double subtotal = (baseFare + distanceFare + timeFare) * surgeMultiplier;
        double platformFee = subtotal * 0.20;  // 20% platform commission
        
        return new Fare(subtotal, platformFee, surgeMultiplier);
    }
}
```

### Surge Pricing [🔥 Must Know]

```
Surge = demand / supply in a geographic area

Divide city into hexagonal cells (H3 grid).
For each cell, every 2 minutes:
  demand = ride requests in last 5 minutes
  supply = available drivers in cell
  ratio = demand / supply
  
  ratio < 1.0 → surge = 1.0x (no surge)
  ratio 1.0-2.0 → surge = 1.2x-1.5x
  ratio 2.0-3.0 → surge = 1.5x-2.0x
  ratio > 3.0 → surge = 2.0x-3.0x (cap)

Show surge to rider BEFORE they confirm.
Surge attracts more drivers to high-demand areas (economic incentive).
```

### ETA Calculation

```
ETA from driver to rider:
  1. Get driver's current location
  2. Query routing service (Google Maps API, OSRM, or internal)
  3. Get estimated travel time considering current traffic
  4. Update ETA every 30 seconds during en-route phase

ETA for trip (rider to destination):
  Same routing service, but from pickup to destination.
  Show before ride confirmation for fare estimate.
```

## 5. Bottlenecks & Trade-offs

| Bottleneck | Solution |
|-----------|----------|
| 125K location updates/sec | Redis GEO (handles 100K+ ops/sec). Shard by city if needed. |
| Matching latency | Pre-index drivers geospatially. K-nearest in < 50ms with Redis GEORADIUS. |
| Real-time tracking | WebSocket for rider/driver apps. Kafka for event persistence. |
| Surge calculation | Pre-compute per cell every 2 min. Cache in Redis. |
| Flash demand (concert ends) | Queue ride requests. Batch matching. Expand search radius. |
| Driver location staleness | TTL on driver location (30 sec). If no update, mark as offline. |

## 6. Revision Checklist

- [ ] Geospatial index: Redis GEO (GEOADD, GEORADIUS) or QuadTree or S2/H3 cells.
- [ ] Location updates: 125K/sec via WebSocket → Redis GEOADD. Kafka for persistence.
- [ ] Matching: find K nearest available drivers, send request sequentially, 15s timeout each.
- [ ] Trip state machine: REQUESTED → ASSIGNED → EN_ROUTE → ARRIVED → STARTED → COMPLETED.
- [ ] Fare: base + distance*rate + time*rate, multiplied by surge.
- [ ] Surge: demand/supply ratio per geographic cell, recalculated every 2 min.
- [ ] ETA: routing service (Google Maps / OSRM) with real-time traffic.
- [ ] Payment: post-trip, idempotent, handle failures gracefully.

> 🔗 **See Also:** [02-system-design/problems/payment-system.md](payment-system.md) for payment processing. [02-system-design/problems/notification-system.md](notification-system.md) for push notifications. [06-tech-stack/02-redis-deep-dive.md](../../06-tech-stack/02-redis-deep-dive.md) for Redis GEO commands.

---

## 9. Interviewer Deep-Dive Questions

1. **"500K drivers sending location every 4 seconds. How do you handle 125K writes/sec?"**
   → Redis GeoSet: `GEOADD drivers <lng> <lat> <driver_id>`. Redis handles 100K+ ops/sec. For higher scale: shard by geo-region (city). Don't persist every update to DB — only persist trip-related locations.

2. **"How do you match rider with nearest driver?"**
   → `GEORADIUS drivers <rider_lng> <rider_lat> 5km COUNT 10 ASC` — returns 10 nearest drivers within 5km. Filter: only available drivers (check status in Redis). Rank by: distance, rating, ETA. Send ride request to top driver. If declined/timeout (15s): send to next.

3. **"Surge pricing — how do you calculate it in real-time?"**
   → Divide city into hexagonal cells (H3 geospatial index). Per cell: track demand (ride requests/min) and supply (available drivers). Surge multiplier = demand/supply ratio, smoothed over 5-minute window. Cap at 3-5x. Update every minute. Cache in Redis per cell.

4. **"GPS is inaccurate (urban canyons, tunnels). How do you handle it?"**
   → Map matching: snap GPS coordinates to nearest road using road network graph. Kalman filter: smooth noisy GPS readings using vehicle speed and heading. For fare calculation: use map-matched distance (road distance), not straight-line distance.

5. **"How do you handle shared rides (pool)?"**
   → Matching algorithm: find riders with similar routes (origin and destination within threshold). Detour constraint: shared ride adds max 10 minutes to any rider's trip. Real-time: as new ride request comes in, check existing active pool rides for compatibility. Pricing: split fare proportionally by distance.

## 10. Failure Matrix

| Component Down | Impact | Mitigation |
|---|---|---|
| Redis (location) | Can't find nearby drivers | Cache last known locations. Degrade to wider search radius. |
| Matching service | Can't assign rides | Queue requests. Manual dispatch fallback. |
| Payment service | Can't charge after trip | Queue payment. Charge when service recovers. Trip still completes. |
