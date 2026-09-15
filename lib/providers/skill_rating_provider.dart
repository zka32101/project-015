import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:math' as math;

/// Rating tier
enum RatingTier {
  bronze('ブロンズ', 0, 500),
  silver('シルバー', 500, 1000),
  gold('ゴールド', 1000, 1500),
  platinum('プラチナ', 1500, 2000),
  diamond('ダイヤモンド', 2000, 2500),
  master('マスター', 2500, 10000);

  final String label;
  final int minRating;
  final int maxRating;
  const RatingTier(this.label, this.minRating, this.maxRating);

  static RatingTier getTierForRating(int rating) {
    for (final tier in RatingTier.values) {
      if (rating >= tier.minRating && rating < tier.maxRating) {
        return tier;
      }
    }
    return RatingTier.master;
  }
}

/// Skill category
enum SkillCategory {
  opening('序盤'),
  midgame('中盤'),
  endgame('終盤'),
  tactical('戦術力');

  final String label;
  const SkillCategory(this.label);
}

/// Rating record
class RatingRecord {
  final DateTime timestamp;
  final int ratingBefore;
  final int ratingAfter;
  final int ratingChange;
  final bool isWin;
  final String? opponentName;
  final int? opponentRating;

  const RatingRecord({
    required this.timestamp,
    required this.ratingBefore,
    required this.ratingAfter,
    required this.ratingChange,
    required this.isWin,
    this.opponentName,
    this.opponentRating,
  });

  RatingRecord copyWith({
    DateTime? timestamp,
    int? ratingBefore,
    int? ratingAfter,
    int? ratingChange,
    bool? isWin,
    String? opponentName,
    int? opponentRating,
  }) {
    return RatingRecord(
      timestamp: timestamp ?? this.timestamp,
      ratingBefore: ratingBefore ?? this.ratingBefore,
      ratingAfter: ratingAfter ?? this.ratingAfter,
      ratingChange: ratingChange ?? this.ratingChange,
      isWin: isWin ?? this.isWin,
      opponentName: opponentName ?? this.opponentName,
      opponentRating: opponentRating ?? this.opponentRating,
    );
  }
}

/// Skill rating
class SkillRating {
  final SkillCategory category;
  final int rating;
  final int maxRating;
  final int gamesPlayed;

  const SkillRating({
    required this.category,
    required this.rating,
    required this.maxRating,
    required this.gamesPlayed,
  });

  SkillRating copyWith({
    SkillCategory? category,
    int? rating,
    int? maxRating,
    int? gamesPlayed,
  }) {
    return SkillRating(
      category: category ?? this.category,
      rating: rating ?? this.rating,
      maxRating: maxRating ?? this.maxRating,
      gamesPlayed: gamesPlayed ?? this.gamesPlayed,
    );
  }
}

/// Skill rating state
class SkillRatingState {
  final int currentRating;
  final RatingTier currentTier;
  final int totalGamesPlayed;
  final int totalWins;
  final double winRate;
  final List<RatingRecord> ratingHistory;
  final List<SkillRating> skillRatings;
  final int highestRating;
  final DateTime? highestRatingDate;
  final int ratingChange24h;
  final bool isLoading;
  final String? error;

  const SkillRatingState({
    required this.currentRating,
    required this.currentTier,
    required this.totalGamesPlayed,
    required this.totalWins,
    required this.winRate,
    required this.ratingHistory,
    required this.skillRatings,
    required this.highestRating,
    this.highestRatingDate,
    this.ratingChange24h = 0,
    this.isLoading = false,
    this.error,
  });

  SkillRatingState copyWith({
    int? currentRating,
    RatingTier? currentTier,
    int? totalGamesPlayed,
    int? totalWins,
    double? winRate,
    List<RatingRecord>? ratingHistory,
    List<SkillRating>? skillRatings,
    int? highestRating,
    DateTime? highestRatingDate,
    int? ratingChange24h,
    bool? isLoading,
    String? error,
  }) {
    return SkillRatingState(
      currentRating: currentRating ?? this.currentRating,
      currentTier: currentTier ?? this.currentTier,
      totalGamesPlayed: totalGamesPlayed ?? this.totalGamesPlayed,
      totalWins: totalWins ?? this.totalWins,
      winRate: winRate ?? this.winRate,
      ratingHistory: ratingHistory ?? this.ratingHistory,
      skillRatings: skillRatings ?? this.skillRatings,
      highestRating: highestRating ?? this.highestRating,
      highestRatingDate: highestRatingDate ?? this.highestRatingDate,
      ratingChange24h: ratingChange24h ?? this.ratingChange24h,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

/// Notifier for skill rating
class SkillRatingNotifier extends StateNotifier<SkillRatingState> {
  final SharedPreferences prefs;

  SkillRatingNotifier(this.prefs)
      : super(_buildInitialState(prefs)) {
    _initializeRating();
  }

  static SkillRatingState _buildInitialState(SharedPreferences prefs) {
    final currentRating = prefs.getInt('current_rating') ?? 1200;
    final highestRating = prefs.getInt('highest_rating') ?? currentRating;
    final totalGamesPlayed = prefs.getInt('total_games_played_rating') ?? 0;
    final totalWins = prefs.getInt('total_wins_rating') ?? 0;

    final winRate = totalGamesPlayed > 0
        ? (totalWins / totalGamesPlayed)
        : 0.0;

    return SkillRatingState(
      currentRating: currentRating,
      currentTier: RatingTier.getTierForRating(currentRating),
      totalGamesPlayed: totalGamesPlayed,
      totalWins: totalWins,
      winRate: winRate,
      ratingHistory: [],
      skillRatings: [],
      highestRating: highestRating,
    );
  }

  void _initializeRating() {
    _initializeSkillRatings();
    _generateSampleHistory();
  }

  void _initializeSkillRatings() {
    final ratings = [
      SkillRating(
        category: SkillCategory.opening,
        rating: 1150,
        maxRating: 1450,
        gamesPlayed: 45,
      ),
      SkillRating(
        category: SkillCategory.midgame,
        rating: 1200,
        maxRating: 1500,
        gamesPlayed: 52,
      ),
      SkillRating(
        category: SkillCategory.endgame,
        rating: 1250,
        maxRating: 1520,
        gamesPlayed: 48,
      ),
      SkillRating(
        category: SkillCategory.tactical,
        rating: 1180,
        maxRating: 1480,
        gamesPlayed: 50,
      ),
    ];

    state = state.copyWith(skillRatings: ratings);
  }

  void _generateSampleHistory() {
    final now = DateTime.now();
    final history = <RatingRecord>[];
    var currentRating = 1200;

    for (int i = 19; i >= 0; i--) {
      final timestamp = now.subtract(Duration(hours: i));
      final isWin = math.Random().nextBool();
      final ratingChange = isWin
          ? math.Random().nextInt(20) + 10
          : -(math.Random().nextInt(20) + 5);
      final previousRating = currentRating;
      currentRating = (currentRating + ratingChange).clamp(0, 10000);

      history.add(RatingRecord(
        timestamp: timestamp,
        ratingBefore: previousRating,
        ratingAfter: currentRating,
        ratingChange: ratingChange,
        isWin: isWin,
        opponentName: isWin
            ? ['AI (Hard)', 'AI (Normal)', 'Player'].
                [math.Random().nextInt(3)]
            : ['AI (Expert)', 'Player'].
                [math.Random().nextInt(2)],
        opponentRating: previousRating + math.Random().nextInt(200) - 100,
      ));
    }

    state = state.copyWith(ratingHistory: history);
  }

  Future<void> recordGameResult({
    required bool isWin,
    required int opponentRating,
    String? opponentName,
  }) async {
    try {
      final ratingChange = _calculateRatingChange(
        isWin: isWin,
        currentRating: state.currentRating,
        opponentRating: opponentRating,
      );

      final newRating =
          (state.currentRating + ratingChange).clamp(0, 10000);
      final newTotal = state.totalGamesPlayed + 1;
      final newWins = state.totalWins + (isWin ? 1 : 0);
      final newWinRate = newWins / newTotal;

      final record = RatingRecord(
        timestamp: DateTime.now(),
        ratingBefore: state.currentRating,
        ratingAfter: newRating,
        ratingChange: ratingChange,
        isWin: isWin,
        opponentName: opponentName,
        opponentRating: opponentRating,
      );

      final history = [record, ...state.ratingHistory].take(50).toList();

      await prefs.setInt('current_rating', newRating);
      await prefs.setInt('total_games_played_rating', newTotal);
      await prefs.setInt('total_wins_rating', newWins);

      int newHighest = state.highestRating;
      DateTime? newHighestDate = state.highestRatingDate;
      if (newRating > newHighest) {
        newHighest = newRating;
        newHighestDate = DateTime.now();
        await prefs.setInt('highest_rating', newHighest);
      }

      final ratingChange24h = _calculateRatingChange24h(history);

      state = state.copyWith(
        currentRating: newRating,
        currentTier: RatingTier.getTierForRating(newRating),
        totalGamesPlayed: newTotal,
        totalWins: newWins,
        winRate: newWinRate,
        ratingHistory: history,
        highestRating: newHighest,
        highestRatingDate: newHighestDate,
        ratingChange24h: ratingChange24h,
      );
    } catch (e) {
      state = state.copyWith(error: 'Failed to record game: $e');
    }
  }

  int _calculateRatingChange({
    required bool isWin,
    required int currentRating,
    required int opponentRating,
  }) {
    const K = 32;
    final expected = 1 / (1 + math.pow(10, (opponentRating - currentRating) / 400));
    final score = isWin ? 1.0 : 0.0;
    final change = (K * (score - expected)).round();
    return change;
  }

  int _calculateRatingChange24h(List<RatingRecord> history) {
    final now = DateTime.now();
    final day24hAgo = now.subtract(const Duration(hours: 24));

    final recent = history
        .where((record) => record.timestamp.isAfter(day24hAgo))
        .toList();

    if (recent.isEmpty) return 0;
    return recent.last.ratingAfter - recent.last.ratingBefore;
  }

  Future<void> updateSkillRating(
    SkillCategory category,
    int newRating,
  ) async {
    try {
      final updated = state.skillRatings
          .map((skill) => skill.category == category
              ? skill.copyWith(
                  rating: newRating,
                  maxRating: math.max(skill.maxRating, newRating),
                  gamesPlayed: skill.gamesPlayed + 1,
                )
              : skill)
          .toList();

      state = state.copyWith(skillRatings: updated);
    } catch (e) {
      state = state.copyWith(error: 'Failed to update skill rating: $e');
    }
  }
}

/// Riverpod provider for skill rating
final skillRatingProvider =
    StateNotifierProvider<SkillRatingNotifier, SkillRatingState>(
  (ref) async {
    final prefs = await SharedPreferences.getInstance();
    return SkillRatingNotifier(prefs);
  },
);
