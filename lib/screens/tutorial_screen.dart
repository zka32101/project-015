import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../engine/board.dart';
import '../engine/board_theme.dart';
import '../engine/models.dart';
import 'game_screen.dart';

const tutorialSeenPrefsKey = 'tutorial_seen';

/// Scripted single-move tutorial: a fixed board where the only guided action
/// is to move a piece onto an adjacent enemy piece, guaranteeing the very
/// first tap delivers the "寝返り" (flip-conversion) Aha Moment before the
/// player ever sees the real 9-vs-9 board (design doc Section3 Must#4 /
/// Section16 "最優先" item).
class TutorialScreen extends ConsumerStatefulWidget {
  const TutorialScreen({super.key});

  @override
  ConsumerState<TutorialScreen> createState() => _TutorialScreenState();
}

enum _TutorialStep { intro, waitingForMove, ahaMoment }

const _tutorialPlayer = Square(3, 2);
const _tutorialEnemy = Square(3, 3);

class _TutorialScreenState extends ConsumerState<TutorialScreen> {
  late Board _board;
  _TutorialStep _step = _TutorialStep.intro;

  @override
  void initState() {
    super.initState();
    _board = _buildTutorialBoard();
  }

  Board _buildTutorialBoard() {
    final board = Board.empty();
    board.set(_tutorialPlayer,
        const Piece(type: PieceType.normal, owner: Owner.playerA, face: Face.front));
    board.set(_tutorialEnemy,
        const Piece(type: PieceType.normal, owner: Owner.playerB, face: Face.front));
    return board;
  }

  void _onTapSquare(Square square) {
    if (_step != _TutorialStep.waitingForMove) return;
    if (square != _tutorialEnemy) return;

    HapticFeedback.mediumImpact();
    setState(() {
      final captured = _board.at(_tutorialEnemy)!;
      _board.set(_tutorialPlayer, null);
      _board.set(_tutorialEnemy,
          captured.copyWith(owner: Owner.playerA, face: captured.face.flipped));
      _step = _TutorialStep.ahaMoment;
    });
  }

  Future<void> _goToRealGame() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(tutorialSeenPrefsKey, true);
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const GameScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = ref.watch(boardThemeProvider);

    return Scaffold(
      backgroundColor: theme.screenBackground,
      body: DecoratedBox(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/images/splash_background.png'),
            fit: BoxFit.cover,
            opacity: 0.35,
          ),
        ),
        child: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(20),
              child: Text(
                switch (_step) {
                  _TutorialStep.intro => '駒を動かすと、相手の駒に触れた瞬間\n相手の駒があなたの色に「寝返り」ます。',
                  _TutorialStep.waitingForMove => '朱色の駒をタップして寝返らせよう！',
                  _TutorialStep.ahaMoment => 'これが「寝返り」！\n奪うのではなく、味方に変える。',
                },
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white, fontSize: 18, height: 1.5),
              ),
            ),
            Expanded(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: AspectRatio(
                    aspectRatio: 1,
                    child: _TutorialBoard(
                      board: _board,
                      theme: theme,
                      highlightSquare:
                          _step == _TutorialStep.waitingForMove ? _tutorialEnemy : null,
                      onTapSquare: _onTapSquare,
                    ),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: switch (_step) {
                _TutorialStep.intro => ElevatedButton(
                    onPressed: () => setState(() => _step = _TutorialStep.waitingForMove),
                    child: const Text('やってみる'),
                  ),
                _TutorialStep.waitingForMove => TextButton(
                    onPressed: _goToRealGame,
                    child: const Text('スキップ', style: TextStyle(color: Colors.white70)),
                  ),
                _TutorialStep.ahaMoment => ElevatedButton(
                    key: const Key('start_game_button'),
                    onPressed: _goToRealGame,
                    child: const Text('対局をはじめる'),
                  ),
              },
            ),
          ],
        ),
        ),
      ),
    );
  }
}

class _TutorialBoard extends StatelessWidget {
  final Board board;
  final BoardTheme theme;
  final Square? highlightSquare;
  final void Function(Square) onTapSquare;

  const _TutorialBoard({
    required this.board,
    required this.theme,
    required this.highlightSquare,
    required this.onTapSquare,
  });

  @override
  Widget build(BuildContext context) {
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
          final square = Square(index ~/ 6, index % 6);
          final piece = board.at(square);
          final isHighlighted = highlightSquare == square;
          final isDark = (square.row + square.col) % 2 == 0;

          return GestureDetector(
            key: Key('tutorial_cell_${square.row}_${square.col}'),
            onTap: () => onTapSquare(square),
            child: Container(
              margin: const EdgeInsets.all(1.5),
              decoration: BoxDecoration(
                color: isDark ? Colors.black.withValues(alpha: 0.22) : Colors.white.withValues(alpha: 0.05),
                border: isHighlighted
                    ? Border.all(color: theme.accentGold, width: 2.5)
                    : null,
                borderRadius: BorderRadius.circular(3),
              ),
              child: piece == null
                  ? null
                  : Center(
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        width: 34,
                        height: 34,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                                color: Colors.black45,
                                blurRadius: 3,
                                offset: Offset(1, 1)),
                          ],
                        ),
                        child: ClipOval(
                          child: ColorFiltered(
                            colorFilter: ColorFilter.mode(
                              piece.type == PieceType.king
                                  ? theme.accentGold
                                  : (piece.face == Face.front
                                      ? theme.frontPieceColor
                                      : theme.backPieceColor),
                              BlendMode.color,
                            ),
                            child: Image.asset(
                              pieceAssetFor(piece.type, piece.face),
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                      ),
                    ),
            ),
          );
        },
      ),
    );
  }
}
