import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../engine/game_analytics.dart';

/// Main statistics display panel
class GameStatisticsPanel extends ConsumerWidget {
  final GameAnalytics analytics;

  const GameStatisticsPanel({
    Key? key,
    required this.analytics,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.white10,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Game Statistics',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _StatisticCard(
                label: 'Total Games',
                value: analytics.baseStats.totalGames.toString(),
                color: Colors.blue,
              ),
              _StatisticCard(
                label: 'Win Rate',
                value: analytics.totalWinRatePercentage,
                color: Colors.green,
              ),
              _StatisticCard(
                label: 'Draws',
                value: analytics.drawRatePercentage,
                color: Colors.amber,
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _StatisticCard(
                label: 'Wins',
                value: analytics.baseStats.playerAWins.toString(),
                color: Colors.green[600]!,
              ),
              _StatisticCard(
                label: 'Losses',
                value: analytics.baseStats.playerBWins.toString(),
                color: Colors.red[600]!,
              ),
              _StatisticCard(
                label: 'W/L Ratio',
                value: analytics.winLossRatio.toStringAsFixed(2),
                color: Colors.purple,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Individual statistic card
class _StatisticCard extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _StatisticCard({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.white54,
              fontSize: 11,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

/// Difficulty performance analysis panel
class DifficultyAnalyticsPanel extends ConsumerWidget {
  final GameAnalytics analytics;

  const DifficultyAnalyticsPanel({
    Key? key,
    required this.analytics,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final difficulties = analytics.baseStats.statsByDifficulty;
    if (difficulties.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.white10,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Difficulty Performance',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 12),
          ...difficulties.entries.map((entry) {
            final difficulty = entry.key;
            final stats = entry.value;
            final rate = stats.totalGames > 0 ? stats.winRate : 0.0;

            return Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      difficulty,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 13,
                      ),
                    ),
                    Text(
                      '${stats.wins}W-${stats.losses}L',
                      style: TextStyle(
                        color: Colors.white54,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: rate,
                    minHeight: 6,
                    backgroundColor: Colors.grey[800],
                    valueColor: AlwaysStoppedAnimation<Color>(
                      rate >= 0.6 ? Colors.green : rate >= 0.4 ? Colors.amber : Colors.red,
                    ),
                  ),
                ),
                Text(
                  '${(rate * 100).toStringAsFixed(1)}%',
                  style: TextStyle(
                    color: Colors.white54,
                    fontSize: 11,
                  ),
                ),
                const SizedBox(height: 8),
              ],
            );
          }).toList(),
        ],
      ),
    );
  }
}

/// Streak and performance level panel
class StreakAndPerformancePanel extends ConsumerWidget {
  final GameAnalytics analytics;

  const StreakAndPerformancePanel({
    Key? key,
    required this.analytics,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentStreak = analytics.currentStreak;
    final streakType = analytics.currentStreakType;
    final bestWinStreak = analytics.bestWinStreak;
    final performanceLevel = analytics.getPerformanceLevel();
    final skillRating = analytics.getSkillRating();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.white10,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Performance Overview',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _PerformanceIndicator(
                label: 'Current Streak',
                value: currentStreak.toString(),
                type: streakType,
              ),
              _PerformanceIndicator(
                label: 'Best Streak',
                value: bestWinStreak.toString(),
                type: 'best',
              ),
              _PerformanceIndicator(
                label: 'Skill Rating',
                value: skillRating.toString(),
                type: 'rating',
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue[900]?.withOpacity(0.3),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: Colors.blue[300]!.withOpacity(0.3),
                width: 1,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Performance Level',
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 13,
                  ),
                ),
                Text(
                  performanceLevel,
                  style: TextStyle(
                    color: Colors.blue[300],
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Performance indicator component
class _PerformanceIndicator extends StatelessWidget {
  final String label;
  final String value;
  final String type; // 'win', 'loss', 'best', 'rating'

  const _PerformanceIndicator({
    required this.label,
    required this.value,
    required this.type,
  });

  Color get _color {
    switch (type) {
      case 'win':
        return Colors.green;
      case 'loss':
        return Colors.red;
      case 'best':
        return Colors.amber;
      case 'rating':
        return Colors.purple;
      default:
        return Colors.blue;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: _color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: _color.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.white54,
              fontSize: 11,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              color: _color,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

/// Milestone/achievement display panel
class MilestonePanel extends ConsumerWidget {
  final GameAnalytics analytics;

  const MilestonePanel({
    Key? key,
    required this.analytics,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final achievements = analytics.getAchievedMilestones();
    final allMilestones = [
      'first_win',
      'ten_wins',
      'fifty_wins',
      'hundred_wins',
      'win_streak_5',
      'win_streak_10',
      'perfect_game',
      'beat_all_difficulties',
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.white10,
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
                'Achievements',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.amber[900]?.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(
                    color: Colors.amber[300]!.withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: Text(
                  '${achievements.length}/${allMilestones.length}',
                  style: TextStyle(
                    color: Colors.amber[300],
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
            childAspectRatio: 2.5,
            children: allMilestones.map((milestone) {
              final achieved = achievements.contains(milestone);
              final progress = analytics.getMilestoneProgress(milestone);

              return _MilestoneCard(
                milestone: milestone,
                achieved: achieved,
                progress: progress,
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

/// Individual milestone card
class _MilestoneCard extends StatelessWidget {
  final String milestone;
  final bool achieved;
  final double progress;

  const _MilestoneCard({
    required this.milestone,
    required this.achieved,
    required this.progress,
  });

  String get _label {
    switch (milestone) {
      case 'first_win':
        return 'First Win';
      case 'ten_wins':
        return '10 Wins';
      case 'fifty_wins':
        return '50 Wins';
      case 'hundred_wins':
        return '100 Wins';
      case 'win_streak_5':
        return '5-Win Streak';
      case 'win_streak_10':
        return '10-Win Streak';
      case 'perfect_game':
        return 'Perfect Game';
      case 'beat_all_difficulties':
        return 'Master All';
      default:
        return milestone;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: achieved ? Colors.amber[900]?.withOpacity(0.2) : Colors.grey[800]?.withOpacity(0.3),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: achieved ? Colors.amber[300]!.withOpacity(0.5) : Colors.grey[700]!.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            achieved ? '✓' : '◯',
            style: TextStyle(
              color: achieved ? Colors.amber[300] : Colors.grey[600],
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            _label,
            style: TextStyle(
              color: achieved ? Colors.white : Colors.white54,
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
          if (progress < 1.0 && progress > 0.0) ...[
            const SizedBox(height: 2),
            ClipRRect(
              borderRadius: BorderRadius.circular(2),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 2,
                backgroundColor: Colors.grey[800],
                valueColor: const AlwaysStoppedAnimation<Color>(Colors.amber),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Time-based activity analytics
class ActivityAnalyticsPanel extends ConsumerWidget {
  final GameAnalytics analytics;

  const ActivityAnalyticsPanel({
    Key? key,
    required this.analytics,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (analytics.sessionHistory.isEmpty) {
      return const SizedBox.shrink();
    }

    final gamesLast7Days = analytics.getGamesInLastDays(7);
    final avgPerDay = analytics.getAverageGamesPerDay(7);
    final mostActiveDay = analytics.getMostActiveDayOfWeek();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.white10,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Activity (Last 7 Days)',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _ActivityCard(
                label: 'Games Played',
                value: gamesLast7Days.toString(),
                color: Colors.cyan,
              ),
              _ActivityCard(
                label: 'Per Day Avg',
                value: avgPerDay.toStringAsFixed(1),
                color: Colors.teal,
              ),
              _ActivityCard(
                label: 'Most Active',
                value: mostActiveDay != null ? analytics.getDayName(mostActiveDay) : '—',
                color: Colors.lightGreen,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Activity card component
class _ActivityCard extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _ActivityCard({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.white54,
              fontSize: 11,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

/// Full analytics dashboard
class GameAnalyticsDashboard extends ConsumerWidget {
  final GameAnalytics analytics;

  const GameAnalyticsDashboard({
    Key? key,
    required this.analytics,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          GameStatisticsPanel(analytics: analytics),
          const SizedBox(height: 12),
          DifficultyAnalyticsPanel(analytics: analytics),
          const SizedBox(height: 12),
          StreakAndPerformancePanel(analytics: analytics),
          const SizedBox(height: 12),
          MilestonePanel(analytics: analytics),
          const SizedBox(height: 12),
          ActivityAnalyticsPanel(analytics: analytics),
          const SizedBox(height: 12),
        ],
      ),
    );
  }
}
