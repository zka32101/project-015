import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../engine/board.dart';
import '../engine/board_theme.dart';
import '../engine/game_state.dart';
import '../engine/models.dart';
import '../engine/move_generator.dart';
import '../engine/puzzle.dart';

const puzzleClearedDatePrefsKey = 'daily_puzzle_cleared_date';
const puzzleStreakPrefsKey = 'daily_puzzle_streak';

/// Section3 Must#6 "日次パズル（今日の1局・棋譜提示型）" -- a Wordle-style single
/// puzzle shared by every player on a given calendar date (design doc
/// Section14 v1.2, called out as the highest-priority LiveOps idea).
class PuzzleScreen extends ConsumerStatefulWidget {
  const PuzzleScreen({super.key});

  @override
  ConsumerState<PuzzleScreen> createState() => _PuzzleScreenState();
}

enum _PuzzleStatus { playing, wrongMove, solved, alreadyClearedToday }

class _PuzzleScreenState extends ConsumerState<PuzzleScreen> {
  late final Puzzle _puzzle;
  late final GameState _state;
  Square? _selected;
  List<Square> _legalDestinations = const [];
  _PuzzleStatus _status = _PuzzleStatus.playing;
  int _streak = 0;

  @override
  void initState() {
    super.initState();
    _puzzle = puzzleForDate(DateTime.now());
    _state = _buildFreshState();
    _loadClearedStatus();
  }

  GameState _buildFreshState() {
    final state = GameState.initial();
    state.board = _puzzle.buildBoard();
    state.turn = _puzzle.solverOwner;
    return state;
  }

  Future<void> _loadClearedStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final clearedDate = prefs.getString(puzzleClearedDatePrefsKey);
    final streak = prefs.getInt(puzzleStreakPrefsKey) ?? 0;
    final today = formatDateKey(DateTime.now());
    if (!mounted) return;
    setState(() {
      _streak = streak;
      if (clearedDate == today) _status = _PuzzleStatus.alreadyClearedToday;
    });
  }

  Future<void> _recordClear() async {
    final prefs = await SharedPreferences.getInstance();
    final today = DateTime.now();
    final todayKey = formatDateKey(today);
    final clearedDate = prefs.getString(puzzleClearedDatePrefsKey);
    final yesterdayKey = formatDateKey(today.subtract(const Duration(days: 1)));

    final newStreak = (clearedDate == yesterdayKey) ? _streak + 1 : 1;
    await prefs.setString(puzzleClearedDatePrefsKey, todayKey);
    await prefs.setInt(puzzleStreakPrefsKey, newStreak);
    if (!mounted) return;
    setState(() => _streak = newStreak);
  }

  void _onTapSquare(Square square) {
    if (_status != _PuzzleStatus.playing && _status != _PuzzleStatus.wrongMove) return;

    if (_selected != null && _legalDestinations.contains(square)) {
      _state.applyMove(Move(_selected!, square));
      final won = _state.result ==
          (_puzzle.solverOwner == Owner.playerA
              ? GameResult.playerAWins
              : GameResult.playerBWins);
      if (won) {
        HapticFeedback.heavyImpact();
        setState(() {
          _status = _PuzzleStatus.solved;
          _selected = null;
          _legalDestinations = const [];
        });
        _recordClear();
      } else {
        HapticFeedback.selectionClick();
        setState(() {
          _status = _PuzzleStatus.wrongMove;
          _selected = null;
          _legalDestinations = const [];
        });
      }
      return;
    }

    final piece = _state.board.at(square);
    if (piece != null && piece.owner == _puzzle.solverOwner) {
      setState(() {
        _selected = square;
        _legalDestinations = MoveGenerator.destinationsFor(_state.board, square);
        if (_status == _PuzzleStatus.wrongMove) _status = _PuzzleStatus.playing;
      });
      return;
    }

    setState(() {
      _selected = null;
      _legalDestinations = const [];
    });
  }

  void _retry() {
    setState(() {
      _state.board = _puzzle.buildBoard();
      _state.turn = _puzzle.solverOwner;
      _state.result = GameResult.ongoing;
      _selected = null;
      _legalDestinations = const [];
      _status = _PuzzleStatus.playing;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = ref.watch(boardThemeProvider);

    return Scaffold(
      backgroundColor: theme.screenBackground,
      appBar: AppBar(
        title: Text('今日の1局（${_puzzle.difficultyLabel}）'),
        backgroundColor: theme.woodDark,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.local_fire_department, color: theme.accentGold, size: 20),
                  const SizedBox(width: 4),
                  Text('連続 $_streak 日', style: const TextStyle(color: Colors.white)),
                ],
              ),
            ),
            Text(
              switch (_status) {
                _PuzzleStatus.playing => '1手で相手の王を取れ！',
                _PuzzleStatus.wrongMove => 'ちがう手です。もう一度！',
                _PuzzleStatus.solved => '正解！お見事！',
                _PuzzleStatus.alreadyClearedToday => '今日の1局はクリア済みです',
              },
              style: TextStyle(
                color: _status == _PuzzleStatus.wrongMove ? theme.backPieceColor : Colors.white,
                fontSize: 16,
              ),
            ),
            Expanded(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: AspectRatio(
                    aspectRatio: 1,
                    child: _PuzzleBoard(
                      board: _state.board,
                      theme: theme,
                      selected: _selected,
                      legalDestinations: _legalDestinations,
                      onTapSquare: _onTapSquare,
                    ),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: switch (_status) {
                _PuzzleStatus.solved => const SizedBox.shrink(),
                _PuzzleStatus.alreadyClearedToday => ElevatedButton(
                    key: const Key('puzzle_retry_button'),
                    onPressed: _retry,
                    child: const Text('もう一度あそぶ'),
                  ),
                _ => TextButton(
                    key: const Key('puzzle_reset_button'),
                    onPressed: _retry,
                    child: const Text('はじめから', style: TextStyle(color: Colors.white70)),
                  ),
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _PuzzleBoard extends StatelessWidget {
  final Board board;
  final BoardTheme theme;
  final Square? selected;
  final List<Square> legalDestinations;
  final void Function(Square) onTapSquare;

  const _PuzzleBoard({
    required this.board,
    required this.theme,
    required this.selected,
    required this.legalDestinations,
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
          final isDark = (square.row + square.col) % 2 == 0;

          return GestureDetector(
            key: Key('puzzle_cell_${square.row}_${square.col}'),
            onTap: () => onTapSquare(square),
            child: Container(
              margin: const EdgeInsets.all(1.5),
              constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
              decoration: BoxDecoration(
                color: isDark ? Colors.black.withValues(alpha: 0.22) : Colors.white.withValues(alpha: 0.05),
                border: selected == square
                    ? Border.all(color: theme.accentGold, width: 2.5)
                    : null,
                borderRadius: BorderRadius.circular(3),
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  if (legalDestinations.contains(square))
                    Container(
                      margin: const EdgeInsets.all(6),
                      decoration: const BoxDecoration(
                        color: Color(0x664CAF50),
                        shape: BoxShape.circle,
                      ),
                    ),
                  if (piece != null)
                    Container(
                      width: 34,
                      height: 34,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(color: Colors.black45, blurRadius: 3, offset: Offset(1, 1)),
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
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
