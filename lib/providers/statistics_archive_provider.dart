import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:math' as math;

/// Time period for statistics
enum StatsPeriod {
  daily('1日'),
  weekly('1週間'),
  monthly('1ヶ月'),
  allTime('全期間');

  final String label;
  const StatsPeriod(this.label);
}

/// Statistics snapshot for a time period
class StatsSnapshot {
  final DateTime timestamp;
  final int wins;
  final int losses;
  final int totalGames;
  final double winRate;
  final int totalPoints;
  final int avgPointsPerGame;
  final double avgGameDuration; // in minutes

  const StatsSnapshot({
    required this.timestamp,
    required this.wins,
    required this.losses,
    required this.totalGames,
    required this.winRate,
    required this.totalPoints,
    required this.avgPointsPerGame,
    required this.avgGameDuration,
  });

  StatsSnapshot copyWith({
    DateTime? timestamp,
    int? wins,
    int? losses,
    int? totalGames,
    double? winRate,
    int? totalPoints,
    int? avgPointsPerGame,
    double? avgGameDuration,
  }) {
    return StatsSnapshot(
      timestamp: timestamp ?? this.timestamp,
      wins: wins ?? this.wins,
      losses: losses ?? this.losses,
      totalGames: totalGames ?? this.totalGames,
      winRate: winRate ?? this.winRate,
      totalPoints: totalPoints ?? this.totalPoints,
      avgPointsPerGame: avgPointsPerGame ?? this.avgPointsPerGame,
      avgGameDuration: avgGameDuration ?? this.avgGameDuration,
    );
  }
}

/// Statistics milestone (achievement in stats)
class StatsMilestone {
  final String id;
  final String title;
  final String description;
  final String emoji;
  final DateTime achievedDate;
  final String category; // 'wins', 'winrate', 'consistency', etc.

  const StatsMilestone({
    required this.id,
    required this.title,
    required this.description,
    required this.emoji,
    required this.achievedDate,
    required this.category,
  });
}

/// Statistics archive state
class StatisticsArchiveState {
  final List<StatsSnapshot> dailySnapshots;
  final List<StatsSnapshot> weeklySnapshots;
  final List<StatsSnapshot> monthlySnapshots;
  final StatsSnapshot? overallStats;
  final List<StatsMilestone> milestones;
  final double bestWinRate;
  final int highestWinStreak;
  final DateTime lastUpdated;
  final bool isLoading;
  final String? error;

  const StatisticsArchiveState({
    required this.dailySnapshots,
    required this.weeklySnapshots,
    required this.monthlySnapshots,
    this.overallStats,
    required this.milestones,
    this.bestWinRate = 0.0,
    this.highestWinStreak = 0,
    required this.lastUpdated,
    this.isLoading = false,
    this.error,
  });

  /// Copy with modifications
  StatisticsArchiveState copyWith({
    List<StatsSnapshot>? dailySnapshots,
    List<StatsSnapshot>? weeklySnapshots,
    List<StatsSnapshot>? monthlySnapshots,
    StatsSnapshot? overallStats,
    List<StatsMilestone>? milestones,
    double? bestWinRate,
    int? highestWinStreak,
    DateTime? lastUpdated,
    bool? isLoading,
    String? error,
  }) {
    return StatisticsArchiveState(
      dailySnapshots: dailySnapshots ?? this.dailySnapshots,
      weeklySnapshots: weeklySnapshots ?? this.weeklySnapshots,
      monthlySnapshots: monthlySnapshots ?? this.monthlySnapshots,
      overallStats: overallStats ?? this.overallStats,
      milestones: milestones ?? this.milestones,
      bestWinRate: bestWinRate ?? this.bestWinRate,
      highestWinStreak: highestWinStreak ?? this.highestWinStreak,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

/// Notifier for statistics archive
class StatisticsArchiveNotifier extends StateNotifier<StatisticsArchiveState> {
  SharedPreferences? _prefs;

  StatisticsArchiveNotifier()
      : super(_buildInitialState()) {
    _initializeArchive();
  }

  /// Initialize archive
  Future<void> _initializeArchive() async {
    final prefs = await SharedPreferences.getInstance();
    _prefs = prefs;
    _generateHistoricalData();
  }

  /// Build initial state
  static StatisticsArchiveState _buildInitialState() {
    return StatisticsArchiveState(
      dailySnapshots: [],
      weeklySnapshots: [],
      monthlySnapshots: [],
      milestones: [],
      lastUpdated: DateTime.now(),
    );
  }

  /// Generate historical statistics data
  void _generateHistoricalData() {
    final now = DateTime.now();
    final random = math.Random();

    // Generate daily snapshots (last 30 days)
    final dailySnapshots = <StatsSnapshot>[];
    for (int i = 29; i >= 0; i--) {
      final date = now.subtract(Duration(days: i));
      final gamesCount = random.nextInt(15) + 5;
      final wins = random.nextInt(gamesCount + 1);
      final losses = gamesCount - wins;
      final totalPoints = wins * random.nextInt(100) + random.nextInt(100);

      dailySnapshots.add(StatsSnapshot(
        timestamp: date,
        wins: wins,
        losses: losses,
        totalGames: gamesCount,
        winRate: gamesCount > 0 ? wins / gamesCount : 0.0,
        totalPoints: totalPoints,
        avgPointsPerGame:
            gamesCount > 0 ? (totalPoints ~/ gamesCount) : 0,
        avgGameDuration: random.nextDouble() * 10 + 5, // 5-15 minutes
      ));
    }

    // Generate weekly snapshots (last 12 weeks)
    final weeklySnapshots = <StatsSnapshot>[];
    for (int i = 11; i >= 0; i--) {
      final weekStart = now.subtract(Duration(days: i * 7));
      final gamesCount = random.nextInt(100) + 50;
      final wins = random.nextInt(gamesCount + 1);
      final losses = gamesCount - wins;
      final totalPoints =
          wins * random.nextInt(100) + random.nextInt(500);

      weeklySnapshots.add(StatsSnapshot(
        timestamp: weekStart,
        wins: wins,
        losses: losses,
        totalGames: gamesCount,
        winRate: gamesCount > 0 ? wins / gamesCount : 0.0,
        totalPoints: totalPoints,
        avgPointsPerGame:
            gamesCount > 0 ? (totalPoints ~/ gamesCount) : 0,
        avgGameDuration: random.nextDouble() * 10 + 5,
      ));
    }

    // Generate monthly snapshots (last 12 months)
    final monthlySnapshots = <StatsSnapshot>[];
    for (int i = 11; i >= 0; i--) {
      final monthStart = DateTime(now.year, now.month - i, 1);
      final gamesCount = random.nextInt(500) + 200;
      final wins = random.nextInt(gamesCount + 1);
      final losses = gamesCount - wins;
      final totalPoints =
          wins * random.nextInt(100) + random.nextInt(2000);

      monthlySnapshots.add(StatsSnapshot(
        timestamp: monthStart,
        wins: wins,
        losses: losses,
        totalGames: gamesCount,
        winRate: gamesCount > 0 ? wins / gamesCount : 0.0,
        totalPoints: totalPoints,
        avgPointsPerGame:
            gamesCount > 0 ? (totalPoints ~/ gamesCount) : 0,
        avgGameDuration: random.nextDouble() * 10 + 5,
      ));
    }

    // Calculate overall stats
    final totalWins = dailySnapshots.fold(0, (sum, s) => sum + s.wins);
    final totalLosses = dailySnapshots.fold(0, (sum, s) => sum + s.losses);
    final totalGames = totalWins + totalLosses;
    final overallStats = StatsSnapshot(
      timestamp: now,
      wins: totalWins,
      losses: totalLosses,
      totalGames: totalGames,
      winRate: totalGames > 0 ? totalWins / totalGames : 0.0,
      totalPoints:
          dailySnapshots.fold(0, (sum, s) => sum + s.totalPoints),
      avgPointsPerGame: totalGames > 0
          ? (dailySnapshots.fold(0, (sum, s) => sum + s.totalPoints) ~/
              totalGames)
          : 0,
      avgGameDuration: 7.5,
    );

    // Generate milestones
    final milestones = _generateMilestones(
      overallStats,
      dailySnapshots,
      weeklySnapshots,
    );

    // Calculate best win rate and highest streak
    double bestRate = overallStats.winRate;
    for (final snapshot in dailySnapshots) {
      if (snapshot.totalGames >= 5 && snapshot.winRate > bestRate) {
        bestRate = snapshot.winRate;
      }
    }

    int highestStreak = 0;
    int currentStreak = 0;
    for (final snapshot in dailySnapshots) {
      if (snapshot.wins > snapshot.losses) {
        currentStreak++;
        highestStreak = math.max(highestStreak, currentStreak);
      } else {
        currentStreak = 0;
      }
    }

    state = state.copyWith(
      dailySnapshots: dailySnapshots,
      weeklySnapshots: weeklySnapshots,
      monthlySnapshots: monthlySnapshots,
      overallStats: overallStats,
      milestones: milestones,
      bestWinRate: bestRate,
      highestWinStreak: highestStreak,
      lastUpdated: now,
    );
  }

  /// Generate milestones based on statistics
  List<StatsMilestone> _generateMilestones(
    StatsSnapshot overallStats,
    List<StatsSnapshot> dailySnapshots,
    List<StatsSnapshot> weeklySnapshots,
  ) {
    final milestones = <StatsMilestone>[];

    // First game milestone
    if (overallStats.totalGames >= 1) {
      milestones.add(StatsMilestone(
        id: 'first_game',
        title: '初試合',
        description: '最初のゲームをプレイ',
        emoji: '🎮',
        achievedDate: dailySnapshots.first.timestamp,
        category: 'milestones',
      ));
    }

    // 100 games milestone
    if (overallStats.totalGames >= 100) {
      milestones.add(StatsMilestone(
        id: 'milestone_100',
        title: '100試合達成',
        description: '100ゲームをプレイ',
        emoji: '💯',
        achievedDate: DateTime.now().subtract(Duration(days: 10)),
        category: 'milestones',
      ));
    }

    // 500 games milestone
    if (overallStats.totalGames >= 500) {
      milestones.add(StatsMilestone(
        id: 'milestone_500',
        title: '500試合達成',
        description: '500ゲームをプレイ',
        emoji: '🔥',
        achievedDate: DateTime.now().subtract(Duration(days: 5)),
        category: 'milestones',
      ));
    }

    // High win rate milestone
    if (overallStats.winRate >= 0.65) {
      milestones.add(StatsMilestone(
        id: 'high_winrate',
        title: '高勝率達成',
        description: '65%以上の勝率を達成',
        emoji: '📈',
        achievedDate: DateTime.now().subtract(Duration(days: 15)),
        category: 'winrate',
      ));
    }

    // Consistent play milestone
    if (dailySnapshots
        .where((s) => s.totalGames > 0)
        .length >=
        14) {
      milestones.add(StatsMilestone(
        id: 'consistent',
        title: '継続プレイヤー',
        description: '14日以上連続でプレイ',
        emoji: '⭐',
        achievedDate: DateTime.now().subtract(Duration(days: 3)),
        category: 'consistency',
      ));
    }

    return milestones;
  }

  /// Record daily snapshot (called periodically)
  Future<void> recordDailySnapshot(StatsSnapshot snapshot) async {
    final prefs = _prefs ??= await SharedPreferences.getInstance();
    final archive = prefs.getStringList('daily_snapshots') ?? [];
    // Keep last 90 days
    if (archive.length >= 90) {
      archive.removeAt(0);
    }
    archive.add(_snapshotToJson(snapshot));
    await prefs.setStringList('daily_snapshots', archive);
  }

  /// Convert snapshot to JSON string for storage
  String _snapshotToJson(StatsSnapshot snapshot) {
    return '${snapshot.timestamp.toIso8601String()}|${snapshot.wins}|${snapshot.losses}|${snapshot.totalGames}|${snapshot.totalPoints}|${snapshot.avgGameDuration}';
  }
}

/// Riverpod provider for statistics archive
final statisticsArchiveProvider =
    StateNotifierProvider<StatisticsArchiveNotifier, StatisticsArchiveState>(
  (ref) => StatisticsArchiveNotifier(),
);

/// Alternative sync provider (for testing)
final statisticsArchiveSyncProvider =
    StateNotifierProvider<StatisticsArchiveNotifier, StatisticsArchiveState>(
        (ref) {
  throw UnimplementedError();
});
