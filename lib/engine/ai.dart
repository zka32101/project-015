import 'dart:async';
import 'dart:math';

import 'ai_evaluator.dart';
import 'ai_thinking_info.dart';
import 'board.dart';
import 'models.dart';
import 'move_generator.dart';

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
          searchDepth: _hardSearchDepth,
          thinkingTime: thinkingTime,
        );
    }
  }

  Move _pickEasy(Board board, Owner owner, List<Move> moves) {
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
    Move? best;
    var bestScore = -_infinity;
    for (final move in moves) {
      final childBoard = _applyToBoard(board, move, owner);
      final score = -_negamax(
        childBoard,
        owner.opponent,
        _hardSearchDepth - 1,
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

  /// Minimax with thinking that returns both move and evaluation score.
  Map<String, Object?> _pickMinimaxWithThinking(Board board, Owner owner, List<Move> moves) {
    Move? best;
    var bestScore = -_infinity;
    for (final move in moves) {
      final childBoard = _applyToBoard(board, move, owner);
      final score = -_negamax(
        childBoard,
        owner.opponent,
        _hardSearchDepth - 1,
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
