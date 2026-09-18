import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Daily bonus information
class DailyBonus {
  final DateTime date;
  final int rewardPoints;
  final String emoji;
  final bool isCompleted;
  final bool isClaimed;
  final bool isToday;
  final String? description;

  const DailyBonus({
    required this.date,
    required this.rewardPoints,
    required this.emoji,
    this.isCompleted = false,
    this.isClaimed = false,
    this.isToday = false,
    this.description,
  });

  DailyBonus copyWith({
    DateTime? date,
    int? rewardPoints,
    String? emoji,
    bool? isCompleted,
    bool? isClaimed,
    bool? isToday,
    String? description,
  }) {
    return DailyBonus(
      date: date ?? this.date,
      rewardPoints: rewardPoints ?? this.rewardPoints,
      emoji: emoji ?? this.emoji,
      isCompleted: isCompleted ?? this.isCompleted,
      isClaimed: isClaimed ?? this.isClaimed,
      isToday: isToday ?? this.isToday,
      description: description ?? this.description,
    );
  }
}

/// Calendar month data
class CalendarMonth {
  final int month;
  final int year;
  final List<DailyBonus> days;
  final int completedDays;
  final int claimedRewards;
  final int totalRewardsPossible;

  const CalendarMonth({
    required this.month,
    required this.year,
    required this.days,
    required this.completedDays,
    required this.claimedRewards,
    required this.totalRewardsPossible,
  });

  double get completionPercentage =>
      completedDays == 0 ? 0.0 : claimedRewards / totalRewardsPossible;
}

/// Daily bonus calendar state
class DailyBonusCalendarState {
  final CalendarMonth currentMonth;
  final CalendarMonth? previousMonth;
  final int totalBonusEarned;
  final int currentStreak;
  final int bestStreak;
  final List<DateTime> claimedDates;
  final bool isLoading;
  final String? error;

  const DailyBonusCalendarState({
    required this.currentMonth,
    this.previousMonth,
    this.totalBonusEarned = 0,
    this.currentStreak = 0,
    this.bestStreak = 0,
    required this.claimedDates,
    this.isLoading = false,
    this.error,
  });

  /// Copy with modifications
  DailyBonusCalendarState copyWith({
    CalendarMonth? currentMonth,
    CalendarMonth? previousMonth,
    int? totalBonusEarned,
    int? currentStreak,
    int? bestStreak,
    List<DateTime>? claimedDates,
    bool? isLoading,
    String? error,
  }) {
    return DailyBonusCalendarState(
      currentMonth: currentMonth ?? this.currentMonth,
      previousMonth: previousMonth ?? this.previousMonth,
      totalBonusEarned: totalBonusEarned ?? this.totalBonusEarned,
      currentStreak: currentStreak ?? this.currentStreak,
      bestStreak: bestStreak ?? this.bestStreak,
      claimedDates: claimedDates ?? this.claimedDates,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

/// Notifier for daily bonus calendar
class DailyBonusCalendarNotifier
    extends StateNotifier<DailyBonusCalendarState> {
  final SharedPreferences prefs;

  DailyBonusCalendarNotifier(this.prefs)
      : super(_buildInitialState(prefs)) {
    _initializeCalendar();
  }

  /// Initialize calendar
  void _initializeCalendar() {
    _generateCalendarMonths();
  }

  /// Build initial state
  static DailyBonusCalendarState _buildInitialState(
    SharedPreferences prefs,
  ) {
    final claimedDatesStr = prefs.getStringList('claimed_bonus_dates') ?? [];
    final claimedDates = claimedDatesStr
        .map((dateStr) => DateTime.parse(dateStr))
        .toList();

    return DailyBonusCalendarState(
      currentMonth: CalendarMonth(
        month: DateTime.now().month,
        year: DateTime.now().year,
        days: [],
        completedDays: 0,
        claimedRewards: 0,
        totalRewardsPossible: 0,
      ),
      claimedDates: claimedDates,
      totalBonusEarned: prefs.getInt('total_bonus_earned') ?? 0,
      currentStreak: prefs.getInt('bonus_current_streak') ?? 0,
      bestStreak: prefs.getInt('bonus_best_streak') ?? 0,
    );
  }

  /// Generate calendar months
  void _generateCalendarMonths() async {
    final now = DateTime.now();
    final currentMonth = now.month;
    final currentYear = now.year;

    // Generate current month
    final currentMonthData =
        _generateCalendarMonth(currentMonth, currentYear);

    // Generate previous month
    int prevMonth = currentMonth - 1;
    int prevYear = currentYear;
    if (prevMonth < 1) {
      prevMonth = 12;
      prevYear--;
    }
    final previousMonthData =
        _generateCalendarMonth(prevMonth, prevYear);

    state = state.copyWith(
      currentMonth: currentMonthData,
      previousMonth: previousMonthData,
    );
  }

  /// Generate a calendar month
  CalendarMonth _generateCalendarMonth(int month, int year) {
    final now = DateTime.now();
    final daysInMonth = DateTime(year, month + 1, 0).day;
    final days = <DailyBonus>[];

    int completedDays = 0;
    int claimedRewards = 0;
    int totalPossible = 0;

    for (int day = 1; day <= daysInMonth; day++) {
      final date = DateTime(year, month, day);
      final isToday = date.year == now.year &&
          date.month == now.month &&
          date.day == now.day;
      final isFuture = date.isAfter(now);

      // Generate reward based on day (escalating rewards)
      final baseReward = 10 + (day ~/ 7) * 5; // +5 every week
      final bonusMultiplier = 1 + ((day - 1) % 7) * 0.1; // Escalates through week
      final rewardPoints = (baseReward * bonusMultiplier).toInt();

      // Check if claimed
      final isClaimed = state.claimedDates.any(
        (claimedDate) =>
            claimedDate.year == date.year &&
            claimedDate.month == date.month &&
            claimedDate.day == date.day,
      );

      final isCompleted = isClaimed || isToday;

      if (isCompleted) {
        completedDays++;
        if (isClaimed) {
          claimedRewards += rewardPoints;
        }
      }

      totalPossible += rewardPoints;

      final emoji = _getEmoji(day, daysInMonth);

      days.add(DailyBonus(
        date: date,
        rewardPoints: rewardPoints,
        emoji: emoji,
        isCompleted: isCompleted,
        isClaimed: isClaimed,
        isToday: isToday,
        description: _getDescription(day, daysInMonth),
      ));
    }

    return CalendarMonth(
      month: month,
      year: year,
      days: days,
      completedDays: completedDays,
      claimedRewards: claimedRewards,
      totalRewardsPossible: totalPossible,
    );
  }

  /// Get emoji for day
  String _getEmoji(int day, int daysInMonth) {
    if (day % 7 == 0) return '💎'; // Weekly special
    if (day == daysInMonth) return '🎁'; // Month end
    if (day == 1) return '🌟'; // Month start
    if (day % 5 == 0) return '⭐'; // Every 5 days
    return '📅';
  }

  /// Get description for day
  String _getDescription(int day, int daysInMonth) {
    if (day % 7 == 0) return '週間ボーナス！';
    if (day == daysInMonth) return '月末特別報酬';
    if (day == 1) return '月初スタート';
    return '日間ボーナス';
  }

  /// Claim daily bonus
  Future<void> claimBonus(DailyBonus bonus) async {
    if (bonus.isClaimed || bonus.date.isAfter(DateTime.now())) {
      state = state.copyWith(
        error: '既にクレームしたか、未来の日付です',
      );
      return;
    }

    try {
      // Add to claimed dates
      final claimedDates = [...state.claimedDates, bonus.date];
      await prefs.setStringList(
        'claimed_bonus_dates',
        claimedDates.map((d) => d.toIso8601String()).toList(),
      );

      // Update total bonus
      final newTotal =
          state.totalBonusEarned + bonus.rewardPoints;
      await prefs.setInt('total_bonus_earned', newTotal);

      // Update streak
      int newStreak = state.currentStreak + 1;
      int newBestStreak = state.bestStreak;
      if (newStreak > newBestStreak) {
        newBestStreak = newStreak;
        await prefs.setInt('bonus_best_streak', newBestStreak);
      }
      await prefs.setInt('bonus_current_streak', newStreak);

      // Regenerate calendar months
      final currentMonth =
          _generateCalendarMonth(DateTime.now().month, DateTime.now().year);
      final now = DateTime.now();
      int prevMonth = now.month - 1;
      int prevYear = now.year;
      if (prevMonth < 1) {
        prevMonth = 12;
        prevYear--;
      }
      final previousMonthData =
          _generateCalendarMonth(prevMonth, prevYear);

      state = state.copyWith(
        currentMonth: currentMonth,
        previousMonth: previousMonthData,
        claimedDates: claimedDates,
        totalBonusEarned: newTotal,
        currentStreak: newStreak,
        bestStreak: newBestStreak,
      );
    } catch (e) {
      state = state.copyWith(
        error: 'クレーム失敗: $e',
      );
    }
  }
}

/// Riverpod provider for daily bonus calendar
final dailyBonusCalendarProvider =
    StateNotifierProvider<DailyBonusCalendarNotifier, DailyBonusCalendarState>(
  (ref) async {
    final prefs = await SharedPreferences.getInstance();
    return DailyBonusCalendarNotifier(prefs);
  },
);

/// Alternative sync provider (for testing)
final dailyBonusCalendarSyncProvider =
    StateNotifierProvider<DailyBonusCalendarNotifier, DailyBonusCalendarState>(
        (ref) {
  throw UnimplementedError();
});
