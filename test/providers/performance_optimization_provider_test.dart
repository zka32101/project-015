import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:reversia/providers/performance_optimization_provider.dart';

void main() {
  group('PerformanceOptimizationNotifier', () {
    late ProviderContainer container;

    setUp(() {
      container = ProviderContainer();
    });

    tearDown(() {
      container.dispose();
    });

    test('initial state reports healthy memory and performance', () {
      final state = container.read(performanceOptimizationProvider);
      expect(state.metrics, isNotEmpty);
      expect(state.isMemoryHealthy, isTrue);
      expect(state.isPerformanceHealthy, isTrue);
      expect(state.memoryUtilization, closeTo(50, 0.01));
    });

    test('clearCache resets all cache stats to zero', () async {
      final notifier = container.read(performanceOptimizationProvider.notifier);

      await notifier.clearCache();

      final cache = container.read(performanceOptimizationProvider).cacheStats;
      expect(cache.cachedReplays, 0);
      expect(cache.cachedProfiles, 0);
      expect(cache.cachedLeaderboards, 0);
      expect(cache.totalCacheSize, 0);
      expect(container.read(performanceOptimizationProvider).isMonitoring, isFalse);
    });

    test('toggle methods flip their respective boolean flags', () {
      final notifier = container.read(performanceOptimizationProvider.notifier);
      final before = container.read(performanceOptimizationProvider);

      notifier.toggleOptimizations();
      notifier.toggleImageCaching();
      notifier.toggleAggressiveCaching();

      final after = container.read(performanceOptimizationProvider);
      expect(after.enableOptimizations, !before.enableOptimizations);
      expect(after.enableImageCaching, !before.enableImageCaching);
      expect(after.enableAggressiveCaching, !before.enableAggressiveCaching);
    });

    test('optimizeMemory reduces memory usage', () async {
      final notifier = container.read(performanceOptimizationProvider.notifier);
      final before = container.read(performanceOptimizationProvider).memoryUsageMB;

      await notifier.optimizeMemory();

      final state = container.read(performanceOptimizationProvider);
      expect(state.memoryUsageMB, lessThan(before));
      expect(state.isMonitoring, isFalse);
    });

    test('refreshMetrics repopulates the metrics list', () async {
      final notifier = container.read(performanceOptimizationProvider.notifier);

      await notifier.refreshMetrics();

      final state = container.read(performanceOptimizationProvider);
      expect(state.metrics, isNotEmpty);
      expect(state.isMonitoring, isFalse);
    });

    test('clearError resets the error field', () {
      final notifier = container.read(performanceOptimizationProvider.notifier);
      notifier.clearError();
      expect(container.read(performanceOptimizationProvider).error, isNull);
    });
  });
}
