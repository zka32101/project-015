import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/seasonal_progression_provider.dart';

class SeasonalProgressionScreen extends ConsumerWidget {
  const SeasonalProgressionScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final seasonalState = ref.watch(seasonalProgressionProvider);
    final theme = Theme.of(context);

    if (seasonalState.isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('シーズン進捗')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (seasonalState.error != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('シーズン進捗')),
        body: Center(
          child: Text('エラー: ${seasonalState.error}'),
        ),
      );
    }

    final season = seasonalState.currentSeason;
    final playerData = seasonalState.playerSeasonalData;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('シーズン進捗'),
        elevation: 0,
      ),
      body: CustomScrollView(
        slivers: [
          // Current season header
          SliverToBoxAdapter(
            child: _SeasonHeader(season: season),
          ),
          const SliverPadding(padding: EdgeInsets.only(top: 16)),

          // Player tier card
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: _PlayerTierCard(
                playerData: playerData,
                nextTier: seasonalState.nextTier,
                nextTierProgress: seasonalState.nextTierProgress,
              ),
            ),
          ),
          const SliverPadding(padding: EdgeInsets.only(top: 24)),

          // Tier progression path
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'ティア進捗',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _TierProgressionPath(playerData: playerData),
                ],
              ),
            ),
          ),
          const SliverPadding(padding: EdgeInsets.only(top: 24)),

          // Seasonal rewards
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'シーズン報酬',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SliverPadding(padding: EdgeInsets.only(top: 12)),

          SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final reward = season.rewards[index];
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: _RewardCard(
                    reward: reward,
                    isUnlocked: playerData.unlockedRewards
                        .any((r) => r.id == reward.id),
                  ),
                );
              },
              childCount: season.rewards.length,
            ),
          ),
          const SliverPadding(padding: EdgeInsets.only(top: 24)),

          // Season statistics
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'シーズン統計',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _SeasonalStatsGrid(playerData: playerData),
                ],
              ),
            ),
          ),
          const SliverPadding(padding: EdgeInsets.only(bottom: 32)),
        ],
      ),
    );
  }
}

/// Season header with timer
class _SeasonHeader extends StatelessWidget {
  final Season season;

  const _SeasonHeader({required this.season});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final progressPercent = (season.progressPercentage * 100).toStringAsFixed(0);

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.purple.withValues(alpha: 0.8),
            Colors.indigo.withValues(alpha: 0.6),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.purple.withValues(alpha: 0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    season.theme,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: Colors.white.withValues(alpha: 0.9),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'シーズン ${season.seasonNumber}',
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  '📅',
                  style: TextStyle(fontSize: 32),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '進捗: $progressPercent%',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.9),
                  fontSize: 12,
                ),
              ),
              Text(
                '残り${season.daysRemaining}日',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.9),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: season.progressPercentage,
              minHeight: 8,
              backgroundColor: Colors.white.withValues(alpha: 0.3),
              valueColor: AlwaysStoppedAnimation(
                Colors.white.withValues(alpha: 0.9),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Player tier card
class _PlayerTierCard extends StatelessWidget {
  final PlayerSeasonalData playerData;
  final SeasonalTier nextTier;
  final double nextTierProgress;

  const _PlayerTierCard({
    required this.playerData,
    required this.nextTier,
    required this.nextTierProgress,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tier = playerData.currentTier;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        border: Border.all(
          color: Colors.grey.shade300,
          width: 1.5,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '現在のティア',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: Colors.grey.shade700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(
                        tier.emoji,
                        style: const TextStyle(fontSize: 32),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        tier.label,
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.purple.shade100,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'ランク #${playerData.seasonNumber}',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: Colors.purple.shade700,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${playerData.seasonalRating}',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            '次のティアまで',
            style: theme.textTheme.bodySmall?.copyWith(
              color: Colors.grey.shade700,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${nextTier.emoji} ${nextTier.label}',
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                '${(nextTierProgress * 100).toStringAsFixed(0)}%',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: nextTierProgress,
              minHeight: 10,
              backgroundColor: Colors.grey.shade300,
              valueColor: AlwaysStoppedAnimation(
                Colors.purple.shade600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Tier progression path visualization
class _TierProgressionPath extends StatelessWidget {
  final PlayerSeasonalData playerData;

  const _TierProgressionPath({required this.playerData});

  @override
  Widget build(BuildContext context) {
    final tiers = SeasonalTier.values;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (int i = 0; i < tiers.length; i++) ...[
            _TierNode(
              tier: tiers[i],
              isUnlocked: playerData.currentTier.index >= i,
              isCurrent: playerData.currentTier == tiers[i],
              progress: playerData.getTierProgress(tiers[i]),
            ),
            if (i < tiers.length - 1)
              Container(
                width: 40,
                height: 2,
                color: playerData.currentTier.index > i
                    ? Colors.purple.shade600
                    : Colors.grey.shade300,
              ),
          ],
        ],
      ),
    );
  }
}

/// Individual tier node
class _TierNode extends StatelessWidget {
  final SeasonalTier tier;
  final bool isUnlocked;
  final bool isCurrent;
  final double progress;

  const _TierNode({
    required this.tier,
    required this.isUnlocked,
    required this.isCurrent,
    required this.progress,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      children: [
        Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isUnlocked ? Colors.purple.shade100 : Colors.grey.shade100,
            border: Border.all(
              color: isCurrent
                  ? Colors.purple.shade600
                  : isUnlocked
                      ? Colors.purple.shade300
                      : Colors.grey.shade300,
              width: isCurrent ? 3 : 2,
            ),
          ),
          child: Center(
            child: Text(
              tier.emoji,
              style: const TextStyle(fontSize: 28),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          tier.label,
          style: theme.textTheme.bodySmall?.copyWith(
            fontWeight: FontWeight.w600,
            color: isUnlocked ? Colors.purple.shade700 : Colors.grey.shade600,
          ),
          textAlign: TextAlign.center,
        ),
        if (isCurrent) ...[
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.purple.shade100,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              '現在',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: Colors.purple.shade700,
              ),
            ),
          ),
        ],
      ],
    );
  }
}

/// Seasonal reward card
class _RewardCard extends StatelessWidget {
  final SeasonalReward reward;
  final bool isUnlocked;

  const _RewardCard({
    required this.reward,
    required this.isUnlocked,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isUnlocked
            ? Colors.amber.withValues(alpha: 0.1)
            : Colors.grey.withValues(alpha: 0.1),
        border: Border.all(
          color: isUnlocked
              ? Colors.amber.withValues(alpha: 0.3)
              : Colors.grey.withValues(alpha: 0.2),
          width: 1.5,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Text(
            reward.emoji,
            style: const TextStyle(fontSize: 32),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  reward.name,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: isUnlocked ? Colors.amber.shade900 : Colors.grey.shade700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  reward.description,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
          if (isUnlocked)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.amber.shade100,
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Text(
                '取得済み',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.amber,
                ),
              ),
            )
          else
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                reward.requiredTier.label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade600,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Seasonal statistics grid
class _SeasonalStatsGrid extends StatelessWidget {
  final PlayerSeasonalData playerData;

  const _SeasonalStatsGrid({required this.playerData});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.2,
      children: [
        _StatCard(
          label: 'シーズン勝利',
          value: playerData.seasonalWins.toString(),
          emoji: '🏆',
          theme: theme,
        ),
        _StatCard(
          label: 'シーズン対戦',
          value: playerData.seasonalGames.toString(),
          emoji: '🎮',
          theme: theme,
        ),
        _StatCard(
          label: '勝率',
          value: '${(playerData.seasonalWinRate * 100).toStringAsFixed(1)}%',
          emoji: '📈',
          theme: theme,
        ),
        _StatCard(
          label: 'シーズンポイント',
          value: playerData.seasonalPoints.toString(),
          emoji: '⭐',
          theme: theme,
        ),
      ],
    );
  }
}

/// Individual stat card
class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final String emoji;
  final ThemeData theme;

  const _StatCard({
    required this.label,
    required this.value,
    required this.emoji,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blue.withValues(alpha: 0.05),
        border: Border.all(
          color: Colors.blue.withValues(alpha: 0.2),
          width: 1,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            emoji,
            style: const TextStyle(fontSize: 24),
          ),
          Column(
            children: [
              Text(
                value,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                label,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: Colors.grey.shade600,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
