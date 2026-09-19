import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/replay_sharing_provider.dart';

class ReplaySharingScreen extends ConsumerWidget {
  const ReplaySharingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sharingState = ref.watch(replaySharingProvider);
    final theme = Theme.of(context);

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        appBar: AppBar(
          title: const Text('リプレイ共有'),
          elevation: 0,
          bottom: TabBar(
            tabs: [
              const Tab(text: 'コミュニティ'),
              Tab(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.upload),
                    const SizedBox(width: 4),
                    const Text('マイリプレイ'),
                    if (sharingState.mySharedReplays.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(left: 4),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 4,
                            vertical: 1,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.red,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '${sharingState.mySharedReplays.length}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              Tab(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.favorite),
                    const SizedBox(width: 4),
                    const Text('お気に入り'),
                    if (sharingState.favorites.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(left: 4),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 4,
                            vertical: 1,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.red,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '${sharingState.favorites.length}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _CommunityTab(sharingState: sharingState),
            _MyReplaysTab(sharingState: sharingState),
            _FavoritesTab(sharingState: sharingState),
          ],
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () => _showShareDialog(context, ref),
          label: const Text('リプレイを共有'),
          icon: const Icon(Icons.share),
        ),
      ),
    );
  }

  void _showShareDialog(BuildContext context, WidgetRef ref) {
    final titleController = TextEditingController();
    final descriptionController = TextEditingController();
    String selectedDifficulty = 'つよい';
    String selectedWinner = 'あなた';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('リプレイを共有'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: titleController,
                decoration: const InputDecoration(
                  labelText: 'タイトル',
                  hintText: 'e.g., 今日の最高の一局',
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: descriptionController,
                decoration: const InputDecoration(
                  labelText: '説明',
                  hintText: 'このリプレイについて説明してください',
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 16),
              const Text('難易度', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              StatefulBuilder(
                builder: (context, setState) => Row(
                  children: [
                    Expanded(
                      child: SegmentedButton<String>(
                        segments: const [
                          ButtonSegment(label: Text('かんたん'), value: 'かんたん'),
                          ButtonSegment(label: Text('ふつう'), value: 'ふつう'),
                          ButtonSegment(label: Text('つよい'), value: 'つよい'),
                        ],
                        selected: {selectedDifficulty},
                        onSelectionChanged: (Set<String> newSelection) {
                          setState(() {
                            selectedDifficulty = newSelection.first;
                          });
                        },
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              const Text('勝者', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              StatefulBuilder(
                builder: (context, setState) => Row(
                  children: [
                    Expanded(
                      child: SegmentedButton<String>(
                        segments: const [
                          ButtonSegment(label: Text('あなた'), value: 'あなた'),
                          ButtonSegment(label: Text('AI'), value: 'AI'),
                          ButtonSegment(label: Text('引き分け'), value: '引き分け'),
                        ],
                        selected: {selectedWinner},
                        onSelectionChanged: (Set<String> newSelection) {
                          setState(() {
                            selectedWinner = newSelection.first;
                          });
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('キャンセル'),
          ),
          FilledButton(
            onPressed: () {
              if (titleController.text.trim().isNotEmpty) {
                ref.read(replaySharingProvider.notifier).shareReplay(
                      gameTitle: titleController.text,
                      description: descriptionController.text,
                      moveCount: 55,
                      winner: selectedWinner,
                      difficulty: selectedDifficulty,
                    );
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('リプレイを共有しました')),
                );
              }
            },
            child: const Text('共有'),
          ),
        ],
      ),
    );
  }
}

class _CommunityTab extends ConsumerWidget {
  final ReplaySharingState sharingState;

  const _CommunityTab({required this.sharingState});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    if (sharingState.sharedReplays.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.videogame_asset_off,
              size: 64,
              color: Colors.grey.withAlpha(128),
            ),
            const SizedBox(height: 16),
            Text(
              'リプレイがまだありません',
              style: theme.textTheme.titleMedium?.copyWith(
                color: Colors.grey,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: sharingState.sharedReplays.length + 1,
      itemBuilder: (context, index) {
        if (index == sharingState.sharedReplays.length) {
          return Padding(
            padding: const EdgeInsets.all(16),
            child: SizedBox(
              width: double.infinity,
              child: FilledButton.tonal(
                onPressed: () =>
                    ref.read(replaySharingProvider.notifier).loadMoreReplays(),
                child: const Text('さらに読み込む'),
              ),
            ),
          );
        }

        final replay = sharingState.sharedReplays[index];
        return _ReplayCard(
          replay: replay,
          onLike: () =>
              ref.read(replaySharingProvider.notifier).likeReplay(replay.id),
          onFavorite: () =>
              ref.read(replaySharingProvider.notifier).addToFavorites(replay),
        );
      },
    );
  }
}

class _MyReplaysTab extends ConsumerWidget {
  final ReplaySharingState sharingState;

  const _MyReplaysTab({required this.sharingState});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    if (sharingState.mySharedReplays.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.upload_file,
              size: 64,
              color: Colors.grey.withAlpha(128),
            ),
            const SizedBox(height: 16),
            Text(
              'まだリプレイを共有していません',
              style: theme.textTheme.titleMedium?.copyWith(
                color: Colors.grey,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: sharingState.mySharedReplays.length,
      itemBuilder: (context, index) {
        final replay = sharingState.mySharedReplays[index];
        return _MyReplayCard(replay: replay);
      },
    );
  }
}

class _FavoritesTab extends ConsumerWidget {
  final ReplaySharingState sharingState;

  const _FavoritesTab({required this.sharingState});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    if (sharingState.favorites.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.favorite_border,
              size: 64,
              color: Colors.grey.withAlpha(128),
            ),
            const SizedBox(height: 16),
            Text(
              'お気に入りがまだありません',
              style: theme.textTheme.titleMedium?.copyWith(
                color: Colors.grey,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: sharingState.favorites.length,
      itemBuilder: (context, index) {
        final replay = sharingState.favorites[index];
        return _ReplayCard(
          replay: replay,
          onLike: () =>
              ref.read(replaySharingProvider.notifier).likeReplay(replay.id),
          onFavorite: () =>
              ref.read(replaySharingProvider.notifier).removeFromFavorites(
                    replay.id,
                  ),
          isFavorite: true,
        );
      },
    );
  }
}

class _ReplayCard extends StatelessWidget {
  final SharedReplay replay;
  final VoidCallback onLike;
  final VoidCallback onFavorite;
  final bool isFavorite;

  const _ReplayCard({
    required this.replay,
    required this.onLike,
    required this.onFavorite,
    this.isFavorite = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Text(
                      replay.authorAvatarEmoji,
                      style: const TextTheme().titleLarge,
                    ),
                    const SizedBox(width: 8),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          replay.authorName,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          replay.ageInDays.inDays == 0
                              ? '今日'
                              : '${replay.ageInDays.inDays}日前',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: _getDifficultyColor(replay.difficulty),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        replay.difficulty,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    if (replay.winner.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.green.shade100,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          '${replay.winner}勝',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: Colors.green.shade700,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              replay.gameTitle,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              replay.description,
              style: theme.textTheme.bodySmall?.copyWith(
                color: Colors.grey.shade700,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(Icons.preview, size: 16, color: Colors.grey.shade600),
                    const SizedBox(width: 4),
                    Text(
                      '${replay.viewCount}',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Icon(Icons.comment, size: 16, color: Colors.grey.shade600),
                    const SizedBox(width: 4),
                    Text(
                      '${replay.commentCount}',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    IconButton(
                      icon: Icon(
                        isFavorite ? Icons.favorite : Icons.favorite_border,
                        color: isFavorite ? Colors.red : Colors.grey.shade600,
                        size: 20,
                      ),
                      onPressed: onFavorite,
                      constraints: const BoxConstraints(),
                      padding: const EdgeInsets.all(4),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${replay.likeCount}',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(Icons.thumb_up_outlined, size: 20),
                      onPressed: onLike,
                      constraints: const BoxConstraints(),
                      padding: const EdgeInsets.all(4),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color _getDifficultyColor(String difficulty) {
    return switch (difficulty) {
      'つよい' => Colors.red,
      'ふつう' => Colors.orange,
      'かんたん' => Colors.green,
      _ => Colors.blue,
    };
  }
}

class _MyReplayCard extends StatelessWidget {
  final SharedReplay replay;

  const _MyReplayCard({required this.replay});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        replay.gameTitle,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        replay.description,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: Colors.grey.shade700,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.green.shade100,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    '${replay.viewCount}views',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: Colors.green.shade700,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(Icons.thumb_up, size: 16, color: Colors.red),
                    const SizedBox(width: 4),
                    Text(
                      '${replay.likeCount}',
                      style: theme.textTheme.labelSmall,
                    ),
                    const SizedBox(width: 16),
                    Icon(Icons.comment, size: 16, color: Colors.blue),
                    const SizedBox(width: 4),
                    Text(
                      '${replay.commentCount}',
                      style: theme.textTheme.labelSmall,
                    ),
                  ],
                ),
                Row(
                  children: [
                    TextButton.icon(
                      icon: const Icon(Icons.share, size: 18),
                      label: const Text('共有'),
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'リプレイURLをコピー: ${replay.shareUrl}',
                            ),
                          ),
                        );
                      },
                    ),
                    TextButton.icon(
                      icon: const Icon(Icons.play_arrow, size: 18),
                      label: const Text('見る'),
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('リプレイを再生します'),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
