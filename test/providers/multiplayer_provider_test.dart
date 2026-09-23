import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:reversia/providers/multiplayer_provider.dart';

MultiplayerNotifier _buildNotifier(
  FakeFirebaseFirestore firestore,
  String uid,
) {
  final auth = MockFirebaseAuth(
    mockUser: MockUser(uid: uid),
    signedIn: true,
  );
  return MultiplayerNotifier(firestore: firestore, auth: auth);
}

Future<void> _hostSampleLobby(MultiplayerNotifier host) {
  return host.hostLobby(
    hostName: 'ホスト太郎',
    hostAvatarEmoji: '🦅',
    hostRating: 1800,
    gameMode: 'ランク戦',
    timeLimit: 10,
    isRanked: true,
  );
}

void main() {
  group('MultiplayerNotifier', () {
    late FakeFirebaseFirestore firestore;

    setUp(() {
      firestore = FakeFirebaseFirestore();
    });

    test('initial state starts empty until Firestore has lobbies/history', () async {
      final notifier = _buildNotifier(firestore, 'me');
      await pumpEventQueue();

      expect(notifier.state.availableLobbies, isEmpty);
      expect(notifier.state.matchHistory, isEmpty);
      expect(notifier.state.currentMatch, isNull);
    });

    test('hostLobby creates a lobby that shows up in availableLobbies', () async {
      final notifier = _buildNotifier(firestore, 'host');
      await pumpEventQueue();

      await _hostSampleLobby(notifier);
      await pumpEventQueue();

      expect(notifier.state.availableLobbies, hasLength(1));
      expect(notifier.state.availableLobbies.first.hostName, 'ホスト太郎');
      expect(notifier.state.availableLobbies.first.isFull, isFalse);
    });

    test('joinLobby starts a match and removes the lobby from the open list', () async {
      final host = _buildNotifier(firestore, 'host');
      await pumpEventQueue();
      await _hostSampleLobby(host);
      await pumpEventQueue();
      final lobbyId = host.state.availableLobbies.first.id;

      final joiner = _buildNotifier(firestore, 'joiner');
      await pumpEventQueue();
      await joiner.joinLobby(
        lobbyId,
        playerName: '参加者花子',
        playerAvatarEmoji: '🌸',
        playerRating: 1600,
      );
      await pumpEventQueue();

      expect(joiner.state.error, isNull);
      expect(joiner.state.currentMatch, isNotNull);
      expect(joiner.state.currentMatch!.player1Name, 'ホスト太郎');
      expect(joiner.state.currentMatch!.player2Name, '参加者花子');
      // Reversia starts each side with 9 pieces, not Othello's 2.
      expect(joiner.state.currentMatch!.player1Pieces, 9);
      expect(joiner.state.currentMatch!.player2Pieces, 9);
      expect(host.state.availableLobbies, isEmpty);
    });

    test('joinLobby with an unknown lobby id surfaces an error instead of throwing', () async {
      final notifier = _buildNotifier(firestore, 'me');
      await pumpEventQueue();

      await notifier.joinLobby('does_not_exist');
      await pumpEventQueue();

      expect(notifier.state.isLoading, isFalse);
      expect(notifier.state.currentMatch, isNull);
      expect(notifier.state.error, isNotNull);
    });

    test('joinLobby refuses to let the host join their own lobby', () async {
      final notifier = _buildNotifier(firestore, 'host');
      await pumpEventQueue();
      await _hostSampleLobby(notifier);
      await pumpEventQueue();
      final lobbyId = notifier.state.availableLobbies.first.id;

      await notifier.joinLobby(lobbyId);
      await pumpEventQueue();

      expect(notifier.state.currentMatch, isNull);
      expect(notifier.state.error, isNotNull);
    });

    test('startQuickMatch pairs two waiting players together', () async {
      final playerA = _buildNotifier(firestore, 'a');
      await pumpEventQueue();
      final playerB = _buildNotifier(firestore, 'b');
      await pumpEventQueue();

      await playerA.startQuickMatch(playerName: 'プレイヤーA');
      await pumpEventQueue();
      expect(playerA.state.currentMatch, isNull);
      expect(playerA.state.isSearchingForMatch, isTrue);

      await playerB.startQuickMatch(playerName: 'プレイヤーB');
      await pumpEventQueue();

      expect(playerB.state.currentMatch, isNotNull);
      expect(playerB.state.isSearchingForMatch, isFalse);

      // Player A is still listening to their own queue document, which
      // player B's claim should have updated with the new matchId.
      await pumpEventQueue();
      expect(playerA.state.currentMatch, isNotNull);
      expect(playerA.state.isSearchingForMatch, isFalse);
    });

    test('updateMatchState writes moveCount/turn/pieces through to Firestore', () async {
      final host = _buildNotifier(firestore, 'host');
      await pumpEventQueue();
      await _hostSampleLobby(host);
      await pumpEventQueue();
      final lobbyId = host.state.availableLobbies.first.id;

      final joiner = _buildNotifier(firestore, 'joiner');
      await pumpEventQueue();
      await joiner.joinLobby(lobbyId, playerName: '参加者花子');
      await pumpEventQueue();

      await joiner.updateMatchState(
        moveCount: 5,
        currentTurn: 'player2',
        player1Pieces: 8,
        player2Pieces: 7,
      );
      await pumpEventQueue();

      expect(joiner.state.currentMatch!.moveCount, 5);
      expect(joiner.state.currentMatch!.currentTurn, 'player2');
      expect(joiner.state.currentMatch!.player1Pieces, 8);
      expect(joiner.state.currentMatch!.player2Pieces, 7);
    });

    test('updateMatchState is a no-op when there is no current match', () async {
      final notifier = _buildNotifier(firestore, 'me');
      await pumpEventQueue();

      await notifier.updateMatchState(
        moveCount: 1,
        currentTurn: 'player1',
        player1Pieces: 9,
        player2Pieces: 9,
      );

      expect(notifier.state.currentMatch, isNull);
    });

    test('endMatch clears currentMatch and the finished match reaches matchHistory', () async {
      final host = _buildNotifier(firestore, 'host');
      await pumpEventQueue();
      await _hostSampleLobby(host);
      await pumpEventQueue();
      final lobbyId = host.state.availableLobbies.first.id;

      final joiner = _buildNotifier(firestore, 'joiner');
      await pumpEventQueue();
      await joiner.joinLobby(lobbyId, playerName: '参加者花子');
      await pumpEventQueue();

      await joiner.endMatch(
        winner: '参加者花子',
        winnerRatingGain: 20,
        loserRatingLoss: 20,
      );
      await pumpEventQueue();

      expect(joiner.state.currentMatch, isNull);
      expect(joiner.state.matchHistory, hasLength(1));
      expect(joiner.state.matchHistory.first.winner, '参加者花子');
    });

    test('endMatch is a no-op when there is no current match', () async {
      final notifier = _buildNotifier(firestore, 'me');
      await pumpEventQueue();
      final historyLengthBefore = notifier.state.matchHistory.length;

      await notifier.endMatch(
        winner: 'あなた',
        winnerRatingGain: 10,
        loserRatingLoss: 10,
      );

      expect(notifier.state.matchHistory.length, historyLengthBefore);
    });

    test('exitMatch clears currentMatch without touching history', () async {
      final host = _buildNotifier(firestore, 'host');
      await pumpEventQueue();
      await _hostSampleLobby(host);
      await pumpEventQueue();
      final lobbyId = host.state.availableLobbies.first.id;

      final joiner = _buildNotifier(firestore, 'joiner');
      await pumpEventQueue();
      await joiner.joinLobby(lobbyId, playerName: '参加者花子');
      await pumpEventQueue();
      expect(joiner.state.currentMatch, isNotNull);

      final historyLengthBefore = joiner.state.matchHistory.length;
      joiner.exitMatch();

      expect(joiner.state.currentMatch, isNull);
      expect(joiner.state.matchHistory.length, historyLengthBefore);
    });

    test('clearError resets a previously set error', () async {
      final notifier = _buildNotifier(firestore, 'me');
      await pumpEventQueue();

      await notifier.joinLobby('does_not_exist');
      await pumpEventQueue();
      expect(notifier.state.error, isNotNull);

      notifier.clearError();
      expect(notifier.state.error, isNull);
    });
  });
}
