# LLD: Splitwise

## 1. Problem Statement
Design an expense-sharing application like Splitwise.

💡 **Why this is a great LLD problem:** It tests the Strategy pattern (different split types), data modeling (balance tracking between user pairs), and an interesting algorithm (debt simplification — minimize the number of transactions to settle all debts). The split validation (amounts must add up) is a common edge case candidates miss.

🎯 **Key Follow-ups:** How do you simplify debts? → Net balance per user. Users with positive balance are creditors, negative are debtors. Match largest creditor with largest debtor. This minimizes transactions. How do you handle currency conversion? → Store amounts in base currency, convert on display.

> 🔗 **See Also:** [04-lld/02-design-patterns.md](../02-design-patterns.md) for Strategy pattern (split types). [02-system-design/problems/payment-system.md](../../02-system-design/problems/payment-system.md) for payment/settlement concepts.

## 2. Requirements
- Add expenses (equal split, exact amounts, percentage)
- Track balances between users
- Simplify debts (minimize transactions)
- Group expenses

## 3. Entities & Relationships
```
User: id, name, email
Group: id, name, members[]
Expense: id, paidBy, amount, splitType, splits[]
Split (abstract): user, amount <── EqualSplit, ExactSplit, PercentSplit
BalanceSheet: tracks net balance between every pair of users
```

## 4. Design Patterns Used
- **Strategy:** Different split types (equal, exact, percentage)
- **Observer:** Notify users when expense is added

## 5. Complete Java Implementation

```java
enum SplitType { EQUAL, EXACT, PERCENT }

class User {
    private final String id, name, email;
    User(String id, String name, String email) { this.id = id; this.name = name; this.email = email; }
    String getId() { return id; }
    String getName() { return name; }
}

abstract class Split {
    protected User user;
    protected double amount;
    Split(User user) { this.user = user; }
    User getUser() { return user; }
    double getAmount() { return amount; }
    void setAmount(double amount) { this.amount = amount; }
}
class EqualSplit extends Split { EqualSplit(User user) { super(user); } }
class ExactSplit extends Split { ExactSplit(User user, double amount) { super(user); this.amount = amount; } }
class PercentSplit extends Split {
    double percent;
    PercentSplit(User user, double percent) { super(user); this.percent = percent; }
}

class Expense {
    private final String id;
    private final User paidBy;
    private final double amount;
    private final List<Split> splits;
    private final SplitType type;

    Expense(User paidBy, double amount, List<Split> splits, SplitType type) {
        this.id = UUID.randomUUID().toString();
        this.paidBy = paidBy;
        this.amount = amount;
        this.splits = splits;
        this.type = type;
        computeSplits();
    }

    private void computeSplits() {
        if (type == SplitType.EQUAL) {
            double share = amount / splits.size();
            splits.forEach(s -> s.setAmount(share));
        } else if (type == SplitType.PERCENT) {
            for (Split s : splits) {
                PercentSplit ps = (PercentSplit) s;
                s.setAmount(amount * ps.percent / 100.0);
            }
        }
        // EXACT: amounts already set
        double total = splits.stream().mapToDouble(Split::getAmount).sum();
        if (Math.abs(total - amount) > 0.01) throw new IllegalArgumentException("Split amounts don't add up");
    }
}

class ExpenseService {
    // balances[A][B] > 0 means A owes B
    private final Map<String, Map<String, Double>> balances = new HashMap<>();

    void addExpense(Expense expense) {
        String payer = expense.getPaidBy().getId();
        for (Split split : expense.getSplits()) {
            String debtor = split.getUser().getId();
            if (debtor.equals(payer)) continue;
            updateBalance(debtor, payer, split.getAmount());
        }
    }

    private void updateBalance(String debtor, String creditor, double amount) {
        balances.computeIfAbsent(debtor, k -> new HashMap<>())
                .merge(creditor, amount, Double::sum);
        balances.computeIfAbsent(creditor, k -> new HashMap<>())
                .merge(debtor, -amount, Double::sum);
    }

    Map<String, Double> getBalances(String userId) {
        return balances.getOrDefault(userId, Map.of());
    }
}
```

## 6-8. Extensions & Walkthrough
- Simplify debts: minimize number of transactions using a greedy algorithm (net balances → match max creditor with max debtor)
- Add group support, expense history, currency conversion
- Walkthrough: entities (5 min) → Split hierarchy (5 min) → Expense + validation (10 min) → BalanceSheet (10 min) → Simplify debts (5 min)


---

### Concurrency & Thread Safety

**Concurrent expense additions and balance recalculation:**
```java
class ExpenseService {
    private final ConcurrentHashMap<String, ReentrantLock> groupLocks = new ConcurrentHashMap<>();
    
    public void addExpense(String groupId, Expense expense) {
        // Lock per group: expenses in different groups don't block each other
        ReentrantLock lock = groupLocks.computeIfAbsent(groupId, k -> new ReentrantLock());
        lock.lock();
        try {
            expenseRepo.save(expense);
            recalculateBalances(groupId); // must be atomic with expense addition
        } finally {
            lock.unlock();
        }
    }
    
    // Balance map uses ConcurrentHashMap for thread-safe reads
    private final ConcurrentHashMap<String, Map<String, Double>> balances = new ConcurrentHashMap<>();
    
    public Map<String, Double> getBalances(String groupId) {
        return Collections.unmodifiableMap(balances.getOrDefault(groupId, Map.of()));
    }
}

// Alternative: use database transactions instead of in-memory locks
// @Transactional ensures expense + balance update are atomic in DB
```
