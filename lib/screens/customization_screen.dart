import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/customization_provider.dart';

class CustomizationScreen extends ConsumerWidget {
  const CustomizationScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final customizationState = ref.watch(customizationProvider);
    final theme = Theme.of(context);

    return DefaultTabController(
      length: 4,
      child: Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        appBar: AppBar(
          title: const Text('カスタマイズ'),
          elevation: 0,
          bottom: TabBar(
            tabs: [
              const Tab(text: 'ボード'),
              const Tab(text: 'ピース'),
              const Tab(text: 'テーマ'),
              const Tab(text: '設定'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _BoardStylesTab(customizationState: customizationState),
            _PieceStylesTab(customizationState: customizationState),
            _ThemesTab(customizationState: customizationState),
            _SettingsTab(customizationState: customizationState),
          ],
        ),
      ),
    );
  }
}

class _BoardStylesTab extends ConsumerWidget {
  final CustomizationState customizationState;

  const _BoardStylesTab({required this.customizationState});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    return ListView(
      children: [
        if (customizationState.unlockedBoardStyles.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              'ロック解除済み',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          SizedBox(
            height: 200,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: customizationState.unlockedBoardStyles.length,
              itemBuilder: (context, index) {
                final board = customizationState.unlockedBoardStyles[index];
                final isSelected =
                    customizationState.selectedBoardStyleId == board.id;
                return _BoardStyleCard(
                  board: board,
                  isSelected: isSelected,
                  onTap: () =>
                      ref.read(customizationProvider.notifier)
                          .selectBoardStyle(board.id),
                );
              },
            ),
          ),
        ],
        if (customizationState.lockedBoardStyles.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              'ロック中',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade600,
              ),
            ),
          ),
          ...customizationState.lockedBoardStyles.map((board) =>
              _LockedBoardStyleCard(
                board: board,
                onUnlock: () =>
                    ref.read(customizationProvider.notifier)
                        .unlockBoardStyle(board.id),
              )),
        ],
      ],
    );
  }
}

class _PieceStylesTab extends ConsumerWidget {
  final CustomizationState customizationState;

  const _PieceStylesTab({required this.customizationState});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    return ListView(
      children: [
        if (customizationState.unlockedPieceStyles.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              'ロック解除済み',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          SizedBox(
            height: 200,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: customizationState.unlockedPieceStyles.length,
              itemBuilder: (context, index) {
                final piece = customizationState.unlockedPieceStyles[index];
                final isSelected =
                    customizationState.selectedPieceStyleId == piece.id;
                return _PieceStyleCard(
                  piece: piece,
                  isSelected: isSelected,
                  onTap: () =>
                      ref.read(customizationProvider.notifier)
                          .selectPieceStyle(piece.id),
                );
              },
            ),
          ),
        ],
        if (customizationState.lockedPieceStyles.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              'ロック中',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade600,
              ),
            ),
          ),
          ...customizationState.lockedPieceStyles.map((piece) =>
              _LockedPieceStyleCard(
                piece: piece,
                onUnlock: () =>
                    ref.read(customizationProvider.notifier)
                        .unlockPieceStyle(piece.id),
              )),
        ],
      ],
    );
  }
}

class _ThemesTab extends ConsumerWidget {
  final CustomizationState customizationState;

  const _ThemesTab({required this.customizationState});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListView.builder(
      itemCount: customizationState.themePresets.length,
      itemBuilder: (context, index) {
        final preset = customizationState.themePresets[index];
        return _ThemePresetCard(
          preset: preset,
          onApply: () =>
              ref.read(customizationProvider.notifier)
                  .applyThemePreset(preset.id),
        );
      },
    );
  }
}

class _SettingsTab extends ConsumerWidget {
  final CustomizationState customizationState;

  const _SettingsTab({required this.customizationState});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    return ListView(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            'ゲーム設定',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        ListTile(
          title: const Text('アニメーション'),
          subtitle: const Text('駒の移動やエフェクトを有効にする'),
          trailing: Switch(
            value: customizationState.enableAnimations,
            onChanged: (_) =>
                ref.read(customizationProvider.notifier).toggleAnimations(),
          ),
        ),
        ListTile(
          title: const Text('効果音'),
          subtitle: const Text('ゲーム中の効果音を再生する'),
          trailing: Switch(
            value: customizationState.enableSoundEffects,
            onChanged: (_) =>
                ref.read(customizationProvider.notifier).toggleSoundEffects(),
          ),
        ),
        ListTile(
          title: const Text('ダークモード'),
          subtitle: const Text('ダークモードを有効にする'),
          trailing: Switch(
            value: customizationState.darkModeEnabled,
            onChanged: (_) =>
                ref.read(customizationProvider.notifier).toggleDarkMode(),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'UI スケール: ${customizationState.uiScale.toStringAsFixed(1)}',
                style: theme.textTheme.labelMedium,
              ),
              const SizedBox(height: 8),
              Slider(
                value: customizationState.uiScale,
                min: 0.8,
                max: 1.2,
                divisions: 8,
                onChanged: (value) =>
                    ref.read(customizationProvider.notifier).setUIScale(value),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            '表示設定',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        ListTile(
          title: const Text('現在のボードスタイル'),
          subtitle: customizationState.selectedBoardStyle != null
              ? Text(customizationState.selectedBoardStyle!.name)
              : const Text('不明'),
          trailing: const Icon(Icons.info_outline),
        ),
        ListTile(
          title: const Text('現在のピーススタイル'),
          subtitle: customizationState.selectedPieceStyle != null
              ? Text(customizationState.selectedPieceStyle!.name)
              : const Text('不明'),
          trailing: const Icon(Icons.info_outline),
        ),
      ],
    );
  }
}

class _BoardStyleCard extends StatelessWidget {
  final BoardStyle board;
  final bool isSelected;
  final VoidCallback onTap;

  const _BoardStyleCard({
    required this.board,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Card(
        margin: const EdgeInsets.all(8),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: board.boardColor,
                border: isSelected
                    ? Border.all(color: Colors.blue, width: 3)
                    : null,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: board.gridColor,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              board.name,
              style: const TextTheme().labelMedium,
            ),
            Text(
              board.rarity,
              style: const TextTheme().labelSmall?.copyWith(
                    color: Colors.grey,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PieceStyleCard extends StatelessWidget {
  final PieceStyle piece;
  final bool isSelected;
  final VoidCallback onTap;

  const _PieceStyleCard({
    required this.piece,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Card(
        margin: const EdgeInsets.all(8),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                border: isSelected
                    ? Border.all(color: Colors.blue, width: 3)
                    : null,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(piece.lightPieceEmoji, style: const TextTheme().displayMedium),
                    const SizedBox(width: 8),
                    Text(piece.darkPieceEmoji, style: const TextTheme().displayMedium),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              piece.name,
              style: const TextTheme().labelMedium,
            ),
            Text(
              piece.rarity,
              style: const TextTheme().labelSmall?.copyWith(
                    color: Colors.grey,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LockedBoardStyleCard extends StatelessWidget {
  final BoardStyle board;
  final VoidCallback onUnlock;

  const _LockedBoardStyleCard({
    required this.board,
    required this.onUnlock,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: board.boardColor.withAlpha(128),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: const Icon(Icons.lock, color: Colors.white70),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    board.name,
                    style: const TextTheme().titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  Text(
                    'ロック解除: ${board.cost}ゴールド',
                    style: const TextTheme().labelSmall?.copyWith(
                          color: Colors.grey.shade600,
                        ),
                  ),
                ],
              ),
            ),
            FilledButton(
              onPressed: onUnlock,
              child: const Text('取得'),
            ),
          ],
        ),
      ),
    );
  }
}

class _LockedPieceStyleCard extends StatelessWidget {
  final PieceStyle piece;
  final VoidCallback onUnlock;

  const _LockedPieceStyleCard({
    required this.piece,
    required this.onUnlock,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Center(
                child: Icon(Icons.lock, color: Colors.grey),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    piece.name,
                    style: const TextTheme().titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  Text(
                    'ロック解除: ${piece.cost}ゴールド',
                    style: const TextTheme().labelSmall?.copyWith(
                          color: Colors.grey.shade600,
                        ),
                  ),
                ],
              ),
            ),
            FilledButton(
              onPressed: onUnlock,
              child: const Text('取得'),
            ),
          ],
        ),
      ),
    );
  }
}

class _ThemePresetCard extends StatelessWidget {
  final ThemePreset preset;
  final VoidCallback onApply;

  const _ThemePresetCard({
    required this.preset,
    required this.onApply,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  preset.name,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (preset.isDefault)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade100,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      'デフォルト',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: Colors.blue.shade700,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'ボード: ${preset.boardStyleId} | ピース: ${preset.pieceStyleId}',
              style: theme.textTheme.labelSmall?.copyWith(
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: onApply,
                child: const Text('適用'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
