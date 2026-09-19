import 'dart:math' as math;

import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Searchable player profile
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
}

/// Player search state
class PlayerSearchState {
  final String query;
  final List<SearchablePlayer> results;
  final bool isLoading;
  final String? error;
  final List<SearchablePlayer> recentlyViewed;

  const PlayerSearchState({
    required this.query,
    required this.results,
    this.isLoading = false,
    this.error,
    required this.recentlyViewed,
  });

  PlayerSearchState copyWith({
    String? query,
    List<SearchablePlayer>? results,
    bool? isLoading,
    Object? error = _unset,
    List<SearchablePlayer>? recentlyViewed,
  }) {
    return PlayerSearchState(
      query: query ?? this.query,
      results: results ?? this.results,
      isLoading: isLoading ?? this.isLoading,
      error: identical(error, _unset) ? this.error : error as String?,
      recentlyViewed: recentlyViewed ?? this.recentlyViewed,
    );
  }
}

/// Sentinel used by [PlayerSearchState.copyWith] to distinguish "field not
/// passed" (keep current value) from "field explicitly passed as null"
/// (clear the value).
const Object _unset = Object();

/// Notifier for player search
class PlayerSearchNotifier extends StateNotifier<PlayerSearchState> {
  static final List<SearchablePlayer> _samplePlayers = [
    SearchablePlayer(
      id: 'player_1',
      name: 'エリート太郎',
      avatarEmoji: '🦅',
      rating: 2150,
      totalWins: 234,
      totalLosses: 45,
      totalDraws: 12,
      seasonalTier: 'ダイヤモンド',
      lastActiveDate: DateTime.now().subtract(const Duration(hours: 2)),
    ),
    SearchablePlayer(
      id: 'player_2',
      name: 'リバーシ花子',
      avatarEmoji: '🌸',
      rating: 1890,
      totalWins: 156,
      totalLosses: 78,
      totalDraws: 8,
      seasonalTier: 'プラチナ',
      lastActiveDate: DateTime.now().subtract(const Duration(hours: 5)),
    ),
    SearchablePlayer(
      id: 'player_3',
      name: '勝利の戦士',
      avatarEmoji: '⚔️',
      rating: 1720,
      totalWins: 128,
      totalLosses: 92,
      totalDraws: 15,
      seasonalTier: 'ゴールド',
      lastActiveDate: DateTime.now().subtract(const Duration(hours: 12)),
    ),
    SearchablePlayer(
      id: 'player_4',
      name: 'スーパー次郎',
      avatarEmoji: '🌟',
      rating: 1650,
      totalWins: 110,
      totalLosses: 105,
      totalDraws: 5,
      seasonalTier: 'シルバー',
      lastActiveDate: DateTime.now().subtract(const Duration(days: 1)),
    ),
    SearchablePlayer(
      id: 'player_5',
      name: 'リバーシマスター',
      avatarEmoji: '👑',
      rating: 2280,
      totalWins: 267,
      totalLosses: 38,
      totalDraws: 18,
      seasonalTier: 'マスター',
      lastActiveDate: DateTime.now().subtract(const Duration(minutes: 30)),
    ),
    SearchablePlayer(
      id: 'player_6',
      name: '初心者君',
      avatarEmoji: '🌱',
      rating: 980,
      totalWins: 25,
      totalLosses: 45,
      totalDraws: 3,
      seasonalTier: 'ブロンズ',
      lastActiveDate: DateTime.now().subtract(const Duration(days: 3)),
    ),
    SearchablePlayer(
      id: 'player_7',
      name: '強敵なり',
      avatarEmoji: '🐉',
      rating: 2050,
      totalWins: 203,
      totalLosses: 61,
      totalDraws: 11,
      seasonalTier: 'ダイヤモンド',
      lastActiveDate: DateTime.now().subtract(const Duration(hours: 8)),
    ),
    SearchablePlayer(
      id: 'player_8',
      name: 'トレーニング中',
      avatarEmoji: '💪',
      rating: 1420,
      totalWins: 89,
      totalLosses: 71,
      totalDraws: 6,
      seasonalTier: 'シルバー',
      lastActiveDate: DateTime.now().subtract(const Duration(days: 2)),
    ),
  ];

  PlayerSearchNotifier()
      : super(const PlayerSearchState(
          query: '',
          results: [],
          recentlyViewed: [],
        ));

  Future<void> searchPlayers(String query) async {
    if (query.trim().isEmpty) {
      state = state.copyWith(query: '', results: []);
      return;
    }

    state = state.copyWith(isLoading: true);

    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 500));

    final searchQuery = query.toLowerCase().trim();
    final filtered = _samplePlayers
        .where((player) =>
            player.name.toLowerCase().contains(searchQuery) ||
            player.id.toLowerCase().contains(searchQuery))
        .toList();

    // Sort by rating (descending)
    filtered.sort((a, b) => b.rating.compareTo(a.rating));

    state = state.copyWith(
      query: query,
      results: filtered,
      isLoading: false,
      error: null,
    );
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

  List<SearchablePlayer> getRandomPlayers({int count = 5}) {
    final random = math.Random();
    final shuffled = List<SearchablePlayer>.from(_samplePlayers)..shuffle(random);
    return shuffled.take(count).toList();
  }

  List<SearchablePlayer> getSuggestedPlayers() {
    // Return top rated players not recently viewed
    final viewedIds = state.recentlyViewed.map((p) => p.id).toSet();
    final suggested = _samplePlayers
        .where((p) => !viewedIds.contains(p.id))
        .toList();
    suggested.sort((a, b) => b.rating.compareTo(a.rating));
    return suggested.take(5).toList();
  }
}

/// Riverpod provider for player search
final playerSearchProvider =
    StateNotifierProvider<PlayerSearchNotifier, PlayerSearchState>(
  (ref) => PlayerSearchNotifier(),
);
