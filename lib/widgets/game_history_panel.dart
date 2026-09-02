import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../engine/game_notation.dart';
import '../engine/models.dart';
import '../viewmodels/game_view_model.dart';

/// Displays current game in standard algebraic notation
class GameNotationDisplay extends ConsumerWidget {
  const GameNotationDisplay({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final gameState = ref.watch(gameViewModelProvider);
    final viewModel = ref.read(gameViewModelProvider.notifier);

    if (gameState.game.moveHistory.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.2),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          'Game notation will appear here',
          style: TextStyle(
            color: Colors.white70,
            fontSize: 12,
            fontStyle: FontStyle.italic,
          ),
        ),
      );
    }

    final notation = viewModel.getGameNotation();

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
            '棋譜（標準記法）',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: Colors.white70,
                ),
          ),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Text(
              notation,
              style: const TextStyle(
                color: Colors.white,
                fontFamily: 'Courier',
                fontSize: 11,
                letterSpacing: 0.5,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Moves: ${gameState.game.moveHistory.length}',
            style: TextStyle(
              color: Colors.white54,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }
}

/// Detailed game history sheet with turn-by-turn breakdown
class GameHistorySheet extends ConsumerWidget {
  const GameHistorySheet({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final gameState = ref.watch(gameViewModelProvider);
    final viewModel = ref.read(gameViewModelProvider.notifier);

    final moves = gameState.game.moveHistory;
    if (moves.isEmpty) {
      return Center(
        child: Text(
          'No moves yet',
          style: TextStyle(color: Colors.white54),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: (moves.length + 1) ~/ 2,
      itemBuilder: (context, turnIndex) {
        final moveIndex1 = turnIndex * 2;
        final moveIndex2 = turnIndex * 2 + 1;
        final hasSecondMove = moveIndex2 < moves.length;

        final move1 = moves[moveIndex1];
        final move2 = hasSecondMove ? moves[moveIndex2] : null;

        return _TurnHistoryTile(
          turnNumber: turnIndex + 1,
          blackMove: move1,
          whiteMove: move2,
        );
      },
    );
  }
}

/// Single turn in game history
class _TurnHistoryTile extends StatelessWidget {
  final int turnNumber;
  final Move blackMove;
  final Move? whiteMove;

  const _TurnHistoryTile({
    required this.turnNumber,
    required this.blackMove,
    this.whiteMove,
  });

  @override
  Widget build(BuildContext context) {
    final blackNotation = GameNotation.moveToNotation(blackMove);
    final whiteNotation = whiteMove != null ? GameNotation.moveToNotation(whiteMove!) : null;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.2),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        children: [
          // Turn number
          Container(
            width: 40,
            height: 32,
            decoration: BoxDecoration(
              color: Colors.blue[900]?.withOpacity(0.5),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Center(
              child: Text(
                '$turnNumber',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),

          // Black move
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '黒 (Black)',
                  style: TextStyle(
                    color: Colors.white54,
                    fontSize: 10,
                  ),
                ),
                Text(
                  blackNotation,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    fontFamily: 'Courier',
                  ),
                ),
              ],
            ),
          ),

          // White move
          if (whiteNotation != null) ...[
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '白 (White)',
                    style: TextStyle(
                      color: Colors.white54,
                      fontSize: 10,
                    ),
                  ),
                  Text(
                    whiteNotation,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      fontFamily: 'Courier',
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Compact game status with move count
class GameStatusBadge extends ConsumerWidget {
  const GameStatusBadge({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final gameState = ref.watch(gameViewModelProvider);
    final moveCount = gameState.game.moveHistory.length;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.4),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '移動: ',
            style: TextStyle(color: Colors.white70, fontSize: 12),
          ),
          Text(
            '$moveCount',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}

/// Bottom sheet for viewing complete game history
void showGameHistorySheet(BuildContext context) {
  showModalBottomSheet(
    context: context,
    builder: (context) => Container(
      color: Colors.grey[900],
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
                  '棋譜（ゲーム履歴）',
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
            child: GameHistorySheet(),
          ),
        ],
      ),
    ),
  );
}

/// Copy game notation button
class CopyNotationButton extends ConsumerWidget {
  const CopyNotationButton({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final viewModel = ref.read(gameViewModelProvider.notifier);

    return ElevatedButton.icon(
      onPressed: () {
        final notation = viewModel.getGameNotation();
        // Copy to clipboard
        // In a real app: Clipboard.setData(ClipboardData(text: notation))
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('棋譜: $notation'),
            duration: const Duration(seconds: 3),
          ),
        );
      },
      icon: const Icon(Icons.copy),
      label: const Text('Copy notation'),
    );
  }
}
