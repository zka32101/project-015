import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/performance_optimization_provider.dart';

class PerformanceOptimizationScreen extends ConsumerWidget {
  const PerformanceOptimizationScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final perfState = ref.watch(performanceOptimizationProvider);
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('パフォーマンス'),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'メトリクスを更新',
            onPressed: () =>
                ref.read(performanceOptimizationProvider.notifier).refreshMetrics(),
          ),
        ],
      ),
      body: ListView(
        children: [
          _SystemHealthCard(perfState: perfState),
          _MemoryMetricsCard(perfState: perfState),
          _CacheStatsCard(perfState: perfState),
          _PerformanceMetricsCard(perfState: perfState),
          _OptimizationSettingsCard(perfState: perfState),
        ],
      ),
    );
  }
}

class _SystemHealthCard extends ConsumerWidget {
  final PerformanceOptimizationState perfState;

  const _SystemHealthCard({required this.perfState});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final memoryHealthy = perfState.isMemoryHealthy;
    final perfHealthy = perfState.isPerformanceHealthy;

    return Card(
      margin: const EdgeInsets.all(8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'システム状態',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _HealthIndicator(
                  label: 'メモリ',
                  isHealthy: memoryHealthy,
                  value: '${perfState.memoryUtilization.toStringAsFixed(1)}%',
                ),
                _HealthIndicator(
                  label: 'パフォーマンス',
                  isHealthy: perfHealthy,
                  value: '${perfState.fps.toStringAsFixed(1)} FPS',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _MemoryMetricsCard extends ConsumerWidget {
  final PerformanceOptimizationState perfState;

  const _MemoryMetricsCard({required this.perfState});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.all(8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'メモリ使用状況',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '${perfState.memoryUsageMB}MB / ${perfState.maxMemoryMB}MB',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: perfState.memoryUtilization / 100,
                minHeight: 8,
                backgroundColor: Colors.grey.shade300,
                valueColor: AlwaysStoppedAnimation(
                  perfState.isMemoryHealthy
                      ? Colors.green.shade500
                      : Colors.red.shade500,
                ),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton.tonal(
                onPressed: () =>
                    ref.read(performanceOptimizationProvider.notifier).optimizeMemory(),
                child: const Text('メモリを最適化'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CacheStatsCard extends ConsumerWidget {
  final PerformanceOptimizationState perfState;

  const _CacheStatsCard({required this.perfState});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final cache = perfState.cacheStats;

    return Card(
      margin: const EdgeInsets.all(8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'キャッシュ統計',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '${cache.totalCacheSize}MB / ${cache.maxCacheSize}MB',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: cache.cacheUtilization / 100,
                minHeight: 6,
                backgroundColor: Colors.grey.shade300,
                valueColor: AlwaysStoppedAnimation(Colors.blue.shade500),
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
                      'キャッシュヒット率',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: Colors.grey.shade600,
                      ),
                    ),
                    Text(
                      '${(cache.cacheHitRate * 100).toStringAsFixed(1)}%',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'キャッシュ内容',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: Colors.grey.shade600,
                      ),
                    ),
                    Text(
                      'リプレイ: ${cache.cachedReplays} | プロフィール: ${cache.cachedProfiles}',
                      style: theme.textTheme.labelSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: FilledButton.tonal(
                onPressed: () =>
                    ref.read(performanceOptimizationProvider.notifier).clearCache(),
                child: const Text('キャッシュをクリア'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PerformanceMetricsCard extends StatelessWidget {
  final PerformanceOptimizationState perfState;

  const _PerformanceMetricsCard({required this.perfState});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.all(8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'パフォーマンスメトリクス',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            ...perfState.metrics.map((metric) =>
                _MetricRow(metric: metric)),
          ],
        ),
      ),
    );
  }
}

class _OptimizationSettingsCard extends ConsumerWidget {
  final PerformanceOptimizationState perfState;

  const _OptimizationSettingsCard({required this.perfState});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.all(8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '最適化設定',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            ListTile(
              dense: true,
              title: const Text('パフォーマンス最適化'),
              subtitle: const Text('フレームスキップとメモリ管理を有効化'),
              trailing: Switch(
                value: perfState.enableOptimizations,
                onChanged: (_) =>
                    ref.read(performanceOptimizationProvider.notifier)
                        .toggleOptimizations(),
              ),
            ),
            ListTile(
              dense: true,
              title: const Text('画像キャッシング'),
              subtitle: const Text('読み込んだ画像をメモリに保存'),
              trailing: Switch(
                value: perfState.enableImageCaching,
                onChanged: (_) =>
                    ref.read(performanceOptimizationProvider.notifier)
                        .toggleImageCaching(),
              ),
            ),
            ListTile(
              dense: true,
              title: const Text('積極的キャッシング'),
              subtitle: const Text('予測的データプリロード'),
              trailing: Switch(
                value: perfState.enableAggressiveCaching,
                onChanged: (_) =>
                    ref.read(performanceOptimizationProvider.notifier)
                        .toggleAggressiveCaching(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HealthIndicator extends StatelessWidget {
  final String label;
  final bool isHealthy;
  final String value;

  const _HealthIndicator({
    required this.label,
    required this.isHealthy,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      children: [
        Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            color: isHealthy ? Colors.green.shade100 : Colors.red.shade100,
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Icon(
              isHealthy ? Icons.check_circle : Icons.error,
              color: isHealthy ? Colors.green.shade700 : Colors.red.shade700,
              size: 32,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: theme.textTheme.labelSmall,
        ),
        Text(
          value,
          style: theme.textTheme.labelMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}

class _MetricRow extends StatelessWidget {
  final PerformanceMetric metric;

  const _MetricRow({required this.metric});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                metric.name,
                style: theme.textTheme.labelMedium,
              ),
              Text(
                '${metric.value.toStringAsFixed(1)} ${metric.unit}',
                style: theme.textTheme.labelSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: metric.isOptimal
                  ? Colors.green.shade100
                  : Colors.yellow.shade100,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              metric.isOptimal ? '最適' : '要改善',
              style: theme.textTheme.labelSmall?.copyWith(
                color: metric.isOptimal
                    ? Colors.green.shade700
                    : Colors.yellow.shade700,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
