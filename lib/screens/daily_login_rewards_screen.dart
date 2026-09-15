import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/daily_login_rewards_provider.dart';

class DailyLoginRewardsScreen extends ConsumerWidget {
  const DailyLoginRewardsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rewardsState = ref.watch(dailyLoginRewardsSyncProvider);
    final theme = Theme.of(context);

    return rewardsState.when(
      data: (state) {
        return Scaffold(
          backgroundColor: theme.scaffoldBackgroundColor,
          appBar: AppBar(
            title: const Text('デイリーリワード'),
            elevation: 0,
          ),
          body: CustomScrollView(
            slivers: [
              // Streak card
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: _StreakCard(streak: state.streak),
                ),
              ),
              const SliverPadding(padding: EdgeInsets.only(top: 8)),

              // Daily reward card
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: _DailyRewardCard(
                    rewardPoints: state.todayRewardPoints,
                    hasClaimedToday: state.hasClaimedToday,
                    multiplier: state.streak.getStreakMultiplier(),
                  ),
                ),
              ),
              const SliverPadding(padding: EdgeInsets.only(top: 24)),

              // Reward tiers section
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    'マイルストーン',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SliverPadding(padding: EdgeInsets.only(top: 12)),

              // Tier list
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final tier = state.rewardTiers[index];
                    final isUnlocked = state.streak.currentStreak >= tier.day;
                    final isCurrent = state.streak.currentStreak == tier.day;

                    return Padding(
                      padding:
                          const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: _MilestoneCard(
                        tier: tier,
                        isUnlocked: isUnlocked,
                        isCurrent: isCurrent,
                        daysRemaining: tier.day - state.streak.currentStreak,
                      ),
                    );
                  },
                  childCount: state.rewardTiers.length,
                ),
              ),
              const SliverPadding(padding: EdgeInsets.only(top: 24)),

              // Statistics section
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'ログイン統計',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      _LoginStatsGrid(streak: state.streak),
                    ],
                  ),
                ),
              ),
              const SliverPadding(padding: EdgeInsets.only(bottom: 32)),
            ],
          ),
        );
      },
      loading: () => Scaffold(
        appBar: AppBar(title: const Text('デイリーリワード')),
        body: const Center(child: CircularProgressIndicator()),
      ),
      error: (error, stack) => Scaffold(
        appBar: AppBar(title: const Text('デイリーリワード')),
        body: Center(child: Text('エラー: $error')),
      ),
    );
  }
}

/// Streak information card
class _StreakCard extends StatelessWidget {
  final LoginStreak streak;

  const _StreakCard({required this.streak});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final multiplier = streak.getStreakMultiplier();
    final multiplierPercent = ((multiplier - 1) * 100).toInt();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.red.withValues(alpha: 0.8),
            Colors.orange.withValues(alpha: 0.6),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.red.withValues(alpha: 0.3),
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
                    '連続ログイン',
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: Colors.white.withValues(alpha: 0.9),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Text(
                        '🔥',
                        style: TextStyle(fontSize: 40),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        '${streak.currentStreak}日',
                        style: const TextStyle(
                          fontSize: 40,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
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
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '×${multiplier.toStringAsFixed(1)}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '+$multiplierPercent%ボーナス',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.9),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'ベストストリーク: ${streak.bestStreak}日',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.9),
                  fontSize: 12,
                ),
              ),
              Text(
                '総ログイン日数: ${streak.totalLoginDays}日',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.9),
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Daily reward claim card
class _DailyRewardCard extends StatelessWidget {
  final int rewardPoints;
  final bool hasClaimedToday;
  final double multiplier;

  const _DailyRewardCard({
    required this.rewardPoints,
    required this.hasClaimedToday,
    required this.multiplier,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.amber.withValues(alpha: 0.15),
            Colors.yellow.withValues(alpha: 0.1),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(
          color: Colors.amber.withValues(alpha: 0.4),
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
              Text(
                '本日のリワード',
                style: theme.textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: Colors.amber.shade700,
                ),
              ),
              if (hasClaimedToday)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.green.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text(
                    '取得済み',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '⭐ $rewardPoints ポイント',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.amber.shade900,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'ストリークボーナス: ×$multiplier',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: Colors.amber.shade700,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.amber.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  '🎁',
                  style: TextStyle(fontSize: 28),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Milestone card
class _MilestoneCard extends StatelessWidget {
  final LoginRewardTier tier;
  final bool isUnlocked;
  final bool isCurrent;
  final int daysRemaining;

  const _MilestoneCard({
    required this.tier,
    required this.isUnlocked,
    required this.isCurrent,
    required this.daysRemaining,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isUnlocked
            ? Colors.purple.withValues(alpha: 0.1)
            : Colors.grey.withValues(alpha: 0.05),
        border: Border.all(
          color: isCurrent
              ? Colors.purple.withValues(alpha: 0.6)
              : isUnlocked
                  ? Colors.purple.withValues(alpha: 0.3)
                  : Colors.grey.withValues(alpha: 0.2),
          width: isCurrent ? 2 : 1.5,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Text(
            tier.emoji,
            style: const TextStyle(fontSize: 32),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${tier.day}日連続 - ${tier.title}',
                      style: theme.textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: isUnlocked ? Colors.purple.shade700 : Colors.grey.shade600,
                      ),
                    ),
                    if (isCurrent)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
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
                ),
                const SizedBox(height: 4),
                Text(
                  '+${tier.rewardPoints} ポイント',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
          if (!isUnlocked)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                'あと$daysRemaining日',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade700,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Login statistics grid
class _LoginStatsGrid extends StatelessWidget {
  final LoginStreak streak;

  const _LoginStatsGrid({required this.streak});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.3,
      children: [
        _StatCard(
          label: '現在のストリーク',
          value: '${streak.currentStreak}日',
          emoji: '🔥',
          theme: theme,
        ),
        _StatCard(
          label: 'ベストストリーク',
          value: '${streak.bestStreak}日',
          emoji: '🏆',
          theme: theme,
        ),
        _StatCard(
          label: '総ログイン日数',
          value: '${streak.totalLoginDays}日',
          emoji: '📅',
          theme: theme,
        ),
        _StatCard(
          label: 'ストリーク倍率',
          value: '×${streak.getStreakMultiplier()}',
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
