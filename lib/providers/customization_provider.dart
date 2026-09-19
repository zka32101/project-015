import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Board style customization
class BoardStyle {
  final String id;
  final String name;
  final String description;
  final Color boardColor;
  final Color gridColor;
  final Color highlightColor;
  final Color lastMoveColor;
  final String rarity;
  final bool isUnlocked;
  final int cost;

  const BoardStyle({
    required this.id,
    required this.name,
    required this.description,
    required this.boardColor,
    required this.gridColor,
    required this.highlightColor,
    required this.lastMoveColor,
    required this.rarity,
    required this.isUnlocked,
    required this.cost,
  });

  BoardStyle copyWith({
    bool? isUnlocked,
  }) {
    return BoardStyle(
      id: id,
      name: name,
      description: description,
      boardColor: boardColor,
      gridColor: gridColor,
      highlightColor: highlightColor,
      lastMoveColor: lastMoveColor,
      rarity: rarity,
      isUnlocked: isUnlocked ?? this.isUnlocked,
      cost: cost,
    );
  }
}

/// Piece style customization
class PieceStyle {
  final String id;
  final String name;
  final String description;
  final String lightPieceEmoji;
  final String darkPieceEmoji;
  final String rarity;
  final bool isUnlocked;
  final int cost;

  const PieceStyle({
    required this.id,
    required this.name,
    required this.description,
    required this.lightPieceEmoji,
    required this.darkPieceEmoji,
    required this.rarity,
    required this.isUnlocked,
    required this.cost,
  });

  PieceStyle copyWith({
    bool? isUnlocked,
  }) {
    return PieceStyle(
      id: id,
      name: name,
      description: description,
      lightPieceEmoji: lightPieceEmoji,
      darkPieceEmoji: darkPieceEmoji,
      rarity: rarity,
      isUnlocked: isUnlocked ?? this.isUnlocked,
      cost: cost,
    );
  }
}

/// Theme preset
class ThemePreset {
  final String id;
  final String name;
  final String boardStyleId;
  final String pieceStyleId;
  final bool isDefault;
  final bool isFavorite;

  const ThemePreset({
    required this.id,
    required this.name,
    required this.boardStyleId,
    required this.pieceStyleId,
    required this.isDefault,
    this.isFavorite = false,
  });

  ThemePreset copyWith({
    bool? isFavorite,
    bool? isDefault,
  }) {
    return ThemePreset(
      id: id,
      name: name,
      boardStyleId: boardStyleId,
      pieceStyleId: pieceStyleId,
      isDefault: isDefault ?? this.isDefault,
      isFavorite: isFavorite ?? this.isFavorite,
    );
  }
}

/// Customization state
class CustomizationState {
  final List<BoardStyle> boardStyles;
  final List<PieceStyle> pieceStyles;
  final List<ThemePreset> themePresets;
  final String selectedBoardStyleId;
  final String selectedPieceStyleId;
  final bool enableAnimations;
  final bool enableSoundEffects;
  final double uiScale;
  final bool darkModeEnabled;
  final bool isLoading;
  final String? error;

  const CustomizationState({
    required this.boardStyles,
    required this.pieceStyles,
    required this.themePresets,
    required this.selectedBoardStyleId,
    required this.selectedPieceStyleId,
    required this.enableAnimations,
    required this.enableSoundEffects,
    required this.uiScale,
    required this.darkModeEnabled,
    this.isLoading = false,
    this.error,
  });

  BoardStyle? get selectedBoardStyle =>
      boardStyles.firstWhere((b) => b.id == selectedBoardStyleId, orElse: () => boardStyles.first);

  PieceStyle? get selectedPieceStyle =>
      pieceStyles.firstWhere((p) => p.id == selectedPieceStyleId, orElse: () => pieceStyles.first);

  List<BoardStyle> get unlockedBoardStyles =>
      boardStyles.where((b) => b.isUnlocked).toList();

  List<PieceStyle> get unlockedPieceStyles =>
      pieceStyles.where((p) => p.isUnlocked).toList();

  List<BoardStyle> get lockedBoardStyles =>
      boardStyles.where((b) => !b.isUnlocked).toList();

  List<PieceStyle> get lockedPieceStyles =>
      pieceStyles.where((p) => !p.isUnlocked).toList();

  CustomizationState copyWith({
    List<BoardStyle>? boardStyles,
    List<PieceStyle>? pieceStyles,
    List<ThemePreset>? themePresets,
    String? selectedBoardStyleId,
    String? selectedPieceStyleId,
    bool? enableAnimations,
    bool? enableSoundEffects,
    double? uiScale,
    bool? darkModeEnabled,
    bool? isLoading,
    Object? error = _unset,
  }) {
    return CustomizationState(
      boardStyles: boardStyles ?? this.boardStyles,
      pieceStyles: pieceStyles ?? this.pieceStyles,
      themePresets: themePresets ?? this.themePresets,
      selectedBoardStyleId: selectedBoardStyleId ?? this.selectedBoardStyleId,
      selectedPieceStyleId: selectedPieceStyleId ?? this.selectedPieceStyleId,
      enableAnimations: enableAnimations ?? this.enableAnimations,
      enableSoundEffects: enableSoundEffects ?? this.enableSoundEffects,
      uiScale: uiScale ?? this.uiScale,
      darkModeEnabled: darkModeEnabled ?? this.darkModeEnabled,
      isLoading: isLoading ?? this.isLoading,
      error: identical(error, _unset) ? this.error : error as String?,
    );
  }
}

/// Sentinel used by [CustomizationState.copyWith] to distinguish "field not
/// passed" (keep current value) from "field explicitly passed as null"
/// (clear the value).
const Object _unset = Object();

/// Notifier for customization
class CustomizationNotifier extends StateNotifier<CustomizationState> {
  static final List<BoardStyle> _sampleBoardStyles = [];
  static final List<PieceStyle> _samplePieceStyles = [];
  static final List<ThemePreset> _sampleThemePresets = [];

  CustomizationNotifier()
      : super(const CustomizationState(
          boardStyles: [],
          pieceStyles: [],
          themePresets: [],
          selectedBoardStyleId: 'board_1',
          selectedPieceStyleId: 'piece_1',
          enableAnimations: true,
          enableSoundEffects: true,
          uiScale: 1.0,
          darkModeEnabled: false,
        )) {
    _initialize();
  }

  void _initialize() {
    _generateBoardStyles();
    _generatePieceStyles();
    _generateThemePresets();
  }

  void _generateBoardStyles() {
    _sampleBoardStyles.clear();
    _sampleBoardStyles.addAll([
      BoardStyle(
        id: 'board_1',
        name: 'クラシック緑',
        description: '定番の緑色ボード',
        boardColor: const Color(0xFF4CAF50),
        gridColor: const Color(0xFF2E7D32),
        highlightColor: const Color(0xFF81C784),
        lastMoveColor: const Color(0xFFF9A825),
        rarity: 'コモン',
        isUnlocked: true,
        cost: 0,
      ),
      BoardStyle(
        id: 'board_2',
        name: 'ナイトウッド',
        description: '深みのある茶色ボード',
        boardColor: const Color(0xFF6D4C41),
        gridColor: const Color(0xFF3E2723),
        highlightColor: const Color(0xFFBCAAA4),
        lastMoveColor: const Color(0xFFFFD54F),
        rarity: 'レア',
        isUnlocked: true,
        cost: 5000,
      ),
      BoardStyle(
        id: 'board_3',
        name: 'ロイヤルブルー',
        description: '高級感のある青色ボード',
        boardColor: const Color(0xFF1A237E),
        gridColor: const Color(0xFF0D47A1),
        highlightColor: const Color(0xFF3F51B5),
        lastMoveColor: const Color(0xFF00BCD4),
        rarity: 'レア',
        isUnlocked: false,
        cost: 10000,
      ),
      BoardStyle(
        id: 'board_4',
        name: 'サクラピンク',
        description: '春をイメージしたボード',
        boardColor: const Color(0xFFC2185B),
        gridColor: const Color(0xFF880E4F),
        highlightColor: const Color(0xFFE91E63),
        lastMoveColor: const Color(0xFFFFC0CB),
        rarity: 'エピック',
        isUnlocked: false,
        cost: 15000,
      ),
    ]);

    state = state.copyWith(boardStyles: List.from(_sampleBoardStyles));
  }

  void _generatePieceStyles() {
    _samplePieceStyles.clear();
    _samplePieceStyles.addAll([
      PieceStyle(
        id: 'piece_1',
        name: '標準',
        description: '円形の標準的なピース',
        lightPieceEmoji: '⚪',
        darkPieceEmoji: '⚫',
        rarity: 'コモン',
        isUnlocked: true,
        cost: 0,
      ),
      PieceStyle(
        id: 'piece_2',
        name: 'アニマル',
        description: '動物をテーマにしたピース',
        lightPieceEmoji: '🐰',
        darkPieceEmoji: '🦊',
        rarity: 'レア',
        isUnlocked: true,
        cost: 3000,
      ),
      PieceStyle(
        id: 'piece_3',
        name: 'エレメンタル',
        description: '炎と氷のピース',
        lightPieceEmoji: '❄️',
        darkPieceEmoji: '🔥',
        rarity: 'エピック',
        isUnlocked: false,
        cost: 8000,
      ),
      PieceStyle(
        id: 'piece_4',
        name: 'ムーン＆サン',
        description: '月と太陽がテーマ',
        lightPieceEmoji: '☀️',
        darkPieceEmoji: '🌙',
        rarity: 'レジェンダリー',
        isUnlocked: false,
        cost: 20000,
      ),
    ]);

    state = state.copyWith(pieceStyles: List.from(_samplePieceStyles));
  }

  void _generateThemePresets() {
    _sampleThemePresets.clear();
    _sampleThemePresets.addAll([
      ThemePreset(
        id: 'theme_1',
        name: 'クラシック',
        boardStyleId: 'board_1',
        pieceStyleId: 'piece_1',
        isDefault: true,
      ),
      ThemePreset(
        id: 'theme_2',
        name: 'ダークウッド',
        boardStyleId: 'board_2',
        pieceStyleId: 'piece_2',
        isDefault: false,
        isFavorite: true,
      ),
      ThemePreset(
        id: 'theme_3',
        name: 'アニマルパーティ',
        boardStyleId: 'board_1',
        pieceStyleId: 'piece_2',
        isDefault: false,
      ),
    ]);

    state = state.copyWith(themePresets: List.from(_sampleThemePresets));
  }

  Future<void> selectBoardStyle(String boardStyleId) async {
    final board = state.boardStyles.firstWhere((b) => b.id == boardStyleId);
    if (!board.isUnlocked) {
      state = state.copyWith(
        error: '${board.name}はまだロック解除されていません。(必要: ${board.cost}ゴールド)',
      );
      return;
    }

    state = state.copyWith(selectedBoardStyleId: boardStyleId);
  }

  Future<void> selectPieceStyle(String pieceStyleId) async {
    final piece = state.pieceStyles.firstWhere((p) => p.id == pieceStyleId);
    if (!piece.isUnlocked) {
      state = state.copyWith(
        error: '${piece.name}はまだロック解除されていません。(必要: ${piece.cost}ゴールド)',
      );
      return;
    }

    state = state.copyWith(selectedPieceStyleId: pieceStyleId);
  }

  Future<void> unlockBoardStyle(String boardStyleId) async {
    state = state.copyWith(isLoading: true);
    await Future.delayed(const Duration(milliseconds: 800));

    final updated = state.boardStyles.map((b) {
      if (b.id == boardStyleId) {
        return b.copyWith(isUnlocked: true);
      }
      return b;
    }).toList();

    state = state.copyWith(
      boardStyles: updated,
      isLoading: false,
      error: null,
    );
  }

  Future<void> unlockPieceStyle(String pieceStyleId) async {
    state = state.copyWith(isLoading: true);
    await Future.delayed(const Duration(milliseconds: 800));

    final updated = state.pieceStyles.map((p) {
      if (p.id == pieceStyleId) {
        return p.copyWith(isUnlocked: true);
      }
      return p;
    }).toList();

    state = state.copyWith(
      pieceStyles: updated,
      isLoading: false,
      error: null,
    );
  }

  void toggleAnimations() {
    state = state.copyWith(enableAnimations: !state.enableAnimations);
  }

  void toggleSoundEffects() {
    state = state.copyWith(enableSoundEffects: !state.enableSoundEffects);
  }

  void toggleDarkMode() {
    state = state.copyWith(darkModeEnabled: !state.darkModeEnabled);
  }

  void setUIScale(double scale) {
    state = state.copyWith(uiScale: scale);
  }

  Future<void> applyThemePreset(String themeId) async {
    final theme = state.themePresets.firstWhere((t) => t.id == themeId);
    state = state.copyWith(
      selectedBoardStyleId: theme.boardStyleId,
      selectedPieceStyleId: theme.pieceStyleId,
    );
  }

  void clearError() {
    state = state.copyWith(error: null);
  }
}

/// Riverpod provider for customization
final customizationProvider =
    StateNotifierProvider<CustomizationNotifier, CustomizationState>(
  (ref) => CustomizationNotifier(),
);
