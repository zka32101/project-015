import 'dart:async';
import 'dart:math' as math;

import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Limited-time event
class LimitedEvent {
  final String id;
  final String title;
  final String description;
  final String icon;
  final DateTime startDate;
  final DateTime endDate;
  final String eventType; // 'challenge', 'tournament', 'mission', 'bonus'
  final int requiredLevel;
  final List<String> rewards;
  final int participantCount;
  final bool isCompleted;
  final double progressPercentage;

  const LimitedEvent({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
    required this.startDate,
    required this.endDate,
    required this.eventType,
    required this.requiredLevel,
    required this.rewards,
    required this.participantCount,
    this.isCompleted = false,
    this.progressPercentage = 0.0,
  });

  bool get isActive => DateTime.now().isBefore(endDate) && DateTime.now().isAfter(startDate);

  bool get isUpcoming => DateTime.now().isBefore(startDate);

  bool get isExpired => DateTime.now().isAfter(endDate);

  Duration get timeRemaining => endDate.difference(DateTime.now());

  Duration get timeUntilStart => startDate.difference(DateTime.now());

  String get daysRemaining {
    if (isExpired) return '終了';
    final days = timeRemaining.inDays;
    if (days > 0) return '$days日残り';
    final hours = timeRemaining.inHours;
    return '$hours時間残り';
  }

  LimitedEvent copyWith({
    double? progressPercentage,
    bool? isCompleted,
    int? participantCount,
  }) {
    return LimitedEvent(
      id: id,
      title: title,
      description: description,
      icon: icon,
      startDate: startDate,
      endDate: endDate,
      eventType: eventType,
      requiredLevel: requiredLevel,
      rewards: rewards,
      participantCount: participantCount ?? this.participantCount,
      isCompleted: isCompleted ?? this.isCompleted,
      progressPercentage: progressPercentage ?? this.progressPercentage,
    );
  }
}

/// Event reward item
class EventReward {
  final String id;
  final String itemName;
  final String itemIcon;
  final int quantity;
  final String itemType; // 'coin', 'gem', 'badge', 'avatar'

  const EventReward({
    required this.id,
    required this.itemName,
    required this.itemIcon,
    required this.quantity,
    required this.itemType,
  });
}

/// Event system state
class EventSystemState {
  final List<LimitedEvent> activeEvents;
  final List<LimitedEvent> upcomingEvents;
  final List<LimitedEvent> completedEvents;
  final List<EventReward> claimedRewards;
  final bool isLoading;
  final String? error;
  final int totalParticipants;

  const EventSystemState({
    required this.activeEvents,
    required this.upcomingEvents,
    required this.completedEvents,
    required this.claimedRewards,
    this.isLoading = false,
    this.error,
    required this.totalParticipants,
  });

  EventSystemState copyWith({
    List<LimitedEvent>? activeEvents,
    List<LimitedEvent>? upcomingEvents,
    List<LimitedEvent>? completedEvents,
    List<EventReward>? claimedRewards,
    bool? isLoading,
    String? error,
    int? totalParticipants,
  }) {
    return EventSystemState(
      activeEvents: activeEvents ?? this.activeEvents,
      upcomingEvents: upcomingEvents ?? this.upcomingEvents,
      completedEvents: completedEvents ?? this.completedEvents,
      claimedRewards: claimedRewards ?? this.claimedRewards,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      totalParticipants: totalParticipants ?? this.totalParticipants,
    );
  }
}

/// Notifier for event system
class EventSystemNotifier extends StateNotifier<EventSystemState> {
  static final List<LimitedEvent> _sampleActiveEvents = [];
  static final List<LimitedEvent> _sampleUpcomingEvents = [];
  static final List<EventReward> _sampleRewards = [];
  final math.Random _random = math.Random();

  EventSystemNotifier()
      : super(const EventSystemState(
          activeEvents: [],
          upcomingEvents: [],
          completedEvents: [],
          claimedRewards: [],
          totalParticipants: 0,
        )) {
    _initialize();
  }

  void _initialize() {
    _generateActiveEvents();
    _generateUpcomingEvents();
    _generateRewards();
  }

  void _generateActiveEvents() {
    final now = DateTime.now();
    _sampleActiveEvents.clear();
    _sampleActiveEvents.addAll([
      LimitedEvent(
        id: 'event_1',
        title: '秋の大盤賞',
        description: '全プレイヤー対象の大型イベント。上位ランカーを目指そう！',
        icon: '🍁',
        startDate: now.subtract(const Duration(days: 5)),
        endDate: now.add(const Duration(days: 9)),
        eventType: 'tournament',
        requiredLevel: 1,
        rewards: ['10,000ゴールド', 'レアバッジ', 'アバター'],
        participantCount: 2341,
        progressPercentage: 0.6,
      ),
      LimitedEvent(
        id: 'event_2',
        title: 'AI つよい 攻略チャレンジ',
        description: 'つよいAIに3連勝できたら報酬獲得！',
        icon: '🤖',
        startDate: now.subtract(const Duration(days: 2)),
        endDate: now.add(const Duration(days: 12)),
        eventType: 'challenge',
        requiredLevel: 5,
        rewards: ['5,000ゴールド', 'チャレンジバッジ'],
        participantCount: 856,
        progressPercentage: 0.3,
      ),
      LimitedEvent(
        id: 'event_3',
        title: 'デイリーボーナス 2倍キャンペーン',
        description: 'ログインボーナスが今だけ2倍！毎日のログインを忘れずに。',
        icon: '💎',
        startDate: now.subtract(const Duration(days: 1)),
        endDate: now.add(const Duration(days: 6)),
        eventType: 'bonus',
        requiredLevel: 1,
        rewards: ['ログインボーナス2倍'],
        participantCount: 5234,
        progressPercentage: 0.15,
      ),
    ]);

    state = state.copyWith(
      activeEvents: List.from(_sampleActiveEvents),
      totalParticipants: 8431,
    );
  }

  void _generateUpcomingEvents() {
    final now = DateTime.now();
    _sampleUpcomingEvents.clear();
    _sampleUpcomingEvents.addAll([
      LimitedEvent(
        id: 'event_4',
        title: 'ハロウィン スペシャルイベント',
        description: 'ハロウィン記念。限定アバターやバッジが手に入る！',
        icon: '🎃',
        startDate: now.add(const Duration(days: 3)),
        endDate: now.add(const Duration(days: 17)),
        eventType: 'tournament',
        requiredLevel: 1,
        rewards: ['ハロウィンバッジ', '限定アバター'],
        participantCount: 0,
        progressPercentage: 0.0,
      ),
      LimitedEvent(
        id: 'event_5',
        title: '新年特別ランキング',
        description: '年末年始特別企画。豪華な報酬を目指して競おう！',
        icon: '🎊',
        startDate: now.add(const Duration(days: 15)),
        endDate: now.add(const Duration(days: 30)),
        eventType: 'tournament',
        requiredLevel: 1,
        rewards: ['30,000ゴールド', 'ダイヤモンド', 'マスターバッジ'],
        participantCount: 0,
        progressPercentage: 0.0,
      ),
    ]);

    state = state.copyWith(upcomingEvents: List.from(_sampleUpcomingEvents));
  }

  void _generateRewards() {
    _sampleRewards.clear();
    _sampleRewards.addAll([
      EventReward(
        id: 'reward_1',
        itemName: '秋の大盤賞 ボーナスゴールド',
        itemIcon: '🏆',
        quantity: 5000,
        itemType: 'coin',
      ),
      EventReward(
        id: 'reward_2',
        itemName: 'チャレンジマスター バッジ',
        itemIcon: '🎖️',
        quantity: 1,
        itemType: 'badge',
      ),
    ]);

    state = state.copyWith(claimedRewards: List.from(_sampleRewards));
  }

  Future<void> participateInEvent(String eventId) async {
    state = state.copyWith(isLoading: true);
    await Future.delayed(const Duration(milliseconds: 500));

    final eventIndex =
        state.activeEvents.indexWhere((e) => e.id == eventId);
    if (eventIndex >= 0) {
      final event = state.activeEvents[eventIndex];
      final updated = event.copyWith(
        participantCount: event.participantCount + 1,
      );
      final updatedEvents = [...state.activeEvents];
      updatedEvents[eventIndex] = updated;
      state = state.copyWith(
        activeEvents: updatedEvents,
        isLoading: false,
      );
    } else {
      state = state.copyWith(isLoading: false);
    }
  }

  Future<void> completeEventChallenge(String eventId) async {
    state = state.copyWith(isLoading: true);
    await Future.delayed(const Duration(seconds: 1));

    final eventIndex =
        state.activeEvents.indexWhere((e) => e.id == eventId);
    if (eventIndex >= 0) {
      final event = state.activeEvents[eventIndex];
      final updated = event.copyWith(
        isCompleted: true,
        progressPercentage: 1.0,
      );
      final updatedEvents = [...state.activeEvents];
      updatedEvents[eventIndex] = updated;

      // Add reward
      final reward = EventReward(
        id: 'reward_${DateTime.now().millisecondsSinceEpoch}',
        itemName: '${event.title} クリア報酬',
        itemIcon: event.icon,
        quantity: 2500,
        itemType: 'coin',
      );

      state = state.copyWith(
        activeEvents: updatedEvents,
        claimedRewards: [reward, ...state.claimedRewards],
        isLoading: false,
        error: null,
      );
    } else {
      state = state.copyWith(isLoading: false);
    }
  }

  Future<void> claimEventReward(String eventId) async {
    state = state.copyWith(isLoading: true);
    await Future.delayed(const Duration(milliseconds: 600));

    // Simulate claiming reward
    final newReward = EventReward(
      id: 'reward_${DateTime.now().millisecondsSinceEpoch}',
      itemName: 'イベント報酬',
      itemIcon: '🎁',
      quantity: 1000,
      itemType: 'coin',
    );

    state = state.copyWith(
      claimedRewards: [newReward, ...state.claimedRewards],
      isLoading: false,
      error: null,
    );
  }

  Future<void> updateEventProgress(String eventId, double progress) async {
    final eventIndex =
        state.activeEvents.indexWhere((e) => e.id == eventId);
    if (eventIndex >= 0) {
      final event = state.activeEvents[eventIndex];
      final updated = event.copyWith(progressPercentage: progress);
      final updatedEvents = [...state.activeEvents];
      updatedEvents[eventIndex] = updated;
      state = state.copyWith(activeEvents: updatedEvents);
    }
  }

  void clearError() {
    state = state.copyWith(error: null);
  }
}

/// Riverpod provider for event system
final eventSystemProvider =
    StateNotifierProvider<EventSystemNotifier, EventSystemState>(
  (ref) => EventSystemNotifier(),
);
