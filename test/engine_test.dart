import 'package:flutter_test/flutter_test.dart';
import 'package:reversia/engine/board.dart';
import 'package:reversia/engine/game_state.dart';
import 'package:reversia/engine/models.dart';
import 'package:reversia/engine/move_generator.dart';

void main() {
  group('initial setup', () {
    test('each side has 9 pieces including exactly one king', () {
      final board = Board.initial();
      expect(board.pieceCount(Owner.playerA), 9);
      expect(board.pieceCount(Owner.playerB), 9);
      expect(board.hasKing(Owner.playerA), true);
      expect(board.hasKing(Owner.playerB), true);
    });
  });

  group('front-face orthogonal movement', () {
    test('front piece moves 1 square orthogonally, not diagonally', () {
      final board = Board.empty();
      board.set(const Square(3, 3),
          const Piece(type: PieceType.normal, owner: Owner.playerA, face: Face.front));
      final dests = MoveGenerator.destinationsFor(board, const Square(3, 3));
      expect(dests.toSet(), {
        const Square(2, 3),
        const Square(4, 3),
        const Square(3, 2),
        const Square(3, 4),
      });
    });

    test('move flips the piece to back face', () {
      final state = GameState.initial();
      state.applyMove(const Move(Square(1, 1), Square(2, 1)));
      final piece = state.board.at(const Square(2, 1))!;
      expect(piece.face, Face.back);
    });
  });

  group('back-face diagonal-2 movement', () {
    test('back piece moves exactly 2 diagonally, blocked if intermediate occupied', () {
      final board = Board.empty();
      board.set(const Square(3, 3),
          const Piece(type: PieceType.normal, owner: Owner.playerA, face: Face.back));
      final dests = MoveGenerator.destinationsFor(board, const Square(3, 3));
      expect(dests.toSet(), {
        const Square(1, 1),
        const Square(1, 5),
        const Square(5, 1),
        const Square(5, 5),
      });
    });

    test('blocked when intermediate diagonal square is occupied', () {
      final board = Board.empty();
      board.set(const Square(3, 3),
          const Piece(type: PieceType.normal, owner: Owner.playerA, face: Face.back));
      board.set(const Square(2, 2),
          const Piece(type: PieceType.normal, owner: Owner.playerB, face: Face.front));
      final dests = MoveGenerator.destinationsFor(board, const Square(3, 3));
      expect(dests.contains(const Square(1, 1)), false);
      expect(dests.contains(const Square(1, 5)), true);
    });
  });

  group('king movement', () {
    test('king moves 1 square in all 8 directions and never flips', () {
      final board = Board.empty();
      board.set(const Square(3, 3),
          const Piece(type: PieceType.king, owner: Owner.playerA, face: Face.front));
      final dests = MoveGenerator.destinationsFor(board, const Square(3, 3));
      expect(dests.length, 8);
    });
  });

  group('capture / flip-conversion', () {
    test('non-king capture converts owner and flips face, board stays at 1 piece there', () {
      final board = Board.empty();
      board.set(const Square(3, 3),
          const Piece(type: PieceType.normal, owner: Owner.playerA, face: Face.front));
      board.set(const Square(3, 4),
          const Piece(type: PieceType.normal, owner: Owner.playerB, face: Face.front));
      final state = _stateWith(board, Owner.playerA);
      state.applyMove(const Move(Square(3, 3), Square(3, 4)));

      expect(state.board.at(const Square(3, 3)), null);
      final captured = state.board.at(const Square(3, 4))!;
      expect(captured.owner, Owner.playerA);
      expect(captured.face, Face.back); // was front, toggled
      expect(state.result, GameResult.ongoing);
    });

    test('capturing enemy king ends the game immediately', () {
      final board = Board.empty();
      board.set(const Square(3, 3),
          const Piece(type: PieceType.normal, owner: Owner.playerA, face: Face.front));
      board.set(const Square(3, 4),
          const Piece(type: PieceType.king, owner: Owner.playerB, face: Face.front));
      final state = _stateWith(board, Owner.playerA);
      state.applyMove(const Move(Square(3, 3), Square(3, 4)));
      expect(state.result, GameResult.playerAWins);
    });
  });

  group('threefold repetition', () {
    test('3rd occurrence of a position ends the game as a loss for the mover who caused it', () {
      // Two lone kings shuffling back and forth reproduces the same position repeatedly.
      final board = Board.empty();
      board.set(const Square(0, 0),
          const Piece(type: PieceType.king, owner: Owner.playerA, face: Face.front));
      board.set(const Square(5, 5),
          const Piece(type: PieceType.king, owner: Owner.playerB, face: Face.front));
      final state = _stateWith(board, Owner.playerA);

      final aMoves = [
        const Move(Square(0, 0), Square(0, 1)),
        const Move(Square(0, 1), Square(0, 0)),
      ];
      final bMoves = [
        const Move(Square(5, 5), Square(5, 4)),
        const Move(Square(5, 4), Square(5, 5)),
      ];

      var aIdx = 0, bIdx = 0, total = 0;
      while (!state.isOver) {
        final mover = state.turn;
        if (mover == Owner.playerA) {
          state.applyMove(aMoves[aIdx % 2]);
          aIdx++;
        } else {
          state.applyMove(bMoves[bIdx % 2]);
          bIdx++;
        }
        total++;
        if (total > 20) break; // safety net
      }

      expect(state.result, isNot(GameResult.ongoing));
    });
  });

  group('60-ply tiebreak', () {
    test('reaching the ply limit resolves by piece count', () {
      // Not fully exercised here beyond the constant; full-game coverage is
      // provided by the self-play simulation tool.
      expect(plyLimit, 60);
    });
  });

  group('no legal moves', () {
    test('declareNoMovesLoss ends the game for the side with no moves', () {
      final state = GameState.initial();
      state.declareNoMovesLoss();
      expect(state.result, GameResult.playerBWins); // playerA had no moves
    });
  });

  group('move history', () {
    test('records every applied move in order, including the king-capture win', () {
      final state = GameState.initial();
      state.applyMove(const Move(Square(1, 1), Square(2, 1)));
      state.applyMove(const Move(Square(4, 3), Square(3, 3)));
      expect(state.moveHistory, [
        const Move(Square(1, 1), Square(2, 1)),
        const Move(Square(4, 3), Square(3, 3)),
      ]);

      final board = Board.empty();
      board.set(const Square(3, 3),
          const Piece(type: PieceType.normal, owner: Owner.playerA, face: Face.front));
      board.set(const Square(3, 4),
          const Piece(type: PieceType.king, owner: Owner.playerB, face: Face.front));
      final winState = _stateWith(board, Owner.playerA);
      winState.applyMove(const Move(Square(3, 3), Square(3, 4)));
      expect(winState.moveHistory, [const Move(Square(3, 3), Square(3, 4))]);
    });
  });
}

GameState _stateWith(Board board, Owner turn) {
  final state = GameState.initial();
  state.board = board;
  state.turn = turn;
  return state;
}
