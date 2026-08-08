import 'dart:math';

import 'package:reversia/engine/game_state.dart';
import 'package:reversia/engine/models.dart';
import 'package:reversia/engine/move_generator.dart';

/// Runs N random-vs-random self-play games and reports first-move win rate.
/// This is a baseline sanity check (Section 11/15 of the design doc), not a
/// proof of balance under optimal play -- a strong skew here already signals
/// a structural problem; near-50% here does not by itself prove balance.
void main(List<String> args) {
  final games = args.isNotEmpty ? int.parse(args[0]) : 1000;
  final seed = args.length > 1 ? int.parse(args[1]) : 42;
  final random = Random(seed);

  var aWins = 0, bWins = 0, draws = 0;
  var kingCaptureEnds = 0, repetitionEnds = 0, plyLimitEnds = 0, noMoveEnds = 0;
  var totalPlies = 0;

  for (var i = 0; i < games; i++) {
    final state = GameState.initial();
    String endReason = 'unknown';

    while (!state.isOver) {
      final moves = MoveGenerator.legalMovesFor(state.board, state.turn);
      if (moves.isEmpty) {
        state.declareNoMovesLoss();
        endReason = 'noMoves';
        break;
      }
      final beforePly = state.plyCount;
      state.applyMove(moves[random.nextInt(moves.length)]);
      if (state.isOver) {
        if (state.plyCount == beforePly) {
          endReason = 'kingCapture';
        } else if (state.plyCount >= plyLimit) {
          endReason = 'plyLimit';
        } else {
          endReason = 'repetition';
        }
      }
    }

    totalPlies += state.plyCount;
    switch (endReason) {
      case 'kingCapture':
        kingCaptureEnds++;
        break;
      case 'repetition':
        repetitionEnds++;
        break;
      case 'plyLimit':
        plyLimitEnds++;
        break;
      case 'noMoves':
        noMoveEnds++;
        break;
    }

    switch (state.result) {
      case GameResult.playerAWins:
        aWins++;
        break;
      case GameResult.playerBWins:
        bWins++;
        break;
      case GameResult.draw:
        draws++;
        break;
      case GameResult.ongoing:
        throw StateError('Game did not terminate');
    }
  }

  print('=== REVERSIA self-play ($games games, random vs random, seed=$seed) ===');
  print('Player A (first mover) wins: $aWins (${(aWins / games * 100).toStringAsFixed(1)}%)');
  print('Player B (second mover) wins: $bWins (${(bWins / games * 100).toStringAsFixed(1)}%)');
  print('Draws: $draws (${(draws / games * 100).toStringAsFixed(1)}%)');
  print('Avg plies per game: ${(totalPlies / games).toStringAsFixed(1)}');
  print('End reasons: kingCapture=$kingCaptureEnds repetition=$repetitionEnds '
      'plyLimit=$plyLimitEnds noMoves=$noMoveEnds');
}
