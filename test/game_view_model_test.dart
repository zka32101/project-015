import 'package:flutter_test/flutter_test.dart';
import 'package:reversia/engine/board.dart';
import 'package:reversia/engine/game_state.dart';
import 'package:reversia/engine/models.dart';
import 'package:reversia/viewmodels/game_view_model.dart';

/// Builds a GameViewState wrapping a hand-crafted board, bypassing
/// GameState.initial() so scenarios (like "king in danger") can be set up
/// directly -- mirrors the _stateWith helper in engine_test.dart.
GameState _stateWithBoard(Board board, Owner turn) {
  final state = GameState.initial();
  state.board = board;
  state.turn = turn;
  return state;
}

void main() {
  group('GameViewState.kingThreatSquares', () {
    test('flags the side-to-move own king when threat preview is on and it is reachable', () {
      final board = Board.empty();
      board.set(const Square(3, 3),
          const Piece(type: PieceType.king, owner: Owner.playerA, face: Face.front));
      board.set(const Square(3, 4),
          const Piece(type: PieceType.normal, owner: Owner.playerB, face: Face.front));
      final game = _stateWithBoard(board, Owner.playerA);

      final viewState = GameViewState(game: game, showThreatPreview: true);

      expect(viewState.kingThreatSquares, contains(const Square(3, 3)));
      expect(viewState.opponentThreatSquares, contains(const Square(3, 3)));
    });

    test('is empty when threat preview is off, even if the king is reachable', () {
      final board = Board.empty();
      board.set(const Square(3, 3),
          const Piece(type: PieceType.king, owner: Owner.playerA, face: Face.front));
      board.set(const Square(3, 4),
          const Piece(type: PieceType.normal, owner: Owner.playerB, face: Face.front));
      final game = _stateWithBoard(board, Owner.playerA);

      final viewState = GameViewState(game: game, showThreatPreview: false);

      expect(viewState.kingThreatSquares, isEmpty);
      expect(viewState.opponentThreatSquares, isEmpty);
    });

    test('does not flag a threatened square that only holds a non-king piece', () {
      final board = Board.empty();
      board.set(const Square(3, 3),
          const Piece(type: PieceType.normal, owner: Owner.playerA, face: Face.front));
      board.set(const Square(3, 4),
          const Piece(type: PieceType.normal, owner: Owner.playerB, face: Face.front));
      final game = _stateWithBoard(board, Owner.playerA);

      final viewState = GameViewState(game: game, showThreatPreview: true);

      expect(viewState.kingThreatSquares, isEmpty);
      expect(viewState.opponentThreatSquares, contains(const Square(3, 3)));
    });
  });
}
