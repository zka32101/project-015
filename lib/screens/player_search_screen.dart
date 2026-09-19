import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/friends_provider.dart' as friends_provider;
import '../providers/player_search_provider.dart';

class PlayerSearchScreen extends ConsumerStatefulWidget {
  const PlayerSearchScreen({super.key});

  @override
  ConsumerState<PlayerSearchScreen> createState() => _PlayerSearchScreenState();
}

class _PlayerSearchScreenState extends ConsumerState<PlayerSearchScreen>
    with SingleTickerProviderStateMixin {
  late TextEditingController _searchController;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('プレイヤー検索'),
        elevation: 0,
      ),
      body: Column(
        children: [
          _SearchBar(controller: _searchController),
          const SizedBox(height: 8),
          TabBar(
            controller: _tabController,
            tabs: const [
              Tab(text: '検索結果'),
              Tab(text: 'おすすめ'),
              Tab(text: '最近見た'),
            ],
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _SearchResultsTab(controller: _searchController),
                _SuggestedPlayersTab(),
                _RecentlyViewedTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SearchBar extends ConsumerWidget {
  final TextEditingController controller;

  const _SearchBar({required this.controller});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: SearchBar(
        controller: controller,
        hintText: 'プレイヤー名で検索...',
        leading: const Padding(
          padding: EdgeInsets.only(left: 8),
          child: Icon(Icons.search),
        ),
        trailing: controller.text.isNotEmpty
            ? [
                IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    controller.clear();
                    ref.read(playerSearchProvider.notifier).clearSearch();
                  },
                ),
              ]
            : null,
        onChanged: (value) {
          ref.read(playerSearchProvider.notifier).searchPlayers(value);
          (context as Element).markNeedsBuild();
        },
      ),
    );
  }
}

class _SearchResultsTab extends ConsumerWidget {
  final TextEditingController controller;

  const _SearchResultsTab({required this.controller});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final searchState = ref.watch(playerSearchProvider);

    if (controller.text.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search,
              size: 64,
              color: Colors.grey.withAlpha(128),
            ),
            const SizedBox(height: 16),
            Text(
              'プレイヤーを検索してください',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Colors.grey,
                  ),
            ),
          ],
        ),
      );
    }

    if (searchState.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (searchState.results.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.person_off,
              size: 64,
              color: Colors.grey.withAlpha(128),
            ),
            const SizedBox(height: 16),
            Text(
              '「${controller.text}」に一致するプレイヤーが見つかりません',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Colors.grey,
                  ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: searchState.results.length,
      itemBuilder: (context, index) {
        final player = searchState.results[index];
        return _PlayerSearchResultCard(player: player);
      },
    );
  }
}

class _SuggestedPlayersTab extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final searchState = ref.watch(playerSearchProvider);
    final suggested = searchState.getSuggestedPlayers();

    if (suggested.isEmpty) {
      return Center(
        child: Text(
          'おすすめプレイヤーがありません',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            color: Colors.grey,
          ),
        ),
      );
    }

    return ListView.builder(
      itemCount: suggested.length,
      itemBuilder: (context, index) {
        return _PlayerSearchResultCard(player: suggested[index]);
      },
    );
  }
}

class _RecentlyViewedTab extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final searchState = ref.watch(playerSearchProvider);

    if (searchState.recentlyViewed.isEmpty) {
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
              'まだプレイヤーを見ていません',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Colors.grey,
                  ),
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () =>
                  ref.read(playerSearchProvider.notifier).clearRecentlyViewed(),
              child: const Text('履歴をクリア'),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: searchState.recentlyViewed.length,
      itemBuilder: (context, index) {
        return _PlayerSearchResultCard(player: searchState.recentlyViewed[index]);
      },
    );
  }
}

class _PlayerSearchResultCard extends ConsumerWidget {
  final SearchablePlayer player;

  const _PlayerSearchResultCard({required this.player});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isFriend = ref.watch(friends_provider.friendsProvider).maybeWhen(
      data: (friendsState) =>
          friendsState.friends.any((f) => f.id == player.id),
      orElse: () => false,
    );

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: InkWell(
        onTap: () {
          ref.read(playerSearchProvider.notifier).addToRecentlyViewed(player);
          _showPlayerDetailDialog(context, ref, player, isFriend);
        },
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Text(
                player.avatarEmoji,
                style: const TextTheme().displayMedium,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      player.name,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: _getTierColor(player.seasonalTier),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            player.seasonalTier,
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'レート: ${player.rating}',
                          style: theme.textTheme.labelMedium?.copyWith(
                            color: Colors.grey.shade700,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${player.totalWins}勝 ${player.totalLosses}敗 (勝率: ${(player.winRate * 100).toStringAsFixed(1)}%)',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  if (player.isActive)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.green.shade100,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        'オンライン',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: Colors.green.shade700,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    )
                  else
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        'オフライン',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ),
                  const SizedBox(height: 8),
                  if (isFriend)
                    Icon(
                      Icons.check_circle,
                      color: Colors.green.shade700,
                      size: 20,
                    )
                  else
                    const SizedBox(width: 20, height: 20),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getTierColor(String tier) {
    return switch (tier) {
      'マスター' => Colors.red,
      'ダイヤモンド' => Colors.blue,
      'プラチナ' => Colors.cyan,
      'ゴールド' => Colors.yellow.shade700,
      'シルバー' => Colors.grey,
      'ブロンズ' => Colors.orange,
      _ => Colors.blue.shade300,
    };
  }

  void _showPlayerDetailDialog(
    BuildContext context,
    WidgetRef ref,
    SearchablePlayer player,
    bool isFriend,
  ) {
    showDialog(
      context: context,
      builder: (context) => _PlayerDetailDialog(
        player: player,
        isFriend: isFriend,
      ),
    );
  }
}

class _PlayerDetailDialog extends ConsumerWidget {
  final SearchablePlayer player;
  final bool isFriend;

  const _PlayerDetailDialog({
    required this.player,
    required this.isFriend,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    return Dialog(
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                player.avatarEmoji,
                style: const TextTheme().displayLarge,
              ),
              const SizedBox(height: 12),
              Text(
                player.name,
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: _getTierColor(player.seasonalTier),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  player.seasonalTier,
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              _buildStatRow(theme, 'レート', player.rating.toString()),
              _buildStatRow(theme, '総勝数', player.totalWins.toString()),
              _buildStatRow(theme, '総敗数', player.totalLosses.toString()),
              _buildStatRow(theme, 'ドロー', player.totalDraws.toString()),
              _buildStatRow(
                theme,
                '勝率',
                '${(player.winRate * 100).toStringAsFixed(1)}%',
              ),
              _buildStatRow(
                theme,
                '総対局数',
                player.totalGames.toString(),
              ),
              const SizedBox(height: 20),
              if (!isFriend)
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: () {
                      ref
                          .read(friends_provider.friendsProvider.notifier)
                          .sendFriendRequest(player.name);
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('${player.name}にフレンド申請を送信しました'),
                        ),
                      );
                    },
                    child: const Text('フレンド申請を送る'),
                  ),
                )
              else
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.tonal(
                    onPressed: () {
                      ref
                          .read(friends_provider.friendsProvider.notifier)
                          .sendChallenge(friends_provider.Friend(
                            id: player.id,
                            name: player.name,
                            avatarEmoji: player.avatarEmoji,
                            status:
                                friends_provider.FriendStatus.online,
                            rating: player.rating,
                            addedDate: DateTime.now(),
                          ));
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('${player.name}に対戦を申し込みました'),
                        ),
                      );
                    },
                    child: const Text('対戦を申し込む'),
                  ),
                ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('閉じる'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatRow(ThemeData theme, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: Colors.grey.shade700,
            ),
          ),
          Text(
            value,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Color _getTierColor(String tier) {
    return switch (tier) {
      'マスター' => Colors.red,
      'ダイヤモンド' => Colors.blue,
      'プラチナ' => Colors.cyan,
      'ゴールド' => Colors.yellow.shade700,
      'シルバー' => Colors.grey,
      'ブロンズ' => Colors.orange,
      _ => Colors.blue.shade300,
    };
  }
}
