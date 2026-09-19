import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:reversia/providers/event_system_provider.dart';

void main() {
  group('EventSystemNotifier', () {
    late ProviderContainer container;

    setUp(() {
      container = ProviderContainer();
    });

    tearDown(() {
      container.dispose();
    });

    test('initial state has active and upcoming events plus claimed rewards', () {
      final state = container.read(eventSystemProvider);
      expect(state.activeEvents, isNotEmpty);
      expect(state.upcomingEvents, isNotEmpty);
      expect(state.claimedRewards, isNotEmpty);
      expect(state.totalParticipants, greaterThan(0));
    });

    test('participateInEvent increments the participant count of that event only', () async {
      final notifier = container.read(eventSystemProvider.notifier);
      final target = container.read(eventSystemProvider).activeEvents.first;
      final other = container.read(eventSystemProvider).activeEvents[1];

      await notifier.participateInEvent(target.id);

      final updated = container.read(eventSystemProvider).activeEvents;
      expect(
        updated.firstWhere((e) => e.id == target.id).participantCount,
        target.participantCount + 1,
      );
      expect(
        updated.firstWhere((e) => e.id == other.id).participantCount,
        other.participantCount,
      );
    });

    test('participateInEvent with an unknown id is a no-op, not a crash', () async {
      final notifier = container.read(eventSystemProvider.notifier);
      final before = container.read(eventSystemProvider).activeEvents;

      await notifier.participateInEvent('does_not_exist');

      final after = container.read(eventSystemProvider).activeEvents;
      expect(after.length, before.length);
      expect(container.read(eventSystemProvider).isLoading, isFalse);
    });

    test('completeEventChallenge marks the event completed and grants a reward', () async {
      final notifier = container.read(eventSystemProvider.notifier);
      final target = container.read(eventSystemProvider).activeEvents.first;
      final rewardsBefore = container.read(eventSystemProvider).claimedRewards.length;

      await notifier.completeEventChallenge(target.id);

      final state = container.read(eventSystemProvider);
      final updatedEvent = state.activeEvents.firstWhere((e) => e.id == target.id);
      expect(updatedEvent.isCompleted, isTrue);
      expect(updatedEvent.progressPercentage, 1.0);
      expect(state.claimedRewards.length, rewardsBefore + 1);
    });

    test('claimEventReward adds a new reward to the claimed list', () async {
      final notifier = container.read(eventSystemProvider.notifier);
      final before = container.read(eventSystemProvider).claimedRewards.length;

      await notifier.claimEventReward('event_1');

      expect(container.read(eventSystemProvider).claimedRewards.length, before + 1);
    });

    test("updateEventProgress updates only the targeted event's progress", () async {
      final notifier = container.read(eventSystemProvider.notifier);
      final target = container.read(eventSystemProvider).activeEvents.first;

      await notifier.updateEventProgress(target.id, 0.42);

      final updated =
          container.read(eventSystemProvider).activeEvents.firstWhere((e) => e.id == target.id);
      expect(updated.progressPercentage, 0.42);
    });

    test('clearError resets the error field', () {
      final notifier = container.read(eventSystemProvider.notifier);
      notifier.clearError();
      expect(container.read(eventSystemProvider).error, isNull);
    });
  });
}
