import 'dart:convert';

import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'game_notation.dart';
import 'models.dart';

/// Manages game persistence using SharedPreferences
class GameStorage {
  static const String _storageKeyPrefix = 'reversia_game_';
  static const String _gameListKey = 'reversia_game_list';
  static const int _maxSavedGames = 50; // Limit to prevent storage bloat

  /// Save a game record
  static Future<bool> saveGame(GameRecord record) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final gameId = _generateGameId();
      final gameJson = jsonEncode(record.toJson());

      // Save the game
      await prefs.setString('$_storageKeyPrefix$gameId', gameJson);

      // Update game list
      final gameList = prefs.getStringList(_gameListKey) ?? [];
      gameList.insert(0, gameId); // Add newest first

      // Limit saved games
      if (gameList.length > _maxSavedGames) {
        final removedIds = gameList.sublist(_maxSavedGames);
        gameList.removeRange(_maxSavedGames, gameList.length);

        // Delete old game data
        for (final id in removedIds) {
          await prefs.remove('$_storageKeyPrefix$id');
        }
      }

      await prefs.setStringList(_gameListKey, gameList);
      return true;
    } catch (e) {
      print('Error saving game: $e');
      return false;
    }
  }

  /// Load a game by ID
  static Future<GameRecord?> loadGame(String gameId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final gameJson = prefs.getString('$_storageKeyPrefix$gameId');
      if (gameJson == null) return null;

      final decoded = jsonDecode(gameJson) as Map<String, dynamic>;
      return GameRecord.fromJson(decoded);
    } catch (e) {
      print('Error loading game: $e');
      return null;
    }
  }

  /// Get list of all saved games
  static Future<List<SavedGameInfo>> getSavedGames() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final gameIds = prefs.getStringList(_gameListKey) ?? [];

      final games = <SavedGameInfo>[];
      for (final id in gameIds) {
        final gameJson = prefs.getString('$_storageKeyPrefix$id');
        if (gameJson != null) {
          try {
            final decoded = jsonDecode(gameJson) as Map<String, dynamic>;
            final record = GameRecord.fromJson(decoded);
            games.add(SavedGameInfo(
              id: id,
              record: record,
            ));
          } catch (e) {
            print('Error parsing game $id: $e');
          }
        }
      }
      return games;
    } catch (e) {
      print('Error getting saved games: $e');
      return [];
    }
  }

  /// Delete a saved game
  static Future<bool> deleteGame(String gameId) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Delete the game data
      await prefs.remove('$_storageKeyPrefix$gameId');

      // Update game list
      final gameList = prefs.getStringList(_gameListKey) ?? [];
      gameList.removeWhere((id) => id == gameId);
      await prefs.setStringList(_gameListKey, gameList);

      return true;
    } catch (e) {
      print('Error deleting game: $e');
      return false;
    }
  }

  /// Clear all saved games
  static Future<bool> clearAllGames() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final gameIds = prefs.getStringList(_gameListKey) ?? [];

      for (final id in gameIds) {
        await prefs.remove('$_storageKeyPrefix$id');
      }

      await prefs.remove(_gameListKey);
      return true;
    } catch (e) {
      print('Error clearing games: $e');
      return false;
    }
  }

  /// Get storage statistics
  static Future<StorageStats> getStorageStats() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final gameIds = prefs.getStringList(_gameListKey) ?? [];

      int totalBytes = 0;
      for (final id in gameIds) {
        final gameJson = prefs.getString('$_storageKeyPrefix$id');
        if (gameJson != null) {
          totalBytes += gameJson.length;
        }
      }

      return StorageStats(
        totalGames: gameIds.length,
        estimatedBytes: totalBytes,
        maxGames: _maxSavedGames,
      );
    } catch (e) {
      return StorageStats.empty();
    }
  }

  /// Generate a unique game ID (timestamp-based)
  static String _generateGameId() {
    return DateTime.now().millisecondsSinceEpoch.toString();
  }
}

/// Information about a saved game
class SavedGameInfo {
  final String id;
  final GameRecord record;

  SavedGameInfo({
    required this.id,
    required this.record,
  });

  /// Get display name for the game
  String getDisplayName() {
    final opponent = record.aiDifficulty != null
        ? 'AI (${record.aiDifficulty})'
        : 'Player B';
    return 'You vs $opponent';
  }

  /// Get short time display (e.g., "2 hours ago")
  String getTimeDisplay() {
    final now = DateTime.now();
    final diff = now.difference(record.playedAt);

    if (diff.inMinutes < 1) {
      return 'Just now';
    } else if (diff.inMinutes < 60) {
      return '${diff.inMinutes}m ago';
    } else if (diff.inHours < 24) {
      return '${diff.inHours}h ago';
    } else if (diff.inDays < 7) {
      return '${diff.inDays}d ago';
    } else {
      return DateFormat('MMM d, y').format(record.playedAt);
    }
  }
}

/// Storage statistics
class StorageStats {
  final int totalGames;
  final int estimatedBytes;
  final int maxGames;

  StorageStats({
    required this.totalGames,
    required this.estimatedBytes,
    required this.maxGames,
  });

  factory StorageStats.empty() {
    return StorageStats(
      totalGames: 0,
      estimatedBytes: 0,
      maxGames: 50,
    );
  }

  double get usagePercent => totalGames / maxGames;

  String get formattedSize {
    if (estimatedBytes < 1024) {
      return '$estimatedBytes B';
    } else if (estimatedBytes < 1024 * 1024) {
      return '${(estimatedBytes / 1024).toStringAsFixed(1)} KB';
    } else {
      return '${(estimatedBytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
  }

  String get usageString => '$totalGames / $maxGames games';
}
