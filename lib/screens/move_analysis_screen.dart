import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../engine/game_record.dart';
import '../providers/move_analysis_provider.dart';

class MoveAnalysisScreen extends ConsumerStatefulWidget {
  final GameRecord gameRecord;

  const MoveAnalysisScreen({
    super.key,
    required this.gameRecord,
  });

  @override
  ConsumerState<MoveAnalysisScreen> createState() => _MoveAnalysisScreenState();
}

class _MoveAnalysisScreenState extends ConsumerState<MoveAnalysisScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(moveAnalysisProvider.notifier).analyzeGame(widget.gameRecord);
    });
  }

  @override
  Widget build(BuildContext context) {
    final analysisState = ref.watch(moveAnalysisProvider);
    final theme = Theme.of(context);

    if (analysisState.isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('手数分析')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (analysisState.error != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('手数分析')),
        body: Center(
          child: Text('エラー: ${analysisState.error}'),
        ),
      );
    }

    final analysis = analysisState.analysis;
    if (analysis == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('手数分析')),
        body: const Center(child: Text('分析データなし')),
      );
    }

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('手数分析'),
        elevation: 0,
      ),
      body: CustomScrollView(
        slivers: [
          // Overall accuracy header
          SliverToBoxAdapter(
            child: _OverallAccuracyCard(analysis: analysis),
          ),
          const SliverPadding(padding: EdgeInsets.only(top: 8)),

          // Game feedback
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: _GameFeedbackCard(analysis: analysis),
            ),
          ),
          const SliverPadding(padding: EdgeInsets.only(top: 16)),

          // Quality distribution
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '手の質の分布',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _QualityDistributionChart(analysis: analysis),
                ],
              ),
            ),
          ),
          const SliverPadding(padding: EdgeInsets.only(top: 16)),

          // Phase analysis
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'ゲーム段階別分析',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _PhaseAnalysisCards(analysis: analysis),
                ],
              ),
            ),
          ),
          const SliverPadding(padding: EdgeInsets.only(top: 16)),

          // Strengths and improvements
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '強い点と改善点',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _StrengthsAndImprovements(analysis: analysis),
                ],
              ),
            ),
          ),
          const SliverPadding(padding: EdgeInsets.only(top: 16)),

          // Move-by-move analysis
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '手数ごとの分析',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _MoveByMoveList(analysis: analysis),
                ],
              ),
            ),
          ),
          const SliverPadding(padding: EdgeInsets.only(bottom: 32)),
        ],
      ),
    );
  }
}

/// Overall accuracy card
class _OverallAccuracyCard extends StatelessWidget {
  final GameMovesAnalysis analysis;

  const _OverallAccuracyCard({required this.analysis});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accuracy = analysis.overallAccuracy;

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            _getAccuracyColor(accuracy).withValues(alpha: 0.8),
            _getAccuracyColor(accuracy).withValues(alpha: 0.5),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: _getAccuracyColor(accuracy).withValues(alpha: 0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            '判断精度',
            style: theme.textTheme.bodyLarge?.copyWith(
              color: Colors.white.withValues(alpha: 0.9),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${accuracy.toStringAsFixed(1)}%',
            style: const TextStyle(
              fontSize: 48,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              _getAccuracyLabel(accuracy),
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.9),
                fontSize: 12,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  Color _getAccuracyColor(double accuracy) {
    if (accuracy >= 80) return Colors.green;
    if (accuracy >= 60) return Colors.blue;
    if (accuracy >= 40) return Colors.orange;
    return Colors.red;
  }

  String _getAccuracyLabel(double accuracy) {
    if (accuracy >= 80) return '素晴らしい判断力です';
    if (accuracy >= 60) return '良い判断が多いです';
    if (accuracy >= 40) return '基本は堅実です';
    return '基本の改善が必要です';
  }
}

/// Game feedback card
class _GameFeedbackCard extends StatelessWidget {
  final GameMovesAnalysis analysis;

  const _GameFeedbackCard({required this.analysis});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.blue.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.lightbulb, color: Colors.blue),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'フィードバック',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            analysis.overallFeedback,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: Colors.blue.shade700,
            ),
          ),
        ],
      ),
    );
  }
}

/// Quality distribution chart
class _QualityDistributionChart extends StatelessWidget {
  final GameMovesAnalysis analysis;

  const _QualityDistributionChart({required this.analysis});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final qualities = [
      ('優秀', analysis.excellentMoves, Colors.green),
      ('良い', analysis.goodMoves, Colors.lightGreen),
      ('許容', analysis.acceptableMoves, Colors.orange),
      ('改善要', analysis.suboptimalMoves, Colors.deepOrange),
      ('致命的', analysis.criticalErrors, Colors.red),
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.green.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          for (final (label, count, color) in qualities)
            _QualityBar(
              label: label,
              count: count,
              total: analysis.moveAnalyses.length,
              color: color,
            ),
        ],
      ),
    );
  }
}

/// Quality bar
class _QualityBar extends StatelessWidget {
  final String label;
  final int count;
  final int total;
  final Color color;

  const _QualityBar({
    required this.label,
    required this.count,
    required this.total,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final percentage = total > 0 ? (count / total) * 100 : 0.0;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          SizedBox(
            width: 60,
            child: Text(
              label,
              style: const TextStyle(fontSize: 12),
            ),
          ),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: percentage / 100,
                minHeight: 8,
                backgroundColor: color.withValues(alpha: 0.2),
                valueColor: AlwaysStoppedAnimation(color),
              ),
            ),
          ),
          const SizedBox(width: 12),
          SizedBox(
            width: 50,
            child: Text(
              '$count (${percentage.toStringAsFixed(0)}%)',
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }
}

/// Phase analysis cards
class _PhaseAnalysisCards extends StatelessWidget {
  final GameMovesAnalysis analysis;

  const _PhaseAnalysisCards({required this.analysis});

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 3,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      children: [
        _PhaseCard(
          icon: Icons.auto_awesome,
          label: 'オープニング',
          advice: analysis.getOpeningAdvice(),
          color: Colors.blue,
        ),
        _PhaseCard(
          icon: Icons.trending_up,
          label: 'ミッドゲーム',
          advice: analysis.getMidgameAdvice(),
          color: Colors.orange,
        ),
        _PhaseCard(
          icon: Icons.check_circle,
          label: 'エンドゲーム',
          advice: analysis.getEndgameAdvice(),
          color: Colors.green,
        ),
      ],
    );
  }
}

/// Phase card
class _PhaseCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String advice;
  final Color color;

  const _PhaseCard({
    required this.icon,
    required this.label,
    required this.advice,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            children: [
              Icon(icon, color: color, size: 24),
              const SizedBox(height: 6),
              Text(
                label,
                style: theme.textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  fontSize: 11,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
          Expanded(
            child: Center(
              child: Text(
                advice,
                style: theme.textTheme.bodySmall?.copyWith(
                  fontSize: 10,
                  color: theme.textTheme.bodySmall?.color?.withValues(
                    alpha: 0.7,
                  ),
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Strengths and improvements section
class _StrengthsAndImprovements extends StatelessWidget {
  final GameMovesAnalysis analysis;

  const _StrengthsAndImprovements({required this.analysis});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      children: [
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.green.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.green.withValues(alpha: 0.3),
                width: 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.check_circle,
                        color: Colors.green, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      '強い点',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ...analysis.strengthAreas
                    .map((area) => Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: Row(
                            children: [
                              const Icon(Icons.star,
                                  color: Colors.green, size: 16),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  area,
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: Colors.green.shade700,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ))
                    .toList(),
              ],
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.orange.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.orange.withValues(alpha: 0.3),
                width: 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.lightbulb,
                        color: Colors.orange, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      '改善点',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.orange,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ...analysis.improvementAreas
                    .map((area) => Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: Row(
                            children: [
                              const Icon(Icons.arrow_forward,
                                  color: Colors.orange, size: 16),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  area,
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: Colors.orange.shade700,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ))
                    .toList(),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// Move-by-move list
class _MoveByMoveList extends StatelessWidget {
  final GameMovesAnalysis analysis;

  const _MoveByMoveList({required this.analysis});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.grey.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          for (int i = 0; i < analysis.moveAnalyses.length; i++)
            _MoveAnalysisTile(
              moveAnalysis: analysis.moveAnalyses[i],
              isLast: i == analysis.moveAnalyses.length - 1,
            ),
        ],
      ),
    );
  }
}

/// Move analysis tile
class _MoveAnalysisTile extends StatelessWidget {
  final MoveAnalysis moveAnalysis;
  final bool isLast;

  const _MoveAnalysisTile({
    required this.moveAnalysis,
    required this.isLast,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.grey.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: Text(
                    moveAnalysis.moveNumber.toString(),
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          moveAnalysis.getQualityEmoji(),
                          style: const TextStyle(fontSize: 16),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          moveAnalysis.getQualityLabel(),
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Color(int.parse(
                                moveAnalysis.getQualityColor().replaceFirst('#', '0xFF'))),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      moveAnalysis.explanation,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.textTheme.bodySmall?.color?.withValues(
                          alpha: 0.7,
                        ),
                      ),
                    ),
                    if (moveAnalysis.betterMove != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        '代案: ${moveAnalysis.betterMove}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: Colors.orange,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.grey.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '${(moveAnalysis.confidence * 100).toStringAsFixed(0)}%',
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    fontSize: 11,
                  ),
                ),
              ),
            ],
          ),
        ),
        if (!isLast)
          Divider(
            height: 1,
            color: Colors.grey.withValues(alpha: 0.1),
          ),
      ],
    );
  }
}
