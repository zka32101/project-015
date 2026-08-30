import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../engine/ai.dart';
import '../engine/board_theme.dart';
import '../engine/statistics.dart';
import '../viewmodels/game_view_model.dart';

class StatisticsScreen extends ConsumerWidget {
  const StatisticsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final viewState = ref.watch(gameViewModelProvider);
    final stats = viewState.statistics;
    final theme = ref.watch(boardThemeProvider);

    return Scaffold(
      backgroundColor: theme.screenBackground,
      appBar: AppBar(
        title: const Text('成績'),
        backgroundColor: theme.woodDark,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Overall Statistics
              _StatisticsCard(
                title: '全体成績',
                theme: theme,
                child: Column(
                  children: [
                    _StatRow(
                      label: '対局数',
                      value: '${stats.totalGames}局',
                      theme: theme,
                    ),
                    _StatRow(
                      label: '藍陣営の勝利',
                      value: '${stats.playerAWins}勝',
                      theme: theme,
                      color: theme.frontPieceColor,
                    ),
                    _StatRow(
                      label: '朱陣営の勝利',
                      value: '${stats.playerBWins}勝',
                      theme: theme,
                      color: theme.backPieceColor,
                    ),
                    _StatRow(
                      label: '引き分け',
                      value: '${stats.draws}局',
                      theme: theme,
                    ),
                    const SizedBox(height: 12),
                    _StatRow(
                      label: '藍陣営の勝率',
                      value: stats.formatWinRate(stats.playerAWinRate),
                      theme: theme,
                      isHighlight: true,
                    ),
                    _StatRow(
                      label: '朱陣営の勝率',
                      value: stats.formatWinRate(stats.playerBWinRate),
                      theme: theme,
                      isHighlight: true,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              // Win Streaks
              _StatisticsCard(
                title: 'ウィンストリーク',
                theme: theme,
                child: Column(
                  children: [
                    _StatRow(
                      label: '藍陣営の連勝',
                      value: '${stats.playerAWinStreak}連勝',
                      theme: theme,
                      color: theme.frontPieceColor,
                    ),
                    _StatRow(
                      label: '藍陣営の最長連勝',
                      value: '${stats.playerALongestStreak}連勝',
                      theme: theme,
                      isHighlight: true,
                    ),
                    const SizedBox(height: 8),
                    _StatRow(
                      label: '朱陣営の連勝',
                      value: '${stats.playerBWinStreak}連勝',
                      theme: theme,
                      color: theme.backPieceColor,
                    ),
                    _StatRow(
                      label: '朱陣営の最長連勝',
                      value: '${stats.playerBLongestStreak}連勝',
                      theme: theme,
                      isHighlight: true,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              // Per-Difficulty Statistics
              ...[
                ('ローカル2人対戦', 'local'),
                ('AI: かんたん', 'easy'),
                ('AI: ふつう', 'medium'),
                ('AI: つよい', 'hard'),
              ].map((entry) {
                final label = entry.$1;
                final key = entry.$2;
                final diffStats = stats.statsByDifficulty[key]!;

                if (diffStats.totalGames == 0) {
                  return SizedBox.shrink();
                }

                return Column(
                  children: [
                    _StatisticsCard(
                      title: label,
                      theme: theme,
                      child: Column(
                        children: [
                          _StatRow(
                            label: '対局数',
                            value: '${diffStats.totalGames}局',
                            theme: theme,
                          ),
                          _StatRow(
                            label: '勝利',
                            value: '${diffStats.wins}勝',
                            theme: theme,
                            color: theme.frontPieceColor,
                          ),
                          _StatRow(
                            label: '敗北',
                            value: '${diffStats.losses}敗',
                            theme: theme,
                            color: theme.backPieceColor,
                          ),
                          _StatRow(
                            label: '引き分け',
                            value: '${diffStats.draws}局',
                            theme: theme,
                          ),
                          const SizedBox(height: 12),
                          _StatRow(
                            label: '勝率',
                            value: _formatWinRate(diffStats.winRate),
                            theme: theme,
                            isHighlight: true,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                );
              }),
              if (stats.totalGames == 0)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 32),
                    child: Text(
                      'まだ対局がありません',
                      style: TextStyle(
                        color: Colors.white54,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatWinRate(double winRate) {
    if (winRate.isNaN) return 'N/A';
    return '${(winRate * 100).toStringAsFixed(1)}%';
  }
}

class _StatisticsCard extends StatelessWidget {
  final String title;
  final BoardTheme theme;
  final Widget child;

  const _StatisticsCard({
    required this.title,
    required this.theme,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.black26,
        border: Border.all(color: theme.accentGold.withValues(alpha: 0.3)),
        borderRadius: BorderRadius.circular(8),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              color: theme.accentGold,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

class _StatRow extends StatelessWidget {
  final String label;
  final String value;
  final BoardTheme theme;
  final Color? color;
  final bool isHighlight;

  const _StatRow({
    required this.label,
    required this.value,
    required this.theme,
    this.color,
    this.isHighlight = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(color: Colors.white70, fontSize: 14),
          ),
          Row(
            children: [
              if (color != null)
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              Text(
                value,
                style: TextStyle(
                  color: isHighlight ? theme.accentGold : Colors.white,
                  fontSize: isHighlight ? 15 : 14,
                  fontWeight: isHighlight ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
