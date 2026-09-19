import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:reversia/providers/player_search_provider.dart';

void main() {
  group('PlayerSearchNotifier', () {
    late ProviderContainer container;

    setUp(() {
      container = ProviderContainer();
    });

    tearDown(() {
      container.dispose();
    });

    test('initial state has no query, no results, no recently viewed', () {
      final state = container.read(playerSearchProvider);
      expect(state.query, isEmpty);
      expect(state.results, isEmpty);
      expect(state.recentlyViewed, isEmpty);
      expect(state.isLoading, isFalse);
      expect(state.error, isNull);
    });

    test('searchPlayers with empty query resets results', () async {
      final notifier = container.read(playerSearchProvider.notifier);
      await notifier.searchPlayers('太郎');
      expect(container.read(playerSearchProvider).results, isNotEmpty);

      await notifier.searchPlayers('');
      final state = container.read(playerSearchProvider);
      expect(state.query, isEmpty);
      expect(state.results, isEmpty);
    });

    test('searchPlayers matches by name substring', () async {
      final notifier = container.read(playerSearchProvider.notifier);
      await notifier.searchPlayers('太郎');

      final state = container.read(playerSearchProvider);
      expect(state.isLoading, isFalse);
      expect(state.results, hasLength(1));
      expect(state.results.single.name, 'エリート太郎');
    });

    test('searchPlayers matches by id', () async {
      final notifier = container.read(playerSearchProvider.notifier);
      await notifier.searchPlayers('player_2');

      final state = container.read(playerSearchProvider);
      expect(state.results, hasLength(1));
      expect(state.results.single.id, 'player_2');
    });

    test('searchPlayers with no match returns empty results, not loading', () async {
      final notifier = container.read(playerSearchProvider.notifier);
      await notifier.searchPlayers('存在しないプレイヤー名前です');

      final state = container.read(playerSearchProvider);
      expect(state.results, isEmpty);
      expect(state.isLoading, isFalse);
    });

    test('clearSearch resets query, results and error', () async {
      final notifier = container.read(playerSearchProvider.notifier);
      await notifier.searchPlayers('太郎');

      notifier.clearSearch();
      final state = container.read(playerSearchProvider);
      expect(state.query, isEmpty);
      expect(state.results, isEmpty);
      expect(state.error, isNull);
    });

    test('addToRecentlyViewed inserts at the front and dedupes by id', () {
      final notifier = container.read(playerSearchProvider.notifier);
      final players = notifier.getRandomPlayers(count: 2);

      notifier.addToRecentlyViewed(players[0]);
      notifier.addToRecentlyViewed(players[1]);
      // Re-adding the first player should move it back to the front, not
      // duplicate it.
      notifier.addToRecentlyViewed(players[0]);

      final recentlyViewed = container.read(playerSearchProvider).recentlyViewed;
      expect(recentlyViewed, hasLength(2));
      expect(recentlyViewed.first.id, players[0].id);
    });

    test('addToRecentlyViewed caps the list at 10 entries, evicting the oldest', () {
      final notifier = container.read(playerSearchProvider.notifier);
      for (var i = 0; i < 11; i++) {
        notifier.addToRecentlyViewed(SearchablePlayer(
          id: 'synthetic_$i',
          name: 'Synthetic $i',
          avatarEmoji: '🙂',
          rating: 1000 + i,
          totalWins: 0,
          totalLosses: 0,
          totalDraws: 0,
          seasonalTier: 'ブロンズ',
          lastActiveDate: DateTime.now(),
        ));
      }

      final recentlyViewed = container.read(playerSearchProvider).recentlyViewed;
      expect(recentlyViewed, hasLength(10));
      expect(recentlyViewed.first.id, 'synthetic_10');
      expect(recentlyViewed.any((p) => p.id == 'synthetic_0'), isFalse);
    });

    test('clearRecentlyViewed empties the list', () {
      final notifier = container.read(playerSearchProvider.notifier);
      final players = notifier.getRandomPlayers(count: 2);
      for (final p in players) {
        notifier.addToRecentlyViewed(p);
      }
      expect(container.read(playerSearchProvider).recentlyViewed, isNotEmpty);

      notifier.clearRecentlyViewed();
      expect(container.read(playerSearchProvider).recentlyViewed, isEmpty);
    });

    test(
        'getSuggestedPlayers excludes recently viewed and returns at most 5, '
        'sorted by rating descending', () {
      final notifier = container.read(playerSearchProvider.notifier);
      final all = notifier.getRandomPlayers(count: 8);
      final topRated = [...all]..sort((a, b) => b.rating.compareTo(a.rating));
      notifier.addToRecentlyViewed(topRated.first);

      final suggested = notifier.getSuggestedPlayers();

      expect(suggested.length, lessThanOrEqualTo(5));
      expect(suggested.any((p) => p.id == topRated.first.id), isFalse);
      for (var i = 1; i < suggested.length; i++) {
        expect(suggested[i - 1].rating, greaterThanOrEqualTo(suggested[i].rating));
      }
    });
  });
}
