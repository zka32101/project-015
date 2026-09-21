import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/leaderboard_provider.dart';

class LeaderboardScreen extends ConsumerWidget {
  const LeaderboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final leaderboardState = ref.watch(leaderboardProvider);
    final leaderboard = ref.read(leaderboardProvider.notifier);
    final theme = Theme.of(context);

    if (leaderboardState.isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('ランキング')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (leaderboardState.error != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('ランキング')),
        body: Center(
          child: Text('エラー: ${leaderboardState.error}'),
        ),
      );
    }

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('ランキング'),
        elevation: 0,
      ),
      body: CustomScrollView(
        slivers: [
          // Period selector
          SliverToBoxAdapter(
            child: _PeriodSelector(
              currentPeriod: leaderboardState.period,
              onPeriodChanged: leaderboard.setPeriod,
            ),
          ),
          const SliverPadding(padding: EdgeInsets.only(top: 16)),

          // Player rank card
          if (leaderboardState.playerEntry != null)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: _PlayerRankCard(
                  entry: leaderboardState.playerEntry!,
                  advantage: leaderboardState.getPlayerAdvantageVsAverage(),
                ),
              ),
            ),
          const SliverPadding(padding: EdgeInsets.only(top: 20)),

          // Top 3 featured section
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'トップランカー',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
              ),
            ),
          ),
          const SliverPadding(padding: EdgeInsets.only(top: 8)),

          SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final entry = leaderboardState.getTopThree()[index];
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: _TopRankCard(entry: entry),
                );
              },
              childCount: leaderboardState.getTopThree().length,
            ),
          ),
          const SliverPadding(padding: EdgeInsets.only(top: 24)),

          // All rankings section
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                '全ランキング',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SliverPadding(padding: EdgeInsets.only(top: 12)),

          // Ranking list
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final entry = leaderboardState.entries[index];
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  child: _RankingListItem(entry: entry),
                );
              },
              childCount: leaderboardState.entries.length,
            ),
          ),
          const SliverPadding(padding: EdgeInsets.only(bottom: 32)),
        ],
      ),
    );
  }
}

/// Period selector buttons
class _PeriodSelector extends StatelessWidget {
  final LeaderboardPeriod currentPeriod;
  final Function(LeaderboardPeriod) onPeriodChanged;

  const _PeriodSelector({
    required this.currentPeriod,
    required this.onPeriodChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          for (final period in LeaderboardPeriod.values)
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: FilterChip(
                  label: Text(
                    period.label,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: currentPeriod == period
                          ? Colors.white
                          : Colors.grey.shade700,
                    ),
                  ),
                  selected: currentPeriod == period,
                  onSelected: (_) => onPeriodChanged(period),
                  backgroundColor: Colors.grey.shade200,
                  selectedColor: Colors.blue.shade600,
                  side: BorderSide.none,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Player's current rank card
class _PlayerRankCard extends StatelessWidget {
  final LeaderboardEntry entry;
  final double advantage;

  const _PlayerRankCard({
    required this.entry,
    required this.advantage,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isPositive = advantage >= 0;
    final advantageLabel = isPositive ? '+' : '';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.blue.withValues(alpha: 0.15),
            Colors.cyan.withValues(alpha: 0.1),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(
          color: Colors.blue.withValues(alpha: 0.4),
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
                    'あなたのランク',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: Colors.blue.shade700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(
                        entry.getRankEmoji(),
                        style: const TextStyle(fontSize: 28),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        '#${entry.rank}',
                        style: const TextStyle(
                          fontSize: 28,
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
                      color: Colors.blue.shade100,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      entry.getRatingCategory(),
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.blue.shade700,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    entry.rating.toStringAsFixed(0),
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
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
                    '勝率: ${(entry.winRate * 100).toStringAsFixed(1)}%',
                    style: theme.textTheme.bodySmall,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${entry.wins}勝 / ${entry.totalGames}戦',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: isPositive
                      ? Colors.green.withValues(alpha: 0.2)
                      : Colors.orange.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '$advantageLabel${advantage.toStringAsFixed(1)}%',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: isPositive ? Colors.green.shade700 : Colors.orange.shade700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '平均プレイヤーより${isPositive ? '強い' : '弱い'}',
            style: theme.textTheme.bodySmall?.copyWith(
              color: isPositive ? Colors.green.shade700 : Colors.orange.shade700,
            ),
          ),
        ],
      ),
    );
  }
}

/// Top rank card for top 3
class _TopRankCard extends StatelessWidget {
  final LeaderboardEntry entry;

  const _TopRankCard({required this.entry});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isFirstPlace = entry.rank == 1;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.amber.withValues(alpha: 0.15),
            Colors.orange.withValues(alpha: 0.1),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(
          color: Colors.amber.withValues(alpha: 0.4),
          width: isFirstPlace ? 2 : 1.5,
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: isFirstPlace
            ? [
                BoxShadow(
                  color: Colors.amber.withValues(alpha: 0.2),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ]
            : null,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    entry.getRankEmoji(),
                    style: const TextStyle(fontSize: 28),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        entry.playerName,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        entry.getRankLabel(),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: Colors.amber.shade700,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                '${entry.wins}勝 ${(entry.winRate * 100).toStringAsFixed(0)}% ${entry.streak}連勝',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.amber.shade100,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              entry.rating.toStringAsFixed(0),
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: Colors.amber.shade900,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// List item for ranking
class _RankingListItem extends StatelessWidget {
  final LeaderboardEntry entry;

  const _RankingListItem({required this.entry});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isTopTen = entry.rank <= 10;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: isTopTen ? Colors.amber.withValues(alpha: 0.05) : Colors.transparent,
        border: Border(
          bottom: BorderSide(
            color: Colors.grey.withValues(alpha: 0.1),
            width: 1,
          ),
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          // Rank
          SizedBox(
            width: 50,
            child: Text(
              '#${entry.rank}',
              style: theme.textTheme.bodyLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: isTopTen ? Colors.amber.shade700 : Colors.grey.shade700,
              ),
            ),
          ),

          // Player info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry.playerName,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  '${entry.wins}W / ${entry.totalGames}G',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),

          // Stats
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                entry.rating.toStringAsFixed(0),
                style: theme.textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.blue.shade600,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '${(entry.winRate * 100).toStringAsFixed(0)}%',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
