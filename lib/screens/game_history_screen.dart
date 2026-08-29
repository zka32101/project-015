import 'package:flutter/material.dart';

import '../engine/board_theme.dart';
import '../engine/game_record.dart';
import '../engine/models.dart';

class GameHistoryScreen extends StatefulWidget {
  final GameHistoryManager historyManager;

  const GameHistoryScreen({
    super.key,
    required this.historyManager,
  });

  @override
  State<GameHistoryScreen> createState() => _GameHistoryScreenState();
}

class _GameHistoryScreenState extends State<GameHistoryScreen> {
  late List<GameRecord> _displayedRecords;
  String? _filterDifficulty;
  GameResult? _filterResult;

  @override
  void initState() {
    super.initState();
    _displayedRecords = widget.historyManager.getAllRecords();
  }

  void _applyFilters() {
    var records = widget.historyManager.getAllRecords();

    if (_filterResult != null) {
      records = records.where((r) => r.result == _filterResult).toList();
    }

    if (_filterDifficulty != null) {
      records = records.where((r) => r.aiDifficulty == _filterDifficulty).toList();
    }

    setState(() => _displayedRecords = records);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('対局履歴'),
      ),
      body: _displayedRecords.isEmpty
          ? Center(
              child: Text(
                '対局履歴がありません',
                style: theme.textTheme.bodyLarge,
              ),
            )
          : Column(
              children: [
                // Filter controls
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      Expanded(
                        child: _FilterChip(
                          label: '全て',
                          selected: _filterResult == null,
                          onTap: () {
                            setState(() => _filterResult = null);
                            _applyFilters();
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _FilterChip(
                          label: '勝利',
                          selected: _filterResult == GameResult.playerAWins,
                          onTap: () {
                            setState(() => _filterResult = GameResult.playerAWins);
                            _applyFilters();
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _FilterChip(
                          label: '敗北',
                          selected: _filterResult == GameResult.playerBWins,
                          onTap: () {
                            setState(() => _filterResult = GameResult.playerBWins);
                            _applyFilters();
                          },
                        ),
                      ),
                    ],
                  ),
                ),
                // Game list
                Expanded(
                  child: ListView.builder(
                    itemCount: _displayedRecords.length,
                    itemBuilder: (context, index) {
                      final record = _displayedRecords[index];
                      return _GameHistoryTile(record: record);
                    },
                  ),
                ),
              ],
            ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? Colors.amber[700] : Colors.grey[800],
          borderRadius: BorderRadius.circular(20),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              color: selected ? Colors.black : Colors.white,
              fontWeight: selected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ),
      ),
    );
  }
}

class _GameHistoryTile extends StatelessWidget {
  final GameRecord record;

  const _GameHistoryTile({required this.record});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final resultColor = _getResultColor(record.result);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.grey[850],
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: resultColor.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  record.resultDisplay,
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: resultColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  _formatDate(record.playedAt),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: Colors.grey[500],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('対戦型: ${record.aiDifficulty ?? 'ローカル'}',
                        style: theme.textTheme.bodySmall),
                    Text('手数: ${record.totalMoves}手',
                        style: theme.textTheme.bodySmall),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text('時間: ${record.durationDisplay}',
                        style: theme.textTheme.bodySmall),
                    Text('駒数: 藍${record.playerAPieceCount} vs 朱${record.playerBPieceCount}',
                        style: theme.textTheme.bodySmall),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color _getResultColor(GameResult result) {
    switch (result) {
      case GameResult.playerAWins:
        return Colors.green;
      case GameResult.playerBWins:
        return Colors.red;
      case GameResult.draw:
        return Colors.yellow;
      case GameResult.ongoing:
        return Colors.grey;
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final recordDate = DateTime(date.year, date.month, date.day);

    if (recordDate == today) {
      return '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    } else if (recordDate == today.subtract(const Duration(days: 1))) {
      return '昨日';
    } else {
      return '${date.month}/${date.day}';
    }
  }
}
