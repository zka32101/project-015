import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../engine/ai.dart';
import 'game_analytics_provider.dart';

/// Difficulty progression tier
class DifficultyTier {
  final AiDifficulty? difficulty;
  final String name;
  final String emoji;
  final String description;
  final double requiredWinRate;
  final int minimumGames;
  final String recommendation;

  const DifficultyTier({
    required this.difficulty,
    required this.name,
    required this.emoji,
    required this.description,
    required this.requiredWinRate,
    required this.minimumGames,
    required this.recommendation,
  });

  /// Get color for tier
  String getColor() {
    switch (difficulty) {
      case AiDifficulty.easy:
        return '#4CAF50'; // Green
      case AiDifficulty.medium:
        return '#FFC107'; // Orange
      case AiDifficulty.hard:
        return '#F44336'; // Red
      default:
        return '#2196F3'; // Blue (local)
    }
  }
}

/// Progression data for a specific difficulty
class ProgressionData {
  final DifficultyTier tier;
  final int gamesPlayed;
  final double currentWinRate;
  final bool isCurrentLevel;
  final bool canProgress;
  final bool shouldProgress;
  final String status;
  final double progressPercentage;

  const ProgressionData({
    required this.tier,
    required this.gamesPlayed,
    required this.currentWinRate,
    required this.isCurrentLevel,
    required this.canProgress,
    required this.shouldProgress,
    required this.status,
    required this.progressPercentage,
  });

  /// Determine if player is ready to advance
  bool get isReadyToAdvance => canProgress && shouldProgress;

  /// Get progress description
  String getProgressDescription() {
    if (gamesPlayed < tier.minimumGames) {
      return '${tier.minimumGames - gamesPlayed}ゲーム必要';
    }
    if (currentWinRate < tier.requiredWinRate) {
      final winRateNeeded = (tier.requiredWinRate * 100).toStringAsFixed(1);
      final currentRate = (currentWinRate * 100).toStringAsFixed(1);
      return '勝率 $currentRate% → ${winRateNeeded}%が必要';
    }
    return '進出可能！';
  }
}

/// Overall progression state
class DifficultyProgressionState {
  final List<ProgressionData> allTiers;
  final AiDifficulty? currentDifficulty;
  final ProgressionData? currentTierData;
  final ProgressionData? nextTierData;
  final String overallRecommendation;
  final int totalProgressionPoints;
  final bool isLoading;
  final String? error;

  const DifficultyProgressionState({
    required this.allTiers,
    required this.currentDifficulty,
    required this.currentTierData,
    required this.nextTierData,
    required this.overallRecommendation,
    required this.totalProgressionPoints,
    this.isLoading = false,
    this.error,
  });
}

/// Notifier for difficulty progression
class DifficultyProgressionNotifier
    extends StateNotifier<DifficultyProgressionState> {
  static const List<DifficultyTier> _tiers = [
    DifficultyTier(
      difficulty: null,
      name: 'ローカル対戦',
      emoji: '👥',
      description: 'ローカルマルチプレイ',
      requiredWinRate: 0.5,
      minimumGames: 5,
      recommendation: 'AIと対戦を始める準備ができています',
    ),
    DifficultyTier(
      difficulty: AiDifficulty.easy,
      name: 'かんたん',
      emoji: '🟢',
      description: '初級AI - ゲーム開始プレイヤー向け',
      requiredWinRate: 0.55,
      minimumGames: 10,
      recommendation: '基本を学ぶのに最適です',
    ),
    DifficultyTier(
      difficulty: AiDifficulty.medium,
      name: 'ふつう',
      emoji: '🟡',
      description: '中級AI - バランスの取れた挑戦',
      requiredWinRate: 0.50,
      minimumGames: 15,
      recommendation: 'スキル向上に良い難易度です',
    ),
    DifficultyTier(
      difficulty: AiDifficulty.hard,
      name: 'つよい',
      emoji: '🔴',
      description: '上級AI - 最難関挑戦',
      requiredWinRate: 0.45,
      minimumGames: 20,
      recommendation: '最高のプレイヤー向けです',
    ),
  ];

  DifficultyProgressionNotifier(
    GameAnalyticsState analyticsState,
    AiDifficulty? currentDifficulty,
  ) : super(
          _buildProgressionState(analyticsState, currentDifficulty),
        );

  /// Build progression state
  static DifficultyProgressionState _buildProgressionState(
    GameAnalyticsState analyticsState,
    AiDifficulty? currentDifficulty,
  ) {
    final allProgressionData = <ProgressionData>[];

    for (int i = 0; i < _tiers.length; i++) {
      final tier = _tiers[i];
      final difficultyAnalytics = analyticsState.difficultyBreakdown
          .cast<DifficultyAnalytics?>()
          .firstWhere(
            (d) =>
                d?.difficulty ==
                (tier.difficulty == null
                    ? 'local'
                    : tier.difficulty.toString().split('.').last),
            orElse: () => null,
          );

      final gamesPlayed = difficultyAnalytics?.totalGames ?? 0;
      final currentWinRate = difficultyAnalytics?.winRate ?? 0.0;
      final isCurrentLevel = tier.difficulty == currentDifficulty;

      // Determine if can progress
      final hasEnoughGames = gamesPlayed >= tier.minimumGames;
      final hasGoodWinRate = currentWinRate >= tier.requiredWinRate;
      final canProgress = hasEnoughGames && hasGoodWinRate;

      // Determine progress percentage
      double progressPercentage = 0.0;
      if (hasEnoughGames) {
        progressPercentage = (currentWinRate / tier.requiredWinRate).clamp(0, 1);
      } else {
        progressPercentage =
            (gamesPlayed / tier.minimumGames).clamp(0, 1) * 0.5;
      }

      final progressData = ProgressionData(
        tier: tier,
        gamesPlayed: gamesPlayed,
        currentWinRate: currentWinRate,
        isCurrentLevel: isCurrentLevel,
        canProgress: canProgress,
        shouldProgress: i < _tiers.length - 1, // Can progress unless at max
        status: _getStatus(hasEnoughGames, hasGoodWinRate, isCurrentLevel),
        progressPercentage: progressPercentage,
      );

      allProgressionData.add(progressData);
    }

    // Find next tier progression
    ProgressionData? nextTierData;
    for (int i = 0; i < allProgressionData.length; i++) {
      if (allProgressionData[i].isCurrentLevel &&
          i < allProgressionData.length - 1) {
        nextTierData = allProgressionData[i + 1];
        break;
      }
    }

    // Calculate total progression points
    int totalPoints = 0;
    for (final tier in _tiers) {
      final data = allProgressionData
          .firstWhere((d) => d.tier == tier);
      if (data.canProgress) {
        totalPoints += 100;
      }
      totalPoints += (data.progressPercentage * 50).toInt();
    }

    // Generate recommendation
    final currentTierData =
        allProgressionData.firstWhere((d) => d.isCurrentLevel);
    final recommendation = _generateRecommendation(
      currentTierData,
      analyticsState.getGamesPerDay(),
    );

    return DifficultyProgressionState(
      allTiers: allProgressionData,
      currentDifficulty: currentDifficulty,
      currentTierData: currentTierData,
      nextTierData: nextTierData,
      overallRecommendation: recommendation,
      totalProgressionPoints: totalPoints,
      isLoading: false,
    );
  }

  /// Get status string
  static String _getStatus(
    bool hasEnoughGames,
    bool hasGoodWinRate,
    bool isCurrentLevel,
  ) {
    if (isCurrentLevel) {
      if (!hasEnoughGames) return 'プレイ中';
      if (!hasGoodWinRate) return '練習中';
      return 'マスター中';
    }

    if (!hasEnoughGames) return 'ロック中';
    if (!hasGoodWinRate) return 'チャレンジ中';
    return '達成済み';
  }

  /// Generate personalized recommendation
  static String _generateRecommendation(
    ProgressionData currentTier,
    double gamesPerDay,
  ) {
    if (!currentTier.canProgress) {
      if (currentTier.gamesPlayed < currentTier.tier.minimumGames) {
        final remaining =
            currentTier.tier.minimumGames - currentTier.gamesPlayed;
        final daysNeeded = (remaining / gamesPerDay).ceil();
        return '$remaining ゲームをプレイして、約 $daysNeeded 日で進出できます';
      } else {
        final winRateNeeded =
            (currentTier.tier.requiredWinRate * 100).toStringAsFixed(1);
        return '勝率を ${winRateNeeded}% に上げて進出を目指しましょう';
      }
    }

    return '次のレベルへの進出準備ができました！';
  }

  /// Refresh progression state
  void refresh(
    GameAnalyticsState analyticsState,
    AiDifficulty? currentDifficulty,
  ) {
    state = _buildProgressionState(analyticsState, currentDifficulty);
  }
}

/// Riverpod provider for difficulty progression
final difficultyProgressionProvider = StateNotifierProvider<
    DifficultyProgressionNotifier,
    DifficultyProgressionState>((ref) {
  final analyticsState = ref.watch(gameAnalyticsProvider);
  // Note: currentDifficulty should be passed from GameViewModel in real implementation
  // For now, we use null as default
  return DifficultyProgressionNotifier(analyticsState, null);
});

/// Convenience selector for current tier
final currentProgressionTierProvider =
    Provider<ProgressionData?>((ref) {
  return ref.watch(difficultyProgressionProvider).currentTierData;
});

/// Convenience selector for next tier
final nextProgressionTierProvider = Provider<ProgressionData?>((ref) {
  return ref.watch(difficultyProgressionProvider).nextTierData;
});

/// Convenience selector for total points
final totalProgressionPointsProvider = Provider<int>((ref) {
  return ref.watch(difficultyProgressionProvider).totalProgressionPoints;
});

/// Convenience selector for recommendation
final progressionRecommendationProvider = Provider<String>((ref) {
  return ref.watch(difficultyProgressionProvider).overallRecommendation;
});
