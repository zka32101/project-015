import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../engine/board_theme.dart';
import '../engine/game_state.dart';
import '../engine/models.dart';
import '../engine/replay.dart';

/// Full-screen game replay viewer with move-by-move navigation.
class KifuViewerScreen extends StatefulWidget {
  final GameState completedGame;
  final BoardTheme theme;

  const KifuViewerScreen({
    super.key,
    required this.completedGame,
    required this.theme,
  });

  @override
  State<KifuViewerScreen> createState() => _KifuViewerScreenState();
}

class _KifuViewerScreenState extends State<KifuViewerScreen> {
  late GameReplay _replay;

  @override
  void initState() {
    super.initState();
    _replay = GameReplay(
      moveHistory: widget.completedGame.moveHistory,
      initialState: GameState.initial(),
    );
    // Start at the end
    _replay.goToEnd();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: widget.theme.screenBackground,
      appBar: AppBar(
        title: const Text('棋譜再生'),
        backgroundColor: widget.theme.woodDark,
      ),
      body: Column(
        children: [
          Expanded(
            flex: 3,
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: AspectRatio(
                  aspectRatio: 1,
                  child: _ReplayBoard(
                    replay: _replay,
                    theme: widget.theme,
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Column(
              children: [
                _ReplayControls(
                  replay: _replay,
                  onChanged: () => setState(() {}),
                ),
                Expanded(
                  child: _MoveList(
                    moveHistory: widget.completedGame.moveHistory,
                    currentMoveIndex: _replay.moveIndex,
                    onSelectMove: (index) {
                      setState(() {
                        _replay.jumpToMove(index);
                      });
                    },
                    theme: widget.theme,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Displays the board at the current replay position.
class _ReplayBoard extends StatelessWidget {
  final GameReplay replay;
  final BoardTheme theme;

  const _ReplayBoard({
    required this.replay,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    final gameState = replay.currentState;
    final lastMove = replay.lastMove;
    final lastMoveSquares = lastMove == null ? <Square>{} : {lastMove.from, lastMove.to};

    return Container(
      decoration: BoxDecoration(
        image: DecorationImage(
          image: AssetImage(theme.woodTextureAsset),
          fit: BoxFit.cover,
        ),
        border: Border.all(color: theme.accentGold, width: 3),
        borderRadius: BorderRadius.circular(4),
      ),
      child: GridView.builder(
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.all(6),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 6),
        itemCount: 36,
        itemBuilder: (context, index) {
          final row = index ~/ 6;
          final col = index % 6;
          final square = Square(row, col);
          final piece = gameState.board.at(square);
          final isDark = (row + col) % 2 == 0;
          final isLastMove = lastMoveSquares.contains(square);

          return Container(
            margin: const EdgeInsets.all(1.5),
            decoration: BoxDecoration(
              color: isDark ? Colors.black.withValues(alpha: 0.22) : Colors.white.withValues(alpha: 0.05),
              border: isLastMove
                  ? Border.all(color: theme.accentGold, width: 2.5)
                  : Border.all(color: Colors.transparent, width: 2.5),
              borderRadius: BorderRadius.circular(3),
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                if (isLastMove)
                  Container(
                    decoration: BoxDecoration(
                      color: theme.accentGold.withValues(alpha: 0.14),
                    ),
                  ),
                if (piece != null)
                  _ReplayPiece(piece: piece, theme: theme),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _ReplayPiece extends StatelessWidget {
  final Piece piece;
  final BoardTheme theme;

  const _ReplayPiece({required this.piece, required this.theme});

  @override
  Widget build(BuildContext context) {
    final isFront = piece.face == Face.front;
    final color = piece.type == PieceType.king
        ? theme.accentGold
        : (isFront ? theme.frontPieceColor : theme.backPieceColor);

    return Container(
      width: 34,
      height: 34,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: const [
          BoxShadow(color: Colors.black45, blurRadius: 3, offset: Offset(1, 1)),
        ],
      ),
      child: ClipOval(
        child: ColorFiltered(
          colorFilter: ColorFilter.mode(color, BlendMode.color),
          child: Image.asset(
            _pieceAssetFor(piece.type, piece.face),
            fit: BoxFit.cover,
          ),
        ),
      ),
    );
  }

  String _pieceAssetFor(PieceType type, Face face) {
    if (type == PieceType.king) return 'assets/images/piece_king.png';
    return face == Face.front
        ? 'assets/images/piece_front.png'
        : 'assets/images/piece_back.png';
  }
}

/// Replay control buttons (first, prev, next, last)
class _ReplayControls extends StatelessWidget {
  final GameReplay replay;
  final VoidCallback onChanged;

  const _ReplayControls({
    required this.replay,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.skip_previous),
                onPressed: replay.isAtStart
                    ? null
                    : () {
                        HapticFeedback.selectionClick();
                        replay.goToStart();
                        onChanged();
                      },
              ),
              IconButton(
                icon: const Icon(Icons.navigate_before),
                onPressed: replay.isAtStart
                    ? null
                    : () {
                        HapticFeedback.selectionClick();
                        replay.goBack();
                        onChanged();
                      },
              ),
              Text(
                '${replay.moveIndex + 1} / ${replay.totalMoves}手',
                style: const TextStyle(color: Colors.white, fontSize: 14),
              ),
              IconButton(
                icon: const Icon(Icons.navigate_next),
                onPressed: replay.isAtEnd
                    ? null
                    : () {
                        HapticFeedback.selectionClick();
                        replay.goForward();
                        onChanged();
                      },
              ),
              IconButton(
                icon: const Icon(Icons.skip_next),
                onPressed: replay.isAtEnd
                    ? null
                    : () {
                        HapticFeedback.selectionClick();
                        replay.goToEnd();
                        onChanged();
                      },
              ),
            ],
          ),
          SliderTheme(
            data: SliderThemeData(
              activeTrackColor: Colors.white54,
              inactiveTrackColor: Colors.white12,
              thumbColor: Colors.white,
              overlayColor: Colors.white30,
            ),
            child: Slider(
              value: (replay.moveIndex + 1).toDouble(),
              min: 1,
              max: replay.totalMoves.toDouble(),
              divisions: replay.totalMoves > 1 ? replay.totalMoves - 1 : 1,
              onChanged: (value) {
                replay.jumpToMove(value.toInt() - 1);
                onChanged();
              },
            ),
          ),
        ],
      ),
    );
  }
}

/// List of moves with current position highlighting
class _MoveList extends StatelessWidget {
  final List<Move> moveHistory;
  final int currentMoveIndex;
  final Function(int) onSelectMove;
  final BoardTheme theme;

  const _MoveList({
    required this.moveHistory,
    required this.currentMoveIndex,
    required this.onSelectMove,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black26,
      child: moveHistory.isEmpty
          ? Center(
              child: Text(
                '指し手がありません',
                style: TextStyle(color: Colors.white54),
              ),
            )
          : ListView.builder(
              itemCount: moveHistory.length,
              itemBuilder: (context, index) {
                final move = moveHistory[index];
                final isPlayerA = index.isEven;
                final isSelected = index == currentMoveIndex;

                return Container(
                  color: isSelected ? theme.accentGold.withValues(alpha: 0.1) : Colors.transparent,
                  child: ListTile(
                    dense: true,
                    onTap: () => onSelectMove(index),
                    leading: Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: isPlayerA ? theme.frontPieceColor : theme.backPieceColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                    title: Text(
                      '${index + 1}手目: ${move.from} → ${move.to}',
                      style: TextStyle(
                        color: isSelected ? theme.accentGold : Colors.white,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }
}
