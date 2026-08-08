import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:reversia/engine/ai.dart';
import 'package:reversia/engine/board.dart';
import 'package:reversia/engine/models.dart';
import 'package:reversia/engine/move_generator.dart';

void main() {
  group('ReversiaAi', () {
    test('easy/medium/hard all return a legal move for the initial position', () {
      for (final difficulty in AiDifficulty.values) {
        final ai = ReversiaAi(difficulty, Random(1));
        final board = Board.initial();
        final move = ai.pickMove(board, Owner.playerA);
        expect(move, isNotNull);
        final legal = MoveGenerator.legalMovesFor(board, Owner.playerA);
        expect(legal.map((m) => m.toString()), contains(move.toString()));
      }
    });

    test('returns null when the side has no pieces on the board at all', () {
      final board = Board.empty();
      board.set(const Square(5, 5),
          const Piece(type: PieceType.king, owner: Owner.playerB, face: Face.front));
      final ai = ReversiaAi(AiDifficulty.hard);
      expect(ai.pickMove(board, Owner.playerA), isNull);
    });

    test('medium always takes an immediately available king-capture win', () {
      final board = Board.empty();
      board.set(const Square(3, 3),
          const Piece(type: PieceType.normal, owner: Owner.playerA, face: Face.front));
      board.set(const Square(3, 4),
          const Piece(type: PieceType.king, owner: Owner.playerB, face: Face.front));
      // A distracting non-capturing move must not be chosen instead.
      board.set(const Square(0, 0),
          const Piece(type: PieceType.normal, owner: Owner.playerA, face: Face.front));

      final ai = ReversiaAi(AiDifficulty.medium, Random(7));
      final move = ai.pickMove(board, Owner.playerA);
      expect(move, const Move(Square(3, 3), Square(3, 4)));
    });

    test('hard avoids a move that hands over the king next turn when a safe move exists', () {
      // Player A's king at (3,3) is only threatened via the front-face move
      // from B's piece at (3,4); moving the king to (2,3) escapes, while
      // leaving it at (3,3) (i.e. moving a spare piece) walks into capture.
      final board = Board.empty();
      board.set(const Square(3, 3),
          const Piece(type: PieceType.king, owner: Owner.playerA, face: Face.front));
      board.set(const Square(3, 4),
          const Piece(type: PieceType.normal, owner: Owner.playerB, face: Face.front));
      board.set(const Square(0, 0),
          const Piece(type: PieceType.normal, owner: Owner.playerA, face: Face.front));
      // B needs its own king present so hasKing() checks reflect a real game;
      // tucked away where it can't reach either of A's pieces this ply.
      board.set(const Square(5, 5),
          const Piece(type: PieceType.king, owner: Owner.playerB, face: Face.front));

      final ai = ReversiaAi(AiDifficulty.hard);
      final move = ai.pickMove(board, Owner.playerA);
      // Moving the spare piece at (0,0) leaves the king capturable; hard
      // should not do that when the king can instead move to safety.
      expect(move!.from, const Square(3, 3));
    });

    test('hard also takes an immediately available king-capture win', () {
      // Regression test for the AI's internal search simulation: it must
      // treat capturing the enemy king as removing it (game over), not as
      // converting it into an extra piece for the mover.
      final board = Board.empty();
      board.set(const Square(3, 3),
          const Piece(type: PieceType.normal, owner: Owner.playerA, face: Face.front));
      board.set(const Square(3, 4),
          const Piece(type: PieceType.king, owner: Owner.playerB, face: Face.front));
      board.set(const Square(0, 0),
          const Piece(type: PieceType.king, owner: Owner.playerA, face: Face.front));

      final ai = ReversiaAi(AiDifficulty.hard);
      final move = ai.pickMove(board, Owner.playerA);
      expect(move, const Move(Square(3, 3), Square(3, 4)));
    });
  });
}
