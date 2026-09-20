import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/friends_provider.dart';

class FriendsScreen extends ConsumerWidget {
  const FriendsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final friendsState = ref.watch(friendsProvider);
    final theme = Theme.of(context);

    return DefaultTabController(
          length: 4,
          child: Scaffold(
            backgroundColor: theme.scaffoldBackgroundColor,
            appBar: AppBar(
              title: const Text('フレンド'),
              elevation: 0,
              actions: [
                IconButton(
                  key: const Key('add_friend_button'),
                  icon: const Icon(Icons.person_add),
                  tooltip: 'フレンド追加',
                  onPressed: () => _showAddFriendDialog(context, ref),
                ),
              ],
              bottom: TabBar(
                isScrollable: true,
                tabs: [
                  const Tab(text: 'フレンド'),
                  Tab(
                    child: _TabWithBadge(
                      label: '申請',
                      count: friendsState.incomingRequestCount,
                    ),
                  ),
                  const Tab(text: 'アクティビティ'),
                  Tab(
                    child: _TabWithBadge(
                      label: '対戦挑戦',
                      count: friendsState.challenges
                          .where((c) =>
                              c.isIncoming &&
                              !c.isAccepted &&
                              !c.isDeclined)
                          .length,
                    ),
                  ),
                ],
              ),
            ),
            body: TabBarView(
              children: [
                _FriendsList(friends: friendsState.friends),
                _RequestsList(requests: friendsState.friendRequests),
                _ActivityFeed(entries: friendsState.activityFeed),
                _ChallengesList(challenges: friendsState.challenges),
              ],
            ),
          ),
    );
  }

  void _showAddFriendDialog(BuildContext context, WidgetRef ref) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('フレンド申請を送る'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'プレイヤー名を入力',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('キャンセル'),
          ),
          FilledButton(
            onPressed: () {
              ref
                  .read(friendsProvider.notifier)
                  .sendFriendRequest(controller.text);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('${controller.text}に申請を送りました')),
              );
            },
            child: const Text('送信'),
          ),
        ],
      ),
    );
  }
}

/// Tab label with a notification badge
class _TabWithBadge extends StatelessWidget {
  final String label;
  final int count;

  const _TabWithBadge({required this.label, required this.count});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(label),
        if (count > 0) ...[
          const SizedBox(width: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.red,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              '$count',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ],
    );
  }
}

/// Friends list tab
class _FriendsList extends ConsumerWidget {
  final List<Friend> friends;

  const _FriendsList({required this.friends});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (friends.isEmpty) {
      return const Center(child: Text('フレンドがいません'));
    }

    final sorted = [...friends]..sort((a, b) {
        if (a.isFavorite != b.isFavorite) {
          return a.isFavorite ? -1 : 1;
        }
        return a.status.index.compareTo(b.status.index);
      });

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: sorted.length,
      itemBuilder: (context, index) {
        final friend = sorted[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: _FriendCard(friend: friend),
        );
      },
    );
  }
}

/// Friend card
class _FriendCard extends ConsumerWidget {
  final Friend friend;

  const _FriendCard({required this.friend});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final statusColor = _getStatusColor(friend.status);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.blue.withValues(alpha: 0.06),
            Colors.purple.withValues(alpha: 0.03),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(color: Colors.blue.withValues(alpha: 0.15)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Stack(
            children: [
              CircleAvatar(
                radius: 26,
                backgroundColor: Colors.blue.withValues(alpha: 0.15),
                child: Text(
                  friend.avatarEmoji,
                  style: const TextStyle(fontSize: 26),
                ),
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  width: 14,
                  height: 14,
                  decoration: BoxDecoration(
                    color: statusColor,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: theme.scaffoldBackgroundColor,
                      width: 2,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        friend.name,
                        style: theme.textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (friend.isFavorite) ...[
                      const SizedBox(width: 4),
                      const Text('⭐', style: TextStyle(fontSize: 12)),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  '${friend.status.label} · Rating ${friend.rating}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: statusColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '対戦成績 ${friend.winsAgainst}勝${friend.lossesAgainst}敗${friend.drawsAgainst}分',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
          Column(
            children: [
              IconButton(
                icon: Icon(
                  friend.isFavorite ? Icons.star : Icons.star_border,
                  color: Colors.amber,
                ),
                onPressed: () => ref
                    .read(friendsProvider.notifier)
                    .toggleFavorite(friend.id),
              ),
              IconButton(
                icon: const Icon(Icons.sports_esports),
                tooltip: '対戦を申し込む',
                onPressed: () {
                  ref.read(friendsProvider.notifier).sendChallenge(friend);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('${friend.name}に対戦を申し込みました')),
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(FriendStatus status) {
    return switch (status) {
      FriendStatus.online => Colors.green,
      FriendStatus.inGame => Colors.blue,
      FriendStatus.away => Colors.orange,
      FriendStatus.offline => Colors.grey,
    };
  }
}

/// Requests list tab
class _RequestsList extends ConsumerWidget {
  final List<FriendRequest> requests;

  const _RequestsList({required this.requests});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (requests.isEmpty) {
      return const Center(child: Text('申請はありません'));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: requests.length,
      itemBuilder: (context, index) {
        final request = requests[index];
        final theme = Theme.of(context);
        final isIncoming =
            request.direction == FriendRequestDirection.incoming;

        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey.withValues(alpha: 0.06),
              border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: Colors.blue.withValues(alpha: 0.15),
                  child: Text(
                    request.avatarEmoji,
                    style: const TextStyle(fontSize: 24),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        request.name,
                        style: theme.textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        isIncoming
                            ? 'Rating ${request.rating} · 申請中'
                            : 'Rating ${request.rating} · 送信済み',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                if (isIncoming)
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.check_circle, color: Colors.green),
                        onPressed: () => ref
                            .read(friendsProvider.notifier)
                            .acceptRequest(request),
                      ),
                      IconButton(
                        icon: const Icon(Icons.cancel, color: Colors.red),
                        onPressed: () => ref
                            .read(friendsProvider.notifier)
                            .declineRequest(request),
                      ),
                    ],
                  )
                else
                  Text(
                    '⏳',
                    style: theme.textTheme.titleMedium,
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// Activity feed tab
class _ActivityFeed extends StatelessWidget {
  final List<ActivityEntry> entries;

  const _ActivityFeed({required this.entries});

  @override
  Widget build(BuildContext context) {
    if (entries.isEmpty) {
      return const Center(child: Text('アクティビティはありません'));
    }

    final theme = Theme.of(context);

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: entries.length,
      itemBuilder: (context, index) {
        final entry = entries[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.purple.withValues(alpha: 0.05),
              border: Border.all(color: Colors.purple.withValues(alpha: 0.15)),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Text(entry.friendAvatarEmoji,
                    style: const TextStyle(fontSize: 24)),
                const SizedBox(width: 10),
                Expanded(
                  child: RichText(
                    text: TextSpan(
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.textTheme.bodyMedium?.color,
                      ),
                      children: [
                        TextSpan(
                          text: entry.friendName,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        TextSpan(text: 'が${entry.message} ${entry.emoji}'),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  _formatTime(entry.timestamp),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  String _formatTime(DateTime time) {
    final diff = DateTime.now().difference(time);
    if (diff.inHours < 1) return '${diff.inMinutes}分前';
    if (diff.inHours < 24) return '${diff.inHours}時間前';
    return '${diff.inDays}日前';
  }
}

/// Challenges list tab
class _ChallengesList extends ConsumerWidget {
  final List<FriendChallenge> challenges;

  const _ChallengesList({required this.challenges});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (challenges.isEmpty) {
      return const Center(child: Text('対戦挑戦はありません'));
    }

    final theme = Theme.of(context);

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: challenges.length,
      itemBuilder: (context, index) {
        final challenge = challenges[index];
        final resolved = challenge.isAccepted || challenge.isDeclined;

        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: challenge.isAccepted
                  ? Colors.green.withValues(alpha: 0.08)
                  : challenge.isDeclined
                      ? Colors.grey.withValues(alpha: 0.08)
                      : Colors.orange.withValues(alpha: 0.08),
              border: Border.all(
                color: challenge.isAccepted
                    ? Colors.green.withValues(alpha: 0.3)
                    : challenge.isDeclined
                        ? Colors.grey.withValues(alpha: 0.3)
                        : Colors.orange.withValues(alpha: 0.3),
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Text(challenge.friendAvatarEmoji,
                    style: const TextStyle(fontSize: 28)),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        challenge.isIncoming
                            ? '${challenge.friendName}からの挑戦'
                            : '${challenge.friendName}に挑戦中',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        challenge.isAccepted
                            ? '承諾済み'
                            : challenge.isDeclined
                                ? '辞退済み'
                                : '回答待ち',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                if (challenge.isIncoming && !resolved)
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.check_circle,
                            color: Colors.green),
                        onPressed: () => ref
                            .read(friendsProvider.notifier)
                            .respondToChallenge(challenge, accept: true),
                      ),
                      IconButton(
                        icon: const Icon(Icons.cancel, color: Colors.red),
                        onPressed: () => ref
                            .read(friendsProvider.notifier)
                            .respondToChallenge(challenge, accept: false),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}
