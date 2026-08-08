enum Owner { playerA, playerB }

enum PieceType { normal, king }

enum Face { front, back }

extension FaceX on Face {
  Face get flipped => this == Face.front ? Face.back : Face.front;
}

extension OwnerX on Owner {
  Owner get opponent => this == Owner.playerA ? Owner.playerB : Owner.playerA;
}

class Piece {
  final PieceType type;
  final Owner owner;
  final Face face;

  const Piece({required this.type, required this.owner, required this.face});

  Piece copyWith({Owner? owner, Face? face}) => Piece(
        type: type,
        owner: owner ?? this.owner,
        face: type == PieceType.king ? Face.front : (face ?? this.face),
      );

  @override
  String toString() =>
      '${owner == Owner.playerA ? 'A' : 'B'}${type == PieceType.king ? 'K' : (face == Face.front ? 'f' : 'b')}';
}

class Square {
  final int row;
  final int col;
  const Square(this.row, this.col);

  bool get onBoard => row >= 0 && row < 6 && col >= 0 && col < 6;

  @override
  bool operator ==(Object other) =>
      other is Square && other.row == row && other.col == col;
  @override
  int get hashCode => row * 6 + col;
  @override
  String toString() => '($row,$col)';
}

class Move {
  final Square from;
  final Square to;
  const Move(this.from, this.to);

  @override
  bool operator ==(Object other) =>
      other is Move && other.from == from && other.to == to;
  @override
  int get hashCode => Object.hash(from, to);
  @override
  String toString() => '$from->$to';
}

enum GameResult { ongoing, playerAWins, playerBWins, draw }
