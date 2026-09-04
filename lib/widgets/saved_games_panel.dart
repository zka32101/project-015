import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../engine/game_storage.dart';
import '../engine/game_replay.dart';
import '../engine/models.dart';
import '../viewmodels/game_view_model.dart';

/// Panel for browsing and managing saved games
class SavedGamesPanel extends ConsumerStatefulWidget {
  final VoidCallback onGameSelected;

  const SavedGamesPanel({
    Key? key,
    required this.onGameSelected,
  }) : super(key: key);

  @override
  ConsumerState<SavedGamesPanel> createState() => _SavedGamesPanelState();
}

class _SavedGamesPanelState extends ConsumerState<SavedGamesPanel> {
  late Future<List<SavedGameInfo>> _gamesFuture;

  @override
  void initState() {
    super.initState();
    _gamesFuture = GameStorage.getSavedGames();
  }

  void _refreshGames() {
    setState(() {
      _gamesFuture = GameStorage.getSavedGames();
    });
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<SavedGameInfo>>(
      future: _gamesFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(
            child: CircularProgressIndicator(),
          );
        }

        if (snapshot.hasError) {
          return Center(
            child: Text('Error loading games: ${snapshot.error}'),
          );
        }

        final games = snapshot.data ?? [];

        if (games.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.folder_open,
                  size: 48,
                  color: Colors.white30,
                ),
                const SizedBox(height: 16),
                Text(
                  'No saved games yet',
                  style: TextStyle(
                    color: Colors.white54,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Play a game to save it',
                  style: TextStyle(
                    color: Colors.white38,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(12),
          itemCount: games.length,
          itemBuilder: (context, index) {
            final game = games[index];
            return _SavedGameTile(
              gameInfo: game,
              onSelected: () {
                // Load and start replay
                widget.onGameSelected();
              },
              onDelete: () {
                _deleteGame(game.id);
              },
            );
          },
        );
      },
    );
  }

  Future<void> _deleteGame(String gameId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Game?'),
        content: const Text('This game will be permanently deleted.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed ?? false) {
      await GameStorage.deleteGame(gameId);
      _refreshGames();
    }
  }
}

/// Individual saved game tile
class _SavedGameTile extends StatelessWidget {
  final SavedGameInfo gameInfo;
  final VoidCallback onSelected;
  final VoidCallback onDelete;

  const _SavedGameTile({
    required this.gameInfo,
    required this.onSelected,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.3),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Colors.white10,
          width: 1,
        ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        title: Text(
          gameInfo.getDisplayName(),
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              gameInfo.record.result ?? 'In progress',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 12,
              ),
            ),
            Text(
              gameInfo.getTimeDisplay(),
              style: TextStyle(
                color: Colors.white54,
                fontSize: 11,
              ),
            ),
          ],
        ),
        trailing: PopupMenuButton(
          itemBuilder: (context) => [
            PopupMenuItem(
              child: const Text('Replay'),
              onTap: onSelected,
            ),
            PopupMenuItem(
              child: const Text('Delete'),
              onTap: onDelete,
            ),
          ],
        ),
        onTap: onSelected,
      ),
    );
  }
}

/// Storage statistics display
class StorageStatsDisplay extends ConsumerWidget {
  const StorageStatsDisplay({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return FutureBuilder<StorageStats>(
      future: GameStorage.getStorageStats(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox.shrink();
        }

        final stats = snapshot.data ?? StorageStats.empty();

        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'ストレージ',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 8),
              LinearProgressIndicator(
                value: stats.usagePercent,
                backgroundColor: Colors.grey[700],
                valueColor: AlwaysStoppedAnimation<Color>(
                  stats.usagePercent > 0.8
                      ? Colors.red[600]!
                      : Colors.blue[600]!,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    stats.usageString,
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 11,
                    ),
                  ),
                  Text(
                    stats.formattedSize,
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Quick save button for current game
class QuickSaveButton extends ConsumerWidget {
  final Function(bool success) onSaveComplete;

  const QuickSaveButton({
    Key? key,
    required this.onSaveComplete,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final gameState = ref.watch(gameViewModelProvider);

    if (gameState.game.moveHistory.isEmpty) {
      return const SizedBox.shrink();
    }

    return ElevatedButton.icon(
      onPressed: () async {
        final record = ref.read(gameViewModelProvider.notifier).createGameRecord();
        final success = await GameStorage.saveGame(record);

        onSaveComplete(success);

        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('ゲームを保存しました'),
              duration: Duration(seconds: 2),
            ),
          );
        }
      },
      icon: const Icon(Icons.save),
      label: const Text('Save Game'),
    );
  }
}

/// Load game confirmation dialog
class LoadGameDialog extends StatelessWidget {
  final SavedGameInfo gameInfo;
  final VoidCallback onLoad;

  const LoadGameDialog({
    Key? key,
    required this.gameInfo,
    required this.onLoad,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Load Game?'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Game: ${gameInfo.getDisplayName()}'),
          const SizedBox(height: 8),
          Text('Result: ${gameInfo.record.result ?? "In progress"}'),
          const SizedBox(height: 8),
          Text(
            'Saved: ${gameInfo.getTimeDisplay()}',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 12,
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            Navigator.pop(context);
            onLoad();
          },
          child: const Text('Load'),
        ),
      ],
    );
  }
}

/// Show saved games bottom sheet
void showSavedGamesSheet(BuildContext context) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    builder: (context) => Container(
      height: MediaQuery.of(context).size.height * 0.8,
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: Colors.white10,
                ),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '保存済みゲーム',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Colors.white,
                      ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white70),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          Expanded(
            child: SavedGamesPanel(
              onGameSelected: () => Navigator.pop(context),
            ),
          ),
        ],
      ),
    ),
  );
}
