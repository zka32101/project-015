import 'game_state.dart';
import 'models.dart';
import 'move_generator.dart';

/// Game replay engine for stepping through games move-by-move
class GameReplay {
  final List<Move> moves;
  int _currentMoveIndex = -1; // -1 means initial position

  GameReplay(this.moves);

  /// Current move index (0-based, -1 for initial position)
  int get currentMoveIndex => _currentMoveIndex;

  /// Total number of moves in the replay
  int get totalMoves => moves.length;

  /// Whether we can move forward
  bool get canMoveForward => _currentMoveIndex < moves.length - 1;

  /// Whether we can move backward
  bool get canMoveBackward => _currentMoveIndex >= 0;

  /// Current progress percentage
  double get progressPercent {
    if (moves.isEmpty) return 0.0;
    return (_currentMoveIndex + 1) / moves.length;
  }

  /// Get the move at a specific index
  Move? getMoveAt(int index) {
    if (index < 0 || index >= moves.length) return null;
    return moves[index];
  }

  /// Get the current move (if any)
  Move? get currentMove => _currentMoveIndex >= 0 ? moves[_currentMoveIndex] : null;

  /// Get the next move (if any)
  Move? get nextMove => _currentMoveIndex + 1 < moves.length ? moves[_currentMoveIndex + 1] : null;

  /// Get the previous move (if any)
  Move? get previousMove => _currentMoveIndex > 0 ? moves[_currentMoveIndex - 1] : null;

  /// Move to the next move
  bool moveForward() {
    if (canMoveForward) {
      _currentMoveIndex++;
      return true;
    }
    return false;
  }

  /// Move to the previous move
  bool moveBackward() {
    if (canMoveBackward) {
      _currentMoveIndex--;
      return true;
    }
    return false;
  }

  /// Jump to a specific move index
  bool jumpToMove(int index) {
    if (index >= -1 && index < moves.length) {
      _currentMoveIndex = index;
      return true;
    }
    return false;
  }

  /// Jump to the start (initial position)
  void jumpToStart() {
    _currentMoveIndex = -1;
  }

  /// Jump to the end (final position)
  void jumpToEnd() {
    _currentMoveIndex = moves.length - 1;
  }

  /// Get description of current position
  String getCurrentPositionDescription() {
    if (_currentMoveIndex == -1) {
      return 'Initial position';
    }
    return 'After move ${_currentMoveIndex + 1} of ${moves.length}';
  }

  /// Get the board state at current move (by replaying from start)
  GameState getBoardStateAtCurrentMove() {
    final board = GameState.initial();
    for (int i = 0; i <= _currentMoveIndex && i < moves.length; i++) {
      board.applyMove(moves[i]);
    }
    return board;
  }

  /// Get a list of all moves up to current position
  List<Move> getMovesUpToCurrent() {
    if (_currentMoveIndex < 0) return [];
    return moves.sublist(0, _currentMoveIndex + 1);
  }

  /// Get remaining moves from current position
  List<Move> getRemainingMoves() {
    if (_currentMoveIndex + 1 >= moves.length) return [];
    return moves.sublist(_currentMoveIndex + 1);
  }
}

/// Replay session with additional metadata
class ReplaySession {
  final GameReplay replay;
  final String playerAName;
  final String playerBName;
  final DateTime playedAt;
  final String? result;
  final String? aiDifficulty;

  ReplaySession({
    required this.replay,
    required this.playerAName,
    required this.playerBName,
    required this.playedAt,
    this.result,
    this.aiDifficulty,
  });

  /// Get formatted date string
  String getFormattedDate() {
    return '${playedAt.year}-${playedAt.month.toString().padLeft(2, '0')}-${playedAt.day.toString().padLeft(2, '0')} '
        '${playedAt.hour.toString().padLeft(2, '0')}:${playedAt.minute.toString().padLeft(2, '0')}';
  }

  /// Get game summary
  String getSummary() {
    final date = getFormattedDate();
    final aiInfo = aiDifficulty != null ? ' (AI: $aiDifficulty)' : '';
    final resultStr = result ?? 'In progress';
    return '$playerAName vs $playerBName$aiInfo\n$date\n$resultStr';
  }
}
