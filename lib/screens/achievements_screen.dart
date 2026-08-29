import 'package:flutter/material.dart';

import '../engine/achievements.dart';
import '../engine/board_theme.dart';

class AchievementsScreen extends StatefulWidget {
  const AchievementsScreen({super.key});

  @override
  State<AchievementsScreen> createState() => _AchievementsScreenState();
}

class _AchievementsScreenState extends State<AchievementsScreen> {
  late AchievementManager _manager;
  late List<Achievement> _achievements;
  late List<Achievement> _unlockedAchievements;

  @override
  void initState() {
    super.initState();
    _manager = AchievementManager();
    _achievements = _manager.achievements.values.toList();
    _unlockedAchievements = _manager.getUnlockedAchievements();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final unlockedCount = _unlockedAchievements.length;
    final totalCount = _achievements.length;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('実績'),
      ),
      body: CustomScrollView(
        slivers: [
          // Header with progress
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Text(
                    '実績進捗',
                    style: theme.textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 16),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LinearProgressIndicator(
                      value: unlockedCount / totalCount,
                      minHeight: 24,
                      backgroundColor: Colors.grey[800],
                      valueColor: AlwaysStoppedAnimation<Color>(
                        Colors.amber[700]!,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '$unlockedCount/$totalCount',
                    style: theme.textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
          ),
          // Unlocked achievements section
          if (_unlockedAchievements.isNotEmpty) ...[
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Text(
                  '取得済み実績',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            SliverGrid(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                childAspectRatio: 0.85,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
              ),
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final achievement = _unlockedAchievements[index];
                  return _AchievementCard(achievement: achievement);
                },
                childCount: _unlockedAchievements.length,
              ),
            ),
          ],
          // Locked achievements section
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Text(
                '未取得実績',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          SliverGrid(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              childAspectRatio: 0.85,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
            ),
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final locked = _achievements
                    .where((a) => !a.isUnlocked)
                    .toList();
                final achievement = locked[index];
                return _AchievementCard(achievement: achievement);
              },
              childCount: _achievements
                  .where((a) => !a.isUnlocked)
                  .length,
            ),
          ),
          const SliverPadding(padding: EdgeInsets.only(bottom: 16)),
        ],
      ),
    );
  }
}

class _AchievementCard extends StatelessWidget {
  final Achievement achievement;

  const _AchievementCard({required this.achievement});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isUnlocked = achievement.isUnlocked;

    return GestureDetector(
      onTap: () {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text('${achievement.emoji} ${achievement.name}'),
            content: Text(achievement.description),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('閉じる'),
              ),
            ],
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: isUnlocked
              ? Colors.amber[700]?.withValues(alpha: 0.2)
              : Colors.grey[800],
          border: Border.all(
            color: isUnlocked ? Colors.amber[700]! : Colors.grey[600]!,
            width: 2,
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              achievement.emoji,
              style: const TextStyle(fontSize: 32),
            ),
            const SizedBox(height: 8),
            Text(
              achievement.name,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: isUnlocked ? Colors.amber[700] : Colors.grey,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            if (!isUnlocked)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  'ロック中',
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontSize: 10,
                    color: Colors.grey[500],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
