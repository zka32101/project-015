import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/multiplayer_provider.dart';

class MultiplayerLobbyScreen extends ConsumerWidget {
  const MultiplayerLobbyScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final multiplayerState = ref.watch(multiplayerProvider);
    final theme = Theme.of(context);

    if (multiplayerState.currentMatch != null) {
      return _MatchFoundPlaceholder(match: multiplayerState.currentMatch!);
    }

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        appBar: AppBar(
          title: const Text('マルチプレイ'),
          elevation: 0,
          actions: [
            IconButton(
              icon: const Icon(Icons.add),
              tooltip: 'ロビーを作成',
              onPressed: () => _showHostLobbyDialog(context, ref),
            ),
          ],
          bottom: TabBar(
            tabs: [
              Tab(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.public),
                    const SizedBox(width: 4),
                    const Text('オンラインロビー'),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.green.shade100,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '${multiplayerState.onlinePlayersCount}人',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: Colors.green.shade700,
                          fontWeight: FontWeight.bold,
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
                    const Icon(Icons.history),
                    const SizedBox(width: 4),
                    const Text('対局履歴'),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade100,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '${multiplayerState.matchHistory.length}局',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: Colors.blue.shade700,
                          fontWeight: FontWeight.bold,
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
            _LobbiesTab(multiplayerState: multiplayerState),
            _MatchHistoryTab(multiplayerState: multiplayerState),
          ],
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () => _showQuickMatchDialog(context, ref),
          label: const Text('クイックマッチ'),
          icon: const Icon(Icons.bolt),
        ),
      ),
    );
  }

  void _showQuickMatchDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('クイックマッチ'),
        content: const Text('マッチメイキング中...\n同等レートのプレイヤーを探しています'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('キャンセル'),
          ),
        ],
      ),
    );

    ref.read(multiplayerProvider.notifier).startQuickMatch().then((_) {
      if (!context.mounted) return;
      Navigator.pop(context);

      final state = ref.read(multiplayerProvider);
      final message = state.currentMatch != null
          ? '対戦相手が見つかりました！'
          : state.error ?? '対戦相手を探しています... 見つかり次第お知らせします';
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
    });
  }

  void _showHostLobbyDialog(BuildContext context, WidgetRef ref) {
    int timeLimit = 10;
    bool isRanked = true;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('ロビーを作成'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              DropdownButtonFormField<int>(
                initialValue: timeLimit,
                decoration: const InputDecoration(labelText: '持ち時間'),
                items: const [5, 10, 15, 30]
                    .map((m) => DropdownMenuItem(value: m, child: Text('$m分')))
                    .toList(),
                onChanged: (value) => setState(() => timeLimit = value ?? timeLimit),
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('ランク戦'),
                value: isRanked,
                onChanged: (value) => setState(() => isRanked = value),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('キャンセル'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.pop(context);
                ref.read(multiplayerProvider.notifier).hostLobby(
                      hostName: 'あなた',
                      hostAvatarEmoji: '🎮',
                      hostRating: 1500,
                      gameMode: isRanked ? 'ランク戦' : 'カジュアル戦',
                      timeLimit: timeLimit,
                      isRanked: isRanked,
                    );
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('ロビーを作成しました。対戦相手を待っています...')),
                );
              },
              child: const Text('作成'),
            ),
          ],
        ),
      ),
    );
  }
}

/// Shown once [MultiplayerState.currentMatch] is set. There is no live,
/// synced game board yet -- pairing (lobby/quick match, opponent identity,
/// turn/piece-count sync) is real and Firestore-backed, but rendering the
/// actual Reversia board for an online match is a separate follow-up.
class _MatchFoundPlaceholder extends ConsumerWidget {
  final MultiplayerMatch match;

  const _MatchFoundPlaceholder({required this.match});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('対戦相手が見つかりました')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('${match.player1AvatarEmoji} ${match.player1Name}'),
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: Text('vs'),
              ),
              Text('${match.player2AvatarEmoji} ${match.player2Name}'),
              const SizedBox(height: 24),
              Text(
                '対局画面は現在開発中です。もうしばらくお待ちください。',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey),
              ),
              const SizedBox(height: 24),
              OutlinedButton(
                onPressed: () => ref.read(multiplayerProvider.notifier).exitMatch(),
                child: const Text('退出'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LobbiesTab extends ConsumerWidget {
  final MultiplayerState multiplayerState;

  const _LobbiesTab({required this.multiplayerState});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    if (multiplayerState.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (multiplayerState.availableLobbies.isEmpty) {
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
              'オンラインロビーがありません',
              style: theme.textTheme.titleMedium?.copyWith(
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 16),
            FilledButton.tonal(
              onPressed: () =>
                  ref.read(multiplayerProvider.notifier).refreshLobbies(),
              child: const Text('更新'),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () =>
          ref.read(multiplayerProvider.notifier).refreshLobbies(),
      child: ListView.builder(
        itemCount: multiplayerState.availableLobbies.length,
        itemBuilder: (context, index) {
          final lobby = multiplayerState.availableLobbies[index];
          return _LobbyCard(
            lobby: lobby,
            onJoin: () {
              ref.read(multiplayerProvider.notifier).joinLobby(lobby.id);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('ロビーに参加しました')),
              );
            },
          );
        },
      ),
    );
  }
}

class _LobbyCard extends StatelessWidget {
  final OnlineLobby lobby;
  final VoidCallback onJoin;

  const _LobbyCard({
    required this.lobby,
    required this.onJoin,
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
                      lobby.hostAvatarEmoji,
                      style: const TextTheme().titleLarge,
                    ),
                    const SizedBox(width: 8),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          lobby.hostName,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'レート: ${lobby.hostRating}',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: lobby.isRanked ? Colors.orange.shade100 : Colors.blue.shade100,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    lobby.isRanked ? 'ランク戦' : 'カジュアル',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color:
                          lobby.isRanked ? Colors.orange.shade700 : Colors.blue.shade700,
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
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.timer,
                          size: 16,
                          color: Colors.grey.shade600,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${lobby.timeLimit}分',
                          style: theme.textTheme.labelMedium?.copyWith(
                            color: Colors.grey.shade600,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Icon(
                          Icons.people,
                          size: 16,
                          color: Colors.grey.shade600,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${lobby.playerCount}/${lobby.maxPlayers}',
                          style: theme.textTheme.labelMedium?.copyWith(
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${lobby.age.inMinutes}分前に作成',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: Colors.grey.shade500,
                      ),
                    ),
                  ],
                ),
                FilledButton(
                  onPressed: lobby.isFull ? null : onJoin,
                  child: const Text('参加'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _MatchHistoryTab extends StatelessWidget {
  final MultiplayerState multiplayerState;

  const _MatchHistoryTab({required this.multiplayerState});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (multiplayerState.matchHistory.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.history,
              size: 64,
              color: Colors.grey.withAlpha(128),
            ),
            const SizedBox(height: 16),
            Text(
              'まだ対局がありません',
              style: theme.textTheme.titleMedium?.copyWith(
                color: Colors.grey,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: multiplayerState.matchHistory.length,
      itemBuilder: (context, index) {
        final result = multiplayerState.matchHistory[index];
        return _MatchResultCard(result: result);
      },
    );
  }
}

class _MatchResultCard extends StatelessWidget {
  final MatchResult result;

  const _MatchResultCard({required this.result});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isPlayer1Winner = result.isWinForPlayer1;

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
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: result.isRanked ? Colors.orange.shade100 : Colors.blue.shade100,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    result.gameMode,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: result.isRanked ? Colors.orange.shade700 : Colors.blue.shade700,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Text(
                  result.playedAt.toString().split('.')[0],
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _PlayerResult(
                  name: result.player1Name,
                  avatarEmoji: result.player1AvatarEmoji,
                  isWinner: isPlayer1Winner,
                  ratingChange: isPlayer1Winner
                      ? result.winnerRatingGain
                      : -result.loserRatingLoss,
                ),
                Expanded(
                  child: Center(
                    child: Text(
                      'vs',
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ),
                ),
                _PlayerResult(
                  name: result.player2Name,
                  avatarEmoji: result.player2AvatarEmoji,
                  isWinner: !isPlayer1Winner,
                  ratingChange: !isPlayer1Winner
                      ? result.winnerRatingGain
                      : -result.loserRatingLoss,
                  alignRight: true,
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '手数: ${result.totalMoves}',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: Colors.grey.shade600,
                  ),
                ),
                Text(
                  '時間: ${result.duration ~/ 60}分${result.duration % 60}秒',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _PlayerResult extends StatelessWidget {
  final String name;
  final String avatarEmoji;
  final bool isWinner;
  final int ratingChange;
  final bool alignRight;

  const _PlayerResult({
    required this.name,
    required this.avatarEmoji,
    required this.isWinner,
    required this.ratingChange,
    this.alignRight = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Expanded(
      child: Column(
        crossAxisAlignment: alignRight ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: alignRight ? MainAxisAlignment.end : MainAxisAlignment.start,
            children: [
              Text(
                avatarEmoji,
                style: const TextTheme().titleLarge,
              ),
              const SizedBox(width: 4),
              Column(
                crossAxisAlignment: alignRight ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: theme.textTheme.labelMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    isWinner ? '勝利' : '敗北',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: isWinner ? Colors.green.shade700 : Colors.red.shade700,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            '${ratingChange > 0 ? '+' : ''}$ratingChange',
            style: theme.textTheme.labelSmall?.copyWith(
              color: ratingChange > 0 ? Colors.green.shade700 : Colors.red.shade700,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
