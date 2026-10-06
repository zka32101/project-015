import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Direction of a pending friend request relative to the signed-in player.
enum FriendRequestDirection { incoming, outgoing }

/// A real friend, backed by `friends/{uid}/list/{friendUid}` (see
/// firestore.rules). [rating] is a snapshot of the friend's rankPoints from
/// when the friendship was formed -- it doesn't update live, since keeping
/// it current would mean a separate publicProfiles subscription per friend.
/// [isFavorite] is a purely local, per-device preference (not synced).
class Friend {
  final String id;
  final String name;
  final int rating;
  final DateTime addedDate;
  final bool isFavorite;

  const Friend({
    required this.id,
    required this.name,
    required this.rating,
    required this.addedDate,
    this.isFavorite = false,
  });

  Friend copyWith({bool? isFavorite}) => Friend(
        id: id,
        name: name,
        rating: rating,
        addedDate: addedDate,
        isFavorite: isFavorite ?? this.isFavorite,
      );
}

/// A pending friend request, backed by `friendRequests/{requestId}`.
class FriendRequest {
  final String id;
  final String otherUid;
  final String name;
  final int rating;
  final FriendRequestDirection direction;
  final DateTime requestedDate;

  const FriendRequest({
    required this.id,
    required this.otherUid,
    required this.name,
    required this.rating,
    required this.direction,
    required this.requestedDate,
  });
}

class FriendsState {
  final List<Friend> friends;
  final List<FriendRequest> friendRequests;
  final bool isLoading;
  final String? error;

  const FriendsState({
    required this.friends,
    required this.friendRequests,
    this.isLoading = false,
    this.error,
  });

  int get incomingRequestCount => friendRequests
      .where((r) => r.direction == FriendRequestDirection.incoming)
      .length;

  FriendsState copyWith({
    List<Friend>? friends,
    List<FriendRequest>? friendRequests,
    bool? isLoading,
    Object? error = _unset,
  }) {
    return FriendsState(
      friends: friends ?? this.friends,
      friendRequests: friendRequests ?? this.friendRequests,
      isLoading: isLoading ?? this.isLoading,
      error: identical(error, _unset) ? this.error : error as String?,
    );
  }
}

const Object _unset = Object();

/// Real friends: a request/accept flow plus a mutual friend list, backed by
/// `friendRequests/{requestId}` and `friends/{uid}/list/{friendUid}`.
///
/// Deliberately scoped down from the old sample data's feature set -- no
/// live online/away/in-game presence, no per-friend match history, no
/// activity feed, no challenges. Those all need either a presence system
/// or per-pair match history this client-only design doesn't have.
///
/// Accepting is a two-step handshake, since neither side can write into
/// the other's friend list (see firestore.rules): the recipient flips the
/// request's `status` to `accepted` and writes their own
/// `friends/{me}/list/{sender}` entry; the sender's client is watching its
/// own outgoing requests, notices the flip, writes
/// `friends/{me}/list/{recipient}`, and deletes the now-fully-claimed
/// request document.
class FriendsNotifier extends StateNotifier<FriendsState> {
  static const String _publicProfileCollection = 'publicProfiles';
  static const String _requestsCollection = 'friendRequests';
  static const String _friendsCollection = 'friends';
  static const String _favoritesPrefsKey = 'friends_favorite_ids';

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  SharedPreferences? _prefs;
  Set<String> _favoriteIds = {};
  List<Friend> _friends = [];
  List<FriendRequest> _incoming = [];
  List<FriendRequest> _outgoingPending = [];
  final Set<String> _claiming = {};

  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _friendsSub;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _incomingSub;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _outgoingSub;

  FriendsNotifier({FirebaseFirestore? firestore, FirebaseAuth? auth})
      : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance,
        super(const FriendsState(friends: [], friendRequests: [])) {
    _loadFavorites();
    _watchAll();
  }

  Future<void> _loadFavorites() async {
    final prefs = _prefs ??= await SharedPreferences.getInstance();
    _favoriteIds = (prefs.getStringList(_favoritesPrefsKey) ?? const []).toSet();
    _applyFriends();
  }

  void _watchAll() {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;

    _friendsSub = _firestore
        .collection(_friendsCollection)
        .doc(uid)
        .collection('list')
        .snapshots()
        .listen((snapshot) {
      _friends = snapshot.docs.map((doc) {
        final data = doc.data();
        return Friend(
          id: doc.id,
          name: data['displayName'] as String? ?? '名無しさん',
          rating: data['rankPoints'] as int? ?? 0,
          addedDate: (data['addedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
        );
      }).toList();
      _applyFriends();
    });

    _incomingSub = _firestore
        .collection(_requestsCollection)
        .where('to', isEqualTo: uid)
        .where('status', isEqualTo: 'pending')
        .snapshots()
        .listen((snapshot) {
      _incoming = snapshot.docs.map((doc) {
        final data = doc.data();
        return FriendRequest(
          id: doc.id,
          otherUid: data['from'] as String,
          name: data['fromDisplayName'] as String? ?? '名無しさん',
          rating: data['fromRating'] as int? ?? 0,
          direction: FriendRequestDirection.incoming,
          requestedDate: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
        );
      }).toList();
      _applyRequests();
    });

    // My own outgoing requests, of any status: `pending` ones are shown in
    // the UI; `accepted` ones mean the recipient claimed their half, so I
    // claim mine and clean up the request doc.
    _outgoingSub = _firestore
        .collection(_requestsCollection)
        .where('from', isEqualTo: uid)
        .snapshots()
        .listen((snapshot) {
      final pending = <FriendRequest>[];
      final accepted = <QueryDocumentSnapshot<Map<String, dynamic>>>[];
      for (final doc in snapshot.docs) {
        final data = doc.data();
        if (data['status'] == 'accepted') {
          accepted.add(doc);
        } else if (data['status'] == 'pending') {
          pending.add(FriendRequest(
            id: doc.id,
            otherUid: data['to'] as String,
            name: data['toDisplayName'] as String? ?? '名無しさん',
            rating: data['toRating'] as int? ?? 0,
            direction: FriendRequestDirection.outgoing,
            requestedDate: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
          ));
        }
      }
      _outgoingPending = pending;
      _applyRequests();
      _claimAcceptedRequests(accepted);
    });
  }

  Future<void> _claimAcceptedRequests(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> acceptedDocs,
  ) async {
    final me = _auth.currentUser;
    if (me == null) return;

    for (final doc in acceptedDocs) {
      final data = doc.data();
      final friendUid = data['to'] as String;
      if (_claiming.contains(doc.id)) continue;
      if (_friends.any((f) => f.id == friendUid)) continue;

      _claiming.add(doc.id);
      try {
        await _firestore
            .collection(_friendsCollection)
            .doc(me.uid)
            .collection('list')
            .doc(friendUid)
            .set({
          'displayName': data['toDisplayName'] ?? '名無しさん',
          'rankPoints': data['toRating'] ?? 0,
          'addedAt': Timestamp.fromDate(DateTime.now()),
        });
        await _firestore.collection(_requestsCollection).doc(doc.id).delete();
      } finally {
        _claiming.remove(doc.id);
      }
    }
  }

  void _applyFriends() {
    final friends =
        _friends.map((f) => f.copyWith(isFavorite: _favoriteIds.contains(f.id))).toList();
    state = state.copyWith(friends: friends);
  }

  void _applyRequests() {
    state = state.copyWith(friendRequests: [..._incoming, ..._outgoingPending]);
  }

  /// Looks up a player by exact display name and sends them a friend
  /// request. Known limitation: display names aren't unique, so this
  /// matches whichever player registered that name first to sync.
  Future<void> sendFriendRequest(String name) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return;
    final me = _auth.currentUser;
    if (me == null) {
      state = state.copyWith(error: 'サインインが必要です');
      return;
    }

    state = state.copyWith(error: null);
    try {
      final matches = await _firestore
          .collection(_publicProfileCollection)
          .where('displayName', isEqualTo: trimmed)
          .limit(1)
          .get();
      if (matches.docs.isEmpty) {
        state = state.copyWith(error: 'プレイヤーが見つかりませんでした');
        return;
      }

      final target = matches.docs.first;
      final targetUid = target.id;
      if (targetUid == me.uid) {
        state = state.copyWith(error: '自分自身にはフレンド申請できません');
        return;
      }
      if (_friends.any((f) => f.id == targetUid)) {
        state = state.copyWith(error: 'すでにフレンドです');
        return;
      }

      final asSender = await _firestore
          .collection(_requestsCollection)
          .where('from', isEqualTo: me.uid)
          .where('to', isEqualTo: targetUid)
          .where('status', isEqualTo: 'pending')
          .limit(1)
          .get();
      final asRecipient = await _firestore
          .collection(_requestsCollection)
          .where('from', isEqualTo: targetUid)
          .where('to', isEqualTo: me.uid)
          .where('status', isEqualTo: 'pending')
          .limit(1)
          .get();
      if (asSender.docs.isNotEmpty || asRecipient.docs.isNotEmpty) {
        state = state.copyWith(error: 'すでに申請済みです');
        return;
      }

      final myProfile =
          await _firestore.collection(_publicProfileCollection).doc(me.uid).get();
      final targetData = target.data();

      await _firestore.collection(_requestsCollection).add({
        'from': me.uid,
        'to': targetUid,
        'fromDisplayName': me.displayName ?? '名無しさん',
        'fromRating': myProfile.data()?['rankPoints'] as int? ?? 0,
        'toDisplayName': targetData['displayName'] as String? ?? '名無しさん',
        'toRating': targetData['rankPoints'] as int? ?? 0,
        'status': 'pending',
        'createdAt': Timestamp.fromDate(DateTime.now()),
      });
    } catch (_) {
      state = state.copyWith(error: '申請の送信に失敗しました');
    }
  }

  Future<void> acceptRequest(FriendRequest request) async {
    final me = _auth.currentUser;
    if (me == null) return;
    try {
      await _firestore.collection(_requestsCollection).doc(request.id).update({
        'status': 'accepted',
      });
      await _firestore
          .collection(_friendsCollection)
          .doc(me.uid)
          .collection('list')
          .doc(request.otherUid)
          .set({
        'displayName': request.name,
        'rankPoints': request.rating,
        'addedAt': Timestamp.fromDate(DateTime.now()),
      });
    } catch (_) {
      state = state.copyWith(error: 'フレンド申請の承認に失敗しました');
    }
  }

  Future<void> declineRequest(FriendRequest request) async {
    try {
      await _firestore.collection(_requestsCollection).doc(request.id).delete();
    } catch (_) {
      state = state.copyWith(error: 'フレンド申請の拒否に失敗しました');
    }
  }

  Future<void> toggleFavorite(String friendId) async {
    if (_favoriteIds.contains(friendId)) {
      _favoriteIds.remove(friendId);
    } else {
      _favoriteIds.add(friendId);
    }
    _applyFriends();
    final prefs = _prefs ??= await SharedPreferences.getInstance();
    await prefs.setStringList(_favoritesPrefsKey, _favoriteIds.toList());
  }

  Future<void> removeFriend(String friendId) async {
    final me = _auth.currentUser;
    if (me == null) return;
    try {
      await _firestore
          .collection(_friendsCollection)
          .doc(me.uid)
          .collection('list')
          .doc(friendId)
          .delete();
    } catch (_) {
      state = state.copyWith(error: 'フレンドの削除に失敗しました');
    }
  }

  void clearError() {
    state = state.copyWith(error: null);
  }

  @override
  void dispose() {
    _friendsSub?.cancel();
    _incomingSub?.cancel();
    _outgoingSub?.cancel();
    super.dispose();
  }
}

/// Riverpod provider for friends
final friendsProvider = StateNotifierProvider<FriendsNotifier, FriendsState>(
  (ref) => FriendsNotifier(),
);
