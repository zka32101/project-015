import 'models.dart';

/// Information about an AI's move decision, including thinking details.
class AiMoveResult {
  final Move? move;
  final int? evaluationScore;
  final int searchDepth;
  final Duration thinkingTime;

  const AiMoveResult({
    required this.move,
    this.evaluationScore,
    required this.searchDepth,
    required this.thinkingTime,
  });

  /// Copies this result with optional field overrides.
  AiMoveResult copyWith({
    Move? move,
    int? evaluationScore,
    int? searchDepth,
    Duration? thinkingTime,
  }) {
    return AiMoveResult(
      move: move ?? this.move,
      evaluationScore: evaluationScore ?? this.evaluationScore,
      searchDepth: searchDepth ?? this.searchDepth,
      thinkingTime: thinkingTime ?? this.thinkingTime,
    );
  }
}
