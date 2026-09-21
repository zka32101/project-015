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

    test(
        'hard AI uses the opening/middlegame search depth on the initial board, not the endgame depth',
        () {
      // Regression test: _endgamePieceThreshold used to be 20, above this
      // game's fixed 18-piece starting total (which only ever decreases),
      // so the hard AI always used the deeper endgame search from move 1.
      final ai = ReversiaAi(AiDifficulty.hard, Random(1));
      final result = ai.pickMoveWithThinking(Board.initial(), Owner.playerA,
          moveNumber: 999); // outside the opening book's range
      expect(result.searchDepth, 4);
    });

    test('hard AI uses the deeper endgame search depth once few pieces remain', () {
      final board = Board.empty();
      board.set(const Square(2, 2),
          const Piece(type: PieceType.king, owner: Owner.playerA, face: Face.front));
      board.set(const Square(5, 5),
          const Piece(type: PieceType.king, owner: Owner.playerB, face: Face.front));

      final ai = ReversiaAi(AiDifficulty.hard, Random(1));
      final result = ai.pickMoveWithThinking(board, Owner.playerA, moveNumber: 999);
      expect(result.searchDepth, 8);
    });

    test(
        'opening book overrides greedy scoring for medium difficulty once moveNumber is supplied',
        () {
      // Regression test: _getMoveNumber() used to estimate the move number
      // from total piece count using an Othello-style model (start at 4
      // pieces, +1/move) that doesn't match this game's 18-piece,
      // capture-only-removes rules, so it never mapped back into the
      // opening book's 1-5 range and the book was permanently unreachable.
      final board = Board.empty();
      board.set(const Square(2, 0),
          const Piece(type: PieceType.normal, owner: Owner.playerA, face: Face.front));
      board.set(const Square(3, 0),
          const Piece(type: PieceType.normal, owner: Owner.playerB, face: Face.front));

      final ai = ReversiaAi(AiDifficulty.medium);

      // Without a supplied moveNumber, the AI has no reliable way to know
      // it's in the opening and falls back to greedy scoring, which
      // strongly prefers the available capture at (2,0)->(3,0).
      final withoutMoveNumber = ai.pickMove(board, Owner.playerA);
      expect(withoutMoveNumber, const Move(Square(2, 0), Square(3, 0)));

      // With moveNumber: 1 (matching OpeningBook's move-1 entries), the AI
      // must consult and take the book move -- (2,0)->(2,1) is listed for
      // move 1 -- even though it's a strictly worse greedy score than the
      // free capture at (3,0). Medium always prefers the book's top move
      // when one is legally available.
      final withMoveNumber = ai.pickMove(board, Owner.playerA, moveNumber: 1);
      expect(withMoveNumber, const Move(Square(2, 0), Square(2, 1)));
    });
  });
}
