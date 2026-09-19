import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/avatars_provider.dart';

class AvatarsScreen extends ConsumerWidget {
  const AvatarsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final avatarsState = ref.watch(avatarsProvider);
    final theme = Theme.of(context);

    return Scaffold(
          backgroundColor: theme.scaffoldBackgroundColor,
          appBar: AppBar(
            title: const Text('アバター＆コスメティック'),
            elevation: 0,
          ),
          body: CustomScrollView(
            slivers: [
              // Current avatar preview
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: _AvatarPreview(
                    avatar: avatarsState.selectedAvatar,
                    totalUnlocked: avatarsState.totalAvatarsUnlocked,
                  ),
                ),
              ),
              const SliverPadding(padding: EdgeInsets.only(top: 8)),

              // Avatar selection tabs
              SliverToBoxAdapter(
                child: _AvatarTabs(
                  avatars: avatarsState.availableAvatars,
                  selectedAvatar: avatarsState.selectedAvatar,
                ),
              ),

              // Cosmetics section
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'コスメティック',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],
                  ),
                ),
              ),

              // Cosmetics grid
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                sliver: SliverGrid(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final cosmetic =
                          avatarsState.availableCosmetics[index];
                      return _CosmeticCard(
                        cosmetic: cosmetic,
                        isEquipped: avatarsState.selectedAvatar
                                ?.equippedCosmetics
                                .contains(cosmetic.id) ??
                            false,
                        onEquip: () {
                          ref
                              .read(avatarsProvider.notifier)
                              .equipCosmetic(cosmetic.id);
                        },
                        onRemove: () {
                          ref
                              .read(avatarsProvider.notifier)
                              .removeCosmetic(cosmetic.id);
                        },
                      );
                    },
                    childCount: avatarsState.availableCosmetics.length,
                  ),
                  gridDelegate:
                      const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: 0.9,
                  ),
                ),
              ),
              const SliverPadding(padding: EdgeInsets.only(bottom: 32)),
            ],
          ),
    );
  }
}

/// Avatar preview
class _AvatarPreview extends StatelessWidget {
  final Avatar? avatar;
  final int totalUnlocked;

  const _AvatarPreview({
    required this.avatar,
    required this.totalUnlocked,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.purple.withValues(alpha: 0.8),
            Colors.indigo.withValues(alpha: 0.6),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.purple.withValues(alpha: 0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          if (avatar != null) ...[
            Text(
              avatar!.emoji,
              style: const TextStyle(fontSize: 64),
            ),
            const SizedBox(height: 12),
            Text(
              avatar!.name,
              style: theme.textTheme.titleLarge?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  avatar!.category.label,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: Colors.white.withValues(alpha: 0.9),
                  ),
                ),
                Row(
                  children: List.generate(
                    avatar!.rarity,
                    (index) => const Text(
                      '⭐',
                      style: TextStyle(fontSize: 12),
                    ),
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'アバター解放数',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Colors.white.withValues(alpha: 0.9),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$totalUnlocked個',
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                Text(
                  '💎',
                  style: theme.textTheme.titleLarge,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Avatar tabs
class _AvatarTabs extends ConsumerWidget {
  final List<Avatar> avatars;
  final Avatar? selectedAvatar;

  const _AvatarTabs({
    required this.avatars,
    required this.selectedAvatar,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categories = AvatarCategory.values.toList();

    return DefaultTabController(
      length: categories.length,
      child: Column(
        children: [
          TabBar(
            tabs: categories
                .map((cat) => Tab(text: cat.label))
                .toList(),
            isScrollable: true,
            labelColor: Colors.blue,
            unselectedLabelColor: Colors.grey,
            indicatorColor: Colors.blue,
          ),
          SizedBox(
            height: 240,
            child: TabBarView(
              children: categories
                  .map((category) => _AvatarGrid(
                        avatars: avatars
                            .where((a) => a.category == category)
                            .toList(),
                        selectedAvatar: selectedAvatar,
                        onSelect: (avatar) {
                          ref
                              .read(avatarsProvider.notifier)
                              .equipAvatar(avatar);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('${avatar.name}を装備しました！'),
                              duration: const Duration(seconds: 1),
                            ),
                          );
                        },
                      ))
                  .toList(),
            ),
          ),
        ],
      ),
    );
  }
}

/// Avatar grid
class _AvatarGrid extends StatelessWidget {
  final List<Avatar> avatars;
  final Avatar? selectedAvatar;
  final Function(Avatar) onSelect;

  const _AvatarGrid({
    required this.avatars,
    required this.selectedAvatar,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
      ),
      itemCount: avatars.length,
      itemBuilder: (context, index) {
        final avatar = avatars[index];
        final isSelected = selectedAvatar?.id == avatar.id;

        return GestureDetector(
          onTap: avatar.isUnlocked ? () => onSelect(avatar) : null,
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.blue.withValues(alpha: 0.1),
                  Colors.purple.withValues(alpha: 0.05),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              border: Border.all(
                color: isSelected
                    ? Colors.blue
                    : (avatar.isUnlocked
                        ? Colors.blue.withValues(alpha: 0.3)
                        : Colors.grey.withValues(alpha: 0.2)),
                width: isSelected ? 3 : 2,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Stack(
              children: [
                Center(
                  child: Opacity(
                    opacity: avatar.isUnlocked ? 1.0 : 0.4,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          avatar.emoji,
                          style: const TextStyle(fontSize: 40),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          avatar.name,
                          style: TextStyle(
                            fontSize: 8,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey.shade700,
                            overflow: TextOverflow.ellipsis,
                          ),
                          maxLines: 1,
                        ),
                      ],
                    ),
                  ),
                ),
                if (!avatar.isUnlocked)
                  Positioned(
                    top: 4,
                    right: 4,
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        color: Colors.orange,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text(
                        '🔒',
                        style: TextStyle(fontSize: 12),
                      ),
                    ),
                  ),
                if (isSelected)
                  Positioned(
                    bottom: 4,
                    right: 4,
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        color: Colors.blue,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Icon(
                        Icons.check,
                        size: 12,
                        color: Colors.white,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// Cosmetic card
class _CosmeticCard extends ConsumerWidget {
  final CosmeticItem cosmetic;
  final bool isEquipped;
  final VoidCallback onEquip;
  final VoidCallback onRemove;

  const _CosmeticCard({
    required this.cosmetic,
    required this.isEquipped,
    required this.onEquip,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final rarityColor = _getRarityColor(cosmetic.rarity);

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            rarityColor.withValues(alpha: 0.1),
            rarityColor.withValues(alpha: 0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(
          color: cosmetic.isUnlocked
              ? rarityColor.withValues(alpha: 0.5)
              : Colors.grey.withValues(alpha: 0.2),
          width: 2,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Stack(
        children: [
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Opacity(
                opacity: cosmetic.isUnlocked ? 1.0 : 0.4,
                child: Text(
                  cosmetic.emoji,
                  style: const TextStyle(fontSize: 36),
                ),
              ),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Text(
                  cosmetic.name,
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: rarityColor,
                    fontSize: 11,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 6,
                  vertical: 2,
                ),
                decoration: BoxDecoration(
                  color: rarityColor.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  cosmetic.type.label,
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontSize: 9,
                    color: rarityColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          if (!cosmetic.isUnlocked)
            Positioned(
              top: 4,
              right: 4,
              child: Container(
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.8),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text(
                  '🔒',
                  style: TextStyle(fontSize: 12),
                ),
              ),
            ),
          if (isEquipped && cosmetic.isUnlocked)
            Positioned(
              bottom: 4,
              right: 4,
              child: Container(
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  color: Colors.green,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Icon(
                  Icons.check,
                  size: 12,
                  color: Colors.white,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Color _getRarityColor(int rarity) {
    return switch (rarity) {
      1 => Colors.grey,
      2 => Colors.green,
      3 => Colors.blue,
      4 => Colors.purple,
      5 => Colors.orange,
      _ => Colors.grey,
    };
  }
}
