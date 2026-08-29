import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

/// Represents an achievement that a player can unlock
class Achievement {
  final String id;
  final String name;
  final String description;
  final String emoji;
  bool isUnlocked;
  DateTime? unlockedAt;

  Achievement({
    required this.id,
    required this.name,
    required this.description,
    required this.emoji,
    this.isUnlocked = false,
    this.unlockedAt,
  });

  void unlock() {
    if (!isUnlocked) {
      isUnlocked = true;
      unlockedAt = DateTime.now();
    }
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'description': description,
    'emoji': emoji,
    'isUnlocked': isUnlocked,
    'unlockedAt': unlockedAt?.toIso8601String(),
  };

  factory Achievement.fromJson(Map<String, dynamic> json) {
    return Achievement(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      emoji: json['emoji'],
      isUnlocked: json['isUnlocked'] ?? false,
      unlockedAt: json['unlockedAt'] != null
          ? DateTime.parse(json['unlockedAt'])
          : null,
    );
  }
}

/// Manages player achievements and unlocks
class AchievementManager {
  static const String prefsKey = 'achievements';
  static final AchievementManager _instance = AchievementManager._internal();

  final Map<String, Achievement> achievements = {};
  late SharedPreferences _prefs;

  AchievementManager._internal() {
    _initializeAchievements();
  }

  factory AchievementManager() {
    return _instance;
  }

  /// Initialize all available achievements
  void _initializeAchievements() {
    achievements['first_win'] = Achievement(
      id: 'first_win',
      name: '初勝利',
      description: '初めてゲームに勝利する',
      emoji: '🎉',
    );
    achievements['ten_wins'] = Achievement(
      id: 'ten_wins',
      name: '10勝',
      description: '10ゲーム勝利する',
      emoji: '🏆',
    );
    achievements['fifty_wins'] = Achievement(
      id: 'fifty_wins',
      name: '50勝',
      description: '50ゲーム勝利する',
      emoji: '👑',
    );
    achievements['hundred_wins'] = Achievement(
      id: 'hundred_wins',
      name: '100勝',
      description: '100ゲーム勝利する',
      emoji: '💎',
    );
    achievements['beat_easy'] = Achievement(
      id: 'beat_easy',
      name: 'AI克服：かんたん',
      description: 'かんたんAIに勝つ',
      emoji: '🤖',
    );
    achievements['beat_medium'] = Achievement(
      id: 'beat_medium',
      name: 'AI克服：ふつう',
      description: 'ふつうAIに勝つ',
      emoji: '🧠',
    );
    achievements['beat_hard'] = Achievement(
      id: 'beat_hard',
      name: 'AI克服：つよい',
      description: 'つよいAIに勝つ',
      emoji: '⚡',
    );
    achievements['daily_puzzle'] = Achievement(
      id: 'daily_puzzle',
      name: '今日の1局',
      description: 'デイリーパズルを解く',
      emoji: '🎯',
    );
    achievements['perfect_game'] = Achievement(
      id: 'perfect_game',
      name: 'パーフェクト',
      description: 'ゲームを完璧にプレイ（未実装）',
      emoji: '💯',
    );
    achievements['five_win_streak'] = Achievement(
      id: 'five_win_streak',
      name: '5連勝',
      description: '5ゲーム連続勝利',
      emoji: '🔥',
    );
  }

  /// Load achievements from persistent storage
  Future<void> load(SharedPreferences prefs) async {
    _prefs = prefs;
    final data = prefs.getString(prefsKey);
    if (data != null) {
      try {
        final List decoded = jsonDecode(data);
        for (final item in decoded) {
          final achievement = Achievement.fromJson(item);
          achievements[achievement.id] = achievement;
        }
      } catch (e) {
        // If loading fails, keep defaults
      }
    }
  }

  /// Save achievements to persistent storage
  Future<void> save() async {
    final data = jsonEncode(
      achievements.values.map((a) => a.toJson()).toList(),
    );
    await _prefs.setString(prefsKey, data);
  }

  /// Check and unlock achievements based on game results
  Future<void> checkAndUnlockAchievements({
    required int totalWins,
    required int currentWinStreak,
    required String? aiDifficultyBeaten,
  }) async {
    if (totalWins == 1) unlock('first_win');
    if (totalWins == 10) unlock('ten_wins');
    if (totalWins == 50) unlock('fifty_wins');
    if (totalWins == 100) unlock('hundred_wins');

    if (aiDifficultyBeaten == 'easy') unlock('beat_easy');
    if (aiDifficultyBeaten == 'medium') unlock('beat_medium');
    if (aiDifficultyBeaten == 'hard') unlock('beat_hard');

    if (currentWinStreak == 5) unlock('five_win_streak');

    await save();
  }

  /// Unlock an achievement by id
  void unlock(String id) {
    achievements[id]?.unlock();
  }

  /// Get all unlocked achievements
  List<Achievement> getUnlockedAchievements() {
    return achievements.values.where((a) => a.isUnlocked).toList();
  }

  /// Get unlock progress for an achievement
  double getUnlockProgress(String id) {
    // This would be customized per achievement
    return achievements[id]?.isUnlocked == true ? 1.0 : 0.0;
  }
}
