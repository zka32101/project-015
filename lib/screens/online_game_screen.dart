import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../engine/game_notation.dart';
import '../engine/game_state.dart';
import '../engine/models.dart';
import '../engine/move_generator.dart';
import '../providers/multiplayer_provider.dart';

/// Plays a live, Firestore-synced online match.
///
/// Deliberately simpler than the single-player board in game_screen.dart
/// (no theme transitions, long-press previews, undo/redo, or session/rank
/// recording): this is a separate, self-contained screen so online play
/// can't regress the well-tested single-player experience, at the cost of
/// less visual polish for now.
///
/// Both clients independently replay the same move list (synced via
/// [MultiplayerNotifier.pushMove]) through the identical GameState engine
/// single-player uses, so they always reach the same board and the same
/// game-over determination without needing to trust anything but the move
/// order itself.
class OnlineGameScreen extends ConsumerStatefulWidget {
  const OnlineGameScreen({super.key});

  @override
  ConsumerState<OnlineGameScreen> createState() => _OnlineGameScreenState();
}

class _OnlineGameScreenState extends ConsumerState<OnlineGameScreen> {
  final GameState _game = GameState.initial();
  int _appliedMoveCount = 0;
  Square? _selected;
  bool _matchEnded = false;

  @override
  Widget build(BuildContext context) {
    final match = ref.watch(multiplayerProvider.select((s) => s.currentMatch));
    if (match == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    _applyRemoteMoves(match);

    if (_game.isOver && !_matchEnded) {
      _matchEnded = true;
      WidgetsBinding.instance.addPostFrameCallback((_) => _endMatch(match));
    }

    final myUid = ref.read(multiplayerProvider.notifier).myUid;
    final myRole = myUid == match.player1Uid ? 'player1' : 'player2';
    final myOwner = myRole == 'player1' ? Owner.playerA : Owner.playerB;
    final isMyTurn = match.currentTurn == myRole && !_game.isOver;

    final legalDestinations = _selected == null
        ? const <Square>{}
        : MoveGenerator.legalMovesFor(_game.board, myOwner)
            .where((m) => m.from == _selected)
            .map((m) => m.to)
            .toSet();

    return Scaffold(
      appBar: AppBar(
        title: Text(
          _game.isOver
              ? '対局終了'
              : (isMyTurn ? 'あなたの番です' : '相手の番です'),
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('${match.player1AvatarEmoji} ${match.player1Name}'),
                const Text('vs'),
                Text('${match.player2AvatarEmoji} ${match.player2Name}'),
              ],
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: AspectRatio(
                aspectRatio: 1,
                child: GridView.builder(
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate:
                      const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 6),
                  itemCount: 36,
                  itemBuilder: (context, index) {
                    final square = Square(index ~/ 6, index % 6);
                    return _OnlineBoardCell(
                      key: Key('online_cell_${square.row}_${square.col}'),
                      piece: _game.board.at(square),
                      isSelected: _selected == square,
                      isLegalDestination: legalDestinations.contains(square),
                      onTap: isMyTurn ? () => _onTapSquare(square, myOwner) : null,
                    );
                  },
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: OutlinedButton(
              onPressed: () => ref.read(multiplayerProvider.notifier).exitMatch(),
              child: Text(_game.isOver ? 'ロビーに戻る' : '退出'),
            ),
          ),
        ],
      ),
    );
  }

  void _applyRemoteMoves(MultiplayerMatch match) {
    while (_appliedMoveCount < match.moves.length) {
      final notation = match.moves[_appliedMoveCount];
      final move = Move(
        GameNotation.notationToSquare(notation.substring(0, 2))!,
        GameNotation.notationToSquare(notation.substring(2, 4))!,
      );
      if (!_game.isOver) {
        _game.applyMove(move);
      }
      _appliedMoveCount++;
    }
  }

  void _onTapSquare(Square square, Owner myOwner) {
    final selected = _selected;
    if (selected != null) {
      final legal = MoveGenerator.legalMovesFor(_game.board, myOwner)
          .where((m) => m.from == selected && m.to == square);
      if (legal.isNotEmpty) {
        final move = legal.first;
        setState(() {
          _game.applyMove(move);
          _appliedMoveCount = _game.moveHistory.length;
          _selected = null;
        });
        _pushLocalMove(move);
        return;
      }
    }

    final piece = _game.board.at(square);
    setState(() {
      _selected = piece?.owner == myOwner ? square : null;
    });
  }

  void _pushLocalMove(Move move) {
    final match = ref.read(multiplayerProvider).currentMatch;
    if (match == null) return;
    final nextTurn = match.currentTurn == 'player1' ? 'player2' : 'player1';
    ref.read(multiplayerProvider.notifier).pushMove(
          move: move,
          moveCount: _game.moveHistory.length,
          currentTurn: nextTurn,
          player1Pieces: _game.board.pieceCount(Owner.playerA).toDouble(),
          player2Pieces: _game.board.pieceCount(Owner.playerB).toDouble(),
        );
  }

  void _endMatch(MultiplayerMatch match) {
    String winner;
    int winnerGain = 0;
    int loserLoss = 0;
    switch (_game.result) {
      case GameResult.playerAWins:
        winner = match.player1Name;
        winnerGain = 20;
        loserLoss = 20;
        break;
      case GameResult.playerBWins:
        winner = match.player2Name;
        winnerGain = 20;
        loserLoss = 20;
        break;
      case GameResult.draw:
      case GameResult.ongoing:
        winner = '引き分け';
        break;
    }

    ref.read(multiplayerProvider.notifier).endMatch(
          winner: winner,
          winnerRatingGain: winnerGain,
          loserRatingLoss: loserLoss,
        );
  }
}

class _OnlineBoardCell extends StatelessWidget {
  final Piece? piece;
  final bool isSelected;
  final bool isLegalDestination;
  final VoidCallback? onTap;

  const _OnlineBoardCell({
    super.key,
    required this.piece,
    required this.isSelected,
    required this.isLegalDestination,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.all(1.5),
        decoration: BoxDecoration(
          color: isSelected
              ? Colors.amber.withValues(alpha: 0.4)
              : (isLegalDestination
                  ? Colors.green.withValues(alpha: 0.3)
                  : Colors.brown.withValues(alpha: 0.3)),
          border: Border.all(color: Colors.brown.shade700),
        ),
        child: Center(child: _pieceLabel()),
      ),
    );
  }

  Widget? _pieceLabel() {
    final currentPiece = piece;
    if (currentPiece == null) return null;
    final color =
        currentPiece.owner == Owner.playerA ? Colors.blue.shade800 : Colors.red.shade800;
    final label = currentPiece.type == PieceType.king
        ? '★'
        : (currentPiece.face == Face.front ? '●' : '○');
    return Text(
      label,
      style: TextStyle(color: color, fontSize: 20, fontWeight: FontWeight.bold),
    );
  }
}
