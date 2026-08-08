import 'ai.dart';

/// Simple shogi-style rank ladder (級位→段位) driven by accumulated rank
/// points from AI wins. Design doc Section5 "R①Retention: 段位制（将棋の級位感）".
/// Thresholds/weights are a first-pass guess, not tuned against real play data.
const List<int> _rankThresholds = [0, 6, 12, 20, 30, 42, 56, 72, 90, 110];
const List<String> _rankLabels = [
  '10級',
  '9級',
  '7級',
  '5級',
  '3級',
  '1級',
  '初段',
  '二段',
  '三段',
  '四段',
];

/// Beating a harder AI is worth more toward rank than beating an easy one,
/// so the ladder rewards real difficulty rather than just match count.
int rankPointsForWin(AiDifficulty difficulty) {
  switch (difficulty) {
    case AiDifficulty.easy:
      return 1;
    case AiDifficulty.medium:
      return 2;
    case AiDifficulty.hard:
      return 4;
  }
}

String rankLabelForWins(int points) {
  var label = _rankLabels.first;
  for (var i = 0; i < _rankThresholds.length; i++) {
    if (points >= _rankThresholds[i]) label = _rankLabels[i];
  }
  return label;
}

/// Full rank-ladder standing for a "段位詳細" screen: current label plus how
/// far along the player is toward the next rank (null next* fields mean the
/// top of the ladder has been reached).
class RankProgress {
  final String label;
  final int points;
  final String? nextLabel;
  final int? pointsToNext;
  final double progressToNext; // 0.0-1.0, always 1.0 at the top of the ladder

  const RankProgress({
    required this.label,
    required this.points,
    required this.nextLabel,
    required this.pointsToNext,
    required this.progressToNext,
  });
}

RankProgress rankProgressForPoints(int points) {
  var currentIndex = 0;
  for (var i = 0; i < _rankThresholds.length; i++) {
    if (points >= _rankThresholds[i]) currentIndex = i;
  }

  final label = _rankLabels[currentIndex];
  final isMaxed = currentIndex == _rankThresholds.length - 1;
  if (isMaxed) {
    return RankProgress(
      label: label,
      points: points,
      nextLabel: null,
      pointsToNext: null,
      progressToNext: 1,
    );
  }

  final currentThreshold = _rankThresholds[currentIndex];
  final nextThreshold = _rankThresholds[currentIndex + 1];
  final span = nextThreshold - currentThreshold;
  final progress = span == 0 ? 1.0 : (points - currentThreshold) / span;

  return RankProgress(
    label: label,
    points: points,
    nextLabel: _rankLabels[currentIndex + 1],
    pointsToNext: nextThreshold - points,
    progressToNext: progress.clamp(0, 1).toDouble(),
  );
}
