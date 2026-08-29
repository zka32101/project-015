import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

import 'models.dart';

/// Records a completed game for history and analysis
class GameRecord {
  final String id; // Unique identifier (timestamp-based)
  final DateTime playedAt;
  final GameResult result;
  final String? aiDifficulty; // null for local 2-player
  final int totalMoves;
  final int durationSeconds;
  final int playerAPieceCount;
  final int playerBPieceCount;
  final List<String> moveList; // Stored as strings for serialization

  GameRecord({
    required this.id,
    required this.playedAt,
    required this.result,
    this.aiDifficulty,
    required this.totalMoves,
    required this.durationSeconds,
    required this.playerAPieceCount,
    required this.playerBPieceCount,
    required this.moveList,
  });

  String get resultDisplay {
    switch (result) {
      case GameResult.playerAWins:
        return '藍陣営の勝利';
      case GameResult.playerBWins:
        return '朱陣営の勝利';
      case GameResult.draw:
        return '引き分け';
      case GameResult.ongoing:
        return '進行中';
    }
  }

  String get durationDisplay {
    final minutes = durationSeconds ~/ 60;
    final seconds = durationSeconds % 60;
    return '${minutes}分${seconds}秒';
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'playedAt': playedAt.toIso8601String(),
    'result': result.index,
    'aiDifficulty': aiDifficulty,
    'totalMoves': totalMoves,
    'durationSeconds': durationSeconds,
    'playerAPieceCount': playerAPieceCount,
    'playerBPieceCount': playerBPieceCount,
    'moveList': moveList,
  };

  factory GameRecord.fromJson(Map<String, dynamic> json) {
    return GameRecord(
      id: json['id'],
      playedAt: DateTime.parse(json['playedAt']),
      result: GameResult.values[json['result']],
      aiDifficulty: json['aiDifficulty'],
      totalMoves: json['totalMoves'],
      durationSeconds: json['durationSeconds'],
      playerAPieceCount: json['playerAPieceCount'],
      playerBPieceCount: json['playerBPieceCount'],
      moveList: List<String>.from(json['moveList']),
    );
  }
}

/// Manages game history and record storage
class GameHistoryManager {
  static const String prefsKey = 'game_history';
  static const int maxRecords = 100; // Keep last 100 games

  late SharedPreferences _prefs;
  final List<GameRecord> _records = [];

  /// Initialize the manager
  Future<void> init(SharedPreferences prefs) async {
    _prefs = prefs;
    await _loadRecords();
  }

  /// Load records from persistent storage
  Future<void> _loadRecords() async {
    final data = _prefs.getString(prefsKey);
    _records.clear();
    if (data != null) {
      try {
        final List decoded = jsonDecode(data);
        for (final item in decoded) {
          _records.add(GameRecord.fromJson(item));
        }
        // Sort by date descending (newest first)
        _records.sort((a, b) => b.playedAt.compareTo(a.playedAt));
      } catch (e) {
        // If loading fails, start with empty list
      }
    }
  }

  /// Save records to persistent storage
  Future<void> _saveRecords() async {
    final data = jsonEncode(
      _records.map((r) => r.toJson()).toList(),
    );
    await _prefs.setString(prefsKey, data);
  }

  /// Add a new game record
  Future<void> addRecord(GameRecord record) async {
    _records.insert(0, record); // Add to beginning (newest first)

    // Keep only the most recent maxRecords
    if (_records.length > maxRecords) {
      _records.removeRange(maxRecords, _records.length);
    }

    await _saveRecords();
  }

  /// Get all records
  List<GameRecord> getAllRecords() => List.from(_records);

  /// Get records filtered by result
  List<GameRecord> getRecordsByResult(GameResult result) {
    return _records.where((r) => r.result == result).toList();
  }

  /// Get records against specific AI difficulty
  List<GameRecord> getRecordsByDifficulty(String difficulty) {
    return _records.where((r) => r.aiDifficulty == difficulty).toList();
  }

  /// Get records from a specific date
  List<GameRecord> getRecordsByDate(DateTime date) {
    return _records.where((r) {
      return r.playedAt.year == date.year &&
          r.playedAt.month == date.month &&
          r.playedAt.day == date.day;
    }).toList();
  }

  /// Get record count
  int get totalRecordCount => _records.length;

  /// Get recent records (last N games)
  List<GameRecord> getRecentRecords(int count) {
    return _records.take(count).toList();
  }

  /// Get average game duration
  double get averageDurationSeconds {
    if (_records.isEmpty) return 0;
    final total = _records.fold<int>(
      0,
      (sum, record) => sum + record.durationSeconds,
    );
    return total / _records.length;
  }

  /// Delete a specific record
  Future<void> deleteRecord(String id) async {
    _records.removeWhere((r) => r.id == id);
    await _saveRecords();
  }

  /// Clear all records
  Future<void> clearAll() async {
    _records.clear();
    await _saveRecords();
  }
}
