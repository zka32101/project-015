import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../engine/game_record.dart';
import '../providers/replay_study_provider.dart';

class ReplayStudyScreen extends ConsumerWidget {
  const ReplayStudyScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final games = ref.watch(studyableGamesProvider);
    final studyState = ref.watch(replayStudyProvider);
    final sorted = [...games]
      ..sort((a, b) => b.playedAt.compareTo(a.playedAt));

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('リプレイ研究モード'),
        elevation: 0,
      ),
      body: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: _StudyOverview(
                    totalStudySeconds: studyState.totalStudySeconds,
                    totalAnnotations: studyState.totalAnnotations,
                    studyStreak: studyState.studyStreak,
                    studiedGameCount: studyState.studiedGames.length,
                  ),
                ),
              ),
              const SliverPadding(padding: EdgeInsets.only(top: 8)),
              if (sorted.isEmpty)
                const SliverFillRemaining(
                  child: Center(
                    child: Padding(
                      padding: EdgeInsets.all(24),
                      child: Text(
                        '対局履歴がありません。\n対局を完了すると、ここで研究できるようになります。',
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                )
              else
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final record = sorted[index];
                      final studied = studyState.getOrCreate(record.id);
                      return Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        child: _StudyGameCard(
                          record: record,
                          studied: studied,
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => StudyDetailScreen(
                                  record: record,
                                ),
                              ),
                            );
                          },
                        ),
                      );
                    },
                    childCount: sorted.length,
                  ),
                ),
              const SliverPadding(padding: EdgeInsets.only(bottom: 32)),
            ],
          ),
    );
  }
}

/// Study overview header
class _StudyOverview extends StatelessWidget {
  final int totalStudySeconds;
  final int totalAnnotations;
  final int studyStreak;
  final int studiedGameCount;

  const _StudyOverview({
    required this.totalStudySeconds,
    required this.totalAnnotations,
    required this.studyStreak,
    required this.studiedGameCount,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final minutes = totalStudySeconds ~/ 60;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.teal.withValues(alpha: 0.8),
            Colors.blue.withValues(alpha: 0.6),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.teal.withValues(alpha: 0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            '棋譜を振り返り、実力アップ',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: Colors.white.withValues(alpha: 0.9),
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _OverviewStat(emoji: '⏱️', value: '$minutes分', label: '研究時間'),
              _OverviewStat(
                  emoji: '📝', value: '$totalAnnotations', label: '注釈数'),
              _OverviewStat(
                  emoji: '🔥', value: '$studyStreak日', label: '継続日数'),
              _OverviewStat(
                  emoji: '📚', value: '$studiedGameCount', label: '研究対局数'),
            ],
          ),
        ],
      ),
    );
  }
}

class _OverviewStat extends StatelessWidget {
  final String emoji;
  final String value;
  final String label;

  const _OverviewStat({
    required this.emoji,
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Text(emoji, style: const TextStyle(fontSize: 22)),
        const SizedBox(height: 6),
        Text(
          value,
          style: theme.textTheme.bodyLarge?.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: Colors.white.withValues(alpha: 0.85),
          ),
        ),
      ],
    );
  }
}

/// Study game card
class _StudyGameCard extends StatelessWidget {
  final GameRecord record;
  final StudiedGame studied;
  final VoidCallback onTap;

  const _StudyGameCard({
    required this.record,
    required this.studied,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasStudy = studied.studySessionCount > 0;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Colors.teal.withValues(alpha: 0.08),
              Colors.blue.withValues(alpha: 0.04),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          border: Border.all(
            color: studied.isCompleted
                ? Colors.green.withValues(alpha: 0.5)
                : Colors.teal.withValues(alpha: 0.2),
            width: studied.isCompleted ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: Colors.teal.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Center(
                child: Text(
                  studied.isCompleted ? '✅' : '📖',
                  style: const TextStyle(fontSize: 22),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    record.resultDisplay,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${record.totalMoves}手 · ${record.durationDisplay} · ${_formatDate(record.playedAt)}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: Colors.grey.shade600,
                    ),
                  ),
                  if (hasStudy) ...[
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        if (studied.annotations.isNotEmpty) ...[
                          const Icon(Icons.edit_note, size: 14, color: Colors.blue),
                          const SizedBox(width: 2),
                          Text(
                            '${studied.annotations.length}',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: Colors.blue,
                            ),
                          ),
                          const SizedBox(width: 10),
                        ],
                        if (studied.bookmarkedMoves.isNotEmpty) ...[
                          const Icon(Icons.bookmark, size: 14, color: Colors.orange),
                          const SizedBox(width: 2),
                          Text(
                            '${studied.bookmarkedMoves.length}',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: Colors.orange,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ],
              ),
            ),
            const Icon(Icons.chevron_right),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.year}/${date.month}/${date.day}';
  }
}

/// Detail screen for studying a single game
class StudyDetailScreen extends ConsumerStatefulWidget {
  final GameRecord record;

  const StudyDetailScreen({super.key, required this.record});

  @override
  ConsumerState<StudyDetailScreen> createState() => _StudyDetailScreenState();
}

class _StudyDetailScreenState extends ConsumerState<StudyDetailScreen> {
  final Stopwatch _stopwatch = Stopwatch();
  int? _selectedMoveIndex;

  @override
  void initState() {
    super.initState();
    _stopwatch.start();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(replayStudyProvider.notifier).startStudySession(widget.record.id);
    });
  }

  @override
  void dispose() {
    _stopwatch.stop();
    final seconds = _stopwatch.elapsed.inSeconds;
    if (seconds > 0) {
      ref
          .read(replayStudyProvider.notifier)
          .addStudyTime(widget.record.id, seconds);
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final studyState = ref.watch(replayStudyProvider);
    final studied = studyState.getOrCreate(widget.record.id);

    return Scaffold(
          backgroundColor: theme.scaffoldBackgroundColor,
          appBar: AppBar(
            title: Text('研究: ${widget.record.resultDisplay}'),
            actions: [
              IconButton(
                icon: Icon(
                  studied.isCompleted
                      ? Icons.check_circle
                      : Icons.check_circle_outline,
                  color: studied.isCompleted ? Colors.green : null,
                ),
                tooltip: '研究完了としてマーク',
                onPressed: () {
                  ref
                      .read(replayStudyProvider.notifier)
                      .markCompleted(widget.record.id, !studied.isCompleted);
                },
              ),
            ],
          ),
          body: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${widget.record.totalMoves}手 · ${widget.record.durationDisplay}',
                      style: theme.textTheme.bodyMedium,
                    ),
                    Text(
                      '${studied.studySessionCount}回目の研究',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: widget.record.moveList.length,
                  itemBuilder: (context, index) {
                    final moveNotation = widget.record.moveList[index];
                    MoveAnnotation? annotation;
                    for (final a in studied.annotations) {
                      if (a.moveIndex == index) {
                        annotation = a;
                        break;
                      }
                    }
                    final isBookmarked =
                        studied.bookmarkedMoves.contains(index);
                    final isSelected = _selectedMoveIndex == index;

                    return _MoveRow(
                      moveNumber: index + 1,
                      notation: moveNotation,
                      annotation: annotation,
                      isBookmarked: isBookmarked,
                      isSelected: isSelected,
                      onTap: () {
                        setState(() {
                          _selectedMoveIndex = isSelected ? null : index;
                        });
                      },
                      onBookmarkToggle: () {
                        ref
                            .read(replayStudyProvider.notifier)
                            .toggleBookmark(widget.record.id, index);
                      },
                      onAnnotate: () => _showAnnotationDialog(
                        context,
                        index,
                        annotation,
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
    );
  }

  void _showAnnotationDialog(
    BuildContext context,
    int moveIndex,
    MoveAnnotation? existing,
  ) {
    final controller = TextEditingController(text: existing?.note ?? '');
    MoveTag? selectedTag = existing?.tag;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text('${moveIndex + 1}手目に注釈を追加'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: controller,
                autofocus: true,
                maxLines: 3,
                decoration: const InputDecoration(
                  hintText: 'この手についてのメモ',
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                children: MoveTag.values.map((tag) {
                  final isSelected = selectedTag == tag;
                  return ChoiceChip(
                    label: Text('${tag.emoji} ${tag.label}'),
                    selected: isSelected,
                    onSelected: (selected) {
                      setDialogState(() {
                        selectedTag = selected ? tag : null;
                      });
                    },
                  );
                }).toList(),
              ),
            ],
          ),
          actions: [
            if (existing != null)
              TextButton(
                onPressed: () {
                  ref
                      .read(replayStudyProvider.notifier)
                      .removeAnnotation(widget.record.id, moveIndex);
                  Navigator.pop(context);
                },
                child: const Text('削除', style: TextStyle(color: Colors.red)),
              ),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('キャンセル'),
            ),
            FilledButton(
              onPressed: () {
                if (controller.text.trim().isNotEmpty || selectedTag != null) {
                  ref.read(replayStudyProvider.notifier).addAnnotation(
                        widget.record.id,
                        moveIndex,
                        controller.text.trim(),
                        tag: selectedTag,
                      );
                }
                Navigator.pop(context);
              },
              child: const Text('保存'),
            ),
          ],
        ),
      ),
    );
  }
}

/// A single move row with optional annotation and bookmark
class _MoveRow extends StatelessWidget {
  final int moveNumber;
  final String notation;
  final MoveAnnotation? annotation;
  final bool isBookmarked;
  final bool isSelected;
  final VoidCallback onTap;
  final VoidCallback onBookmarkToggle;
  final VoidCallback onAnnotate;

  const _MoveRow({
    required this.moveNumber,
    required this.notation,
    required this.annotation,
    required this.isBookmarked,
    required this.isSelected,
    required this.onTap,
    required this.onBookmarkToggle,
    required this.onAnnotate,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Container(
        decoration: BoxDecoration(
          color: isSelected
              ? Colors.blue.withValues(alpha: 0.08)
              : Colors.grey.withValues(alpha: 0.04),
          border: Border.all(
            color: isSelected
                ? Colors.blue.withValues(alpha: 0.4)
                : Colors.grey.withValues(alpha: 0.15),
          ),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          children: [
            InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(10),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                child: Row(
                  children: [
                    SizedBox(
                      width: 32,
                      child: Text(
                        '$moveNumber',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Text(
                        notation,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    if (annotation?.tag != null) ...[
                      Text(annotation!.tag!.emoji,
                          style: const TextStyle(fontSize: 16)),
                      const SizedBox(width: 6),
                    ],
                    IconButton(
                      icon: Icon(
                        isBookmarked ? Icons.bookmark : Icons.bookmark_border,
                        color: isBookmarked ? Colors.orange : Colors.grey,
                        size: 20,
                      ),
                      onPressed: onBookmarkToggle,
                      constraints: const BoxConstraints(
                          minWidth: 32, minHeight: 32),
                      padding: EdgeInsets.zero,
                    ),
                    IconButton(
                      icon: Icon(
                        annotation != null
                            ? Icons.edit_note
                            : Icons.note_add_outlined,
                        color: annotation != null ? Colors.blue : Colors.grey,
                        size: 20,
                      ),
                      onPressed: onAnnotate,
                      constraints: const BoxConstraints(
                          minWidth: 32, minHeight: 32),
                      padding: EdgeInsets.zero,
                    ),
                  ],
                ),
              ),
            ),
            if (annotation != null && annotation!.note.isNotEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    annotation!.note,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: Colors.grey.shade700,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
