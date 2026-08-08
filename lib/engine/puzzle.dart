import 'board.dart';
import 'models.dart';

/// A single "今日の1局" puzzle (Section3 Must#6 / Section14 v1.2, highest
/// priority LiveOps idea): a fixed position with exactly one winning move
/// for [solverOwner] -- capture the enemy king in one ply.
class Puzzle {
  final String id;
  final String difficultyLabel;
  final Owner solverOwner;
  final Move solutionMove;
  final Board Function() buildBoard;

  const Puzzle({
    required this.id,
    required this.difficultyLabel,
    required this.solverOwner,
    required this.solutionMove,
    required this.buildBoard,
  });
}

Board _board(List<(Square, Piece)> pieces) {
  final board = Board.empty();
  for (final (square, piece) in pieces) {
    board.set(square, piece);
  }
  return board;
}

const _pA = Owner.playerA;
const _pB = Owner.playerB;

/// A fixed rotation of hand-authored puzzles. Each MUST have exactly one
/// legal move for solverOwner that captures the opponent's king -- verified
/// by test/puzzle_test.dart rather than by eyeballing (per house rule: data
/// correctness is checked by script, never by inspection alone).
final List<Puzzle> dailyPuzzles = [
  Puzzle(
    id: 'orthogonal-front',
    difficultyLabel: 'かんたん',
    solverOwner: _pA,
    solutionMove: const Move(Square(2, 2), Square(2, 3)),
    buildBoard: () => _board([
      (const Square(2, 2), const Piece(type: PieceType.normal, owner: _pA, face: Face.front)),
      (const Square(2, 3), const Piece(type: PieceType.king, owner: _pB, face: Face.front)),
    ]),
  ),
  Puzzle(
    id: 'diagonal-back',
    difficultyLabel: 'ふつう',
    solverOwner: _pA,
    solutionMove: const Move(Square(1, 1), Square(3, 3)),
    buildBoard: () => _board([
      (const Square(1, 1), const Piece(type: PieceType.normal, owner: _pA, face: Face.back)),
      (const Square(3, 3), const Piece(type: PieceType.king, owner: _pB, face: Face.front)),
      // Decoy: a non-winning move must exist so the puzzle isn't a forced single legal move.
      (const Square(5, 0), const Piece(type: PieceType.normal, owner: _pA, face: Face.front)),
    ]),
  ),
  Puzzle(
    id: 'king-strike',
    difficultyLabel: 'ふつう',
    solverOwner: _pA,
    solutionMove: const Move(Square(4, 4), Square(4, 5)),
    buildBoard: () => _board([
      (const Square(4, 4), const Piece(type: PieceType.king, owner: _pA, face: Face.front)),
      (const Square(4, 5), const Piece(type: PieceType.king, owner: _pB, face: Face.front)),
      (const Square(0, 0), const Piece(type: PieceType.normal, owner: _pA, face: Face.front)),
    ]),
  ),
  Puzzle(
    id: 'diagonal-jump-block',
    difficultyLabel: 'むずかしい',
    solverOwner: _pA,
    solutionMove: const Move(Square(0, 0), Square(2, 2)),
    buildBoard: () => _board([
      (const Square(0, 0), const Piece(type: PieceType.normal, owner: _pA, face: Face.back)),
      (const Square(2, 2), const Piece(type: PieceType.king, owner: _pB, face: Face.front)),
      // Another A piece one square off the direct path -- a tempting but wrong move.
      (const Square(0, 1), const Piece(type: PieceType.normal, owner: _pA, face: Face.front)),
    ]),
  ),
  Puzzle(
    id: 'orthogonal-far-side',
    difficultyLabel: 'かんたん',
    solverOwner: _pA,
    solutionMove: const Move(Square(5, 2), Square(5, 3)),
    buildBoard: () => _board([
      (const Square(5, 2), const Piece(type: PieceType.normal, owner: _pA, face: Face.front)),
      (const Square(5, 3), const Piece(type: PieceType.king, owner: _pB, face: Face.front)),
      (const Square(0, 5), const Piece(type: PieceType.normal, owner: _pA, face: Face.back)),
    ]),
  ),
];

/// Deterministic "Wordle-style" daily selection: every player sees the same
/// puzzle on the same calendar date.
Puzzle puzzleForDate(DateTime date) {
  final dayOfYear = date.difference(DateTime(date.year, 1, 1)).inDays;
  final index = dayOfYear % dailyPuzzles.length;
  return dailyPuzzles[index];
}

String formatDateKey(DateTime date) =>
    '${date.year.toString().padLeft(4, '0')}-'
    '${date.month.toString().padLeft(2, '0')}-'
    '${date.day.toString().padLeft(2, '0')}';
