import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../engine/game_record.dart';
import 'game_records_provider.dart';

/// Tag applied to a specific move during study
enum MoveTag {
  brilliant('会心の一手', '💎'),
  good('良い手', '👍'),
  mistake('疑問手', '❓'),
  blunder('悪手', '❌'),
  critical('重要局面', '🔑');

  final String label;
  final String emoji;
  const MoveTag(this.label, this.emoji);
}

/// A single annotation attached to a move index within a studied game
class MoveAnnotation {
  final int moveIndex;
  final String note;
  final MoveTag? tag;
  final DateTime createdDate;

  const MoveAnnotation({
    required this.moveIndex,
    required this.note,
    this.tag,
    required this.createdDate,
  });

  MoveAnnotation copyWith({
    int? moveIndex,
    String? note,
    MoveTag? tag,
    DateTime? createdDate,
  }) {
    return MoveAnnotation(
      moveIndex: moveIndex ?? this.moveIndex,
      note: note ?? this.note,
      tag: tag ?? this.tag,
      createdDate: createdDate ?? this.createdDate,
    );
  }

  Map<String, dynamic> toJson() => {
        'moveIndex': moveIndex,
        'note': note,
        'tag': tag?.index,
        'createdDate': createdDate.toIso8601String(),
      };

  factory MoveAnnotation.fromJson(Map<String, dynamic> json) =>
      MoveAnnotation(
        moveIndex: json['moveIndex'],
        note: json['note'],
        tag: json['tag'] != null ? MoveTag.values[json['tag']] : null,
        createdDate: DateTime.parse(json['createdDate']),
      );
}

/// A studied game: a GameRecord plus study metadata
class StudiedGame {
  final String gameRecordId;
  final List<MoveAnnotation> annotations;
  final Set<int> bookmarkedMoves;
  final int studySessionCount;
  final int totalStudySeconds;
  final DateTime? lastStudiedDate;
  final bool isCompleted;

  const StudiedGame({
    required this.gameRecordId,
    this.annotations = const [],
    this.bookmarkedMoves = const {},
    this.studySessionCount = 0,
    this.totalStudySeconds = 0,
    this.lastStudiedDate,
    this.isCompleted = false,
  });

  StudiedGame copyWith({
    String? gameRecordId,
    List<MoveAnnotation>? annotations,
    Set<int>? bookmarkedMoves,
    int? studySessionCount,
    int? totalStudySeconds,
    DateTime? lastStudiedDate,
    bool? isCompleted,
  }) {
    return StudiedGame(
      gameRecordId: gameRecordId ?? this.gameRecordId,
      annotations: annotations ?? this.annotations,
      bookmarkedMoves: bookmarkedMoves ?? this.bookmarkedMoves,
      studySessionCount: studySessionCount ?? this.studySessionCount,
      totalStudySeconds: totalStudySeconds ?? this.totalStudySeconds,
      lastStudiedDate: lastStudiedDate ?? this.lastStudiedDate,
      isCompleted: isCompleted ?? this.isCompleted,
    );
  }

  Map<String, dynamic> toJson() => {
        'gameRecordId': gameRecordId,
        'annotations': annotations.map((a) => a.toJson()).toList(),
        'bookmarkedMoves': bookmarkedMoves.toList(),
        'studySessionCount': studySessionCount,
        'totalStudySeconds': totalStudySeconds,
        'lastStudiedDate': lastStudiedDate?.toIso8601String(),
        'isCompleted': isCompleted,
      };

  factory StudiedGame.fromJson(Map<String, dynamic> json) => StudiedGame(
        gameRecordId: json['gameRecordId'],
        annotations: (json['annotations'] as List<dynamic>? ?? [])
            .map((a) => MoveAnnotation.fromJson(a as Map<String, dynamic>))
            .toList(),
        bookmarkedMoves: (json['bookmarkedMoves'] as List<dynamic>? ?? [])
            .map((e) => e as int)
            .toSet(),
        studySessionCount: json['studySessionCount'] ?? 0,
        totalStudySeconds: json['totalStudySeconds'] ?? 0,
        lastStudiedDate: json['lastStudiedDate'] != null
            ? DateTime.parse(json['lastStudiedDate'])
            : null,
        isCompleted: json['isCompleted'] ?? false,
      );
}

/// Replay study state
class ReplayStudyState {
  final Map<String, StudiedGame> studiedGames;
  final int totalStudySeconds;
  final int totalAnnotations;
  final int studyStreak;
  final bool isLoading;
  final String? error;

  const ReplayStudyState({
    required this.studiedGames,
    this.totalStudySeconds = 0,
    this.totalAnnotations = 0,
    this.studyStreak = 0,
    this.isLoading = false,
    this.error,
  });

  StudiedGame getOrCreate(String gameRecordId) =>
      studiedGames[gameRecordId] ?? StudiedGame(gameRecordId: gameRecordId);

  ReplayStudyState copyWith({
    Map<String, StudiedGame>? studiedGames,
    int? totalStudySeconds,
    int? totalAnnotations,
    int? studyStreak,
    bool? isLoading,
    String? error,
  }) {
    return ReplayStudyState(
      studiedGames: studiedGames ?? this.studiedGames,
      totalStudySeconds: totalStudySeconds ?? this.totalStudySeconds,
      totalAnnotations: totalAnnotations ?? this.totalAnnotations,
      studyStreak: studyStreak ?? this.studyStreak,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

/// Notifier for the replay study mode
class ReplayStudyNotifier extends StateNotifier<ReplayStudyState> {
  final SharedPreferences prefs;
  static const _studiedGamesKey = 'replay_study_games';
  static const _lastStudyDateKey = 'replay_study_last_date';
  static const _studyStreakKey = 'replay_study_streak';

  ReplayStudyNotifier(this.prefs)
      : super(ReplayStudyState(
          studiedGames: const {},
          studyStreak: prefs.getInt(_studyStreakKey) ?? 0,
        )) {
    _loadStudiedGames();
  }

  void _loadStudiedGames() {
    final stored = prefs.getStringList(_studiedGamesKey);
    if (stored == null || stored.isEmpty) return;

    final games = <String, StudiedGame>{};
    var totalSeconds = 0;
    var totalAnnotations = 0;

    for (final s in stored) {
      final game = StudiedGame.fromJson(jsonDecode(s) as Map<String, dynamic>);
      games[game.gameRecordId] = game;
      totalSeconds += game.totalStudySeconds;
      totalAnnotations += game.annotations.length;
    }

    state = state.copyWith(
      studiedGames: games,
      totalStudySeconds: totalSeconds,
      totalAnnotations: totalAnnotations,
    );
  }

  Future<void> _persist() async {
    final encoded = state.studiedGames.values
        .map((g) => jsonEncode(g.toJson()))
        .toList();
    await prefs.setStringList(_studiedGamesKey, encoded);
  }

  Future<void> _updateGame(
    String gameRecordId,
    StudiedGame Function(StudiedGame) update,
  ) async {
    final current = state.getOrCreate(gameRecordId);
    final updated = update(current);

    final games = {...state.studiedGames, gameRecordId: updated};
    final totalSeconds =
        games.values.fold<int>(0, (sum, g) => sum + g.totalStudySeconds);
    final totalAnnotations =
        games.values.fold<int>(0, (sum, g) => sum + g.annotations.length);

    state = state.copyWith(
      studiedGames: games,
      totalStudySeconds: totalSeconds,
      totalAnnotations: totalAnnotations,
    );

    await _persist();
  }

  /// Call when the user opens a game for study — records session and streak
  Future<void> startStudySession(String gameRecordId) async {
    await _updateGame(gameRecordId, (game) {
      return game.copyWith(
        studySessionCount: game.studySessionCount + 1,
        lastStudiedDate: DateTime.now(),
      );
    });

    await _updateStreak();
  }

  Future<void> _updateStreak() async {
    final today = DateTime.now();
    final todayKey = '${today.year}-${today.month}-${today.day}';
    final lastDateStr = prefs.getString(_lastStudyDateKey);

    if (lastDateStr == todayKey) return; // already counted today

    int newStreak = state.studyStreak;
    if (lastDateStr != null) {
      final lastDate = DateTime.parse(lastDateStr.split('-').length == 3
          ? _keyToIso(lastDateStr)
          : today.toIso8601String());
      final diff = today.difference(lastDate).inDays;
      newStreak = diff <= 1 ? newStreak + 1 : 1;
    } else {
      newStreak = 1;
    }

    await prefs.setString(_lastStudyDateKey, todayKey);
    await prefs.setInt(_studyStreakKey, newStreak);

    state = state.copyWith(studyStreak: newStreak);
  }

  String _keyToIso(String key) {
    final parts = key.split('-');
    final y = int.parse(parts[0]);
    final m = int.parse(parts[1]);
    final d = int.parse(parts[2]);
    return DateTime(y, m, d).toIso8601String();
  }

  Future<void> addStudyTime(String gameRecordId, int seconds) async {
    await _updateGame(gameRecordId, (game) {
      return game.copyWith(
        totalStudySeconds: game.totalStudySeconds + seconds,
        lastStudiedDate: DateTime.now(),
      );
    });
  }

  Future<void> addAnnotation(
    String gameRecordId,
    int moveIndex,
    String note, {
    MoveTag? tag,
  }) async {
    await _updateGame(gameRecordId, (game) {
      final annotations = [...game.annotations];
      final existingIndex =
          annotations.indexWhere((a) => a.moveIndex == moveIndex);

      final annotation = MoveAnnotation(
        moveIndex: moveIndex,
        note: note,
        tag: tag,
        createdDate: DateTime.now(),
      );

      if (existingIndex != -1) {
        annotations[existingIndex] = annotation;
      } else {
        annotations.add(annotation);
      }

      annotations.sort((a, b) => a.moveIndex.compareTo(b.moveIndex));

      return game.copyWith(annotations: annotations);
    });
  }

  Future<void> removeAnnotation(String gameRecordId, int moveIndex) async {
    await _updateGame(gameRecordId, (game) {
      final annotations =
          game.annotations.where((a) => a.moveIndex != moveIndex).toList();
      return game.copyWith(annotations: annotations);
    });
  }

  Future<void> toggleBookmark(String gameRecordId, int moveIndex) async {
    await _updateGame(gameRecordId, (game) {
      final bookmarks = {...game.bookmarkedMoves};
      if (bookmarks.contains(moveIndex)) {
        bookmarks.remove(moveIndex);
      } else {
        bookmarks.add(moveIndex);
      }
      return game.copyWith(bookmarkedMoves: bookmarks);
    });
  }

  Future<void> markCompleted(String gameRecordId, bool completed) async {
    await _updateGame(gameRecordId, (game) {
      return game.copyWith(isCompleted: completed);
    });
  }
}

/// Riverpod provider for replay study mode
final replayStudyProvider =
    StateNotifierProvider<ReplayStudyNotifier, ReplayStudyState>(
  (ref) async {
    final prefs = await SharedPreferences.getInstance();
    return ReplayStudyNotifier(prefs);
  },
);

/// Convenience provider exposing the list of studyable games from game history
final studyableGamesProvider = Provider<List<GameRecord>>((ref) {
  final recordsState = ref.watch(gameRecordsProvider);
  return recordsState.allRecords;
});
