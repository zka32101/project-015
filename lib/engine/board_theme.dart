import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'models.dart';

/// AI-generated lacquered-disc artwork (assets/images/piece_*.png). The same
/// three source images are re-tinted per board theme via BlendMode.color
/// (see callers) so one asset set adapts to whichever palette is selected.
String pieceAssetFor(PieceType type, Face face) {
  if (type == PieceType.king) return 'assets/images/piece_king.png';
  return face == Face.front ? 'assets/images/piece_front.png' : 'assets/images/piece_back.png';
}

/// Selectable board/piece color themes (design doc Section3 Could
/// "盤テーマ変更"). Colors are grouped so the whole GameScreen can swap
/// palette in one place instead of scattered hardcoded constants.
class BoardTheme {
  final String id;
  final String label;
  final Color woodLight;
  final Color woodDark;
  final Color frontPieceColor; // 表
  final Color backPieceColor; // 裏
  final Color accentGold;
  final Color screenBackground;
  final String woodTextureAsset;

  const BoardTheme({
    required this.id,
    required this.label,
    required this.woodLight,
    required this.woodDark,
    required this.frontPieceColor,
    required this.backPieceColor,
    required this.accentGold,
    required this.screenBackground,
    required this.woodTextureAsset,
  });
}

/// Default: 和モダン（墨×金）Section10 baseline palette.
const wamodernTheme = BoardTheme(
  id: 'wamodern',
  label: '和モダン（墨×金）',
  woodLight: Color(0xFF8D6E52),
  woodDark: Color(0xFF6B4F3B),
  frontPieceColor: Color(0xFF2E3A59),
  backPieceColor: Color(0xFFC0392B),
  accentGold: Color(0xFFD4AF37),
  screenBackground: Color(0xFF3E2E22),
  woodTextureAsset: 'assets/images/board_wood_wamodern.png',
);

/// 深緑（竹林）-- a cooler, greener alternative.
const bambooTheme = BoardTheme(
  id: 'bamboo',
  label: '深緑（竹林）',
  woodLight: Color(0xFF5B7553),
  woodDark: Color(0xFF3E5240),
  frontPieceColor: Color(0xFF1F3A2E),
  backPieceColor: Color(0xFFB5651D),
  accentGold: Color(0xFFD9C36A),
  screenBackground: Color(0xFF23301F),
  woodTextureAsset: 'assets/images/board_wood_bamboo.png',
);

/// 藍雪（雪原）-- a colder indigo/silver palette.
const snowIndigoTheme = BoardTheme(
  id: 'snow_indigo',
  label: '藍雪（雪原）',
  woodLight: Color(0xFF5A6B7A),
  woodDark: Color(0xFF3E4C59),
  frontPieceColor: Color(0xFF1B2A4A),
  backPieceColor: Color(0xFF8E1F3B),
  accentGold: Color(0xFFC7D3DD),
  screenBackground: Color(0xFF232C36),
  woodTextureAsset: 'assets/images/board_wood_snow.png',
);

const List<BoardTheme> boardThemes = [wamodernTheme, bambooTheme, snowIndigoTheme];

BoardTheme boardThemeById(String? id) =>
    boardThemes.firstWhere((t) => t.id == id, orElse: () => wamodernTheme);

const boardThemePrefsKey = 'board_theme_id';

class BoardThemeNotifier extends Notifier<BoardTheme> {
  @override
  BoardTheme build() {
    _load();
    return wamodernTheme;
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final id = prefs.getString(boardThemePrefsKey);
    if (id != null) state = boardThemeById(id);
  }

  void setTheme(BoardTheme theme) {
    state = theme;
    SharedPreferences.getInstance().then((prefs) {
      prefs.setString(boardThemePrefsKey, theme.id);
    });
  }
}

final boardThemeProvider = NotifierProvider<BoardThemeNotifier, BoardTheme>(
  BoardThemeNotifier.new,
);
