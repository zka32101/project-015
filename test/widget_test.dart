import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:reversia/engine/board_theme.dart';
import 'package:reversia/main.dart';
import 'package:reversia/screens/game_screen.dart';
import 'package:reversia/screens/rank_detail_screen.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('board renders and shows the initial turn banner', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: ReversiaApp(tutorialSeen: true)));
    await tester.pumpAndSettle();

    expect(find.byType(GameScreen), findsOneWidget);
    expect(find.text('藍陣営の番'), findsOneWidget);
  });

  testWidgets('tap own piece then a highlighted destination moves it and passes the turn',
      (tester) async {
    await tester.pumpWidget(const ProviderScope(child: ReversiaApp(tutorialSeen: true)));
    await tester.pumpAndSettle();

    // Player A's row-1 piece at (1,1) has a legal front-face move to (2,1) (empty square).
    await tester.tap(find.byKey(const Key('cell_1_1')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('cell_2_1')));
    await tester.pumpAndSettle();

    // Turn passed to player B after a completed move.
    expect(find.text('朱陣営の番'), findsOneWidget);
  });

  testWidgets('tapping an illegal square does not move or crash', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: ReversiaApp(tutorialSeen: true)));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('cell_1_1')));
    await tester.pump();
    // (5,5) is player B's territory, not a legal destination for A's piece.
    await tester.tap(find.byKey(const Key('cell_5_5')));
    await tester.pumpAndSettle();

    expect(find.text('藍陣営の番'), findsOneWidget);
  });

  testWidgets('selecting an AI opponent auto-plays B after A moves', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: ReversiaApp(tutorialSeen: true)));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('ai_menu')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('AI: かんたん'));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('cell_1_1')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('cell_2_1')));
    await tester.pump();
    // Turn passes to B; the AI schedules its reply via Future.delayed(500ms).
    // pumpAndSettle alone won't wait for a bare Timer with no scheduled frame,
    // so force the fake clock forward past the delay first.
    await tester.pump(const Duration(milliseconds: 600));
    await tester.pumpAndSettle();

    // Back to A's turn once the AI has moved.
    expect(find.text('藍陣営の番'), findsOneWidget);
  });

  testWidgets('rank badge starts at 10級 for a fresh player', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: ReversiaApp(tutorialSeen: true)));
    await tester.pumpAndSettle();

    expect(find.text('10級'), findsOneWidget);
  });

  testWidgets('threat preview toggle switches its icon and does not crash', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: ReversiaApp(tutorialSeen: true)));
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.visibility_off_outlined), findsOneWidget);
    expect(find.byIcon(Icons.visibility), findsNothing);

    await tester.tap(find.byKey(const Key('threat_preview_toggle')));
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.visibility), findsOneWidget);
    expect(find.byIcon(Icons.visibility_off_outlined), findsNothing);

    // Board still renders and remains interactive after toggling.
    await tester.tap(find.byKey(const Key('cell_1_1')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('cell_2_1')));
    await tester.pumpAndSettle();
    expect(find.text('朱陣営の番'), findsOneWidget);
  });

  testWidgets('kifu sheet shows a placeholder before any move, then lists moves after one',
      (tester) async {
    await tester.pumpWidget(const ProviderScope(child: ReversiaApp(tutorialSeen: true)));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('kifu_button')));
    await tester.pumpAndSettle();
    expect(find.text('まだ指し手がありません'), findsOneWidget);

    await tester.tapAt(const Offset(1, 1)); // dismiss the bottom sheet
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('cell_1_1')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('cell_2_1')));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('kifu_button')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('kifu_list')), findsOneWidget);
    expect(find.textContaining('1手目'), findsOneWidget);
  });

  testWidgets('last-move highlight appears on both endpoints after a move', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: ReversiaApp(tutorialSeen: true)));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('last_move_highlight')), findsNothing);

    await tester.tap(find.byKey(const Key('cell_1_1')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('cell_2_1')));
    await tester.pumpAndSettle();

    // Both the source (now empty) and destination squares are highlighted.
    expect(find.byKey(const Key('last_move_highlight')), findsNWidgets(2));
  });

  testWidgets('turn banner shows the ply counter', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: ReversiaApp(tutorialSeen: true)));
    await tester.pumpAndSettle();

    expect(find.textContaining('0/60手'), findsOneWidget);

    await tester.tap(find.byKey(const Key('cell_1_1')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('cell_2_1')));
    await tester.pumpAndSettle();

    expect(find.textContaining('1/60手'), findsOneWidget);
  });

  testWidgets('theme menu switches the board theme and persists the choice', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: ReversiaApp(tutorialSeen: true)));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('theme_menu')));
    await tester.pumpAndSettle();
    await tester.tap(find.text(bambooTheme.label));
    await tester.pumpAndSettle();

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString(boardThemePrefsKey), bambooTheme.id);

    // The board container itself should now paint the bamboo wood texture.
    final boardContainer = tester.widget<Container>(
      find.descendant(
        of: find.byType(GameScreen),
        matching: find.byWidgetPredicate((w) =>
            w is Container &&
            w.decoration is BoxDecoration &&
            (w.decoration as BoxDecoration).image?.image ==
                AssetImage(bambooTheme.woodTextureAsset)),
      ).first,
    );
    final decorationImage = (boardContainer.decoration as BoxDecoration).image;
    expect(decorationImage?.image, AssetImage(bambooTheme.woodTextureAsset));
  });

  testWidgets('tapping the rank badge opens the rank detail screen', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: ReversiaApp(tutorialSeen: true)));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('rank_badge')));
    await tester.pumpAndSettle();

    expect(find.byType(RankDetailScreen), findsOneWidget);
    expect(find.byKey(const Key('rank_progress_bar')), findsOneWidget);
    expect(find.byKey(const Key('rank_next_label')), findsOneWidget);
  });
}
