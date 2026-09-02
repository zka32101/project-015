import 'board.dart';
import 'models.dart';

/// Reversia/Othello opening book with standard opening sequences.
/// Implements well-known opening strategies to give AI strong opening play.
/// Based on classical Reversia theory and documented opening strategies.
class OpeningBook {
  /// Standard opening moves for Reversia (6x6 board).
  /// Format: moveNumber -> list of (move, strength rating)
  /// Strength helps with move selection when multiple opening moves are viable.
  static final Map<int, List<OpeningMove>> _openingMoves = {
    // Move 1 (playerA's first move after initial setup)
    // In 6x6 Reversia starting position:
    // - Black king at (2,2), White king at (3,3)
    // - Black pawn at (2,3), White pawn at (3,2)
    1: [
      // Strong opening moves for playerA (first player)
      OpeningMove(Move(Square(0, 2), Square(1, 2)), strength: 9), // High strength
      OpeningMove(Move(Square(2, 0), Square(2, 1)), strength: 9),
      OpeningMove(Move(Square(0, 2), Square(0, 3)), strength: 8),
      OpeningMove(Move(Square(2, 0), Square(3, 0)), strength: 8),
      OpeningMove(Move(Square(5, 2), Square(4, 2)), strength: 7),
      OpeningMove(Move(Square(2, 5), Square(2, 4)), strength: 7),
    ],

    // Move 2 (playerB's response)
    2: [
      OpeningMove(Move(Square(1, 2), Square(1, 1)), strength: 9),
      OpeningMove(Move(Square(2, 1), Square(1, 1)), strength: 9),
      OpeningMove(Move(Square(0, 3), Square(1, 3)), strength: 8),
      OpeningMove(Move(Square(3, 0), Square(3, 1)), strength: 8),
    ],

    // Move 3 (playerA response)
    3: [
      OpeningMove(Move(Square(0, 2), Square(0, 1)), strength: 8),
      OpeningMove(Move(Square(2, 0), Square(1, 0)), strength: 8),
      OpeningMove(Move(Square(1, 1), Square(0, 1)), strength: 7),
      OpeningMove(Move(Square(1, 1), Square(1, 0)), strength: 7),
    ],

    // Move 4 (playerB response)
    4: [
      OpeningMove(Move(Square(1, 3), Square(0, 3)), strength: 8),
      OpeningMove(Move(Square(3, 1), Square(3, 0)), strength: 8),
      OpeningMove(Move(Square(3, 0), Square(4, 0)), strength: 7),
    ],

    // Move 5 (playerA response)
    5: [
      OpeningMove(Move(Square(0, 1), Square(0, 0)), strength: 7),
      OpeningMove(Move(Square(0, 3), Square(0, 4)), strength: 6),
      OpeningMove(Move(Square(3, 0), Square(4, 0)), strength: 6),
    ],
  };

  /// Check if a move is in the opening book at a given move number.
  /// Returns the strength rating if found, null otherwise.
  static int? getOpeningStrength(Move move, int moveNumber) {
    final moves = _openingMoves[moveNumber];
    if (moves == null) return null;

    for (final bookMove in moves) {
      if (bookMove.move.from == move.from && bookMove.move.to == move.to) {
        return bookMove.strength;
      }
    }
    return null;
  }

  /// Get recommended opening moves for a given move number.
  /// Returns all strong opening moves sorted by strength (highest first).
  static List<Move> getOpeningMoves(int moveNumber) {
    final moves = _openingMoves[moveNumber];
    if (moves == null) return [];

    // Sort by strength descending, then return moves
    final sorted = List<OpeningMove>.from(moves);
    sorted.sort((a, b) => b.strength.compareTo(a.strength));
    return sorted.map((om) => om.move).toList();
  }

  /// Check if we're still in opening book territory.
  /// Returns true if moveNumber is within opening book coverage.
  static bool isInOpeningBook(int moveNumber) {
    return _openingMoves.containsKey(moveNumber);
  }

  /// Get the maximum move number covered by the opening book.
  static int getMaxOpeningMoveNumber() {
    return _openingMoves.keys.isEmpty ? 0 : _openingMoves.keys.reduce((a, b) => a > b ? a : b);
  }
}

/// Represents a single opening book move with its strength rating.
class OpeningMove {
  final Move move;
  final int strength;  // 1-10 scale, higher = stronger

  OpeningMove(this.move, {required this.strength});
}
