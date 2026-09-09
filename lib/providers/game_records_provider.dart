import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../engine/game_record.dart';

/// Sort order for game records
enum GameRecordSort {
  newest,
  oldest,
  duration,
  moves,
  winRate,
}

/// Filter options for game records
class GameRecordFilter {
  final String? difficulty;
  final GameResult? result;
  final DateTime? dateFrom;
  final DateTime? dateTo;

  const GameRecordFilter({
    this.difficulty,
    this.result,
    this.dateFrom,
    this.dateTo,
  });

  /// Create filter from another with selective updates
  GameRecordFilter copyWith({
    String? difficulty,
    GameResult? result,
    DateTime? dateFrom,
    DateTime? dateTo,
  }) {
    return GameRecordFilter(
      difficulty: difficulty ?? this.difficulty,
      result: result ?? this.result,
      dateFrom: dateFrom ?? this.dateFrom,
      dateTo: dateTo ?? this.dateTo,
    );
  }
}

/// State for game records with filtering and sorting
class GameRecordsState {
  final List<GameRecord> allRecords;
  final List<GameRecord> filteredRecords;
  final GameRecordFilter filter;
  final GameRecordSort sort;
  final bool isLoading;
  final String? error;

  const GameRecordsState({
    required this.allRecords,
    required this.filteredRecords,
    required this.filter,
    required this.sort,
    this.isLoading = false,
    this.error,
  });

  /// Count of win/loss/draw results
  int get winCount => filteredRecords.where((r) => r.result == GameResult.playerAWins).length;
  int get lossCount => filteredRecords.where((r) => r.result == GameResult.playerBWins).length;
  int get drawCount => filteredRecords.where((r) => r.result == GameResult.draw).length;

  /// Win rate of filtered records
  double get winRate {
    if (filteredRecords.isEmpty) return 0.0;
    return winCount / filteredRecords.length;
  }

  /// Average game duration
  double get averageDuration {
    if (filteredRecords.isEmpty) return 0.0;
    final total = filteredRecords.fold<int>(
      0,
      (sum, record) => sum + record.durationSeconds,
    );
    return total / filteredRecords.length;
  }
}

/// Notifier for managing game records
class GameRecordsNotifier extends StateNotifier<GameRecordsState> {
  final GameHistoryManager _manager;
  bool _initialized = false;

  GameRecordsNotifier(this._manager)
      : super(
          GameRecordsState(
            allRecords: [],
            filteredRecords: [],
            filter: const GameRecordFilter(),
            sort: GameRecordSort.newest,
          ),
        );

  /// Check if manager is initialized
  bool get isInitialized => _initialized;

  /// Load records from storage
  Future<void> loadRecords() async {
    state = state.copyWith(isLoading: true);
    try {
      // Initialize manager if not already done
      if (!_initialized) {
        await _manager.init(await SharedPreferences.getInstance());
        _initialized = true;
      }

      final records = _manager.getAllRecords();
      _applyFiltersAndSort(records, state.filter, state.sort);
      state = state.copyWith(isLoading: false, error: null);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  /// Add a new game record
  Future<void> addRecord(GameRecord record) async {
    try {
      // Ensure manager is initialized
      if (!_initialized) {
        await _manager.init(await SharedPreferences.getInstance());
        _initialized = true;
      }

      await _manager.addRecord(record);
      final records = _manager.getAllRecords();
      _applyFiltersAndSort(records, state.filter, state.sort);
      // Clear error on success
      if (state.error != null) {
        state = state.copyWith(error: null);
      }
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  /// Delete a game record
  Future<void> deleteRecord(String id) async {
    try {
      // Ensure manager is initialized
      if (!_initialized) {
        await _manager.init(await SharedPreferences.getInstance());
        _initialized = true;
      }

      await _manager.deleteRecord(id);
      final records = _manager.getAllRecords();
      _applyFiltersAndSort(records, state.filter, state.sort);
      // Clear error on success
      if (state.error != null) {
        state = state.copyWith(error: null);
      }
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  /// Update filter
  void setFilter(GameRecordFilter filter) {
    _applyFiltersAndSort(state.allRecords, filter, state.sort);
  }

  /// Update sort order
  void setSort(GameRecordSort sort) {
    _applyFiltersAndSort(state.allRecords, state.filter, sort);
  }

  /// Clear all records
  Future<void> clearAll() async {
    try {
      // Ensure manager is initialized
      if (!_initialized) {
        await _manager.init(await SharedPreferences.getInstance());
        _initialized = true;
      }

      await _manager.clearAll();
      state = GameRecordsState(
        allRecords: [],
        filteredRecords: [],
        filter: const GameRecordFilter(),
        sort: GameRecordSort.newest,
        isLoading: false,
        error: null,
      );
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  /// Apply filters and sorting to records
  void _applyFiltersAndSort(
    List<GameRecord> records,
    GameRecordFilter filter,
    GameRecordSort sort,
  ) {
    var filtered = records;

    // Apply filters
    if (filter.result != null) {
      filtered = filtered.where((r) => r.result == filter.result).toList();
    }

    if (filter.difficulty != null) {
      filtered = filtered.where((r) => r.aiDifficulty == filter.difficulty).toList();
    }

    if (filter.dateFrom != null) {
      final dateFrom = DateTime(
        filter.dateFrom!.year,
        filter.dateFrom!.month,
        filter.dateFrom!.day,
      );
      filtered = filtered.where((r) => r.playedAt.isAfter(dateFrom)).toList();
    }

    if (filter.dateTo != null) {
      final dateTo = DateTime(
        filter.dateTo!.year,
        filter.dateTo!.month,
        filter.dateTo!.day,
        23,
        59,
        59,
      );
      filtered = filtered.where((r) => r.playedAt.isBefore(dateTo)).toList();
    }

    // Apply sorting
    switch (sort) {
      case GameRecordSort.newest:
        filtered.sort((a, b) => b.playedAt.compareTo(a.playedAt));
      case GameRecordSort.oldest:
        filtered.sort((a, b) => a.playedAt.compareTo(b.playedAt));
      case GameRecordSort.duration:
        filtered.sort((a, b) => b.durationSeconds.compareTo(a.durationSeconds));
      case GameRecordSort.moves:
        filtered.sort((a, b) => b.totalMoves.compareTo(a.totalMoves));
      case GameRecordSort.winRate:
        // Sort by result (wins first, then draws, then losses)
        filtered.sort((a, b) {
          final aScore = a.result == GameResult.playerAWins
              ? 2
              : a.result == GameResult.draw
                  ? 1
                  : 0;
          final bScore = b.result == GameResult.playerAWins
              ? 2
              : b.result == GameResult.draw
                  ? 1
                  : 0;
          return bScore.compareTo(aScore);
        });
    }

    state = state.copyWith(
      allRecords: records,
      filteredRecords: filtered,
      filter: filter,
      sort: sort,
    );
  }

  /// Helper method to copy state
  GameRecordsState copyWith({
    List<GameRecord>? allRecords,
    List<GameRecord>? filteredRecords,
    GameRecordFilter? filter,
    GameRecordSort? sort,
    bool? isLoading,
    String? error,
  }) {
    return GameRecordsState(
      allRecords: allRecords ?? state.allRecords,
      filteredRecords: filteredRecords ?? state.filteredRecords,
      filter: filter ?? state.filter,
      sort: sort ?? state.sort,
      isLoading: isLoading ?? state.isLoading,
      error: error,
    );
  }
}

/// Riverpod provider for shared preferences
final sharedPreferencesProvider = FutureProvider<SharedPreferences>((ref) async {
  return SharedPreferences.getInstance();
});

/// Riverpod provider for game history manager
final gameHistoryManagerProvider = Provider<GameHistoryManager>((ref) {
  return GameHistoryManager();
});

/// Riverpod provider for game records state and management
final gameRecordsProvider =
    StateNotifierProvider<GameRecordsNotifier, GameRecordsState>((ref) {
  final manager = ref.watch(gameHistoryManagerProvider);
  return GameRecordsNotifier(manager);
});
