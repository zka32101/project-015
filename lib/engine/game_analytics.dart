import 'package:intl/intl.dart';
import 'statistics.dart';

/// Advanced game analytics and performance metrics
class GameAnalytics {
  final GameStatistics baseStats;
  final List<GameSession> sessionHistory;

  GameAnalytics({
    required this.baseStats,
    List<GameSession>? sessionHistory,
  }) : sessionHistory = sessionHistory ?? [];

  // ============ Overall Statistics ============

  /// Total win rate across all games
  double get totalWinRate {
    if (baseStats.totalGames == 0) return 0.0;
    return baseStats.playerAWins / baseStats.totalGames;
  }

  /// Win rate formatted as percentage
  String get totalWinRatePercentage {
    return '${(totalWinRate * 100).toStringAsFixed(1)}%';
  }

  /// Average win/loss ratio
  double get winLossRatio {
    if (baseStats.playerBWins == 0) return baseStats.playerAWins.toDouble();
    return baseStats.playerAWins / baseStats.playerBWins;
  }

  /// Draw rate
  double get drawRate {
    if (baseStats.totalGames == 0) return 0.0;
    return baseStats.draws / baseStats.totalGames;
  }

  /// Draw rate as percentage
  String get drawRatePercentage {
    return '${(drawRate * 100).toStringAsFixed(1)}%';
  }

  // ============ Difficulty Analysis ============

  /// Get win rate against specific difficulty
  double getWinRateVsDifficulty(String difficulty) {
    final stats = baseStats.statsByDifficulty[difficulty];
    if (stats == null || stats.totalGames == 0) return 0.0;
    return stats.winRate;
  }

  /// Get formatted win rate for difficulty
  String getFormattedWinRateVsDifficulty(String difficulty) {
    final rate = getWinRateVsDifficulty(difficulty);
    return '${(rate * 100).toStringAsFixed(1)}%';
  }

  /// Get best difficulty performance
  String? getBestDifficulty() {
    String? best;
    double bestRate = -1;

    for (final entry in baseStats.statsByDifficulty.entries) {
      if (entry.value.totalGames == 0) continue;
      if (entry.value.winRate > bestRate) {
        bestRate = entry.value.winRate;
        best = entry.key;
      }
    }

    return best;
  }

  /// Get worst difficulty performance
  String? getWorstDifficulty() {
    String? worst;
    double worstRate = double.maxFinite;

    for (final entry in baseStats.statsByDifficulty.entries) {
      if (entry.value.totalGames == 0) continue;
      if (entry.value.winRate < worstRate) {
        worstRate = entry.value.winRate;
        worst = entry.key;
      }
    }

    return worst;
  }

  // ============ Streak Analysis ============

  /// Current active streak
  int get currentStreak {
    return (baseStats.playerAWinStreak > 0)
        ? baseStats.playerAWinStreak
        : -(baseStats.playerBWinStreak);
  }

  /// Streak type: 'win', 'loss', or 'none'
  String get currentStreakType {
    if (baseStats.playerAWinStreak > 0) return 'win';
    if (baseStats.playerBWinStreak > 0) return 'loss';
    return 'none';
  }

  /// Best ever win streak
  int get bestWinStreak => baseStats.playerALongestStreak;

  /// Best ever loss streak (tracked separately)
  int bestLossStreak = 0;

  // ============ Time-based Analytics ============

  /// Games played in last N days
  int getGamesInLastDays(int days) {
    final cutoffDate = DateTime.now().subtract(Duration(days: days));
    return sessionHistory.where((s) => s.playedAt.isAfter(cutoffDate)).length;
  }

  /// Average games per day over last N days
  double getAverageGamesPerDay(int days) {
    final gamesInPeriod = getGamesInLastDays(days);
    return gamesInPeriod / days;
  }

  /// Most active day of week (0 = Monday, 6 = Sunday)
  int? getMostActiveDayOfWeek() {
    if (sessionHistory.isEmpty) return null;

    final dayMap = <int, int>{};
    for (final session in sessionHistory) {
      final day = session.playedAt.weekday;
      dayMap[day] = (dayMap[day] ?? 0) + 1;
    }

    int? mostActive;
    int maxCount = 0;
    for (final entry in dayMap.entries) {
      if (entry.value > maxCount) {
        maxCount = entry.value;
        mostActive = entry.key;
      }
    }

    return mostActive;
  }

  /// Get day name from weekday number
  String getDayName(int weekday) {
    const days = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    return weekday >= 1 && weekday <= 7 ? days[weekday - 1] : 'Unknown';
  }

  // ============ Performance Metrics ============

  /// Win rate trend: negative = declining, positive = improving
  double getWinRateTrend(int lastNGames) {
    if (sessionHistory.length < 2) return 0.0;

    final recentGames = sessionHistory.take(lastNGames).toList();
    if (recentGames.length < 2) return 0.0;

    // Calculate recent win rate
    final recentWins = recentGames.where((s) => s.playerAWon).length;
    final recentWinRate = recentWins / recentGames.length;

    // Compare to overall
    final trend = recentWinRate - totalWinRate;
    return trend;
  }

  /// Skill rating based on wins and streak
  int getSkillRating() {
    // Simple rating: base 1000 + wins*10 + streak*5
    int rating = 1000 + (baseStats.playerAWins * 10) + (baseStats.playerAWinStreak * 5);
    return rating.clamp(0, 999999);
  }

  /// Performance level description
  String getPerformanceLevel() {
    final rate = totalWinRate;
    if (rate >= 0.75) return 'Excellent';
    if (rate >= 0.60) return 'Very Good';
    if (rate >= 0.50) return 'Good';
    if (rate >= 0.40) return 'Fair';
    if (rate >= 0.25) return 'Needs Work';
    return 'Beginner';
  }

  // ============ Achievements ============

  /// Check if player has achieved milestone
  bool hasMilestone(String milestone) {
    switch (milestone) {
      case 'first_win':
        return baseStats.playerAWins >= 1;
      case 'ten_wins':
        return baseStats.playerAWins >= 10;
      case 'fifty_wins':
        return baseStats.playerAWins >= 50;
      case 'hundred_wins':
        return baseStats.playerAWins >= 100;
      case 'win_streak_5':
        return baseStats.playerALongestStreak >= 5;
      case 'win_streak_10':
        return baseStats.playerALongestStreak >= 10;
      case 'perfect_game':
        return sessionHistory.any((s) => s.isPerfectWin);
      case 'beat_all_difficulties':
        return baseStats.statsByDifficulty.values.every((s) => s.wins > 0);
      default:
        return false;
    }
  }

  /// Get list of achieved milestones
  List<String> getAchievedMilestones() {
    const allMilestones = [
      'first_win',
      'ten_wins',
      'fifty_wins',
      'hundred_wins',
      'win_streak_5',
      'win_streak_10',
      'perfect_game',
      'beat_all_difficulties',
    ];
    return allMilestones.where((m) => hasMilestone(m)).toList();
  }

  /// Get milestone progress (0.0 to 1.0)
  double getMilestoneProgress(String milestone) {
    switch (milestone) {
      case 'ten_wins':
        return (baseStats.playerAWins / 10).clamp(0.0, 1.0);
      case 'fifty_wins':
        return (baseStats.playerAWins / 50).clamp(0.0, 1.0);
      case 'hundred_wins':
        return (baseStats.playerAWins / 100).clamp(0.0, 1.0);
      case 'win_streak_5':
        return (baseStats.playerAWinStreak / 5).clamp(0.0, 1.0);
      case 'win_streak_10':
        return (baseStats.playerAWinStreak / 10).clamp(0.0, 1.0);
      default:
        return hasMilestone(milestone) ? 1.0 : 0.0;
    }
  }
}

/// Represents a single game session for analytics
class GameSession {
  final DateTime playedAt;
  final bool playerAWon;
  final String? aiDifficulty;
  final int movesCount;
  final Duration duration;
  final double playerAWinStrength; // 0.0 to 1.0

  const GameSession({
    required this.playedAt,
    required this.playerAWon,
    this.aiDifficulty,
    required this.movesCount,
    required this.duration,
    this.playerAWinStrength = 0.5,
  });

  /// Whether this was a dominant win (60%+ win strength)
  bool get isDominantWin => playerAWon && playerAWinStrength >= 0.6;

  /// Whether this was a close win (45-55% win strength)
  bool get isCloseWin => playerAWon && playerAWinStrength >= 0.45 && playerAWinStrength < 0.6;

  /// Whether this was a perfect win (100% win strength)
  bool get isPerfectWin => playerAWon && playerAWinStrength >= 0.95;

  /// Average moves per minute
  double get movesPerMinute {
    if (duration.inMinutes == 0) return 0.0;
    return movesCount / duration.inMinutes;
  }

  /// Format session date
  String getFormattedDate() {
    return DateFormat('MMM d, y HH:mm').format(playedAt);
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() => {
        'playedAt': playedAt.toIso8601String(),
        'playerAWon': playerAWon,
        'aiDifficulty': aiDifficulty,
        'movesCount': movesCount,
        'durationSeconds': duration.inSeconds,
        'playerAWinStrength': playerAWinStrength,
      };

  /// Create from JSON
  factory GameSession.fromJson(Map<String, dynamic> json) {
    return GameSession(
      playedAt: DateTime.parse(json['playedAt'] as String),
      playerAWon: json['playerAWon'] as bool,
      aiDifficulty: json['aiDifficulty'] as String?,
      movesCount: json['movesCount'] as int,
      duration: Duration(seconds: json['durationSeconds'] as int),
      playerAWinStrength: (json['playerAWinStrength'] as num?)?.toDouble() ?? 0.5,
    );
  }
}
