import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:reversia/engine/board_theme.dart';
import 'package:reversia/main.dart';
import 'package:reversia/screens/game_screen.dart';
import 'package:reversia/screens/tutorial_screen.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('first launch shows the tutorial, not the real game', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: ReversiaApp(tutorialSeen: false)));
    await tester.pumpAndSettle();

    expect(find.byType(TutorialScreen), findsOneWidget);
    expect(find.byType(GameScreen), findsNothing);
  });

  testWidgets(
      'tapping the enemy square delivers the Aha Moment, then continues to the real game',
      (tester) async {
    await tester.pumpWidget(const ProviderScope(child: ReversiaApp(tutorialSeen: false)));
    await tester.pumpAndSettle();

    await tester.tap(find.text('やってみる'));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('tutorial_cell_3_3')));
    await tester.pumpAndSettle();

    expect(find.textContaining('寝返り'), findsWidgets);

    await tester.tap(find.byKey(const Key('start_game_button')));
    await tester.pumpAndSettle();

    expect(find.byType(GameScreen), findsOneWidget);
  });

  testWidgets('tutorial_seen persists so a later launch skips straight to the real game',
      (tester) async {
    await tester.pumpWidget(const ProviderScope(child: ReversiaApp(tutorialSeen: false)));
    await tester.pumpAndSettle();
    await tester.tap(find.text('やってみる'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('tutorial_cell_3_3')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('start_game_button')));
    await tester.pumpAndSettle();

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getBool(tutorialSeenPrefsKey), true);
  });

  testWidgets('tutorial board reflects a previously selected board theme', (tester) async {
    SharedPreferences.setMockInitialValues({boardThemePrefsKey: bambooTheme.id});
    await tester.pumpWidget(const ProviderScope(child: ReversiaApp(tutorialSeen: false)));
    await tester.pumpAndSettle();

    final scaffold = tester.widget<Scaffold>(find.byType(Scaffold));
    expect(scaffold.backgroundColor, bambooTheme.screenBackground);
  });
}
