import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Player leaderboard entry
class LeaderboardEntry {
  final String playerId;
  final String playerName;
  final int rank;
  final double rating;
  final int wins;
  final int totalGames;
  final double winRate;
  final int streak;
  final String skillLevel;
  final DateTime lastPlayedAt;

  const LeaderboardEntry({
    required this.playerId,
    required this.playerName,
    required this.rank,
    required this.rating,
    required this.wins,
    required this.totalGames,
    required this.winRate,
    required this.streak,
    required this.skillLevel,
    required this.lastPlayedAt,
  });

  /// Get rank badge emoji
  String getRankEmoji() {
    if (rank == 1) return '🥇';
    if (rank == 2) return '🥈';
    if (rank == 3) return '🥉';
    if (rank <= 10) return '⭐';
    return '📊';
  }

  /// Get rank label
  String getRankLabel() {
    if (rank == 1) return 'グランドマスター';
    if (rank <= 10) return 'マスター';
    if (rank <= 50) return 'エキスパート';
    if (rank <= 100) return 'アドバンス';
    return 'チャレンジャー';
  }

  /// Get rating category
  String getRatingCategory() {
    if (rating >= 3000) return 'S+';
    if (rating >= 2500) return 'S';
    if (rating >= 2000) return 'A+';
    if (rating >= 1500) return 'A';
    if (rating >= 1000) return 'B+';
    if (rating >= 500) return 'B';
    return 'C';
  }
}

/// Leaderboard time period
enum LeaderboardPeriod {
  allTime('全期間'),
  thisMonth('今月'),
  thisWeek('今週'),
  today('今日');

  final String label;
  const LeaderboardPeriod(this.label);
}

/// Leaderboard state
class LeaderboardState {
  final List<LeaderboardEntry> entries;
  final LeaderboardPeriod period;
  final int? playerRank;
  final LeaderboardEntry? playerEntry;
  final bool isLoading;
  final String? error;

  const LeaderboardState({
    required this.entries,
    required this.period,
    this.playerRank,
    this.playerEntry,
    this.isLoading = false,
    this.error,
  });

  /// Get top 3 entries for featured section
  List<LeaderboardEntry> getTopThree() {
    return entries.take(3).toList();
  }

  /// Get entries around player rank
  List<LeaderboardEntry> getPlayerContext() {
    if (playerRank == null) return [];
    final startIdx = (playerRank! - 3).clamp(0, entries.length - 1);
    final endIdx = (playerRank! + 2).clamp(0, entries.length);
    return entries.sublist(startIdx, endIdx);
  }

  /// Get player advantage/disadvantage vs average
  double getPlayerAdvantageVsAverage() {
    if (playerEntry == null || entries.isEmpty) return 0;
    final avgRating =
        entries.fold<double>(0, (sum, e) => sum + e.rating) / entries.length;
    return ((playerEntry!.rating - avgRating) / avgRating * 100).clamp(-100, 100);
  }

  /// Copy with modifications
  LeaderboardState copyWith({
    List<LeaderboardEntry>? entries,
    LeaderboardPeriod? period,
    Object? playerRank = _unset,
    Object? playerEntry = _unset,
    bool? isLoading,
    Object? error = _unset,
  }) {
    return LeaderboardState(
      entries: entries ?? this.entries,
      period: period ?? this.period,
      playerRank: identical(playerRank, _unset) ? this.playerRank : playerRank as int?,
      playerEntry: identical(playerEntry, _unset)
          ? this.playerEntry
          : playerEntry as LeaderboardEntry?,
      isLoading: isLoading ?? this.isLoading,
      error: identical(error, _unset) ? this.error : error as String?,
    );
  }
}

const Object _unset = Object();

/// Notifier for the leaderboard, backed by the `publicProfiles` Firestore
/// collection that CloudSyncNotifier publishes to on each sync (see
/// lib/providers/cloud_sync_provider.dart). Real rank points, wins, games
/// and win streak for every player who has ever signed in and synced --
/// no more locally-fabricated rival players.
///
/// Two known limitations, kept out of scope here:
/// - Per-period leaderboards (today/this week/this month) would need
///   server-side aggregation this client-only design doesn't have, so
///   [setPeriod] only relabels the same all-time ranking.
/// - A player's entry only reflects their *last sync*, not every game
///   played since -- publicProfiles is written on sync, not on every move.
class LeaderboardNotifier extends StateNotifier<LeaderboardState> {
  static const String _collection = 'publicProfiles';

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _sub;

  LeaderboardNotifier({FirebaseFirestore? firestore, FirebaseAuth? auth})
      : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance,
        super(const LeaderboardState(
          entries: [],
          period: LeaderboardPeriod.allTime,
          isLoading: true,
        )) {
    _watchLeaderboard();
  }

  void _watchLeaderboard() {
    _sub?.cancel();
    _sub = _firestore
        .collection(_collection)
        .orderBy('rankPoints', descending: true)
        .limit(100)
        .snapshots()
        .listen((snapshot) {
      final entries = <LeaderboardEntry>[
        for (var i = 0; i < snapshot.docs.length; i++) _entryFromDoc(snapshot.docs[i], i + 1),
      ];

      final myUid = _auth.currentUser?.uid;
      final myIndex = myUid == null ? -1 : entries.indexWhere((e) => e.playerId == myUid);

      state = state.copyWith(
        entries: entries,
        playerRank: myIndex == -1 ? null : myIndex + 1,
        playerEntry: myIndex == -1 ? null : entries[myIndex],
        isLoading: false,
      );
    }, onError: (_) {
      state = state.copyWith(isLoading: false, error: 'ランキングの取得に失敗しました');
    });
  }

  LeaderboardEntry _entryFromDoc(
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
    int rank,
  ) {
    final data = doc.data();
    final wins = data['wins'] as int? ?? 0;
    final totalGames = data['totalGames'] as int? ?? 0;
    final rating = (data['rankPoints'] as num?)?.toDouble() ?? 0;

    return LeaderboardEntry(
      playerId: doc.id,
      playerName: data['displayName'] as String? ?? '名無しさん',
      rank: rank,
      rating: rating,
      wins: wins,
      totalGames: totalGames,
      winRate: totalGames > 0 ? wins / totalGames : 0.0,
      streak: data['winStreak'] as int? ?? 0,
      skillLevel: _getSkillLevelFromRating(rating),
      lastPlayedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  /// Get skill level from rating
  static String _getSkillLevelFromRating(double rating) {
    if (rating >= 2700) return 'マスター';
    if (rating >= 2300) return 'アドバンス';
    if (rating >= 1900) return 'インターミディエイト';
    if (rating >= 1500) return 'ビギナー+';
    return 'ビギナー';
  }

  /// Change leaderboard period. See the class doc -- this only relabels
  /// the same all-time ranking, since per-period aggregation isn't
  /// supported yet.
  void setPeriod(LeaderboardPeriod period) {
    state = state.copyWith(period: period);
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}

/// Riverpod provider for leaderboard
final leaderboardProvider =
    StateNotifierProvider<LeaderboardNotifier, LeaderboardState>((ref) {
  return LeaderboardNotifier();
});
