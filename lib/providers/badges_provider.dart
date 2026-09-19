import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../engine/models.dart';
import 'game_analytics_provider.dart';
import 'leaderboard_provider.dart';
import 'seasonal_progression_provider.dart';

/// Badge tier levels
enum BadgeTier {
  bronze('🥉', 'ブロンズ'),
  silver('🥈', 'シルバー'),
  gold('🥇', 'ゴールド'),
  platinum('💎', 'プラチナ'),
  diamond('👑', 'ダイヤモンド');

  final String emoji;
  final String label;
  const BadgeTier(this.emoji, this.label);
}

/// Badge definition
class Badge {
  final String id;
  final String name;
  final String description;
  final String emoji;
  final BadgeTier tier;
  final DateTime? unlockedDate;
  final bool isLocked;
  final double progressPercentage; // 0.0 to 1.0 for locked badges

  const Badge({
    required this.id,
    required this.name,
    required this.description,
    required this.emoji,
    required this.tier,
    this.unlockedDate,
    this.isLocked = true,
    this.progressPercentage = 0.0,
  });

  Badge copyWith({
    String? id,
    String? name,
    String? description,
    String? emoji,
    BadgeTier? tier,
    DateTime? unlockedDate,
    bool? isLocked,
    double? progressPercentage,
  }) {
    return Badge(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      emoji: emoji ?? this.emoji,
      tier: tier ?? this.tier,
      unlockedDate: unlockedDate ?? this.unlockedDate,
      isLocked: isLocked ?? this.isLocked,
      progressPercentage: progressPercentage ?? this.progressPercentage,
    );
  }
}

/// Badges state
class BadgesState {
  final List<Badge> allBadges;
  final List<Badge> unlockedBadges;
  final String? selectedTitle; // Player's selected title badge
  final int totalPoints; // Badge collection score
  final bool isLoading;
  final String? error;

  const BadgesState({
    required this.allBadges,
    required this.unlockedBadges,
    this.selectedTitle,
    this.totalPoints = 0,
    this.isLoading = false,
    this.error,
  });

  /// Get completion percentage
  double getCompletionPercentage() {
    if (allBadges.isEmpty) return 0.0;
    return unlockedBadges.length / allBadges.length;
  }

  /// Copy with modifications
  BadgesState copyWith({
    List<Badge>? allBadges,
    List<Badge>? unlockedBadges,
    String? selectedTitle,
    int? totalPoints,
    bool? isLoading,
    String? error,
  }) {
    return BadgesState(
      allBadges: allBadges ?? this.allBadges,
      unlockedBadges: unlockedBadges ?? this.unlockedBadges,
      selectedTitle: selectedTitle ?? this.selectedTitle,
      totalPoints: totalPoints ?? this.totalPoints,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

/// Notifier for badges
class BadgesNotifier extends StateNotifier<BadgesState> {
  SharedPreferences? _prefs;
  final Ref ref;

  BadgesNotifier(this.ref) : super(_buildInitialState()) {
    _initializeBadges();
  }

  /// Initialize badges
  Future<void> _initializeBadges() async {
    final prefs = await SharedPreferences.getInstance();
    _prefs = prefs;

    final allBadges = state.allBadges;
    final unlockedIds = prefs.getStringList('unlocked_badges') ?? [];
    final selectedTitle = prefs.getString('selected_title');
    final unlockedBadges = allBadges
        .where((badge) => unlockedIds.contains(badge.id))
        .toList();

    state = state.copyWith(
      unlockedBadges: unlockedBadges,
      selectedTitle: selectedTitle,
      totalPoints: unlockedBadges.length * 10,
    );

    await _updateBadgeStates();
  }

  /// Build initial state
  static BadgesState _buildInitialState() {
    final allBadges = _generateAllBadges();

    return BadgesState(
      allBadges: allBadges,
      unlockedBadges: [],
    );
  }

  /// Update badge unlock states based on game progress
  Future<void> _updateBadgeStates() async {
    try {
      final analytics = ref.watch(gameAnalyticsProvider);
      final leaderboard = ref.watch(leaderboardProvider);
      final seasonal = ref.watch(seasonalProgressionProvider);

      final updatedBadges = <String>[];
      final existingUnlocked =
          state.unlockedBadges.map((b) => b.id).toSet();
      final totalWins = analytics.allRecords
          .where((r) => r.result == GameResult.playerAWins)
          .length;

      // Check all badge conditions
      if (totalWins >= 10) updatedBadges.add('first_wins_10');
      if (totalWins >= 50) updatedBadges.add('veteran_50');
      if (totalWins >= 100) updatedBadges.add('master_100');
      if (totalWins >= 500) updatedBadges.add('legend_500');

      if (analytics.overallWinRate >= 0.7)
        updatedBadges.add('dominant_70');
      if (analytics.overallWinRate >= 0.8)
        updatedBadges.add('elite_80');
      if (analytics.overallWinRate >= 0.9)
        updatedBadges.add('unstoppable_90');

      if (analytics.totalGamesAnalyzed >= 500)
        updatedBadges.add('grinder_500');
      if (analytics.totalGamesAnalyzed >= 1000)
        updatedBadges.add('addict_1000');

      if ((leaderboard.playerRank ?? 999999) <= 10)
        updatedBadges.add('top_10_rank');
      if ((leaderboard.playerRank ?? 999999) <= 5)
        updatedBadges.add('top_5_rank');
      if (leaderboard.playerRank == 1)
        updatedBadges.add('champion_rank');

      if (seasonal.playerSeasonalData.currentTier == SeasonalTier.master)
        updatedBadges.add('master_tier');

      // Check for newly unlocked badges
      final newlyUnlocked = updatedBadges.where(
        (id) => !existingUnlocked.contains(id),
      );

      // Save updated list
      if (newlyUnlocked.isNotEmpty) {
        final allIds = {...existingUnlocked, ...newlyUnlocked};
        final prefs = _prefs ??= await SharedPreferences.getInstance();
        await prefs.setStringList('unlocked_badges', allIds.toList());
      }

      // Update state with new badge information
      final allBadges = _generateAllBadges();
      final unlockedBadgesList = allBadges
          .where((badge) => updatedBadges.contains(badge.id))
          .map((badge) => badge.copyWith(
                isLocked: false,
                unlockedDate: DateTime.now(),
              ))
          .toList();

      state = state.copyWith(
        allBadges: allBadges,
        unlockedBadges: unlockedBadgesList,
        totalPoints: unlockedBadgesList.length * 10,
      );
    } catch (e) {
      state = state.copyWith(error: 'Failed to update badges: $e');
    }
  }

  /// Select a title badge
  Future<void> selectTitle(String badgeId) async {
    if (!state.unlockedBadges.any((b) => b.id == badgeId)) {
      state = state.copyWith(error: 'This badge is not unlocked');
      return;
    }

    final prefs = _prefs ??= await SharedPreferences.getInstance();
    await prefs.setString('selected_title', badgeId);
    state = state.copyWith(selectedTitle: badgeId);
  }

  /// Generate all available badges
  static List<Badge> _generateAllBadges() {
    return [
      // Win-based badges
      const Badge(
        id: 'first_wins_10',
        name: '初勝利',
        description: '10勝達成',
        emoji: '🎯',
        tier: BadgeTier.bronze,
        isLocked: true,
      ),
      const Badge(
        id: 'veteran_50',
        name: 'ベテラン',
        description: '50勝達成',
        emoji: '⚔️',
        tier: BadgeTier.silver,
        isLocked: true,
      ),
      const Badge(
        id: 'master_100',
        name: 'マスター',
        description: '100勝達成',
        emoji: '🏆',
        tier: BadgeTier.gold,
        isLocked: true,
      ),
      const Badge(
        id: 'legend_500',
        name: 'レジェンド',
        description: '500勝達成',
        emoji: '👑',
        tier: BadgeTier.diamond,
        isLocked: true,
      ),

      // Win rate badges
      const Badge(
        id: 'dominant_70',
        name: 'ドミナント',
        description: '70%勝率達成',
        emoji: '🔥',
        tier: BadgeTier.silver,
        isLocked: true,
      ),
      const Badge(
        id: 'elite_80',
        name: 'エリート',
        description: '80%勝率達成',
        emoji: '⭐',
        tier: BadgeTier.gold,
        isLocked: true,
      ),
      const Badge(
        id: 'unstoppable_90',
        name: '無敵',
        description: '90%勝率達成',
        emoji: '💥',
        tier: BadgeTier.platinum,
        isLocked: true,
      ),

      // Game count badges
      const Badge(
        id: 'grinder_500',
        name: 'グラインダー',
        description: '500局プレイ',
        emoji: '⚙️',
        tier: BadgeTier.bronze,
        isLocked: true,
      ),
      const Badge(
        id: 'addict_1000',
        name: '中毒者',
        description: '1000局プレイ',
        emoji: '🎮',
        tier: BadgeTier.gold,
        isLocked: true,
      ),

      // Ranking badges
      const Badge(
        id: 'top_10_rank',
        name: 'トップ10',
        description: 'ランキングTOP10入り',
        emoji: '🎖️',
        tier: BadgeTier.gold,
        isLocked: true,
      ),
      const Badge(
        id: 'top_5_rank',
        name: 'トップ5',
        description: 'ランキングTOP5入り',
        emoji: '🥇',
        tier: BadgeTier.platinum,
        isLocked: true,
      ),
      const Badge(
        id: 'champion_rank',
        name: 'チャンピオン',
        description: 'ランキング1位',
        emoji: '👑',
        tier: BadgeTier.diamond,
        isLocked: true,
      ),

      // Seasonal badges
      const Badge(
        id: 'master_tier',
        name: 'シーズンマスター',
        description: 'シーズン最高ランクに到達',
        emoji: '🌟',
        tier: BadgeTier.platinum,
        isLocked: true,
      ),
    ];
  }
}

/// Riverpod provider for badges
final badgesProvider = StateNotifierProvider<BadgesNotifier, BadgesState>(
  (ref) => BadgesNotifier(ref),
);

/// Alternative sync provider (for testing)
final badgesSyncProvider =
    StateNotifierProvider<BadgesNotifier, BadgesState>((ref) {
  throw UnimplementedError();
});
