import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../engine/models.dart';
import '../engine/move_analyzer.dart';
import '../viewmodels/game_view_model.dart';

/// Displays move analysis for current position with top suggestions
class MoveAnalysisPanel extends ConsumerWidget {
  final bool showOnlyBest;
  final int suggestionsCount;

  const MoveAnalysisPanel({
    Key? key,
    this.showOnlyBest = false,
    this.suggestionsCount = 3,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final gameState = ref.watch(gameViewModelProvider);

    if (gameState.game.isOver) {
      return const SizedBox.shrink();
    }

    final viewModel = ref.read(gameViewModelProvider.notifier);
    final analyses = viewModel.getMoveAnalysis();

    if (analyses.isEmpty) {
      return const SizedBox.shrink();
    }

    final displayAnalyses =
        showOnlyBest ? [analyses.first] : analyses.take(suggestionsCount).toList();

    return Container(
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '推奨手順',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: Colors.white70,
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 8),
          ...displayAnalyses.map((analysis) {
            return _MoveAnalysisItem(analysis: analysis);
          }),
        ],
      ),
    );
  }
}

/// Single move analysis item display
class _MoveAnalysisItem extends StatelessWidget {
  final MoveAnalysis analysis;

  const _MoveAnalysisItem({required this.analysis});

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDarkMode ? Colors.white : Colors.black;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Rank badge
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: _getCategoryColor(analysis.category),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Center(
                  child: Text(
                    '${analysis.rank}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              // Move notation
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${analysis.move.from.row}${analysis.move.from.col} → ${analysis.move.to.row}${analysis.move.to.col}',
                      style: TextStyle(
                        color: textColor,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                    if (analysis.reasons.isNotEmpty)
                      Text(
                        analysis.reasons.first,
                        style: TextStyle(
                          color: textColor.withOpacity(0.7),
                          fontSize: 11,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              // Strength indicator
              Text(
                analysis.strengthDisplay,
                style: TextStyle(
                  color: _getCategoryColor(analysis.category),
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Color _getCategoryColor(MoveCategory category) {
    switch (category) {
      case MoveCategory.winning:
        return Colors.amber[600]!;
      case MoveCategory.excellent:
        return Colors.green[600]!;
      case MoveCategory.good:
        return Colors.blue[600]!;
      case MoveCategory.solid:
        return Colors.grey[600]!;
      case MoveCategory.risky:
        return Colors.red[600]!;
    }
  }
}

/// Compact move analysis badge for use during piece selection
class MoveStrengthBadge extends ConsumerWidget {
  final Move move;

  const MoveStrengthBadge({
    Key? key,
    required this.move,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final gameState = ref.watch(gameViewModelProvider);
    final viewModel = ref.read(gameViewModelProvider.notifier);

    final analysis = viewModel.analyzeMoveSpecific(move);
    if (analysis == null) return const SizedBox.shrink();

    return Positioned(
      top: 4,
      right: 4,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: _getCategoryColor(analysis.category),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(
          analysis.categoryEmoji,
          style: const TextStyle(fontSize: 10),
        ),
      ),
    );
  }

  Color _getCategoryColor(MoveCategory category) {
    switch (category) {
      case MoveCategory.winning:
        return Colors.amber[600]!;
      case MoveCategory.excellent:
        return Colors.green[600]!;
      case MoveCategory.good:
        return Colors.blue[600]!;
      case MoveCategory.solid:
        return Colors.grey[600]!;
      case MoveCategory.risky:
        return Colors.red[600]!;
    }
  }
}

/// Strategic advice banner for the current position
class StrategicAdviceBanner extends ConsumerWidget {
  const StrategicAdviceBanner({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final gameState = ref.watch(gameViewModelProvider);

    if (gameState.game.isOver) {
      return const SizedBox.shrink();
    }

    final viewModel = ref.read(gameViewModelProvider.notifier);
    final advice = viewModel.getStrategicAdvice();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blue[900]?.withOpacity(0.3),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Colors.blue[700]!,
          width: 1,
        ),
      ),
      child: Text(
        advice,
        style: TextStyle(
          color: Colors.blue[300],
          fontSize: 12,
          fontStyle: FontStyle.italic,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }
}

/// Detailed move analysis sheet for selected move
class MoveAnalysisDetailsSheet extends StatelessWidget {
  final MoveAnalysis analysis;

  const MoveAnalysisDetailsSheet({
    Key? key,
    required this.analysis,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDarkMode ? Colors.white : Colors.black;
    final categoryColor = _getCategoryColor(analysis.category);

    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with move and strength
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: categoryColor,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: Text(
                    analysis.categoryEmoji,
                    style: const TextStyle(fontSize: 20),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${analysis.move.from.row}${analysis.move.from.col} → ${analysis.move.to.row}${analysis.move.to.col}',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    Text(
                      analysis.strengthDisplay,
                      style: TextStyle(
                        color: categoryColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Category tags
          Wrap(
            spacing: 8,
            children: analysis.categories.map((tag) {
              return Chip(
                label: Text(tag),
                backgroundColor: categoryColor.withOpacity(0.3),
                labelStyle: TextStyle(color: categoryColor),
                side: BorderSide(color: categoryColor),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),

          // Reasons
          if (analysis.reasons.isNotEmpty) ...[
            Text(
              '理由',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 8),
            ...analysis.reasons.map((reason) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '• ',
                      style: TextStyle(color: textColor),
                    ),
                    Expanded(
                      child: Text(
                        reason,
                        style: TextStyle(color: textColor),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ],

          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('了解'),
            ),
          ),
        ],
      ),
    );
  }

  Color _getCategoryColor(MoveCategory category) {
    switch (category) {
      case MoveCategory.winning:
        return Colors.amber[600]!;
      case MoveCategory.excellent:
        return Colors.green[600]!;
      case MoveCategory.good:
        return Colors.blue[600]!;
      case MoveCategory.solid:
        return Colors.grey[600]!;
      case MoveCategory.risky:
        return Colors.red[600]!;
    }
  }
}
