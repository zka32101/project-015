import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:reversia/providers/leaderboard_provider.dart';

LeaderboardNotifier _buildNotifier(FakeFirebaseFirestore firestore, {String? uid}) {
  final auth = uid == null
      ? MockFirebaseAuth(signedIn: false)
      : MockFirebaseAuth(mockUser: MockUser(uid: uid), signedIn: true);
  return LeaderboardNotifier(firestore: firestore, auth: auth);
}

Future<void> _seedProfile(
  FakeFirebaseFirestore firestore,
  String uid, {
  required String displayName,
  required int rankPoints,
  int wins = 0,
  int totalGames = 0,
  int winStreak = 0,
}) {
  return firestore.collection('publicProfiles').doc(uid).set({
    'displayName': displayName,
    'rankPoints': rankPoints,
    'wins': wins,
    'totalGames': totalGames,
    'winStreak': winStreak,
    'updatedAt': Timestamp.now(),
  });
}

void main() {
  group('LeaderboardNotifier', () {
    late FakeFirebaseFirestore firestore;

    setUp(() {
      firestore = FakeFirebaseFirestore();
    });

    test('starts loading, then reflects real public profiles sorted by rankPoints', () async {
      await _seedProfile(firestore, 'a', displayName: 'あかり', rankPoints: 100);
      await _seedProfile(firestore, 'b', displayName: 'ゆうと', rankPoints: 300);
      await _seedProfile(firestore, 'c', displayName: 'さくら', rankPoints: 200);

      final notifier = _buildNotifier(firestore);
      await pumpEventQueue();

      expect(notifier.state.isLoading, isFalse);
      expect(notifier.state.entries, hasLength(3));
      expect(notifier.state.entries[0].playerName, 'ゆうと');
      expect(notifier.state.entries[0].rank, 1);
      expect(notifier.state.entries[1].playerName, 'さくら');
      expect(notifier.state.entries[1].rank, 2);
      expect(notifier.state.entries[2].playerName, 'あかり');
      expect(notifier.state.entries[2].rank, 3);
    });

    test('finds the signed-in player\'s own rank and entry', () async {
      await _seedProfile(firestore, 'a', displayName: 'あかり', rankPoints: 100);
      await _seedProfile(
        firestore,
        'me',
        displayName: 'あなた',
        rankPoints: 250,
        wins: 5,
        totalGames: 8,
        winStreak: 2,
      );

      final notifier = _buildNotifier(firestore, uid: 'me');
      await pumpEventQueue();

      expect(notifier.state.playerRank, 1);
      expect(notifier.state.playerEntry, isNotNull);
      expect(notifier.state.playerEntry!.playerName, 'あなた');
      expect(notifier.state.playerEntry!.winRate, 5 / 8);
    });

    test('playerRank/playerEntry stay null when signed out or not on the board', () async {
      await _seedProfile(firestore, 'a', displayName: 'あかり', rankPoints: 100);

      final signedOut = _buildNotifier(firestore);
      await pumpEventQueue();
      expect(signedOut.state.playerRank, isNull);
      expect(signedOut.state.playerEntry, isNull);

      final notYetSynced = _buildNotifier(firestore, uid: 'nobody-yet');
      await pumpEventQueue();
      expect(notYetSynced.state.playerRank, isNull);
      expect(notYetSynced.state.playerEntry, isNull);
    });

    test('has no entries when nobody has ever synced', () async {
      final notifier = _buildNotifier(firestore);
      await pumpEventQueue();

      expect(notifier.state.isLoading, isFalse);
      expect(notifier.state.entries, isEmpty);
    });

    test('setPeriod only relabels the period -- entries stay the real all-time ranking', () async {
      await _seedProfile(firestore, 'a', displayName: 'あかり', rankPoints: 100);
      final notifier = _buildNotifier(firestore);
      await pumpEventQueue();

      notifier.setPeriod(LeaderboardPeriod.thisWeek);

      expect(notifier.state.period, LeaderboardPeriod.thisWeek);
      expect(notifier.state.entries, hasLength(1));
    });
  });
}
