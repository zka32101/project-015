import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../engine/ai.dart';
import '../engine/game_state.dart';
import '../engine/models.dart';
import '../engine/move_generator.dart';
import '../engine/rank.dart';

/// The AI, when enabled, always controls playerB.
const aiControlledOwner = Owner.playerB;
const rankPointsPrefsKey = 'rank_points';

class GameViewState {
  final GameState game;
  final Square? selected;
  final List<Square> legalDestinations;
  final Move? lastMove;
  final AiDifficulty? aiDifficulty;
  final bool showThreatPreview;
  final int rankPoints;

  const GameViewState({
    required this.game,
    this.selected,
    this.legalDestinations = const [],
    this.lastMove,
    this.aiDifficulty,
    this.showThreatPreview = false,
    this.rankPoints = 0,
  });

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
    );
  }

  GameViewState _carryMeta(GameState newGame, {Move? lastMove}) {
    return GameViewState(
      game: newGame,
      lastMove: lastMove,
      aiDifficulty: aiDifficulty,
      showThreatPreview: showThreatPreview,
      rankPoints: rankPoints,
    );
  }
}

/// Drives a single match: selection, legal-move highlighting, applying moves
/// against the pure GameState engine, and (when an AI difficulty is set)
/// auto-playing playerB's turns.
class GameViewModel extends Notifier<GameViewState> {
  bool _winRecordedThisGame = false;

  @override
  GameViewState build() {
    _loadRankPoints();
    return GameViewState(game: GameState.initial());
  }

  Future<void> _loadRankPoints() async {
    final prefs = await SharedPreferences.getInstance();
    final points = prefs.getInt(rankPointsPrefsKey) ?? 0;
    state = state.copyWith(rankPoints: points);
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
    state = state._carryMeta(GameState.initial());
    _maybeScheduleAiMove();
  }

  void _autoFailIfNoMoves() {
    final s = state;
    if (s.game.isOver) return;
    if (MoveGenerator.legalMovesFor(s.game.board, s.game.turn).isEmpty) {
      s.game.declareNoMovesLoss();
      state = s._carryMeta(s.game, lastMove: s.lastMove);
    }
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
  }

  void _maybeScheduleAiMove() {
    final difficulty = state.aiDifficulty;
    if (difficulty == null) return;
    if (state.game.isOver || state.game.turn != aiControlledOwner) return;

    Future.delayed(const Duration(milliseconds: 500), () {
      final s = state;
      if (s.game.isOver || s.game.turn != aiControlledOwner) return;
      if (s.aiDifficulty == null) return;

      final ai = ReversiaAi(s.aiDifficulty!);
      final move = ai.pickMove(s.game.board, aiControlledOwner);
      if (move == null) {
        s.game.declareNoMovesLoss();
        state = s._carryMeta(s.game, lastMove: s.lastMove);
        return;
      }
      s.game.applyMove(move);
      state = s._carryMeta(s.game, lastMove: move);
      _autoFailIfNoMoves();
      _maybeRecordAiWin();
    });
  }
}

final gameViewModelProvider =
    NotifierProvider<GameViewModel, GameViewState>(GameViewModel.new);
