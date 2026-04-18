# LLD: Library Management System

## 1. Problem Statement
Design a library management system.

💡 **Why this is a common LLD problem:** It tests CRUD operations with state management (book copy lifecycle: AVAILABLE → ISSUED → RETURNED), fine calculation (Strategy pattern), and search functionality. It's straightforward but tests clean OOP design.

🎯 **Key Follow-ups:** How do you handle concurrent book issuance? → Optimistic locking on BookCopy status. How do you implement search? → Index by title, author, ISBN (HashMap or database indexes). How do you handle reservations? → Queue per book, notify next in line when returned.

> 🔗 **See Also:** [04-lld/01-solid-principles.md](../01-solid-principles.md) for SRP (separate BookService, MemberService, FineService).

## 2. Requirements
- Add/remove books, search by title/author/ISBN
- Issue and return books, track due dates
- Fine calculation for late returns
- Member management, book reservations

## 3. Entities & Relationships
```
Library 1──* Book 1──* BookCopy (physical copies)
Member: id, name, issuedBooks[], fines
BookCopy: id, book, status (AVAILABLE, ISSUED, RESERVED, LOST)
IssuanceRecord: member, bookCopy, issueDate, dueDate, returnDate
```

## 4. Design Patterns Used
- **Strategy:** Fine calculation (per day, flat rate)
- **Observer:** Notify member when reserved book becomes available
- **State:** BookCopy states (AVAILABLE → ISSUED → RETURNED)

## 5. Complete Java Implementation

```java
enum BookStatus { AVAILABLE, ISSUED, RESERVED, LOST }

class Book {
    private final String isbn, title, author;
    private final List<BookCopy> copies = new ArrayList<>();
    Book(String isbn, String title, String author) { this.isbn = isbn; this.title = title; this.author = author; }
    void addCopy(BookCopy copy) { copies.add(copy); }
    List<BookCopy> getAvailableCopies() {
        return copies.stream().filter(c -> c.getStatus() == BookStatus.AVAILABLE).toList();
    }
}

class BookCopy {
    private final String id;
    private final Book book;
    private BookStatus status = BookStatus.AVAILABLE;
    BookCopy(String id, Book book) { this.id = id; this.book = book; }
    BookStatus getStatus() { return status; }
    void setStatus(BookStatus s) { this.status = s; }
}

class Member {
    private final String id, name;
    private final List<IssuanceRecord> activeIssues = new ArrayList<>();
    private double fines = 0;
    private static final int MAX_BOOKS = 5;

    boolean canIssue() { return activeIssues.size() < MAX_BOOKS && fines == 0; }
    void addIssue(IssuanceRecord record) { activeIssues.add(record); }
    void removeIssue(IssuanceRecord record) { activeIssues.remove(record); }
    void addFine(double amount) { fines += amount; }
}

class IssuanceRecord {
    private final Member member;
    private final BookCopy bookCopy;
    private final LocalDate issueDate;
    private final LocalDate dueDate;
    private LocalDate returnDate;

    IssuanceRecord(Member member, BookCopy copy, int loanDays) {
        this.member = member; this.bookCopy = copy;
        this.issueDate = LocalDate.now();
        this.dueDate = issueDate.plusDays(loanDays);
    }
}

class LibraryService {
    private final Map<String, Book> books = new HashMap<>(); // ISBN -> Book
    private final FineStrategy fineStrategy;

    LibraryService(FineStrategy fineStrategy) { this.fineStrategy = fineStrategy; }

    IssuanceRecord issueBook(Member member, String isbn) {
        if (!member.canIssue()) throw new RuntimeException("Cannot issue: limit reached or fines pending");
        Book book = books.get(isbn);
        BookCopy copy = book.getAvailableCopies().stream().findFirst()
            .orElseThrow(() -> new RuntimeException("No copies available"));
        copy.setStatus(BookStatus.ISSUED);
        IssuanceRecord record = new IssuanceRecord(member, copy, 14);
        member.addIssue(record);
        return record;
    }

    double returnBook(IssuanceRecord record) {
        record.getBookCopy().setStatus(BookStatus.AVAILABLE);
        record.setReturnDate(LocalDate.now());
        record.getMember().removeIssue(record);
        long daysLate = ChronoUnit.DAYS.between(record.getDueDate(), LocalDate.now());
        if (daysLate > 0) {
            double fine = fineStrategy.calculate(daysLate);
            record.getMember().addFine(fine);
            return fine;
        }
        return 0;
    }
}

interface FineStrategy { double calculate(long daysLate); }
class PerDayFine implements FineStrategy { public double calculate(long days) { return days * 1.0; } }
```

## 6-8. Extensions & Walkthrough
- Add reservation queue, search by multiple criteria, email notifications
- Walkthrough: entities (5 min) → Book/BookCopy/Member (10 min) → Issue/Return logic (10 min) → Fine strategy (5 min) → Extensions (5 min)
