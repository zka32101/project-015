import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../providers/cloud_sync_provider.dart';
import '../viewmodels/game_view_model.dart';

/// Lets the player back up (and restore, on a new device) their rank
/// points, statistics, session history and game records via a Google
/// account. See CloudSyncNotifier for why this needs real sign-in rather
/// than the anonymous auth multiplayer uses.
class CloudSyncScreen extends ConsumerWidget {
  const CloudSyncScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final syncState = ref.watch(cloudSyncProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('クラウド同期')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            'Googleアカウントでサインインすると、ランクポイント・成績・対局履歴をバックアップし、'
            '機種変更や再インストール後に復元できます。',
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: 24),
          if (syncState.error != null) ...[
            Text(
              syncState.error!,
              style: TextStyle(color: theme.colorScheme.error),
            ),
            const SizedBox(height: 12),
          ],
          if (!syncState.isSignedIn)
            FilledButton.icon(
              onPressed: syncState.isSyncing ? null : () => _signIn(context, ref),
              icon: const Icon(Icons.login),
              label: Text(syncState.isSyncing ? 'サインイン中...' : 'Googleでサインイン'),
            )
          else ...[
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.account_circle),
              title: Text(syncState.displayName ?? syncState.email ?? 'サインイン済み'),
              subtitle: syncState.lastSyncedAt != null
                  ? Text('最終同期: ${syncState.lastSyncedAt}')
                  : const Text('未同期'),
            ),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: syncState.isSyncing ? null : () => _syncNow(context, ref),
              icon: const Icon(Icons.cloud_upload),
              label: Text(syncState.isSyncing ? '同期中...' : '今すぐ同期'),
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: () => ref.read(cloudSyncProvider.notifier).signOut(),
              icon: const Icon(Icons.logout),
              label: const Text('サインアウト'),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _signIn(BuildContext context, WidgetRef ref) async {
    final prefs = await SharedPreferences.getInstance();
    final restored = await ref.read(cloudSyncProvider.notifier).signInWithGoogle(prefs);
    if (restored) {
      await ref.read(gameViewModelProvider.notifier).reloadFromPrefs();
    }
    if (!context.mounted) return;
    final message = restored
        ? 'クラウドのバックアップを復元しました'
        : ref.read(cloudSyncProvider).error ?? 'このアカウントの初回バックアップを作成しました';
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _syncNow(BuildContext context, WidgetRef ref) async {
    final prefs = await SharedPreferences.getInstance();
    await ref.read(cloudSyncProvider.notifier).syncNow(prefs);
    if (!context.mounted) return;
    final error = ref.read(cloudSyncProvider).error;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(error ?? '同期しました')),
    );
  }
}
