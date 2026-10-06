import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:reversia/providers/friends_provider.dart';

FriendsNotifier _buildNotifier(
  FakeFirebaseFirestore firestore,
  String uid, {
  String? displayName,
}) {
  final auth = MockFirebaseAuth(
    mockUser: MockUser(uid: uid, displayName: displayName),
    signedIn: true,
  );
  return FriendsNotifier(firestore: firestore, auth: auth);
}

Future<void> _seedProfile(
  FakeFirebaseFirestore firestore,
  String uid, {
  required String displayName,
  int rankPoints = 0,
}) {
  return firestore.collection('publicProfiles').doc(uid).set({
    'displayName': displayName,
    'rankPoints': rankPoints,
    'wins': 0,
    'losses': 0,
    'draws': 0,
    'updatedAt': Timestamp.now(),
  });
}

void main() {
  group('FriendsNotifier', () {
    late FakeFirebaseFirestore firestore;

    setUp(() {
      firestore = FakeFirebaseFirestore();
      SharedPreferences.setMockInitialValues({});
    });

    test('sendFriendRequest creates a pending request for a real player', () async {
      await _seedProfile(firestore, 'them', displayName: 'あかり', rankPoints: 200);
      final me = _buildNotifier(firestore, 'me', displayName: 'わたし');
      await pumpEventQueue();

      await me.sendFriendRequest('あかり');

      expect(me.state.error, isNull);
      final requests = await firestore.collection('friendRequests').get();
      expect(requests.docs, hasLength(1));
      expect(requests.docs.first.data()['from'], 'me');
      expect(requests.docs.first.data()['to'], 'them');
      expect(requests.docs.first.data()['status'], 'pending');
    });

    test('sendFriendRequest fails when no player has that name', () async {
      final me = _buildNotifier(firestore, 'me');
      await pumpEventQueue();

      await me.sendFriendRequest('存在しない名前');

      expect(me.state.error, isNotNull);
      final requests = await firestore.collection('friendRequests').get();
      expect(requests.docs, isEmpty);
    });

    test('sendFriendRequest refuses to friend yourself', () async {
      await _seedProfile(firestore, 'me', displayName: 'わたし');
      final me = _buildNotifier(firestore, 'me', displayName: 'わたし');
      await pumpEventQueue();

      await me.sendFriendRequest('わたし');

      expect(me.state.error, isNotNull);
    });

    test('sendFriendRequest refuses a duplicate pending request', () async {
      await _seedProfile(firestore, 'them', displayName: 'あかり');
      final me = _buildNotifier(firestore, 'me');
      await pumpEventQueue();

      await me.sendFriendRequest('あかり');
      await me.sendFriendRequest('あかり');

      final requests = await firestore.collection('friendRequests').get();
      expect(requests.docs, hasLength(1));
    });

    test('the recipient sees the request as incoming, the sender as outgoing', () async {
      await _seedProfile(firestore, 'them', displayName: 'あかり', rankPoints: 300);
      final me = _buildNotifier(firestore, 'me', displayName: 'わたし');
      final them = _buildNotifier(firestore, 'them', displayName: 'あかり');
      await pumpEventQueue();

      await me.sendFriendRequest('あかり');
      await pumpEventQueue();

      expect(me.state.friendRequests, hasLength(1));
      expect(me.state.friendRequests.first.direction, FriendRequestDirection.outgoing);
      expect(them.state.friendRequests, hasLength(1));
      expect(them.state.friendRequests.first.direction, FriendRequestDirection.incoming);
      expect(them.state.friendRequests.first.name, 'わたし');
      expect(them.state.incomingRequestCount, 1);
    });

    test('accepting completes the handshake on both sides and cleans up the request', () async {
      await _seedProfile(firestore, 'them', displayName: 'あかり', rankPoints: 300);
      await _seedProfile(firestore, 'me', displayName: 'わたし', rankPoints: 150);
      final me = _buildNotifier(firestore, 'me', displayName: 'わたし');
      final them = _buildNotifier(firestore, 'them', displayName: 'あかり');
      await pumpEventQueue();

      await me.sendFriendRequest('あかり');
      await pumpEventQueue();

      await them.acceptRequest(them.state.friendRequests.first);
      await pumpEventQueue();
      await pumpEventQueue();

      expect(them.state.friends, hasLength(1));
      expect(them.state.friends.first.id, 'me');
      expect(them.state.friends.first.name, 'わたし');

      expect(me.state.friends, hasLength(1));
      expect(me.state.friends.first.id, 'them');
      expect(me.state.friends.first.name, 'あかり');

      // Both sides are done with the request; it's cleaned up, not stuck
      // around as a stale 'accepted' document.
      final remaining = await firestore.collection('friendRequests').get();
      expect(remaining.docs, isEmpty);
      expect(me.state.friendRequests, isEmpty);
      expect(them.state.friendRequests, isEmpty);
    });

    test('declining deletes the request without creating a friendship', () async {
      await _seedProfile(firestore, 'them', displayName: 'あかり');
      final me = _buildNotifier(firestore, 'me');
      final them = _buildNotifier(firestore, 'them');
      await pumpEventQueue();

      await me.sendFriendRequest('あかり');
      await pumpEventQueue();

      await them.declineRequest(them.state.friendRequests.first);
      await pumpEventQueue();

      expect(them.state.friends, isEmpty);
      expect(me.state.friends, isEmpty);
      expect(me.state.friendRequests, isEmpty);
      expect(them.state.friendRequests, isEmpty);
    });

    test('toggleFavorite flips and persists the favorite flag locally', () async {
      await firestore.collection('friends').doc('me').collection('list').doc('f1').set({
        'displayName': 'あかり',
        'rankPoints': 100,
        'addedAt': Timestamp.now(),
      });
      final me = _buildNotifier(firestore, 'me');
      await pumpEventQueue();

      expect(me.state.friends.single.isFavorite, isFalse);

      await me.toggleFavorite('f1');
      expect(me.state.friends.single.isFavorite, isTrue);

      await me.toggleFavorite('f1');
      expect(me.state.friends.single.isFavorite, isFalse);
    });

    test('removeFriend deletes only the caller\'s own friend-list entry', () async {
      await firestore.collection('friends').doc('me').collection('list').doc('f1').set({
        'displayName': 'あかり',
        'rankPoints': 100,
        'addedAt': Timestamp.now(),
      });
      final me = _buildNotifier(firestore, 'me');
      await pumpEventQueue();
      expect(me.state.friends, hasLength(1));

      await me.removeFriend('f1');
      await pumpEventQueue();

      expect(me.state.friends, isEmpty);
    });

    test('clearError resets a previously set error', () async {
      final me = _buildNotifier(firestore, 'me');
      await me.sendFriendRequest('いない人');
      expect(me.state.error, isNotNull);

      me.clearError();

      expect(me.state.error, isNull);
    });
  });
}
