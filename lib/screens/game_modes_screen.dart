import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/game_modes_provider.dart';

class GameModesScreen extends ConsumerWidget {
  const GameModesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final modesState = ref.watch(gameModesProvider);
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('ゲームモード'),
        elevation: 0,
      ),
      body: CustomScrollView(
        slivers: [
          // Modes played header
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: _ModesPlayedHeader(
                totalPlayed: modesState.totalModesPlayed,
              ),
            ),
          ),
          const SliverPadding(padding: EdgeInsets.only(top: 8)),

          // Game modes grid
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            sliver: SliverGrid(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final mode = modesState.availableModes[index];
                  return _GameModeCard(mode: mode);
                },
                childCount: modesState.availableModes.length,
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

/// Modes played header
class _ModesPlayedHeader extends StatelessWidget {
  final int totalPlayed;

  const _ModesPlayedHeader({required this.totalPlayed});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.indigo.withValues(alpha: 0.8),
            Colors.purple.withValues(alpha: 0.6),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.indigo.withValues(alpha: 0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            'モード別プレイ記録',
            style: theme.textTheme.titleLarge?.copyWith(
              color: Colors.white.withValues(alpha: 0.9),
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'プレイ済みモード',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: Colors.white.withValues(alpha: 0.9),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '$totalPlayed回',
                    style: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    const Text(
                      '🎮',
                      style: TextStyle(fontSize: 32),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'すべてのモード\nをプレイしよう！',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Game mode card
class _GameModeCard extends ConsumerWidget {
  final GameMode mode;

  const _GameModeCard({required this.mode});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final modeColor = _getModeColor(mode.type);

    return GestureDetector(
      onTap: () {
        showModalBottomSheet(
          context: context,
          backgroundColor: Colors.transparent,
          builder: (context) => _GameModeDetailSheet(mode: mode),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              modeColor.withValues(alpha: 0.15),
              modeColor.withValues(alpha: 0.05),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          border: Border.all(
            color: modeColor.withValues(alpha: 0.4),
            width: 2,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Top section: emoji and title
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                children: [
                  Text(
                    mode.emoji,
                    style: const TextStyle(fontSize: 32),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    mode.name,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: modeColor,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: modeColor.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      mode.difficulty,
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontSize: 10,
                        color: modeColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Bottom section: stats
            Container(
              decoration: BoxDecoration(
                color: modeColor.withValues(alpha: 0.1),
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(10),
                  bottomRight: Radius.circular(10),
                ),
              ),
              padding: const EdgeInsets.all(8),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _StatBadge(
                        label: 'プレイ数',
                        value: '${mode.totalPlayed}',
                        emoji: '🎯',
                      ),
                      _StatBadge(
                        label: 'スコア',
                        value: '${mode.bestScore}',
                        emoji: '⭐',
                      ),
                    ],
                  ),
                  if (mode.highestLevel > 1) ...[
                    const SizedBox(height: 4),
                    Text(
                      'レベル: ${mode.highestLevel}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontSize: 10,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getModeColor(GameModeType type) {
    return switch (type) {
      GameModeType.classic => Colors.blue,
      GameModeType.blitz => Colors.orange,
      GameModeType.puzzle => Colors.purple,
      GameModeType.survival => Colors.red,
      GameModeType.timeAttack => Colors.amber,
      GameModeType.endless => Colors.green,
    };
  }
}

/// Stat badge
class _StatBadge extends StatelessWidget {
  final String label;
  final String value;
  final String emoji;

  const _StatBadge({
    required this.label,
    required this.value,
    required this.emoji,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      children: [
        Text(
          emoji,
          style: const TextStyle(fontSize: 12),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: theme.textTheme.bodySmall?.copyWith(
            fontWeight: FontWeight.bold,
            fontSize: 11,
          ),
        ),
        const SizedBox(height: 1),
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            fontSize: 8,
            color: Colors.grey.shade600,
          ),
        ),
      ],
    );
  }
}

/// Game mode detail sheet
class _GameModeDetailSheet extends ConsumerWidget {
  final GameMode mode;

  const _GameModeDetailSheet({required this.mode});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final modeColor = _getModeColor(mode.type);

    return Container(
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(20),
        ),
      ),
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // Header
          Center(
            child: Column(
              children: [
                Text(
                  mode.emoji,
                  style: const TextStyle(fontSize: 48),
                ),
                const SizedBox(height: 12),
                Text(
                  mode.name,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: modeColor,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Description
          Text(
            mode.description,
            style: theme.textTheme.bodyLarge,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),

          // Stats grid
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.3,
            children: [
              _DetailStat(
                label: 'ベストスコア',
                value: '${mode.bestScore}',
                emoji: '⭐',
              ),
              _DetailStat(
                label: 'プレイ数',
                value: '${mode.totalPlayed}回',
                emoji: '🎮',
              ),
              _DetailStat(
                label: '最高レベル',
                value: '${mode.highestLevel}',
                emoji: '📈',
              ),
              _DetailStat(
                label: '難易度',
                value: mode.difficulty,
                emoji: '⚔️',
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Rules
          if (mode.rules.isNotEmpty) ...[
            Text(
              'ルール',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: modeColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                mode.rules,
                style: theme.textTheme.bodyMedium,
              ),
            ),
            const SizedBox(height: 24),
          ],

          // Play button
          ElevatedButton(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('${mode.name}をプレイ開始'),
                  duration: const Duration(seconds: 2),
                ),
              );
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: modeColor,
              minimumSize: const Size.fromHeight(48),
            ),
            child: Text(
              'プレイ開始',
              style: theme.textTheme.bodyLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Close button
          OutlinedButton(
            onPressed: () => Navigator.pop(context),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size.fromHeight(48),
            ),
            child: Text(
              '閉じる',
              style: theme.textTheme.bodyLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _getModeColor(GameModeType type) {
    return switch (type) {
      GameModeType.classic => Colors.blue,
      GameModeType.blitz => Colors.orange,
      GameModeType.puzzle => Colors.purple,
      GameModeType.survival => Colors.red,
      GameModeType.timeAttack => Colors.amber,
      GameModeType.endless => Colors.green,
    };
  }
}

/// Detail stat display
class _DetailStat extends StatelessWidget {
  final String label;
  final String value;
  final String emoji;

  const _DetailStat({
    required this.label,
    required this.value,
    required this.emoji,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            emoji,
            style: const TextStyle(fontSize: 24),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: theme.textTheme.bodyLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: Colors.grey.shade600,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
