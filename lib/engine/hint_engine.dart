import 'ai.dart';
import 'board.dart';
import 'models.dart';
import 'move_generator.dart';

/// Provides game hints by analyzing positions and suggesting strong moves
class HintEngine {
  /// Analyzes the current position and returns the best move suggestion
  /// Uses AI difficulty to determine hint strength
  static Move? getBestMoveHint(Board board, Owner owner, {AiDifficulty difficulty = AiDifficulty.medium}) {
    final ai = ReversiaAi(difficulty);
    return ai.pickMove(board, owner);
  }

  /// Evaluates all legal moves and returns them sorted by strength
  static List<(Move move, int score)> getMoveSuggestions(Board board, Owner owner) {
    final moves = MoveGenerator.legalMovesFor(board, owner);
    final suggestions = <(Move, int)>[];

    for (final move in moves) {
      final score = _evaluateMove(board, move, owner);
      suggestions.add((move, score));
    }

    // Sort by score (highest first)
    suggestions.sort((a, b) => b.$2.compareTo(a.$2));
    return suggestions;
  }

  /// Get hints for dangerous opponent moves
  static List<Square> getThreatSquares(Board board, Owner owner) {
    final opponentMoves = MoveGenerator.legalMovesFor(board, owner.opponent);
    return opponentMoves.map((m) => m.to).toList();
  }

  /// Evaluate a move's strength based on simple heuristics
  static int _evaluateMove(Board board, Move move, Owner owner) {
    final target = board.at(move.to);
    int score = 0;

    // King capture is the best move
    if (target != null && target.type == PieceType.king && target.owner != owner) {
      score += 1000;
    }
    // Capturing any piece is good
    else if (target != null && target.owner != owner) {
      score += 100;
    }
    // Moving to the center is generally good (average row/col = 2.5, so distance from center)
    else {
      const centerRow = 2.5;
      const centerCol = 2.5;
      final distFromCenter = ((move.to.row - centerRow).abs() + (move.to.col - centerCol).abs()).toDouble();
      score += (6 - distFromCenter.toInt()) * 5;
    }

    return score;
  }

  /// Get a difficulty-appropriate hint with explanation
  static HintSuggestion? getHintWithExplanation(Board board, Owner owner) {
    final suggestions = getMoveSuggestions(board, owner);
    if (suggestions.isEmpty) return null;

    final bestMove = suggestions.first.$1;
    final target = board.at(bestMove.to);

    String explanation;
    if (target != null && target.type == PieceType.king && target.owner != owner) {
      explanation = 'ここで相手の王を取ることができます！';
    } else if (target != null && target.owner != owner) {
      explanation = '相手の駒を取る良い手です。';
    } else {
      explanation = 'ここは戦略的に良い位置です。';
    }

    return HintSuggestion(
      move: bestMove,
      explanation: explanation,
      isWinningMove: target != null && target.type == PieceType.king && target.owner != owner,
    );
  }
}

/// Represents a hint suggestion with reasoning
class HintSuggestion {
  final Move move;
  final String explanation;
  final bool isWinningMove;

  HintSuggestion({
    required this.move,
    required this.explanation,
    required this.isWinningMove,
  });
}
