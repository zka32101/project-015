import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:reversia/providers/multiplayer_provider.dart';

void main() {
  group('MultiplayerNotifier', () {
    late ProviderContainer container;

    setUp(() {
      container = ProviderContainer();
    });

    tearDown(() {
      container.dispose();
    });

    test('initial state has sample lobbies, match history and an online count', () {
      final state = container.read(multiplayerProvider);
      expect(state.availableLobbies, isNotEmpty);
      expect(state.matchHistory, isNotEmpty);
      expect(state.currentMatch, isNull);
      expect(state.onlinePlayersCount, inInclusiveRange(15, 49));
    });

    test('joinLobby with a valid lobby id starts a match against its host', () async {
      final notifier = container.read(multiplayerProvider.notifier);
      final lobby = container.read(multiplayerProvider).availableLobbies.first;

      await notifier.joinLobby(lobby.id);

      final state = container.read(multiplayerProvider);
      expect(state.isLoading, isFalse);
      expect(state.error, isNull);
      expect(state.currentMatch, isNotNull);
      expect(state.currentMatch!.player1Name, lobby.hostName);
    });

    test('joinLobby with an unknown lobby id surfaces an error instead of throwing', () async {
      final notifier = container.read(multiplayerProvider.notifier);

      await notifier.joinLobby('does_not_exist');

      final state = container.read(multiplayerProvider);
      expect(state.isLoading, isFalse);
      expect(state.currentMatch, isNull);
      expect(state.error, isNotNull);
    });

    test('endMatch actually clears currentMatch and appends a result to history', () async {
      final notifier = container.read(multiplayerProvider.notifier);
      final lobby = container.read(multiplayerProvider).availableLobbies.first;
      await notifier.joinLobby(lobby.id);
      expect(container.read(multiplayerProvider).currentMatch, isNotNull);

      final historyLengthBefore = container.read(multiplayerProvider).matchHistory.length;
      await notifier.endMatch(winner: 'あなた', winnerRatingGain: 20, loserRatingLoss: 20);

      final state = container.read(multiplayerProvider);
      expect(state.currentMatch, isNull);
      expect(state.matchHistory.length, historyLengthBefore + 1);
      expect(state.matchHistory.first.winner, 'あなた');
    });

    test('endMatch is a no-op when there is no current match', () async {
      final notifier = container.read(multiplayerProvider.notifier);
      final historyLengthBefore = container.read(multiplayerProvider).matchHistory.length;

      await notifier.endMatch(winner: 'あなた', winnerRatingGain: 10, loserRatingLoss: 10);

      expect(container.read(multiplayerProvider).matchHistory.length, historyLengthBefore);
    });

    test('exitMatch actually clears currentMatch without touching history', () async {
      final notifier = container.read(multiplayerProvider.notifier);
      final lobby = container.read(multiplayerProvider).availableLobbies.first;
      await notifier.joinLobby(lobby.id);
      expect(container.read(multiplayerProvider).currentMatch, isNotNull);

      final historyLengthBefore = container.read(multiplayerProvider).matchHistory.length;
      notifier.exitMatch();

      final state = container.read(multiplayerProvider);
      expect(state.currentMatch, isNull);
      expect(state.matchHistory.length, historyLengthBefore);
    });

    test('updateMatchState updates the ongoing match fields', () async {
      final notifier = container.read(multiplayerProvider.notifier);
      final lobby = container.read(multiplayerProvider).availableLobbies.first;
      await notifier.joinLobby(lobby.id);

      notifier.updateMatchState(
        moveCount: 12,
        currentTurn: 'player2',
        player1Pieces: 20,
        player2Pieces: 44,
      );

      final match = container.read(multiplayerProvider).currentMatch!;
      expect(match.moveCount, 12);
      expect(match.currentTurn, 'player2');
      expect(match.player1Pieces, 20);
      expect(match.player2Pieces, 44);
    });

    test('updateMatchState is a no-op when there is no current match', () {
      final notifier = container.read(multiplayerProvider.notifier);
      notifier.updateMatchState(
        moveCount: 1,
        currentTurn: 'player1',
        player1Pieces: 2,
        player2Pieces: 2,
      );
      expect(container.read(multiplayerProvider).currentMatch, isNull);
    });

    test('clearError resets a previously set error', () async {
      final notifier = container.read(multiplayerProvider.notifier);
      await notifier.joinLobby('does_not_exist');
      expect(container.read(multiplayerProvider).error, isNotNull);

      notifier.clearError();
      expect(container.read(multiplayerProvider).error, isNull);
    });
  });
}
