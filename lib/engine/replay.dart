import 'board.dart';
import 'game_state.dart';
import 'models.dart';

/// Allows replaying a game move-by-move for review and analysis.
class GameReplay {
  final List<Move> moveHistory;
  final GameState initialState;
  int _currentMoveIndex = -1; // -1 means showing initial position

  GameReplay({
    required this.moveHistory,
    required this.initialState,
  });

  /// Get the current game state at the current move index
  GameState get currentState {
    if (_currentMoveIndex < 0) {
      // Return a fresh copy of the initial state
      final state = GameState.initial();
      state.board = initialState.board.clone();
      state.turn = initialState.turn;
      return state;
    }

    // Replay moves up to current index
    final state = GameState.initial();
    state.board = initialState.board.clone();
    state.turn = initialState.turn;

    for (int i = 0; i <= _currentMoveIndex && i < moveHistory.length; i++) {
      state.applyMove(moveHistory[i]);
    }

    return state;
  }

  /// Get the current move index (-1 = initial, 0+ = after move N)
  int get moveIndex => _currentMoveIndex;

  /// Total number of moves in the game
  int get totalMoves => moveHistory.length;

  /// Check if we're at the beginning
  bool get isAtStart => _currentMoveIndex < 0;

  /// Check if we're at the end
  bool get isAtEnd => _currentMoveIndex >= moveHistory.length - 1;

  /// Move to the previous position
  void goBack() {
    if (_currentMoveIndex > -1) {
      _currentMoveIndex--;
    }
  }

  /// Move to the next position
  void goForward() {
    if (_currentMoveIndex < moveHistory.length - 1) {
      _currentMoveIndex++;
    }
  }

  /// Jump to a specific move number
  void jumpToMove(int moveNumber) {
    _currentMoveIndex = moveNumber.clamp(-1, moveHistory.length - 1);
  }

  /// Go to the start
  void goToStart() {
    _currentMoveIndex = -1;
  }

  /// Go to the end
  void goToEnd() {
    _currentMoveIndex = moveHistory.length - 1;
  }

  /// Get the move at the specified index, or null if out of bounds
  Move? getMoveAt(int index) {
    if (index < 0 || index >= moveHistory.length) return null;
    return moveHistory[index];
  }

  /// Get all moves from start to current position
  List<Move> get movedSoFar =>
      _currentMoveIndex < 0 ? [] : moveHistory.sublist(0, _currentMoveIndex + 1);

  /// Get the last move that was played
  Move? get lastMove => _currentMoveIndex >= 0 ? moveHistory[_currentMoveIndex] : null;
}
