import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/statistics_archive_provider.dart';

class StatisticsArchiveScreen extends ConsumerStatefulWidget {
  const StatisticsArchiveScreen({super.key});

  @override
  ConsumerState<StatisticsArchiveScreen> createState() =>
      _StatisticsArchiveScreenState();
}

class _StatisticsArchiveScreenState
    extends ConsumerState<StatisticsArchiveScreen> {
  late PageController _pageController;
  int _currentPeriod = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final archiveState = ref.watch(statisticsArchiveProvider);
    final theme = Theme.of(context);

    final periods = [
      archiveState.dailySnapshots,
      archiveState.weeklySnapshots,
      archiveState.monthlySnapshots,
    ];
    final periodLabels = ['日別', '週別', '月別'];

    return Scaffold(
          backgroundColor: theme.scaffoldBackgroundColor,
          appBar: AppBar(
            title: const Text('統計アーカイブ'),
            elevation: 0,
          ),
          body: CustomScrollView(
            slivers: [
              // Overall stats header
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: _OverallStatsCard(
                    stats: archiveState.overallStats,
                    bestWinRate: archiveState.bestWinRate,
                    highestWinStreak: archiveState.highestWinStreak,
                  ),
                ),
              ),
              const SliverPadding(padding: EdgeInsets.only(top: 8)),

              // Period selector tabs
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: List.generate(
                        3,
                        (index) => Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: FilterChip(
                            selected: _currentPeriod == index,
                            label: Text(periodLabels[index]),
                            onSelected: (selected) {
                              setState(() => _currentPeriod = index);
                              _pageController.animateToPage(
                                index,
                                duration: const Duration(milliseconds: 300),
                                curve: Curves.easeInOut,
                              );
                            },
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SliverPadding(padding: EdgeInsets.only(top: 16)),

              // Statistics chart and list
              SliverFillRemaining(
                child: PageView(
                  controller: _pageController,
                  onPageChanged: (index) {
                    setState(() => _currentPeriod = index);
                  },
                  children: [
                    _StatisticsView(
                      snapshots: periods[0],
                      periodLabel: periodLabels[0],
                    ),
                    _StatisticsView(
                      snapshots: periods[1],
                      periodLabel: periodLabels[1],
                    ),
                    _StatisticsView(
                      snapshots: periods[2],
                      periodLabel: periodLabels[2],
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
  }
}

/// Overall statistics card
class _OverallStatsCard extends StatelessWidget {
  final StatsSnapshot? stats;
  final double bestWinRate;
  final int highestWinStreak;

  const _OverallStatsCard({
    required this.stats,
    required this.bestWinRate,
    required this.highestWinStreak,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (stats == null) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.teal.withValues(alpha: 0.8),
            Colors.cyan.withValues(alpha: 0.6),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.teal.withValues(alpha: 0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            '総合統計',
            style: theme.textTheme.titleLarge?.copyWith(
              color: Colors.white.withValues(alpha: 0.9),
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.5,
            children: [
              _StatItem(
                label: '総試合数',
                value: '${stats!.totalGames}',
                emoji: '🎮',
                theme: theme,
              ),
              _StatItem(
                label: '勝利数',
                value: '${stats!.wins}',
                emoji: '🏆',
                theme: theme,
              ),
              _StatItem(
                label: '敗数',
                value: '${stats!.losses}',
                emoji: '📉',
                theme: theme,
              ),
              _StatItem(
                label: '全体勝率',
                value: '${(stats!.winRate * 100).toStringAsFixed(1)}%',
                emoji: '📊',
                theme: theme,
              ),
              _StatItem(
                label: 'ベスト勝率',
                value: '${(bestWinRate * 100).toStringAsFixed(1)}%',
                emoji: '⭐',
                theme: theme,
              ),
              _StatItem(
                label: '最高連勝',
                value: '$highestWinStreak',
                emoji: '🔥',
                theme: theme,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Statistics view for a period
class _StatisticsView extends StatelessWidget {
  final List<StatsSnapshot> snapshots;
  final String periodLabel;

  const _StatisticsView({
    required this.snapshots,
    required this.periodLabel,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (snapshots.isEmpty) {
      return Center(
        child: Text(
          'データなし',
          style: theme.textTheme.bodyLarge,
        ),
      );
    }

    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: snapshots.length,
            itemBuilder: (context, index) {
              final snapshot =
                  snapshots[snapshots.length - 1 - index];
              final date = _formatDate(snapshot.timestamp, periodLabel);

              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _StatSnapshotCard(
                  snapshot: snapshot,
                  date: date,
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  String _formatDate(DateTime date, String period) {
    if (period == '日別') {
      return '${date.month}月${date.day}日';
    } else if (period == '週別') {
      return '${date.year}年${date.month}月第${((date.day - 1) ~/ 7) + 1}週';
    } else {
      return '${date.year}年${date.month}月';
    }
  }
}

/// Stat item in grid
class _StatItem extends StatelessWidget {
  final String label;
  final String value;
  final String emoji;
  final ThemeData theme;

  const _StatItem({
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
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            emoji,
            style: const TextStyle(fontSize: 20),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: Colors.white.withValues(alpha: 0.8),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

/// Statistics snapshot card
class _StatSnapshotCard extends StatelessWidget {
  final StatsSnapshot snapshot;
  final String date;

  const _StatSnapshotCard({
    required this.snapshot,
    required this.date,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isWinning = snapshot.wins > snapshot.losses;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            (isWinning ? Colors.green : Colors.red)
                .withValues(alpha: 0.1),
            (isWinning ? Colors.green : Colors.red)
                .withValues(alpha: 0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(
          color: (isWinning ? Colors.green : Colors.red)
              .withValues(alpha: 0.3),
          width: 1.5,
        ),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                date,
                style: theme.textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: isWinning ? Colors.green : Colors.red,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: (isWinning ? Colors.green : Colors.red)
                      .withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '${snapshot.wins}勝${snapshot.losses}敗',
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: isWinning ? Colors.green : Colors.red,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _StatDetail(
                label: '勝率',
                value: '${(snapshot.winRate * 100).toStringAsFixed(1)}%',
                emoji: '📊',
              ),
              _StatDetail(
                label: '試合数',
                value: '${snapshot.totalGames}',
                emoji: '🎮',
              ),
              _StatDetail(
                label: 'ポイント',
                value: '${snapshot.totalPoints}',
                emoji: '⭐',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Stat detail in row
class _StatDetail extends StatelessWidget {
  final String label;
  final String value;
  final String emoji;

  const _StatDetail({
    required this.label,
    required this.value,
    required this.emoji,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      children: [
        Text(
          emoji,
          style: const TextStyle(fontSize: 14),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: theme.textTheme.bodySmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 1),
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            fontSize: 10,
            color: Colors.grey.shade600,
          ),
        ),
      ],
    );
  }
}
