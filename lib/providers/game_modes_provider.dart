import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Game mode type
enum GameModeType {
  classic('クラシック'),
  blitz('ブリッツ'),
  puzzle('パズル'),
  survival('サバイバル'),
  timeAttack('タイムアタック'),
  endless('エンドレス');

  final String label;
  const GameModeType(this.label);
}

/// Game mode configuration
class GameMode {
  final GameModeType type;
  final String name;
  final String description;
  final String emoji;
  final int? timeLimit; // seconds
  final bool hasScoring;
  final String difficulty; // Easy, Normal, Hard, Expert
  final int minPlayers;
  final int maxPlayers;
  final String rules;
  final int bestScore;
  final DateTime? bestScoreDate;
  final int totalPlayed;
  final int highestLevel;

  const GameMode({
    required this.type,
    required this.name,
    required this.description,
    required this.emoji,
    this.timeLimit,
    this.hasScoring = true,
    this.difficulty = 'Normal',
    this.minPlayers = 1,
    this.maxPlayers = 2,
    this.rules = '',
    this.bestScore = 0,
    this.bestScoreDate,
    this.totalPlayed = 0,
    this.highestLevel = 1,
  });

  GameMode copyWith({
    GameModeType? type,
    String? name,
    String? description,
    String? emoji,
    int? timeLimit,
    bool? hasScoring,
    String? difficulty,
    int? minPlayers,
    int? maxPlayers,
    String? rules,
    int? bestScore,
    DateTime? bestScoreDate,
    int? totalPlayed,
    int? highestLevel,
  }) {
    return GameMode(
      type: type ?? this.type,
      name: name ?? this.name,
      description: description ?? this.description,
      emoji: emoji ?? this.emoji,
      timeLimit: timeLimit ?? this.timeLimit,
      hasScoring: hasScoring ?? this.hasScoring,
      difficulty: difficulty ?? this.difficulty,
      minPlayers: minPlayers ?? this.minPlayers,
      maxPlayers: maxPlayers ?? this.maxPlayers,
      rules: rules ?? this.rules,
      bestScore: bestScore ?? this.bestScore,
      bestScoreDate: bestScoreDate ?? this.bestScoreDate,
      totalPlayed: totalPlayed ?? this.totalPlayed,
      highestLevel: highestLevel ?? this.highestLevel,
    );
  }
}

/// Game modes state
class GameModesState {
  final List<GameMode> availableModes;
  final GameMode? selectedMode;
  final int totalModesPlayed;
  final bool isLoading;
  final String? error;

  const GameModesState({
    required this.availableModes,
    this.selectedMode,
    this.totalModesPlayed = 0,
    this.isLoading = false,
    this.error,
  });

  /// Copy with modifications
  GameModesState copyWith({
    List<GameMode>? availableModes,
    GameMode? selectedMode,
    int? totalModesPlayed,
    bool? isLoading,
    String? error,
  }) {
    return GameModesState(
      availableModes: availableModes ?? this.availableModes,
      selectedMode: selectedMode ?? this.selectedMode,
      totalModesPlayed: totalModesPlayed ?? this.totalModesPlayed,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

/// Notifier for game modes
class GameModesNotifier extends StateNotifier<GameModesState> {
  SharedPreferences? _prefs;

  GameModesNotifier()
      : super(_buildInitialState()) {
    _initializeModes();
  }

  /// Initialize modes
  Future<void> _initializeModes() async {
    final prefs = await SharedPreferences.getInstance();
    _prefs = prefs;
    _generateGameModes();
    state = state.copyWith(
      totalModesPlayed: prefs.getInt('total_modes_played') ?? 0,
    );
  }

  /// Build initial state
  static GameModesState _buildInitialState() {
    return const GameModesState(
      availableModes: [],
      totalModesPlayed: 0,
    );
  }

  /// Generate game modes
  void _generateGameModes() {
    final modes = [
      GameMode(
        type: GameModeType.classic,
        name: 'クラシック',
        description: '標準的なリバーシゲーム',
        emoji: '♟️',
        difficulty: 'Normal',
        hasScoring: true,
        minPlayers: 1,
        maxPlayers: 2,
        rules: '標準的なリバーシのルールに従います。駒を挟んで返します。',
        bestScore: 45,
        totalPlayed: 243,
        highestLevel: 12,
      ),
      GameMode(
        type: GameModeType.blitz,
        name: 'ブリッツ',
        description: 'パッパッと対局。制限時間付き。',
        emoji: '⚡',
        timeLimit: 60, // 60 seconds per game
        difficulty: 'Hard',
        hasScoring: true,
        minPlayers: 1,
        maxPlayers: 2,
        rules: '1分間以内に最高スコアを目指します。時間内に多く獲得してください。',
        bestScore: 52,
        totalPlayed: 89,
        highestLevel: 8,
      ),
      GameMode(
        type: GameModeType.puzzle,
        name: 'パズル',
        description: 'ルールに従って正解を見つける。',
        emoji: '🧩',
        difficulty: 'Expert',
        hasScoring: true,
        minPlayers: 1,
        maxPlayers: 1,
        rules: '各レベルの最適な手を見つけます。',
        bestScore: 100,
        totalPlayed: 156,
        highestLevel: 45,
      ),
      GameMode(
        type: GameModeType.survival,
        name: 'サバイバル',
        description: 'AIに勝ち続ける。何連勝できる？',
        emoji: '🎯',
        difficulty: 'Hard',
        hasScoring: true,
        minPlayers: 1,
        maxPlayers: 1,
        rules: 'AIに連勝するモード。負けたらゲームオーバー。',
        bestScore: 12, // 12 consecutive wins
        totalPlayed: 34,
        highestLevel: 12,
      ),
      GameMode(
        type: GameModeType.timeAttack,
        name: 'タイムアタック',
        description: '5分で最高スコアを狙え。',
        emoji: '⏱️',
        timeLimit: 300, // 5 minutes
        difficulty: 'Hard',
        hasScoring: true,
        minPlayers: 1,
        maxPlayers: 1,
        rules: '5分間でできるだけ多くの勝利を目指します。',
        bestScore: 18, // 18 wins in 5 minutes
        totalPlayed: 42,
        highestLevel: 5,
      ),
      GameMode(
        type: GameModeType.endless,
        name: 'エンドレス',
        description: 'ノーストレス。無限にプレイ。',
        emoji: '∞',
        difficulty: 'Easy',
        hasScoring: false,
        minPlayers: 1,
        maxPlayers: 2,
        rules: '無制限にプレイできます。ハイスコアは記録されません。',
        bestScore: 0,
        totalPlayed: 567,
        highestLevel: 1,
      ),
    ];

    state = state.copyWith(availableModes: modes);
  }

  /// Select a game mode
  Future<void> selectMode(GameMode mode) async {
    state = state.copyWith(selectedMode: mode);
  }

  /// Record mode completion
  Future<void> recordModeCompletion(
    GameModeType modeType,
    int score,
    int level,
  ) async {
    try {
      final updatedModes = state.availableModes.map((mode) {
        if (mode.type == modeType) {
          int newBestScore = score > mode.bestScore ? score : mode.bestScore;
          int newHighestLevel =
              level > mode.highestLevel ? level : mode.highestLevel;

          return mode.copyWith(
            bestScore: newBestScore,
            bestScoreDate: DateTime.now(),
            totalPlayed: mode.totalPlayed + 1,
            highestLevel: newHighestLevel,
          );
        }
        return mode;
      }).toList();

      final newTotal = state.totalModesPlayed + 1;
      final prefs = _prefs ??= await SharedPreferences.getInstance();
      await prefs.setInt('total_modes_played', newTotal);

      state = state.copyWith(
        availableModes: updatedModes,
        totalModesPlayed: newTotal,
      );
    } catch (e) {
      state = state.copyWith(error: 'Failed to record completion: $e');
    }
  }

  /// Reset mode statistics
  Future<void> resetModeStats(GameModeType modeType) async {
    try {
      final updatedModes = state.availableModes.map((mode) {
        if (mode.type == modeType) {
          return mode.copyWith(
            bestScore: 0,
            bestScoreDate: null,
            totalPlayed: 0,
            highestLevel: 1,
          );
        }
        return mode;
      }).toList();

      state = state.copyWith(availableModes: updatedModes);
    } catch (e) {
      state = state.copyWith(error: 'Failed to reset stats: $e');
    }
  }
}

/// Riverpod provider for game modes
final gameModesProvider =
    StateNotifierProvider<GameModesNotifier, GameModesState>(
  (ref) => GameModesNotifier(),
);

/// Alternative sync provider (for testing)
final gameModesSyncProvider =
    StateNotifierProvider<GameModesNotifier, GameModesState>((ref) {
  throw UnimplementedError();
});
