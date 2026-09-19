import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Performance metric data
class PerformanceMetric {
  final String name;
  final double value;
  final String unit;
  final double targetValue;
  final bool isOptimal;

  const PerformanceMetric({
    required this.name,
    required this.value,
    required this.unit,
    required this.targetValue,
    required this.isOptimal,
  });

  double get percentageOfTarget => (value / targetValue) * 100;
}

/// Cache statistics
class CacheStats {
  final int cachedReplays;
  final int cachedProfiles;
  final int cachedLeaderboards;
  final int totalCacheSize;
  final int maxCacheSize;
  final double cacheHitRate;

  const CacheStats({
    required this.cachedReplays,
    required this.cachedProfiles,
    required this.cachedLeaderboards,
    required this.totalCacheSize,
    required this.maxCacheSize,
    required this.cacheHitRate,
  });

  double get cacheUtilization => (totalCacheSize / maxCacheSize) * 100;

  CacheStats copyWith({
    int? cachedReplays,
    int? cachedProfiles,
    int? cachedLeaderboards,
    int? totalCacheSize,
    double? cacheHitRate,
  }) {
    return CacheStats(
      cachedReplays: cachedReplays ?? this.cachedReplays,
      cachedProfiles: cachedProfiles ?? this.cachedProfiles,
      cachedLeaderboards: cachedLeaderboards ?? this.cachedLeaderboards,
      totalCacheSize: totalCacheSize ?? this.totalCacheSize,
      maxCacheSize: maxCacheSize,
      cacheHitRate: cacheHitRate ?? this.cacheHitRate,
    );
  }
}

/// Performance optimization state
class PerformanceOptimizationState {
  final List<PerformanceMetric> metrics;
  final CacheStats cacheStats;
  final bool enableOptimizations;
  final bool enableImageCaching;
  final bool enableAggressiveCaching;
  final int memoryUsageMB;
  final int maxMemoryMB;
  final double fps;
  final bool isMonitoring;
  final String? error;

  const PerformanceOptimizationState({
    required this.metrics,
    required this.cacheStats,
    required this.enableOptimizations,
    required this.enableImageCaching,
    required this.enableAggressiveCaching,
    required this.memoryUsageMB,
    required this.maxMemoryMB,
    required this.fps,
    required this.isMonitoring,
    this.error,
  });

  double get memoryUtilization => (memoryUsageMB / maxMemoryMB) * 100;

  bool get isMemoryHealthy => memoryUtilization < 80;

  bool get isPerformanceHealthy => fps > 50;

  PerformanceOptimizationState copyWith({
    List<PerformanceMetric>? metrics,
    CacheStats? cacheStats,
    bool? enableOptimizations,
    bool? enableImageCaching,
    bool? enableAggressiveCaching,
    int? memoryUsageMB,
    double? fps,
    bool? isMonitoring,
    Object? error = _unset,
  }) {
    return PerformanceOptimizationState(
      metrics: metrics ?? this.metrics,
      cacheStats: cacheStats ?? this.cacheStats,
      enableOptimizations: enableOptimizations ?? this.enableOptimizations,
      enableImageCaching: enableImageCaching ?? this.enableImageCaching,
      enableAggressiveCaching:
          enableAggressiveCaching ?? this.enableAggressiveCaching,
      memoryUsageMB: memoryUsageMB ?? this.memoryUsageMB,
      maxMemoryMB: maxMemoryMB,
      fps: fps ?? this.fps,
      isMonitoring: isMonitoring ?? this.isMonitoring,
      error: identical(error, _unset) ? this.error : error as String?,
    );
  }
}

/// Sentinel used by [PerformanceOptimizationState.copyWith] to distinguish
/// "field not passed" (keep current value) from "field explicitly passed as
/// null" (clear the value).
const Object _unset = Object();

/// Notifier for performance optimization
class PerformanceOptimizationNotifier
    extends StateNotifier<PerformanceOptimizationState> {
  PerformanceOptimizationNotifier()
      : super(PerformanceOptimizationState(
          metrics: _generateMetrics(),
          cacheStats: const CacheStats(
            cachedReplays: 45,
            cachedProfiles: 128,
            cachedLeaderboards: 8,
            totalCacheSize: 152,
            maxCacheSize: 512,
            cacheHitRate: 0.78,
          ),
          enableOptimizations: true,
          enableImageCaching: true,
          enableAggressiveCaching: false,
          memoryUsageMB: 256,
          maxMemoryMB: 512,
          fps: 58.5,
          isMonitoring: false,
        )) {
    _initialize();
  }

  static List<PerformanceMetric> _generateMetrics() {
    return [
      PerformanceMetric(
        name: 'フレームレート',
        value: 58.5,
        unit: 'FPS',
        targetValue: 60,
        isOptimal: true,
      ),
      PerformanceMetric(
        name: 'ロード時間',
        value: 1.2,
        unit: 's',
        targetValue: 2.0,
        isOptimal: true,
      ),
      PerformanceMetric(
        name: 'メモリ使用',
        value: 256,
        unit: 'MB',
        targetValue: 400,
        isOptimal: true,
      ),
      PerformanceMetric(
        name: 'キャッシュヒット率',
        value: 78,
        unit: '%',
        targetValue: 85,
        isOptimal: false,
      ),
    ];
  }

  void _initialize() {
    // Initialize performance monitoring
  }

  Future<void> clearCache() async {
    state = state.copyWith(isMonitoring: true);
    await Future.delayed(const Duration(milliseconds: 800));

    final clearedCache = state.cacheStats.copyWith(
      cachedReplays: 0,
      cachedProfiles: 0,
      cachedLeaderboards: 0,
      totalCacheSize: 0,
    );

    state = state.copyWith(
      cacheStats: clearedCache,
      isMonitoring: false,
      error: null,
    );
  }

  void toggleOptimizations() {
    state = state.copyWith(enableOptimizations: !state.enableOptimizations);
  }

  void toggleImageCaching() {
    state = state.copyWith(enableImageCaching: !state.enableImageCaching);
  }

  void toggleAggressiveCaching() {
    state = state.copyWith(
      enableAggressiveCaching: !state.enableAggressiveCaching,
    );
  }

  Future<void> optimizeMemory() async {
    state = state.copyWith(isMonitoring: true);
    await Future.delayed(const Duration(milliseconds: 1200));

    state = state.copyWith(
      memoryUsageMB: (state.memoryUsageMB * 0.7).toInt(),
      isMonitoring: false,
      error: null,
    );
  }

  Future<void> refreshMetrics() async {
    state = state.copyWith(isMonitoring: true);
    await Future.delayed(const Duration(milliseconds: 600));

    final updatedMetrics = _generateMetrics();
    state = state.copyWith(
      metrics: updatedMetrics,
      isMonitoring: false,
      error: null,
    );
  }

  void clearError() {
    state = state.copyWith(error: null);
  }
}

/// Riverpod provider for performance optimization
final performanceOptimizationProvider =
    StateNotifierProvider<PerformanceOptimizationNotifier,
        PerformanceOptimizationState>(
  (ref) => PerformanceOptimizationNotifier(),
);
