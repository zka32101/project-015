import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/game_analytics_provider.dart';

class GameAnalyticsDashboardScreen extends ConsumerWidget {
  const GameAnalyticsDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final analyticsState = ref.watch(gameAnalyticsProvider);
    final theme = Theme.of(context);

    if (analyticsState.isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('ゲーム分析')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (analyticsState.totalGamesAnalyzed == 0) {
      return Scaffold(
        appBar: AppBar(title: const Text('ゲーム分析')),
        body: Center(
          child: Text(
            'ゲーム履歴がありません',
            style: theme.textTheme.bodyLarge,
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('ゲーム分析'),
        elevation: 0,
      ),
      body: CustomScrollView(
        slivers: [
          // Summary Statistics Section
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '統計概要',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _SummaryStatsGrid(analyticsState: analyticsState),
                ],
              ),
            ),
          ),
          const SliverPadding(padding: EdgeInsets.only(top: 8)),

          // Difficulty Performance Section
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'AI別成績',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _DifficultyPerformanceChart(
                    analytics: analyticsState,
                  ),
                ],
              ),
            ),
          ),
          const SliverPadding(padding: EdgeInsets.only(top: 24)),

          // Performance Trend Section
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '成績推移',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _PerformanceTrendChart(
                    analyticsState: analyticsState,
                  ),
                ],
              ),
            ),
          ),
          const SliverPadding(padding: EdgeInsets.only(top: 24)),

          // Activity Section
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'アクティビティ',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _ActivityChart(analyticsState: analyticsState),
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

/// Summary statistics grid
class _SummaryStatsGrid extends StatelessWidget {
  final GameAnalyticsState analyticsState;

  const _SummaryStatsGrid({required this.analyticsState});

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
        _StatTile(
          theme: theme,
          label: '総対局数',
          value: '${analyticsState.totalGamesAnalyzed}',
          icon: Icons.sports_esports,
          color: Colors.blue,
        ),
        _StatTile(
          theme: theme,
          label: '総勝率',
          value:
              '${(analyticsState.overallWinRate * 100).toStringAsFixed(1)}%',
          icon: Icons.trending_up,
          color: Colors.green,
        ),
        _StatTile(
          theme: theme,
          label: '今週のゲーム',
          value: '${analyticsState.gamesThisWeek}',
          icon: Icons.calendar_today,
          color: Colors.orange,
        ),
        _StatTile(
          theme: theme,
          label: '平均ゲーム時間',
          value: '${analyticsState.averageDurationOverall.toStringAsFixed(0)}秒',
          icon: Icons.timer,
          color: Colors.purple,
        ),
      ],
    );
  }
}

/// Individual stat tile
class _StatTile extends StatelessWidget {
  final ThemeData theme;
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _StatTile({
    required this.theme,
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.textTheme.bodySmall?.color?.withValues(
                    alpha: 0.7,
                  ),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: theme.textTheme.titleSmall?.copyWith(
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

/// Difficulty performance chart
class _DifficultyPerformanceChart extends StatelessWidget {
  final GameAnalyticsState analytics;

  const _DifficultyPerformanceChart({required this.analytics});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final difficultyBreakdown = analytics.difficultyBreakdown;

    if (difficultyBreakdown.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Center(
          child: Text('データなし'),
        ),
      );
    }

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
        children: [
          for (int i = 0; i < difficultyBreakdown.length; i++)
            _DifficultyBar(
              difficulty: difficultyBreakdown[i],
              isLast: i == difficultyBreakdown.length - 1,
            ),
        ],
      ),
    );
  }
}

/// Single difficulty bar
class _DifficultyBar extends StatelessWidget {
  final DifficultyAnalytics difficulty;
  final bool isLast;

  const _DifficultyBar({
    required this.difficulty,
    required this.isLast,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final winRatePercent = (difficulty.winRate * 100).toStringAsFixed(1);

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Row(
                children: [
                  Text(
                    difficulty.getEmoji(),
                    style: const TextStyle(fontSize: 20),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    difficulty.getLabel(),
                    style: theme.textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
            Text(
              '$winRatePercent%',
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.blue,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: difficulty.winRate,
            minHeight: 8,
            backgroundColor: Colors.grey.withValues(alpha: 0.2),
            valueColor: AlwaysStoppedAnimation(
              _getColorForWinRate(difficulty.winRate),
            ),
          ),
        ),
        const SizedBox(height: 4),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '${difficulty.wins}勝 ${difficulty.losses}敗 ${difficulty.draws}分',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.textTheme.bodySmall?.color?.withValues(
                  alpha: 0.6,
                ),
              ),
            ),
            Text(
              '${difficulty.totalGames}局',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.textTheme.bodySmall?.color?.withValues(
                  alpha: 0.6,
                ),
              ),
            ),
          ],
        ),
        if (!isLast) const SizedBox(height: 16),
      ],
    );
  }

  Color _getColorForWinRate(double rate) {
    if (rate >= 0.6) return Colors.green;
    if (rate >= 0.5) return Colors.blue;
    if (rate >= 0.4) return Colors.orange;
    return Colors.red;
  }
}

/// Performance trend chart
class _PerformanceTrendChart extends StatelessWidget {
  final GameAnalyticsState analyticsState;

  const _PerformanceTrendChart({required this.analyticsState});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final recentPerformance = analyticsState.recentPerformance;
    final trend = analyticsState.getTrend();

    if (recentPerformance.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Center(
          child: Text('データなし'),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.cyan.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '最近${recentPerformance.length}ゲーム',
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: _getTrendColor(trend).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  trend,
                  style: TextStyle(
                    fontSize: 12,
                    color: _getTrendColor(trend),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Simple dot chart
          SizedBox(
            height: 80,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                for (final point in recentPerformance)
                  _TrendDot(
                    winRate: point.winRate,
                    gameNumber: point.gameNumber,
                  ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          // Stats row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _TrendStat(
                label: '現在',
                value:
                    '${(recentPerformance.first.winRate * 100).toStringAsFixed(1)}%',
              ),
              _TrendStat(
                label: '最高',
                value:
                    '${(recentPerformance.map((p) => p.winRate).reduce((a, b) => a > b ? a : b) * 100).toStringAsFixed(1)}%',
              ),
              _TrendStat(
                label: '平均',
                value:
                    '${((recentPerformance.fold<double>(0, (sum, p) => sum + p.winRate) / recentPerformance.length) * 100).toStringAsFixed(1)}%',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Color _getTrendColor(String trend) {
    if (trend.contains('向上')) return Colors.green;
    if (trend.contains('低下')) return Colors.red;
    return Colors.orange;
  }
}

/// Single trend dot
class _TrendDot extends StatelessWidget {
  final double winRate;
  final int gameNumber;

  const _TrendDot({
    required this.winRate,
    required this.gameNumber,
  });

  @override
  Widget build(BuildContext context) {
    final height = winRate * 70; // Scale to fit in 80px height

    return Tooltip(
      message: 'ゲーム$gameNumber: ${(winRate * 100).toStringAsFixed(1)}%',
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Container(
            width: 6,
            height: height,
            decoration: BoxDecoration(
              color: _getColorForRate(winRate),
              borderRadius: BorderRadius.circular(3),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            gameNumber.toString(),
            style: const TextStyle(fontSize: 9),
          ),
        ],
      ),
    );
  }

  Color _getColorForRate(double rate) {
    if (rate >= 0.6) return Colors.green;
    if (rate >= 0.5) return Colors.blue;
    if (rate >= 0.4) return Colors.orange;
    return Colors.red;
  }
}

/// Trend stat display
class _TrendStat extends StatelessWidget {
  final String label;
  final String value;

  const _TrendStat({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      children: [
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.6),
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: Colors.blue,
          ),
        ),
      ],
    );
  }
}

/// Activity chart showing games per day
class _ActivityChart extends StatelessWidget {
  final GameAnalyticsState analyticsState;

  const _ActivityChart({required this.analyticsState});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final gamesPerDay = analyticsState.getGamesPerDay();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.purple.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'アクティビティ',
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              Icon(
                Icons.trending_up,
                color: Colors.purple,
                size: 20,
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _ActivityStat(
                icon: Icons.calendar_today,
                label: '今月のゲーム',
                value: '${analyticsState.gamesThisMonth}',
                color: Colors.orange,
              ),
              _ActivityStat(
                icon: Icons.date_range,
                label: '1日平均',
                value: '${gamesPerDay.toStringAsFixed(1)}',
                color: Colors.purple,
              ),
              _ActivityStat(
                icon: Icons.speed,
                label: 'ゲーム/週',
                value: '${(gamesPerDay * 7).toStringAsFixed(0)}',
                color: Colors.cyan,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Activity stat display
class _ActivityStat extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _ActivityStat({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color:
                theme.textTheme.bodySmall?.color?.withValues(alpha: 0.6),
            fontSize: 11,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}
