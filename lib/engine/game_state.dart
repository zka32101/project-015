import 'board.dart';
import 'models.dart';

const int repetitionLimit = 3;
const int plyLimit = 60;

class GameState {
  Board board;
  Owner turn;
  int plyCount = 0;
  GameResult result = GameResult.ongoing;
  final Map<String, int> _positionCounts = {};

  /// Every move applied so far, in order (Section3 Must#5 "対局リプレイ").
  /// Moves alternate strictly starting with playerA, so the mover for
  /// moveHistory[i] is playerA when i is even, playerB when i is odd.
  final List<Move> moveHistory = [];

  GameState._(this.board, this.turn) {
    _recordPosition();
  }

  factory GameState.initial() => GameState._(Board.initial(), Owner.playerA);

  bool get isOver => result != GameResult.ongoing;

  /// Not specified in the design doc: if the side to move has zero legal
  /// moves, that side loses. Call this when MoveGenerator.legalMovesFor
  /// returns an empty list for [turn]. (Assumption flagged for design review.)
  void declareNoMovesLoss() {
    if (isOver) return;
    result = turn == Owner.playerA ? GameResult.playerBWins : GameResult.playerAWins;
  }

  void _recordPosition() {
    final key = '${board.positionKey}|$turn';
    _positionCounts[key] = (_positionCounts[key] ?? 0) + 1;
  }

  /// Applies [move] for the current side to move. Caller must ensure the move
  /// is legal (see MoveGenerator.legalMovesFor).
  void applyMove(Move move) {
    if (isOver) {
      throw StateError('Game already finished');
    }
    final mover = turn;
    final piece = board.at(move.from);
    if (piece == null || piece.owner != mover) {
      throw ArgumentError('No movable piece for $mover at ${move.from}');
    }

    final target = board.at(move.to);
    moveHistory.add(move);
    board.set(move.from, null);

    if (target != null) {
      // target.owner must be the opponent (own-piece destinations are illegal moves).
      if (target.type == PieceType.king) {
        board.set(move.to, piece.type == PieceType.king
            ? piece
            : piece.copyWith(face: piece.face.flipped));
        result =
            mover == Owner.playerA ? GameResult.playerAWins : GameResult.playerBWins;
        return;
      }
      // Non-king capture: the captured piece converts to mover's side and flips.
      board.set(move.to, target.copyWith(owner: mover, face: target.face.flipped));
    } else {
      board.set(move.to,
          piece.type == PieceType.king ? piece : piece.copyWith(face: piece.face.flipped));
    }

    turn = mover.opponent;
    plyCount++;

    final key = '${board.positionKey}|$turn';
    final count = (_positionCounts[key] ?? 0) + 1;
    _positionCounts[key] = count;
    if (count >= repetitionLimit) {
      // The side that just moved caused the position to repeat -> loses.
      result = mover == Owner.playerA ? GameResult.playerBWins : GameResult.playerAWins;
      return;
    }

    if (plyCount >= plyLimit) {
      final aCount = board.pieceCount(Owner.playerA);
      final bCount = board.pieceCount(Owner.playerB);
      if (aCount > bCount) {
        result = GameResult.playerAWins;
      } else if (bCount > aCount) {
        result = GameResult.playerBWins;
      } else {
        result = GameResult.draw;
      }
    }
  }
}
