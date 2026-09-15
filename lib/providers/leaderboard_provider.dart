import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'game_analytics_provider.dart';
import 'player_profile_provider.dart';

/// Player leaderboard entry
class LeaderboardEntry {
  final String playerId;
  final String playerName;
  final int rank;
  final double rating;
  final int wins;
  final int totalGames;
  final double winRate;
  final int streak;
  final String skillLevel;
  final DateTime lastPlayedAt;

  const LeaderboardEntry({
    required this.playerId,
    required this.playerName,
    required this.rank,
    required this.rating,
    required this.wins,
    required this.totalGames,
    required this.winRate,
    required this.streak,
    required this.skillLevel,
    required this.lastPlayedAt,
  });

  /// Get rank badge emoji
  String getRankEmoji() {
    if (rank == 1) return '🥇';
    if (rank == 2) return '🥈';
    if (rank == 3) return '🥉';
    if (rank <= 10) return '⭐';
    return '📊';
  }

  /// Get rank label
  String getRankLabel() {
    if (rank == 1) return 'グランドマスター';
    if (rank <= 10) return 'マスター';
    if (rank <= 50) return 'エキスパート';
    if (rank <= 100) return 'アドバンス';
    return 'チャレンジャー';
  }

  /// Get rating category
  String getRatingCategory() {
    if (rating >= 3000) return 'S+';
    if (rating >= 2500) return 'S';
    if (rating >= 2000) return 'A+';
    if (rating >= 1500) return 'A';
    if (rating >= 1000) return 'B+';
    if (rating >= 500) return 'B';
    return 'C';
  }
}

/// Leaderboard time period
enum LeaderboardPeriod {
  allTime('全期間'),
  thisMonth('今月'),
  thisWeek('今週'),
  today('今日');

  final String label;
  const LeaderboardPeriod(this.label);
}

/// Leaderboard state
class LeaderboardState {
  final List<LeaderboardEntry> entries;
  final LeaderboardPeriod period;
  final int? playerRank;
  final LeaderboardEntry? playerEntry;
  final bool isLoading;
  final String? error;

  const LeaderboardState({
    required this.entries,
    required this.period,
    this.playerRank,
    this.playerEntry,
    this.isLoading = false,
    this.error,
  });

  /// Get top 3 entries for featured section
  List<LeaderboardEntry> getTopThree() {
    return entries.take(3).toList();
  }

  /// Get entries around player rank
  List<LeaderboardEntry> getPlayerContext() {
    if (playerRank == null) return [];
    final startIdx = (playerRank! - 3).clamp(0, entries.length - 1);
    final endIdx = (playerRank! + 2).clamp(0, entries.length);
    return entries.sublist(startIdx, endIdx);
  }

  /// Get player advantage/disadvantage vs average
  double getPlayerAdvantageVsAverage() {
    if (playerEntry == null || entries.isEmpty) return 0;
    final avgRating =
        entries.fold<double>(0, (sum, e) => sum + e.rating) / entries.length;
    return ((playerEntry!.rating - avgRating) / avgRating * 100).clamp(-100, 100);
  }

  /// Copy with modifications
  LeaderboardState copyWith({
    List<LeaderboardEntry>? entries,
    LeaderboardPeriod? period,
    int? playerRank,
    LeaderboardEntry? playerEntry,
    bool? isLoading,
    String? error,
  }) {
    return LeaderboardState(
      entries: entries ?? this.entries,
      period: period ?? this.period,
      playerRank: playerRank ?? this.playerRank,
      playerEntry: playerEntry ?? this.playerEntry,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

/// Notifier for leaderboard
class LeaderboardNotifier extends StateNotifier<LeaderboardState> {
  final GameAnalyticsState analytics;
  final PlayerProfile? playerProfile;

  LeaderboardNotifier(this.analytics, this.playerProfile)
      : super(_buildState(analytics, playerProfile, LeaderboardPeriod.allTime)) {
    _initializeLeaderboard();
  }

  /// Initialize leaderboard
  void _initializeLeaderboard() {
    // In a real app, this would fetch from a backend
    // For now, we generate simulated leaderboard data
  }

  /// Build leaderboard state
  static LeaderboardState _buildState(
    GameAnalyticsState analytics,
    PlayerProfile? playerProfile,
    LeaderboardPeriod period,
  ) {
    // Generate simulated leaderboard entries
    final entries = _generateLeaderboardEntries(analytics, period);

    // Find player rank if profile exists
    int? playerRank;
    LeaderboardEntry? playerEntry;

    if (playerProfile != null) {
      final playerRating =
          _calculatePlayerRating(playerProfile, analytics);
      playerEntry = LeaderboardEntry(
        playerId: 'current_player',
        playerName: 'あなた',
        rank: 0, // Will be set below
        rating: playerRating,
        wins: playerProfile.wins,
        totalGames: playerProfile.totalGames,
        winRate: playerProfile.winRate,
        streak: playerProfile.currentStreak,
        skillLevel: playerProfile.skillLevel,
        lastPlayedAt: DateTime.now(),
      );

      // Find player's rank
      for (int i = 0; i < entries.length; i++) {
        if (entries[i].rating <= playerRating) {
          playerRank = i + 1;
          playerEntry = playerEntry.copyWith(rank: playerRank);
          break;
        }
      }

      // If player is at bottom, assign last rank
      if (playerRank == null) {
        playerRank = entries.length + 1;
        playerEntry = playerEntry.copyWith(rank: playerRank);
      }
    }

    return LeaderboardState(
      entries: entries,
      period: period,
      playerRank: playerRank,
      playerEntry: playerEntry,
      isLoading: false,
    );
  }

  /// Generate simulated leaderboard entries
  static List<LeaderboardEntry> _generateLeaderboardEntries(
    GameAnalyticsState analytics,
    LeaderboardPeriod period,
  ) {
    final entries = <LeaderboardEntry>[];

    // Generate top 100 simulated players
    final baseWinRate = analytics.overallWinRate;
    final baseGames = analytics.totalGamesAnalyzed;

    for (int i = 0; i < 100; i++) {
      final variance = (i * 0.5);
      final rating = ((3000 - (i * 25)) - variance).clamp(100, 3000);
      final winRate = (baseWinRate - (i * 0.003)).clamp(0.2, 0.9);
      final games = (baseGames + (100 - i) * 10).toInt();
      final wins = (games * winRate).toInt();

      entries.add(LeaderboardEntry(
        playerId: 'player_$i',
        playerName: _generatePlayerName(i),
        rank: i + 1,
        rating: rating,
        wins: wins,
        totalGames: games,
        winRate: winRate,
        streak: (20 - (i % 10)).clamp(0, 20),
        skillLevel: _getSkillLevelFromRating(rating),
        lastPlayedAt: DateTime.now().subtract(
          Duration(days: (i % 30)),
        ),
      ));
    }

    return entries;
  }

  /// Calculate player rating based on profile and analytics
  static double _calculatePlayerRating(
    PlayerProfile profile,
    GameAnalyticsState analytics,
  ) {
    // Rating formula: base on wins, win rate, and game diversity
    final winBonus = profile.wins * 10;
    final rateBonus = profile.winRate * 1000;
    final consistencyBonus = analytics.totalGamesAnalyzed > 50 ? 200 : 0;
    final streakBonus = profile.currentStreak * 20;

    return (winBonus + rateBonus + consistencyBonus + streakBonus)
        .clamp(100, 3000)
        .toDouble();
  }

  /// Generate player name
  static String _generatePlayerName(int index) {
    final names = [
      'リバーシマスター',
      'ビッグプレイヤー',
      'スマートプレイ',
      'ウィニング戦略',
      'パワープレイヤー',
      'チャンピオン',
      'ナイトレイダー',
      'アイスブレイカー',
      'ロックスター',
      'ファイアスター',
    ];
    return '${names[index % names.length]}_${index + 1}';
  }

  /// Get skill level from rating
  static String _getSkillLevelFromRating(double rating) {
    if (rating >= 2700) return 'マスター';
    if (rating >= 2300) return 'アドバンス';
    if (rating >= 1900) return 'インターミディエイト';
    if (rating >= 1500) return 'ビギナー+';
    return 'ビギナー';
  }

  /// Change leaderboard period
  void setPeriod(LeaderboardPeriod period) {
    state = _buildState(analytics, playerProfile, period);
  }
}

extension _LeaderboardEntryCopyWith on LeaderboardEntry {
  LeaderboardEntry copyWith({
    String? playerId,
    String? playerName,
    int? rank,
    double? rating,
    int? wins,
    int? totalGames,
    double? winRate,
    int? streak,
    String? skillLevel,
    DateTime? lastPlayedAt,
  }) {
    return LeaderboardEntry(
      playerId: playerId ?? this.playerId,
      playerName: playerName ?? this.playerName,
      rank: rank ?? this.rank,
      rating: rating ?? this.rating,
      wins: wins ?? this.wins,
      totalGames: totalGames ?? this.totalGames,
      winRate: winRate ?? this.winRate,
      streak: streak ?? this.streak,
      skillLevel: skillLevel ?? this.skillLevel,
      lastPlayedAt: lastPlayedAt ?? this.lastPlayedAt,
    );
  }
}

/// Riverpod provider for leaderboard
final leaderboardProvider =
    StateNotifierProvider<LeaderboardNotifier, LeaderboardState>((ref) {
  final analytics = ref.watch(gameAnalyticsProvider);
  final playerProfile = ref.watch(playerProfileProvider);

  return LeaderboardNotifier(analytics, playerProfile);
});
