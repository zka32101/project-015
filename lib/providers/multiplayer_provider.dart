import 'dart:async';
import 'dart:math' as math;

import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Online battle lobby state
class OnlineLobby {
  final String id;
  final String hostName;
  final String hostAvatarEmoji;
  final int hostRating;
  final String gameMode;
  final int timeLimit;
  final int playerCount;
  final int maxPlayers;
  final DateTime createdAt;
  final bool isRanked;
  final String? password;

  const OnlineLobby({
    required this.id,
    required this.hostName,
    required this.hostAvatarEmoji,
    required this.hostRating,
    required this.gameMode,
    required this.timeLimit,
    required this.playerCount,
    required this.maxPlayers,
    required this.createdAt,
    required this.isRanked,
    this.password,
  });

  bool get isFull => playerCount >= maxPlayers;

  int get waitingSlots => maxPlayers - playerCount;

  Duration get age => DateTime.now().difference(createdAt);

  OnlineLobby copyWith({
    int? playerCount,
  }) {
    return OnlineLobby(
      id: id,
      hostName: hostName,
      hostAvatarEmoji: hostAvatarEmoji,
      hostRating: hostRating,
      gameMode: gameMode,
      timeLimit: timeLimit,
      playerCount: playerCount ?? this.playerCount,
      maxPlayers: maxPlayers,
      createdAt: createdAt,
      isRanked: isRanked,
      password: password,
    );
  }
}

/// Ongoing multiplayer match
class MultiplayerMatch {
  final String id;
  final String player1Name;
  final String player1AvatarEmoji;
  final int player1Rating;
  final String player2Name;
  final String player2AvatarEmoji;
  final int player2Rating;
  final String gameMode;
  final DateTime startedAt;
  final bool isRanked;
  final int moveCount;
  final String currentTurn; // 'player1' or 'player2'
  final double player1Pieces;
  final double player2Pieces;

  const MultiplayerMatch({
    required this.id,
    required this.player1Name,
    required this.player1AvatarEmoji,
    required this.player1Rating,
    required this.player2Name,
    required this.player2AvatarEmoji,
    required this.player2Rating,
    required this.gameMode,
    required this.startedAt,
    required this.isRanked,
    required this.moveCount,
    required this.currentTurn,
    required this.player1Pieces,
    required this.player2Pieces,
  });

  Duration get duration => DateTime.now().difference(startedAt);

  MultiplayerMatch copyWith({
    int? moveCount,
    String? currentTurn,
    double? player1Pieces,
    double? player2Pieces,
  }) {
    return MultiplayerMatch(
      id: id,
      player1Name: player1Name,
      player1AvatarEmoji: player1AvatarEmoji,
      player1Rating: player1Rating,
      player2Name: player2Name,
      player2AvatarEmoji: player2AvatarEmoji,
      player2Rating: player2Rating,
      gameMode: gameMode,
      startedAt: startedAt,
      isRanked: isRanked,
      moveCount: moveCount ?? this.moveCount,
      currentTurn: currentTurn ?? this.currentTurn,
      player1Pieces: player1Pieces ?? this.player1Pieces,
      player2Pieces: player2Pieces ?? this.player2Pieces,
    );
  }
}

/// Completed match result
class MatchResult {
  final String id;
  final String player1Name;
  final String player1AvatarEmoji;
  final String player2Name;
  final String player2AvatarEmoji;
  final String winner;
  final int winnerRatingGain;
  final int loserRatingLoss;
  final DateTime playedAt;
  final int duration;
  final int totalMoves;
  final bool isRanked;
  final String gameMode;

  const MatchResult({
    required this.id,
    required this.player1Name,
    required this.player1AvatarEmoji,
    required this.player2Name,
    required this.player2AvatarEmoji,
    required this.winner,
    required this.winnerRatingGain,
    required this.loserRatingLoss,
    required this.playedAt,
    required this.duration,
    required this.totalMoves,
    required this.isRanked,
    required this.gameMode,
  });

  bool get isWinForPlayer1 => winner == player1Name;

  String get opponentFor(String playerName) =>
      playerName == player1Name ? player2Name : player1Name;
}

/// Multiplayer state
class MultiplayerState {
  final List<OnlineLobby> availableLobbies;
  final MultiplayerMatch? currentMatch;
  final List<MatchResult> matchHistory;
  final bool isSearchingForMatch;
  final bool isLoading;
  final String? error;
  final int onlinePlayersCount;

  const MultiplayerState({
    required this.availableLobbies,
    this.currentMatch,
    required this.matchHistory,
    this.isSearchingForMatch = false,
    this.isLoading = false,
    this.error,
    required this.onlinePlayersCount,
  });

  MultiplayerState copyWith({
    List<OnlineLobby>? availableLobbies,
    MultiplayerMatch? currentMatch,
    List<MatchResult>? matchHistory,
    bool? isSearchingForMatch,
    bool? isLoading,
    String? error,
    int? onlinePlayersCount,
  }) {
    return MultiplayerState(
      availableLobbies: availableLobbies ?? this.availableLobbies,
      currentMatch: currentMatch ?? this.currentMatch,
      matchHistory: matchHistory ?? this.matchHistory,
      isSearchingForMatch: isSearchingForMatch ?? this.isSearchingForMatch,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      onlinePlayersCount: onlinePlayersCount ?? this.onlinePlayersCount,
    );
  }
}

/// Notifier for multiplayer and online battles
class MultiplayerNotifier extends StateNotifier<MultiplayerState> {
  static final List<OnlineLobby> _sampleLobbies = [];
  static final List<MatchResult> _sampleMatches = [];
  final math.Random _random = math.Random();

  MultiplayerNotifier()
      : super(const MultiplayerState(
          availableLobbies: [],
          matchHistory: [],
          onlinePlayersCount: 0,
        )) {
    _initialize();
  }

  void _initialize() {
    _generateSampleLobbies();
    _generateSampleMatches();
    _simulateOnlineCount();
  }

  void _generateSampleLobbies() {
    final now = DateTime.now();
    _sampleLobbies.clear();
    _sampleLobbies.addAll([
      OnlineLobby(
        id: 'lobby_1',
        hostName: 'エキスパート太郎',
        hostAvatarEmoji: '🦅',
        hostRating: 2100,
        gameMode: 'ランク戦',
        timeLimit: 10,
        playerCount: 1,
        maxPlayers: 2,
        createdAt: now.subtract(const Duration(minutes: 2)),
        isRanked: true,
      ),
      OnlineLobby(
        id: 'lobby_2',
        hostName: 'リバーシ花子',
        hostAvatarEmoji: '🌸',
        hostRating: 1850,
        gameMode: 'カジュアル戦',
        timeLimit: 15,
        playerCount: 2,
        maxPlayers: 2,
        createdAt: now.subtract(const Duration(minutes: 5)),
        isRanked: false,
      ),
      OnlineLobby(
        id: 'lobby_3',
        hostName: '勝利の戦士',
        hostAvatarEmoji: '⚔️',
        hostRating: 1700,
        gameMode: 'ランク戦',
        timeLimit: 5,
        playerCount: 1,
        maxPlayers: 2,
        createdAt: now.subtract(const Duration(minutes: 3)),
        isRanked: true,
      ),
      OnlineLobby(
        id: 'lobby_4',
        hostName: 'スーパー次郎',
        hostAvatarEmoji: '🌟',
        hostRating: 1600,
        gameMode: 'トレーニング',
        timeLimit: 30,
        playerCount: 1,
        maxPlayers: 4,
        createdAt: now.subtract(const Duration(minutes: 8)),
        isRanked: false,
      ),
    ]);

    state = state.copyWith(
      availableLobbies: List.from(_sampleLobbies),
      onlinePlayersCount: 24,
    );
  }

  void _generateSampleMatches() {
    final now = DateTime.now();
    _sampleMatches.clear();
    _sampleMatches.addAll([
      MatchResult(
        id: 'match_1',
        player1Name: 'エリート太郎',
        player1AvatarEmoji: '🦅',
        player2Name: 'リバーシ花子',
        player2AvatarEmoji: '🌸',
        winner: 'エリート太郎',
        winnerRatingGain: 18,
        loserRatingLoss: 18,
        playedAt: now.subtract(const Duration(hours: 2)),
        duration: 420,
        totalMoves: 58,
        isRanked: true,
        gameMode: 'ランク戦',
      ),
      MatchResult(
        id: 'match_2',
        player1Name: '勝利の戦士',
        player1AvatarEmoji: '⚔️',
        player2Name: 'スーパー次郎',
        player2AvatarEmoji: '🌟',
        winner: 'スーパー次郎',
        winnerRatingGain: 24,
        loserRatingLoss: 24,
        playedAt: now.subtract(const Duration(hours: 5)),
        duration: 380,
        totalMoves: 55,
        isRanked: true,
        gameMode: 'ランク戦',
      ),
      MatchResult(
        id: 'match_3',
        player1Name: 'リバーシマスター',
        player1AvatarEmoji: '👑',
        player2Name: '強敵なり',
        player2AvatarEmoji: '🐉',
        winner: 'リバーシマスター',
        winnerRatingGain: 15,
        loserRatingLoss: 15,
        playedAt: now.subtract(const Duration(hours: 12)),
        duration: 450,
        totalMoves: 60,
        isRanked: true,
        gameMode: 'ランク戦',
      ),
    ]);

    state = state.copyWith(matchHistory: List.from(_sampleMatches));
  }

  void _simulateOnlineCount() {
    final count = 15 + _random.nextInt(35);
    state = state.copyWith(onlinePlayersCount: count);
  }

  Future<void> refreshLobbies() async {
    state = state.copyWith(isLoading: true);
    await Future.delayed(const Duration(milliseconds: 500));

    _generateSampleLobbies();
    state = state.copyWith(isLoading: false);
  }

  Future<void> joinLobby(String lobbyId) async {
    state = state.copyWith(isLoading: true);
    await Future.delayed(const Duration(seconds: 1));

    final lobby = state.availableLobbies
        .firstWhere((l) => l.id == lobbyId, orElse: () => throw 'Lobby not found');

    // Simulate match starting
    final now = DateTime.now();
    final match = MultiplayerMatch(
      id: 'match_${DateTime.now().millisecondsSinceEpoch}',
      player1Name: lobby.hostName,
      player1AvatarEmoji: lobby.hostAvatarEmoji,
      player1Rating: lobby.hostRating,
      player2Name: 'あなた',
      player2AvatarEmoji: '🎮',
      player2Rating: 1500,
      gameMode: lobby.gameMode,
      startedAt: now,
      isRanked: lobby.isRanked,
      moveCount: 0,
      currentTurn: 'player1',
      player1Pieces: 2,
      player2Pieces: 2,
    );

    state = state.copyWith(
      currentMatch: match,
      isLoading: false,
    );
  }

  Future<void> startQuickMatch() async {
    state = state.copyWith(isSearchingForMatch: true);
    await Future.delayed(const Duration(seconds: 2));

    final now = DateTime.now();
    final opponents = ['エリート太郎', 'リバーシ花子', '勝利の戦士', 'スーパー次郎'];
    final emojis = ['🦅', '🌸', '⚔️', '🌟'];
    final ratings = [2100, 1850, 1700, 1600];

    final index = _random.nextInt(opponents.length);

    final match = MultiplayerMatch(
      id: 'match_${DateTime.now().millisecondsSinceEpoch}',
      player1Name: opponents[index],
      player1AvatarEmoji: emojis[index],
      player1Rating: ratings[index],
      player2Name: 'あなた',
      player2AvatarEmoji: '🎮',
      player2Rating: 1500,
      gameMode: 'ランク戦',
      startedAt: now,
      isRanked: true,
      moveCount: 0,
      currentTurn: 'player1',
      player1Pieces: 2,
      player2Pieces: 2,
    );

    state = state.copyWith(
      currentMatch: match,
      isSearchingForMatch: false,
    );
  }

  void updateMatchState({
    required int moveCount,
    required String currentTurn,
    required double player1Pieces,
    required double player2Pieces,
  }) {
    if (state.currentMatch == null) return;

    state = state.copyWith(
      currentMatch: state.currentMatch!.copyWith(
        moveCount: moveCount,
        currentTurn: currentTurn,
        player1Pieces: player1Pieces,
        player2Pieces: player2Pieces,
      ),
    );
  }

  Future<void> endMatch({
    required String winner,
    required int winnerRatingGain,
    required int loserRatingLoss,
  }) async {
    if (state.currentMatch == null) return;

    final match = state.currentMatch!;
    final result = MatchResult(
      id: match.id,
      player1Name: match.player1Name,
      player1AvatarEmoji: match.player1AvatarEmoji,
      player2Name: match.player2Name,
      player2AvatarEmoji: match.player2AvatarEmoji,
      winner: winner,
      winnerRatingGain: winnerRatingGain,
      loserRatingLoss: loserRatingLoss,
      playedAt: DateTime.now(),
      duration: match.duration.inSeconds,
      totalMoves: match.moveCount,
      isRanked: match.isRanked,
      gameMode: match.gameMode,
    );

    final updatedHistory = [result, ...state.matchHistory];
    state = state.copyWith(
      currentMatch: null,
      matchHistory: updatedHistory,
    );
  }

  void exitMatch() {
    state = state.copyWith(currentMatch: null);
  }

  void clearError() {
    state = state.copyWith(error: null);
  }
}

/// Riverpod provider for multiplayer functionality
final multiplayerProvider =
    StateNotifierProvider<MultiplayerNotifier, MultiplayerState>(
  (ref) => MultiplayerNotifier(),
);
