import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/friends_provider.dart';

/// Runs a friends-provider action and surfaces its error, if any, in a
/// snackbar -- these actions are fire-and-forget from the UI's point of
/// view, so there's no other feedback path for a failed write.
Future<void> _runAndReportError(
  BuildContext context,
  WidgetRef ref,
  Future<void> Function() action,
) async {
  final messenger = ScaffoldMessenger.of(context);
  final notifier = ref.read(friendsProvider.notifier);
  await action();
  final error = notifier.state.error;
  if (error != null) {
    messenger.showSnackBar(SnackBar(content: Text(error)));
    notifier.clearError();
  }
}

class FriendsScreen extends ConsumerWidget {
  const FriendsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final friendsState = ref.watch(friendsProvider);
    final theme = Theme.of(context);

    return DefaultTabController(
      length: 2,
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
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _FriendsList(friends: friendsState.friends),
            _RequestsList(requests: friendsState.friendRequests),
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
            onPressed: () async {
              final name = controller.text;
              final notifier = ref.read(friendsProvider.notifier);
              final messenger = ScaffoldMessenger.of(context);
              Navigator.pop(context);
              await notifier.sendFriendRequest(name);
              final error = notifier.state.error;
              messenger.showSnackBar(
                SnackBar(content: Text(error ?? '$nameに申請を送りました')),
              );
              if (error != null) notifier.clearError();
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
        return b.addedDate.compareTo(a.addedDate);
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
          CircleAvatar(
            radius: 26,
            backgroundColor: Colors.blue.withValues(alpha: 0.15),
            child: const Text('👤', style: TextStyle(fontSize: 26)),
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
                  'Rating ${friend.rating}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: Icon(
              friend.isFavorite ? Icons.star : Icons.star_border,
              color: Colors.amber,
            ),
            onPressed: () =>
                ref.read(friendsProvider.notifier).toggleFavorite(friend.id),
          ),
          IconButton(
            icon: const Icon(Icons.person_remove_outlined),
            tooltip: 'フレンド解除',
            onPressed: () => _runAndReportError(
              context,
              ref,
              () => ref.read(friendsProvider.notifier).removeFriend(friend.id),
            ),
          ),
        ],
      ),
    );
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
                  child: const Text('👤', style: TextStyle(fontSize: 24)),
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
                        onPressed: () => _runAndReportError(
                          context,
                          ref,
                          () => ref
                              .read(friendsProvider.notifier)
                              .acceptRequest(request),
                        ),
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
