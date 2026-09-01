import 'board.dart';
import 'models.dart';
import 'move_generator.dart';

/// Advanced evaluation system for better game balance and strategy
class AdvancedEvaluator {
  // Piece value weights
  static const int kingValue = 500;
  static const int normalPieceValue = 100;
  static const int mobilityWeight = 15;
  static const int centerControlWeight = 20;
  static const int kingSafetyWeight = 80;
  static const int captureWeight = 150;

  // Board positional weights (corners > edges > center)
  static const int cornerWeight = 150;      // Corners are very valuable
  static const int edgeWeight = 50;         // Edge squares are valuable
  static const int xSquareWeight = -30;     // X-squares (risky, adjacent to corners)
  static const int cSquareWeight = -20;     // C-squares (somewhat risky)

  /// Comprehensive board evaluation considering multiple strategic factors
  static int evaluate(Board board, Owner owner) {
    int score = 0;

    // 1. Material evaluation (piece count)
    score += _evaluateMaterial(board, owner);

    // 2. King safety - preserve your king!
    score += _evaluateKingSafety(board, owner);

    // 3. Position control (center advantage)
    score += _evaluatePositionControl(board, owner);

    // 4. Strategic position control (corners, edges, X-squares)
    score += _evaluateStrategicPosition(board, owner);

    // 5. Piece mobility (more moves = better)
    score += _evaluateMobility(board, owner);

    return score;
  }

  /// Evaluate material advantage
  static int _evaluateMaterial(Board board, Owner owner) {
    int myMaterial = 0;
    int oppMaterial = 0;

    for (int r = 0; r < 6; r++) {
      for (int c = 0; c < 6; c++) {
        final piece = board.at(Square(r, c));
        if (piece == null) continue;

        final value = piece.type == PieceType.king ? kingValue : normalPieceValue;

        if (piece.owner == owner) {
          myMaterial += value;
        } else {
          oppMaterial += value;
        }
      }
    }

    return (myMaterial - oppMaterial);
  }

  /// Evaluate king safety - penalty for king in danger
  static int _evaluateKingSafety(Board board, Owner owner) {
    // Find opponent's king and assess threat level
    final opponentMoves = MoveGenerator.legalMovesFor(board, owner.opponent);

    int kingThreatCount = 0;
    for (final move in opponentMoves) {
      final target = board.at(move.to);
      if (target != null && target.type == PieceType.king && target.owner == owner) {
        kingThreatCount++;
      }
    }

    // Penalize if king is threatened (multiple threats = worse)
    return -kingThreatCount * kingSafetyWeight;
  }

  /// Evaluate center control (6x6 board center is roughly rows 2-3, cols 2-3)
  static int _evaluatePositionControl(Board board, Owner owner) {
    final centerSquares = [
      [2, 2], [2, 3],
      [3, 2], [3, 3],
    ];

    int centerPieces = 0;
    int opponentCenterPieces = 0;

    for (final pos in centerSquares) {
      final piece = board.at(Square(pos[0], pos[1]));
      if (piece == null) continue;

      if (piece.owner == owner) {
        centerPieces++;
      } else {
        opponentCenterPieces++;
      }
    }

    return (centerPieces - opponentCenterPieces) * centerControlWeight;
  }

  /// Evaluate strategic position control (corners, edges, dangerous squares)
  /// This is crucial for Reversia strategy: corners are safe and permanent,
  /// edges are valuable, while X-squares and C-squares are risky.
  static int _evaluateStrategicPosition(Board board, Owner owner) {
    int score = 0;

    for (int r = 0; r < 6; r++) {
      for (int c = 0; c < 6; c++) {
        final piece = board.at(Square(r, c));
        if (piece == null || piece.owner != owner) continue;

        final squareType = _classifySquare(r, c);
        score += squareType.weight;
      }
    }

    return score;
  }

  /// Classify a square's strategic importance in Reversia
  static _SquareType _classifySquare(int row, int col) {
    // Corners: (0,0), (0,5), (5,0), (5,5) - very safe and permanent
    if ((row == 0 || row == 5) && (col == 0 || col == 5)) {
      return _SquareType(name: 'corner', weight: cornerWeight);
    }

    // X-squares: diagonally adjacent to corners - risky! (e.g., (1,1) near (0,0))
    if ((row == 1 || row == 4) && (col == 1 || col == 4)) {
      return _SquareType(name: 'x_square', weight: xSquareWeight);
    }

    // C-squares: orthogonally adjacent to corners - somewhat risky (e.g., (0,1) near (0,0))
    if ((row == 0 || row == 5) && (col == 1 || col == 4)) {
      return _SquareType(name: 'c_square_edge', weight: cSquareWeight);
    }
    if ((row == 1 || row == 4) && (col == 0 || col == 5)) {
      return _SquareType(name: 'c_square_edge', weight: cSquareWeight);
    }

    // Edge squares (row or col = 0 or 5, but not corner/C-square)
    if (row == 0 || row == 5 || col == 0 || col == 5) {
      return _SquareType(name: 'edge', weight: edgeWeight);
    }

    // Interior squares
    return _SquareType(name: 'interior', weight: 0);
  }

  /// Evaluate piece mobility (how many moves available)
  static int _evaluateMobility(Board board, Owner owner) {
    final myMoves = MoveGenerator.legalMovesFor(board, owner).length;
    final oppMoves = MoveGenerator.legalMovesFor(board, owner.opponent).length;

    return (myMoves - oppMoves) * mobilityWeight;
  }

  /// Evaluate a specific move's value (for greedy strategy)
  static int evaluateMove(Board board, Move move, Owner owner) {
    int score = 0;

    final target = board.at(move.to);

    // King capture is excellent
    if (target != null && target.type == PieceType.king && target.owner != owner) {
      score += 10000;
    }
    // Regular capture is good
    else if (target != null && target.owner != owner) {
      score += captureWeight;
    }

    // Moving toward center is decent
    const centerRow = 2.5;
    const centerCol = 2.5;
    final distFromCenter = (move.to.row - centerRow).abs() + (move.to.col - centerCol).abs();
    score += (6 - distFromCenter.toInt()) * 5;

    return score;
  }
}

/// Simple data class for square type classification
class _SquareType {
  final String name;
  final int weight;

  _SquareType({required this.name, required this.weight});
}

/// Difficulty-specific AI strategies
class AiStrategy {
  // Easy AI - slightly smarter random with some preference
  static int evaluateMoveEasy(Board board, Move move, Owner owner) {
    // 80% random, 20% smart
    final target = board.at(move.to);
    int score = 0;

    // Captures are slightly preferred
    if (target != null && target.owner != owner) {
      score += 50;
    }

    return score;
  }

  // Medium AI - improved greedy strategy
  static int evaluateMoveMedium(Board board, Move move, Owner owner) {
    // Use the advanced evaluator
    return AdvancedEvaluator.evaluateMove(board, move, owner);
  }

  // Hard AI - strategic evaluation (used in minimax)
  static int evaluateBoardHard(Board board, Owner owner) {
    return AdvancedEvaluator.evaluate(board, owner);
  }
}
