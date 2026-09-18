import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/daily_bonus_calendar_provider.dart';

class DailyBonusCalendarScreen extends ConsumerWidget {
  const DailyBonusCalendarScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final calendarAsync = ref.watch(dailyBonusCalendarProvider);
    final theme = Theme.of(context);

    return calendarAsync.when(
      data: (calendarState) {
        return Scaffold(
          backgroundColor: theme.scaffoldBackgroundColor,
          appBar: AppBar(
            title: const Text('ログインカレンダー'),
            elevation: 0,
          ),
          body: CustomScrollView(
            slivers: [
              // Streak and rewards header
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: _StreakHeader(
                    currentStreak: calendarState.currentStreak,
                    bestStreak: calendarState.bestStreak,
                    totalBonusEarned: calendarState.totalBonusEarned,
                  ),
                ),
              ),
              const SliverPadding(padding: EdgeInsets.only(top: 8)),

              // Current month calendar
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: _MonthCalendar(
                    month: calendarState.currentMonth,
                    onClaimBonus: (bonus) {
                      ref
                          .read(dailyBonusCalendarProvider.notifier)
                          .claimBonus(bonus);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('${bonus.rewardPoints}⭐を獲得'),
                          duration: const Duration(seconds: 2),
                        ),
                      );
                    },
                  ),
                ),
              ),
              const SliverPadding(padding: EdgeInsets.only(top: 24)),

              // Previous month (if available)
              if (calendarState.previousMonth != null) ...[
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      '前月',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SliverPadding(padding: EdgeInsets.only(top: 12)),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: _MonthCalendar(
                      month: calendarState.previousMonth!,
                      onClaimBonus: (bonus) {
                        ref
                            .read(dailyBonusCalendarProvider.notifier)
                            .claimBonus(bonus);
                      },
                    ),
                  ),
                ),
              ],
              const SliverPadding(padding: EdgeInsets.only(bottom: 32)),
            ],
          ),
        );
      },
      loading: () => Scaffold(
        appBar: AppBar(title: const Text('ログインカレンダー')),
        body: const Center(child: CircularProgressIndicator()),
      ),
      error: (error, stack) => Scaffold(
        appBar: AppBar(title: const Text('ログインカレンダー')),
        body: Center(child: Text('エラー: $error')),
      ),
    );
  }
}

/// Streak and rewards header
class _StreakHeader extends StatelessWidget {
  final int currentStreak;
  final int bestStreak;
  final int totalBonusEarned;

  const _StreakHeader({
    required this.currentStreak,
    required this.bestStreak,
    required this.totalBonusEarned,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.deepOrange.withValues(alpha: 0.8),
            Colors.orange.withValues(alpha: 0.6),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.deepOrange.withValues(alpha: 0.3),
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
                    '現在のストリーク',
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: Colors.white.withValues(alpha: 0.9),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Text(
                        '🔥',
                        style: TextStyle(fontSize: 32),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '$currentStreak日',
                        style: const TextStyle(
                          fontSize: 32,
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
                  Text(
                    'ベストストリーク',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: Colors.white.withValues(alpha: 0.9),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '$bestStreak日',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.amber,
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
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '総獲得ボーナス',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: Colors.white.withValues(alpha: 0.9),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '$totalBonusEarned⭐',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  children: [
                    const Text(
                      '💡',
                      style: TextStyle(fontSize: 20),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '毎日ログインして\nボーナスをゲット！',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Month calendar view
class _MonthCalendar extends StatelessWidget {
  final CalendarMonth month;
  final Function(DailyBonus) onClaimBonus;

  const _MonthCalendar({
    required this.month,
    required this.onClaimBonus,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.grey.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Month header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${month.year}年 ${month.month}月',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: Colors.amber.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '${month.completedDays}/${month.days.length}日',
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.amber,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Progress bar
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: month.completionPercentage,
              minHeight: 6,
              backgroundColor: Colors.grey.withValues(alpha: 0.2),
              valueColor: const AlwaysStoppedAnimation(Colors.amber),
            ),
          ),
          const SizedBox(height: 12),

          // Day labels
          GridView.count(
            crossAxisCount: 7,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
            children: [
              ..._buildDayLabels(theme),
              ...month.days.map(
                (bonus) => _DayCell(
                  bonus: bonus,
                  onTap: () => onClaimBonus(bonus),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  List<Widget> _buildDayLabels(ThemeData theme) {
    final labels = ['日', '月', '火', '水', '木', '金', '土'];
    return labels
        .map(
          (label) => Center(
            child: Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade600,
              ),
            ),
          ),
        )
        .toList();
  }
}

/// Day cell in calendar
class _DayCell extends StatelessWidget {
  final DailyBonus bonus;
  final VoidCallback onTap;

  const _DayCell({
    required this.bonus,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isFuture = bonus.date.isAfter(DateTime.now());

    return GestureDetector(
      onTap: !bonus.isClaimed && !isFuture ? onTap : null,
      child: Container(
        decoration: BoxDecoration(
          gradient: bonus.isClaimed
              ? LinearGradient(
                  colors: [
                    Colors.green.withValues(alpha: 0.2),
                    Colors.green.withValues(alpha: 0.1),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : bonus.isToday
                  ? LinearGradient(
                      colors: [
                        Colors.amber.withValues(alpha: 0.2),
                        Colors.amber.withValues(alpha: 0.1),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    )
                  : null,
          color: isFuture ? Colors.grey.withValues(alpha: 0.1) : null,
          border: Border.all(
            color: bonus.isToday
                ? Colors.amber.withValues(alpha: 0.6)
                : bonus.isClaimed
                    ? Colors.green.withValues(alpha: 0.5)
                    : Colors.grey.withValues(alpha: 0.2),
            width: bonus.isToday ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Stack(
          children: [
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  bonus.emoji,
                  style: const TextStyle(fontSize: 18),
                ),
                const SizedBox(height: 2),
                Text(
                  '${bonus.date.day}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: isFuture ? Colors.grey.shade400 : null,
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  '${bonus.rewardPoints}⭐',
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontSize: 10,
                    color: Colors.amber,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            if (bonus.isClaimed)
              Positioned(
                top: 2,
                right: 2,
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: Colors.green,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check,
                    color: Colors.white,
                    size: 10,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
