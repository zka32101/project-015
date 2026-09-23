import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:reversia/providers/multiplayer_provider.dart';
import 'package:reversia/screens/online_game_screen.dart';

MultiplayerNotifier _buildNotifier(FakeFirebaseFirestore firestore, String uid) {
  final auth = MockFirebaseAuth(mockUser: MockUser(uid: uid), signedIn: true);
  return MultiplayerNotifier(firestore: firestore, auth: auth);
}

void main() {
  testWidgets(
      'tapping own piece then a legal destination moves it and syncs the turn to Firestore',
      (tester) async {
    final firestore = FakeFirebaseFirestore();
    final host = _buildNotifier(firestore, 'host');
    await pumpEventQueue();
    await host.hostLobby(
      hostName: 'ホスト太郎',
      hostAvatarEmoji: '🦅',
      hostRating: 1800,
      gameMode: 'ランク戦',
      timeLimit: 10,
      isRanked: true,
    );
    await pumpEventQueue();
    final lobbyId = host.state.availableLobbies.first.id;

    final joiner = _buildNotifier(firestore, 'joiner');
    await pumpEventQueue();
    await joiner.joinLobby(lobbyId, playerName: '参加者花子');
    await pumpEventQueue();
    // hostLobby's _watchOwnLobby is what gets the host into the match too.
    expect(host.state.currentMatch, isNotNull);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [multiplayerProvider.overrideWith((ref) => host)],
        child: const MaterialApp(home: OnlineGameScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('あなたの番です'), findsOneWidget);

    // Board.initial(): (0,0) is one of playerA's row-0 pieces; its only
    // legal move is straight down to the empty (1,0) -- see
    // Board.initial()'s layout (row 1 only has pieces at cols 1-3).
    await tester.tap(find.byKey(const Key('online_cell_0_0')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('online_cell_1_0')));
    await tester.pumpAndSettle();
    await pumpEventQueue();
    await tester.pumpAndSettle();

    expect(host.state.currentMatch!.moves, ['a1a2']);
    expect(host.state.currentMatch!.currentTurn, 'player2');
    expect(find.text('相手の番です'), findsOneWidget);
  });
}
