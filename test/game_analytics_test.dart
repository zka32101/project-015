import 'package:flutter_test/flutter_test.dart';

import 'package:reversia/engine/game_analytics.dart';

void main() {
  group('GameSession.movesPerMinute', () {
    test('reports a non-zero rate for a game finished in under a minute', () {
      // Regression test: movesPerMinute used to truncate duration to whole
      // minutes (duration.inMinutes) before checking for zero, so any game
      // finished in under 60 seconds always reported 0.0 instead of the
      // real rate.
      final session = GameSession(
        playedAt: DateTime(2026),
        playerAWon: true,
        movesCount: 10,
        duration: const Duration(seconds: 40),
      );

      expect(session.movesPerMinute, closeTo(15.0, 0.01)); // 10 / (40/60)
    });

    test('reports 0.0 for a zero-duration game instead of dividing by zero', () {
      final session = GameSession(
        playedAt: DateTime(2026),
        playerAWon: true,
        movesCount: 0,
        duration: Duration.zero,
      );

      expect(session.movesPerMinute, 0.0);
    });

    test('still computes the correct rate for multi-minute games', () {
      final session = GameSession(
        playedAt: DateTime(2026),
        playerAWon: true,
        movesCount: 30,
        duration: const Duration(minutes: 3),
      );

      expect(session.movesPerMinute, closeTo(10.0, 0.01));
    });
  });
}
