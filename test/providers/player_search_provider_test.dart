import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:reversia/providers/player_search_provider.dart';

Future<void> _seedProfile(
  FakeFirebaseFirestore firestore,
  String uid, {
  required String displayName,
  required int rankPoints,
  int wins = 0,
  int losses = 0,
  int draws = 0,
}) {
  return firestore.collection('publicProfiles').doc(uid).set({
    'displayName': displayName,
    'rankPoints': rankPoints,
    'wins': wins,
    'losses': losses,
    'draws': draws,
    'updatedAt': Timestamp.now(),
  });
}

void main() {
  group('PlayerSearchNotifier', () {
    late FakeFirebaseFirestore firestore;

    setUp(() {
      firestore = FakeFirebaseFirestore();
    });

    test('watches the top players, sorted by rankPoints descending', () async {
      await _seedProfile(firestore, 'a', displayName: 'あかり', rankPoints: 100);
      await _seedProfile(firestore, 'b', displayName: 'ゆうと', rankPoints: 300);

      final notifier = PlayerSearchNotifier(firestore: firestore);
      await pumpEventQueue();

      expect(notifier.state.topPlayers, hasLength(2));
      expect(notifier.state.topPlayers[0].name, 'ゆうと');
      expect(notifier.state.topPlayers[1].name, 'あかり');
    });

    test('searchPlayers finds real profiles by display-name prefix', () async {
      await _seedProfile(firestore, 'a', displayName: 'さくら', rankPoints: 100, wins: 5, losses: 2);
      await _seedProfile(firestore, 'b', displayName: 'さとし', rankPoints: 200);
      await _seedProfile(firestore, 'c', displayName: 'ゆうと', rankPoints: 300);

      final notifier = PlayerSearchNotifier(firestore: firestore);
      await pumpEventQueue();

      await notifier.searchPlayers('さ');

      expect(notifier.state.isLoading, isFalse);
      expect(notifier.state.error, isNull);
      expect(notifier.state.results, hasLength(2));
      expect(notifier.state.results.map((p) => p.name), containsAll(['さくら', 'さとし']));
      final sakura = notifier.state.results.firstWhere((p) => p.name == 'さくら');
      expect(sakura.totalWins, 5);
      expect(sakura.totalLosses, 2);
    });

    test('searchPlayers with an empty query clears the results', () async {
      await _seedProfile(firestore, 'a', displayName: 'さくら', rankPoints: 100);
      final notifier = PlayerSearchNotifier(firestore: firestore);
      await pumpEventQueue();

      await notifier.searchPlayers('さ');
      expect(notifier.state.results, isNotEmpty);

      await notifier.searchPlayers('   ');
      expect(notifier.state.results, isEmpty);
      expect(notifier.state.query, isEmpty);
    });

    test('clearSearch resets query, results and error', () async {
      await _seedProfile(firestore, 'a', displayName: 'さくら', rankPoints: 100);
      final notifier = PlayerSearchNotifier(firestore: firestore);
      await pumpEventQueue();

      await notifier.searchPlayers('さ');
      notifier.clearSearch();

      expect(notifier.state.query, isEmpty);
      expect(notifier.state.results, isEmpty);
      expect(notifier.state.error, isNull);
    });

    test('addToRecentlyViewed dedupes, orders most-recent-first, and caps at 10', () async {
      final notifier = PlayerSearchNotifier(firestore: firestore);
      await pumpEventQueue();

      for (var i = 0; i < 11; i++) {
        notifier.addToRecentlyViewed(SearchablePlayer(
          id: 'p$i',
          name: 'player$i',
          avatarEmoji: '👤',
          rating: 100,
          totalWins: 0,
          totalLosses: 0,
          totalDraws: 0,
          seasonalTier: 'ブロンズ',
          lastActiveDate: DateTime.now(),
        ));
      }
      // Re-view p5 -- should move to front, not duplicate.
      notifier.addToRecentlyViewed(SearchablePlayer(
        id: 'p5',
        name: 'player5',
        avatarEmoji: '👤',
        rating: 100,
        totalWins: 0,
        totalLosses: 0,
        totalDraws: 0,
        seasonalTier: 'ブロンズ',
        lastActiveDate: DateTime.now(),
      ));

      expect(notifier.state.recentlyViewed, hasLength(10));
      expect(notifier.state.recentlyViewed.first.id, 'p5');
      expect(notifier.state.recentlyViewed.where((p) => p.id == 'p5'), hasLength(1));
    });

    test('clearRecentlyViewed empties the list', () async {
      final notifier = PlayerSearchNotifier(firestore: firestore);
      await pumpEventQueue();

      notifier.addToRecentlyViewed(SearchablePlayer(
        id: 'p1',
        name: 'player1',
        avatarEmoji: '👤',
        rating: 100,
        totalWins: 0,
        totalLosses: 0,
        totalDraws: 0,
        seasonalTier: 'ブロンズ',
        lastActiveDate: DateTime.now(),
      ));
      notifier.clearRecentlyViewed();

      expect(notifier.state.recentlyViewed, isEmpty);
    });

    test('getSuggestedPlayers excludes recently-viewed players', () async {
      await _seedProfile(firestore, 'a', displayName: 'あかり', rankPoints: 100);
      await _seedProfile(firestore, 'b', displayName: 'ゆうと', rankPoints: 300);
      final notifier = PlayerSearchNotifier(firestore: firestore);
      await pumpEventQueue();

      notifier.addToRecentlyViewed(notifier.state.topPlayers.first);

      final suggested = notifier.getSuggestedPlayers();
      expect(suggested.any((p) => p.id == notifier.state.topPlayers.first.id), isFalse);
    });

    test('getRandomPlayers returns players drawn from the real top players', () async {
      await _seedProfile(firestore, 'a', displayName: 'あかり', rankPoints: 100);
      await _seedProfile(firestore, 'b', displayName: 'ゆうと', rankPoints: 300);
      final notifier = PlayerSearchNotifier(firestore: firestore);
      await pumpEventQueue();

      final random = notifier.getRandomPlayers(count: 5);

      expect(random.length, lessThanOrEqualTo(2));
      for (final player in random) {
        expect(notifier.state.topPlayers.map((p) => p.id), contains(player.id));
      }
    });

    test('derived SearchablePlayer fields compute correctly', () {
      final player = SearchablePlayer(
        id: 'a',
        name: 'test',
        avatarEmoji: '👤',
        rating: 2800,
        totalWins: 7,
        totalLosses: 2,
        totalDraws: 1,
        seasonalTier: 'マスター',
        lastActiveDate: DateTime.now(),
      );

      expect(player.totalGames, 10);
      expect(player.winRate, 0.7);
      expect(player.isActive, isTrue);
    });
  });
}
