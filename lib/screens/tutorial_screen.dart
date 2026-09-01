import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../engine/board.dart';
import '../engine/board_theme.dart';
import '../engine/models.dart';
import 'game_screen.dart';

const tutorialSeenPrefsKey = 'tutorial_seen';

/// Enhanced multi-step interactive tutorial: guides players through game rules
/// with progressive complexity. Steps: intro → board_setup → move_rules →
/// capture_mechanics → reversal_preview → end_conditions → start_game.
class TutorialScreen extends ConsumerStatefulWidget {
  const TutorialScreen({super.key});

  @override
  ConsumerState<TutorialScreen> createState() => _TutorialScreenState();
}

enum _TutorialStep {
  intro,
  boardSetup,
  moveRules,
  captureMechanics,
  reversalPreview,
  endConditions,
  readyToStart,
}

// Key board positions for tutorial demonstrations
const _playerPiece1 = Square(2, 2);
const _playerPiece2 = Square(2, 3);
const _enemyPiece1 = Square(3, 2);
const _enemyPiece2 = Square(3, 3);
const _moveTarget = Square(2, 1);
const _captureTarget = Square(3, 1);

class _TutorialScreenState extends ConsumerState<TutorialScreen> {
  late Board _board;
  _TutorialStep _currentStep = _TutorialStep.intro;
  Square? _previewTarget;
  bool _showPreview = false;

  static const List<_TutorialStep> allSteps = [
    _TutorialStep.intro,
    _TutorialStep.boardSetup,
    _TutorialStep.moveRules,
    _TutorialStep.captureMechanics,
    _TutorialStep.reversalPreview,
    _TutorialStep.endConditions,
    _TutorialStep.readyToStart,
  ];

  @override
  void initState() {
    super.initState();
    _resetBoardForStep(_currentStep);
  }

  void _resetBoardForStep(_TutorialStep step) {
    _board = Board.empty();
    _showPreview = false;
    _previewTarget = null;

    switch (step) {
      case _TutorialStep.intro:
        // Empty board for introduction
        break;
      case _TutorialStep.boardSetup:
        // Show initial board layout
        _board.set(_playerPiece1,
            const Piece(type: PieceType.normal, owner: Owner.playerA, face: Face.front));
        _board.set(_playerPiece2,
            const Piece(type: PieceType.normal, owner: Owner.playerA, face: Face.front));
        _board.set(_enemyPiece1,
            const Piece(type: PieceType.normal, owner: Owner.playerB, face: Face.front));
        _board.set(_enemyPiece2,
            const Piece(type: PieceType.normal, owner: Owner.playerB, face: Face.front));
        break;
      case _TutorialStep.moveRules:
        // Show board with emphasis on valid moves
        _board.set(_playerPiece1,
            const Piece(type: PieceType.normal, owner: Owner.playerA, face: Face.front));
        _board.set(_enemyPiece1,
            const Piece(type: PieceType.normal, owner: Owner.playerB, face: Face.front));
        _board.set(_enemyPiece2,
            const Piece(type: PieceType.normal, owner: Owner.playerB, face: Face.front));
        break;
      case _TutorialStep.captureMechanics:
        // Setup for capture demonstration
        _board.set(_playerPiece1,
            const Piece(type: PieceType.normal, owner: Owner.playerA, face: Face.front));
        _board.set(_enemyPiece1,
            const Piece(type: PieceType.normal, owner: Owner.playerB, face: Face.front));
        _board.set(_enemyPiece2,
            const Piece(type: PieceType.normal, owner: Owner.playerB, face: Face.front));
        break;
      case _TutorialStep.reversalPreview:
        // Setup for preview demonstration
        _board.set(_playerPiece1,
            const Piece(type: PieceType.normal, owner: Owner.playerA, face: Face.front));
        _board.set(_enemyPiece1,
            const Piece(type: PieceType.normal, owner: Owner.playerB, face: Face.front));
        _board.set(_enemyPiece2,
            const Piece(type: PieceType.normal, owner: Owner.playerB, face: Face.front));
        break;
      case _TutorialStep.endConditions:
        // Example of game ending
        _board.set(_playerPiece1,
            const Piece(type: PieceType.normal, owner: Owner.playerA, face: Face.front));
        break;
      case _TutorialStep.readyToStart:
        // Empty board for final message
        break;
    }
  }

  void _nextStep() {
    HapticFeedback.lightImpact();
    final currentIndex = allSteps.indexOf(_currentStep);
    if (currentIndex < allSteps.length - 1) {
      setState(() {
        _currentStep = allSteps[currentIndex + 1];
        _resetBoardForStep(_currentStep);
      });
    }
  }

  void _previousStep() {
    HapticFeedback.lightImpact();
    final currentIndex = allSteps.indexOf(_currentStep);
    if (currentIndex > 0) {
      setState(() {
        _currentStep = allSteps[currentIndex - 1];
        _resetBoardForStep(_currentStep);
      });
    }
  }

  void _onTapSquare(Square square) {
    HapticFeedback.mediumImpact();

    if (_currentStep == _TutorialStep.captureMechanics && square == _captureTarget) {
      // Perform the capture
      setState(() {
        _board.set(_playerPiece1, null);
        final captured = _board.at(_enemyPiece1)!;
        _board.set(_enemyPiece1,
            captured.copyWith(owner: Owner.playerA, face: captured.face.flipped));
        _showPreview = false;
      });
    } else if (_currentStep == _TutorialStep.reversalPreview) {
      // Show preview effect
      if (square == _captureTarget) {
        setState(() {
          _previewTarget = square;
          _showPreview = true;
        });

        Future.delayed(const Duration(milliseconds: 1500), () {
          if (!mounted) return;
          setState(() {
            _board.set(_playerPiece1, null);
            final captured = _board.at(_enemyPiece1)!;
            _board.set(_enemyPiece1,
                captured.copyWith(owner: Owner.playerA, face: captured.face.flipped));
            _showPreview = false;
            _previewTarget = null;
          });
        });
      }
    }
  }

  Future<void> _goToRealGame() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(tutorialSeenPrefsKey, true);
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const GameScreen()),
    );
  }

  String _getTitle() {
    return switch (_currentStep) {
      _TutorialStep.intro => 'リバーシアへようこそ！',
      _TutorialStep.boardSetup => 'ゲームボード',
      _TutorialStep.moveRules => '駒の移動',
      _TutorialStep.captureMechanics => '敵の駒を「寝返り」させる',
      _TutorialStep.reversalPreview => 'プレビュー機能',
      _TutorialStep.endConditions => 'ゲーム終了',
      _TutorialStep.readyToStart => 'さあ、対局をはじめましょう！',
    };
  }

  String _getDescription() {
    return switch (_currentStep) {
      _TutorialStep.intro =>
        'このゲームでは、あなたの駒を敵の駒に接近させると、\n敵の駒があなたの色に「寝返り」します。\n奪うのではなく、味方に変える戦略です。',
      _TutorialStep.boardSetup =>
        'ボードは6×6のマス目です。\n青い駒があなたの駒、赤い駒が敵の駒です。\n多くの駒を味方にすることが目標です。',
      _TutorialStep.moveRules =>
        '空いているマスに駒を移動できます。\n敵の駒の近くに移動すると、その駒が寝返ります。\n隣接する全ての敵の駒が影響を受けます。',
      _TutorialStep.captureMechanics =>
        '赤い駒をタップして、あなたの駒に変えてみましょう。\n複数の敵の駒が一度に寝返ることもあります。',
      _TutorialStep.reversalPreview =>
        'タップする前に、どの駒が寝返るかプレビューできます。\n敵の次の手も予測できる「透け読みモード」もあります。',
      _TutorialStep.endConditions =>
        'どちらの駒も動けなくなったらゲーム終了です。\n最後にあなたの駒が多い方が勝ちです。\n色々な戦略を試して、勝利を目指しましょう！',
      _TutorialStep.readyToStart =>
        'ゲームの基本は理解できましたね。\n対局をはじめて、実際にプレイしてみましょう。\nくり返しプレイして、戦略を磨いてください。',
    };
  }

  @override
  Widget build(BuildContext context) {
    final theme = ref.watch(boardThemeProvider);
    final currentIndex = allSteps.indexOf(_currentStep);
    final stepCount = allSteps.length;

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
              // Progress indicator
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'ステップ ${currentIndex + 1}/$stepCount',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                    ),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: (currentIndex + 1) / stepCount,
                        minHeight: 4,
                        backgroundColor: Colors.white12,
                        valueColor:
                            AlwaysStoppedAnimation(theme.accentGold),
                      ),
                    ),
                  ],
                ),
              ),
              // Title
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  _getTitle(),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              // Description
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Text(
                  _getDescription(),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    height: 1.6,
                  ),
                ),
              ),
              // Board (shown for certain steps)
              if (_currentStep != _TutorialStep.intro &&
                  _currentStep != _TutorialStep.readyToStart)
                Expanded(
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: AspectRatio(
                        aspectRatio: 1,
                        child: _TutorialBoard(
                          board: _board,
                          theme: theme,
                          onTapSquare: _onTapSquare,
                          highlightSquare: _currentStep ==
                                  _TutorialStep.captureMechanics
                              ? _captureTarget
                              : _currentStep == _TutorialStep.reversalPreview
                                  ? _captureTarget
                                  : null,
                          previewSquare: _showPreview ? _previewTarget : null,
                        ),
                      ),
                    ),
                  ),
                )
              else
                Expanded(
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            _currentStep == _TutorialStep.intro
                                ? Icons.school_outlined
                                : Icons.check_circle_outline,
                            size: 80,
                            color: theme.accentGold,
                          ),
                          const SizedBox(height: 24),
                          if (_currentStep == _TutorialStep.intro)
                            Text(
                              '6×6のボードで敵の駒を\n味方に「寝返り」させるゲームです。',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 15,
                                height: 1.6,
                              ),
                            )
                          else
                            Text(
                              'すべてのルールを\nマスターしました！',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: theme.accentGold,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                height: 1.6,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              // Navigation buttons
              Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Previous button
                    if (currentIndex > 0)
                      TextButton(
                        onPressed: _previousStep,
                        child: const Text(
                          '前へ',
                          style: TextStyle(color: Colors.white70),
                        ),
                      )
                    else
                      const SizedBox(width: 60),
                    // Skip button
                    if (currentIndex < stepCount - 1)
                      TextButton(
                        onPressed: _goToRealGame,
                        child: const Text(
                          'スキップ',
                          style: TextStyle(color: Colors.white54),
                        ),
                      )
                    else
                      const SizedBox(width: 60),
                    // Next/Start button
                    if (currentIndex < stepCount - 1)
                      ElevatedButton(
                        onPressed: _nextStep,
                        child: const Text('次へ'),
                      )
                    else
                      ElevatedButton(
                        key: const Key('start_game_button'),
                        onPressed: _goToRealGame,
                        child: const Text('対局をはじめる'),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TutorialBoard extends StatefulWidget {
  final Board board;
  final BoardTheme theme;
  final Square? highlightSquare;
  final Square? previewSquare;
  final void Function(Square) onTapSquare;

  const _TutorialBoard({
    required this.board,
    required this.theme,
    required this.highlightSquare,
    required this.previewSquare,
    required this.onTapSquare,
  });

  @override
  State<_TutorialBoard> createState() => _TutorialBoardState();
}

class _TutorialBoardState extends State<_TutorialBoard>
    with SingleTickerProviderStateMixin {
  late AnimationController _previewAnimationController;
  late Animation<double> _previewOpacity;

  @override
  void initState() {
    super.initState();
    _previewAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _previewOpacity = Tween<double>(begin: 0.3, end: 0.8).animate(
      CurvedAnimation(parent: _previewAnimationController, curve: Curves.easeInOut),
    );

    if (widget.previewSquare != null) {
      _previewAnimationController.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(_TutorialBoard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.previewSquare != null && oldWidget.previewSquare == null) {
      _previewAnimationController.repeat(reverse: true);
    } else if (widget.previewSquare == null && oldWidget.previewSquare != null) {
      _previewAnimationController.stop();
    }
  }

  @override
  void dispose() {
    _previewAnimationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        image: DecorationImage(
          image: AssetImage(widget.theme.woodTextureAsset),
          fit: BoxFit.cover,
        ),
        border: Border.all(color: widget.theme.accentGold, width: 3),
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
          final piece = widget.board.at(square);
          final isHighlighted = widget.highlightSquare == square;
          final isPreview = widget.previewSquare == square;
          final isDark = (square.row + square.col) % 2 == 0;

          return GestureDetector(
            key: Key('tutorial_cell_${square.row}_${square.col}'),
            onTap: () => widget.onTapSquare(square),
            child: Container(
              margin: const EdgeInsets.all(1.5),
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.black.withValues(alpha: 0.22)
                    : Colors.white.withValues(alpha: 0.05),
                border: isHighlighted
                    ? Border.all(
                        color: widget.theme.accentGold.withValues(alpha: 0.8),
                        width: 3,
                      )
                    : isPreview
                        ? Border.all(
                            color: Colors.amber.withValues(alpha: 0.6),
                            width: 2,
                          )
                        : null,
                borderRadius: BorderRadius.circular(3),
                boxShadow: isHighlighted
                    ? [
                        BoxShadow(
                          color:
                              widget.theme.accentGold.withValues(alpha: 0.4),
                          blurRadius: 8,
                          spreadRadius: 1,
                        ),
                      ]
                    : null,
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Preview effect background
                  if (isPreview)
                    AnimatedBuilder(
                      animation: _previewOpacity,
                      builder: (context, child) {
                        return Container(
                          decoration: BoxDecoration(
                            color: Colors.amber.withValues(
                              alpha: _previewOpacity.value * 0.2,
                            ),
                            borderRadius: BorderRadius.circular(3),
                          ),
                        );
                      },
                    ),
                  // Piece
                  if (piece != null)
                    Center(
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
                              offset: Offset(1, 1),
                            ),
                          ],
                        ),
                        child: ClipOval(
                          child: ColorFiltered(
                            colorFilter: ColorFilter.mode(
                              piece.type == PieceType.king
                                  ? widget.theme.accentGold
                                  : (piece.face == Face.front
                                      ? widget.theme.frontPieceColor
                                      : widget.theme.backPieceColor),
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
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
