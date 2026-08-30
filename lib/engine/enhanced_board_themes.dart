import 'package:flutter/material.dart';
import 'board_theme.dart';

/// Extended board themes with enhanced visuals
class EnhancedBoardThemes {
  // Moonlight theme - cool blues and silvers
  static final moonlight = BoardTheme(
    label: '月光',
    woodDark: const Color(0xFF1a2332),
    woodLight: const Color(0xFF2d3e50),
    woodTextureAsset: 'assets/board/wood_dark.png',
    frontPieceColor: const Color(0xFFb0d4ff), // light blue
    backPieceColor: const Color(0xFFff9ebc), // light pink
    accentGold: const Color(0xFFe8d4b0),
    screenBackground: const Color(0xFF0f1419),
  );

  // Sunset theme - warm oranges and reds
  static final sunset = BoardTheme(
    label: '夕焼け',
    woodDark: const Color(0xFF3d2a1f),
    woodLight: const Color(0xFF5c4033),
    woodTextureAsset: 'assets/board/wood_warm.png',
    frontPieceColor: const Color(0xFFffd89b), // warm yellow
    backPieceColor: const Color(0xFFff6b6b), // coral red
    accentGold: const Color(0xFFffb84d),
    screenBackground: const Color(0xFF2a1a0e),
  );

  // Forest theme - deep greens
  static final forest = BoardTheme(
    label: '深緑',
    woodDark: const Color(0xFF1b3d2f),
    woodLight: const Color(0xFF2d5a47),
    woodTextureAsset: 'assets/board/wood_dark.png',
    frontPieceColor: const Color(0xFFc8e6c9), // light green
    backPieceColor: const Color(0xFFffe0b2), // warm beige
    accentGold: const Color(0xFFb4e7b4),
    screenBackground: const Color(0xFF0d2417),
  );

  // Midnight theme - dark purples and blues
  static final midnight = BoardTheme(
    label: '深夜',
    woodDark: const Color(0xFF1a0f2e),
    woodLight: const Color(0xFF2d1b4e),
    woodTextureAsset: 'assets/board/wood_dark.png',
    frontPieceColor: const Color(0xFFb19cd9), // light purple
    backPieceColor: const Color(0xFF81c5d8), // light cyan
    accentGold: const Color(0xFFe6b800),
    screenBackground: const Color(0xFF0a0515),
  );

  // Cherry blossom theme - soft pinks and whites
  static final cherryBlossom = BoardTheme(
    label: '桜',
    woodDark: const Color(0xFF3d2a2f),
    woodLight: const Color(0xFF5c4047),
    woodTextureAsset: 'assets/board/wood_warm.png',
    frontPieceColor: const Color(0xFFffc0d9), // soft pink
    backPieceColor: const Color(0xFFffd7e8), // lighter pink
    accentGold: const Color(0xFFffe5ec),
    screenBackground: const Color(0xFF2a1a1f),
  );

  // Ocean theme - deep blues and teals
  static final ocean = BoardTheme(
    label: '大洋',
    woodDark: const Color(0xFF0d3b66),
    woodLight: const Color(0xFF1b5a96),
    woodTextureAsset: 'assets/board/wood_dark.png',
    frontPieceColor: const Color(0xFF6dceef), // light cyan
    backPieceColor: const Color(0xFFffa630), // warm orange
    accentGold: const Color(0xFFf4d35e),
    screenBackground: const Color(0xFF052d4a),
  );

  // Autumn theme - warm browns and reds
  static final autumn = BoardTheme(
    label: '秋',
    woodDark: const Color(0xFF4a2c2a),
    woodLight: const Color(0xFF6b4423),
    woodTextureAsset: 'assets/board/wood_warm.png',
    frontPieceColor: const Color(0xFFf4a261), // burnt orange
    backPieceColor: const Color(0xFFe76f51), // rust
    accentGold: const Color(0xFFf4d35e),
    screenBackground: const Color(0xFF2a1810),
  );

  // Spring theme - soft greens and pinks
  static final spring = BoardTheme(
    label: '春',
    woodDark: const Color(0xFF3a4a3f),
    woodLight: const Color(0xFF5a6d61),
    woodTextureAsset: 'assets/board/wood_dark.png',
    frontPieceColor: const Color(0xFFb4e8b9), // soft mint
    backPieceColor: const Color(0xFFfdcab9), // peach
    accentGold: const Color(0xFFf4d4a8),
    screenBackground: const Color(0xFF1a2a1f),
  );

  // Modern theme - sleek grays and blues
  static final modern = BoardTheme(
    label: 'モダン',
    woodDark: const Color(0xFF2a3a47),
    woodLight: const Color(0xFF3d4f66),
    woodTextureAsset: 'assets/board/wood_dark.png',
    frontPieceColor: const Color(0xFF4ea8de), // modern blue
    backPieceColor: const Color(0xFFf72585), // modern pink
    accentGold: const Color(0xFF00d9ff),
    screenBackground: const Color(0xFF1a252f),
  );

  // Retro theme - vintage colors
  static final retro = BoardTheme(
    label: 'レトロ',
    woodDark: const Color(0xFF5c6e59),
    woodLight: const Color(0xFF7a8d73),
    woodTextureAsset: 'assets/board/wood_dark.png',
    frontPieceColor: const Color(0xFFd4a574), // vintage tan
    backPieceColor: const Color(0xFFb4846d), // vintage brown
    accentGold: const Color(0xFfdcaa5c),
    screenBackground: const Color(0xFF3a4937),
  );

  static List<BoardTheme> getAll() => [
    // Original theme
    const BoardTheme(
      label: '標準',
      woodDark: Color(0xFF3e2723),
      woodLight: Color(0xFF5d4037),
      woodTextureAsset: 'assets/board/wood_dark.png',
      frontPieceColor: Color(0xFF42a5f5),
      backPieceColor: Color(0xFFef5350),
      accentGold: Color(0xFFffd700),
      screenBackground: Color(0xFF1a1a1a),
    ),
    // Enhanced themes
    moonlight,
    sunset,
    forest,
    midnight,
    cherryBlossom,
    ocean,
    autumn,
    spring,
    modern,
    retro,
  ];
}

/// High contrast theme for accessibility
class HighContrastBoardTheme extends BoardTheme {
  HighContrastBoardTheme()
      : super(
          label: 'ハイコントラスト',
          woodDark: const Color(0xFF000000),
          woodLight: const Color(0xFF333333),
          woodTextureAsset: 'assets/board/wood_dark.png',
          frontPieceColor: const Color(0xFFffff00), // bright yellow
          backPieceColor: const Color(0xFF00ffff), // bright cyan
          accentGold: const Color(0xFFffffff),
          screenBackground: const Color(0xFF000000),
        );
}

/// Theme animation provider for smooth transitions
class ThemeTransition {
  final BoardTheme from;
  final BoardTheme to;
  final double progress;

  ThemeTransition({
    required this.from,
    required this.to,
    required this.progress,
  });

  /// Interpolate color between two themes
  Color _interpolateColor(Color c1, Color c2, double t) {
    return Color.lerp(c1, c2, t) ?? c1;
  }

  /// Get interpolated theme at current progress
  BoardTheme getInterpolated() {
    return BoardTheme(
      label: from.label,
      woodDark: _interpolateColor(from.woodDark, to.woodDark, progress),
      woodLight: _interpolateColor(from.woodLight, to.woodLight, progress),
      woodTextureAsset: progress < 0.5 ? from.woodTextureAsset : to.woodTextureAsset,
      frontPieceColor:
          _interpolateColor(from.frontPieceColor, to.frontPieceColor, progress),
      backPieceColor: _interpolateColor(from.backPieceColor, to.backPieceColor, progress),
      accentGold: _interpolateColor(from.accentGold, to.accentGold, progress),
      screenBackground:
          _interpolateColor(from.screenBackground, to.screenBackground, progress),
    );
  }
}
