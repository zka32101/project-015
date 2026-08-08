import 'package:flutter_test/flutter_test.dart';
import 'package:reversia/engine/game_state.dart';
import 'package:reversia/engine/models.dart';
import 'package:reversia/engine/move_generator.dart';
import 'package:reversia/engine/puzzle.dart';

GameState _stateFor(Puzzle puzzle) {
  final state = GameState.initial();
  state.board = puzzle.buildBoard();
  state.turn = puzzle.solverOwner;
  return state;
}

void main() {
  group('daily puzzle data integrity', () {
    for (final puzzle in dailyPuzzles) {
      test('${puzzle.id}: solutionMove is legal and wins immediately', () {
        final state = _stateFor(puzzle);
        final legal = MoveGenerator.legalMovesFor(state.board, puzzle.solverOwner);
        expect(legal, contains(puzzle.solutionMove),
            reason: 'solutionMove must be a legal move for solverOwner');

        state.applyMove(puzzle.solutionMove);
        final expectedResult =
            puzzle.solverOwner == Owner.playerA ? GameResult.playerAWins : GameResult.playerBWins;
        expect(state.result, expectedResult,
            reason: 'solutionMove must capture the opponent king immediately');
      });

      test('${puzzle.id}: at least one other legal move exists and does not win', () {
        final state = _stateFor(puzzle);
        final legal = MoveGenerator.legalMovesFor(state.board, puzzle.solverOwner);
        final decoyMoves = legal.where((m) => m != puzzle.solutionMove).toList();
        expect(decoyMoves, isNotEmpty,
            reason: 'a puzzle with only one legal move at all is not a real choice');

        for (final decoy in decoyMoves) {
          final decoyState = _stateFor(puzzle);
          decoyState.applyMove(decoy);
          expect(decoyState.result, GameResult.ongoing,
              reason: 'decoy move $decoy must not also win the puzzle');
        }
      });
    }

    test('puzzle ids are unique', () {
      final ids = dailyPuzzles.map((p) => p.id).toSet();
      expect(ids.length, dailyPuzzles.length);
    });
  });

  group('puzzleForDate', () {
    test('is deterministic for the same date', () {
      final date = DateTime(2026, 3, 15);
      expect(puzzleForDate(date).id, puzzleForDate(date).id);
    });

    test('covers all puzzles across a full year', () {
      final seen = <String>{};
      for (var day = 0; day < 365; day++) {
        seen.add(puzzleForDate(DateTime(2026, 1, 1).add(Duration(days: day))).id);
      }
      expect(seen.length, dailyPuzzles.length);
    });
  });

  group('formatDateKey', () {
    test('zero-pads month and day', () {
      expect(formatDateKey(DateTime(2026, 3, 5)), '2026-03-05');
    });
  });
}
