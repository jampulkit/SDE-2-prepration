# LLD: Snake and Ladder

## 1. Problem Statement
Design a Snake and Ladder board game.

💡 **Why this is a good warm-up LLD problem:** It's simpler than parking lot or elevator but tests clean OOP (separation of Board, Player, Dice, Game), game loop design, and configurable rules (snakes/ladders as data, not hardcoded). The key insight: snakes and ladders are just a `Map<Integer, Integer>` — position → destination.

🎯 **Key Follow-ups:** How do you add special cells (power-ups, traps)? → Strategy pattern for cell behavior. How do you support multiplayer online? → Game state on server, WebSocket for real-time updates. How do you detect winner? → Player reaches or exceeds position 100.

## 2. Requirements
- N×N board (typically 10×10 = 100 cells)
- Configurable snakes and ladders
- Multiple players, turn-based
- Dice roll (1-6), automatic movement

## 3. Entities & Relationships
```
Game: board, players, currentPlayerIndex
Board: size, snakes (Map<Integer,Integer>), ladders (Map<Integer,Integer>)
Player: name, position
Dice: roll()
```

## 5. Complete Java Implementation

```java
class Dice {
    private final Random random = new Random();
    private final int faces;
    Dice(int faces) { this.faces = faces; }
    int roll() { return random.nextInt(faces) + 1; }
}

class Player {
    private final String name;
    private int position = 0;
    Player(String name) { this.name = name; }
    String getName() { return name; }
    int getPosition() { return position; }
    void setPosition(int pos) { this.position = pos; }
}

class Board {
    private final int size;
    private final Map<Integer, Integer> snakes;  // head -> tail
    private final Map<Integer, Integer> ladders; // bottom -> top

    Board(int size, Map<Integer, Integer> snakes, Map<Integer, Integer> ladders) {
        this.size = size; this.snakes = snakes; this.ladders = ladders;
        // Validate: no overlap between snakes and ladders
    }

    int getFinalPosition(int position) {
        if (snakes.containsKey(position)) return snakes.get(position);
        if (ladders.containsKey(position)) return ladders.get(position);
        return position;
    }

    int getWinningPosition() { return size; }
}

class Game {
    private final Board board;
    private final List<Player> players;
    private final Dice dice;
    private int currentPlayerIndex = 0;

    Game(Board board, List<Player> players, Dice dice) {
        this.board = board; this.players = players; this.dice = dice;
    }

    Player play() {
        while (true) {
            Player current = players.get(currentPlayerIndex);
            int roll = dice.roll();
            int newPos = current.getPosition() + roll;

            if (newPos <= board.getWinningPosition()) {
                newPos = board.getFinalPosition(newPos);
                current.setPosition(newPos);
                System.out.printf("%s rolled %d, moved to %d%n", current.getName(), roll, newPos);
                if (newPos == board.getWinningPosition()) {
                    System.out.println(current.getName() + " wins!");
                    return current;
                }
            }
            currentPlayerIndex = (currentPlayerIndex + 1) % players.size();
        }
    }
}
```

## 6-8. Extensions & Walkthrough
- Add special cells (power-ups, skip turn), multiplayer online, undo last move
- Walkthrough: entities (3 min) → Board with snakes/ladders (7 min) → Game loop (10 min) → Extensions (5 min)
