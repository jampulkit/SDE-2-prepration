# LLD: Food Delivery System

## 1. Requirements

**Design an object-oriented food delivery system like Swiggy or Zomato.**

- Users browse restaurants and menus
- Users place orders (multiple items from ONE restaurant)
- System assigns a delivery agent
- Order goes through lifecycle: PLACED → CONFIRMED → PREPARING → PICKED_UP → DELIVERED
- Payment processing (simplified)
- Rating for restaurant and delivery agent

## 2. Entities & Relationships

```
User 1──* Order *──1 Restaurant
Order 1──* OrderItem *──1 MenuItem
Order *──1 DeliveryAgent
Restaurant 1──* MenuItem
Order 1──1 Payment
```

## 3. Design Patterns Used

- **State:** Order lifecycle (each state has different allowed transitions)
- **Strategy:** Delivery agent assignment (nearest, least busy, round-robin)
- **Observer:** Notify user when order status changes
- **Factory:** Create payment processor based on payment method

## 4. Complete Java Implementation

```java
// --- Enums ---
enum OrderStatus { PLACED, CONFIRMED, PREPARING, PICKED_UP, DELIVERED, CANCELLED }
enum PaymentMethod { CARD, UPI, WALLET, COD }
enum PaymentStatus { PENDING, SUCCESS, FAILED }

// --- Core Entities ---
class User {
    private final String id;
    private final String name;
    private final String address;
    // constructor, getters
}

class Restaurant {
    private final String id;
    private final String name;
    private final String address;
    private final List<MenuItem> menu = new ArrayList<>();
    
    public void addMenuItem(MenuItem item) { menu.add(item); }
    public List<MenuItem> getMenu() { return Collections.unmodifiableList(menu); }
}

class MenuItem {
    private final String id;
    private final String name;
    private final double price;
    private boolean available = true;
    // constructor, getters, setAvailable
}

class DeliveryAgent {
    private final String id;
    private final String name;
    private volatile boolean available = true;
    private String currentLocation;
    
    public boolean isAvailable() { return available; }
    public void setAvailable(boolean available) { this.available = available; }
}

// --- Order ---
class OrderItem {
    private final MenuItem menuItem;
    private final int quantity;
    
    public double getTotal() { return menuItem.getPrice() * quantity; }
}

class Order {
    private final String id;
    private final User user;
    private final Restaurant restaurant;
    private final List<OrderItem> items;
    private OrderStatus status;
    private DeliveryAgent agent;
    private Payment payment;
    private final List<OrderObserver> observers = new ArrayList<>();
    
    public Order(String id, User user, Restaurant restaurant, List<OrderItem> items) {
        this.id = id;
        this.user = user;
        this.restaurant = restaurant;
        this.items = items;
        this.status = OrderStatus.PLACED;
    }
    
    public double getTotalAmount() {
        return items.stream().mapToDouble(OrderItem::getTotal).sum();
    }
    
    public void addObserver(OrderObserver observer) { observers.add(observer); }
    
    public void updateStatus(OrderStatus newStatus) {
        if (!isValidTransition(this.status, newStatus)) {
            throw new IllegalStateException("Cannot transition from " + status + " to " + newStatus);
        }
        this.status = newStatus;
        observers.forEach(o -> o.onStatusChange(this, newStatus));
    }
    
    private boolean isValidTransition(OrderStatus from, OrderStatus to) {
        return switch (from) {
            case PLACED -> to == OrderStatus.CONFIRMED || to == OrderStatus.CANCELLED;
            case CONFIRMED -> to == OrderStatus.PREPARING || to == OrderStatus.CANCELLED;
            case PREPARING -> to == OrderStatus.PICKED_UP;
            case PICKED_UP -> to == OrderStatus.DELIVERED;
            default -> false;
        };
    }
}

// --- Observer Pattern ---
interface OrderObserver {
    void onStatusChange(Order order, OrderStatus newStatus);
}

class UserNotificationObserver implements OrderObserver {
    public void onStatusChange(Order order, OrderStatus newStatus) {
        System.out.println("Notification to " + order.getUser().getName() 
            + ": Order " + order.getId() + " is now " + newStatus);
    }
}

class RestaurantNotificationObserver implements OrderObserver {
    public void onStatusChange(Order order, OrderStatus newStatus) {
        if (newStatus == OrderStatus.CONFIRMED) {
            System.out.println("Restaurant " + order.getRestaurant().getName() 
                + ": New order " + order.getId());
        }
    }
}

// --- Strategy Pattern: Agent Assignment ---
interface AgentAssignmentStrategy {
    DeliveryAgent assign(List<DeliveryAgent> agents, String pickupLocation);
}

class NearestAgentStrategy implements AgentAssignmentStrategy {
    public DeliveryAgent assign(List<DeliveryAgent> agents, String pickupLocation) {
        return agents.stream()
            .filter(DeliveryAgent::isAvailable)
            .min(Comparator.comparingDouble(a -> distance(a.getCurrentLocation(), pickupLocation)))
            .orElseThrow(() -> new RuntimeException("No agents available"));
    }
    private double distance(String loc1, String loc2) { return Math.random(); } // simplified
}

class LeastBusyAgentStrategy implements AgentAssignmentStrategy {
    public DeliveryAgent assign(List<DeliveryAgent> agents, String pickupLocation) {
        return agents.stream()
            .filter(DeliveryAgent::isAvailable)
            .findFirst()
            .orElseThrow(() -> new RuntimeException("No agents available"));
    }
}

// --- Payment (Factory Pattern) ---
interface PaymentProcessor {
    PaymentStatus process(double amount);
}

class CardPaymentProcessor implements PaymentProcessor {
    public PaymentStatus process(double amount) { return PaymentStatus.SUCCESS; }
}

class UPIPaymentProcessor implements PaymentProcessor {
    public PaymentStatus process(double amount) { return PaymentStatus.SUCCESS; }
}

class PaymentProcessorFactory {
    public static PaymentProcessor create(PaymentMethod method) {
        return switch (method) {
            case CARD -> new CardPaymentProcessor();
            case UPI -> new UPIPaymentProcessor();
            case WALLET -> new WalletPaymentProcessor();
            case COD -> new CODPaymentProcessor();
        };
    }
}

class Payment {
    private final String id;
    private final double amount;
    private final PaymentMethod method;
    private PaymentStatus status;
    
    public void process() {
        PaymentProcessor processor = PaymentProcessorFactory.create(method);
        this.status = processor.process(amount);
    }
}

// --- Service Layer ---
class FoodDeliveryService {
    private final List<Restaurant> restaurants = new ArrayList<>();
    private final List<DeliveryAgent> agents = new ArrayList<>();
    private final Map<String, Order> orders = new ConcurrentHashMap<>();
    private AgentAssignmentStrategy assignmentStrategy;
    
    public FoodDeliveryService(AgentAssignmentStrategy strategy) {
        this.assignmentStrategy = strategy;
    }
    
    public Order placeOrder(User user, Restaurant restaurant, List<OrderItem> items, PaymentMethod paymentMethod) {
        String orderId = UUID.randomUUID().toString();
        Order order = new Order(orderId, user, restaurant, items);
        order.addObserver(new UserNotificationObserver());
        order.addObserver(new RestaurantNotificationObserver());
        
        // Process payment
        Payment payment = new Payment(UUID.randomUUID().toString(), order.getTotalAmount(), paymentMethod);
        payment.process();
        if (payment.getStatus() != PaymentStatus.SUCCESS) {
            throw new RuntimeException("Payment failed");
        }
        order.setPayment(payment);
        
        // Assign delivery agent
        DeliveryAgent agent = assignmentStrategy.assign(agents, restaurant.getAddress());
        agent.setAvailable(false);
        order.setAgent(agent);
        
        order.updateStatus(OrderStatus.CONFIRMED);
        orders.put(orderId, order);
        return order;
    }
}
```

## 5. Follow-ups

🎯 **Likely Follow-ups:**
- **Q:** How would you handle orders from multiple restaurants?
  **A:** Create separate sub-orders per restaurant, each with its own lifecycle and delivery agent. The parent order tracks overall status.
- **Q:** How would you add a coupon/discount system?
  **A:** Strategy pattern: `DiscountStrategy` interface with implementations like `PercentageDiscount`, `FlatDiscount`, `BuyOneGetOne`. Apply before payment.
- **Q:** How would you handle delivery agent going offline mid-delivery?
  **A:** Timeout on status updates. If no update in 10 minutes, reassign to another agent. Notify user of delay.

## 6. Revision Checklist

- [ ] State pattern: Order lifecycle with valid transitions enforced
- [ ] Strategy: agent assignment (nearest, least busy, round-robin)
- [ ] Observer: notify user and restaurant on status changes
- [ ] Factory: create payment processor based on payment method
- [ ] ConcurrentHashMap for thread-safe order storage
- [ ] Valid state transitions enforced (can't go from DELIVERED to PLACED)

> 🔗 **See Also:** [04-lld/01-solid-principles.md](../01-solid-principles.md) for SOLID. [04-lld/02-design-patterns.md](../02-design-patterns.md) for State, Strategy, Observer patterns.
