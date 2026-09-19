import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:math' as math;

/// Tournament difficulty tier
enum TournamentTier {
  bronze('🥉', 'ブロンズ'),
  silver('🥈', 'シルバー'),
  gold('🥇', 'ゴールド'),
  platinum('💎', 'プラチナ');

  final String emoji;
  final String label;
  const TournamentTier(this.emoji, this.label);
}

/// Tournament status
enum TournamentStatus {
  upcoming('予定中'),
  ongoing('開催中'),
  finished('終了'),
  archived('アーカイブ');

  final String label;
  const TournamentStatus(this.label);
}

/// Tournament participant
class TournamentParticipant {
  final String id;
  final String name;
  final int wins;
  final int losses;
  final int rank;
  final int rating;
  final bool isCurrentPlayer;

  const TournamentParticipant({
    required this.id,
    required this.name,
    required this.wins,
    required this.losses,
    required this.rank,
    required this.rating,
    this.isCurrentPlayer = false,
  });

  double get winRate =>
      wins + losses == 0 ? 0.0 : wins / (wins + losses);
}

/// Tournament round
class TournamentRound {
  final int roundNumber;
  final List<TournamentMatch> matches;
  final DateTime scheduledDate;
  final bool isCompleted;

  const TournamentRound({
    required this.roundNumber,
    required this.matches,
    required this.scheduledDate,
    this.isCompleted = false,
  });
}

/// Tournament match
class TournamentMatch {
  final String id;
  final String player1Id;
  final String player1Name;
  final String player2Id;
  final String player2Name;
  final int? winnerId;
  final bool isCompleted;

  const TournamentMatch({
    required this.id,
    required this.player1Id,
    required this.player1Name,
    required this.player2Id,
    required this.player2Name,
    this.winnerId,
    this.isCompleted = false,
  });

  bool get isCurrentPlayerMatch =>
      winnerId == null && !isCompleted;
}

/// Tournament information
class Tournament {
  final String id;
  final String name;
  final String description;
  final TournamentTier tier;
  final TournamentStatus status;
  final DateTime startDate;
  final DateTime endDate;
  final int maxParticipants;
  final int currentParticipants;
  final int entryFee;
  final int prizePool;
  final List<TournamentParticipant> leaderboard;
  final List<TournamentRound> rounds;
  final int? playerRank;
  final bool isPlayerParticipating;

  const Tournament({
    required this.id,
    required this.name,
    required this.description,
    required this.tier,
    required this.status,
    required this.startDate,
    required this.endDate,
    required this.maxParticipants,
    required this.currentParticipants,
    required this.entryFee,
    required this.prizePool,
    required this.leaderboard,
    required this.rounds,
    this.playerRank,
    this.isPlayerParticipating = false,
  });

  Duration get timeRemaining => endDate.difference(DateTime.now());

  bool get isActive =>
      status == TournamentStatus.ongoing &&
      DateTime.now().isBefore(endDate);
}

/// Tournaments state
class TournamentsState {
  final List<Tournament> activeTournaments;
  final List<Tournament> upcomingTournaments;
  final List<Tournament> pastTournaments;
  final int totalWinnings;
  final int totalParticipations;
  final bool isLoading;
  final String? error;

  const TournamentsState({
    required this.activeTournaments,
    required this.upcomingTournaments,
    required this.pastTournaments,
    this.totalWinnings = 0,
    this.totalParticipations = 0,
    this.isLoading = false,
    this.error,
  });

  /// Copy with modifications
  TournamentsState copyWith({
    List<Tournament>? activeTournaments,
    List<Tournament>? upcomingTournaments,
    List<Tournament>? pastTournaments,
    int? totalWinnings,
    int? totalParticipations,
    bool? isLoading,
    String? error,
  }) {
    return TournamentsState(
      activeTournaments: activeTournaments ?? this.activeTournaments,
      upcomingTournaments: upcomingTournaments ?? this.upcomingTournaments,
      pastTournaments: pastTournaments ?? this.pastTournaments,
      totalWinnings: totalWinnings ?? this.totalWinnings,
      totalParticipations: totalParticipations ?? this.totalParticipations,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

/// Notifier for tournaments
class TournamentsNotifier extends StateNotifier<TournamentsState> {
  SharedPreferences? _prefs;

  TournamentsNotifier()
      : super(_buildInitialState()) {
    _initializeTournaments();
  }

  /// Initialize tournaments
  Future<void> _initializeTournaments() async {
    final prefs = await SharedPreferences.getInstance();
    _prefs = prefs;
    final participationIds =
        prefs.getStringList('tournament_participations') ?? [];
    state = state.copyWith(totalParticipations: participationIds.length);
    _generateTournaments();
  }

  /// Build initial state
  static TournamentsState _buildInitialState() {
    return const TournamentsState(
      activeTournaments: [],
      upcomingTournaments: [],
      pastTournaments: [],
      totalParticipations: 0,
    );
  }

  /// Generate tournaments
  void _generateTournaments() {
    final now = DateTime.now();

    // Active tournaments (ongoing)
    final activeTournaments = [
      _createTournament(
        id: 'tournament_active_1',
        name: '週間シルバー大会',
        description: 'シルバーティアの週間競技大会',
        tier: TournamentTier.silver,
        status: TournamentStatus.ongoing,
        startDate: now.subtract(const Duration(days: 3)),
        endDate: now.add(const Duration(days: 4)),
      ),
      _createTournament(
        id: 'tournament_active_2',
        name: 'ゴールドチャンピオン大会',
        description: 'ゴールドティア最高峰の大会',
        tier: TournamentTier.gold,
        status: TournamentStatus.ongoing,
        startDate: now.subtract(const Duration(days: 1)),
        endDate: now.add(const Duration(days: 6)),
      ),
    ];

    // Upcoming tournaments
    final upcomingTournaments = [
      _createTournament(
        id: 'tournament_upcoming_1',
        name: 'プラチナエリート大会',
        description: 'プラチナティアの限定大会',
        tier: TournamentTier.platinum,
        status: TournamentStatus.upcoming,
        startDate: now.add(const Duration(days: 7)),
        endDate: now.add(const Duration(days: 14)),
      ),
      _createTournament(
        id: 'tournament_upcoming_2',
        name: 'ブロンズリーグ大会',
        description: 'ブロンズティアの初心者向け大会',
        tier: TournamentTier.bronze,
        status: TournamentStatus.upcoming,
        startDate: now.add(const Duration(days: 14)),
        endDate: now.add(const Duration(days: 21)),
      ),
    ];

    // Past tournaments
    final pastTournaments = [
      _createTournament(
        id: 'tournament_past_1',
        name: '先月シルバー大会',
        description: '先月開催されたシルバー大会',
        tier: TournamentTier.silver,
        status: TournamentStatus.finished,
        startDate: now.subtract(const Duration(days: 35)),
        endDate: now.subtract(const Duration(days: 28)),
      ),
    ];

    state = state.copyWith(
      activeTournaments: activeTournaments,
      upcomingTournaments: upcomingTournaments,
      pastTournaments: pastTournaments,
    );
  }

  /// Create a tournament with sample data
  Tournament _createTournament({
    required String id,
    required String name,
    required String description,
    required TournamentTier tier,
    required TournamentStatus status,
    required DateTime startDate,
    required DateTime endDate,
  }) {
    final random = math.Random();
    final participantCount = random.nextInt(50) + 20;
    final prizePool = (participantCount * 10) * 100;

    // Generate leaderboard
    final leaderboard = List.generate(
      math.min(participantCount, 10),
      (index) => TournamentParticipant(
        id: 'player_$index',
        name: _generatePlayerName(index),
        wins: random.nextInt(15) + 5,
        losses: random.nextInt(10),
        rank: index + 1,
        rating: 2000 - (index * 100),
        isCurrentPlayer: index == 2, // 3rd place for demo
      ),
    );

    // Generate rounds
    final rounds = <TournamentRound>[];
    final roundCount = _calculateRounds(participantCount);
    for (int i = 1; i <= roundCount; i++) {
      final roundDate = startDate.add(Duration(days: i));
      final matchCount =
          i == 1 ? participantCount ~/ 2 : math.pow(2, roundCount - i).toInt();

      rounds.add(
        TournamentRound(
          roundNumber: i,
          matches: List.generate(
            matchCount,
            (j) => TournamentMatch(
              id: '${id}_r${i}_m${j}',
              player1Id: 'p${i}_${j}_1',
              player1Name: _generatePlayerName(j * 2),
              player2Id: 'p${i}_${j}_2',
              player2Name: _generatePlayerName(j * 2 + 1),
              winnerId: status == TournamentStatus.finished ||
                      (status == TournamentStatus.ongoing && i < roundCount)
                  ? (random.nextBool() ? 1 : 2)
                  : null,
              isCompleted: status == TournamentStatus.finished ||
                  (status == TournamentStatus.ongoing && i < roundCount),
            ),
          ),
          scheduledDate: roundDate,
          isCompleted: status == TournamentStatus.finished ||
              (status == TournamentStatus.ongoing && i < roundCount),
        ),
      );
    }

    return Tournament(
      id: id,
      name: name,
      description: description,
      tier: tier,
      status: status,
      startDate: startDate,
      endDate: endDate,
      maxParticipants: 128,
      currentParticipants: participantCount,
      entryFee: tier == TournamentTier.bronze
          ? 50
          : tier == TournamentTier.silver
              ? 100
              : tier == TournamentTier.gold
                  ? 200
                  : 500,
      prizePool: prizePool,
      leaderboard: leaderboard,
      rounds: rounds,
      playerRank: random.nextBool() ? random.nextInt(10) + 1 : null,
      isPlayerParticipating: random.nextBool(),
    );
  }

  /// Calculate number of rounds based on participant count
  int _calculateRounds(int participantCount) {
    if (participantCount <= 2) return 1;
    if (participantCount <= 4) return 2;
    if (participantCount <= 8) return 3;
    if (participantCount <= 16) return 4;
    if (participantCount <= 32) return 5;
    return 6;
  }

  /// Generate player name
  String _generatePlayerName(int index) {
    final names = [
      'プレイヤー',
      'チャンプ',
      'マスター',
      'キング',
      'エース',
    ];
    return '${names[index % names.length]}${index + 1}';
  }

  /// Participate in a tournament
  Future<void> participateTournament(String tournamentId) async {
    try {
      final prefs = _prefs ??= await SharedPreferences.getInstance();
      final participations = prefs.getStringList('tournament_participations') ?? [];
      if (!participations.contains(tournamentId)) {
        participations.add(tournamentId);
        await prefs.setStringList('tournament_participations', participations);
      }

      state = state.copyWith(
        totalParticipations: participations.length,
      );
    } catch (e) {
      state = state.copyWith(
        error: 'Failed to participate: $e',
      );
    }
  }

  /// Withdraw from tournament
  Future<void> withdrawTournament(String tournamentId) async {
    try {
      final prefs = _prefs ??= await SharedPreferences.getInstance();
      final participations = prefs.getStringList('tournament_participations') ?? [];
      participations.remove(tournamentId);
      await prefs.setStringList('tournament_participations', participations);

      state = state.copyWith(
        totalParticipations: participations.length,
      );
    } catch (e) {
      state = state.copyWith(
        error: 'Failed to withdraw: $e',
      );
    }
  }
}

/// Riverpod provider for tournaments
final tournamentsProvider = StateNotifierProvider<TournamentsNotifier, TournamentsState>(
  (ref) => TournamentsNotifier(),
);

/// Alternative sync provider (for testing)
final tournamentsSyncProvider =
    StateNotifierProvider<TournamentsNotifier, TournamentsState>((ref) {
  throw UnimplementedError();
});
