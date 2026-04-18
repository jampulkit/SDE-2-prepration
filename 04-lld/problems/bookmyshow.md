# LLD: BookMyShow (Movie Ticket Booking)

## 1. Problem Statement
Design a movie ticket booking system like BookMyShow.

💡 **Why this is critical for interviews:** It tests concurrent seat selection (the hardest part — preventing double booking), State pattern for seat lifecycle, and payment integration. The seat locking mechanism (AVAILABLE → LOCKED → BOOKED with timeout) is the key design decision.

⚙️ **Under the Hood — Preventing Double Booking:** When User A selects seat 5A, it must be LOCKED (reserved for 10 minutes) so User B can't select it simultaneously. If User A doesn't complete payment within 10 minutes, the lock expires and the seat becomes AVAILABLE again. Implementation: optimistic locking with version column, or `UPDATE seats SET status='LOCKED' WHERE id=? AND status='AVAILABLE'` (atomic DB operation).

🎯 **Key Follow-ups:** How do you handle 10,000 users trying to book the same show? → Queue requests, lock seats atomically. How do you handle payment failure after seat lock? → Release lock, return seats to AVAILABLE.

> 🔗 **See Also:** [02-system-design/problems/payment-system.md](../../02-system-design/problems/payment-system.md) for payment integration patterns.

## 2. Requirements
- Browse movies, theaters, showtimes
- Select seats and book tickets
- Handle concurrent seat selection (no double booking)
- Payment processing
- Booking confirmation/cancellation

## 3. Entities & Relationships
```
Movie 1──* Show *──1 Theater
Theater 1──* Screen 1──* Seat
Show 1──* ShowSeat (available/booked/locked)
Booking: user, show, seats, status, payment
```

## 4. Design Patterns Used
- **State:** Seat states (AVAILABLE → LOCKED → BOOKED / AVAILABLE)
- **Strategy:** Pricing (weekday, weekend, premium)
- **Observer:** Notify on booking confirmation

## 5. Complete Java Implementation

```java
enum SeatStatus { AVAILABLE, LOCKED, BOOKED }
enum BookingStatus { PENDING, CONFIRMED, CANCELLED }

class Seat {
    private final String id;
    private final String row;
    private final int number;
    private final SeatType type; // REGULAR, PREMIUM, VIP
    Seat(String id, String row, int number, SeatType type) {
        this.id = id; this.row = row; this.number = number; this.type = type;
    }
    // getters
}

class ShowSeat {
    private final Seat seat;
    private volatile SeatStatus status = SeatStatus.AVAILABLE;
    private LocalDateTime lockExpiry;

    ShowSeat(Seat seat) { this.seat = seat; }

    synchronized boolean lock(Duration timeout) {
        if (status != SeatStatus.AVAILABLE) return false;
        status = SeatStatus.LOCKED;
        lockExpiry = LocalDateTime.now().plus(timeout);
        return true;
    }

    synchronized boolean book() {
        if (status != SeatStatus.LOCKED) return false;
        status = SeatStatus.BOOKED;
        return true;
    }

    synchronized void release() {
        if (status == SeatStatus.LOCKED) status = SeatStatus.AVAILABLE;
    }

    boolean isExpired() {
        return status == SeatStatus.LOCKED && LocalDateTime.now().isAfter(lockExpiry);
    }
}

class Show {
    private final String id;
    private final Movie movie;
    private final Screen screen;
    private final LocalDateTime startTime;
    private final Map<String, ShowSeat> seats = new ConcurrentHashMap<>();

    // Lock seats for a user (with timeout to prevent indefinite holds)
    List<ShowSeat> lockSeats(List<String> seatIds, Duration timeout) {
        List<ShowSeat> locked = new ArrayList<>();
        for (String seatId : seatIds) {
            ShowSeat showSeat = seats.get(seatId);
            if (showSeat == null || !showSeat.lock(timeout)) {
                locked.forEach(ShowSeat::release); // rollback
                throw new RuntimeException("Seat " + seatId + " unavailable");
            }
            locked.add(showSeat);
        }
        return locked;
    }
}

class Booking {
    private final String id;
    private final User user;
    private final Show show;
    private final List<ShowSeat> seats;
    private BookingStatus status = BookingStatus.PENDING;
    private double totalAmount;

    Booking(User user, Show show, List<ShowSeat> seats, double amount) {
        this.id = UUID.randomUUID().toString();
        this.user = user; this.show = show; this.seats = seats; this.totalAmount = amount;
    }

    void confirm() {
        seats.forEach(ShowSeat::book);
        this.status = BookingStatus.CONFIRMED;
    }

    void cancel() {
        seats.forEach(ShowSeat::release);
        this.status = BookingStatus.CANCELLED;
    }
}

class BookingService {
    private final Map<String, Booking> bookings = new ConcurrentHashMap<>();

    Booking createBooking(User user, Show show, List<String> seatIds) {
        List<ShowSeat> locked = show.lockSeats(seatIds, Duration.ofMinutes(10));
        double amount = calculatePrice(locked);
        Booking booking = new Booking(user, show, locked, amount);
        bookings.put(booking.getId(), booking);
        return booking;
    }

    void confirmBooking(String bookingId, PaymentDetails payment) {
        Booking booking = bookings.get(bookingId);
        // process payment...
        booking.confirm();
    }
}
```

## 6. How to Extend
- Add coupon/discount system → DiscountStrategy
- Add waitlist for sold-out shows
- Add seat map visualization

## 7. Common Mistakes
- Not handling concurrent seat selection (race condition → double booking)
- No lock timeout (seats locked forever if user abandons)
- Not rolling back partial seat locks on failure

## 8. Walkthrough Script
1. (5 min) Requirements, entities, class diagram
2. (15 min) Code ShowSeat (with synchronized lock/book), Show, Booking
3. (10 min) BookingService with lock timeout and rollback
4. (5 min) Discuss concurrency, payment integration, extensions


---

### Concurrency & Thread Safety

**Concurrent seat booking (the core challenge):**
```java
// 500 users try to book the same seat simultaneously.
// Without synchronization: two users both see seat as AVAILABLE, both book it.

// Approach 1: Optimistic locking (preferred for high concurrency)
class SeatService {
    public boolean bookSeat(long seatId, long userId) {
        // UPDATE seats SET status='LOCKED', locked_by=?, version=version+1
        // WHERE id=? AND status='AVAILABLE' AND version=?
        int updated = seatRepo.lockSeat(seatId, userId, currentVersion);
        return updated == 1; // 0 means someone else got it first
    }
}

// Approach 2: SELECT FOR UPDATE (pessimistic, simpler but lower throughput)
@Transactional
public boolean bookSeat(long seatId, long userId) {
    Seat seat = seatRepo.findByIdForUpdate(seatId); // locks row in DB
    if (seat.getStatus() != SeatStatus.AVAILABLE) return false;
    seat.setStatus(SeatStatus.LOCKED);
    seat.setLockedBy(userId);
    seat.setLockExpiry(Instant.now().plusMinutes(10)); // auto-release after 10 min
    return true;
}

// Seat lock expiry: background job releases seats locked > 10 min (payment timeout)
@Scheduled(fixedRate = 60000)
public void releaseExpiredLocks() {
    seatRepo.releaseExpiredLocks(Instant.now());
}
```
