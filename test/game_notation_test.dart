import 'package:flutter_test/flutter_test.dart';

import 'package:reversia/engine/game_notation.dart';
import 'package:reversia/engine/models.dart';

void main() {
  group('GameNotation', () {
    test('moveToNotation encodes both the origin and destination square', () {
      // Regression test: moveToNotation used to encode only move.to, making
      // the round trip through notationToGame() lossy -- every move was
      // reconstructed with a hardcoded Square(0, 0) origin, silently
      // corrupting any saved game that went through this path.
      const move = Move(Square(2, 1), Square(3, 4));
      expect(GameNotation.moveToNotation(move), 'b3e4');
    });

    test('gameToNotation then notationToGame round-trips a move history exactly', () {
      final moves = [
        const Move(Square(1, 1), Square(2, 1)),
        const Move(Square(4, 1), Square(3, 1)),
        const Move(Square(2, 1), Square(1, 1)),
      ];

      final notation = GameNotation.gameToNotation(moves);
      final roundTripped = GameNotation.notationToGame(notation);

      expect(roundTripped, moves);
    });

    test('GameRecord.toJson then fromJson preserves every move exactly', () {
      final moves = [
        const Move(Square(0, 4), Square(1, 4)),
        const Move(Square(5, 2), Square(4, 2)),
      ];
      final record = GameRecord(
        playerAName: 'A',
        playerBName: 'B',
        moves: moves,
        playedAt: DateTime(2026, 1, 1),
      );

      final roundTripped = GameRecord.fromJson(record.toJson());

      expect(roundTripped.moves, moves);
    });
  });
}
