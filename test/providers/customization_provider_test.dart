import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:reversia/providers/customization_provider.dart';

void main() {
  group('CustomizationNotifier', () {
    late ProviderContainer container;

    setUp(() {
      container = ProviderContainer();
    });

    tearDown(() {
      container.dispose();
    });

    test('initial state selects the default (unlocked) board and piece styles', () {
      final state = container.read(customizationProvider);
      expect(state.selectedBoardStyleId, 'board_1');
      expect(state.selectedPieceStyleId, 'piece_1');
      expect(state.selectedBoardStyle?.isUnlocked, isTrue);
      expect(state.selectedPieceStyle?.isUnlocked, isTrue);
      expect(state.lockedBoardStyles, isNotEmpty);
      expect(state.lockedPieceStyles, isNotEmpty);
    });

    test('selectBoardStyle switches selection when the style is unlocked', () async {
      final notifier = container.read(customizationProvider.notifier);

      await notifier.selectBoardStyle('board_2');

      expect(container.read(customizationProvider).selectedBoardStyleId, 'board_2');
    });

    test('selectBoardStyle refuses a locked style and reports an error', () async {
      final notifier = container.read(customizationProvider.notifier);
      final locked = container.read(customizationProvider).lockedBoardStyles.first;

      await notifier.selectBoardStyle(locked.id);

      final state = container.read(customizationProvider);
      expect(state.selectedBoardStyleId, isNot(locked.id));
      expect(state.error, isNotNull);
    });

    test('selectPieceStyle refuses a locked style and reports an error', () async {
      final notifier = container.read(customizationProvider.notifier);
      final locked = container.read(customizationProvider).lockedPieceStyles.first;

      await notifier.selectPieceStyle(locked.id);

      final state = container.read(customizationProvider);
      expect(state.selectedPieceStyleId, isNot(locked.id));
      expect(state.error, isNotNull);
    });

    test('unlockBoardStyle unlocks the style so it can then be selected', () async {
      final notifier = container.read(customizationProvider.notifier);
      final locked = container.read(customizationProvider).lockedBoardStyles.first;

      await notifier.unlockBoardStyle(locked.id);

      final state = container.read(customizationProvider);
      expect(state.boardStyles.firstWhere((b) => b.id == locked.id).isUnlocked, isTrue);
      expect(state.isLoading, isFalse);
      expect(state.error, isNull);

      await notifier.selectBoardStyle(locked.id);
      expect(container.read(customizationProvider).selectedBoardStyleId, locked.id);
    });

    test('unlockPieceStyle unlocks the style so it can then be selected', () async {
      final notifier = container.read(customizationProvider.notifier);
      final locked = container.read(customizationProvider).lockedPieceStyles.first;

      await notifier.unlockPieceStyle(locked.id);

      final state = container.read(customizationProvider);
      expect(state.pieceStyles.firstWhere((p) => p.id == locked.id).isUnlocked, isTrue);

      await notifier.selectPieceStyle(locked.id);
      expect(container.read(customizationProvider).selectedPieceStyleId, locked.id);
    });

    test('toggle methods flip their respective boolean flags', () {
      final notifier = container.read(customizationProvider.notifier);
      final before = container.read(customizationProvider);

      notifier.toggleAnimations();
      notifier.toggleSoundEffects();
      notifier.toggleDarkMode();

      final after = container.read(customizationProvider);
      expect(after.enableAnimations, !before.enableAnimations);
      expect(after.enableSoundEffects, !before.enableSoundEffects);
      expect(after.darkModeEnabled, !before.darkModeEnabled);
    });

    test('setUIScale updates the scale value', () {
      final notifier = container.read(customizationProvider.notifier);
      notifier.setUIScale(1.2);
      expect(container.read(customizationProvider).uiScale, 1.2);
    });

    test("applyThemePreset selects the preset's board and piece styles", () async {
      final notifier = container.read(customizationProvider.notifier);
      final preset =
          container.read(customizationProvider).themePresets.firstWhere((t) => !t.isDefault);

      await notifier.applyThemePreset(preset.id);

      final state = container.read(customizationProvider);
      expect(state.selectedBoardStyleId, preset.boardStyleId);
      expect(state.selectedPieceStyleId, preset.pieceStyleId);
    });

    test('clearError resets a previously set error', () async {
      final notifier = container.read(customizationProvider.notifier);
      final locked = container.read(customizationProvider).lockedBoardStyles.first;
      await notifier.selectBoardStyle(locked.id);
      expect(container.read(customizationProvider).error, isNotNull);

      notifier.clearError();
      expect(container.read(customizationProvider).error, isNull);
    });
  });
}
