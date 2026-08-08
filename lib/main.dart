import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'screens/game_screen.dart';
import 'screens/tutorial_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  final tutorialSeen = prefs.getBool(tutorialSeenPrefsKey) ?? false;
  runApp(ProviderScope(child: ReversiaApp(tutorialSeen: tutorialSeen)));
}

class ReversiaApp extends StatelessWidget {
  final bool tutorialSeen;
  const ReversiaApp({super.key, this.tutorialSeen = false});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'リバーシア',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF8D6E52)),
        useMaterial3: true,
      ),
      home: tutorialSeen ? const GameScreen() : const TutorialScreen(),
    );
  }
}
