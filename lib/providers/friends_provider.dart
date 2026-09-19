import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Online status of a friend
enum FriendStatus {
  online('オンライン'),
  inGame('対局中'),
  away('離席中'),
  offline('オフライン');

  final String label;
  const FriendStatus(this.label);
}

/// Friend request direction
enum FriendRequestDirection { incoming, outgoing }

/// A single friend relationship
class Friend {
  final String id;
  final String name;
  final String avatarEmoji;
  final FriendStatus status;
  final int rating;
  final int winsAgainst;
  final int lossesAgainst;
  final int drawsAgainst;
  final DateTime addedDate;
  final DateTime? lastPlayedDate;
  final bool isFavorite;

  const Friend({
    required this.id,
    required this.name,
    required this.avatarEmoji,
    required this.status,
    required this.rating,
    this.winsAgainst = 0,
    this.lossesAgainst = 0,
    this.drawsAgainst = 0,
    required this.addedDate,
    this.lastPlayedDate,
    this.isFavorite = false,
  });

  int get totalGames => winsAgainst + lossesAgainst + drawsAgainst;

  double get winRate => totalGames == 0 ? 0.0 : winsAgainst / totalGames;

  Friend copyWith({
    String? id,
    String? name,
    String? avatarEmoji,
    FriendStatus? status,
    int? rating,
    int? winsAgainst,
    int? lossesAgainst,
    int? drawsAgainst,
    DateTime? addedDate,
    DateTime? lastPlayedDate,
    bool? isFavorite,
  }) {
    return Friend(
      id: id ?? this.id,
      name: name ?? this.name,
      avatarEmoji: avatarEmoji ?? this.avatarEmoji,
      status: status ?? this.status,
      rating: rating ?? this.rating,
      winsAgainst: winsAgainst ?? this.winsAgainst,
      lossesAgainst: lossesAgainst ?? this.lossesAgainst,
      drawsAgainst: drawsAgainst ?? this.drawsAgainst,
      addedDate: addedDate ?? this.addedDate,
      lastPlayedDate: lastPlayedDate ?? this.lastPlayedDate,
      isFavorite: isFavorite ?? this.isFavorite,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'avatarEmoji': avatarEmoji,
        'status': status.index,
        'rating': rating,
        'winsAgainst': winsAgainst,
        'lossesAgainst': lossesAgainst,
        'drawsAgainst': drawsAgainst,
        'addedDate': addedDate.toIso8601String(),
        'lastPlayedDate': lastPlayedDate?.toIso8601String(),
        'isFavorite': isFavorite,
      };

  factory Friend.fromJson(Map<String, dynamic> json) => Friend(
        id: json['id'],
        name: json['name'],
        avatarEmoji: json['avatarEmoji'],
        status: FriendStatus.values[json['status']],
        rating: json['rating'],
        winsAgainst: json['winsAgainst'] ?? 0,
        lossesAgainst: json['lossesAgainst'] ?? 0,
        drawsAgainst: json['drawsAgainst'] ?? 0,
        addedDate: DateTime.parse(json['addedDate']),
        lastPlayedDate: json['lastPlayedDate'] != null
            ? DateTime.parse(json['lastPlayedDate'])
            : null,
        isFavorite: json['isFavorite'] ?? false,
      );
}

/// A pending friend request
class FriendRequest {
  final String id;
  final String name;
  final String avatarEmoji;
  final int rating;
  final FriendRequestDirection direction;
  final DateTime requestedDate;

  const FriendRequest({
    required this.id,
    required this.name,
    required this.avatarEmoji,
    required this.rating,
    required this.direction,
    required this.requestedDate,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'avatarEmoji': avatarEmoji,
        'rating': rating,
        'direction': direction.index,
        'requestedDate': requestedDate.toIso8601String(),
      };

  factory FriendRequest.fromJson(Map<String, dynamic> json) => FriendRequest(
        id: json['id'],
        name: json['name'],
        avatarEmoji: json['avatarEmoji'],
        rating: json['rating'],
        direction: FriendRequestDirection.values[json['direction']],
        requestedDate: DateTime.parse(json['requestedDate']),
      );
}

/// A social activity feed entry
class ActivityEntry {
  final String id;
  final String friendName;
  final String friendAvatarEmoji;
  final String message;
  final String emoji;
  final DateTime timestamp;

  const ActivityEntry({
    required this.id,
    required this.friendName,
    required this.friendAvatarEmoji,
    required this.message,
    required this.emoji,
    required this.timestamp,
  });
}

/// A challenge sent between friends
class FriendChallenge {
  final String id;
  final String friendId;
  final String friendName;
  final String friendAvatarEmoji;
  final DateTime sentDate;
  final bool isIncoming;
  final bool isAccepted;
  final bool isDeclined;

  const FriendChallenge({
    required this.id,
    required this.friendId,
    required this.friendName,
    required this.friendAvatarEmoji,
    required this.sentDate,
    required this.isIncoming,
    this.isAccepted = false,
    this.isDeclined = false,
  });

  FriendChallenge copyWith({
    bool? isAccepted,
    bool? isDeclined,
  }) {
    return FriendChallenge(
      id: id,
      friendId: friendId,
      friendName: friendName,
      friendAvatarEmoji: friendAvatarEmoji,
      sentDate: sentDate,
      isIncoming: isIncoming,
      isAccepted: isAccepted ?? this.isAccepted,
      isDeclined: isDeclined ?? this.isDeclined,
    );
  }
}

/// Friends state
class FriendsState {
  final List<Friend> friends;
  final List<FriendRequest> friendRequests;
  final List<ActivityEntry> activityFeed;
  final List<FriendChallenge> challenges;
  final bool isLoading;
  final String? error;

  const FriendsState({
    required this.friends,
    required this.friendRequests,
    required this.activityFeed,
    required this.challenges,
    this.isLoading = false,
    this.error,
  });

  List<Friend> get onlineFriends =>
      friends.where((f) => f.status != FriendStatus.offline).toList();

  int get incomingRequestCount => friendRequests
      .where((r) => r.direction == FriendRequestDirection.incoming)
      .length;

  FriendsState copyWith({
    List<Friend>? friends,
    List<FriendRequest>? friendRequests,
    List<ActivityEntry>? activityFeed,
    List<FriendChallenge>? challenges,
    bool? isLoading,
    String? error,
  }) {
    return FriendsState(
      friends: friends ?? this.friends,
      friendRequests: friendRequests ?? this.friendRequests,
      activityFeed: activityFeed ?? this.activityFeed,
      challenges: challenges ?? this.challenges,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

/// Notifier for friends and social features
class FriendsNotifier extends StateNotifier<FriendsState> {
  SharedPreferences? _prefs;
  static const _friendsKey = 'friends_list';
  static const _requestsKey = 'friend_requests';

  FriendsNotifier()
      : super(const FriendsState(
          friends: [],
          friendRequests: [],
          activityFeed: [],
          challenges: [],
        )) {
    _initialize();
  }

  Future<void> _initialize() async {
    final prefs = await SharedPreferences.getInstance();
    _prefs = prefs;
    _loadFriends(prefs);
    _loadRequests(prefs);
    _generateActivityFeed();
    _generateChallenges();
  }

  void _loadFriends(SharedPreferences prefs) {
    final stored = prefs.getStringList(_friendsKey);
    if (stored != null && stored.isNotEmpty) {
      final friends = stored
          .map((s) => Friend.fromJson(jsonDecode(s) as Map<String, dynamic>))
          .toList();
      state = state.copyWith(friends: friends);
      return;
    }

    // Seed with sample friends for first run
    final now = DateTime.now();
    final sample = [
      Friend(
        id: 'friend_1',
        name: 'あかり',
        avatarEmoji: '🦊',
        status: FriendStatus.online,
        rating: 1420,
        winsAgainst: 8,
        lossesAgainst: 5,
        drawsAgainst: 1,
        addedDate: now.subtract(const Duration(days: 60)),
        lastPlayedDate: now.subtract(const Duration(hours: 3)),
        isFavorite: true,
      ),
      Friend(
        id: 'friend_2',
        name: 'ゆうと',
        avatarEmoji: '🐻',
        status: FriendStatus.inGame,
        rating: 1650,
        winsAgainst: 3,
        lossesAgainst: 9,
        drawsAgainst: 2,
        addedDate: now.subtract(const Duration(days: 45)),
        lastPlayedDate: now.subtract(const Duration(days: 1)),
      ),
      Friend(
        id: 'friend_3',
        name: 'さくら',
        avatarEmoji: '🐧',
        status: FriendStatus.offline,
        rating: 1180,
        winsAgainst: 12,
        lossesAgainst: 4,
        drawsAgainst: 0,
        addedDate: now.subtract(const Duration(days: 20)),
        lastPlayedDate: now.subtract(const Duration(days: 5)),
      ),
      Friend(
        id: 'friend_4',
        name: 'たける',
        avatarEmoji: '🦁',
        status: FriendStatus.away,
        rating: 1990,
        winsAgainst: 1,
        lossesAgainst: 6,
        drawsAgainst: 1,
        addedDate: now.subtract(const Duration(days: 10)),
        lastPlayedDate: now.subtract(const Duration(hours: 20)),
      ),
      Friend(
        id: 'friend_5',
        name: 'みお',
        avatarEmoji: '🐰',
        status: FriendStatus.online,
        rating: 1340,
        addedDate: now.subtract(const Duration(days: 2)),
      ),
    ];

    state = state.copyWith(friends: sample);
    _persistFriends();
  }

  void _loadRequests(SharedPreferences prefs) {
    final stored = prefs.getStringList(_requestsKey);
    if (stored != null && stored.isNotEmpty) {
      final requests = stored
          .map((s) =>
              FriendRequest.fromJson(jsonDecode(s) as Map<String, dynamic>))
          .toList();
      state = state.copyWith(friendRequests: requests);
      return;
    }

    final now = DateTime.now();
    final sample = [
      FriendRequest(
        id: 'req_1',
        name: 'はると',
        avatarEmoji: '🦉',
        rating: 1290,
        direction: FriendRequestDirection.incoming,
        requestedDate: now.subtract(const Duration(hours: 5)),
      ),
      FriendRequest(
        id: 'req_2',
        name: 'りん',
        avatarEmoji: '🐼',
        rating: 1510,
        direction: FriendRequestDirection.incoming,
        requestedDate: now.subtract(const Duration(days: 1)),
      ),
    ];

    state = state.copyWith(friendRequests: sample);
    _persistRequests();
  }

  void _generateActivityFeed() {
    final now = DateTime.now();
    final friends = state.friends;
    if (friends.isEmpty) return;

    final entries = <ActivityEntry>[
      ActivityEntry(
        id: 'activity_1',
        friendName: friends[0].name,
        friendAvatarEmoji: friends[0].avatarEmoji,
        message: 'レーティング1400に到達しました',
        emoji: '📈',
        timestamp: now.subtract(const Duration(hours: 2)),
      ),
      if (friends.length > 1)
        ActivityEntry(
          id: 'activity_2',
          friendName: friends[1].name,
          friendAvatarEmoji: friends[1].avatarEmoji,
          message: 'AI(エキスパート)に勝利しました',
          emoji: '🏆',
          timestamp: now.subtract(const Duration(hours: 6)),
        ),
      if (friends.length > 2)
        ActivityEntry(
          id: 'activity_3',
          friendName: friends[2].name,
          friendAvatarEmoji: friends[2].avatarEmoji,
          message: '新しいバッジ「連勝王」を獲得しました',
          emoji: '🎖️',
          timestamp: now.subtract(const Duration(days: 1)),
        ),
      if (friends.length > 3)
        ActivityEntry(
          id: 'activity_4',
          friendName: friends[3].name,
          friendAvatarEmoji: friends[3].avatarEmoji,
          message: '週間目標を達成しました',
          emoji: '✅',
          timestamp: now.subtract(const Duration(days: 2)),
        ),
    ];

    state = state.copyWith(activityFeed: entries);
  }

  void _generateChallenges() {
    final friends = state.friends;
    if (friends.length < 2) return;

    final now = DateTime.now();
    final challenges = [
      FriendChallenge(
        id: 'challenge_1',
        friendId: friends[1].id,
        friendName: friends[1].name,
        friendAvatarEmoji: friends[1].avatarEmoji,
        sentDate: now.subtract(const Duration(hours: 4)),
        isIncoming: true,
      ),
    ];

    state = state.copyWith(challenges: challenges);
  }

  Future<void> _persistFriends() async {
    final prefs = _prefs ??= await SharedPreferences.getInstance();
    final encoded =
        state.friends.map((f) => jsonEncode(f.toJson())).toList();
    await prefs.setStringList(_friendsKey, encoded);
  }

  Future<void> _persistRequests() async {
    final prefs = _prefs ??= await SharedPreferences.getInstance();
    final encoded =
        state.friendRequests.map((r) => jsonEncode(r.toJson())).toList();
    await prefs.setStringList(_requestsKey, encoded);
  }

  Future<void> toggleFavorite(String friendId) async {
    final updated = state.friends
        .map((f) =>
            f.id == friendId ? f.copyWith(isFavorite: !f.isFavorite) : f)
        .toList();
    state = state.copyWith(friends: updated);
    await _persistFriends();
  }

  Future<void> removeFriend(String friendId) async {
    final updated = state.friends.where((f) => f.id != friendId).toList();
    state = state.copyWith(friends: updated);
    await _persistFriends();
  }

  Future<void> acceptRequest(FriendRequest request) async {
    try {
      final newFriend = Friend(
        id: 'friend_${DateTime.now().millisecondsSinceEpoch}',
        name: request.name,
        avatarEmoji: request.avatarEmoji,
        status: FriendStatus.online,
        rating: request.rating,
        addedDate: DateTime.now(),
      );

      final updatedFriends = [...state.friends, newFriend];
      final updatedRequests =
          state.friendRequests.where((r) => r.id != request.id).toList();

      state = state.copyWith(
        friends: updatedFriends,
        friendRequests: updatedRequests,
      );

      await _persistFriends();
      await _persistRequests();
    } catch (e) {
      state = state.copyWith(error: 'Failed to accept request: $e');
    }
  }

  Future<void> declineRequest(FriendRequest request) async {
    try {
      final updatedRequests =
          state.friendRequests.where((r) => r.id != request.id).toList();
      state = state.copyWith(friendRequests: updatedRequests);
      await _persistRequests();
    } catch (e) {
      state = state.copyWith(error: 'Failed to decline request: $e');
    }
  }

  Future<void> sendFriendRequest(String name) async {
    if (name.trim().isEmpty) return;

    try {
      final emojis = ['🦊', '🐻', '🐧', '🦁', '🐰', '🦉', '🐼', '🐨', '🐯', '🐸'];
      final random = math.Random();

      final request = FriendRequest(
        id: 'req_${DateTime.now().millisecondsSinceEpoch}',
        name: name.trim(),
        avatarEmoji: emojis[random.nextInt(emojis.length)],
        rating: 1000 + random.nextInt(1000),
        direction: FriendRequestDirection.outgoing,
        requestedDate: DateTime.now(),
      );

      state = state.copyWith(
        friendRequests: [...state.friendRequests, request],
      );
      await _persistRequests();
    } catch (e) {
      state = state.copyWith(error: 'Failed to send request: $e');
    }
  }

  Future<void> sendChallenge(Friend friend) async {
    try {
      final challenge = FriendChallenge(
        id: 'challenge_${DateTime.now().millisecondsSinceEpoch}',
        friendId: friend.id,
        friendName: friend.name,
        friendAvatarEmoji: friend.avatarEmoji,
        sentDate: DateTime.now(),
        isIncoming: false,
      );

      state = state.copyWith(challenges: [challenge, ...state.challenges]);
    } catch (e) {
      state = state.copyWith(error: 'Failed to send challenge: $e');
    }
  }

  Future<void> respondToChallenge(
    FriendChallenge challenge, {
    required bool accept,
  }) async {
    try {
      final updated = state.challenges
          .map((c) => c.id == challenge.id
              ? c.copyWith(isAccepted: accept, isDeclined: !accept)
              : c)
          .toList();
      state = state.copyWith(challenges: updated);
    } catch (e) {
      state = state.copyWith(error: 'Failed to respond to challenge: $e');
    }
  }

  Future<void> recordMatchResult(
    String friendId, {
    required bool won,
    required bool draw,
  }) async {
    try {
      final updated = state.friends.map((f) {
        if (f.id != friendId) return f;
        return f.copyWith(
          winsAgainst: f.winsAgainst + (won && !draw ? 1 : 0),
          lossesAgainst: f.lossesAgainst + (!won && !draw ? 1 : 0),
          drawsAgainst: f.drawsAgainst + (draw ? 1 : 0),
          lastPlayedDate: DateTime.now(),
        );
      }).toList();

      state = state.copyWith(friends: updated);
      await _persistFriends();
    } catch (e) {
      state = state.copyWith(error: 'Failed to record match: $e');
    }
  }
}

/// Riverpod provider for friends and social features
final friendsProvider =
    StateNotifierProvider<FriendsNotifier, FriendsState>(
  (ref) => FriendsNotifier(),
);
