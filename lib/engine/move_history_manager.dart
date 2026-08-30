import 'game_state.dart';
import 'models.dart';

/// Manages undo/redo history for game moves
class MoveHistoryManager {
  /// Stack of game states for undo functionality
  final List<GameState> _undoStack = [];

  /// Stack of moves for redo functionality
  final List<Move> _redoStack = [];

  /// Check if undo is available
  bool get canUndo => _undoStack.isNotEmpty;

  /// Check if redo is available
  bool get canRedo => _redoStack.isNotEmpty;

  /// Record a move - called when a move is applied
  void recordMove(GameState stateBefore) {
    // Clear redo stack when a new move is made
    _redoStack.clear();

    // Store the state before the move for undo
    _undoStack.add(stateBefore);
  }

  /// Undo the last move if possible
  GameState? undo(GameState currentState) {
    if (!canUndo) return null;

    // Store current state in redo stack
    _redoStack.add(currentState.moveHistory.last);

    // Return the previous state
    return _undoStack.removeLast();
  }

  /// Redo the last undone move if possible
  Move? redo() {
    if (!canRedo) return null;
    return _redoStack.removeLast();
  }

  /// Clear all undo/redo history (useful for game restart)
  void clear() {
    _undoStack.clear();
    _redoStack.clear();
  }

  /// Get the number of moves that can be undone
  int get undoCount => _undoStack.length;

  /// Get the number of moves that can be redone
  int get redoCount => _redoStack.length;
}
