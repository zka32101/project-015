import 'dart:math';

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
  static const int _hardSearchDepth = 3;

  ReversiaAi(this.difficulty, [Random? random]) : random = random ?? Random();

  Move? pickMove(Board board, Owner owner) {
    final moves = MoveGenerator.legalMovesFor(board, owner);
    if (moves.isEmpty) return null;

    switch (difficulty) {
      case AiDifficulty.easy:
        return moves[random.nextInt(moves.length)];
      case AiDifficulty.medium:
        return _pickGreedy(board, owner, moves);
      case AiDifficulty.hard:
        return _pickMinimax(board, owner, moves);
    }
  }

  Move _pickGreedy(Board board, Owner owner, List<Move> moves) {
    final kingCapture = moves.where((m) {
      final target = board.at(m.to);
      return target != null && target.owner != owner && target.type == PieceType.king;
    });
    if (kingCapture.isNotEmpty) return kingCapture.first;

    final captures = moves.where((m) {
      final target = board.at(m.to);
      return target != null && target.owner != owner;
    }).toList();
    if (captures.isNotEmpty) return captures[random.nextInt(captures.length)];

    return moves[random.nextInt(moves.length)];
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
    final mine = board.pieceCount(owner);
    final theirs = board.pieceCount(owner.opponent);
    return (mine - theirs) * 10;
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
