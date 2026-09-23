import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../engine/game_notation.dart';
import '../engine/models.dart';

/// A lobby waiting for a second player, backed by a `lobbies` Firestore
/// document. Reversia is strictly 2-player, so a lobby always fills at
/// exactly 2 (host + one joiner); once full, [matchId] is set and both
/// clients pick up the created match document.
class OnlineLobby {
  final String id;
  final String hostUid;
  final String hostName;
  final String hostAvatarEmoji;
  final int hostRating;
  final String gameMode;
  final int timeLimit;
  final int playerCount;
  final DateTime createdAt;
  final bool isRanked;
  final String? matchId;

  const OnlineLobby({
    required this.id,
    required this.hostUid,
    required this.hostName,
    required this.hostAvatarEmoji,
    required this.hostRating,
    required this.gameMode,
    required this.timeLimit,
    required this.playerCount,
    required this.createdAt,
    required this.isRanked,
    this.matchId,
  });

  int get maxPlayers => 2;

  bool get isFull => playerCount >= maxPlayers;

  int get waitingSlots => maxPlayers - playerCount;

  Duration get age => DateTime.now().difference(createdAt);

  factory OnlineLobby.fromSnapshot(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    return OnlineLobby(
      id: doc.id,
      hostUid: data['hostUid'] as String,
      hostName: data['hostName'] as String,
      hostAvatarEmoji: data['hostAvatarEmoji'] as String,
      hostRating: data['hostRating'] as int,
      gameMode: data['gameMode'] as String,
      timeLimit: data['timeLimit'] as int,
      playerCount: data['playerCount'] as int,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      isRanked: data['isRanked'] as bool,
      matchId: data['matchId'] as String?,
    );
  }

  Map<String, dynamic> toFirestore() => {
        'hostUid': hostUid,
        'hostName': hostName,
        'hostAvatarEmoji': hostAvatarEmoji,
        'hostRating': hostRating,
        'gameMode': gameMode,
        'timeLimit': timeLimit,
        'playerCount': playerCount,
        'createdAt': Timestamp.fromDate(createdAt),
        'isRanked': isRanked,
        'matchId': matchId,
      };
}

/// Ongoing multiplayer match, backed by a `matches` Firestore document that
/// both players read from and write moves to.
class MultiplayerMatch {
  final String id;
  final String player1Uid;
  final String player1Name;
  final String player1AvatarEmoji;
  final int player1Rating;
  final String player2Uid;
  final String player2Name;
  final String player2AvatarEmoji;
  final int player2Rating;
  final String gameMode;
  final DateTime startedAt;
  final bool isRanked;
  final int moveCount;
  final String currentTurn; // 'player1' or 'player2'
  final double player1Pieces;
  final double player2Pieces;
  // Every move so far, in standard notation (see GameNotation.moveToNotation),
  // so both clients can replay the exact same board via GameState.applyMove.
  final List<String> moves;

  const MultiplayerMatch({
    required this.id,
    required this.player1Uid,
    required this.player1Name,
    required this.player1AvatarEmoji,
    required this.player1Rating,
    required this.player2Uid,
    required this.player2Name,
    required this.player2AvatarEmoji,
    required this.player2Rating,
    required this.gameMode,
    required this.startedAt,
    required this.isRanked,
    required this.moveCount,
    required this.currentTurn,
    required this.player1Pieces,
    required this.player2Pieces,
    this.moves = const [],
  });

  Duration get duration => DateTime.now().difference(startedAt);

  factory MultiplayerMatch.fromSnapshot(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    return MultiplayerMatch(
      id: doc.id,
      player1Uid: data['player1Uid'] as String,
      player1Name: data['player1Name'] as String,
      player1AvatarEmoji: data['player1AvatarEmoji'] as String,
      player1Rating: data['player1Rating'] as int,
      player2Uid: data['player2Uid'] as String,
      player2Name: data['player2Name'] as String,
      player2AvatarEmoji: data['player2AvatarEmoji'] as String,
      player2Rating: data['player2Rating'] as int,
      gameMode: data['gameMode'] as String,
      startedAt: (data['startedAt'] as Timestamp).toDate(),
      isRanked: data['isRanked'] as bool,
      moveCount: data['moveCount'] as int,
      currentTurn: data['currentTurn'] as String,
      player1Pieces: (data['player1Pieces'] as num).toDouble(),
      player2Pieces: (data['player2Pieces'] as num).toDouble(),
      moves: (data['moves'] as List<dynamic>? ?? const [])
          .map((m) => m as String)
          .toList(),
    );
  }

  Map<String, dynamic> toFirestore() => {
        'player1Uid': player1Uid,
        'player1Name': player1Name,
        'player1AvatarEmoji': player1AvatarEmoji,
        'player1Rating': player1Rating,
        'player2Uid': player2Uid,
        'player2Name': player2Name,
        'player2AvatarEmoji': player2AvatarEmoji,
        'player2Rating': player2Rating,
        'gameMode': gameMode,
        'startedAt': Timestamp.fromDate(startedAt),
        'isRanked': isRanked,
        'moveCount': moveCount,
        'currentTurn': currentTurn,
        'player1Pieces': player1Pieces,
        'player2Pieces': player2Pieces,
        'moves': moves,
        'status': 'active',
        'winner': null,
        // Powers the "my match history" query in _watchHistory below.
        'participants': [player1Uid, player2Uid],
      };
}

/// A finished match, read back from a `matches` document once its status
/// has been set to 'finished' by [MultiplayerNotifier.endMatch].
class MatchResult {
  final String id;
  final String player1Name;
  final String player1AvatarEmoji;
  final String player2Name;
  final String player2AvatarEmoji;
  final String winner;
  final int winnerRatingGain;
  final int loserRatingLoss;
  final DateTime playedAt;
  final int duration;
  final int totalMoves;
  final bool isRanked;
  final String gameMode;

  const MatchResult({
    required this.id,
    required this.player1Name,
    required this.player1AvatarEmoji,
    required this.player2Name,
    required this.player2AvatarEmoji,
    required this.winner,
    required this.winnerRatingGain,
    required this.loserRatingLoss,
    required this.playedAt,
    required this.duration,
    required this.totalMoves,
    required this.isRanked,
    required this.gameMode,
  });

  bool get isWinForPlayer1 => winner == player1Name;

  String opponentFor(String playerName) =>
      playerName == player1Name ? player2Name : player1Name;

  factory MatchResult.fromSnapshot(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    return MatchResult(
      id: doc.id,
      player1Name: data['player1Name'] as String,
      player1AvatarEmoji: data['player1AvatarEmoji'] as String,
      player2Name: data['player2Name'] as String,
      player2AvatarEmoji: data['player2AvatarEmoji'] as String,
      winner: data['winner'] as String,
      winnerRatingGain: data['winnerRatingGain'] as int,
      loserRatingLoss: data['loserRatingLoss'] as int,
      playedAt: (data['endedAt'] as Timestamp).toDate(),
      duration: data['duration'] as int,
      totalMoves: data['moveCount'] as int,
      isRanked: data['isRanked'] as bool,
      gameMode: data['gameMode'] as String,
    );
  }
}

/// Multiplayer state
class MultiplayerState {
  final List<OnlineLobby> availableLobbies;
  final MultiplayerMatch? currentMatch;
  final List<MatchResult> matchHistory;
  final bool isSearchingForMatch;
  final bool isLoading;
  final String? error;
  final int onlinePlayersCount;

  const MultiplayerState({
    required this.availableLobbies,
    this.currentMatch,
    required this.matchHistory,
    this.isSearchingForMatch = false,
    this.isLoading = false,
    this.error,
    required this.onlinePlayersCount,
  });

  MultiplayerState copyWith({
    List<OnlineLobby>? availableLobbies,
    Object? currentMatch = _unset,
    List<MatchResult>? matchHistory,
    bool? isSearchingForMatch,
    bool? isLoading,
    Object? error = _unset,
    int? onlinePlayersCount,
  }) {
    return MultiplayerState(
      availableLobbies: availableLobbies ?? this.availableLobbies,
      currentMatch: identical(currentMatch, _unset)
          ? this.currentMatch
          : currentMatch as MultiplayerMatch?,
      matchHistory: matchHistory ?? this.matchHistory,
      isSearchingForMatch: isSearchingForMatch ?? this.isSearchingForMatch,
      isLoading: isLoading ?? this.isLoading,
      error: identical(error, _unset) ? this.error : error as String?,
      onlinePlayersCount: onlinePlayersCount ?? this.onlinePlayersCount,
    );
  }
}

/// Sentinel used by [MultiplayerState.copyWith] to distinguish "field not
/// passed" (keep current value) from "field explicitly passed as null"
/// (clear the value).
const Object _unset = Object();

/// Notifier for multiplayer and online battles, backed by Firestore so two
/// separate app instances pointed at the same Firebase project can actually
/// see and play against each other.
///
/// Note: this only syncs lobby/match *metadata* (who's playing, whose turn
/// it is, piece counts). Wiring the real board so moves actually flow
/// through here is a separate follow-up -- see [updateMatchState].
class MultiplayerNotifier extends StateNotifier<MultiplayerState> {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _lobbiesSub;
  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? _matchSub;
  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? _queueSub;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _historySub;
  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? _ownLobbySub;

  MultiplayerNotifier({FirebaseFirestore? firestore, FirebaseAuth? auth})
      : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance,
        super(const MultiplayerState(
          availableLobbies: [],
          matchHistory: [],
          onlinePlayersCount: 0,
        )) {
    _initialize();
  }

  /// The signed-in player's uid, for telling player1/player2 apart on the
  /// online game screen. Null until [_ensureSignedIn] has resolved once.
  String? get myUid => _auth.currentUser?.uid;

  Future<String> _ensureSignedIn() async {
    final current = _auth.currentUser;
    if (current != null) return current.uid;
    final credential = await _auth.signInAnonymously();
    return credential.user!.uid;
  }

  Future<void> _initialize() async {
    final uid = await _ensureSignedIn();
    _watchLobbies();
    _watchHistory(uid);
  }

  void _watchLobbies() {
    _lobbiesSub?.cancel();
    _lobbiesSub = _firestore
        .collection('lobbies')
        .where('matchId', isNull: true)
        .orderBy('createdAt', descending: true)
        .limit(50)
        .snapshots()
        .listen((snapshot) {
      final lobbies = snapshot.docs.map(OnlineLobby.fromSnapshot).toList();
      final onlineCount =
          lobbies.fold<int>(0, (total, lobby) => total + lobby.playerCount);
      state = state.copyWith(
        availableLobbies: lobbies,
        onlinePlayersCount: onlineCount,
      );
    });
  }

  void _watchHistory(String uid) {
    _historySub?.cancel();
    _historySub = _firestore
        .collection('matches')
        .where('participants', arrayContains: uid)
        .where('status', isEqualTo: 'finished')
        .orderBy('endedAt', descending: true)
        .limit(20)
        .snapshots()
        .listen((snapshot) {
      final results = snapshot.docs.map(MatchResult.fromSnapshot).toList();
      state = state.copyWith(matchHistory: results);
    });
  }

  /// Lobbies are already kept live via [_watchLobbies]; this exists so the
  /// pull-to-refresh gesture and the "no lobbies" empty state have
  /// something to await and show a spinner for.
  Future<void> refreshLobbies() async {
    state = state.copyWith(isLoading: true);
    await _firestore.collection('lobbies').limit(1).get();
    state = state.copyWith(isLoading: false);
  }

  /// Creates a new lobby with the caller as host and waits for someone to
  /// join it (see [joinLobby]). The host's own client learns the match
  /// started by watching its own lobby document for [matchId] to appear --
  /// without this, the host would never leave the lobby screen even after
  /// someone joined, since [joinLobby] runs entirely on the joiner's side.
  Future<void> hostLobby({
    required String hostName,
    required String hostAvatarEmoji,
    required int hostRating,
    required String gameMode,
    required int timeLimit,
    required bool isRanked,
  }) async {
    final uid = await _ensureSignedIn();
    final lobbyRef = await _firestore.collection('lobbies').add(
          OnlineLobby(
            id: '',
            hostUid: uid,
            hostName: hostName,
            hostAvatarEmoji: hostAvatarEmoji,
            hostRating: hostRating,
            gameMode: gameMode,
            timeLimit: timeLimit,
            playerCount: 1,
            createdAt: DateTime.now(),
            isRanked: isRanked,
          ).toFirestore(),
        );
    _watchOwnLobby(lobbyRef);
  }

  void _watchOwnLobby(DocumentReference<Map<String, dynamic>> lobbyRef) {
    _ownLobbySub?.cancel();
    _ownLobbySub = lobbyRef.snapshots().listen((snapshot) {
      final matchId = snapshot.data()?['matchId'] as String?;
      if (matchId == null) return;
      _ownLobbySub?.cancel();
      _watchMatch(matchId);
    });
  }

  Future<void> joinLobby(
    String lobbyId, {
    String playerName = 'あなた',
    String playerAvatarEmoji = '🎮',
    int playerRating = 1500,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    final uid = await _ensureSignedIn();
    final lobbyRef = _firestore.collection('lobbies').doc(lobbyId);
    final matchRef = _firestore.collection('matches').doc();

    try {
      await _firestore.runTransaction((tx) async {
        final snapshot = await tx.get(lobbyRef);
        if (!snapshot.exists) {
          throw StateError('ロビーが見つかりませんでした');
        }
        final lobby = OnlineLobby.fromSnapshot(snapshot);
        if (lobby.isFull || lobby.matchId != null) {
          throw StateError('このロビーは既に満員です');
        }
        if (lobby.hostUid == uid) {
          throw StateError('自分のロビーには参加できません');
        }

        final match = MultiplayerMatch(
          id: matchRef.id,
          player1Uid: lobby.hostUid,
          player1Name: lobby.hostName,
          player1AvatarEmoji: lobby.hostAvatarEmoji,
          player1Rating: lobby.hostRating,
          player2Uid: uid,
          player2Name: playerName,
          player2AvatarEmoji: playerAvatarEmoji,
          player2Rating: playerRating,
          gameMode: lobby.gameMode,
          startedAt: DateTime.now(),
          isRanked: lobby.isRanked,
          moveCount: 0,
          currentTurn: 'player1',
          // Reversia starts each side with 9 pieces on the board (see
          // Board.initial()), not the 2 a Reversi/Othello clone would use.
          player1Pieces: 9,
          player2Pieces: 9,
        );

        tx.set(matchRef, match.toFirestore());
        tx.update(lobbyRef, {'playerCount': 2, 'matchId': matchRef.id});
      });
    } on StateError catch (e) {
      state = state.copyWith(isLoading: false, error: e.message);
      return;
    } catch (_) {
      state = state.copyWith(isLoading: false, error: 'ロビーへの参加に失敗しました');
      return;
    }

    _watchMatch(matchRef.id);
    state = state.copyWith(isLoading: false);
  }

  /// Simple client-side matchmaking: look for someone else already waiting
  /// in the queue and claim them; if nobody is waiting, join the queue and
  /// wait to be claimed. A production-scale version of this would move the
  /// claim into a Cloud Function to close a narrow race window, but for a
  /// hobby-scale player count a transaction on the candidate's queue
  /// document is enough to prevent two callers claiming the same opponent.
  Future<void> startQuickMatch({
    String playerName = 'あなた',
    String playerAvatarEmoji = '🎮',
    int playerRating = 1500,
    String gameMode = 'ランク戦',
  }) async {
    state = state.copyWith(isSearchingForMatch: true, error: null);
    final uid = await _ensureSignedIn();
    final queueRef = _firestore.collection('quickMatchQueue').doc(uid);

    try {
      final candidates = await _firestore
          .collection('quickMatchQueue')
          .where('matchId', isNull: true)
          .limit(10)
          .get();
      final otherCandidates =
          candidates.docs.where((doc) => doc.id != uid).toList();
      final opponentDoc = otherCandidates.isEmpty ? null : otherCandidates.first;

      if (opponentDoc != null) {
        final matchRef = _firestore.collection('matches').doc();
        final claimed = await _firestore.runTransaction<bool>((tx) async {
          final freshOpponent = await tx.get(opponentDoc.reference);
          final opponentData = freshOpponent.data();
          if (!freshOpponent.exists ||
              opponentData == null ||
              opponentData['matchId'] != null) {
            return false;
          }

          final match = MultiplayerMatch(
            id: matchRef.id,
            player1Uid: opponentDoc.id,
            player1Name: opponentData['name'] as String,
            player1AvatarEmoji: opponentData['avatarEmoji'] as String,
            player1Rating: opponentData['rating'] as int,
            player2Uid: uid,
            player2Name: playerName,
            player2AvatarEmoji: playerAvatarEmoji,
            player2Rating: playerRating,
            gameMode: gameMode,
            startedAt: DateTime.now(),
            isRanked: true,
            moveCount: 0,
            currentTurn: 'player1',
            player1Pieces: 9,
            player2Pieces: 9,
          );

          tx.set(matchRef, match.toFirestore());
          tx.update(opponentDoc.reference, {'matchId': matchRef.id});
          return true;
        });

        if (claimed) {
          _watchMatch(matchRef.id);
          state = state.copyWith(isSearchingForMatch: false);
          return;
        }
      }

      // Nobody available to claim (or another caller won the race for the
      // same candidate) -- wait in the queue for someone to claim us.
      await queueRef.set({
        'name': playerName,
        'avatarEmoji': playerAvatarEmoji,
        'rating': playerRating,
        'gameMode': gameMode,
        'matchId': null,
        'requestedAt': Timestamp.fromDate(DateTime.now()),
      });
      _watchQueue(queueRef);
    } catch (_) {
      state = state.copyWith(
        isSearchingForMatch: false,
        error: '対戦相手を見つけられませんでした',
      );
    }
  }

  void _watchQueue(DocumentReference<Map<String, dynamic>> queueRef) {
    _queueSub?.cancel();
    _queueSub = queueRef.snapshots().listen((snapshot) {
      final matchId = snapshot.data()?['matchId'] as String?;
      if (matchId == null) return;
      _queueSub?.cancel();
      queueRef.delete();
      _watchMatch(matchId);
      state = state.copyWith(isSearchingForMatch: false);
    });
  }

  void _watchMatch(String matchId) {
    _matchSub?.cancel();
    _matchSub =
        _firestore.collection('matches').doc(matchId).snapshots().listen((snapshot) {
      if (!snapshot.exists) return;
      state = state.copyWith(currentMatch: MultiplayerMatch.fromSnapshot(snapshot));
    });
  }

  /// Appends [move] to the match's move list and pushes the resulting turn
  /// state, so the opponent's client can replay it locally through
  /// [_watchMatch]. Called by the online game screen right after it applies
  /// the same move to its own local GameState.
  Future<void> pushMove({
    required Move move,
    required int moveCount,
    required String currentTurn,
    required double player1Pieces,
    required double player2Pieces,
  }) async {
    final match = state.currentMatch;
    if (match == null) return;

    await _firestore.collection('matches').doc(match.id).update({
      'moves': FieldValue.arrayUnion([GameNotation.moveToNotation(move)]),
      'moveCount': moveCount,
      'currentTurn': currentTurn,
      'player1Pieces': player1Pieces,
      'player2Pieces': player2Pieces,
    });
  }

  /// Pushes the live board state (whose turn, piece counts) to the match
  /// document so the opponent's client picks it up through [_watchMatch].
  Future<void> updateMatchState({
    required int moveCount,
    required String currentTurn,
    required double player1Pieces,
    required double player2Pieces,
  }) async {
    final match = state.currentMatch;
    if (match == null) return;

    await _firestore.collection('matches').doc(match.id).update({
      'moveCount': moveCount,
      'currentTurn': currentTurn,
      'player1Pieces': player1Pieces,
      'player2Pieces': player2Pieces,
    });
  }

  Future<void> endMatch({
    required String winner,
    required int winnerRatingGain,
    required int loserRatingLoss,
  }) async {
    final match = state.currentMatch;
    if (match == null) return;

    await _firestore.collection('matches').doc(match.id).update({
      'status': 'finished',
      'winner': winner,
      'winnerRatingGain': winnerRatingGain,
      'loserRatingLoss': loserRatingLoss,
      'duration': match.duration.inSeconds,
      'endedAt': Timestamp.fromDate(DateTime.now()),
    });

    _matchSub?.cancel();
    state = state.copyWith(currentMatch: null);
  }

  void exitMatch() {
    _matchSub?.cancel();
    state = state.copyWith(currentMatch: null);
  }

  void clearError() {
    state = state.copyWith(error: null);
  }

  @override
  void dispose() {
    _lobbiesSub?.cancel();
    _matchSub?.cancel();
    _queueSub?.cancel();
    _historySub?.cancel();
    _ownLobbySub?.cancel();
    super.dispose();
  }
}

/// Riverpod provider for multiplayer functionality
final multiplayerProvider =
    StateNotifierProvider<MultiplayerNotifier, MultiplayerState>(
  (ref) => MultiplayerNotifier(),
);
