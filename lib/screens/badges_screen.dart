import 'package:flutter/material.dart' hide Badge;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/badges_provider.dart';

class BadgesScreen extends ConsumerWidget {
  const BadgesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final badgesState = ref.watch(badgesProvider);
    final theme = Theme.of(context);
    final completionPercent = badgesState.getCompletionPercentage();

    return Scaffold(
          backgroundColor: theme.scaffoldBackgroundColor,
          appBar: AppBar(
            title: const Text('バッジコレクション'),
            elevation: 0,
          ),
          body: CustomScrollView(
            slivers: [
              // Collection header
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: _CollectionHeader(
                    unlockedCount: badgesState.unlockedBadges.length,
                    totalCount: badgesState.allBadges.length,
                    completionPercent: completionPercent,
                    totalPoints: badgesState.totalPoints,
                  ),
                ),
              ),
              const SliverPadding(padding: EdgeInsets.only(top: 8)),

              // Unlocked badges section
              if (badgesState.unlockedBadges.isNotEmpty) ...[
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      '獲得済みバッジ (${badgesState.unlockedBadges.length})',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SliverPadding(padding: EdgeInsets.only(top: 12)),
                SliverGrid(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final badge = badgesState.unlockedBadges[index];
                      final isSelected =
                          badgesState.selectedTitle == badge.id;

                      return _BadgeCard(
                        badge: badge,
                        isSelected: isSelected,
                        onTap: () {
                          ref
                              .read(badgesProvider.notifier)
                              .selectTitle(badge.id);
                        },
                      );
                    },
                    childCount: badgesState.unlockedBadges.length,
                  ),
                  gridDelegate:
                      const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: 0.85,
                  ),
                ),
                const SliverPadding(padding: EdgeInsets.only(top: 24)),
              ],

              // Locked badges section
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    '未獲得バッジ (${badgesState.allBadges.length - badgesState.unlockedBadges.length})',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SliverPadding(padding: EdgeInsets.only(top: 12)),
              SliverGrid(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final lockedBadges = badgesState.allBadges
                        .where((b) => !badgesState.unlockedBadges
                            .any((ub) => ub.id == b.id))
                        .toList();

                    if (index >= lockedBadges.length) {
                      return const SizedBox.shrink();
                    }

                    final badge = lockedBadges[index];
                    return _LockedBadgeCard(badge: badge);
                  },
                  childCount: badgesState.allBadges.length -
                      badgesState.unlockedBadges.length,
                ),
                gridDelegate:
                    const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 0.85,
                ),
              ),
              const SliverPadding(padding: EdgeInsets.only(bottom: 32)),
            ],
          ),
    );
  }
}

/// Collection header with stats
class _CollectionHeader extends StatelessWidget {
  final int unlockedCount;
  final int totalCount;
  final double completionPercent;
  final int totalPoints;

  const _CollectionHeader({
    required this.unlockedCount,
    required this.totalCount,
    required this.completionPercent,
    required this.totalPoints,
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'コレクション進捗',
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: Colors.white.withValues(alpha: 0.9),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '$unlockedCount / $totalCount',
                    style: const TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '獲得ポイント',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: Colors.white.withValues(alpha: 0.9),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '$totalPoints⭐',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.amber,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: completionPercent,
              minHeight: 8,
              backgroundColor: Colors.white.withValues(alpha: 0.2),
              valueColor: const AlwaysStoppedAnimation(Colors.amber),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '完成度: ${(completionPercent * 100).toInt()}%',
            style: theme.textTheme.bodySmall?.copyWith(
              color: Colors.white.withValues(alpha: 0.9),
            ),
          ),
        ],
      ),
    );
  }
}

/// Unlocked badge card
class _BadgeCard extends StatelessWidget {
  final Badge badge;
  final bool isSelected;
  final VoidCallback onTap;

  const _BadgeCard({
    required this.badge,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              _getTierColor(badge.tier).withValues(alpha: 0.15),
              _getTierColor(badge.tier).withValues(alpha: 0.05),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          border: Border.all(
            color: isSelected
                ? Colors.amber
                : _getTierColor(badge.tier).withValues(alpha: 0.5),
            width: isSelected ? 3 : 2,
          ),
          borderRadius: BorderRadius.circular(12),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.amber.withValues(alpha: 0.5),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              badge.emoji,
              style: const TextStyle(fontSize: 40),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Text(
                badge.name,
                style: theme.textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: _getTierColor(badge.tier),
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: _getTierColor(badge.tier).withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                badge.tier.label,
                style: theme.textTheme.bodySmall?.copyWith(
                  fontSize: 10,
                  color: _getTierColor(badge.tier),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            if (isSelected)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 4,
                    vertical: 1,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.amber,
                    borderRadius: BorderRadius.circular(3),
                  ),
                  child: const Text(
                    '選択中',
                    style: TextStyle(
                      fontSize: 8,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Color _getTierColor(BadgeTier tier) {
    return switch (tier) {
      BadgeTier.bronze => Colors.orange,
      BadgeTier.silver => Colors.grey,
      BadgeTier.gold => Colors.amber,
      BadgeTier.platinum => Colors.lightBlue,
      BadgeTier.diamond => Colors.purple,
    };
  }
}

/// Locked badge card (greyed out)
class _LockedBadgeCard extends StatelessWidget {
  final Badge badge;

  const _LockedBadgeCard({required this.badge});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.withValues(alpha: 0.1),
        border: Border.all(
          color: Colors.grey.withValues(alpha: 0.3),
          width: 1.5,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Stack(
        children: [
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Opacity(
                opacity: 0.4,
                child: Text(
                  badge.emoji,
                  style: const TextStyle(fontSize: 40),
                ),
              ),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Text(
                  badge.name,
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.grey.shade600,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.grey.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  badge.tier.label,
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontSize: 10,
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          // Lock indicator
          Center(
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.grey.withValues(alpha: 0.7),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.lock,
                color: Colors.white,
                size: 16,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
