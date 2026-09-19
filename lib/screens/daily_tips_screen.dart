import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/daily_tips_provider.dart';

class DailyTipsScreen extends ConsumerWidget {
  const DailyTipsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tipsState = ref.watch(dailyTipsProvider);
    final theme = Theme.of(context);

    return Scaffold(
          backgroundColor: theme.scaffoldBackgroundColor,
          appBar: AppBar(
            title: const Text('デイリーティップス'),
            elevation: 0,
          ),
          body: CustomScrollView(
            slivers: [
              // Today's tip
              if (tipsState.todaysTip != null)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: _TodaysTipCard(
                      tip: tipsState.todaysTip!,
                      onFavoriteToggle: () {
                        ref
                            .read(dailyTipsProvider.notifier)
                            .toggleFavorite(tipsState.todaysTip!);
                      },
                    ),
                  ),
                ),
              const SliverPadding(padding: EdgeInsets.only(top: 8)),

              // Tabs for browsing
              SliverToBoxAdapter(
                child: _TipsTabBar(
                  totalTips: tipsState.totalTipsAvailable,
                  favoritesCount: tipsState.favoriteTips.length,
                  recentCount: tipsState.recentlyViewed.length,
                ),
              ),

              // Tips by category tabs
              SliverToBoxAdapter(
                child: SizedBox(
                  height: 400,
                  child: _CategoryTabs(
                    allTips: tipsState.allTips,
                    favorites: tipsState.favoriteTips,
                    recentlyViewed: tipsState.recentlyViewed,
                    onFavoriteToggle: (tip) {
                      ref
                          .read(dailyTipsProvider.notifier)
                          .toggleFavorite(tip);
                    },
                    onTipTapped: (tip) {
                      ref
                          .read(dailyTipsProvider.notifier)
                          .markAsViewed(tip);
                    },
                  ),
                ),
              ),
              const SliverPadding(padding: EdgeInsets.only(bottom: 32)),
            ],
          ),
    );
  }
}

/// Today's tip card
class _TodaysTipCard extends StatelessWidget {
  final GameTip tip;
  final VoidCallback onFavoriteToggle;

  const _TodaysTipCard({
    required this.tip,
    required this.onFavoriteToggle,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final categoryColor = _getCategoryColor(tip.category);
    final difficultyColor = _getDifficultyColor(tip.difficulty);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            categoryColor.withValues(alpha: 0.8),
            categoryColor.withValues(alpha: 0.5),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: categoryColor.withValues(alpha: 0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '本日のティップス',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Colors.white.withValues(alpha: 0.9),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      tip.title,
                      style: theme.textTheme.titleLarge?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: onFavoriteToggle,
                icon: Icon(
                  tip.isFavorite ? Icons.favorite : Icons.favorite_border,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            tip.content,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: Colors.white.withValues(alpha: 0.95),
              height: 1.6,
            ),
            maxLines: 4,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  tip.category.label,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 11,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: difficultyColor.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  tip.difficulty.label,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 11,
                  ),
                ),
              ),
              Text(
                '閲覧: ${tip.views}',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: Colors.white.withValues(alpha: 0.8),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Color _getCategoryColor(TipCategory category) {
    return switch (category) {
      TipCategory.strategy => Colors.blue,
      TipCategory.opening => Colors.orange,
      TipCategory.endgame => Colors.purple,
      TipCategory.tactics => Colors.red,
      TipCategory.psychology => Colors.green,
      TipCategory.advanced => Colors.pink,
    };
  }

  Color _getDifficultyColor(TipDifficulty difficulty) {
    return switch (difficulty) {
      TipDifficulty.easy => Colors.green,
      TipDifficulty.normal => Colors.blue,
      TipDifficulty.hard => Colors.orange,
      TipDifficulty.expert => Colors.red,
    };
  }
}

/// Tips tab bar
class _TipsTabBar extends StatelessWidget {
  final int totalTips;
  final int favoritesCount;
  final int recentCount;

  const _TipsTabBar({
    required this.totalTips,
    required this.favoritesCount,
    required this.recentCount,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _TabIndicator(
            label: 'すべて',
            count: totalTips,
            emoji: '📚',
          ),
          _TabIndicator(
            label: 'お気に入り',
            count: favoritesCount,
            emoji: '❤️',
          ),
          _TabIndicator(
            label: '最近閲覧',
            count: recentCount,
            emoji: '🕐',
          ),
        ],
      ),
    );
  }
}

/// Tab indicator
class _TabIndicator extends StatelessWidget {
  final String label;
  final int count;
  final String emoji;

  const _TabIndicator({
    required this.label,
    required this.count,
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
        children: [
          Text(
            emoji,
            style: const TextStyle(fontSize: 24),
          ),
          const SizedBox(height: 4),
          Text(
            count.toString(),
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
          ),
        ],
      ),
    );
  }
}

/// Category tabs
class _CategoryTabs extends StatefulWidget {
  final List<GameTip> allTips;
  final List<GameTip> favorites;
  final List<GameTip> recentlyViewed;
  final Function(GameTip) onFavoriteToggle;
  final Function(GameTip) onTipTapped;

  const _CategoryTabs({
    required this.allTips,
    required this.favorites,
    required this.recentlyViewed,
    required this.onFavoriteToggle,
    required this.onTipTapped,
  });

  @override
  State<_CategoryTabs> createState() => _CategoryTabsState();
}

class _CategoryTabsState extends State<_CategoryTabs>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 4,
      child: Column(
        children: [
          TabBar(
            tabs: const [
              Tab(text: '全て'),
              Tab(text: 'お気に入り'),
              Tab(text: '最近閲覧'),
              Tab(text: 'カテゴリ'),
            ],
            isScrollable: true,
            labelColor: Colors.blue,
            unselectedLabelColor: Colors.grey,
            indicatorColor: Colors.blue,
          ),
          Expanded(
            child: TabBarView(
              children: [
                _TipsList(tips: widget.allTips, onFavoriteToggle: widget.onFavoriteToggle, onTipTapped: widget.onTipTapped),
                _TipsList(tips: widget.favorites, onFavoriteToggle: widget.onFavoriteToggle, onTipTapped: widget.onTipTapped),
                _TipsList(tips: widget.recentlyViewed, onFavoriteToggle: widget.onFavoriteToggle, onTipTapped: widget.onTipTapped),
                _CategoryList(tips: widget.allTips, onFavoriteToggle: widget.onFavoriteToggle, onTipTapped: widget.onTipTapped),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Tips list
class _TipsList extends StatelessWidget {
  final List<GameTip> tips;
  final Function(GameTip) onFavoriteToggle;
  final Function(GameTip) onTipTapped;

  const _TipsList({
    required this.tips,
    required this.onFavoriteToggle,
    required this.onTipTapped,
  });

  @override
  Widget build(BuildContext context) {
    if (tips.isEmpty) {
      return const Center(
        child: Text('ティップスがありません'),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: tips.length,
      itemBuilder: (context, index) {
        final tip = tips[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: _TipItem(
            tip: tip,
            onFavoriteToggle: () => onFavoriteToggle(tip),
            onTapped: () => onTipTapped(tip),
          ),
        );
      },
    );
  }
}

/// Category list
class _CategoryList extends StatelessWidget {
  final List<GameTip> tips;
  final Function(GameTip) onFavoriteToggle;
  final Function(GameTip) onTipTapped;

  const _CategoryList({
    required this.tips,
    required this.onFavoriteToggle,
    required this.onTipTapped,
  });

  @override
  Widget build(BuildContext context) {
    final categories = TipCategory.values;

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: categories.length,
      itemBuilder: (context, index) {
        final category = categories[index];
        final categoryTips = tips.where((t) => t.category == category).toList();

        if (categoryTips.isEmpty) {
          return const SizedBox.shrink();
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                category.label,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ),
            ...categoryTips
                .take(3)
                .map((tip) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: _TipItem(
                        tip: tip,
                        onFavoriteToggle: () => onFavoriteToggle(tip),
                        onTapped: () => onTipTapped(tip),
                      ),
                    ))
                .toList(),
            const Divider(height: 16),
          ],
        );
      },
    );
  }
}

/// Tip item
class _TipItem extends StatelessWidget {
  final GameTip tip;
  final VoidCallback onFavoriteToggle;
  final VoidCallback onTapped;

  const _TipItem({
    required this.tip,
    required this.onFavoriteToggle,
    required this.onTapped,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final categoryColor = _getCategoryColor(tip.category);

    return GestureDetector(
      onTap: onTapped,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              categoryColor.withValues(alpha: 0.08),
              categoryColor.withValues(alpha: 0.03),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          border: Border.all(
            color: categoryColor.withValues(alpha: 0.2),
            width: 1,
          ),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    tip.title,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: categoryColor,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                IconButton(
                  onPressed: onFavoriteToggle,
                  icon: Icon(
                    tip.isFavorite ? Icons.favorite : Icons.favorite_border,
                    color: Colors.red,
                    size: 20,
                  ),
                  constraints: const BoxConstraints(
                    minWidth: 36,
                    minHeight: 36,
                  ),
                  padding: EdgeInsets.zero,
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              tip.content,
              style: theme.textTheme.bodySmall?.copyWith(
                color: Colors.grey.shade700,
                height: 1.4,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: categoryColor.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    tip.category.label,
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontSize: 10,
                      color: categoryColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Row(
                  children: [
                    Text(
                      '👁 ${tip.views}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Colors.grey.shade600,
                        fontSize: 10,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      tip.difficulty.label,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Colors.grey.shade600,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color _getCategoryColor(TipCategory category) {
    return switch (category) {
      TipCategory.strategy => Colors.blue,
      TipCategory.opening => Colors.orange,
      TipCategory.endgame => Colors.purple,
      TipCategory.tactics => Colors.red,
      TipCategory.psychology => Colors.green,
      TipCategory.advanced => Colors.pink,
    };
  }
}
