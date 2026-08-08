import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../engine/board_theme.dart';
import '../engine/rank.dart';
import '../viewmodels/game_view_model.dart';

/// Section3 Should "段位システム" made a little more substantial than the
/// AppBar badge alone: current rank, points, and progress toward the next
/// rank on the ladder.
class RankDetailScreen extends ConsumerWidget {
  const RankDetailScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final viewState = ref.watch(gameViewModelProvider);
    final theme = ref.watch(boardThemeProvider);
    final progress = rankProgressForPoints(viewState.rankPoints);

    return Scaffold(
      backgroundColor: theme.screenBackground,
      appBar: AppBar(
        title: const Text('段位'),
        backgroundColor: theme.woodDark,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Column(
                  children: [
                    Text(
                      progress.label,
                      style: TextStyle(
                        color: theme.accentGold,
                        fontSize: 40,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '段位ポイント: ${progress.points}',
                      style: const TextStyle(color: Colors.white, fontSize: 16),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              if (progress.nextLabel != null) ...[
                Text(
                  '次の段位「${progress.nextLabel}」まであと${progress.pointsToNext}pt',
                  key: const Key('rank_next_label'),
                  style: const TextStyle(color: Colors.white70),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    key: const Key('rank_progress_bar'),
                    value: progress.progressToNext,
                    minHeight: 12,
                    backgroundColor: theme.woodDark,
                    valueColor: AlwaysStoppedAnimation(theme.accentGold),
                  ),
                ),
              ] else
                const Text(
                  '最高段位に到達しました！',
                  key: Key('rank_maxed_label'),
                  style: TextStyle(color: Colors.white70),
                  textAlign: TextAlign.center,
                ),
              const SizedBox(height: 32),
              const Divider(color: Colors.white24),
              const SizedBox(height: 16),
              Text(
                '難易度別の獲得ポイント',
                style: TextStyle(color: theme.accentGold, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text('かんたん勝利: +1pt', style: TextStyle(color: Colors.white70)),
              const Text('ふつう勝利: +2pt', style: TextStyle(color: Colors.white70)),
              const Text('つよい勝利: +4pt', style: TextStyle(color: Colors.white70)),
            ],
          ),
        ),
      ),
    );
  }
}
