import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:math' as math;

/// Tip category
enum TipCategory {
  strategy('戦略'),
  opening('序盤理論'),
  endgame('終盤テクニック'),
  tactics('戦術'),
  psychology('心理学'),
  advanced('上級テクニック');

  final String label;
  const TipCategory(this.label);
}

/// Tip difficulty
enum TipDifficulty {
  easy('かんたん'),
  normal('ふつう'),
  hard('むずかしい'),
  expert('エキスパート');

  final String label;
  const TipDifficulty(this.label);
}

/// Game tip
class GameTip {
  final String id;
  final String title;
  final String content;
  final TipCategory category;
  final TipDifficulty difficulty;
  final String source;
  final DateTime dateAdded;
  final bool isFavorite;
  final int views;
  final String? relatedConcept;

  const GameTip({
    required this.id,
    required this.title,
    required this.content,
    required this.category,
    required this.difficulty,
    required this.source,
    required this.dateAdded,
    this.isFavorite = false,
    this.views = 0,
    this.relatedConcept,
  });

  GameTip copyWith({
    String? id,
    String? title,
    String? content,
    TipCategory? category,
    TipDifficulty? difficulty,
    String? source,
    DateTime? dateAdded,
    bool? isFavorite,
    int? views,
    String? relatedConcept,
  }) {
    return GameTip(
      id: id ?? this.id,
      title: title ?? this.title,
      content: content ?? this.content,
      category: category ?? this.category,
      difficulty: difficulty ?? this.difficulty,
      source: source ?? this.source,
      dateAdded: dateAdded ?? this.dateAdded,
      isFavorite: isFavorite ?? this.isFavorite,
      views: views ?? this.views,
      relatedConcept: relatedConcept ?? this.relatedConcept,
    );
  }
}

/// Daily tips state
class DailyTipsState {
  final List<GameTip> allTips;
  final GameTip? todaysTip;
  final List<GameTip> favoriteTips;
  final List<GameTip> recentlyViewed;
  final DateTime lastUpdated;
  final int totalTipsAvailable;
  final bool isLoading;
  final String? error;

  const DailyTipsState({
    required this.allTips,
    this.todaysTip,
    required this.favoriteTips,
    required this.recentlyViewed,
    required this.lastUpdated,
    required this.totalTipsAvailable,
    this.isLoading = false,
    this.error,
  });

  DailyTipsState copyWith({
    List<GameTip>? allTips,
    GameTip? todaysTip,
    List<GameTip>? favoriteTips,
    List<GameTip>? recentlyViewed,
    DateTime? lastUpdated,
    int? totalTipsAvailable,
    bool? isLoading,
    String? error,
  }) {
    return DailyTipsState(
      allTips: allTips ?? this.allTips,
      todaysTip: todaysTip ?? this.todaysTip,
      favoriteTips: favoriteTips ?? this.favoriteTips,
      recentlyViewed: recentlyViewed ?? this.recentlyViewed,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      totalTipsAvailable: totalTipsAvailable ?? this.totalTipsAvailable,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

/// Notifier for daily tips
class DailyTipsNotifier extends StateNotifier<DailyTipsState> {
  final SharedPreferences prefs;

  DailyTipsNotifier(this.prefs)
      : super(_buildInitialState(prefs)) {
    _initializeTips();
  }

  static DailyTipsState _buildInitialState(SharedPreferences prefs) {
    return DailyTipsState(
      allTips: [],
      favoriteTips: [],
      recentlyViewed: [],
      lastUpdated: DateTime.now(),
      totalTipsAvailable: 0,
    );
  }

  void _initializeTips() {
    _generateAllTips();
    _selectTodaysTip();
    _loadFavorites();
  }

  void _generateAllTips() {
    final tips = [
      // Strategy tips
      GameTip(
        id: 'tip_1',
        title: 'コーナーの価値',
        content:
            'コーナーは最も重要な位置です。コーナーを占有すると、相手がそこから駒を返すことができません。ゲーム全体を通じてコーナーの獲得を意識しましょう。',
        category: TipCategory.strategy,
        difficulty: TipDifficulty.easy,
        source: 'オセロ基本戦略',
        dateAdded: DateTime.now().subtract(const Duration(days: 30)),
        relatedConcept: 'コーナー戦略',
      ),
      GameTip(
        id: 'tip_2',
        title: 'エッジの支配',
        content:
            'エッジ（辺）の支配はゲームの中盤から終盤にかけて重要になります。エッジを支配することで、相手の選択肢を減らすことができます。',
        category: TipCategory.strategy,
        difficulty: TipDifficulty.normal,
        source: 'リバーシ戦術ガイド',
        dateAdded: DateTime.now().subtract(const Duration(days: 25)),
        relatedConcept: 'エッジ戦略',
      ),
      GameTip(
        id: 'tip_3',
        title: 'パリティの概念',
        content:
            'パリティ（同じ色の駒を交互に配置する状態）を理解すれば、終盤での駒の支配が予測しやすくなります。特に終盤の8×8ボード全体での支配を見通す力が高まります。',
        category: TipCategory.strategy,
        difficulty: TipDifficulty.hard,
        source: '高度なリバーシ理論',
        dateAdded: DateTime.now().subtract(const Duration(days: 20)),
        relatedConcept: 'パリティ概念',
      ),
      GameTip(
        id: 'tip_4',
        title: 'モビリティの重要性',
        content:
            'モビリティ（移動できるマスの数）が多いプレイヤーが有利です。相手のモビリティを減らしながら、自分のモビリティを保つことを意識しましょう。',
        category: TipCategory.strategy,
        difficulty: TipDifficulty.normal,
        source: 'リバーシ基本戦術',
        dateAdded: DateTime.now().subtract(const Duration(days: 18)),
        relatedConcept: 'モビリティ戦略',
      ),
      // Opening theory
      GameTip(
        id: 'tip_5',
        title: '標準的な序盤展開',
        content:
            'リバーシの序盤では、初期4駒の配置から始まります。最初の数手は、相手のゲーム進行に大きな影響を与えます。基本的な序盤展開パターンを学びましょう。',
        category: TipCategory.opening,
        difficulty: TipDifficulty.easy,
        source: 'リバーシ序盤理論',
        dateAdded: DateTime.now().subtract(const Duration(days: 15)),
        relatedConcept: '標準開幕手順',
      ),
      GameTip(
        id: 'tip_6',
        title: 'ウィング開幕戦術',
        content:
            'ウィング（翼）を支配する開幕戦術は、序盤から優位性を獲得できる方法の一つです。ただし、相手の応酬に注意が必要です。',
        category: TipCategory.opening,
        difficulty: TipDifficulty.normal,
        source: 'オセロ開幕研究',
        dateAdded: DateTime.now().subtract(const Duration(days: 12)),
        relatedConcept: 'ウィング戦術',
      ),
      // Endgame techniques
      GameTip(
        id: 'tip_7',
        title: '終盤の読みの重要性',
        content:
            '終盤では、すべての可能な手の結果を読む（完全読み）ことが可能です。終盤での全手の読みに集中して、最も得な手を選択しましょう。',
        category: TipCategory.endgame,
        difficulty: TipDifficulty.hard,
        source: '終盤完全マスター',
        dateAdded: DateTime.now().subtract(const Duration(days: 10)),
        relatedConcept: '終盤読み',
      ),
      GameTip(
        id: 'tip_8',
        title: 'パスの活用',
        content:
            '相手がパス（手を打てない状況）に追い込まれると、あなたが再び手を打つ権利を得ます。パスを誘発する手を打つことは重要な戦術です。',
        category: TipCategory.endgame,
        difficulty: TipDifficulty.normal,
        source: 'リバーシ終盤戦術',
        dateAdded: DateTime.now().subtract(const Duration(days: 8)),
        relatedConcept: 'パス戦術',
      ),
      // Tactics
      GameTip(
        id: 'tip_9',
        title: 'フロンティア駒の支配',
        content:
            'フロンティア駒（相手との境界線にある駒）の支配は、ゲームの流れを左右する重要な要素です。フロンティア駒を意識的に増やしたり減らしたりすることで、ゲームをコントロールできます。',
        category: TipCategory.tactics,
        difficulty: TipDifficulty.normal,
        source: 'リバーシ戦術大全',
        dateAdded: DateTime.now().subtract(const Duration(days: 6)),
        relatedConcept: 'フロンティア駒',
      ),
      GameTip(
        id: 'tip_10',
        title: 'クイックターン戦術',
        content:
            'クイックターン（連続して相手の駒を返す）を避けることで、あなたの駒の量を保つことができます。これは中盤の重要な戦術です。',
        category: TipCategory.tactics,
        difficulty: TipDifficulty.normal,
        source: '中盤戦術入門',
        dateAdded: DateTime.now().subtract(const Duration(days: 4)),
        relatedConcept: 'ターン管理',
      ),
      // Psychology
      GameTip(
        id: 'tip_11',
        title: 'プレッシャー下での判断',
        content:
            'ゲームが進むにつれて、駒の数が減り、判断が難しくなります。プレッシャー下でも落ち着いて判断するために、事前に可能な手を計画しておくことが有効です。',
        category: TipCategory.psychology,
        difficulty: TipDifficulty.normal,
        source: 'ゲーム心理学',
        dateAdded: DateTime.now().subtract(const Duration(days: 3)),
        relatedConcept: 'メンタルトレーニング',
      ),
      GameTip(
        id: 'tip_12',
        title: 'リスク管理',
        content:
            '大きなリターンを狙うことも重要ですが、リスクをコントロールすることはさらに重要です。自分の安全な位置を確保してから、攻撃に転じましょう。',
        category: TipCategory.psychology,
        difficulty: TipDifficulty.hard,
        source: 'リバーシマスターの思考法',
        dateAdded: DateTime.now().subtract(const Duration(days: 2)),
        relatedConcept: 'リスク管理',
      ),
      // Advanced techniques
      GameTip(
        id: 'tip_13',
        title: 'テンポの支配',
        content:
            'テンポ（ゲームの流れ）を支配することで、相手に自分のペースでゲームをされます。テンポを意識して手を選択しましょう。',
        category: TipCategory.advanced,
        difficulty: TipDifficulty.expert,
        source: 'プロレベルのリバーシ',
        dateAdded: DateTime.now().subtract(const Duration(days: 1)),
        relatedConcept: 'テンポ制御',
      ),
      GameTip(
        id: 'tip_14',
        title: 'ダイナミックオプション',
        content:
            'ダイナミックなオプション（複数の勝利経路）を保つことで、相手に対する柔軟性が増します。一つの道だけに頼らないゲームプランを持つことが重要です。',
        category: TipCategory.advanced,
        difficulty: TipDifficulty.expert,
        source: 'アドバンスド戦略分析',
        dateAdded: DateTime.now(),
        relatedConcept: 'オプション保持',
      ),
      GameTip(
        id: 'tip_15',
        title: 'ポジションの評価',
        content:
            '駒の数だけでなく、その配置によって局面を正しく評価することが重要です。同じ駒数でも、配置によって価値は大きく異なります。',
        category: TipCategory.advanced,
        difficulty: TipDifficulty.hard,
        source: 'ポジション評価ガイド',
        dateAdded: DateTime.now().subtract(const Duration(days: 7)),
        relatedConcept: 'ポジション評価',
      ),
    ];

    state = state.copyWith(
      allTips: tips,
      totalTipsAvailable: tips.length,
    );
  }

  void _selectTodaysTip() {
    if (state.allTips.isEmpty) return;

    final lastUpdateStr = prefs.getString('last_tip_date');
    final today = DateTime.now();
    final todayStr = '${today.year}-${today.month}-${today.day}';

    if (lastUpdateStr == todayStr) {
      // Load today's tip from preferences
      final tipId = prefs.getString('today_tip_id');
      if (tipId != null) {
        final tip = state.allTips.firstWhere(
          (t) => t.id == tipId,
          orElse: () => state.allTips[0],
        );
        state = state.copyWith(
          todaysTip: tip.copyWith(views: tip.views + 1),
        );
        return;
      }
    }

    // Generate new tip for today
    final random = math.Random(today.millisecondsSinceEpoch ~/ 86400000);
    final selectedTip = state.allTips[random.nextInt(state.allTips.length)];

    prefs.setString('last_tip_date', todayStr);
    prefs.setString('today_tip_id', selectedTip.id);

    state = state.copyWith(
      todaysTip: selectedTip.copyWith(views: selectedTip.views + 1),
    );
  }

  void _loadFavorites() {
    final favoriteIds = prefs.getStringList('favorite_tip_ids') ?? [];
    final favorites = state.allTips
        .where((tip) => favoriteIds.contains(tip.id))
        .map((tip) => tip.copyWith(isFavorite: true))
        .toList();

    state = state.copyWith(favoriteTips: favorites);
  }

  Future<void> toggleFavorite(GameTip tip) async {
    try {
      final isFavorite = !tip.isFavorite;
      final favoriteIds = prefs.getStringList('favorite_tip_ids') ?? [];

      if (isFavorite) {
        if (!favoriteIds.contains(tip.id)) {
          favoriteIds.add(tip.id);
        }
      } else {
        favoriteIds.remove(tip.id);
      }

      await prefs.setStringList('favorite_tip_ids', favoriteIds);

      final updated = state.allTips
          .map((t) => t.id == tip.id
              ? t.copyWith(isFavorite: isFavorite)
              : t)
          .toList();

      state = state.copyWith(
        allTips: updated,
        favoriteTips: updated
            .where((t) => t.isFavorite)
            .toList(),
      );
    } catch (e) {
      state = state.copyWith(error: 'Failed to toggle favorite: $e');
    }
  }

  Future<void> markAsViewed(GameTip tip) async {
    try {
      final recentIds = prefs.getStringList('recently_viewed_tip_ids') ?? [];

      recentIds.remove(tip.id);
      recentIds.insert(0, tip.id);

      if (recentIds.length > 20) {
        recentIds.removeRange(20, recentIds.length);
      }

      await prefs.setStringList('recently_viewed_tip_ids', recentIds);

      final updated = state.allTips
          .map((t) => t.id == tip.id
              ? t.copyWith(views: t.views + 1)
              : t)
          .toList();

      final viewed = updated
          .where((t) => recentIds.contains(t.id))
          .toList();

      state = state.copyWith(
        allTips: updated,
        recentlyViewed: viewed,
      );
    } catch (e) {
      state = state.copyWith(error: 'Failed to mark as viewed: $e');
    }
  }

  List<GameTip> getTipsByCategory(TipCategory category) {
    return state.allTips
        .where((tip) => tip.category == category)
        .toList();
  }

  List<GameTip> searchTips(String query) {
    final q = query.toLowerCase();
    return state.allTips
        .where((tip) =>
            tip.title.toLowerCase().contains(q) ||
            tip.content.toLowerCase().contains(q) ||
            tip.relatedConcept?.toLowerCase().contains(q) == true)
        .toList();
  }
}

/// Riverpod provider for daily tips
final dailyTipsProvider =
    StateNotifierProvider<DailyTipsNotifier, DailyTipsState>(
  (ref) async {
    final prefs = await SharedPreferences.getInstance();
    return DailyTipsNotifier(prefs);
  },
);
