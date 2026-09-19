import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:reversia/providers/replay_sharing_provider.dart';

void main() {
  group('ReplaySharingNotifier', () {
    late ProviderContainer container;

    setUp(() {
      container = ProviderContainer();
    });

    tearDown(() {
      container.dispose();
    });

    test('initial state has sample shared replays and my replays, no favorites', () {
      final state = container.read(replaySharingProvider);
      expect(state.sharedReplays, isNotEmpty);
      expect(state.mySharedReplays, isNotEmpty);
      expect(state.favorites, isEmpty);
    });

    test('shareReplay prepends a new replay to mySharedReplays', () async {
      final notifier = container.read(replaySharingProvider.notifier);
      final countBefore = container.read(replaySharingProvider).mySharedReplays.length;

      await notifier.shareReplay(
        gameTitle: 'テスト対局',
        description: 'テスト用の説明',
        moveCount: 40,
        winner: 'あなた',
        difficulty: 'ふつう',
      );

      final state = container.read(replaySharingProvider);
      expect(state.mySharedReplays.length, countBefore + 1);
      expect(state.mySharedReplays.first.gameTitle, 'テスト対局');
      expect(state.isLoading, isFalse);
    });

    test('likeReplay increments the like count of the matching replay only', () async {
      final notifier = container.read(replaySharingProvider.notifier);
      final target = container.read(replaySharingProvider).sharedReplays.first;
      final other = container.read(replaySharingProvider).sharedReplays[1];

      await notifier.likeReplay(target.id);

      final updated = container.read(replaySharingProvider).sharedReplays;
      expect(updated.firstWhere((r) => r.id == target.id).likeCount, target.likeCount + 1);
      expect(updated.firstWhere((r) => r.id == other.id).likeCount, other.likeCount);
    });

    test('unlikeReplay decrements the like count and clamps at zero', () async {
      final notifier = container.read(replaySharingProvider.notifier);
      final target = container.read(replaySharingProvider).sharedReplays.first;

      await notifier.unlikeReplay(target.id);
      final afterOne =
          container.read(replaySharingProvider).sharedReplays.firstWhere((r) => r.id == target.id);
      expect(afterOne.likeCount, target.likeCount - 1);

      // Drive it down to (and past) zero to prove the clamp holds.
      for (var i = 0; i < afterOne.likeCount + 5; i++) {
        await notifier.unlikeReplay(target.id);
      }
      final finalReplay =
          container.read(replaySharingProvider).sharedReplays.firstWhere((r) => r.id == target.id);
      expect(finalReplay.likeCount, 0);
    });

    test('addToFavorites adds once and ignores duplicates', () async {
      final notifier = container.read(replaySharingProvider.notifier);
      final replay = container.read(replaySharingProvider).sharedReplays.first;

      await notifier.addToFavorites(replay);
      await notifier.addToFavorites(replay);

      expect(container.read(replaySharingProvider).favorites, hasLength(1));
    });

    test('removeFromFavorites removes the matching replay', () async {
      final notifier = container.read(replaySharingProvider.notifier);
      final replay = container.read(replaySharingProvider).sharedReplays.first;
      await notifier.addToFavorites(replay);
      expect(container.read(replaySharingProvider).favorites, isNotEmpty);

      await notifier.removeFromFavorites(replay.id);
      expect(container.read(replaySharingProvider).favorites, isEmpty);
    });

    test('addComment increments the comment count of the matching replay', () async {
      final notifier = container.read(replaySharingProvider.notifier);
      final target = container.read(replaySharingProvider).sharedReplays.first;

      await notifier.addComment(target.id, 'いいですね！');

      final updated =
          container.read(replaySharingProvider).sharedReplays.firstWhere((r) => r.id == target.id);
      expect(updated.commentCount, target.commentCount + 1);
    });

    test('loadMoreReplays appends additional replays', () async {
      final notifier = container.read(replaySharingProvider.notifier);
      final countBefore = container.read(replaySharingProvider).sharedReplays.length;

      await notifier.loadMoreReplays();

      final state = container.read(replaySharingProvider);
      expect(state.sharedReplays.length, greaterThan(countBefore));
      expect(state.isLoading, isFalse);
    });

    test('clearError resets the error field', () {
      final notifier = container.read(replaySharingProvider.notifier);
      notifier.clearError();
      expect(container.read(replaySharingProvider).error, isNull);
    });
  });
}
