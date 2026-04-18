# LLD: Design Problems Using Stacks & Queues

## 1. Problem Statement
Design systems that use stacks and queues as core data structures: browser history, undo/redo, task scheduler.

## 2. Browser History (Stack-Based)

```java
class BrowserHistory {
    private final Deque<String> backStack = new ArrayDeque<>();
    private final Deque<String> forwardStack = new ArrayDeque<>();
    private String current;

    BrowserHistory(String homepage) { current = homepage; }

    void visit(String url) {
        backStack.push(current);
        current = url;
        forwardStack.clear(); // new navigation clears forward history
    }

    String back(int steps) {
        while (steps-- > 0 && !backStack.isEmpty()) {
            forwardStack.push(current);
            current = backStack.pop();
        }
        return current;
    }

    String forward(int steps) {
        while (steps-- > 0 && !forwardStack.isEmpty()) {
            backStack.push(current);
            current = forwardStack.pop();
        }
        return current;
    }
}
```

**Design patterns:** Two stacks (back + forward). Visit clears forward stack. Back/forward transfer between stacks.

## 3. Undo/Redo System (Command Pattern + Stack)

```java
interface Command {
    void execute();
    void undo();
}

class TextEditor {
    private StringBuilder text = new StringBuilder();
    private final Deque<Command> undoStack = new ArrayDeque<>();
    private final Deque<Command> redoStack = new ArrayDeque<>();

    void type(String s) {
        Command cmd = new TypeCommand(text, s);
        cmd.execute();
        undoStack.push(cmd);
        redoStack.clear(); // new action clears redo
    }

    void undo() {
        if (!undoStack.isEmpty()) {
            Command cmd = undoStack.pop();
            cmd.undo();
            redoStack.push(cmd);
        }
    }

    void redo() {
        if (!redoStack.isEmpty()) {
            Command cmd = redoStack.pop();
            cmd.execute();
            undoStack.push(cmd);
        }
    }
}

class TypeCommand implements Command {
    private final StringBuilder text;
    private final String typed;
    private final int position;

    TypeCommand(StringBuilder text, String typed) {
        this.text = text; this.typed = typed; this.position = text.length();
    }

    public void execute() { text.append(typed); }
    public void undo() { text.delete(position, position + typed.length()); }
}
```

**Design patterns:** Command pattern (encapsulate action as object), two stacks (undo + redo).

## 4. Task Scheduler (Priority Queue)

```java
class TaskScheduler {
    private final PriorityQueue<Task> queue;

    TaskScheduler() {
        queue = new PriorityQueue<>(Comparator.comparingInt(Task::getPriority)
                                              .thenComparing(Task::getCreatedAt));
    }

    void addTask(Task task) { queue.offer(task); }
    Task getNextTask() { return queue.poll(); }
    boolean hasTasks() { return !queue.isEmpty(); }
}
```

## 5. Design Patterns Used
- **Command:** Undo/redo (encapsulate actions as objects)
- **Strategy:** Different scheduling strategies (FIFO, priority, deadline)
- **Observer:** Notify UI when history/undo state changes

## 6. Revision Checklist
- [ ] Browser history: two stacks (back + forward), visit clears forward
- [ ] Undo/redo: Command pattern + two stacks, new action clears redo
- [ ] Task scheduler: PriorityQueue with custom comparator
- [ ] Command pattern enables undo by storing inverse operation

> 🔗 **See Also:** [01-dsa/03-stacks-queues.md](../../01-dsa/03-stacks-queues.md) for stack/queue fundamentals. [04-lld/02-design-patterns.md](../02-design-patterns.md) for Command and Strategy patterns.
