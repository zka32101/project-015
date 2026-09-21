import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../engine/game_analytics.dart';

/// Overlay widget displaying current game session statistics
class GameStatisticsOverlay extends ConsumerWidget {
  final GameAnalytics analytics;
  final bool isVisible;
  final VoidCallback? onToggle;

  const GameStatisticsOverlay({
    super.key,
    required this.analytics,
    this.isVisible = true,
    this.onToggle,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!isVisible) {
      return Positioned(
        top: 8,
        right: 8,
        child: _StatisticsToggleButton(onPressed: onToggle),
      );
    }

    return Positioned(
      top: 8,
      right: 8,
      child: Container(
        width: 280,
        decoration: BoxDecoration(
          color: Colors.grey[900]?.withValues(alpha: 0.9),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Colors.white10,
            width: 1,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header with close button
            Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Statistics',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  GestureDetector(
                    onTap: onToggle,
                    child: Icon(
                      Icons.close,
                      color: Colors.white54,
                      size: 18,
                    ),
                  ),
                ],
              ),
            ),
            Divider(height: 1, color: Colors.white10),

            // Statistics content
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _StatRow(
                    label: 'Total Games',
                    value: analytics.baseStats.totalGames.toString(),
                  ),
                  const SizedBox(height: 8),
                  _StatRow(
                    label: 'Win Rate',
                    value: analytics.totalWinRatePercentage,
                    color: Colors.green,
                  ),
                  const SizedBox(height: 8),
                  _StatRow(
                    label: 'Current Streak',
                    value: analytics.currentStreak.toString(),
                    subtitle: analytics.currentStreakType,
                    color: analytics.currentStreakType == 'win' ? Colors.green : Colors.red,
                  ),
                  const SizedBox(height: 8),
                  _StatRow(
                    label: 'Best Streak',
                    value: analytics.bestWinStreak.toString(),
                  ),
                  const SizedBox(height: 8),
                  _StatRow(
                    label: 'Performance',
                    value: analytics.getPerformanceLevel(),
                    color: _getPerformanceColor(analytics.getPerformanceLevel()),
                  ),
                  const SizedBox(height: 8),
                  _StatRow(
                    label: 'Skill Rating',
                    value: analytics.getSkillRating().toString(),
                    color: Colors.purple,
                  ),
                  const SizedBox(height: 12),

                  // Achievement indicators
                  if (analytics.getAchievedMilestones().isNotEmpty) ...[
                    Text(
                      'Achievements',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _AchievementIndicators(
                      achievedCount: analytics.getAchievedMilestones().length,
                      totalCount: 8,
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getPerformanceColor(String level) {
    switch (level) {
      case 'Excellent':
        return Colors.green;
      case 'Very Good':
        return Colors.lightGreen;
      case 'Good':
        return Colors.amber;
      case 'Fair':
        return Colors.orange;
      case 'Needs Work':
        return Colors.deepOrange;
      default:
        return Colors.red;
    }
  }
}

/// Individual statistic row
class _StatRow extends StatelessWidget {
  final String label;
  final String value;
  final String? subtitle;
  final Color? color;

  const _StatRow({
    required this.label,
    required this.value,
    this.subtitle,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 11,
              ),
            ),
            if (subtitle != null)
              Text(
                subtitle!,
                style: TextStyle(
                  color: color ?? Colors.white54,
                  fontSize: 10,
                ),
              ),
          ],
        ),
        Text(
          value,
          style: TextStyle(
            color: color ?? Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}

/// Achievement indicators showing progress
class _AchievementIndicators extends StatelessWidget {
  final int achievedCount;
  final int totalCount;

  const _AchievementIndicators({
    required this.achievedCount,
    required this.totalCount,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.amber[900]?.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: Colors.amber[300]!.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.emoji_events,
            color: Colors.amber[400],
            size: 16,
          ),
          const SizedBox(width: 6),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(3),
              child: LinearProgressIndicator(
                value: achievedCount / totalCount,
                minHeight: 6,
                backgroundColor: Colors.amber[900]?.withValues(alpha: 0.3),
                valueColor: AlwaysStoppedAnimation<Color>(Colors.amber[400]!),
              ),
            ),
          ),
          const SizedBox(width: 6),
          Text(
            '$achievedCount/$totalCount',
            style: TextStyle(
              color: Colors.amber[300],
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

/// Toggle button for statistics panel
class _StatisticsToggleButton extends StatelessWidget {
  final VoidCallback? onPressed;

  const _StatisticsToggleButton({this.onPressed});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.blue[900]?.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: Colors.blue[300]!.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
        child: Icon(
          Icons.bar_chart,
          color: Colors.blue[300],
          size: 20,
        ),
      ),
    );
  }
}

/// Quick stats bar for bottom of screen
class QuickStatsBar extends ConsumerWidget {
  final GameAnalytics analytics;

  const QuickStatsBar({
    super.key,
    required this.analytics,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.4),
        border: Border(
          top: BorderSide(
            color: Colors.white10,
            width: 1,
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _QuickStat(
            label: 'W/L',
            value: '${analytics.baseStats.playerAWins}/${analytics.baseStats.playerBWins}',
            icon: Icons.sports,
          ),
          _QuickStat(
            label: 'Streak',
            value: analytics.currentStreak.toString(),
            icon: analytics.currentStreakType == 'win' ? Icons.trending_up : Icons.trending_down,
            color: analytics.currentStreakType == 'win' ? Colors.green : Colors.red,
          ),
          _QuickStat(
            label: 'Level',
            value: analytics.getPerformanceLevel(),
            icon: Icons.star,
          ),
          _QuickStat(
            label: 'Rating',
            value: (analytics.getSkillRating() / 100).toStringAsFixed(0),
            icon: Icons.trending_up,
            color: Colors.purple,
          ),
        ],
      ),
    );
  }
}

/// Individual quick stat
class _QuickStat extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color? color;

  const _QuickStat({
    required this.label,
    required this.value,
    required this.icon,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          color: color ?? Colors.white54,
          size: 16,
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            color: color ?? Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white54,
            fontSize: 9,
          ),
        ),
      ],
    );
  }
}
