import 'game_state.dart';
import 'models.dart';

/// Manages undo/redo functionality for game state
class GameUndoRedoManager {
  final GameState gameState;
  final List<Move> _undoneHistory = [];

  GameUndoRedoManager(this.gameState);

  /// Whether undo is currently available
  bool get canUndo => gameState.moveHistory.isNotEmpty;

  /// Whether redo is currently available
  bool get canRedo => _undoneHistory.isNotEmpty;

  /// Number of undoable moves
  int get undoCount => gameState.moveHistory.length;

  /// Number of redoable moves
  int get redoCount => _undoneHistory.length;

  /// Undo the last move
  /// Returns true if undo was successful, false if no moves to undo
  bool undo() {
    if (!canUndo || gameState.isOver) {
      return false;
    }

    // Remove the last move from history
    final lastMove = gameState.moveHistory.removeLast();
    _undoneHistory.add(lastMove);

    // Reconstruct game state
    _reconstructGameState();

    return true;
  }

  /// Redo the last undone move
  /// Returns true if redo was successful, false if no moves to redo
  bool redo() {
    if (!canRedo) {
      return false;
    }

    // Get the move to redo
    final moveToRedo = _undoneHistory.removeLast();

    // Re-apply the move
    gameState.applyMove(moveToRedo);

    return true;
  }

  /// Undo multiple moves at once
  /// Returns the number of moves actually undone
  int undoMultiple(int count) {
    int undone = 0;
    for (int i = 0; i < count && canUndo && !gameState.isOver; i++) {
      if (undo()) {
        undone++;
      }
    }
    return undone;
  }

  /// Redo multiple moves at once
  /// Returns the number of moves actually redone
  int redoMultiple(int count) {
    int redone = 0;
    for (int i = 0; i < count && canRedo; i++) {
      if (redo()) {
        redone++;
      }
    }
    return redone;
  }

  /// Undo all moves back to the initial position
  /// Returns the number of moves undone
  int undoAll() {
    return undoMultiple(gameState.moveHistory.length);
  }

  /// Redo all undone moves
  /// Returns the number of moves redone
  int redoAll() {
    return redoMultiple(_undoneHistory.length);
  }

  /// Clear redo history (called when a new move is made after undoing)
  void clearRedoHistory() {
    _undoneHistory.clear();
  }

  /// Reconstruct the game state by replaying moves from the beginning
  void _reconstructGameState() {
    // Create a fresh GameState and replay only the moves that should be active
    final freshState = GameState.initial();

    // Transfer the fresh state to the current gameState object
    gameState.board = freshState.board;
    gameState.turn = freshState.turn;
    gameState.plyCount = freshState.plyCount;
    gameState.result = freshState.result;

    // Rebuild position counts by replaying moves
    final savedHistory = List<Move>.from(gameState.moveHistory);
    gameState.moveHistory.clear();

    // Re-apply each move to update the state correctly
    for (final move in savedHistory) {
      try {
        gameState.applyMove(move);
      } catch (e) {
        // If move application fails, restore and break
        gameState.moveHistory.removeAt(gameState.moveHistory.length - 1);
        break;
      }
    }
  }
}
