import 'package:flutter_test/flutter_test.dart';

import 'package:reversia/engine/game_state.dart';
import 'package:reversia/engine/game_undo_redo.dart';
import 'package:reversia/engine/models.dart';

void main() {
  group('GameState.resetAndReplay', () {
    // A short, non-repeating, non-capturing sequence on the real initial
    // board: A's (1,1) piece steps out to the empty (1,0) and B's (4,1)
    // piece steps out to the empty (4,0). Neither move captures, so this
    // is safe to replay repeatedly without hitting the ply/repetition
    // limits on its own.
    final moves = const [
      Move(Square(1, 1), Square(1, 0)),
      Move(Square(4, 1), Square(4, 0)),
    ];

    test('replaying the same moves twice reaches the same state as once', () {
      final once = GameState.initial()..resetAndReplay(moves);
      final twice = GameState.initial()
        ..resetAndReplay(moves)
        ..resetAndReplay(moves);

      expect(twice.board.positionKey, once.board.positionKey);
      expect(twice.turn, once.turn);
      expect(twice.plyCount, once.plyCount);
      expect(twice.moveHistory.length, once.moveHistory.length);
      expect(twice.result, GameResult.ongoing);
    });

    test(
        'repeated calls do not leak position counts across replays into a false repetition loss',
        () {
      // Regression test: resetAndReplay used to be implemented by replaying
      // moves through the *same* long-lived GameState without clearing its
      // private position-count map (see GameUndoRedoManager's old
      // _reconstructGameState), so every call kept incrementing counts for
      // the exact same handful of positions. Since this replays the
      // identical sequence from the identical starting point every time,
      // an unfixed implementation would falsely trigger the repetitionLimit
      // (3) by the 3rd call even though the live game only actually visited
      // each position once per call.
      final gameState = GameState.initial();
      for (var i = 0; i < 5; i++) {
        gameState.resetAndReplay(moves);
        expect(gameState.result, GameResult.ongoing,
            reason: 'resetAndReplay call #${i + 1} should not end the game');
      }
    });
  });

  group('GameUndoRedoManager', () {
    test('undo does not falsely trigger a repetition loss', () {
      final gameState = GameState.initial();
      final manager = GameUndoRedoManager(gameState);

      // Play a short non-repeating sequence.
      gameState.applyMove(const Move(Square(1, 1), Square(1, 0)));
      gameState.applyMove(const Move(Square(4, 1), Square(4, 0)));
      gameState.applyMove(const Move(Square(1, 0), Square(1, 1)));

      expect(gameState.result, GameResult.ongoing);

      // Repeatedly undo and redo the last move. A real player doing this
      // does not cause the game to end; the fixed undo() must not leak
      // stale position counts that would eventually cross repetitionLimit.
      for (var i = 0; i < 5; i++) {
        expect(manager.undo(), isTrue);
        expect(gameState.result, GameResult.ongoing,
            reason: 'undo() should never end the game on its own');
        expect(manager.redo(), isTrue);
      }

      expect(gameState.result, GameResult.ongoing);
      expect(gameState.moveHistory.length, 3);
    });

    test('undo followed by a fresh move reflects only the shorter history', () {
      final gameState = GameState.initial();
      final manager = GameUndoRedoManager(gameState);

      gameState.applyMove(const Move(Square(1, 1), Square(1, 0)));
      gameState.applyMove(const Move(Square(4, 1), Square(4, 0)));

      expect(manager.undo(), isTrue);
      expect(gameState.moveHistory.length, 1);
      expect(gameState.turn, Owner.playerB);

      // Making a genuinely new move after undo (rather than redoing the
      // undone one) must clear the stale redo entry and extend the
      // now-shorter history normally.
      manager.clearRedoHistory();
      gameState.applyMove(const Move(Square(4, 1), Square(4, 0)));

      expect(manager.canRedo, isFalse);
      expect(gameState.moveHistory.length, 2);
      expect(gameState.result, GameResult.ongoing);
    });
  });
}
