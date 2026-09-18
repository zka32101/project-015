import 'package:flutter_riverpod/flutter_riverpod.dart';

/// State for statistics overlay visibility
class StatisticsOverlayState {
  final bool isVisible;

  const StatisticsOverlayState({this.isVisible = false});

  StatisticsOverlayState copyWith({bool? isVisible}) {
    return StatisticsOverlayState(
      isVisible: isVisible ?? this.isVisible,
    );
  }
}

/// Notifier for managing statistics overlay visibility
class StatisticsOverlayNotifier extends StateNotifier<StatisticsOverlayState> {
  StatisticsOverlayNotifier() : super(const StatisticsOverlayState());

  void toggleVisibility() {
    state = state.copyWith(isVisible: !state.isVisible);
  }

  void setVisibility(bool visible) {
    state = state.copyWith(isVisible: visible);
  }

  void show() {
    state = state.copyWith(isVisible: true);
  }

  void hide() {
    state = state.copyWith(isVisible: false);
  }
}

/// Provider for statistics overlay state
final statisticsOverlayProvider =
    StateNotifierProvider<StatisticsOverlayNotifier, StatisticsOverlayState>(
  (ref) => StatisticsOverlayNotifier(),
);
