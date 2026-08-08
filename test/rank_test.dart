import 'package:flutter_test/flutter_test.dart';
import 'package:reversia/engine/ai.dart';
import 'package:reversia/engine/rank.dart';

void main() {
  group('rankPointsForWin', () {
    test('harder AI wins are worth more points', () {
      expect(rankPointsForWin(AiDifficulty.easy), 1);
      expect(rankPointsForWin(AiDifficulty.medium), 2);
      expect(rankPointsForWin(AiDifficulty.hard), 4);
    });
  });

  group('rankLabelForWins', () {
    test('starts at 10級 with zero points', () {
      expect(rankLabelForWins(0), '10級');
    });

    test('climbs the ladder as points accumulate', () {
      expect(rankLabelForWins(5), '10級');
      expect(rankLabelForWins(6), '9級');
      expect(rankLabelForWins(20), '5級');
      expect(rankLabelForWins(56), '初段');
      expect(rankLabelForWins(200), '四段');
    });
  });

  group('rankProgressForPoints', () {
    test('reports the next rank and remaining points mid-ladder', () {
      final progress = rankProgressForPoints(0);
      expect(progress.label, '10級');
      expect(progress.nextLabel, '9級');
      expect(progress.pointsToNext, 6);
      expect(progress.progressToNext, 0);
    });

    test('progress fraction increases toward the next threshold', () {
      // Between 6 (9級) and 12 (7級): halfway is 9 points.
      final progress = rankProgressForPoints(9);
      expect(progress.label, '9級');
      expect(progress.nextLabel, '7級');
      expect(progress.progressToNext, closeTo(0.5, 0.001));
    });

    test('reports no next rank once the top of the ladder is reached', () {
      final progress = rankProgressForPoints(500);
      expect(progress.label, '四段');
      expect(progress.nextLabel, isNull);
      expect(progress.pointsToNext, isNull);
      expect(progress.progressToNext, 1);
    });
  });
}
