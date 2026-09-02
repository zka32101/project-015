import 'models.dart';

/// Game notation system for recording and replaying Reversia games
/// Uses standard algebraic notation: column (a-f) + row (1-6)
class GameNotation {
  /// Convert a move to standard notation (e.g., "c4" for column C, row 4)
  static String moveToNotation(Move move) {
    final col = String.fromCharCode(97 + move.to.col); // a-f
    final row = move.to.row + 1; // 1-6
    return '$col$row';
  }

  /// Parse notation string to Square (e.g., "c4" -> Square(3, 2))
  static Square? notationToSquare(String notation) {
    if (notation.length != 2) return null;

    final colChar = notation[0].toLowerCase();
    final rowChar = notation[1];

    final col = colChar.codeUnitAt(0) - 97; // a=0, b=1, etc.
    final row = int.tryParse(rowChar);

    if (col < 0 || col > 5 || row == null || row < 1 || row > 6) {
      return null;
    }

    return Square(row - 1, col);
  }

  /// Convert entire game history to notation string
  /// Format: "1. c4 d3 2. c5 b4 ..." (moves separated by spaces, turns by dots)
  static String gameToNotation(List<Move> moveHistory) {
    if (moveHistory.isEmpty) return '';

    final notations = moveHistory.map((move) => moveToNotation(move)).toList();
    final buffer = StringBuffer();

    for (int i = 0; i < notations.length; i++) {
      if (i % 2 == 0) {
        // Start of new turn
        buffer.write('${(i ~/ 2) + 1}. ');
      }
      buffer.write(notations[i]);
      if (i < notations.length - 1) {
        buffer.write(' ');
      }
    }

    return buffer.toString();
  }

  /// Parse notation string back to move list
  /// Returns null if notation is invalid
  static List<Move>? notationToGame(String notation) {
    if (notation.isEmpty) return [];

    final moves = <Move>[];
    // Remove turn numbers and split by spaces
    final parts = notation.replaceAll(RegExp(r'\d+\.\s*'), '').split(RegExp(r'\s+'));

    for (final part in parts) {
      if (part.isEmpty) continue;

      // Parse "c4c5" format for move notation (from-to)
      if (part.length == 4) {
        final fromSquare = notationToSquare(part.substring(0, 2));
        final toSquare = notationToSquare(part.substring(2, 4));
        if (fromSquare != null && toSquare != null) {
          moves.add(Move(fromSquare, toSquare));
        } else {
          return null;
        }
      }
      // Parse single square notation (destination only, for simple format)
      else if (part.length == 2) {
        final toSquare = notationToSquare(part);
        if (toSquare != null) {
          moves.add(Move(Square(0, 0), toSquare)); // Placeholder from
        } else {
          return null;
        }
      } else {
        return null;
      }
    }

    return moves;
  }

  /// Format move history as a readable string with turnwise layout
  static String formatMoveHistory(List<Move> moves) {
    if (moves.isEmpty) return 'No moves yet';

    final buffer = StringBuffer();
    buffer.writeln('Move History:');
    buffer.writeln('─' * 40);

    for (int i = 0; i < moves.length; i++) {
      if (i % 2 == 0) {
        buffer.write('Turn ${(i ~/ 2) + 1}: ');
        buffer.write('Black: ${moveToNotation(moves[i])}');
        if (i + 1 < moves.length) {
          buffer.write(' | White: ${moveToNotation(moves[i + 1])}');
          i++; // Skip next move as we've already written it
        }
        buffer.writeln();
      }
    }

    return buffer.toString();
  }

  /// Get the board state at a specific move number (for replay)
  static String getBoardStateDescription(int moveNumber, int totalMoves) {
    final percent = totalMoves > 0 ? ((moveNumber / totalMoves) * 100).toStringAsFixed(0) : '0';
    return 'After move $moveNumber/$totalMoves ($percent%)';
  }
}

/// Game record storing complete game information for replay/analysis
class GameRecord {
  final String playerAName;
  final String playerBName;
  final String? aiDifficulty; // null if human vs human
  final List<Move> moves;
  final DateTime playedAt;
  final String? result; // e.g., "Black wins 25-11"
  final int? duration; // In seconds

  GameRecord({
    required this.playerAName,
    required this.playerBName,
    this.aiDifficulty,
    required this.moves,
    required this.playedAt,
    this.result,
    this.duration,
  });

  /// Convert record to JSON for storage
  Map<String, dynamic> toJson() {
    return {
      'playerAName': playerAName,
      'playerBName': playerBName,
      'aiDifficulty': aiDifficulty,
      'notation': GameNotation.gameToNotation(moves),
      'playedAt': playedAt.toIso8601String(),
      'result': result,
      'duration': duration,
    };
  }

  /// Create record from JSON
  factory GameRecord.fromJson(Map<String, dynamic> json) {
    final moves = GameNotation.notationToGame(json['notation'] ?? '') ?? [];
    return GameRecord(
      playerAName: json['playerAName'] ?? 'Player A',
      playerBName: json['playerBName'] ?? 'Player B',
      aiDifficulty: json['aiDifficulty'],
      moves: moves,
      playedAt: DateTime.parse(json['playedAt']),
      result: json['result'],
      duration: json['duration'],
    );
  }

  /// Get human-readable summary
  String getSummary() {
    final duration = this.duration != null ? ' (${(this.duration! ~/ 60)}m)' : '';
    return '$playerAName vs $playerBName$duration - ${result ?? "In progress"}';
  }
}
