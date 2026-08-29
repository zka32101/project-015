import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../engine/ai.dart';
import '../engine/board_theme.dart';
import '../engine/game_state.dart';
import '../engine/models.dart';
import '../engine/rank.dart';
import '../engine/replay.dart';
import '../viewmodels/game_view_model.dart';
import 'kifu_viewer_screen.dart';
import 'puzzle_screen.dart';
import 'rank_detail_screen.dart';
import 'statistics_screen.dart';
import 'tutorial_screen.dart';

const _highlightColor = Color(0x664CAF50);

class GameScreen extends ConsumerWidget {
  const GameScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final viewState = ref.watch(gameViewModelProvider);
    final viewModel = ref.read(gameViewModelProvider.notifier);
    final theme = ref.watch(boardThemeProvider);
    final game = viewState.game;

    return Scaffold(
      backgroundColor: theme.screenBackground,
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('リバーシア'),
            const SizedBox(width: 10),
            GestureDetector(
              key: const Key('rank_badge'),
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const RankDetailScreen()),
                );
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: theme.accentGold.withValues(alpha: 0.2),
                  border: Border.all(color: theme.accentGold),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  rankLabelForWins(viewState.rankPoints),
                  style: TextStyle(color: theme.accentGold, fontSize: 13),
                ),
              ),
            ),
          ],
        ),
        backgroundColor: theme.woodDark,
        actions: [
          IconButton(
            key: const Key('daily_puzzle_button'),
            icon: const Icon(Icons.calendar_today),
            tooltip: '今日の1局',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const PuzzleScreen()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.help_outline),
            tooltip: '遊び方',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const TutorialScreen()),
              );
            },
          ),
          IconButton(
            key: const Key('threat_preview_toggle'),
            icon: Icon(
              viewState.showThreatPreview
                  ? Icons.visibility
                  : Icons.visibility_off_outlined,
            ),
            tooltip: '透け読みモード（相手の次手プレビュー）',
            onPressed: () =>
                viewModel.setShowThreatPreview(!viewState.showThreatPreview),
          ),
          PopupMenuButton<AiDifficulty?>(
            key: const Key('ai_menu'),
            icon: const Icon(Icons.smart_toy_outlined),
            tooltip: '対戦相手',
            initialValue: viewState.aiDifficulty,
            onSelected: (value) {
              viewModel.setAiDifficulty(value);
              viewModel.restart();
            },
            itemBuilder: (context) => const [
              PopupMenuItem(value: null, child: Text('2人対戦（ローカル）')),
              PopupMenuItem(value: AiDifficulty.easy, child: Text('AI: かんたん')),
              PopupMenuItem(value: AiDifficulty.medium, child: Text('AI: ふつう')),
              PopupMenuItem(value: AiDifficulty.hard, child: Text('AI: つよい')),
            ],
          ),
          PopupMenuButton<BoardTheme>(
            key: const Key('theme_menu'),
            icon: const Icon(Icons.palette_outlined),
            tooltip: '盤テーマ',
            initialValue: theme,
            onSelected: (selected) =>
                ref.read(boardThemeProvider.notifier).setTheme(selected),
            itemBuilder: (context) => [
              for (final t in boardThemes) PopupMenuItem(value: t, child: Text(t.label)),
            ],
          ),
          IconButton(
            key: const Key('statistics_button'),
            icon: const Icon(Icons.bar_chart),
            tooltip: '成績',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const StatisticsScreen()),
              );
            },
          ),
          IconButton(
            key: const Key('kifu_button'),
            icon: const Icon(Icons.history),
            tooltip: '棋譜',
            onPressed: () {
              if (game.isOver && game.moveHistory.isNotEmpty) {
                // For completed games, show the full replay viewer
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => KifuViewerScreen(
                      completedGame: game,
                      theme: theme,
                    ),
                  ),
                );
              } else {
                // For in-progress games, show the simple sheet
                _showKifuSheet(context, game, theme);
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: viewModel.restart,
            tooltip: 'はじめから',
          ),
        ],
      ),
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                _TurnBanner(game: game, theme: theme),
                Expanded(
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: AspectRatio(
                        aspectRatio: 1,
                        child: _Board(
                          viewState: viewState,
                          theme: theme,
                          onTapSquare: viewModel.selectSquare,
                        ),
                      ),
                    ),
                  ),
                ),
                if (game.isOver)
                  _ResultBanner(game: game, theme: theme, onRestart: viewModel.restart),
              ],
            ),
            _VictoryFlash(result: game.result, theme: theme),
          ],
        ),
      ),
    );
  }
}

/// Section3 Must#5 "対局リプレイ（棋譜保存・見返し）" -- a simple scrollable move
/// list, opened on demand rather than a full replay-scrubber (no separate
/// replay engine yet; GameState.moveHistory already has everything needed).
void _showKifuSheet(BuildContext context, GameState game, BoardTheme theme) {
  showModalBottomSheet(
    context: context,
    backgroundColor: theme.woodDark,
    builder: (context) => _KifuSheet(moveHistory: game.moveHistory, theme: theme),
  );
}

class _KifuSheet extends StatelessWidget {
  final List<Move> moveHistory;
  final BoardTheme theme;
  const _KifuSheet({required this.moveHistory, required this.theme});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('棋譜',
                style: TextStyle(
                    color: theme.accentGold, fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            if (moveHistory.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Text('まだ指し手がありません',
                    style: TextStyle(color: Colors.white70), textAlign: TextAlign.center),
              )
            else
              Flexible(
                child: ListView.builder(
                  key: const Key('kifu_list'),
                  shrinkWrap: true,
                  itemCount: moveHistory.length,
                  itemBuilder: (context, index) {
                    final move = moveHistory[index];
                    final isPlayerA = index.isEven; // moves alternate starting with A
                    return ListTile(
                      dense: true,
                      leading: Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: isPlayerA ? theme.frontPieceColor : theme.backPieceColor,
                          shape: BoxShape.circle,
                        ),
                      ),
                      title: Text(
                        '${index + 1}手目  ${move.from} → ${move.to}',
                        style: const TextStyle(color: Colors.white),
                      ),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Full-screen flash + victory SE when the king is captured (Section10:
/// "王取り演出: 全画面フラッシュ+勝利SE"). Purely decorative and non-interactive.
class _VictoryFlash extends StatefulWidget {
  final GameResult result;
  final BoardTheme theme;
  const _VictoryFlash({required this.result, required this.theme});

  @override
  State<_VictoryFlash> createState() => _VictoryFlashState();
}

class _VictoryFlashState extends State<_VictoryFlash> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 550),
    );
  }

  @override
  void didUpdateWidget(covariant _VictoryFlash oldWidget) {
    super.didUpdateWidget(oldWidget);
    final justEnded =
        oldWidget.result == GameResult.ongoing && widget.result != GameResult.ongoing;
    if (justEnded) {
      _controller.forward(from: 0);
      SystemSound.play(SystemSoundType.click);
      HapticFeedback.heavyImpact();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: IgnorePointer(
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, _) {
            final t = _controller.value;
            // Quick, punchy flash-in, then a fade-out that clears sooner.
            final opacity = t < 0.1 ? (t / 0.1) : (1 - (t - 0.1) / 0.9);
            return Opacity(
              opacity: opacity.clamp(0, 1).toDouble() * 0.7,
              child: ColoredBox(color: widget.theme.accentGold),
            );
          },
        ),
      ),
    );
  }
}

class _TurnBanner extends StatelessWidget {
  final GameState game;
  final BoardTheme theme;
  const _TurnBanner({required this.game, required this.theme});

  @override
  Widget build(BuildContext context) {
    if (game.isOver) return const SizedBox(height: 12);
    final isA = game.turn == Owner.playerA;
    final countA = game.board.pieceCount(Owner.playerA);
    final countB = game.board.pieceCount(Owner.playerB);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 16,
                height: 16,
                decoration: BoxDecoration(
                  color: isA ? theme.frontPieceColor : theme.backPieceColor,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                isA ? '藍陣営の番' : '朱陣営の番',
                style: const TextStyle(color: Colors.white, fontSize: 16),
              ),
              const SizedBox(width: 10),
              Text(
                '（${game.plyCount}/$plyLimit手）',
                style: const TextStyle(color: Colors.white54, fontSize: 13),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _PieceCountBadge(
                label: '藍',
                count: countA,
                color: theme.frontPieceColor,
              ),
              const SizedBox(width: 16),
              Text(
                'vs',
                style: TextStyle(color: theme.accentGold, fontSize: 12),
              ),
              const SizedBox(width: 16),
              _PieceCountBadge(
                label: '朱',
                count: countB,
                color: theme.backPieceColor,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PieceCountBadge extends StatelessWidget {
  final String label;
  final int count;
  final Color color;

  const _PieceCountBadge({
    required this.label,
    required this.count,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        border: Border.all(color: color, width: 1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        children: [
          Text(
            label,
            style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.bold),
          ),
          const SizedBox(width: 6),
          Text(
            '$count',
            style: TextStyle(color: color, fontSize: 14, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}

class _ResultBanner extends StatelessWidget {
  final GameState game;
  final BoardTheme theme;
  final VoidCallback onRestart;
  const _ResultBanner({required this.game, required this.theme, required this.onRestart});

  @override
  Widget build(BuildContext context) {
    final text = switch (game.result) {
      GameResult.playerAWins => '藍陣営の勝利！',
      GameResult.playerBWins => '朱陣営の勝利！',
      GameResult.draw => '引き分け',
      _ => '',
    };
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Stack(
        alignment: Alignment.center,
        children: [
          const Positioned.fill(
            child: IgnorePointer(
              child: Opacity(
                opacity: 0.5,
                child: Image(
                  image: AssetImage('assets/images/victory_decoration.png'),
                  fit: BoxFit.contain,
                ),
              ),
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(text,
                  style: TextStyle(
                      color: theme.accentGold, fontSize: 22, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              ElevatedButton(onPressed: onRestart, child: const Text('もう一局')),
            ],
          ),
        ],
      ),
    );
  }
}

class _Board extends StatelessWidget {
  final GameViewState viewState;
  final BoardTheme theme;
  final void Function(Square) onTapSquare;

  const _Board({required this.viewState, required this.theme, required this.onTapSquare});

  @override
  Widget build(BuildContext context) {
    final kingThreatSquares = viewState.kingThreatSquares.toSet();
    final threatSquares =
        viewState.opponentThreatSquares.where((s) => !kingThreatSquares.contains(s)).toSet();

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
        gridDelegate:
            const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 6),
        itemCount: 36,
        itemBuilder: (context, index) {
          final row = index ~/ 6;
          final col = index % 6;
          final square = Square(row, col);
          return _BoardCell(
            key: Key('cell_${row}_$col'),
            square: square,
            piece: viewState.game.board.at(square),
            theme: theme,
            isSelected: viewState.selected == square,
            isLegalDestination: viewState.legalDestinations.contains(square),
            isThreatened: threatSquares.contains(square),
            isKingThreatened: kingThreatSquares.contains(square),
            isLastMove: viewState.lastMoveSquares.contains(square),
            isCurrentTurnPiece: viewState.game.board.at(square)?.owner ==
                viewState.game.turn,
            onTap: () {
              HapticFeedback.selectionClick();
              onTapSquare(square);
            },
          );
        },
      ),
    );
  }
}

/// Stronger, looping warning for a threatened square that holds the
/// side-to-move's own king (透け読みモード's "your king is in danger" case).
class _KingDangerPulse extends StatefulWidget {
  final BoardTheme theme;
  const _KingDangerPulse({super.key, required this.theme});

  @override
  State<_KingDangerPulse> createState() => _KingDangerPulseState();
}

class _KingDangerPulseState extends State<_KingDangerPulse>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final t = _controller.value; // 0 -> 1 -> 0, looping
        return Container(
          margin: const EdgeInsets.all(2),
          decoration: BoxDecoration(
            color: widget.theme.backPieceColor.withValues(alpha: 0.25 + t * 0.3),
            borderRadius: BorderRadius.circular(2),
          ),
        );
      },
    );
  }
}

class _BoardCell extends StatelessWidget {
  final Square square;
  final Piece? piece;
  final BoardTheme theme;
  final bool isSelected;
  final bool isLegalDestination;
  final bool isThreatened;
  final bool isKingThreatened;
  final bool isLastMove;
  final bool isCurrentTurnPiece;
  final VoidCallback onTap;

  const _BoardCell({
    super.key,
    required this.square,
    required this.piece,
    required this.theme,
    required this.isSelected,
    required this.isLegalDestination,
    required this.isThreatened,
    required this.isKingThreatened,
    required this.isLastMove,
    required this.isCurrentTurnPiece,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = (square.row + square.col) % 2 == 0;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.all(1.5),
        constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
        decoration: BoxDecoration(
          // The parent board already paints the wood texture; each cell just
          // tints over it (rather than a flat fill) so the grain shows through.
          color: isDark ? Colors.black.withValues(alpha: 0.22) : Colors.white.withValues(alpha: 0.05),
          border: isSelected
              ? Border.all(color: theme.accentGold, width: 2.5)
              : (isKingThreatened
                  ? Border.all(color: theme.backPieceColor, width: 2.5)
                  : (isThreatened
                      ? Border.all(color: theme.backPieceColor, width: 1.5)
                      : Border.all(color: Colors.transparent, width: 2.5))),
          borderRadius: BorderRadius.circular(3),
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            if (isLastMove)
              Container(
                key: const Key('last_move_highlight'),
                decoration: BoxDecoration(
                  color: theme.accentGold.withValues(alpha: 0.14),
                ),
              ),
            if (isKingThreatened)
              _KingDangerPulse(key: const Key('king_danger_pulse'), theme: theme)
            else if (isThreatened)
              Container(
                margin: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  color: theme.backPieceColor.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            if (isLegalDestination)
              Container(
                margin: const EdgeInsets.all(6),
                decoration: const BoxDecoration(
                  color: _highlightColor,
                  shape: BoxShape.circle,
                ),
              ),
            if (piece != null)
              _FlipPiece(
                key: ValueKey('piece_${square.row}_${square.col}'),
                piece: piece!,
                theme: theme,
                emphasize: isCurrentTurnPiece,
              ),
          ],
        ),
      ),
    );
  }
}

/// Card-flip Fx for the "寝返り" mechanic: whenever [piece] changes identity
/// (face toggled, or captured-and-converted to a new owner), this animates a
/// 180° Y-axis flip revealing the new state, plus a brief highlight pulse and
/// a click SE. Design doc Section10 calls this out as the mimetic core of the
/// app; no Lottie asset pipeline exists yet, so this is a self-contained
/// Flutter animation standing in for it.
class _FlipPiece extends StatefulWidget {
  final Piece piece;
  final BoardTheme theme;
  final bool emphasize;
  const _FlipPiece({
    super.key,
    required this.piece,
    required this.theme,
    required this.emphasize,
  });

  @override
  State<_FlipPiece> createState() => _FlipPieceState();
}

class _FlipPieceState extends State<_FlipPiece> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  Piece? _outgoingPiece;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 260),
    );
  }

  @override
  void didUpdateWidget(covariant _FlipPiece oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.piece, widget.piece)) {
      _outgoingPiece = oldWidget.piece;
      _controller.forward(from: 0);
      SystemSound.play(SystemSoundType.click);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final t = _controller.value;
        final angle = t * math.pi;
        final showingOutgoing = angle < math.pi / 2 && _outgoingPiece != null;
        final displayed = showingOutgoing ? _outgoingPiece! : widget.piece;
        final matrix = Matrix4.identity()
          ..setEntry(3, 2, 0.002)
          ..rotateY(showingOutgoing ? angle : angle - math.pi);
        final pulse = math.sin(t * math.pi); // 0 -> 1 -> 0 across the flip

        return Stack(
          alignment: Alignment.center,
          children: [
            if (pulse > 0)
              Opacity(
                opacity: pulse * 0.75,
                child: Container(
                  width: 34 + pulse * 22,
                  height: 34 + pulse * 22,
                  decoration: BoxDecoration(
                    color: widget.theme.accentGold,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            Transform(
              alignment: Alignment.center,
              transform: matrix,
              child: _PieceCircle(
                piece: displayed,
                theme: widget.theme,
                emphasize: widget.emphasize,
              ),
            ),
          ],
        );
      },
    );
  }
}

class _PieceCircle extends StatelessWidget {
  final Piece piece;
  final BoardTheme theme;
  final bool emphasize;
  const _PieceCircle({required this.piece, required this.theme, required this.emphasize});

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
        border: emphasize ? Border.all(color: Colors.white, width: 2) : null,
        boxShadow: const [
          BoxShadow(color: Colors.black45, blurRadius: 3, offset: Offset(1, 1)),
        ],
      ),
      child: ClipOval(
        child: ColorFiltered(
          colorFilter: ColorFilter.mode(color, BlendMode.color),
          child: Image.asset(
            pieceAssetFor(piece.type, piece.face),
            fit: BoxFit.cover,
          ),
        ),
      ),
    );
  }
}

