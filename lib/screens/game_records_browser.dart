import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../engine/game_record.dart';
import '../engine/models.dart';
import '../providers/game_records_provider.dart';
import 'move_analysis_screen.dart';

/// Comprehensive game records browser with filtering, sorting, and detailed views
class GameRecordsBrowser extends ConsumerStatefulWidget {
  const GameRecordsBrowser({super.key});

  @override
  ConsumerState<GameRecordsBrowser> createState() => _GameRecordsBrowserState();
}

class _GameRecordsBrowserState extends ConsumerState<GameRecordsBrowser> {
  late GameRecordFilter _currentFilter;
  late GameRecordSort _currentSort;

  @override
  void initState() {
    super.initState();
    _currentFilter = const GameRecordFilter();
    _currentSort = GameRecordSort.newest;

    // Load records on init
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(gameRecordsProvider.notifier).loadRecords();
    });
  }

  @override
  Widget build(BuildContext context) {
    final recordsState = ref.watch(gameRecordsProvider);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('対局履歴'),
        elevation: 0,
      ),
      body: recordsState.isLoading
          ? const Center(child: CircularProgressIndicator())
          : recordsState.filteredRecords.isEmpty
              ? _buildEmptyState(context)
              : Column(
                  children: [
                    // Statistics and filters
                    _StatisticsBar(state: recordsState),

                    // Sort and filter controls
                    _FilterControls(
                      currentFilter: _currentFilter,
                      currentSort: _currentSort,
                      onFilterChanged: (filter) {
                        setState(() => _currentFilter = filter);
                        ref.read(gameRecordsProvider.notifier).setFilter(filter);
                      },
                      onSortChanged: (sort) {
                        setState(() => _currentSort = sort);
                        ref.read(gameRecordsProvider.notifier).setSort(sort);
                      },
                    ),

                    // Records list
                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        itemCount: recordsState.filteredRecords.length,
                        itemBuilder: (context, index) {
                          final record = recordsState.filteredRecords[index];
                          return _GameRecordTile(
                            record: record,
                            onTap: () => _showGameDetails(context, record),
                            onDelete: () => _deleteRecord(context, record.id),
                          );
                        },
                      ),
                    ),
                  ],
                ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.history,
            size: 64,
            color: Colors.grey[600],
          ),
          const SizedBox(height: 16),
          Text(
            '対局履歴がありません',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(
            'ゲームをプレイして履歴を作成しましょう',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  void _showGameDetails(BuildContext context, GameRecord record) {
    showModalBottomSheet(
      context: context,
      builder: (context) => _GameDetailSheet(record: record),
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
    );
  }

  void _deleteRecord(BuildContext context, String id) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('対局を削除'),
        content: const Text('この対局の記録を削除してもよろしいですか？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('キャンセル'),
          ),
          TextButton(
            onPressed: () {
              ref.read(gameRecordsProvider.notifier).deleteRecord(id);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('対局を削除しました')),
              );
            },
            child: const Text('削除', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}

/// Statistics bar showing win rate and counts
class _StatisticsBar extends StatelessWidget {
  final GameRecordsState state;

  const _StatisticsBar({required this.state});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[850],
        border: Border(
          bottom: BorderSide(
            color: Colors.white10,
            width: 1,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '履歴統計',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _StatItem(
                label: '対局数',
                value: state.filteredRecords.length.toString(),
              ),
              _StatItem(
                label: '勝率',
                value: '${(state.winRate * 100).toStringAsFixed(1)}%',
                color: Colors.green,
              ),
              _StatItem(
                label: '勝利',
                value: state.winCount.toString(),
                color: Colors.green,
              ),
              _StatItem(
                label: '敗北',
                value: state.lossCount.toString(),
                color: Colors.red,
              ),
              _StatItem(
                label: '引き分け',
                value: state.drawCount.toString(),
                color: Colors.amber,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Individual statistic display
class _StatItem extends StatelessWidget {
  final String label;
  final String value;
  final Color? color;

  const _StatItem({
    required this.label,
    required this.value,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: color ?? Colors.white,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Colors.grey[500],
          ),
        ),
      ],
    );
  }
}

/// Filter and sort controls
class _FilterControls extends ConsumerWidget {
  final GameRecordFilter currentFilter;
  final GameRecordSort currentSort;
  final Function(GameRecordFilter) onFilterChanged;
  final Function(GameRecordSort) onSortChanged;

  const _FilterControls({
    required this.currentFilter,
    required this.currentSort,
    required this.onFilterChanged,
    required this.onSortChanged,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Result filter
          Text(
            '結果で絞込',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _FilterChip(
                  label: '全て',
                  selected: currentFilter.result == null,
                  onTap: () {
                    onFilterChanged(currentFilter.copyWith(result: null));
                  },
                ),
                const SizedBox(width: 8),
                _FilterChip(
                  label: '勝利',
                  selected: currentFilter.result == GameResult.playerAWins,
                  onTap: () {
                    onFilterChanged(
                      currentFilter.copyWith(result: GameResult.playerAWins),
                    );
                  },
                  color: Colors.green,
                ),
                const SizedBox(width: 8),
                _FilterChip(
                  label: '敗北',
                  selected: currentFilter.result == GameResult.playerBWins,
                  onTap: () {
                    onFilterChanged(
                      currentFilter.copyWith(result: GameResult.playerBWins),
                    );
                  },
                  color: Colors.red,
                ),
                const SizedBox(width: 8),
                _FilterChip(
                  label: '引き分け',
                  selected: currentFilter.result == GameResult.draw,
                  onTap: () {
                    onFilterChanged(currentFilter.copyWith(result: GameResult.draw));
                  },
                  color: Colors.amber,
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Sort dropdown
          Row(
            children: [
              Text(
                'ソート：',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.grey[800],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: DropdownButton<GameRecordSort>(
                    value: currentSort,
                    onChanged: (sort) {
                      if (sort != null) {
                        onSortChanged(sort);
                      }
                    },
                    isExpanded: true,
                    underline: const SizedBox(),
                    items: [
                      DropdownMenuItem(
                        value: GameRecordSort.newest,
                        child: Text(
                          '最新順',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ),
                      DropdownMenuItem(
                        value: GameRecordSort.oldest,
                        child: Text(
                          '古い順',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ),
                      DropdownMenuItem(
                        value: GameRecordSort.duration,
                        child: Text(
                          '時間長い順',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ),
                      DropdownMenuItem(
                        value: GameRecordSort.moves,
                        child: Text(
                          '手数多い順',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ),
                      DropdownMenuItem(
                        value: GameRecordSort.winRate,
                        child: Text(
                          '成績順',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// A small selectable chip used by the result filter row
class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final Color? color;

  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final chipColor = color ?? Theme.of(context).colorScheme.primary;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? chipColor.withValues(alpha: 0.15) : null,
          border: Border.all(
            color: selected ? chipColor : Colors.grey.withValues(alpha: 0.5),
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? chipColor : null,
            fontWeight: selected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}

/// Individual game record tile
class _GameRecordTile extends StatelessWidget {
  final GameRecord record;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _GameRecordTile({
    required this.record,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final resultColor = _getResultColor(record.result);

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      color: Colors.grey[850],
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(
          color: resultColor.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      record.resultDisplay,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: resultColor,
                      ),
                    ),
                  ),
                  Text(
                    _formatDate(record.playedAt),
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[500],
                    ),
                  ),
                  PopupMenuButton<String>(
                    onSelected: (value) {
                      if (value == 'analyze') {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) =>
                                MoveAnalysisScreen(gameRecord: record),
                          ),
                        );
                      } else if (value == 'delete') {
                        onDelete();
                      }
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'analyze',
                        child: Row(
                          children: [
                            Icon(Icons.analytics, size: 18),
                            SizedBox(width: 8),
                            Text('分析'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete, size: 18),
                            SizedBox(width: 8),
                            Text('削除'),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _InfoRow(
                          icon: Icons.videogame_asset,
                          label: record.aiDifficulty ?? 'ローカル',
                        ),
                        _InfoRow(
                          icon: Icons.format_list_numbered,
                          label: '${record.totalMoves}手',
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        _InfoRow(
                          icon: Icons.schedule,
                          label: record.durationDisplay,
                        ),
                        _InfoRow(
                          icon: Icons.circle,
                          label:
                              '藍${record.playerAPieceCount} vs 朱${record.playerBPieceCount}',
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
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
        return Colors.amber;
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
      return '昨日 ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    } else {
      return '${date.month}/${date.day} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    }
  }
}

/// Info row for game details
class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;

  const _InfoRow({
    required this.icon,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 14,
            color: Colors.grey[500],
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[300],
            ),
          ),
        ],
      ),
    );
  }
}

/// Detailed game view
class _GameDetailSheet extends StatelessWidget {
  final GameRecord record;

  const _GameDetailSheet({required this.record});

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      expand: false,
      builder: (context, scrollController) => Container(
        decoration: BoxDecoration(
          color: Colors.grey[850],
          borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
        ),
        child: ListView(
          controller: scrollController,
          padding: const EdgeInsets.all(16),
          children: [
            // Header
            Center(
              child: Text(
                record.resultDisplay,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: _getResultColor(record.result),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Game info
            Text(
              'ゲーム情報',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            _DetailRow(label: '日時', value: _formatDateTime(record.playedAt)),
            _DetailRow(label: '手数', value: '${record.totalMoves}手'),
            _DetailRow(label: '時間', value: record.durationDisplay),
            _DetailRow(
              label: '対戦型',
              value: record.aiDifficulty ?? 'ローカル2人プレイ',
            ),
            const SizedBox(height: 16),

            // Board state
            Text(
              '終局時の盤面',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[900],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _PieceCount(
                        label: '藍陣営',
                        count: record.playerAPieceCount,
                      ),
                      _PieceCount(
                        label: '朱陣営',
                        count: record.playerBPieceCount,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
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
        return Colors.amber;
      case GameResult.ongoing:
        return Colors.grey;
    }
  }

  String _formatDateTime(DateTime date) {
    return '${date.year}年${date.month}月${date.day}日 ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }
}

/// Detail row widget
class _DetailRow extends StatelessWidget {
  final String label;
  final String value;

  const _DetailRow({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.grey[500],
              fontSize: 14,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

/// Piece count display
class _PieceCount extends StatelessWidget {
  final String label;
  final int count;

  const _PieceCount({
    required this.label,
    required this.count,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.grey[400],
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          count.toString(),
          style: const TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}
