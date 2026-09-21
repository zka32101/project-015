import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../engine/game_record.dart';
import '../engine/models.dart';

/// Analysis of a single move
class MoveAnalysis {
  final int moveNumber;
  final String position;
  final String actualMove;
  final String? betterMove;
  final String quality;
  final double confidence;
  final String explanation;
  final int boardState; // Piece count or board representation

  const MoveAnalysis({
    required this.moveNumber,
    required this.position,
    required this.actualMove,
    this.betterMove,
    required this.quality,
    required this.confidence,
    required this.explanation,
    required this.boardState,
  });

  /// Get emoji for move quality
  String getQualityEmoji() {
    switch (quality) {
      case 'excellent':
        return '⭐';
      case 'good':
        return '✅';
      case 'acceptable':
        return '👍';
      case 'suboptimal':
        return '⚠️';
      case 'critical_error':
        return '❌';
      default:
        return '❓';
    }
  }

  /// Get color for move quality
  String getQualityColor() {
    switch (quality) {
      case 'excellent':
        return '#4CAF50'; // Green
      case 'good':
        return '#8BC34A'; // Light Green
      case 'acceptable':
        return '#FFC107'; // Orange
      case 'suboptimal':
        return '#FF9800'; // Deep Orange
      case 'critical_error':
        return '#F44336'; // Red
      default:
        return '#9E9E9E'; // Grey
    }
  }

  /// Get label for move quality
  String getQualityLabel() {
    switch (quality) {
      case 'excellent':
        return '優秀';
      case 'good':
        return '良い';
      case 'acceptable':
        return '許容範囲';
      case 'suboptimal':
        return '改善の余地あり';
      case 'critical_error':
        return '致命的';
      default:
        return '不明';
    }
  }
}

/// Analysis of a complete game
class GameMovesAnalysis {
  final GameRecord gameRecord;
  final List<MoveAnalysis> moveAnalyses;
  final double overallAccuracy;
  final int excellentMoves;
  final int goodMoves;
  final int acceptableMoves;
  final int suboptimalMoves;
  final int criticalErrors;
  final String gamePhaseAnalysis;
  final List<String> strengthAreas;
  final List<String> improvementAreas;
  final String overallFeedback;

  const GameMovesAnalysis({
    required this.gameRecord,
    required this.moveAnalyses,
    required this.overallAccuracy,
    required this.excellentMoves,
    required this.goodMoves,
    required this.acceptableMoves,
    required this.suboptimalMoves,
    required this.criticalErrors,
    required this.gamePhaseAnalysis,
    required this.strengthAreas,
    required this.improvementAreas,
    required this.overallFeedback,
  });

  /// Get phase-specific advice
  String getOpeningAdvice() {
    if (moveAnalyses.length < 5) return 'オープニング手数が不足しています';
    final openingMoves = moveAnalyses.take(5).toList();
    final goodMoveCount = openingMoves
        .where((m) => m.quality == 'excellent' || m.quality == 'good')
        .length;
    if (goodMoveCount >= 4) return 'オープニングは堅実です';
    return 'オープニングを改善する必要があります';
  }

  /// Get mid-game advice
  String getMidgameAdvice() {
    if (moveAnalyses.length < 10) return 'ミッドゲームデータが不足しています';
    final midgameMoves =
        moveAnalyses.skip(5).take(moveAnalyses.length - 10).toList();
    if (midgameMoves.isEmpty) return 'ミッドゲームが短すぎます';
    final criticalCount =
        midgameMoves.where((m) => m.quality == 'critical_error').length;
    if (criticalCount > 0) {
      return '$criticalCountつの致命的なエラーがありました';
    }
    return 'ミッドゲームは安定しています';
  }

  /// Get endgame advice
  String getEndgameAdvice() {
    if (moveAnalyses.length < 10) return 'エンドゲームデータが不足しています';
    final endgameMoves = moveAnalyses.skip(moveAnalyses.length - 5).toList();
    final goodMoveCount = endgameMoves
        .where((m) => m.quality == 'excellent' || m.quality == 'good')
        .length;
    if (goodMoveCount >= 4) return 'エンドゲームで強い判断をしました';
    return 'エンドゲームの意思決定を改善してください';
  }
}

/// State for move analysis
class MoveAnalysisState {
  final GameMovesAnalysis? analysis;
  final bool isLoading;
  final String? error;

  const MoveAnalysisState({
    this.analysis,
    this.isLoading = false,
    this.error,
  });

  MoveAnalysisState copyWith({
    GameMovesAnalysis? analysis,
    bool? isLoading,
    String? error,
  }) {
    return MoveAnalysisState(
      analysis: analysis ?? this.analysis,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

/// Notifier for move analysis
class MoveAnalysisNotifier extends StateNotifier<MoveAnalysisState> {
  MoveAnalysisNotifier() : super(const MoveAnalysisState());

  /// Analyze a game
  Future<void> analyzeGame(GameRecord gameRecord) async {
    state = state.copyWith(isLoading: true);
    try {
      final analysis = _performAnalysis(gameRecord);
      state = MoveAnalysisState(analysis: analysis, isLoading: false);
    } catch (e) {
      state = MoveAnalysisState(
        isLoading: false,
        error: 'ゲーム分析に失敗しました: $e',
      );
    }
  }

  /// Perform game analysis (simplified version)
  static GameMovesAnalysis _performAnalysis(GameRecord gameRecord) {
    final moveCount = gameRecord.totalMoves;
    final moveAnalyses = <MoveAnalysis>[];

    // Simulate move analysis based on game patterns
    for (int i = 0; i < moveCount; i++) {
      final quality = _assessMoveQuality(i, moveCount, gameRecord);
      moveAnalyses.add(
        MoveAnalysis(
          moveNumber: i + 1,
          position: 'Position ${i + 1}',
          actualMove: 'Move at position ${(i ~/ 8 + 1)}-${(i % 8 + 1)}',
          betterMove: _suggestAlternative(i, quality),
          quality: quality,
          confidence: 0.75 + (0.2 * (i / moveCount)),
          explanation: _getExplanation(quality, i, moveCount),
          boardState: i,
        ),
      );
    }

    // Calculate statistics
    final excellentCount =
        moveAnalyses.where((m) => m.quality == 'excellent').length;
    final goodCount = moveAnalyses.where((m) => m.quality == 'good').length;
    final acceptableCount =
        moveAnalyses.where((m) => m.quality == 'acceptable').length;
    final suboptimalCount =
        moveAnalyses.where((m) => m.quality == 'suboptimal').length;
    final criticalCount =
        moveAnalyses.where((m) => m.quality == 'critical_error').length;

    final qualityScore = (excellentCount * 2 +
            goodCount * 1.5 +
            acceptableCount * 1 +
            suboptimalCount * 0.5) /
        (moveCount * 2);
    final accuracy = (qualityScore * 100).clamp(0, 100).toDouble();

    return GameMovesAnalysis(
      gameRecord: gameRecord,
      moveAnalyses: moveAnalyses,
      overallAccuracy: accuracy,
      excellentMoves: excellentCount,
      goodMoves: goodCount,
      acceptableMoves: acceptableCount,
      suboptimalMoves: suboptimalCount,
      criticalErrors: criticalCount,
      gamePhaseAnalysis: _analyzePhases(moveAnalyses),
      strengthAreas: _identifyStrengths(moveAnalyses),
      improvementAreas: _identifyImprovements(moveAnalyses),
      overallFeedback:
          _generateOverallFeedback(accuracy, criticalCount, moveCount),
    );
  }

  /// Assess move quality based on position
  static String _assessMoveQuality(
    int moveIndex,
    int totalMoves,
    GameRecord record,
  ) {
    // Early game moves
    if (moveIndex < totalMoves * 0.2) {
      if (moveIndex % 3 == 0) return 'excellent';
      if (moveIndex % 3 == 1) return 'good';
      return 'acceptable';
    }

    // Mid game - more variance
    if (moveIndex < totalMoves * 0.7) {
      if (moveIndex % 5 == 0) return 'critical_error';
      if (moveIndex % 5 == 1) return 'suboptimal';
      if (moveIndex % 5 == 2) return 'acceptable';
      if (moveIndex % 5 == 3) return 'good';
      return 'excellent';
    }

    // End game - depends on result
    if (record.result == GameResult.playerAWins) {
      if (moveIndex % 4 == 0) return 'excellent';
      if (moveIndex % 4 == 1) return 'good';
      return 'acceptable';
    } else if (record.result == GameResult.draw) {
      if (moveIndex % 3 == 0) return 'good';
      return 'acceptable';
    } else {
      if (moveIndex % 3 == 0) return 'critical_error';
      return 'suboptimal';
    }
  }

  /// Suggest alternative move
  static String? _suggestAlternative(int moveIndex, String quality) {
    if (quality == 'critical_error' || quality == 'suboptimal') {
      return 'Alternative move at position ${(moveIndex + 1 ~/ 8 + 1)}-${((moveIndex + 1) % 8 + 1)}';
    }
    return null;
  }

  /// Get explanation for move quality
  static String _getExplanation(String quality, int moveIndex, int totalMoves) {
    switch (quality) {
      case 'excellent':
        return '盤面を支配し、相手の選択肢を制限するよい手です';
      case 'good':
        return '安定した手です。さらに強い手があるかもしれません';
      case 'acceptable':
        return '許容可能な手ですが、改善の余地があります';
      case 'suboptimal':
        return 'より良い手がありました。この局面を見直してください';
      case 'critical_error':
        return 'この手は局面を一気に悪化させています';
      default:
        return '';
    }
  }

  /// Analyze game phases
  static String _analyzePhases(List<MoveAnalysis> moves) {
    if (moves.isEmpty) return '分析できません';

    final earlyGood = moves
        .take((moves.length * 0.2).toInt())
        .where((m) => m.quality == 'excellent' || m.quality == 'good')
        .length;
    final midGood = moves
        .skip((moves.length * 0.2).toInt())
        .take((moves.length * 0.5).toInt())
        .where((m) => m.quality == 'excellent' || m.quality == 'good')
        .length;
    final lateGood = moves
        .skip((moves.length * 0.7).toInt())
        .where((m) => m.quality == 'excellent' || m.quality == 'good')
        .length;

    return '早盤: 安定、中盤: ${midGood > earlyGood ? "強い" : "要改善"}、終盤: ${lateGood > 0 ? "良い" : "課題あり"}';
  }

  /// Identify strength areas
  static List<String> _identifyStrengths(List<MoveAnalysis> moves) {
    if (moves.isEmpty) return [];

    final strengths = <String>[];

    // Check opening
    final earlyGood = moves
        .take((moves.length * 0.2).toInt())
        .where((m) => m.quality == 'excellent' || m.quality == 'good')
        .length;
    if (earlyGood > moves.length * 0.1) strengths.add('オープニング');

    // Check consistency
    final consistentMoves =
        moves.where((m) => m.quality == 'good' || m.quality == 'excellent');
    if (consistentMoves.length > moves.length * 0.6) {
      strengths.add('一貫性のある判断');
    }

    if (strengths.isEmpty) strengths.add('改善の機会が多くあります');

    return strengths;
  }

  /// Identify improvement areas
  static List<String> _identifyImprovements(List<MoveAnalysis> moves) {
    if (moves.isEmpty) return [];

    final improvements = <String>[];

    // Check for critical errors
    final criticals =
        moves.where((m) => m.quality == 'critical_error').length;
    if (criticals > 0) improvements.add('致命的なエラー回避');

    // Check mid-game
    final midMoves = moves
        .skip((moves.length * 0.2).toInt())
        .take((moves.length * 0.5).toInt());
    final midGood = midMoves
        .where((m) => m.quality == 'excellent' || m.quality == 'good')
        .length;
    if (midGood < midMoves.length * 0.4) {
      improvements.add('ミッドゲーム戦略');
    }

    if (improvements.isEmpty) improvements.add('全体的に良い判断です');

    return improvements;
  }

  /// Generate overall feedback
  static String _generateOverallFeedback(
    double accuracy,
    int criticalCount,
    int totalMoves,
  ) {
    if (accuracy >= 80) {
      return '素晴らしい実力です！一貫性のある高い精度を保っています';
    } else if (accuracy >= 60) {
      return '良い判断が目立ちます。ミッドゲームの改善でさらに強くなります';
    } else if (accuracy >= 40) {
      return '基本は堅実です。戦術的な改善で大きく成長できます';
    } else {
      return '基本を見直すことで大きな改善が期待できます';
    }
  }

  /// Clear analysis
  void clear() {
    state = const MoveAnalysisState();
  }
}

/// Riverpod provider for move analysis
final moveAnalysisProvider =
    StateNotifierProvider<MoveAnalysisNotifier, MoveAnalysisState>((ref) {
  return MoveAnalysisNotifier();
});
