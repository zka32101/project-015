import 'dart:async';
import 'dart:math';

import 'ai_evaluator.dart';
import 'ai_thinking_info.dart';
import 'board.dart';
import 'models.dart';
import 'move_generator.dart';
import 'opening_book.dart';

enum AiDifficulty { easy, medium, hard }

/// A single AI policy covering all three difficulty tiers (Section3 Must#2).
/// - easy: uniform random legal move.
/// - medium: greedy 1-ply -- always takes a king-capture win, otherwise
///   prefers converting the most enemy material, otherwise random.
/// - hard: minimax with alpha-beta pruning, shallow fixed depth (fast enough
///   for a 6x6 board with a handful of pieces per side).
class ReversiaAi {
  final AiDifficulty difficulty;
  final Random random;
  static const int _hardSearchDepth = 4;
  static const int _endgameSearchDepth = 8;  // Deeper search in endgame
  static const int _endgamePieceThreshold = 20;  // Activate endgame when ≤20 total pieces

  ReversiaAi(this.difficulty, [Random? random]) : random = random ?? Random();

  Move? pickMove(Board board, Owner owner) {
    final moves = MoveGenerator.legalMovesFor(board, owner);
    if (moves.isEmpty) return null;

    switch (difficulty) {
      case AiDifficulty.easy:
        return _pickEasy(board, owner, moves);
      case AiDifficulty.medium:
        return _pickGreedy(board, owner, moves);
      case AiDifficulty.hard:
        return _pickMinimax(board, owner, moves);
    }
  }

  /// Picks a move and returns detailed thinking information including
  /// evaluation score and search depth. Useful for displaying AI thinking.
  AiMoveResult pickMoveWithThinking(Board board, Owner owner) {
    final startTime = DateTime.now();
    final moves = MoveGenerator.legalMovesFor(board, owner);

    if (moves.isEmpty) {
      final thinkingTime = DateTime.now().difference(startTime);
      return AiMoveResult(
        move: null,
        evaluationScore: null,
        searchDepth: 0,
        thinkingTime: thinkingTime,
      );
    }

    switch (difficulty) {
      case AiDifficulty.easy:
        final move = _pickEasy(board, owner, moves);
        final thinkingTime = DateTime.now().difference(startTime);
        final score = move != null
            ? AiStrategy.evaluateMoveEasy(board, move, owner)
            : null;
        return AiMoveResult(
          move: move,
          evaluationScore: score,
          searchDepth: 1,
          thinkingTime: thinkingTime,
        );

      case AiDifficulty.medium:
        final move = _pickGreedy(board, owner, moves);
        final thinkingTime = DateTime.now().difference(startTime);
        final score = move != null
            ? AiStrategy.evaluateMoveMedium(board, move, owner)
            : null;
        return AiMoveResult(
          move: move,
          evaluationScore: score,
          searchDepth: 1,
          thinkingTime: thinkingTime,
        );

      case AiDifficulty.hard:
        final result = _pickMinimaxWithThinking(board, owner, moves);
        final thinkingTime = DateTime.now().difference(startTime);
        return AiMoveResult(
          move: result['move'] as Move?,
          evaluationScore: result['score'] as int?,
          searchDepth: result['depth'] as int? ?? _hardSearchDepth,
          thinkingTime: thinkingTime,
        );
    }
  }

  Move _pickEasy(Board board, Owner owner, List<Move> moves) {
    // In opening, give 50% chance to use opening book (helps easy AI learn openings)
    final moveNumber = _getMoveNumber(board);
    if (OpeningBook.isInOpeningBook(moveNumber) && random.nextDouble() < 0.5) {
      final bookMove = _selectOpeningMove(moves, moveNumber);
      if (bookMove != null) {
        return bookMove;
      }
    }

    // Easy: 80% random, 20% smart (prefer captures)
    if (random.nextDouble() < 0.8) {
      return moves[random.nextInt(moves.length)];
    }

    // 20% of the time, make a slightly smarter move
    Move? bestMove;
    var bestScore = -100;

    for (final move in moves) {
      final score = AiStrategy.evaluateMoveEasy(board, move, owner);
      if (score > bestScore) {
        bestScore = score;
        bestMove = move;
      }
    }

    return bestMove ?? moves[random.nextInt(moves.length)];
  }

  Move _pickGreedy(Board board, Owner owner, List<Move> moves) {
    // Check opening book for early game moves (medium AI always prefers book moves)
    final moveNumber = _getMoveNumber(board);
    if (OpeningBook.isInOpeningBook(moveNumber)) {
      final bookMove = _selectOpeningMove(moves, moveNumber);
      if (bookMove != null) {
        return bookMove;
      }
    }

    // Use advanced evaluator for greedy move selection
    Move? bestMove;
    var bestScore = -9999;

    for (final move in moves) {
      final score = AiStrategy.evaluateMoveMedium(board, move, owner);
      if (score > bestScore) {
        bestScore = score;
        bestMove = move;
      }
    }

    return bestMove ?? moves[random.nextInt(moves.length)];
  }

  Move _pickMinimax(Board board, Owner owner, List<Move> moves) {
    // Check opening book for early game moves
    final moveNumber = _getMoveNumber(board);
    if (OpeningBook.isInOpeningBook(moveNumber)) {
      final bookMove = _selectOpeningMove(moves, moveNumber);
      if (bookMove != null) {
        return bookMove;
      }
    }

    // Determine search depth based on game phase
    final depth = _getSearchDepth(board);

    Move? best;
    var bestScore = -_infinity;
    for (final move in moves) {
      final childBoard = _applyToBoard(board, move, owner);
      final score = -_negamax(
        childBoard,
        owner.opponent,
        depth - 1,
        -_infinity,
        _infinity,
      );
      if (score > bestScore) {
        bestScore = score;
        best = move;
      }
    }
    return best ?? moves[random.nextInt(moves.length)];
  }

  /// Determine search depth based on game phase (endgame vs opening/middlegame).
  /// Endgame uses deeper search for more optimal play when fewer pieces remain.
  int _getSearchDepth(Board board) {
    final totalPieces = board.pieceCount(Owner.playerA) + board.pieceCount(Owner.playerB);

    // Endgame: when 20 or fewer pieces remain, search deeper for optimal play
    if (totalPieces <= _endgamePieceThreshold) {
      return _endgameSearchDepth;
    }

    // Opening/middlegame: standard search depth
    return _hardSearchDepth;
  }

  /// Calculate the move number in the game (1-based, counting full moves).
  /// Counts total pieces minus initial 4 setup pieces, divided by 2 for turns per player.
  int _getMoveNumber(Board board) {
    final totalPieces = board.pieceCount(Owner.playerA) + board.pieceCount(Owner.playerB);
    // In 6x6 Reversia: start with 4 pieces (2 per player)
    // Each move by one player adds 1 piece (captures convert opponent pieces)
    // moveHistory.length gives us the number of moves made so far
    return board.moveHistory.length + 1;
  }

  /// Select a move from the opening book if available.
  /// Prefers highest-strength moves but picks randomly among strong options.
  Move? _selectOpeningMove(List<Move> legalMoves, int moveNumber) {
    final bookMoves = OpeningBook.getOpeningMoves(moveNumber);
    if (bookMoves.isEmpty) return null;

    // Filter book moves to only legal moves in current position
    final validBookMoves = bookMoves
        .where((bookMove) => legalMoves.any((legal) =>
            legal.from == bookMove.from && legal.to == bookMove.to))
        .toList();

    if (validBookMoves.isEmpty) return null;

    // For medium difficulty, pick strongest. For hard, add some randomness.
    if (difficulty == AiDifficulty.medium) {
      return validBookMoves.first; // Best move
    } else {
      // Hard: 70% pick strongest, 30% pick random strong move
      if (random.nextDouble() < 0.7) {
        return validBookMoves.first;
      } else {
        return validBookMoves[random.nextInt(validBookMoves.length)];
      }
    }
  }

  /// Minimax with thinking that returns both move and evaluation score.
  Map<String, Object?> _pickMinimaxWithThinking(Board board, Owner owner, List<Move> moves) {
    // Check opening book for early game moves
    final moveNumber = _getMoveNumber(board);
    if (OpeningBook.isInOpeningBook(moveNumber)) {
      final bookMove = _selectOpeningMove(moves, moveNumber);
      if (bookMove != null) {
        return {
          'move': bookMove,
          'score': null,  // Opening book moves don't have evaluation scores
          'depth': 1,     // Treat as shallow lookup
        };
      }
    }

    // Determine search depth based on game phase
    final depth = _getSearchDepth(board);

    Move? best;
    var bestScore = -_infinity;
    for (final move in moves) {
      final childBoard = _applyToBoard(board, move, owner);
      final score = -_negamax(
        childBoard,
        owner.opponent,
        depth - 1,
        -_infinity,
        _infinity,
      );
      if (score > bestScore) {
        bestScore = score;
        best = move;
      }
    }
    final finalMove = best ?? moves[random.nextInt(moves.length)];
    return {
      'move': finalMove,
      'score': bestScore == -_infinity ? null : bestScore,
      'depth': depth,  // Return actual search depth used
    };
  }

  static const _infinity = 1 << 20;

  int _negamax(Board board, Owner owner, int depth, int alpha, int beta) {
    if (!board.hasKing(owner)) return -_infinity;
    if (!board.hasKing(owner.opponent)) return _infinity;
    if (depth == 0) return _evaluate(board, owner);

    final moves = MoveGenerator.legalMovesFor(board, owner);
    if (moves.isEmpty) return -_infinity; // no legal moves -> loss

    var value = -_infinity;
    for (final move in moves) {
      final childBoard = _applyToBoard(board, move, owner);
      final score = -_negamax(childBoard, owner.opponent, depth - 1, -beta, -alpha);
      if (score > value) value = score;
      if (value > alpha) alpha = value;
      if (alpha >= beta) break;
    }
    return value;
  }

  int _evaluate(Board board, Owner owner) {
    // Use advanced strategic evaluation for minimax
    return AiStrategy.evaluateBoardHard(board, owner);
  }

  /// Applies [move] to a clone of [board] and returns the clone -- used for
  /// search only, never mutates repetition/ply history (that belongs to
  /// GameState, not to this lookahead). Mirrors GameState.applyMove's rules
  /// exactly: capturing a king removes it (game-over), capturing a normal
  /// piece converts it. Getting this wrong wouldn't currently change any AI
  /// decision (the hasKing() check at the top of _negamax short-circuits
  /// before a converted "ghost king" could ever be read back out), but a
  /// mismatch here is a landmine for any future change to that ordering.
  Board _applyToBoard(Board board, Move move, Owner mover) {
    final b = board.clone();
    final piece = b.at(move.from)!;
    final target = b.at(move.to);
    b.set(move.from, null);
    if (target != null && target.type == PieceType.king) {
      b.set(move.to, piece.type == PieceType.king ? piece : piece.copyWith(face: piece.face.flipped));
    } else if (target != null) {
      b.set(move.to, target.copyWith(owner: mover, face: target.face.flipped));
    } else {
      b.set(move.to,
          piece.type == PieceType.king ? piece : piece.copyWith(face: piece.face.flipped));
    }
    return b;
  }
}
