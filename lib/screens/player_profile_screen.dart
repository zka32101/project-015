import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../engine/board_theme.dart';
import '../engine/game_record.dart';
import '../engine/models.dart';
import '../providers/player_profile_provider.dart';

class PlayerProfileScreen extends ConsumerWidget {
  const PlayerProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileState = ref.watch(playerProfileProvider);
    final theme = Theme.of(context);

    if (profileState.isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('プロフィール')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (profileState.error != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('プロフィール')),
        body: Center(
          child: Text('エラー: ${profileState.error}'),
        ),
      );
    }

    final profile = profileState.profile;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('プロフィール'),
        elevation: 0,
      ),
      body: CustomScrollView(
        slivers: [
          // Player Header
          SliverToBoxAdapter(
            child: _PlayerHeaderCard(profile: profile),
          ),
          const SliverPadding(padding: EdgeInsets.only(top: 16)),

          // Overall Statistics Section
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '総合成績',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _StatisticsGrid(profile: profile),
                ],
              ),
            ),
          ),
          const SliverPadding(padding: EdgeInsets.only(top: 24)),

          // Achievement Progress Section
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '実績の進行状況',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _AchievementProgressCard(profile: profile),
                ],
              ),
            ),
          ),
          const SliverPadding(padding: EdgeInsets.only(top: 24)),

          // Performance Trends Section
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'パフォーマンス',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _PerformanceCard(profile: profile),
                ],
              ),
            ),
          ),
          const SliverPadding(padding: EdgeInsets.only(top: 24)),

          // Recent Games Section
          if (profile.recentGames.isNotEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '最近のゲーム',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ...[
                      for (final game in profile.recentGames)
                        _RecentGameTile(game: game),
                    ],
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

/// Player header card with level and rating
class _PlayerHeaderCard extends StatelessWidget {
  final PlayerProfile profile;

  const _PlayerHeaderCard({required this.profile});

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
          // Player Level Icon and Name
          Center(
            child: Column(
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: 0.2),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.5),
                      width: 2,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      _getLevelEmoji(profile.getPlayerLevel()),
                      style: const TextStyle(fontSize: 40),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  profile.getPlayerLevel(),
                  style: theme.textTheme.headlineSmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'レーティング: ${profile.estimatedRating}',
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: Colors.white.withValues(alpha: 0.9),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          // Quick Stats Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _QuickStatColumn(
                label: '対局数',
                value: '${profile.totalGames}',
              ),
              _QuickStatColumn(
                label: '勝率',
                value: '${(profile.winRate * 100).toStringAsFixed(1)}%',
              ),
              _QuickStatColumn(
                label: '連勝',
                value: '${profile.currentStreak}',
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _getLevelEmoji(String level) {
    switch (level) {
      case 'ビギナー':
        return '🌱';
      case 'ノービス':
        return '🎯';
      case 'アマチュア':
        return '⭐';
      case 'セミプロ':
        return '🔥';
      case 'プロ':
        return '👑';
      case 'マスター':
        return '💎';
      default:
        return '🎮';
    }
  }
}

/// Quick stat column widget
class _QuickStatColumn extends StatelessWidget {
  final String label;
  final String value;

  const _QuickStatColumn({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.white.withValues(alpha: 0.8),
          ),
        ),
      ],
    );
  }
}

/// Statistics grid showing detailed stats
class _StatisticsGrid extends StatelessWidget {
  final PlayerProfile profile;

  const _StatisticsGrid({required this.profile});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      children: [
        _StatCard(
          theme: theme,
          label: '勝利数',
          value: '${profile.wins}',
          icon: Icons.check_circle,
          color: Colors.green,
        ),
        _StatCard(
          theme: theme,
          label: '敗北数',
          value: '${profile.losses}',
          icon: Icons.cancel,
          color: Colors.red,
        ),
        _StatCard(
          theme: theme,
          label: '引き分け',
          value: '${profile.draws}',
          icon: Icons.pause_circle,
          color: Colors.orange,
        ),
        _StatCard(
          theme: theme,
          label: '最長連勝',
          value: '${profile.bestStreak}',
          icon: Icons.trending_up,
          color: Colors.purple,
        ),
        _StatCard(
          theme: theme,
          label: '平均ゲーム時間',
          value: '${profile.averageGameDuration.toStringAsFixed(0)}秒',
          icon: Icons.timer,
          color: Colors.blue,
        ),
        _StatCard(
          theme: theme,
          label: '総手数',
          value: '${profile.totalMoves}',
          icon: Icons.calculate,
          color: Colors.indigo,
        ),
      ],
    );
  }
}

/// Individual stat card
class _StatCard extends StatelessWidget {
  final ThemeData theme;
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.theme,
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withValues(alpha: 0.3),
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.7),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Achievement progress card
class _AchievementProgressCard extends StatelessWidget {
  final PlayerProfile profile;

  const _AchievementProgressCard({required this.profile});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final progressPercent = (profile.achievementCompletion * 100).toStringAsFixed(1);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.amber.withValues(alpha: 0.3),
          width: 1.5,
        ),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '実績達成度',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                '$progressPercent%',
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: Colors.amber,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: profile.achievementCompletion,
              minHeight: 8,
              backgroundColor: Colors.grey.withValues(alpha: 0.2),
              valueColor: AlwaysStoppedAnimation(Colors.amber.shade400),
            ),
          ),
          const SizedBox(height: 12),
          Center(
            child: Text(
              '${profile.achievementsUnlocked} / ${profile.achievementsTotal}',
              style: theme.textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }
}

/// Performance trends card
class _PerformanceCard extends ConsumerWidget {
  final PlayerProfile profile;

  const _PerformanceCard({required this.profile});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final trend = ref.watch(performanceTrendProvider);
    final recentWinRate = ref.watch(recentWinRateProvider);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.cyan.withValues(alpha: 0.3),
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Trend Indicator
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '最近の傾向',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: _getTrendColor(trend).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  trend,
                  style: TextStyle(
                    color: _getTrendColor(trend),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Recent Win Rate
          _PerformanceRow(
            label: '最近10ゲーム勝率',
            value: '${(recentWinRate * 100).toStringAsFixed(1)}%',
            icon: Icons.trending_up,
          ),
          const SizedBox(height: 12),
          _PerformanceRow(
            label: '総合勝率',
            value: '${(profile.winRate * 100).toStringAsFixed(1)}%',
            icon: Icons.bar_chart,
          ),
          const SizedBox(height: 12),
          _PerformanceRow(
            label: 'プレイ時間',
            value: '${profile.getTotalHoursPlayed().toStringAsFixed(1)}時間',
            icon: Icons.schedule,
          ),
        ],
      ),
    );
  }

  Color _getTrendColor(String trend) {
    if (trend.contains('上昇')) return Colors.green;
    if (trend.contains('下降')) return Colors.red;
    return Colors.orange;
  }
}

/// Performance row widget
class _PerformanceRow extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _PerformanceRow({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Icon(icon, size: 18, color: theme.primaryColor),
            const SizedBox(width: 8),
            Text(label, style: theme.textTheme.bodyMedium),
          ],
        ),
        Text(
          value,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: theme.primaryColor,
          ),
        ),
      ],
    );
  }
}

/// Recent game tile
class _RecentGameTile extends StatelessWidget {
  final GameRecord game;

  const _RecentGameTile({required this.game});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isWin = game.result == GameResult.playerAWins;
    final dateFormat = DateFormat('MM/dd HH:mm');

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isWin
              ? Colors.green.withValues(alpha: 0.3)
              : Colors.red.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                isWin ? '勝利' : game.result == GameResult.draw ? '引き分け' : '敗北',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: isWin
                      ? Colors.green
                      : game.result == GameResult.draw
                          ? Colors.orange
                          : Colors.red,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'AI: ${game.aiDifficulty ?? 'ローカル'}',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.7),
                ),
              ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                dateFormat.format(game.playedAt),
                style: theme.textTheme.bodySmall,
              ),
              const SizedBox(height: 4),
              Text(
                '${game.totalMoves}手',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.7),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
