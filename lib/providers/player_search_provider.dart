import 'dart:async';
import 'dart:math' as math;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Searchable player profile, read from the `publicProfiles` Firestore
/// collection that CloudSyncNotifier publishes to (see
/// lib/providers/cloud_sync_provider.dart).
class SearchablePlayer {
  final String id;
  final String name;
  final String avatarEmoji;
  final int rating;
  final int totalWins;
  final int totalLosses;
  final int totalDraws;
  final String seasonalTier;
  final DateTime lastActiveDate;

  const SearchablePlayer({
    required this.id,
    required this.name,
    required this.avatarEmoji,
    required this.rating,
    required this.totalWins,
    required this.totalLosses,
    required this.totalDraws,
    required this.seasonalTier,
    required this.lastActiveDate,
  });

  int get totalGames => totalWins + totalLosses + totalDraws;

  double get winRate => totalGames == 0 ? 0.0 : totalWins / totalGames;

  bool get isActive =>
      DateTime.now().difference(lastActiveDate).inDays < 7;

  factory SearchablePlayer.fromDoc(QueryDocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data();
    final rating = data['rankPoints'] as int? ?? 0;
    return SearchablePlayer(
      id: doc.id,
      name: data['displayName'] as String? ?? '名無しさん',
      // publicProfiles doesn't carry an avatar yet (that's a separate,
      // purely-local customization feature) -- a generic emoji for every
      // real player until it does.
      avatarEmoji: '👤',
      rating: rating,
      totalWins: data['wins'] as int? ?? 0,
      totalLosses: data['losses'] as int? ?? 0,
      totalDraws: data['draws'] as int? ?? 0,
      seasonalTier: _tierFromRating(rating),
      lastActiveDate: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  static String _tierFromRating(int rating) {
    if (rating >= 2700) return 'マスター';
    if (rating >= 2300) return 'ダイヤモンド';
    if (rating >= 1900) return 'プラチナ';
    if (rating >= 1500) return 'ゴールド';
    if (rating >= 1000) return 'シルバー';
    return 'ブロンズ';
  }
}

/// Player search state
class PlayerSearchState {
  final String query;
  final List<SearchablePlayer> results;
  final bool isLoading;
  final String? error;
  final List<SearchablePlayer> recentlyViewed;
  final List<SearchablePlayer> topPlayers;

  const PlayerSearchState({
    required this.query,
    required this.results,
    this.isLoading = false,
    this.error,
    required this.recentlyViewed,
    this.topPlayers = const [],
  });

  PlayerSearchState copyWith({
    String? query,
    List<SearchablePlayer>? results,
    bool? isLoading,
    Object? error = _unset,
    List<SearchablePlayer>? recentlyViewed,
    List<SearchablePlayer>? topPlayers,
  }) {
    return PlayerSearchState(
      query: query ?? this.query,
      results: results ?? this.results,
      isLoading: isLoading ?? this.isLoading,
      error: identical(error, _unset) ? this.error : error as String?,
      recentlyViewed: recentlyViewed ?? this.recentlyViewed,
      topPlayers: topPlayers ?? this.topPlayers,
    );
  }
}

/// Sentinel used by [PlayerSearchState.copyWith] to distinguish "field not
/// passed" (keep current value) from "field explicitly passed as null"
/// (clear the value).
const Object _unset = Object();

/// Notifier for player search, backed by the real `publicProfiles`
/// collection instead of a fixed local sample list.
///
/// Known limitation: Firestore can only do prefix matching efficiently
/// (`displayName >= query AND displayName < query + ''`), not the
/// free-form case-insensitive substring match the old fake data supported.
/// A real "search anywhere in the name, any case" experience needs a
/// dedicated search service (e.g. Algolia) indexing Firestore writes --
/// out of scope here. Search is case-sensitive, start-of-name matching.
class PlayerSearchNotifier extends StateNotifier<PlayerSearchState> {
  static const String _collection = 'publicProfiles';

  final FirebaseFirestore _firestore;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _topPlayersSub;

  PlayerSearchNotifier({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance,
        super(const PlayerSearchState(
          query: '',
          results: [],
          recentlyViewed: [],
        )) {
    _watchTopPlayers();
  }

  void _watchTopPlayers() {
    _topPlayersSub?.cancel();
    _topPlayersSub = _firestore
        .collection(_collection)
        .orderBy('rankPoints', descending: true)
        .limit(20)
        .snapshots()
        .listen((snapshot) {
      state = state.copyWith(
        topPlayers: snapshot.docs.map(SearchablePlayer.fromDoc).toList(),
      );
    });
  }

  Future<void> searchPlayers(String query) async {
    final trimmed = query.trim();
    if (trimmed.isEmpty) {
      state = state.copyWith(query: '', results: [], error: null);
      return;
    }

    state = state.copyWith(query: query, isLoading: true, error: null);
    try {
      final snapshot = await _firestore
          .collection(_collection)
          .orderBy('displayName')
          .where('displayName', isGreaterThanOrEqualTo: trimmed)
          .where('displayName', isLessThan: '$trimmed')
          .limit(20)
          .get();

      final results = snapshot.docs.map(SearchablePlayer.fromDoc).toList()
        ..sort((a, b) => b.rating.compareTo(a.rating));

      state = state.copyWith(results: results, isLoading: false);
    } catch (_) {
      state = state.copyWith(isLoading: false, error: '検索に失敗しました');
    }
  }

  void clearSearch() {
    state = state.copyWith(query: '', results: [], error: null);
  }

  void addToRecentlyViewed(SearchablePlayer player) {
    final updated = state.recentlyViewed.where((p) => p.id != player.id).toList();
    updated.insert(0, player);
    // Keep only last 10
    if (updated.length > 10) {
      updated.removeLast();
    }
    state = state.copyWith(recentlyViewed: updated);
  }

  void clearRecentlyViewed() {
    state = state.copyWith(recentlyViewed: []);
  }

  /// A handful of real, currently-ranked players, shuffled. Not a true
  /// random sample of every player -- just the top 20 by rankPoints,
  /// shuffled -- since Firestore has no efficient uniform-random query
  /// without extra denormalized fields.
  List<SearchablePlayer> getRandomPlayers({int count = 5}) {
    final shuffled = List<SearchablePlayer>.from(state.topPlayers)..shuffle(math.Random());
    return shuffled.take(count).toList();
  }

  List<SearchablePlayer> getSuggestedPlayers() {
    final viewedIds = state.recentlyViewed.map((p) => p.id).toSet();
    return state.topPlayers.where((p) => !viewedIds.contains(p.id)).take(5).toList();
  }

  @override
  void dispose() {
    _topPlayersSub?.cancel();
    super.dispose();
  }
}

/// Riverpod provider for player search
final playerSearchProvider =
    StateNotifierProvider<PlayerSearchNotifier, PlayerSearchState>(
  (ref) => PlayerSearchNotifier(),
);
