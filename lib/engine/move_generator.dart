import 'board.dart';
import 'models.dart';

const _orthogonal = [
  [-1, 0],
  [1, 0],
  [0, -1],
  [0, 1],
];

const _diagonal2 = [
  [-2, -2],
  [-2, 2],
  [2, -2],
  [2, 2],
];

const _kingDirs = [
  [-1, 0],
  [1, 0],
  [0, -1],
  [0, 1],
  [-1, -1],
  [-1, 1],
  [1, -1],
  [1, 1],
];

class MoveGenerator {
  /// Legal destination squares for the piece at [from], given current [board].
  static List<Square> destinationsFor(Board board, Square from) {
    final piece = board.at(from);
    if (piece == null) return const [];

    final dirs = piece.type == PieceType.king
        ? _kingDirs
        : (piece.face == Face.front ? _orthogonal : _diagonal2);

    final results = <Square>[];
    for (final d in dirs) {
      final to = Square(from.row + d[0], from.col + d[1]);
      if (!to.onBoard) continue;

      // Diagonal-2 (back face) cannot jump over an occupied intermediate square.
      if (piece.type == PieceType.normal && piece.face == Face.back) {
        final mid = Square(from.row + d[0] ~/ 2, from.col + d[1] ~/ 2);
        if (board.at(mid) != null) continue;
      }

      final target = board.at(to);
      if (target != null && target.owner == piece.owner) continue; // own piece blocks
      results.add(to);
    }
    return results;
  }

  static List<Move> legalMovesFor(Board board, Owner owner) {
    final moves = <Move>[];
    for (var r = 0; r < 6; r++) {
      for (var c = 0; c < 6; c++) {
        final from = Square(r, c);
        final piece = board.at(from);
        if (piece == null || piece.owner != owner) continue;
        for (final to in destinationsFor(board, from)) {
          moves.add(Move(from, to));
        }
      }
    }
    return moves;
  }
}
