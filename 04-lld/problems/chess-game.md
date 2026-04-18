# LLD: Chess Game

## 1. Problem Statement
Design a two-player chess game.

💡 **Why this is a classic LLD problem:** It tests polymorphism (each piece type has different move rules), the Strategy pattern (move validation per piece), and the Command pattern (moves as objects for undo). The key challenge is clean move validation — each piece has unique rules, and you need to check for check/checkmate after every move.

🎯 **Key Follow-ups:** How do you implement undo? → Command pattern: store moves in a stack, undo pops and reverses. How do you detect checkmate? → After every move, check if opponent's king is in check AND has no legal moves. How do you add new piece types (fairy chess)? → New class extending Piece with its own `getValidMoves()` — OCP.

> 🔗 **See Also:** [04-lld/01-solid-principles.md](../01-solid-principles.md) for OCP (new pieces without modifying existing code). [04-lld/02-design-patterns.md](../02-design-patterns.md) for Strategy and Command patterns.

## 2. Requirements
- Standard 8x8 board, all standard pieces
- Validate legal moves per piece type
- Detect check, checkmate, stalemate
- Turn-based play

## 3. Entities & Relationships
```
Game: board, players[2], currentTurn, status
Board: 8x8 grid of Cell
Cell: position(row, col), piece (nullable)
Piece (abstract): color, position <── King, Queen, Rook, Bishop, Knight, Pawn
Player: name, color
Move: from, to, piece, capturedPiece
```

## 4. Design Patterns Used
- **Strategy:** Each piece type has its own move validation strategy
- **Command:** Move as a command object (enables undo)

## 5. Complete Java Implementation

```java
enum Color { WHITE, BLACK }
enum PieceType { KING, QUEEN, ROOK, BISHOP, KNIGHT, PAWN }

record Position(int row, int col) {
    boolean isValid() { return row >= 0 && row < 8 && col >= 0 && col < 8; }
}

abstract class Piece {
    protected Color color;
    protected Position position;
    Piece(Color color, Position position) { this.color = color; this.position = position; }
    abstract List<Position> getValidMoves(Board board);
    Color getColor() { return color; }
    void setPosition(Position p) { this.position = p; }
}

class Knight extends Piece {
    Knight(Color c, Position p) { super(c, p); }
    List<Position> getValidMoves(Board board) {
        int[][] offsets = {{-2,-1},{-2,1},{-1,-2},{-1,2},{1,-2},{1,2},{2,-1},{2,1}};
        List<Position> moves = new ArrayList<>();
        for (int[] o : offsets) {
            Position p = new Position(position.row() + o[0], position.col() + o[1]);
            if (p.isValid() && (board.getPiece(p) == null || board.getPiece(p).getColor() != color))
                moves.add(p);
        }
        return moves;
    }
}
// Similar implementations for Rook (straight lines), Bishop (diagonals),
// Queen (straight + diagonal), King (one step), Pawn (forward + capture diagonal)

class Board {
    private Piece[][] grid = new Piece[8][8];
    Piece getPiece(Position p) { return grid[p.row()][p.col()]; }
    void setPiece(Position p, Piece piece) { grid[p.row()][p.col()] = piece; }
    void movePiece(Position from, Position to) {
        Piece piece = getPiece(from);
        setPiece(from, null);
        setPiece(to, piece);
        piece.setPosition(to);
    }
    // Initialize board with standard setup...
}

class Game {
    private Board board;
    private Player[] players;
    private int currentTurn = 0; // 0 = WHITE, 1 = BLACK

    boolean makeMove(Position from, Position to) {
        Piece piece = board.getPiece(from);
        if (piece == null || piece.getColor() != players[currentTurn].getColor()) return false;
        if (!piece.getValidMoves(board).contains(to)) return false;
        board.movePiece(from, to);
        currentTurn = 1 - currentTurn;
        return true;
    }
}
```

## 6-8. Extensions & Walkthrough
- Add check/checkmate detection (simulate move, check if king is attacked)
- Add castling, en passant, pawn promotion
- Add move history with undo (Command pattern)
- Walkthrough: entities (5 min) → Piece hierarchy (10 min) → Board + move validation (10 min) → Game flow (5 min) → Extensions (5 min)
