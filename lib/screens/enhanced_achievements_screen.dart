import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/achievements_provider.dart';

/// Enhanced achievements screen with visual badges and progress tracking
class EnhancedAchievementsScreen extends ConsumerWidget {
  const EnhancedAchievementsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final achievementsState = ref.watch(achievementsProvider);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('実績'),
        elevation: 0,
      ),
      body: achievementsState.isLoading
          ? const Center(child: CircularProgressIndicator())
          : CustomScrollView(
              slivers: [
                // Header with completion stats
                SliverToBoxAdapter(
                  child: _AchievementHeader(
                    totalUnlocked: achievementsState.totalUnlocked,
                    totalCount: achievementsState.allAchievements.length,
                    completionPercentage:
                        achievementsState.completionPercentage,
                    lastUnlocked: achievementsState.lastUnlocked,
                  ),
                ),

                // Recently unlocked badge
                if (achievementsState.lastUnlocked != null) ...[
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                      child: Text(
                        '最新の実績',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: _AchievementBadgeCard(
                        achievementWithProgress: achievementsState.lastUnlocked!,
                        isHighlighted: true,
                      ),
                    ),
                  ),
                ],

                // Unlocked achievements by rarity
                if (achievementsState.unlockedAchievements.isNotEmpty) ...[
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                      child: Text(
                        '取得済み実績',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  SliverGrid(
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: 1.2,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                    ),
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final achievement =
                            achievementsState.unlockedAchievements[index];
                        return _AchievementBadgeCard(
                          achievementWithProgress: achievement,
                        );
                      },
                      childCount:
                          achievementsState.unlockedAchievements.length,
                    ),
                  ),
                ],

                // Closest to unlock
                if (achievementsState.getClosestToUnlock().isNotEmpty) ...[
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '次の目標',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'あと少しで取得できそう',
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.copyWith(color: Colors.grey[500]),
                          ),
                        ],
                      ),
                    ),
                  ),
                  SliverGrid(
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: 1.2,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                    ),
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final achievements =
                            achievementsState.getClosestToUnlock();
                        if (index >= achievements.length) return null;
                        return _AchievementBadgeCard(
                          achievementWithProgress: achievements[index],
                          showProgress: true,
                        );
                      },
                      childCount: achievementsState.getClosestToUnlock().length,
                    ),
                  ),
                ],

                // Locked achievements section
                if (achievementsState.lockedAchievements.isNotEmpty) ...[
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                      child: Text(
                        '未取得実績',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  SliverGrid(
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: 1.2,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                    ),
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final achievement =
                            achievementsState.lockedAchievements[index];
                        return _AchievementBadgeCard(
                          achievementWithProgress: achievement,
                          showProgress: true,
                        );
                      },
                      childCount: achievementsState.lockedAchievements.length,
                    ),
                  ),
                ],

                const SliverPadding(padding: EdgeInsets.only(bottom: 16)),
              ],
            ),
    );
  }
}

/// Header showing completion statistics
class _AchievementHeader extends StatelessWidget {
  final int totalUnlocked;
  final int totalCount;
  final double completionPercentage;
  final AchievementWithProgress? lastUnlocked;

  const _AchievementHeader({
    required this.totalUnlocked,
    required this.totalCount,
    required this.completionPercentage,
    this.lastUnlocked,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.amber[800]!.withOpacity(0.1),
            Colors.amber[700]!.withOpacity(0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border(
          bottom: BorderSide(
            color: Colors.amber[700]!.withOpacity(0.2),
            width: 1,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Completion stats
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '実績進捗',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: Colors.grey[500],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '$totalUnlocked/$totalCount',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.amber[700],
                    ),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '達成度',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: Colors.grey[500],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${(completionPercentage * 100).toStringAsFixed(1)}%',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.amber[700],
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Progress bar
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: completionPercentage,
              minHeight: 12,
              backgroundColor: Colors.grey[800],
              valueColor: AlwaysStoppedAnimation<Color>(Colors.amber[700]!),
            ),
          ),

          // Last unlocked info
          if (lastUnlocked != null) ...[
            const SizedBox(height: 12),
            Text(
              '直近の取得：${lastUnlocked!.achievement.name}',
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: Colors.amber[300]),
            ),
          ],
        ],
      ),
    );
  }
}

/// Individual achievement badge card with progress
class _AchievementBadgeCard extends StatelessWidget {
  final AchievementWithProgress achievementWithProgress;
  final bool showProgress;
  final bool isHighlighted;

  const _AchievementBadgeCard({
    required this.achievementWithProgress,
    this.showProgress = false,
    this.isHighlighted = false,
  });

  @override
  Widget build(BuildContext context) {
    final achievement = achievementWithProgress.achievement;
    final isUnlocked = achievement.isUnlocked;
    final rarity = achievementWithProgress.rarity;
    final rarityColor = _getRarityColor(rarity);

    return GestureDetector(
      onTap: () => _showAchievementDetails(context),
      child: Container(
        decoration: BoxDecoration(
          gradient: isUnlocked
              ? LinearGradient(
                  colors: [
                    rarityColor.withOpacity(0.2),
                    rarityColor.withOpacity(0.05),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : null,
          color: isUnlocked ? null : Colors.grey[900],
          border: Border.all(
            color: isUnlocked ? rarityColor : Colors.grey[700]!,
            width: isHighlighted ? 3 : 2,
          ),
          borderRadius: BorderRadius.circular(12),
          boxShadow: isHighlighted
              ? [
                  BoxShadow(
                    color: rarityColor.withOpacity(0.5),
                    blurRadius: 12,
                    spreadRadius: 2,
                  ),
                ]
              : null,
        ),
        child: Stack(
          children: [
            // Main content
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Icon/Emoji
                  Text(
                    achievement.emoji,
                    style: const TextStyle(fontSize: 40),
                  ),
                  const SizedBox(height: 8),

                  // Name
                  Text(
                    achievement.name,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: isUnlocked ? Colors.white : Colors.grey[500],
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),

                  // Progress or status
                  if (showProgress && !isUnlocked)
                    Column(
                      children: [
                        const SizedBox(height: 4),
                        _buildProgressIndicator(),
                        const SizedBox(height: 4),
                        Text(
                          achievementWithProgress.getProgressText(),
                          style: Theme.of(context)
                              .textTheme
                              .bodySmall
                              ?.copyWith(
                                fontSize: 10,
                                color: Colors.grey[400],
                              ),
                        ),
                      ],
                    )
                  else if (isUnlocked && showProgress == false)
                    Text(
                      _getRarityLabel(rarity),
                      style: Theme.of(context)
                          .textTheme
                          .bodySmall
                          ?.copyWith(
                            fontSize: 10,
                            color: rarityColor,
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                ],
              ),
            ),

            // Locked badge
            if (!isUnlocked && !showProgress)
              Positioned(
                top: 4,
                right: 4,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.red[700],
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Icon(
                    Icons.lock,
                    size: 12,
                    color: Colors.white,
                  ),
                ),
              ),

            // New badge
            if (isUnlocked && achievementWithProgress.isNew)
              Positioned(
                top: 4,
                right: 4,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.blue[600],
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text(
                    'NEW',
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

  Widget _buildProgressIndicator() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(4),
      child: LinearProgressIndicator(
        value: achievementWithProgress.progress,
        minHeight: 4,
        backgroundColor: Colors.grey[800],
        valueColor:
            AlwaysStoppedAnimation<Color>(_getRarityColor(achievementWithProgress.rarity)),
      ),
    );
  }

  Color _getRarityColor(AchievementRarity rarity) {
    switch (rarity) {
      case AchievementRarity.common:
        return Colors.grey[400]!;
      case AchievementRarity.uncommon:
        return Colors.green;
      case AchievementRarity.rare:
        return Colors.blue;
      case AchievementRarity.epic:
        return Colors.purple;
    }
  }

  String _getRarityLabel(AchievementRarity rarity) {
    switch (rarity) {
      case AchievementRarity.common:
        return 'Common';
      case AchievementRarity.uncommon:
        return 'Uncommon';
      case AchievementRarity.rare:
        return 'Rare';
      case AchievementRarity.epic:
        return 'Epic';
    }
  }

  void _showAchievementDetails(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) => _AchievementDetailsSheet(
        achievementWithProgress: achievementWithProgress,
      ),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
    );
  }
}

/// Bottom sheet showing detailed achievement information
class _AchievementDetailsSheet extends StatelessWidget {
  final AchievementWithProgress achievementWithProgress;

  const _AchievementDetailsSheet({
    required this.achievementWithProgress,
  });

  @override
  Widget build(BuildContext context) {
    final achievement = achievementWithProgress.achievement;
    final isUnlocked = achievement.isUnlocked;

    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[850],
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  achievement.emoji,
                  style: const TextStyle(fontSize: 48),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Title
            Text(
              achievement.name,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),

            // Description
            Text(
              achievement.description,
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),

            // Progress
            if (!isUnlocked)
              Column(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LinearProgressIndicator(
                      value: achievementWithProgress.progress,
                      minHeight: 16,
                      backgroundColor: Colors.grey[700],
                      valueColor: AlwaysStoppedAnimation<Color>(
                        _getRarityColor(achievementWithProgress.rarity),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    achievementWithProgress.getProgressText(),
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              )
            else
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: Colors.green,
                    width: 1,
                  ),
                ),
                child: Column(
                  children: [
                    const Icon(
                      Icons.check_circle,
                      color: Colors.green,
                      size: 24,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '取得済み',
                      style: Theme.of(context)
                          .textTheme
                          .bodyMedium
                          ?.copyWith(color: Colors.green),
                    ),
                    if (achievement.unlockedAt != null)
                      Text(
                        _formatDate(achievement.unlockedAt!),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey[400],
                        ),
                      ),
                  ],
                ),
              ),

            const SizedBox(height: 16),

            // Rarity info
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 8,
              ),
              decoration: BoxDecoration(
                color: Colors.grey[800],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'レアリティ',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  Text(
                    _getRarityLabel(achievementWithProgress.rarity),
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.copyWith(
                          color: _getRarityColor(achievementWithProgress.rarity),
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getRarityColor(AchievementRarity rarity) {
    switch (rarity) {
      case AchievementRarity.common:
        return Colors.grey[400]!;
      case AchievementRarity.uncommon:
        return Colors.green;
      case AchievementRarity.rare:
        return Colors.blue;
      case AchievementRarity.epic:
        return Colors.purple;
    }
  }

  String _getRarityLabel(AchievementRarity rarity) {
    switch (rarity) {
      case AchievementRarity.common:
        return 'Common';
      case AchievementRarity.uncommon:
        return 'Uncommon';
      case AchievementRarity.rare:
        return 'Rare';
      case AchievementRarity.epic:
        return 'Epic';
    }
  }

  String _formatDate(DateTime date) {
    return '${date.year}年${date.month}月${date.day}日 ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }
}
