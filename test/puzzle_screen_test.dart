import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:reversia/engine/board_theme.dart';
import 'package:reversia/engine/move_generator.dart';
import 'package:reversia/engine/puzzle.dart';
import 'package:reversia/screens/puzzle_screen.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  Future<void> pumpPuzzle(WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(child: MaterialApp(home: PuzzleScreen())),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('shows the playing prompt before any move', (tester) async {
    await pumpPuzzle(tester);
    expect(find.text('1手で相手の王を取れ！'), findsOneWidget);
  });

  testWidgets('tapping the solution move solves the puzzle and records a streak of 1',
      (tester) async {
    await pumpPuzzle(tester);

    final puzzle = puzzleForDate(DateTime.now());
    final fromKey = Key('puzzle_cell_${puzzle.solutionMove.from.row}_${puzzle.solutionMove.from.col}');
    final toKey = Key('puzzle_cell_${puzzle.solutionMove.to.row}_${puzzle.solutionMove.to.col}');

    await tester.tap(find.byKey(fromKey));
    await tester.pump();
    await tester.tap(find.byKey(toKey));
    await tester.pumpAndSettle();

    expect(find.text('正解！お見事！'), findsOneWidget);
    expect(find.text('連続 1 日'), findsOneWidget);

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString(puzzleClearedDatePrefsKey), formatDateKey(DateTime.now()));
    expect(prefs.getInt(puzzleStreakPrefsKey), 1);
  });

  testWidgets('a wrong (non-winning) move shows the retry message, then reset clears it',
      (tester) async {
    await pumpPuzzle(tester);

    final puzzle = puzzleForDate(DateTime.now());
    final board = puzzle.buildBoard();
    final legal = MoveGenerator.legalMovesFor(board, puzzle.solverOwner);
    final decoy = legal.firstWhere((m) => m != puzzle.solutionMove);

    final fromKey = Key('puzzle_cell_${decoy.from.row}_${decoy.from.col}');
    final toKey = Key('puzzle_cell_${decoy.to.row}_${decoy.to.col}');

    await tester.tap(find.byKey(fromKey));
    await tester.pump();
    await tester.tap(find.byKey(toKey));
    await tester.pumpAndSettle();

    expect(find.text('ちがう手です。もう一度！'), findsOneWidget);

    await tester.tap(find.byKey(const Key('puzzle_reset_button')));
    await tester.pumpAndSettle();

    expect(find.text('1手で相手の王を取れ！'), findsOneWidget);
  });

  testWidgets('already-cleared-today state shows the cleared message and retry option',
      (tester) async {
    final today = formatDateKey(DateTime.now());
    SharedPreferences.setMockInitialValues({
      puzzleClearedDatePrefsKey: today,
      puzzleStreakPrefsKey: 3,
    });

    await pumpPuzzle(tester);

    expect(find.text('今日の1局はクリア済みです'), findsOneWidget);
    expect(find.text('連続 3 日'), findsOneWidget);
    expect(find.byKey(const Key('puzzle_retry_button')), findsOneWidget);
  });

  testWidgets('puzzle board reflects a previously selected board theme', (tester) async {
    SharedPreferences.setMockInitialValues({boardThemePrefsKey: snowIndigoTheme.id});
    await pumpPuzzle(tester);

    final scaffold = tester.widget<Scaffold>(find.byType(Scaffold));
    expect(scaffold.backgroundColor, snowIndigoTheme.screenBackground);
  });
}
