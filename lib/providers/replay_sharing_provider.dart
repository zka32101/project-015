import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Shared game replay information
class SharedReplay {
  final String id;
  final String authorName;
  final String authorAvatarEmoji;
  final String gameTitle;
  final String description;
  final int moveCount;
  final String winner;
  final String difficulty;
  final String shareUrl;
  final DateTime sharedAt;
  final int viewCount;
  final int likeCount;
  final int commentCount;

  const SharedReplay({
    required this.id,
    required this.authorName,
    required this.authorAvatarEmoji,
    required this.gameTitle,
    required this.description,
    required this.moveCount,
    required this.winner,
    required this.difficulty,
    required this.shareUrl,
    required this.sharedAt,
    required this.viewCount,
    required this.likeCount,
    required this.commentCount,
  });

  Duration get ageInDays => DateTime.now().difference(sharedAt);

  SharedReplay copyWith({
    int? viewCount,
    int? likeCount,
    int? commentCount,
  }) {
    return SharedReplay(
      id: id,
      authorName: authorName,
      authorAvatarEmoji: authorAvatarEmoji,
      gameTitle: gameTitle,
      description: description,
      moveCount: moveCount,
      winner: winner,
      difficulty: difficulty,
      shareUrl: shareUrl,
      sharedAt: sharedAt,
      viewCount: viewCount ?? this.viewCount,
      likeCount: likeCount ?? this.likeCount,
      commentCount: commentCount ?? this.commentCount,
    );
  }
}

/// Comment on a shared replay
class ReplayComment {
  final String id;
  final String authorName;
  final String authorAvatarEmoji;
  final String text;
  final DateTime postedAt;
  final int likes;

  const ReplayComment({
    required this.id,
    required this.authorName,
    required this.authorAvatarEmoji,
    required this.text,
    required this.postedAt,
    required this.likes,
  });

  ReplayComment copyWith({
    int? likes,
  }) {
    return ReplayComment(
      id: id,
      authorName: authorName,
      authorAvatarEmoji: authorAvatarEmoji,
      text: text,
      postedAt: postedAt,
      likes: likes ?? this.likes,
    );
  }
}

/// Replay sharing state
class ReplaySharingState {
  final List<SharedReplay> sharedReplays;
  final List<SharedReplay> mySharedReplays;
  final List<SharedReplay> favorites;
  final bool isLoading;
  final String? error;

  const ReplaySharingState({
    required this.sharedReplays,
    required this.mySharedReplays,
    required this.favorites,
    this.isLoading = false,
    this.error,
  });

  ReplaySharingState copyWith({
    List<SharedReplay>? sharedReplays,
    List<SharedReplay>? mySharedReplays,
    List<SharedReplay>? favorites,
    bool? isLoading,
    String? error,
  }) {
    return ReplaySharingState(
      sharedReplays: sharedReplays ?? this.sharedReplays,
      mySharedReplays: mySharedReplays ?? this.mySharedReplays,
      favorites: favorites ?? this.favorites,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

/// Notifier for replay sharing and social features
class ReplaySharingNotifier extends StateNotifier<ReplaySharingState> {
  static final List<SharedReplay> _sampleSharedReplays = [];
  static final List<SharedReplay> _sampleMyReplays = [];

  ReplaySharingNotifier()
      : super(const ReplaySharingState(
          sharedReplays: [],
          mySharedReplays: [],
          favorites: [],
        )) {
    _initialize();
  }

  void _initialize() {
    _generateSampleReplays();
    _generateMyReplays();
  }

  void _generateSampleReplays() {
    final now = DateTime.now();
    _sampleSharedReplays.clear();
    _sampleSharedReplays.addAll([
      SharedReplay(
        id: 'replay_1',
        authorName: 'エリート太郎',
        authorAvatarEmoji: '🦅',
        gameTitle: 'AI(つよい)との激戦',
        description: '最後の一手で逆転勝利を収めた興奮の対局。相手の隙を見逃さず決めた。',
        moveCount: 58,
        winner: 'エリート太郎',
        difficulty: 'つよい',
        shareUrl: 'reversia://share/replay_1',
        sharedAt: now.subtract(const Duration(days: 2)),
        viewCount: 234,
        likeCount: 45,
        commentCount: 8,
      ),
      SharedReplay(
        id: 'replay_2',
        authorName: 'リバーシ花子',
        authorAvatarEmoji: '🌸',
        gameTitle: 'ふつうモード完全制覇',
        description: 'AIふつうを完全制覇。布石から終盤までの完璧な一局。',
        moveCount: 52,
        winner: 'リバーシ花子',
        difficulty: 'ふつう',
        shareUrl: 'reversia://share/replay_2',
        sharedAt: now.subtract(const Duration(days: 5)),
        viewCount: 456,
        likeCount: 78,
        commentCount: 15,
      ),
      SharedReplay(
        id: 'replay_3',
        authorName: '勝利の戦士',
        authorAvatarEmoji: '⚔️',
        gameTitle: '究極の逆転ドラマ',
        description: '終盤一手差からの大逆転。相手のミスを完璧に活かした一局。',
        moveCount: 60,
        winner: '勝利の戦士',
        difficulty: 'つよい',
        shareUrl: 'reversia://share/replay_3',
        sharedAt: now.subtract(const Duration(days: 1)),
        viewCount: 789,
        likeCount: 156,
        commentCount: 32,
      ),
      SharedReplay(
        id: 'replay_4',
        authorName: 'スーパー次郎',
        authorAvatarEmoji: '🌟',
        gameTitle: '珍しい局面の研究解析',
        description: '稀見の展開。この局面の正着は何か、皆の意見をお待ちします。',
        moveCount: 45,
        winner: 'スーパー次郎',
        difficulty: 'ふつう',
        shareUrl: 'reversia://share/replay_4',
        sharedAt: now.subtract(const Duration(hours: 8)),
        viewCount: 123,
        likeCount: 34,
        commentCount: 12,
      ),
    ]);

    state = state.copyWith(sharedReplays: List.from(_sampleSharedReplays));
  }

  void _generateMyReplays() {
    final now = DateTime.now();
    _sampleMyReplays.clear();
    _sampleMyReplays.addAll([
      SharedReplay(
        id: 'my_replay_1',
        authorName: 'あなた',
        authorAvatarEmoji: '🎮',
        gameTitle: '今日の一局',
        description: '今日のベストマッチ。終盤の読みが冴えた。',
        moveCount: 54,
        winner: 'あなた',
        difficulty: 'つよい',
        shareUrl: 'reversia://share/my_replay_1',
        sharedAt: now.subtract(const Duration(hours: 2)),
        viewCount: 12,
        likeCount: 3,
        commentCount: 1,
      ),
      SharedReplay(
        id: 'my_replay_2',
        authorName: 'あなた',
        authorAvatarEmoji: '🎮',
        gameTitle: 'AIふつう を 45手で勝利',
        description: '素早い攻撃で相手を圧倒。',
        moveCount: 45,
        winner: 'あなた',
        difficulty: 'ふつう',
        shareUrl: 'reversia://share/my_replay_2',
        sharedAt: now.subtract(const Duration(days: 1)),
        viewCount: 28,
        likeCount: 7,
        commentCount: 2,
      ),
    ]);

    state = state.copyWith(mySharedReplays: List.from(_sampleMyReplays));
  }

  Future<void> shareReplay({
    required String gameTitle,
    required String description,
    required int moveCount,
    required String winner,
    required String difficulty,
  }) async {
    state = state.copyWith(isLoading: true);
    await Future.delayed(const Duration(milliseconds: 800));

    final now = DateTime.now();
    final newReplay = SharedReplay(
      id: 'my_replay_${DateTime.now().millisecondsSinceEpoch}',
      authorName: 'あなた',
      authorAvatarEmoji: '🎮',
      gameTitle: gameTitle,
      description: description,
      moveCount: moveCount,
      winner: winner,
      difficulty: difficulty,
      shareUrl: 'reversia://share/${DateTime.now().millisecondsSinceEpoch}',
      sharedAt: now,
      viewCount: 0,
      likeCount: 0,
      commentCount: 0,
    );

    final updatedMyReplays = [newReplay, ...state.mySharedReplays];
    state = state.copyWith(
      mySharedReplays: updatedMyReplays,
      isLoading: false,
      error: null,
    );
  }

  Future<void> likeReplay(String replayId) async {
    final updatedReplays = state.sharedReplays.map((r) {
      if (r.id == replayId) {
        return r.copyWith(likeCount: r.likeCount + 1);
      }
      return r;
    }).toList();

    state = state.copyWith(sharedReplays: updatedReplays);
  }

  Future<void> unlikeReplay(String replayId) async {
    final updatedReplays = state.sharedReplays.map((r) {
      if (r.id == replayId) {
        return r.copyWith(likeCount: (r.likeCount - 1).clamp(0, 999));
      }
      return r;
    }).toList();

    state = state.copyWith(sharedReplays: updatedReplays);
  }

  Future<void> addToFavorites(SharedReplay replay) async {
    if (state.favorites.any((f) => f.id == replay.id)) {
      return;
    }
    final updated = [replay, ...state.favorites];
    state = state.copyWith(favorites: updated);
  }

  Future<void> removeFromFavorites(String replayId) async {
    final updated = state.favorites.where((f) => f.id != replayId).toList();
    state = state.copyWith(favorites: updated);
  }

  Future<void> addComment(
    String replayId,
    String comment,
  ) async {
    final updatedReplays = state.sharedReplays.map((r) {
      if (r.id == replayId) {
        return r.copyWith(commentCount: r.commentCount + 1);
      }
      return r;
    }).toList();

    state = state.copyWith(sharedReplays: updatedReplays);
  }

  Future<void> loadMoreReplays() async {
    state = state.copyWith(isLoading: true);
    await Future.delayed(const Duration(milliseconds: 600));

    final now = DateTime.now();
    final oldCount = state.sharedReplays.length;

    // Simulate loading more replays
    final moreReplays = [
      SharedReplay(
        id: 'replay_${oldCount + 1}',
        authorName: 'リバーシマスター',
        authorAvatarEmoji: '👑',
        gameTitle: 'マスターの一局',
        description: 'エキスパート級の完璧な一局。学べる部分が多いです。',
        moveCount: 58,
        winner: 'リバーシマスター',
        difficulty: 'つよい',
        shareUrl: 'reversia://share/replay_${oldCount + 1}',
        sharedAt: now.subtract(const Duration(days: 3)),
        viewCount: 567,
        likeCount: 98,
        commentCount: 25,
      ),
    ];

    final updated = [...state.sharedReplays, ...moreReplays];
    state = state.copyWith(
      sharedReplays: updated,
      isLoading: false,
      error: null,
    );
  }

  void clearError() {
    state = state.copyWith(error: null);
  }
}

/// Riverpod provider for replay sharing
final replaySharingProvider =
    StateNotifierProvider<ReplaySharingNotifier, ReplaySharingState>(
  (ref) => ReplaySharingNotifier(),
);
