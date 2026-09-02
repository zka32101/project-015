import 'ai.dart';
import 'ai_evaluator.dart';
import 'board.dart';
import 'models.dart';
import 'move_generator.dart';

/// Comprehensive move analysis for player guidance and strategic understanding
class MoveAnalyzer {
  /// Analyzes all legal moves and returns ranked analysis with explanations
  static List<MoveAnalysis> analyzeMoves(Board board, Owner owner) {
    final moves = MoveGenerator.legalMovesFor(board, owner);
    final analyses = <MoveAnalysis>[];

    for (final move in moves) {
      final analysis = _analyzeSingleMove(board, move, owner, moves.length);
      analyses.add(analysis);
    }

    // Sort by strength descending
    analyses.sort((a, b) => b.strength.compareTo(a.strength));

    // Add rank to each
    for (int i = 0; i < analyses.length; i++) {
      analyses[i] = analyses[i]._withRank(i + 1);
    }

    return analyses;
  }

  /// Analyze a single move in detail
  static MoveAnalysis _analyzeSingleMove(
    Board board,
    Move move,
    Owner owner,
    int totalLegalMoves,
  ) {
    final target = board.at(move.to);
    int strength = 0;
    final categories = <String>[];
    final reasons = <String>[];

    // Check for king capture (highest priority)
    if (target != null && target.type == PieceType.king && target.owner != owner) {
      strength += 10000;
      categories.add('winning');
      reasons.add('相手の王を取る勝利手');
      return MoveAnalysis(
        move: move,
        strength: strength,
        category: MoveCategory.winning,
        categories: categories,
        reasons: reasons,
        rank: 0,
      );
    }

    // Check for piece capture
    bool capturesOpponentPiece = false;
    if (target != null && target.owner != owner) {
      strength += 500;
      categories.add('capture');
      capturesOpponentPiece = true;
      if (target.type == PieceType.king) {
        reasons.add('重要な駒をキャプチャ');
      } else {
        reasons.add('駒をキャプチャして有利');
      }
    }

    // Check position value
    final isCorner = (move.to.row == 0 || move.to.row == 5) &&
        (move.to.col == 0 || move.to.col == 5);
    final isEdge = (move.to.row == 0 || move.to.row == 5 ||
        move.to.col == 0 || move.to.col == 5);
    final isXSquare =
        (move.to.row == 1 || move.to.row == 4) &&
        (move.to.col == 1 || move.to.col == 4);
    final isCSquare = ((move.to.row == 0 || move.to.row == 5) &&
            (move.to.col == 1 || move.to.col == 4)) ||
        ((move.to.row == 1 || move.to.row == 4) &&
            (move.to.col == 0 || move.to.col == 5));

    if (isCorner) {
      strength += 400;
      categories.add('strategic');
      reasons.add('コーナーを確保する強い位置');
    } else if (isEdge && !isXSquare && !isCSquare) {
      strength += 150;
      categories.add('positional');
      reasons.add('エッジのコントロール');
    } else if (isXSquare) {
      strength -= 100;
      categories.add('risky');
      reasons.add('危険な位置（X-square）を避けるべき');
    } else if (isCSquare) {
      strength -= 50;
      categories.add('risky');
      reasons.add('やや危険な位置（C-square）');
    }

    // Center control
    const centerRow = 2.5;
    const centerCol = 2.5;
    final distFromCenter = (move.to.row - centerRow).abs() +
        (move.to.col - centerCol).abs();
    if (distFromCenter <= 2 && !capturesOpponentPiece && !isCorner) {
      strength += 80;
      if (!categories.contains('positional')) {
        categories.add('positional');
      }
      reasons.add('中央付近で局面をコントロール');
    }

    // Determine category
    MoveCategory category = MoveCategory.solid;
    if (strength > 600) {
      category = MoveCategory.excellent;
    } else if (strength > 200) {
      category = MoveCategory.good;
    } else if (strength < -50) {
      category = MoveCategory.risky;
    }

    return MoveAnalysis(
      move: move,
      strength: strength,
      category: category,
      categories: categories,
      reasons: reasons,
      rank: 0,
    );
  }

  /// Get the best move with full analysis
  static MoveAnalysis? getBestMoveAnalysis(Board board, Owner owner) {
    final analyses = analyzeMoves(board, owner);
    return analyses.isNotEmpty ? analyses.first : null;
  }

  /// Get top N moves for display
  static List<MoveAnalysis> getTopMoves(Board board, Owner owner, int count) {
    final analyses = analyzeMoves(board, owner);
    return analyses.take(count).toList();
  }

  /// Get strategic advice based on board position
  static String getStrategicAdvice(Board board, Owner owner) {
    final totalPieces =
        board.pieceCount(Owner.playerA) + board.pieceCount(Owner.playerB);
    final myPieces = board.pieceCount(owner);
    final oppPieces = board.pieceCount(owner.opponent);

    if (totalPieces <= 20) {
      return 'エンドゲーム段階：正確な計算が重要です。';
    }

    if (myPieces < oppPieces) {
      return '劣勢です。キャプチャして駒を増やしましょう。';
    } else if (myPieces > oppPieces) {
      return '優勢です。コーナーを取って優位を保ちましょう。';
    } else {
      return 'ポジション争いの最中。戦略的な位置を確保しましょう。';
    }
  }
}

/// Category of a move for UI display
enum MoveCategory {
  winning,  // Wins the game immediately
  excellent, // Very strong move
  good,      // Good move
  solid,     // Reasonable move
  risky,     // Potentially weak move
}

/// Detailed analysis of a single move
class MoveAnalysis {
  final Move move;
  final int strength; // Higher = better (-1000 to +10000 scale)
  final MoveCategory category;
  final List<String> categories; // Tags: 'capture', 'strategic', 'positional', etc.
  final List<String> reasons; // Human-readable explanations (Japanese)
  final int rank; // 1-based ranking among legal moves

  MoveAnalysis({
    required this.move,
    required this.strength,
    required this.category,
    required this.categories,
    required this.reasons,
    required this.rank,
  });

  /// Create a copy with updated rank
  MoveAnalysis _withRank(int newRank) {
    return MoveAnalysis(
      move: move,
      strength: strength,
      category: category,
      categories: categories,
      reasons: reasons,
      rank: newRank,
    );
  }

  /// Get display string for strength
  String get strengthDisplay {
    if (category == MoveCategory.winning) {
      return '✓ 勝利手';
    } else if (strength > 600) {
      return '★★★ 最高';
    } else if (strength > 200) {
      return '★★ 良好';
    } else if (strength > 0) {
      return '★ 良手';
    } else if (strength < -50) {
      return '⚠ 危険';
    } else {
      return '○ 平凡';
    }
  }

  /// Get emoji for category
  String get categoryEmoji {
    switch (category) {
      case MoveCategory.winning:
        return '👑';
      case MoveCategory.excellent:
        return '⭐';
      case MoveCategory.good:
        return '✓';
      case MoveCategory.solid:
        return '○';
      case MoveCategory.risky:
        return '⚠';
    }
  }

  /// Get color hint for UI (as string for theme compatibility)
  String get colorHint {
    switch (category) {
      case MoveCategory.winning:
        return 'gold';
      case MoveCategory.excellent:
        return 'green';
      case MoveCategory.good:
        return 'blue';
      case MoveCategory.solid:
        return 'gray';
      case MoveCategory.risky:
        return 'red';
    }
  }
}
