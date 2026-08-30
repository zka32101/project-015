import 'package:flutter/material.dart';

import '../engine/board_theme.dart';
import '../engine/game_record.dart';
import '../engine/models.dart';
import '../engine/statistics.dart';

class GameInsightsScreen extends StatefulWidget {
  final GameHistoryManager historyManager;
  final GameStatistics statistics;

  const GameInsightsScreen({
    super.key,
    required this.historyManager,
    required this.statistics,
  });

  @override
  State<GameInsightsScreen> createState() => _GameInsightsScreenState();
}

class _GameInsightsScreenState extends State<GameInsightsScreen> {
  late List<GameRecord> _records;

  @override
  void initState() {
    super.initState();
    _records = widget.historyManager.getAllRecords();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('ゲーム分析'),
      ),
      body: _records.isEmpty
          ? Center(
              child: Text(
                '分析するゲーム履歴がありません',
                style: theme.textTheme.bodyLarge,
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Overall Statistics Card
                  _InsightCard(
                    title: '総合成績',
                    children: [
                      _InsightRow(
                        label: '対局数',
                        value: '${widget.statistics.totalGames}',
                      ),
                      _InsightRow(
                        label: '勝率',
                        value: widget.statistics.formatWinRate(
                          widget.statistics.playerAWinRate,
                        ),
                        isHighlight: true,
                      ),
                      _InsightRow(
                        label: '最長連勝',
                        value: '${widget.statistics.playerALongestStreak}連勝',
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Performance by Difficulty
                  _InsightCard(
                    title: 'AI別成績',
                    children: _buildDifficultyStats(),
                  ),
                  const SizedBox(height: 16),
                  // Game Duration Insights
                  _InsightCard(
                    title: 'ゲーム時間',
                    children: [
                      _InsightRow(
                        label: '平均ゲーム時間',
                        value: _formatDuration(
                          widget.historyManager.averageDurationSeconds.toInt(),
                        ),
                      ),
                      if (_records.isNotEmpty) ...[
                        _InsightRow(
                          label: '最短ゲーム時間',
                          value: _formatDuration(
                            _records.map((r) => r.durationSeconds).reduce((a, b) => a < b ? a : b),
                          ),
                        ),
                        _InsightRow(
                          label: '最長ゲーム時間',
                          value: _formatDuration(
                            _records.map((r) => r.durationSeconds).reduce((a, b) => a > b ? a : b),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Strategic Insights
                  _InsightCard(
                    title: 'ゲーム分析と推奨事項',
                    children: _buildStrategicInsights(),
                  ),
                ],
              ),
            ),
    );
  }

  List<Widget> _buildDifficultyStats() {
    final diffStats = widget.statistics.statsByDifficulty;
    final difficulties = ['local', 'easy', 'medium', 'hard'];
    final labels = ['ローカル', 'かんたん', 'ふつう', 'つよい'];

    return List.generate(difficulties.length, (index) {
      final stats = diffStats[difficulties[index]]!;
      if (stats.totalGames == 0) return SizedBox.shrink();

      return Column(
        children: [
          _InsightRow(
            label: labels[index],
            value: '${stats.wins}勝${stats.losses}敗',
          ),
          if (stats.totalGames > 0)
            _InsightRow(
              label: '${labels[index]}勝率',
              value: _formatWinRate(stats.winRate),
              isHighlight: true,
            ),
          if (index < difficulties.length - 1)
            const SizedBox(height: 8),
        ],
      );
    }).toList();
  }

  List<Widget> _buildStrategicInsights() {
    final insights = <Widget>[];

    // Overall performance insight
    final winRate = widget.statistics.playerAWinRate;
    if (winRate.isNaN) {
      insights.add(const Text(
        'まだゲームをプレイしていません。プレイを開始して成績を記録しましょう。',
        style: TextStyle(color: Colors.white70),
      ));
    } else if (winRate >= 0.7) {
      insights.add(const _InsightText(
        emoji: '🎉',
        text: '素晴らしい成績です！強い対戦相手に挑戦してみてください。',
      ));
    } else if (winRate >= 0.5) {
      insights.add(const _InsightText(
        emoji: '👍',
        text: '安定した成績をキープしています。次のレベルを目指しましょう。',
      ));
    } else {
      insights.add(const _InsightText(
        emoji: '📚',
        text: 'パターン学習を増やすことをお勧めします。デイリーパズルをプレイしましょう。',
      ));
    }

    insights.add(const SizedBox(height: 12));

    // Streak insight
    if (widget.statistics.playerAWinStreak > 0) {
      insights.add(_InsightText(
        emoji: '🔥',
        text: '現在${widget.statistics.playerAWinStreak}連勝中です。この調子を続けましょう！',
      ));
    } else if (widget.statistics.playerALongestStreak > 3) {
      insights.add(_InsightText(
        emoji: '💪',
        text: 'あなたの最長連勝は${widget.statistics.playerALongestStreak}連勝です。また達成できます！',
      ));
    }

    insights.add(const SizedBox(height: 12));

    // Game count insight
    if (widget.statistics.totalGames < 10) {
      insights.add(const _InsightText(
        emoji: '🎮',
        text: 'もっとゲームをプレイして、あなたのスタイルを確立しましょう。',
      ));
    } else if (widget.statistics.totalGames < 50) {
      insights.add(const _InsightText(
        emoji: '📊',
        text: '順調に進んでいます。さらなる経験を積み重ねましょう。',
      ));
    } else {
      insights.add(const _InsightText(
        emoji: '🏆',
        text: '多くのゲーム経験を積んでいます。あなたの成長が見られます。',
      ));
    }

    return insights;
  }

  String _formatDuration(int seconds) {
    final minutes = seconds ~/ 60;
    final secs = seconds % 60;
    return '${minutes}分${secs}秒';
  }

  String _formatWinRate(double rate) {
    if (rate.isNaN) return 'N/A';
    return '${(rate * 100).toStringAsFixed(1)}%';
  }
}

class _InsightCard extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _InsightCard({
    required this.title,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[850],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Colors.amber[700]!.withValues(alpha: 0.3),
        ),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: theme.textTheme.titleMedium?.copyWith(
              color: Colors.amber[700],
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }
}

class _InsightRow extends StatelessWidget {
  final String label;
  final String value;
  final bool isHighlight;

  const _InsightRow({
    required this.label,
    required this.value,
    this.isHighlight = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(color: Colors.white70),
          ),
          Text(
            value,
            style: TextStyle(
              color: isHighlight ? Colors.amber[700] : Colors.white,
              fontWeight: isHighlight ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }
}

class _InsightText extends StatelessWidget {
  final String emoji;
  final String text;

  const _InsightText({
    required this.emoji,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(emoji, style: const TextStyle(fontSize: 20)),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(color: Colors.white70),
          ),
        ),
      ],
    );
  }
}
