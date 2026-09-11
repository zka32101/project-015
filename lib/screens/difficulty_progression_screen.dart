import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/difficulty_progression_provider.dart';

class DifficultyProgressionScreen extends ConsumerWidget {
  const DifficultyProgressionScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final progressionState = ref.watch(difficultyProgressionProvider);
    final theme = Theme.of(context);

    if (progressionState.isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('難易度進捗')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('難易度進捗'),
        elevation: 0,
      ),
      body: CustomScrollView(
        slivers: [
          // Header with points
          SliverToBoxAdapter(
            child: _ProgressionHeader(
              totalPoints: progressionState.totalProgressionPoints,
            ),
          ),
          const SliverPadding(padding: EdgeInsets.only(top: 8)),

          // Recommendation section
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: _RecommendationCard(
                recommendation: progressionState.overallRecommendation,
              ),
            ),
          ),
          const SliverPadding(padding: EdgeInsets.only(top: 24)),

          // Progression path
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'レベル進捗',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _ProgressionPath(
                    tiers: progressionState.allTiers,
                    currentDifficulty: progressionState.currentDifficulty,
                  ),
                ],
              ),
            ),
          ),
          const SliverPadding(padding: EdgeInsets.only(top: 24)),

          // Current tier details
          if (progressionState.currentTierData != null)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '現在のレベル詳細',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _TierDetailCard(
                      progressionData: progressionState.currentTierData!,
                    ),
                  ],
                ),
              ),
            ),
          const SliverPadding(padding: EdgeInsets.only(top: 24)),

          // Next tier guidance
          if (progressionState.nextTierData != null)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '次のレベル',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _NextTierCard(
                      progressionData: progressionState.nextTierData!,
                      isReadyToAdvance:
                          progressionState.nextTierData!.isReadyToAdvance,
                    ),
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

/// Progression header with points
class _ProgressionHeader extends StatelessWidget {
  final int totalPoints;

  const _ProgressionHeader({required this.totalPoints});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            theme.primaryColor.withValues(alpha: 0.8),
            theme.primaryColor.withValues(alpha: 0.5),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: theme.primaryColor.withValues(alpha: 0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            '進捗ポイント',
            style: theme.textTheme.bodyLarge?.copyWith(
              color: Colors.white.withValues(alpha: 0.9),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            totalPoints.toString(),
            style: const TextStyle(
              fontSize: 48,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '難易度を征服して新しいレベルのロックを解除しましょう',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.9),
                fontSize: 12,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
}

/// Recommendation card
class _RecommendationCard extends StatelessWidget {
  final String recommendation;

  const _RecommendationCard({required this.recommendation});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue.withValues(alpha: 0.1),
        border: Border.all(
          color: Colors.blue.withValues(alpha: 0.3),
          width: 1.5,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.blue.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.lightbulb,
              color: Colors.blue,
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              recommendation,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: Colors.blue.shade700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Progression path visualization
class _ProgressionPath extends StatelessWidget {
  final List<ProgressionData> tiers;
  final AiDifficulty? currentDifficulty;

  const _ProgressionPath({
    required this.tiers,
    required this.currentDifficulty,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (int i = 0; i < tiers.length; i++)
          Column(
            children: [
              _TierPathNode(
                progressionData: tiers[i],
                isFirst: i == 0,
                isLast: i == tiers.length - 1,
              ),
              if (i < tiers.length - 1)
                Container(
                  width: 2,
                  height: 16,
                  color: Colors.grey.withValues(alpha: 0.3),
                ),
            ],
          ),
      ],
    );
  }
}

/// Single tier path node
class _TierPathNode extends StatelessWidget {
  final ProgressionData progressionData;
  final bool isFirst;
  final bool isLast;

  const _TierPathNode({
    required this.progressionData,
    required this.isFirst,
    required this.isLast,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tier = progressionData.tier;
    final statusColor = _getStatusColor();

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.cardColor,
        border: Border.all(
          color: statusColor.withValues(alpha: 0.3),
          width: 2,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.15),
              shape: BoxShape.circle,
              border: Border.all(
                color: statusColor.withValues(alpha: 0.5),
                width: 2,
              ),
            ),
            child: Center(
              child: Text(
                tier.emoji,
                style: const TextStyle(fontSize: 28),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tier.name,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  tier.description,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.textTheme.bodySmall?.color?.withValues(
                      alpha: 0.6,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                _ProgressBar(
                  percentage: progressionData.progressPercentage,
                  statusColor: statusColor,
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              progressionData.status,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: statusColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor() {
    if (progressionData.isCurrentLevel) return Colors.blue;
    if (progressionData.canProgress) return Colors.green;
    if (progressionData.gamesPlayed > 0) return Colors.orange;
    return Colors.grey;
  }
}

/// Progress bar widget
class _ProgressBar extends StatelessWidget {
  final double percentage;
  final Color statusColor;

  const _ProgressBar({
    required this.percentage,
    required this.statusColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: percentage,
              minHeight: 6,
              backgroundColor: Colors.grey.withValues(alpha: 0.2),
              valueColor: AlwaysStoppedAnimation(statusColor),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          '${(percentage * 100).toStringAsFixed(0)}%',
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}

/// Tier detail card
class _TierDetailCard extends StatelessWidget {
  final ProgressionData progressionData;

  const _TierDetailCard({required this.progressionData});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tier = progressionData.tier;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.blue.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Text(
                    tier.emoji,
                    style: const TextStyle(fontSize: 28),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        tier.name,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        tier.recommendation,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.textTheme.bodySmall?.color?.withValues(
                            alpha: 0.6,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.blue.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  '現在',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _DetailRow(
            label: 'プレイ数',
            value: '${progressionData.gamesPlayed} / ${tier.minimumGames}',
            isComplete:
                progressionData.gamesPlayed >= tier.minimumGames,
          ),
          const SizedBox(height: 8),
          _DetailRow(
            label: '勝率',
            value:
                '${(progressionData.currentWinRate * 100).toStringAsFixed(1)}% / ${(tier.requiredWinRate * 100).toStringAsFixed(1)}%',
            isComplete: progressionData.currentWinRate >= tier.requiredWinRate,
          ),
          const SizedBox(height: 12),
          Text(
            progressionData.getProgressDescription(),
            style: theme.textTheme.bodySmall?.copyWith(
              color: progressionData.canProgress
                  ? Colors.green
                  : Colors.orange,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

/// Detail row for tier info
class _DetailRow extends StatelessWidget {
  final String label;
  final String value;
  final bool isComplete;

  const _DetailRow({
    required this.label,
    required this.value,
    required this.isComplete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: theme.textTheme.bodyMedium,
        ),
        Row(
          children: [
            Text(
              value,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: isComplete ? Colors.green : Colors.orange,
              ),
            ),
            const SizedBox(width: 8),
            Icon(
              isComplete ? Icons.check_circle : Icons.schedule,
              color: isComplete ? Colors.green : Colors.orange,
              size: 18,
            ),
          ],
        ),
      ],
    );
  }
}

/// Next tier card
class _NextTierCard extends StatelessWidget {
  final ProgressionData progressionData;
  final bool isReadyToAdvance;

  const _NextTierCard({
    required this.progressionData,
    required this.isReadyToAdvance,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tier = progressionData.tier;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isReadyToAdvance
              ? Colors.green.withValues(alpha: 0.3)
              : Colors.orange.withValues(alpha: 0.2),
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Text(
                    tier.emoji,
                    style: const TextStyle(fontSize: 28),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        tier.name,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        tier.description,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.textTheme.bodySmall?.color?.withValues(
                            alpha: 0.6,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              if (isReadyToAdvance)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.green.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    '準備完了！',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isReadyToAdvance
                  ? Colors.green.withValues(alpha: 0.1)
                  : Colors.orange.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              progressionData.getProgressDescription(),
              style: theme.textTheme.bodySmall?.copyWith(
                color: isReadyToAdvance ? Colors.green : Colors.orange,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          if (isReadyToAdvance) ...[
            const SizedBox(height: 12),
            Text(
              tier.recommendation,
              style: theme.textTheme.bodySmall?.copyWith(
                color: Colors.green.shade700,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
