import 'models.dart';

class Board {
  final List<List<Piece?>> grid;

  Board._(this.grid);

  factory Board.initial() {
    final grid = List.generate(6, (_) => List<Piece?>.filled(6, null));

    void placeBackRow(int row, Owner owner) {
      for (var col = 0; col < 6; col++) {
        grid[row][col] =
            Piece(type: PieceType.normal, owner: owner, face: Face.front);
      }
    }

    void placeSecondRow(int row, Owner owner) {
      grid[row][1] =
          Piece(type: PieceType.normal, owner: owner, face: Face.front);
      grid[row][2] = Piece(type: PieceType.king, owner: owner, face: Face.front);
      grid[row][3] =
          Piece(type: PieceType.normal, owner: owner, face: Face.front);
    }

    placeBackRow(0, Owner.playerA);
    placeSecondRow(1, Owner.playerA);
    placeSecondRow(4, Owner.playerB);
    placeBackRow(5, Owner.playerB);

    return Board._(grid);
  }

  factory Board.empty() =>
      Board._(List.generate(6, (_) => List<Piece?>.filled(6, null)));

  Piece? at(Square s) => grid[s.row][s.col];

  Board clone() =>
      Board._(grid.map((row) => List<Piece?>.from(row)).toList());

  void set(Square s, Piece? piece) {
    grid[s.row][s.col] = piece;
  }

  int pieceCount(Owner owner) {
    var count = 0;
    for (final row in grid) {
      for (final p in row) {
        if (p != null && p.owner == owner) count++;
      }
    }
    return count;
  }

  bool hasKing(Owner owner) {
    for (final row in grid) {
      for (final p in row) {
        if (p != null && p.owner == owner && p.type == PieceType.king) {
          return true;
        }
      }
    }
    return false;
  }

  /// Stable string key for repetition detection (board contents only, turn appended by caller).
  String get positionKey {
    final buf = StringBuffer();
    for (var r = 0; r < 6; r++) {
      for (var c = 0; c < 6; c++) {
        final p = grid[r][c];
        buf.write(p == null ? '.' : p.toString());
        buf.write(',');
      }
    }
    return buf.toString();
  }
}
