import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/daily_challenges_provider.dart';

class DailyChallengesScreen extends ConsumerWidget {
  const DailyChallengesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final challengesState = ref.watch(dailyChallengesProvider);
    final theme = Theme.of(context);
    final completion = challengesState.getCompletionPercentage();

    return Scaffold(
          backgroundColor: theme.scaffoldBackgroundColor,
          appBar: AppBar(
            title: const Text('デイリーチャレンジ'),
            elevation: 0,
          ),
          body: CustomScrollView(
            slivers: [
              // Daily rewards header
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: _ChallengesHeader(
                    completedCount: challengesState.completedCount,
                    totalCount: challengesState.todaysChallenges.length,
                    totalRewards: challengesState.totalRewardsToday,
                    completion: completion,
                    streak: challengesState.completionStreak,
                  ),
                ),
              ),
              const SliverPadding(padding: EdgeInsets.only(top: 8)),

              // Challenges list
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final challenge =
                        challengesState.todaysChallenges[index];
                    return Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      child: _ChallengeCard(
                        challenge: challenge,
                        onComplete: () {
                          ref
                              .read(dailyChallengesProvider.notifier)
                              .completeChallenge(challenge);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                '${challenge.title}完了！ +${challenge.reward.basePoints + challenge.reward.bonus}⭐',
                              ),
                              duration: const Duration(seconds: 2),
                            ),
                          );
                        },
                      ),
                    );
                  },
                  childCount: challengesState.todaysChallenges.length,
                ),
              ),
              const SliverPadding(padding: EdgeInsets.only(bottom: 32)),
            ],
          ),
        );
  }
}

/// Challenges header
class _ChallengesHeader extends StatelessWidget {
  final int completedCount;
  final int totalCount;
  final int totalRewards;
  final double completion;
  final int streak;

  const _ChallengesHeader({
    required this.completedCount,
    required this.totalCount,
    required this.totalRewards,
    required this.completion,
    required this.streak,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.indigo.withValues(alpha: 0.8),
            Colors.blue.withValues(alpha: 0.6),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.indigo.withValues(alpha: 0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '本日のチャレンジ',
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: Colors.white.withValues(alpha: 0.9),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '$completedCount/$totalCount',
                    style: const TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '獲得報酬',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: Colors.white.withValues(alpha: 0.9),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '$totalRewards⭐',
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.amber,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: completion,
              minHeight: 8,
              backgroundColor: Colors.white.withValues(alpha: 0.2),
              valueColor: const AlwaysStoppedAnimation(Colors.amber),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '完成度: ${(completion * 100).toInt()}%',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: Colors.white.withValues(alpha: 0.9),
                ),
              ),
              if (streak > 0)
                Row(
                  children: [
                    const Text(
                      '🔥',
                      style: TextStyle(fontSize: 16),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '$streak日連続',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Colors.amber,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Challenge card
class _ChallengeCard extends ConsumerWidget {
  final DailyChallenge challenge;
  final VoidCallback onComplete;

  const _ChallengeCard({
    required this.challenge,
    required this.onComplete,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final difficultyColor = _getDifficultyColor(challenge.difficulty);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            difficultyColor.withValues(alpha: 0.1),
            difficultyColor.withValues(alpha: 0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(
          color: challenge.isCompleted
              ? Colors.green.withValues(alpha: 0.5)
              : difficultyColor.withValues(alpha: 0.4),
          width: 2,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Stack(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              challenge.emoji,
                              style: const TextStyle(fontSize: 28),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                challenge.title,
                                style: theme.textTheme.bodyLarge?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: difficultyColor,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          challenge.description,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: Colors.grey.shade600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '+${challenge.reward.basePoints}',
                        style: theme.textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Colors.amber,
                        ),
                      ),
                      Text(
                        '+${challenge.reward.bonus}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: Colors.amber,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Difficulty and requirement
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: difficultyColor.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      challenge.difficulty.label,
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: difficultyColor,
                        fontSize: 11,
                      ),
                    ),
                  ),
                  Text(
                    challenge.requirement,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: Colors.grey.shade600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Progress bar
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '進捗',
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        '${challenge.progress}%',
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: difficultyColor,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: challenge.progress / 100.0,
                      minHeight: 6,
                      backgroundColor:
                          difficultyColor.withValues(alpha: 0.2),
                      valueColor:
                          AlwaysStoppedAnimation(difficultyColor),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Complete button
              if (!challenge.isCompleted)
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: challenge.progress < 100
                        ? null
                        : onComplete,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: difficultyColor,
                      disabledBackgroundColor: Colors.grey.shade400,
                    ),
                    child: Text(
                      challenge.progress < 100
                          ? 'あと${100 - challenge.progress}%'
                          : '完了！',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          if (challenge.isCompleted)
            Positioned(
              top: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.green,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.check_circle,
                  color: Colors.white,
                  size: 24,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Color _getDifficultyColor(ChallengeDifficulty difficulty) {
    return switch (difficulty) {
      ChallengeDifficulty.easy => Colors.green,
      ChallengeDifficulty.normal => Colors.blue,
      ChallengeDifficulty.hard => Colors.orange,
      ChallengeDifficulty.expert => Colors.red,
    };
  }
}
