import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../engine/ai.dart';
import '../engine/ai_thinking_info.dart';
import '../engine/game_notation.dart';
import '../engine/game_state.dart';
import '../engine/game_undo_redo.dart';
import '../engine/models.dart';
import '../engine/move_analyzer.dart';
import '../engine/move_generator.dart';
import '../engine/rank.dart';
import '../engine/statistics.dart';

/// The AI, when enabled, always controls playerB.
const aiControlledOwner = Owner.playerB;
const rankPointsPrefsKey = 'rank_points';
const gameStatisticsPrefsKey = 'game_statistics';

class GameViewState {
  final GameState game;
  final Square? selected;
  final List<Square> legalDestinations;
  final Move? lastMove;
  final AiDifficulty? aiDifficulty;
  final bool showThreatPreview;
  final int rankPoints;
  final GameStatistics statistics;
  final bool isAiThinking;
  final AiMoveResult? aiThinkingInfo;

  const GameViewState({
    required this.game,
    this.selected,
    this.legalDestinations = const [],
    this.lastMove,
    this.aiDifficulty,
    this.showThreatPreview = false,
    this.rankPoints = 0,
    GameStatistics? statistics,
    this.isAiThinking = false,
    this.aiThinkingInfo,
  }) : statistics = statistics ?? GameStatistics();

  /// Squares the side NOT currently to move could land on next turn --
  /// design doc v1.1 "透け読みモード" (opponent-threat preview), toggle-able.
  List<Square> get opponentThreatSquares {
    if (!showThreatPreview || game.isOver) return const [];
    return MoveGenerator.legalMovesFor(game.board, game.turn.opponent)
        .map((m) => m.to)
        .toSet()
        .toList();
  }

  /// Threatened squares that specifically hold the side-to-move's own king --
  /// the "your king is in danger" subset, worth a stronger warning than a
  /// plain threatened square.
  List<Square> get kingThreatSquares {
    return opponentThreatSquares.where((sq) {
      final piece = game.board.at(sq);
      return piece != null && piece.type == PieceType.king && piece.owner == game.turn;
    }).toList();
  }

  /// Both endpoints of the most recently applied move, for a subtle "what
  /// just happened" highlight on the board.
  Set<Square> get lastMoveSquares =>
      lastMove == null ? const {} : {lastMove!.from, lastMove!.to};

  GameViewState copyWith({
    Square? selected,
    bool clearSelected = false,
    List<Square>? legalDestinations,
    Move? lastMove,
    bool clearLastMove = false,
    AiDifficulty? aiDifficulty,
    bool clearAiDifficulty = false,
    bool? showThreatPreview,
    int? rankPoints,
    GameStatistics? statistics,
    bool? isAiThinking,
    AiMoveResult? aiThinkingInfo,
    bool clearAiThinkingInfo = false,
  }) {
    return GameViewState(
      game: game,
      selected: clearSelected ? null : (selected ?? this.selected),
      legalDestinations: legalDestinations ?? this.legalDestinations,
      lastMove: clearLastMove ? null : (lastMove ?? this.lastMove),
      aiDifficulty:
          clearAiDifficulty ? null : (aiDifficulty ?? this.aiDifficulty),
      showThreatPreview: showThreatPreview ?? this.showThreatPreview,
      rankPoints: rankPoints ?? this.rankPoints,
      statistics: statistics ?? this.statistics,
      isAiThinking: isAiThinking ?? this.isAiThinking,
      aiThinkingInfo: clearAiThinkingInfo ? null : (aiThinkingInfo ?? this.aiThinkingInfo),
    );
  }

  GameViewState _carryMeta(GameState newGame, {Move? lastMove}) {
    return GameViewState(
      game: newGame,
      lastMove: lastMove,
      aiDifficulty: aiDifficulty,
      showThreatPreview: showThreatPreview,
      rankPoints: rankPoints,
      statistics: statistics,
      aiThinkingInfo: aiThinkingInfo,
    );
  }
}

/// Drives a single match: selection, legal-move highlighting, applying moves
/// against the pure GameState engine, and (when an AI difficulty is set)
/// auto-playing playerB's turns.
class GameViewModel extends Notifier<GameViewState> {
  bool _winRecordedThisGame = false;
  bool _gameStatsRecordedThisGame = false;
  late GameUndoRedoManager _undoRedoManager;

  @override
  GameViewState build() {
    _loadRankPoints();
    _loadStatistics();
    final gameState = GameState.initial();
    _undoRedoManager = GameUndoRedoManager(gameState);
    return GameViewState(game: gameState);
  }

  Future<void> _loadRankPoints() async {
    final prefs = await SharedPreferences.getInstance();
    final points = prefs.getInt(rankPointsPrefsKey) ?? 0;
    state = state.copyWith(rankPoints: points);
  }

  Future<void> _loadStatistics() async {
    final prefs = await SharedPreferences.getInstance();
    final statsJson = prefs.getString(gameStatisticsPrefsKey);
    if (statsJson != null) {
      try {
        final Map<String, dynamic> decoded = jsonDecode(statsJson);
        final stats = GameStatistics.fromJson(decoded);
        state = state.copyWith(statistics: stats);
      } catch (e) {
        // If deserialization fails, start fresh
        state = state.copyWith(statistics: GameStatistics());
      }
    }
  }

  Future<void> _saveStatistics() async {
    final prefs = await SharedPreferences.getInstance();
    final statsJson = jsonEncode(state.statistics.toJson());
    await prefs.setString(gameStatisticsPrefsKey, statsJson);
  }

  void selectSquare(Square square) {
    final s = state;
    if (s.game.isOver) return;
    if (s.aiDifficulty != null && s.game.turn == aiControlledOwner) return;

    final piece = s.game.board.at(square);

    // Tapping a legal destination while a piece is selected -> move.
    if (s.selected != null && s.legalDestinations.contains(square)) {
      final move = Move(s.selected!, square);
      s.game.applyMove(move);
      // Clear redo history when a new move is made
      _undoRedoManager.clearRedoHistory();
      state = s._carryMeta(s.game, lastMove: move);
      _autoFailIfNoMoves();
      _maybeRecordAiWin();
      _maybeScheduleAiMove();
      return;
    }

    // Tapping own piece -> (re)select it.
    if (piece != null && piece.owner == s.game.turn) {
      final dests = MoveGenerator.destinationsFor(s.game.board, square);
      state = s.copyWith(
        selected: square,
        legalDestinations: dests,
      );
      return;
    }

    // Tapping anything else -> clear selection.
    state = s.copyWith(clearSelected: true, legalDestinations: const []);
  }

  void setAiDifficulty(AiDifficulty? difficulty) {
    if (difficulty == null) {
      state = state.copyWith(clearAiDifficulty: true);
      return;
    }
    state = state.copyWith(aiDifficulty: difficulty);
    _maybeScheduleAiMove();
  }

  void setShowThreatPreview(bool value) {
    state = state.copyWith(showThreatPreview: value);
  }

  void restart() {
    _winRecordedThisGame = false;
    _gameStatsRecordedThisGame = false;
    final newGameState = GameState.initial();
    _undoRedoManager = GameUndoRedoManager(newGameState);
    state = state._carryMeta(newGameState);
    _maybeScheduleAiMove();
  }

  void _autoFailIfNoMoves() {
    final s = state;
    if (s.game.isOver) return;
    if (MoveGenerator.legalMovesFor(s.game.board, s.game.turn).isEmpty) {
      s.game.declareNoMovesLoss();
      state = s._carryMeta(s.game, lastMove: s.lastMove);
      _maybeRecordGameStatistics();
    }
  }

  /// Record game statistics (wins, losses, streaks) for completed games.
  void _maybeRecordGameStatistics() {
    if (_gameStatsRecordedThisGame) return;
    final s = state;
    if (!s.game.isOver) return;

    _gameStatsRecordedThisGame = true;
    final difficulty = s.aiDifficulty;
    s.statistics.recordGame(
      result: s.game.result,
      aiDifficultyLabel: difficulty?.name,
    );
    state = s.copyWith(statistics: s.statistics);
    _saveStatistics();
  }

  /// Persists rank-ladder points the first (and only the first) time a given
  /// match ends in a playerA victory over the AI (Section5 "段位制"). Beating
  /// a harder AI is worth more points (see rank.dart).
  void _maybeRecordAiWin() {
    if (_winRecordedThisGame) return;
    final s = state;
    if (s.aiDifficulty == null) return;
    if (s.game.result != GameResult.playerAWins) return;

    _winRecordedThisGame = true;
    final newPoints = s.rankPoints + rankPointsForWin(s.aiDifficulty!);
    state = s.copyWith(rankPoints: newPoints);
    SharedPreferences.getInstance().then((prefs) {
      prefs.setInt(rankPointsPrefsKey, newPoints);
    });

    // Also record game statistics
    _maybeRecordGameStatistics();
  }

  void _maybeScheduleAiMove() {
    final difficulty = state.aiDifficulty;
    if (difficulty == null) return;
    if (state.game.isOver || state.game.turn != aiControlledOwner) return;

    // Show thinking indicator
    state = state.copyWith(isAiThinking: true);

    Future.delayed(const Duration(milliseconds: 500), () {
      final s = state;
      if (s.game.isOver || s.game.turn != aiControlledOwner) return;
      if (s.aiDifficulty == null) return;

      final ai = ReversiaAi(s.aiDifficulty!);
      final result = ai.pickMoveWithThinking(s.game.board, aiControlledOwner);
      final move = result.move;

      if (move == null) {
        s.game.declareNoMovesLoss();
        state = s._carryMeta(s.game, lastMove: s.lastMove)
            .copyWith(isAiThinking: false, aiThinkingInfo: result);
        _maybeRecordGameStatistics();
        return;
      }

      s.game.applyMove(move);
      _undoRedoManager.clearRedoHistory();
      state = s._carryMeta(s.game, lastMove: move)
          .copyWith(isAiThinking: false, aiThinkingInfo: result);
      _autoFailIfNoMoves();
      _maybeRecordAiWin();
    });
  }

  /// Calculate which squares would be affected by a move (for preview).
  /// Returns a list of squares whose pieces would flip/change.
  List<Square> getAffectedSquares(Move move) {
    final board = state.game.board;
    final piece = board.at(move.from);
    if (piece == null) return const [];

    final affected = <Square>[];
    final target = board.at(move.to);

    // The source square is always affected (piece moves from here)
    affected.add(move.from);

    // The destination square is always affected (piece moves here or captures here)
    affected.add(move.to);

    return affected;
  }

  /// Get the undo/redo manager for the current game
  GameUndoRedoManager? getUndoRedoManager() => _undoRedoManager;

  /// Whether the last move can be undone
  bool get canUndo => _undoRedoManager.canUndo;

  /// Whether a move can be redone
  bool get canRedo => _undoRedoManager.canRedo;

  /// Number of moves that can be undone
  int get undoCount => _undoRedoManager.undoCount;

  /// Number of moves that can be redone
  int get redoCount => _undoRedoManager.redoCount;

  /// Undo the last move
  void undoLastMove() {
    final s = state;
    if (!_undoRedoManager.canUndo) return;

    if (_undoRedoManager.undo()) {
      final previousMove = s.game.moveHistory.length >= 1 ? s.game.moveHistory.last : null;
      state = s._carryMeta(s.game, lastMove: previousMove);
    }
  }

  /// Redo the last undone move
  void redoLastMove() {
    final s = state;
    if (!_undoRedoManager.canRedo) return;

    if (_undoRedoManager.redo()) {
      final lastMove = s.game.moveHistory.isNotEmpty ? s.game.moveHistory.last : null;
      state = s._carryMeta(s.game, lastMove: lastMove);
    }
  }

  /// Undo multiple moves
  void undoMultipleMoves(int count) {
    final s = state;
    final undone = _undoRedoManager.undoMultiple(count);
    if (undone > 0) {
      final previousMove = s.game.moveHistory.length >= 1 ? s.game.moveHistory.last : null;
      state = s._carryMeta(s.game, lastMove: previousMove);
    }
  }

  /// Redo multiple moves
  void redoMultipleMoves(int count) {
    final s = state;
    final redone = _undoRedoManager.redoMultiple(count);
    if (redone > 0) {
      final lastMove = s.game.moveHistory.isNotEmpty ? s.game.moveHistory.last : null;
      state = s._carryMeta(s.game, lastMove: lastMove);
    }
  }

  /// Undo all moves to the initial position
  void undoAllMoves() {
    final s = state;
    final undone = _undoRedoManager.undoAll();
    if (undone > 0) {
      state = s._carryMeta(s.game, lastMove: null);
    }
  }

  /// Redo all undone moves
  void redoAllMoves() {
    final s = state;
    final redone = _undoRedoManager.redoAll();
    if (redone > 0) {
      final lastMove = s.game.moveHistory.isNotEmpty ? s.game.moveHistory.last : null;
      state = s._carryMeta(s.game, lastMove: lastMove);
    }
  }

  /// Get detailed analysis of all legal moves for current position
  List<MoveAnalysis> getMoveAnalysis() {
    return MoveAnalyzer.analyzeMoves(state.game.board, state.game.turn);
  }

  /// Get the top N best moves with analysis
  List<MoveAnalysis> getTopMovesSuggestions(int count) {
    return MoveAnalyzer.getTopMoves(state.game.board, state.game.turn, count);
  }

  /// Get strategic advice for the current position
  String getStrategicAdvice() {
    return MoveAnalyzer.getStrategicAdvice(state.game.board, state.game.turn);
  }

  /// Get analysis for a specific move
  MoveAnalysis? analyzeMoveSpecific(Move move) {
    final analyses = getMoveAnalysis();
    try {
      return analyses.firstWhere(
        (a) => a.move.from == move.from && a.move.to == move.to,
      );
    } catch (_) {
      return null;
    }
  }

  /// Get the current game in standard notation format
  String getGameNotation() {
    return GameNotation.gameToNotation(state.game.moveHistory);
  }

  /// Get formatted move history for display
  String getFormattedMoveHistory() {
    return GameNotation.formatMoveHistory(state.game.moveHistory);
  }

  /// Get current game state description
  String getGameStateDescription() {
    return GameNotation.getBoardStateDescription(
      state.game.moveHistory.length,
      state.game.moveHistory.length + 10, // Estimate based on typical game length
    );
  }

  /// Create a game record for storage/replay
  GameRecord createGameRecord() {
    final playerBName = state.aiDifficulty != null
        ? 'AI (${state.aiDifficulty!.name})'
        : 'Player B';

    return GameRecord(
      playerAName: 'Player A (You)',
      playerBName: playerBName,
      aiDifficulty: state.aiDifficulty?.name,
      moves: state.game.moveHistory,
      playedAt: DateTime.now(),
      result: state.game.isOver ? _getGameResultString() : null,
      duration: null, // Could track if we store start time
    );
  }

  String _getGameResultString() {
    switch (state.game.result) {
      case GameResult.playerAWins:
        final pieceCountA = state.game.board.pieceCount(Owner.playerA);
        final pieceCountB = state.game.board.pieceCount(Owner.playerB);
        return 'Player A (Black) wins $pieceCountA-$pieceCountB';
      case GameResult.playerBWins:
        final pieceCountA = state.game.board.pieceCount(Owner.playerA);
        final pieceCountB = state.game.board.pieceCount(Owner.playerB);
        return 'Player B (White) wins $pieceCountB-$pieceCountA';
      case GameResult.draw:
        return 'Draw';
      case GameResult.inProgress:
        return 'In progress';
      default:
        return 'Unknown result';
    }
  }
}

final gameViewModelProvider =
    NotifierProvider<GameViewModel, GameViewState>(GameViewModel.new);
