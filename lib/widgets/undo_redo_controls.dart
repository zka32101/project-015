import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../engine/game_undo_redo.dart';
import '../viewmodels/game_view_model.dart';

/// Undo/Redo control buttons for game state management
class UndoRedoControls extends ConsumerWidget {
  final VoidCallback onStateChanged;

  const UndoRedoControls({
    Key? key,
    required this.onStateChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final gameState = ref.watch(gameViewModelProvider);
    final viewModel = ref.read(gameViewModelProvider.notifier);

    // Get the undo/redo manager if available
    final undoRedoManager = viewModel.getUndoRedoManager();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.2),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Undo button
          Tooltip(
            message: 'Undo last move (${undoRedoManager?.undoCount ?? 0})',
            child: IconButton(
              icon: const Icon(Icons.undo),
              onPressed: undoRedoManager?.canUndo ?? false
                  ? () {
                      if (undoRedoManager!.undo()) {
                        onStateChanged();
                      }
                    }
                  : null,
              iconSize: 20,
              constraints: const BoxConstraints(
                minWidth: 36,
                minHeight: 36,
              ),
            ),
          ),

          const SizedBox(width: 4),

          // Move counter display
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '${undoRedoManager?.undoCount ?? 0}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if ((undoRedoManager?.redoCount ?? 0) > 0)
                  Text(
                    '+${undoRedoManager?.redoCount ?? 0}',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 10,
                    ),
                  ),
              ],
            ),
          ),

          const SizedBox(width: 4),

          // Redo button
          Tooltip(
            message: 'Redo move (${undoRedoManager?.redoCount ?? 0})',
            child: IconButton(
              icon: const Icon(Icons.redo),
              onPressed: undoRedoManager?.canRedo ?? false
                  ? () {
                      if (undoRedoManager!.redo()) {
                        onStateChanged();
                      }
                    }
                  : null,
              iconSize: 20,
              constraints: const BoxConstraints(
                minWidth: 36,
                minHeight: 36,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Quick undo button for current game
class QuickUndoButton extends ConsumerWidget {
  final VoidCallback? onUndo;

  const QuickUndoButton({
    Key? key,
    this.onUndo,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final gameState = ref.watch(gameViewModelProvider);
    final viewModel = ref.read(gameViewModelProvider.notifier);
    final undoRedoManager = viewModel.getUndoRedoManager();

    if (!(undoRedoManager?.canUndo ?? false)) {
      return const SizedBox.shrink();
    }

    return ElevatedButton.icon(
      onPressed: () {
        if (undoRedoManager!.undo()) {
          onUndo?.call();
        }
      },
      icon: const Icon(Icons.undo),
      label: const Text('Undo'),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.orange[700],
        foregroundColor: Colors.white,
      ),
    );
  }
}

/// Undo/Redo history display showing recent moves
class UndoRedoHistory extends ConsumerWidget {
  const UndoRedoHistory({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final gameState = ref.watch(gameViewModelProvider);
    final viewModel = ref.read(gameViewModelProvider.notifier);
    final undoRedoManager = viewModel.getUndoRedoManager();

    if ((undoRedoManager?.undoCount ?? 0) == 0 &&
        (undoRedoManager?.redoCount ?? 0) == 0) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.2),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          'No moves to undo/redo',
          style: TextStyle(
            color: Colors.white54,
            fontSize: 12,
            fontStyle: FontStyle.italic,
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.3),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Colors.white10,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'アンドゥ/リドゥ',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Undoable',
                    style: TextStyle(
                      color: Colors.white54,
                      fontSize: 10,
                    ),
                  ),
                  Text(
                    '${undoRedoManager?.undoCount ?? 0} moves',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
              if ((undoRedoManager?.redoCount ?? 0) > 0)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'Redoable',
                      style: TextStyle(
                        color: Colors.white54,
                        fontSize: 10,
                      ),
                    ),
                    Text(
                      '${undoRedoManager?.redoCount ?? 0} moves',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Undo/Redo keyboard shortcuts help
class UndoRedoKeyboardHelp extends StatelessWidget {
  const UndoRedoKeyboardHelp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blue[900]?.withOpacity(0.3),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Colors.blue[300]?.withOpacity(0.5) ?? Colors.blue,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Keyboard Shortcuts',
            style: TextStyle(
              color: Colors.blue[300],
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Text(
                  'Ctrl+Z',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 11,
                    fontFamily: 'Courier',
                  ),
                ),
              ),
              Expanded(
                child: Text(
                  'Undo',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Expanded(
                child: Text(
                  'Ctrl+Y',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 11,
                    fontFamily: 'Courier',
                  ),
                ),
              ),
              Expanded(
                child: Text(
                  'Redo',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 11,
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
