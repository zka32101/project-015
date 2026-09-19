import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Avatar category
enum AvatarCategory {
  classic('クラシック'),
  seasonal('シーズナル'),
  legendary('レジェンダリー'),
  event('イベント');

  final String label;
  const AvatarCategory(this.label);
}

/// Cosmetic item type
enum CosmeticType {
  frame('フレーム'),
  border('ボーダー'),
  background('背景'),
  particle('パーティクル');

  final String label;
  const CosmeticType(this.label);
}

/// Avatar cosmetic
class CosmeticItem {
  final String id;
  final String name;
  final String emoji;
  final CosmeticType type;
  final int rarity; // 1-5
  final bool isUnlocked;
  final DateTime? unlockedDate;
  final String? description;

  const CosmeticItem({
    required this.id,
    required this.name,
    required this.emoji,
    required this.type,
    required this.rarity,
    this.isUnlocked = false,
    this.unlockedDate,
    this.description,
  });

  CosmeticItem copyWith({
    String? id,
    String? name,
    String? emoji,
    CosmeticType? type,
    int? rarity,
    bool? isUnlocked,
    DateTime? unlockedDate,
    String? description,
  }) {
    return CosmeticItem(
      id: id ?? this.id,
      name: name ?? this.name,
      emoji: emoji ?? this.emoji,
      type: type ?? this.type,
      rarity: rarity ?? this.rarity,
      isUnlocked: isUnlocked ?? this.isUnlocked,
      unlockedDate: unlockedDate ?? this.unlockedDate,
      description: description ?? this.description,
    );
  }
}

/// Avatar profile
class Avatar {
  final String id;
  final String name;
  final String emoji;
  final AvatarCategory category;
  final int rarity; // 1-5
  final bool isUnlocked;
  final DateTime? unlockedDate;
  final bool isEquipped;
  final List<String> equippedCosmetics; // List of cosmetic IDs

  const Avatar({
    required this.id,
    required this.name,
    required this.emoji,
    required this.category,
    required this.rarity,
    this.isUnlocked = false,
    this.unlockedDate,
    this.isEquipped = false,
    this.equippedCosmetics = const [],
  });

  Avatar copyWith({
    String? id,
    String? name,
    String? emoji,
    AvatarCategory? category,
    int? rarity,
    bool? isUnlocked,
    DateTime? unlockedDate,
    bool? isEquipped,
    List<String>? equippedCosmetics,
  }) {
    return Avatar(
      id: id ?? this.id,
      name: name ?? this.name,
      emoji: emoji ?? this.emoji,
      category: category ?? this.category,
      rarity: rarity ?? this.rarity,
      isUnlocked: isUnlocked ?? this.isUnlocked,
      unlockedDate: unlockedDate ?? this.unlockedDate,
      isEquipped: isEquipped ?? this.isEquipped,
      equippedCosmetics: equippedCosmetics ?? this.equippedCosmetics,
    );
  }
}

/// Avatars state
class AvatarsState {
  final List<Avatar> availableAvatars;
  final List<CosmeticItem> availableCosmetics;
  final Avatar? selectedAvatar;
  final int totalAvatarsUnlocked;
  final int totalCosmeticsUnlocked;
  final bool isLoading;
  final String? error;

  const AvatarsState({
    required this.availableAvatars,
    required this.availableCosmetics,
    this.selectedAvatar,
    this.totalAvatarsUnlocked = 0,
    this.totalCosmeticsUnlocked = 0,
    this.isLoading = false,
    this.error,
  });

  AvatarsState copyWith({
    List<Avatar>? availableAvatars,
    List<CosmeticItem>? availableCosmetics,
    Avatar? selectedAvatar,
    int? totalAvatarsUnlocked,
    int? totalCosmeticsUnlocked,
    bool? isLoading,
    String? error,
  }) {
    return AvatarsState(
      availableAvatars: availableAvatars ?? this.availableAvatars,
      availableCosmetics: availableCosmetics ?? this.availableCosmetics,
      selectedAvatar: selectedAvatar ?? this.selectedAvatar,
      totalAvatarsUnlocked: totalAvatarsUnlocked ?? this.totalAvatarsUnlocked,
      totalCosmeticsUnlocked:
          totalCosmeticsUnlocked ?? this.totalCosmeticsUnlocked,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

/// Notifier for avatars
class AvatarsNotifier extends StateNotifier<AvatarsState> {
  SharedPreferences? _prefs;

  AvatarsNotifier() : super(_buildInitialState()) {
    _initializeAvatars();
  }

  static AvatarsState _buildInitialState() {
    return const AvatarsState(
      availableAvatars: [],
      availableCosmetics: [],
      totalAvatarsUnlocked: 1,
      totalCosmeticsUnlocked: 0,
    );
  }

  Future<void> _initializeAvatars() async {
    final prefs = await SharedPreferences.getInstance();
    _prefs = prefs;

    state = state.copyWith(
      totalAvatarsUnlocked: prefs.getInt('total_avatars_unlocked') ?? 1,
      totalCosmeticsUnlocked: prefs.getInt('total_cosmetics_unlocked') ?? 0,
    );

    _generateAvatars(prefs);
    _generateCosmetics();
    _loadEquippedAvatar(prefs);
  }

  void _generateAvatars(SharedPreferences prefs) {
    final avatars = [
      // Classic avatars
      Avatar(
        id: 'avatar_classic_1',
        name: 'シンプルペンギン',
        emoji: '🐧',
        category: AvatarCategory.classic,
        rarity: 1,
        isUnlocked: true,
        unlockedDate: DateTime.now(),
        isEquipped: true,
      ),
      Avatar(
        id: 'avatar_classic_2',
        name: 'スマイルクマ',
        emoji: '🐻',
        category: AvatarCategory.classic,
        rarity: 1,
        isUnlocked: true,
        unlockedDate: DateTime.now().subtract(const Duration(days: 7)),
      ),
      Avatar(
        id: 'avatar_classic_3',
        name: 'クールライオン',
        emoji: '🦁',
        category: AvatarCategory.classic,
        rarity: 2,
        isUnlocked: true,
        unlockedDate: DateTime.now().subtract(const Duration(days: 3)),
      ),
      Avatar(
        id: 'avatar_classic_4',
        name: 'ロイヤルイーグル',
        emoji: '🦅',
        category: AvatarCategory.classic,
        rarity: 2,
      ),
      Avatar(
        id: 'avatar_classic_5',
        name: 'ミステリーフォックス',
        emoji: '🦊',
        category: AvatarCategory.classic,
        rarity: 3,
      ),
      // Seasonal avatars
      Avatar(
        id: 'avatar_seasonal_1',
        name: 'サマースター',
        emoji: '⭐',
        category: AvatarCategory.seasonal,
        rarity: 2,
        isUnlocked: true,
        unlockedDate: DateTime.now().subtract(const Duration(days: 30)),
      ),
      Avatar(
        id: 'avatar_seasonal_2',
        name: 'オータムムーン',
        emoji: '🌙',
        category: AvatarCategory.seasonal,
        rarity: 3,
      ),
      Avatar(
        id: 'avatar_seasonal_3',
        name: 'ウィンタースノー',
        emoji: '❄️',
        category: AvatarCategory.seasonal,
        rarity: 3,
      ),
      // Legendary avatars
      Avatar(
        id: 'avatar_legendary_1',
        name: 'ドラゴン皇帝',
        emoji: '🐉',
        category: AvatarCategory.legendary,
        rarity: 5,
      ),
      Avatar(
        id: 'avatar_legendary_2',
        name: 'フェニックスファイア',
        emoji: '🔥',
        category: AvatarCategory.legendary,
        rarity: 5,
      ),
      // Event avatars
      Avatar(
        id: 'avatar_event_1',
        name: 'ハロウィンパンプキン',
        emoji: '🎃',
        category: AvatarCategory.event,
        rarity: 2,
      ),
      Avatar(
        id: 'avatar_event_2',
        name: 'クリスマスサンタ',
        emoji: '🎅',
        category: AvatarCategory.event,
        rarity: 2,
      ),
    ];

    final selectedId = prefs.getString('selected_avatar_id') ?? 'avatar_classic_1';
    final equipped = avatars.firstWhere(
      (a) => a.id == selectedId,
      orElse: () => avatars[0],
    );

    state = state.copyWith(
      availableAvatars: avatars,
      selectedAvatar: equipped,
      totalAvatarsUnlocked: avatars.where((a) => a.isUnlocked).length,
    );
  }

  void _generateCosmetics() {
    final cosmetics = [
      // Frames
      CosmeticItem(
        id: 'cosmetic_frame_1',
        name: 'ゴールドフレーム',
        emoji: '🟨',
        type: CosmeticType.frame,
        rarity: 2,
        isUnlocked: true,
        unlockedDate: DateTime.now(),
        description: 'クラシックなゴールドフレーム',
      ),
      CosmeticItem(
        id: 'cosmetic_frame_2',
        name: 'ダイヤモンドフレーム',
        emoji: '💎',
        type: CosmeticType.frame,
        rarity: 4,
        description: 'きらめくダイヤモンドフレーム',
      ),
      CosmeticItem(
        id: 'cosmetic_frame_3',
        name: 'レインボーフレーム',
        emoji: '🌈',
        type: CosmeticType.frame,
        rarity: 3,
      ),
      // Borders
      CosmeticItem(
        id: 'cosmetic_border_1',
        name: 'ファイアボーダー',
        emoji: '🔥',
        type: CosmeticType.border,
        rarity: 3,
        description: '炎が揺らぐボーダー',
      ),
      CosmeticItem(
        id: 'cosmetic_border_2',
        name: 'アイスボーダー',
        emoji: '❄️',
        type: CosmeticType.border,
        rarity: 3,
      ),
      CosmeticItem(
        id: 'cosmetic_border_3',
        name: 'ライトニングボーダー',
        emoji: '⚡',
        type: CosmeticType.border,
        rarity: 4,
        isUnlocked: true,
        unlockedDate: DateTime.now().subtract(const Duration(days: 5)),
      ),
      // Backgrounds
      CosmeticItem(
        id: 'cosmetic_bg_1',
        name: 'スターリー背景',
        emoji: '✨',
        type: CosmeticType.background,
        rarity: 2,
        isUnlocked: true,
        unlockedDate: DateTime.now().subtract(const Duration(days: 10)),
      ),
      CosmeticItem(
        id: 'cosmetic_bg_2',
        name: 'ムーンライト背景',
        emoji: '🌙',
        type: CosmeticType.background,
        rarity: 3,
      ),
      CosmeticItem(
        id: 'cosmetic_bg_3',
        name: 'グラデーション背景',
        emoji: '🎨',
        type: CosmeticType.background,
        rarity: 4,
      ),
      // Particles
      CosmeticItem(
        id: 'cosmetic_particle_1',
        name: 'スターパーティクル',
        emoji: '⭐',
        type: CosmeticType.particle,
        rarity: 2,
        isUnlocked: true,
        unlockedDate: DateTime.now(),
      ),
      CosmeticItem(
        id: 'cosmetic_particle_2',
        name: 'ハートパーティクル',
        emoji: '💖',
        type: CosmeticType.particle,
        rarity: 3,
      ),
      CosmeticItem(
        id: 'cosmetic_particle_3',
        name: 'サクラパーティクル',
        emoji: '🌸',
        type: CosmeticType.particle,
        rarity: 3,
      ),
    ];

    state = state.copyWith(
      availableCosmetics: cosmetics,
      totalCosmeticsUnlocked: cosmetics.where((c) => c.isUnlocked).length,
    );
  }

  void _loadEquippedAvatar(SharedPreferences prefs) {
    final selectedId = prefs.getString('selected_avatar_id');
    if (selectedId != null) {
      final avatar = state.availableAvatars.firstWhere(
        (a) => a.id == selectedId,
        orElse: () => state.availableAvatars[0],
      );
      state = state.copyWith(selectedAvatar: avatar);
    }
  }

  Future<void> equipAvatar(Avatar avatar) async {
    if (!avatar.isUnlocked) return;

    try {
      final prefs = _prefs ??= await SharedPreferences.getInstance();
      await prefs.setString('selected_avatar_id', avatar.id);

      final updated = state.availableAvatars
          .map((a) => a.copyWith(
                isEquipped: a.id == avatar.id,
              ))
          .toList();

      state = state.copyWith(
        availableAvatars: updated,
        selectedAvatar: avatar.copyWith(isEquipped: true),
      );
    } catch (e) {
      state = state.copyWith(error: 'Failed to equip avatar: $e');
    }
  }

  Future<void> unlockAvatar(String avatarId) async {
    try {
      final updated = state.availableAvatars
          .map((a) => a.id == avatarId
              ? a.copyWith(isUnlocked: true, unlockedDate: DateTime.now())
              : a)
          .toList();

      final prefs = _prefs ??= await SharedPreferences.getInstance();
      await prefs.setInt(
        'total_avatars_unlocked',
        updated.where((a) => a.isUnlocked).length,
      );

      state = state.copyWith(
        availableAvatars: updated,
        totalAvatarsUnlocked: updated.where((a) => a.isUnlocked).length,
      );
    } catch (e) {
      state = state.copyWith(error: 'Failed to unlock avatar: $e');
    }
  }

  Future<void> equipCosmetic(String cosmeticId) async {
    if (state.selectedAvatar == null) return;

    try {
      final equipped = [...state.selectedAvatar!.equippedCosmetics];
      if (!equipped.contains(cosmeticId)) {
        equipped.add(cosmeticId);
      }

      final updated = state.availableAvatars
          .map((a) => a.id == state.selectedAvatar!.id
              ? a.copyWith(equippedCosmetics: equipped)
              : a)
          .toList();

      final prefs = _prefs ??= await SharedPreferences.getInstance();
      await prefs.setStringList('equipped_cosmetics', equipped);

      state = state.copyWith(
        availableAvatars: updated,
        selectedAvatar: state.selectedAvatar!.copyWith(
          equippedCosmetics: equipped,
        ),
      );
    } catch (e) {
      state = state.copyWith(error: 'Failed to equip cosmetic: $e');
    }
  }

  Future<void> removeCosmetic(String cosmeticId) async {
    if (state.selectedAvatar == null) return;

    try {
      final equipped = state.selectedAvatar!.equippedCosmetics
          .where((c) => c != cosmeticId)
          .toList();

      final updated = state.availableAvatars
          .map((a) => a.id == state.selectedAvatar!.id
              ? a.copyWith(equippedCosmetics: equipped)
              : a)
          .toList();

      final prefs = _prefs ??= await SharedPreferences.getInstance();
      await prefs.setStringList('equipped_cosmetics', equipped);

      state = state.copyWith(
        availableAvatars: updated,
        selectedAvatar: state.selectedAvatar!.copyWith(
          equippedCosmetics: equipped,
        ),
      );
    } catch (e) {
      state = state.copyWith(error: 'Failed to remove cosmetic: $e');
    }
  }

  Future<void> unlockCosmetic(String cosmeticId) async {
    try {
      final updated = state.availableCosmetics
          .map((c) => c.id == cosmeticId
              ? c.copyWith(isUnlocked: true, unlockedDate: DateTime.now())
              : c)
          .toList();

      final prefs = _prefs ??= await SharedPreferences.getInstance();
      await prefs.setInt(
        'total_cosmetics_unlocked',
        updated.where((c) => c.isUnlocked).length,
      );

      state = state.copyWith(
        availableCosmetics: updated,
        totalCosmeticsUnlocked: updated.where((c) => c.isUnlocked).length,
      );
    } catch (e) {
      state = state.copyWith(error: 'Failed to unlock cosmetic: $e');
    }
  }
}

/// Riverpod provider for avatars
final avatarsProvider =
    StateNotifierProvider<AvatarsNotifier, AvatarsState>(
  (ref) => AvatarsNotifier(),
);
