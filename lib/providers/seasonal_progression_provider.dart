import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'game_analytics_provider.dart';
import 'player_profile_provider.dart';

/// Seasonal tier level
enum SeasonalTier {
  bronze('ブロンズ', '🥉'),
  silver('シルバー', '⚪'),
  gold('ゴールド', '🟡'),
  platinum('プラチナ', '💎'),
  diamond('ダイヤモンド', '💠'),
  master('マスター', '👑');

  final String label;
  final String emoji;
  const SeasonalTier(this.label, this.emoji);

  /// Get tier color for UI
  String getHexColor() {
    switch (this) {
      case SeasonalTier.bronze:
        return '#CD7F32';
      case SeasonalTier.silver:
        return '#C0C0C0';
      case SeasonalTier.gold:
        return '#FFD700';
      case SeasonalTier.platinum:
        return '#E5E4E2';
      case SeasonalTier.diamond:
        return '#B9F2FF';
      case SeasonalTier.master:
        return '#FFD700';
    }
  }
}

/// Seasonal reward item
class SeasonalReward {
  final String id;
  final String name;
  final String description;
  final String emoji;
  final SeasonalTier requiredTier;
  final int seasonNumber;
  final bool isUnlocked;

  const SeasonalReward({
    required this.id,
    required this.name,
    required this.description,
    required this.emoji,
    required this.requiredTier,
    required this.seasonNumber,
    required this.isUnlocked,
  });
}

/// Season information
class Season {
  final int seasonNumber;
  final String name;
  final DateTime startDate;
  final DateTime endDate;
  final String theme;
  final String description;
  final List<SeasonalReward> rewards;

  const Season({
    required this.seasonNumber,
    required this.name,
    required this.startDate,
    required this.endDate,
    required this.theme,
    required this.description,
    required this.rewards,
  });

  /// Check if season is active
  bool get isActive {
    final now = DateTime.now();
    return now.isAfter(startDate) && now.isBefore(endDate);
  }

  /// Get days remaining in season
  int get daysRemaining {
    final now = DateTime.now();
    if (now.isAfter(endDate)) return 0;
    return endDate.difference(now).inDays;
  }

  /// Get season progress percentage
  double get progressPercentage {
    final totalDays = endDate.difference(startDate).inDays;
    final elapsedDays = DateTime.now().difference(startDate).inDays;
    return (elapsedDays / totalDays).clamp(0, 1);
  }
}

/// Player seasonal data
class PlayerSeasonalData {
  final int seasonNumber;
  final SeasonalTier currentTier;
  final int seasonalRating;
  final int seasonalWins;
  final int seasonalGames;
  final double seasonalWinRate;
  final int seasonalPoints;
  final List<SeasonalReward> unlockedRewards;
  final DateTime joinedAt;

  const PlayerSeasonalData({
    required this.seasonNumber,
    required this.currentTier,
    required this.seasonalRating,
    required this.seasonalWins,
    required this.seasonalGames,
    required this.seasonalWinRate,
    required this.seasonalPoints,
    required this.unlockedRewards,
    required this.joinedAt,
  });

  /// Get tier progress percentage
  double getTierProgress(SeasonalTier tier) {
    // Rating needed for each tier: 200, 400, 600, 800, 1000, 1200
    final tierRatings = {
      SeasonalTier.bronze: 200,
      SeasonalTier.silver: 400,
      SeasonalTier.gold: 600,
      SeasonalTier.platinum: 800,
      SeasonalTier.diamond: 1000,
      SeasonalTier.master: 1200,
    };

    final currentRating = seasonalRating;
    final nextTierRating = tierRatings[tier] ?? 1200;

    if (currentRating >= nextTierRating) return 1.0;

    // Get previous tier rating for progress calculation
    final tierOrder = SeasonalTier.values;
    final currentIndex = tierOrder.indexOf(tier);
    final previousRating =
        currentIndex > 0 ? tierRatings[tierOrder[currentIndex - 1]] ?? 0 : 0;

    final progress =
        ((currentRating - previousRating) / (nextTierRating - previousRating))
            .clamp(0, 1);
    return progress;
  }

  /// Copy with modifications
  PlayerSeasonalData copyWith({
    int? seasonNumber,
    SeasonalTier? currentTier,
    int? seasonalRating,
    int? seasonalWins,
    int? seasonalGames,
    double? seasonalWinRate,
    int? seasonalPoints,
    List<SeasonalReward>? unlockedRewards,
    DateTime? joinedAt,
  }) {
    return PlayerSeasonalData(
      seasonNumber: seasonNumber ?? this.seasonNumber,
      currentTier: currentTier ?? this.currentTier,
      seasonalRating: seasonalRating ?? this.seasonalRating,
      seasonalWins: seasonalWins ?? this.seasonalWins,
      seasonalGames: seasonalGames ?? this.seasonalGames,
      seasonalWinRate: seasonalWinRate ?? this.seasonalWinRate,
      seasonalPoints: seasonalPoints ?? this.seasonalPoints,
      unlockedRewards: unlockedRewards ?? this.unlockedRewards,
      joinedAt: joinedAt ?? this.joinedAt,
    );
  }
}

/// Seasonal progression state
class SeasonalProgressionState {
  final Season currentSeason;
  final List<Season> pastSeasons;
  final PlayerSeasonalData playerSeasonalData;
  final int seasonalRank;
  final SeasonalTier nextTier;
  final double nextTierProgress;
  final bool isLoading;
  final String? error;

  const SeasonalProgressionState({
    required this.currentSeason,
    required this.pastSeasons,
    required this.playerSeasonalData,
    required this.seasonalRank,
    required this.nextTier,
    required this.nextTierProgress,
    this.isLoading = false,
    this.error,
  });

  /// Get seasonal milestone rewards
  List<SeasonalReward> getMilestoneRewards() {
    return playerSeasonalData.unlockedRewards
        .where((r) => r.seasonNumber == currentSeason.seasonNumber)
        .toList();
  }

  /// Get progress to next tier
  int getRatingNeededForNextTier() {
    final tierRatings = {
      SeasonalTier.bronze: 200,
      SeasonalTier.silver: 400,
      SeasonalTier.gold: 600,
      SeasonalTier.platinum: 800,
      SeasonalTier.diamond: 1000,
      SeasonalTier.master: 1200,
    };
    final needed = tierRatings[nextTier] ?? 1200;
    return (needed - playerSeasonalData.seasonalRating).clamp(0, needed);
  }

  /// Copy with modifications
  SeasonalProgressionState copyWith({
    Season? currentSeason,
    List<Season>? pastSeasons,
    PlayerSeasonalData? playerSeasonalData,
    int? seasonalRank,
    SeasonalTier? nextTier,
    double? nextTierProgress,
    bool? isLoading,
    String? error,
  }) {
    return SeasonalProgressionState(
      currentSeason: currentSeason ?? this.currentSeason,
      pastSeasons: pastSeasons ?? this.pastSeasons,
      playerSeasonalData: playerSeasonalData ?? this.playerSeasonalData,
      seasonalRank: seasonalRank ?? this.seasonalRank,
      nextTier: nextTier ?? this.nextTier,
      nextTierProgress: nextTierProgress ?? this.nextTierProgress,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

/// Notifier for seasonal progression
class SeasonalProgressionNotifier
    extends StateNotifier<SeasonalProgressionState> {
  final GameAnalyticsState analytics;
  final PlayerProfile? playerProfile;

  SeasonalProgressionNotifier(this.analytics, this.playerProfile)
      : super(_buildState(analytics, playerProfile)) {
    _initializeSeasons();
  }

  /// Initialize seasons
  void _initializeSeasons() {
    // In a real app, this would fetch from backend
  }

  /// Build seasonal state
  static SeasonalProgressionState _buildState(
    GameAnalyticsState analytics,
    PlayerProfile? playerProfile,
  ) {
    final currentSeason = _getCurrentSeason();
    final pastSeasons = _getPastSeasons();
    final playerData = _buildPlayerSeasonalData(analytics, playerProfile);
    final seasonalRank = _calculateSeasonalRank(playerData);
    final nextTier = _getNextTier(playerData.currentTier);
    final nextTierProgress =
        playerData.getTierProgress(nextTier);

    return SeasonalProgressionState(
      currentSeason: currentSeason,
      pastSeasons: pastSeasons,
      playerSeasonalData: playerData,
      seasonalRank: seasonalRank,
      nextTier: nextTier,
      nextTierProgress: nextTierProgress,
      isLoading: false,
    );
  }

  /// Get current season
  static Season _getCurrentSeason() {
    final now = DateTime.now();
    final seasonNumber = ((now.year - 2024) * 4) + ((now.month - 1) ~/ 3) + 1;
    final quarterStart = ((now.month - 1) ~/ 3) * 3 + 1;
    final startDate = DateTime(now.year, quarterStart, 1);
    final endDate = DateTime(now.year, quarterStart + 3, 0);

    final seasonNames = [
      'スプリング',
      'サマー',
      'オータム',
      'ウィンター',
    ];

    return Season(
      seasonNumber: seasonNumber,
      name: seasonNames[(seasonNumber - 1) % 4],
      startDate: startDate,
      endDate: endDate,
      theme: _getSeasonTheme(seasonNumber),
      description: _getSeasonDescription(seasonNumber),
      rewards: _generateSeasonalRewards(seasonNumber),
    );
  }

  /// Get past seasons
  static List<Season> _getPastSeasons() {
    final now = DateTime.now();
    final currentSeason = _getCurrentSeason();
    final pastSeasons = <Season>[];

    for (int i = 1; i <= 3; i++) {
      final monthsBack = i * 3;
      final seasonStart =
          DateTime(now.year, now.month - monthsBack, 1);
      if (seasonStart.isAfter(DateTime(2024, 1, 1))) {
        final seasonNum = currentSeason.seasonNumber - i;
        final quarterStart = ((seasonStart.month - 1) ~/ 3) * 3 + 1;
        final startDate = DateTime(seasonStart.year, quarterStart, 1);
        final endDate = DateTime(seasonStart.year, quarterStart + 3, 0);

        final seasonNames = [
          'スプリング',
          'サマー',
          'オータム',
          'ウィンター',
        ];

        pastSeasons.add(
          Season(
            seasonNumber: seasonNum,
            name: seasonNames[(seasonNum - 1) % 4],
            startDate: startDate,
            endDate: endDate,
            theme: _getSeasonTheme(seasonNum),
            description: _getSeasonDescription(seasonNum),
            rewards: _generateSeasonalRewards(seasonNum),
          ),
        );
      }
    }

    return pastSeasons;
  }

  /// Build player seasonal data
  static PlayerSeasonalData _buildPlayerSeasonalData(
    GameAnalyticsState analytics,
    PlayerProfile? playerProfile,
  ) {
    final currentSeason = _getCurrentSeason();

    // Calculate seasonal stats (simulated - in real app would filter by season dates)
    final seasonalWins =
        (analytics.allRecords.length * 0.45).toInt();
    final seasonalGames = analytics.allRecords.length;
    final seasonalWinRate = seasonalWins > 0
        ? seasonalWins / seasonalGames
        : analytics.overallWinRate;
    final seasonalRating = _calculateSeasonalRating(
      seasonalWins,
      seasonalWinRate,
      seasonalGames,
    );

    final currentTier = _getTierFromRating(seasonalRating);
    final rewards = _generateSeasonalRewards(currentSeason.seasonNumber);
    final unlockedRewards = rewards
        .where((r) =>
            r.requiredTier.index <= currentTier.index)
        .toList();

    return PlayerSeasonalData(
      seasonNumber: currentSeason.seasonNumber,
      currentTier: currentTier,
      seasonalRating: seasonalRating,
      seasonalWins: seasonalWins,
      seasonalGames: seasonalGames,
      seasonalWinRate: seasonalWinRate,
      seasonalPoints: (seasonalWins * 10).toInt(),
      unlockedRewards: unlockedRewards,
      joinedAt: DateTime.now().subtract(const Duration(days: 30)),
    );
  }

  /// Calculate seasonal rating
  static int _calculateSeasonalRating(
    int wins,
    double winRate,
    int games,
  ) {
    final winBonus = wins * 3;
    final rateBonus = (winRate * 400).toInt();
    final gameBonus = (games * 0.5).toInt();
    return (winBonus + rateBonus + gameBonus).clamp(0, 1200).toInt();
  }

  /// Get tier from rating
  static SeasonalTier _getTierFromRating(int rating) {
    if (rating >= 1000) return SeasonalTier.master;
    if (rating >= 800) return SeasonalTier.diamond;
    if (rating >= 600) return SeasonalTier.platinum;
    if (rating >= 400) return SeasonalTier.gold;
    if (rating >= 200) return SeasonalTier.silver;
    return SeasonalTier.bronze;
  }

  /// Get next tier
  static SeasonalTier _getNextTier(SeasonalTier current) {
    final tiers = SeasonalTier.values;
    final index = tiers.indexOf(current);
    if (index < tiers.length - 1) {
      return tiers[index + 1];
    }
    return current;
  }

  /// Calculate seasonal rank
  static int _calculateSeasonalRank(PlayerSeasonalData data) {
    // Simulated rank based on tier and rating
    final tierBase = (6 - data.currentTier.index) * 15;
    final ratingBonus = (data.seasonalRating / 100).toInt();
    return (tierBase + ratingBonus).clamp(1, 100).toInt();
  }

  /// Get season theme
  static String _getSeasonTheme(int seasonNumber) {
    final themes = ['🌸春', '☀️夏', '🍂秋', '❄️冬'];
    return themes[(seasonNumber - 1) % 4];
  }

  /// Get season description
  static String _getSeasonDescription(int seasonNumber) {
    final descriptions = [
      '新しい季節が始まります。目標を達成し、報酬を獲得しましょう。',
      'この季節で最高のランクを目指しましょう。',
      '秋の涼風と共に、ランキングの頂上を目指します。',
      '冬の挑戦が始まります。全力を尽くしましょう。',
    ];
    return descriptions[(seasonNumber - 1) % 4];
  }

  /// Generate seasonal rewards
  static List<SeasonalReward> _generateSeasonalRewards(int seasonNumber) {
    final rewards = <SeasonalReward>[];

    final rewardNames = {
      SeasonalTier.bronze: 'ブロンズバッジ',
      SeasonalTier.silver: 'シルバーバッジ',
      SeasonalTier.gold: 'ゴールドバッジ',
      SeasonalTier.platinum: 'プラチナバッジ',
      SeasonalTier.diamond: 'ダイヤバッジ',
      SeasonalTier.master: 'マスターバッジ',
    };

    final emojis = {
      SeasonalTier.bronze: '🥉',
      SeasonalTier.silver: '⚪',
      SeasonalTier.gold: '🟡',
      SeasonalTier.platinum: '💎',
      SeasonalTier.diamond: '💠',
      SeasonalTier.master: '👑',
    };

    for (final tier in SeasonalTier.values) {
      rewards.add(
        SeasonalReward(
          id: 'seasonal_${seasonNumber}_${tier.name}',
          name: rewardNames[tier]!,
          description: '${tier.label}ティアに到達',
          emoji: emojis[tier]!,
          requiredTier: tier,
          seasonNumber: seasonNumber,
          isUnlocked: false,
        ),
      );
    }

    return rewards;
  }
}

/// Riverpod provider for seasonal progression
final seasonalProgressionProvider = StateNotifierProvider<
    SeasonalProgressionNotifier,
    SeasonalProgressionState>((ref) {
  final analytics = ref.watch(gameAnalyticsProvider);
  final playerProfile = ref.watch(playerProfileProvider);

  return SeasonalProgressionNotifier(analytics, playerProfile);
});
