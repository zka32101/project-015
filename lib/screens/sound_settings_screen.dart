import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/sound_settings_provider.dart';

class SoundSettingsScreen extends ConsumerWidget {
  const SoundSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final soundSettingsAsync = ref.watch(soundSettingsProvider);
    final theme = Theme.of(context);

    return soundSettingsAsync.when(
      data: (soundState) {
        final settings = soundState.audioSettings;

        return Scaffold(
          backgroundColor: theme.scaffoldBackgroundColor,
          appBar: AppBar(
            title: const Text('音声設定'),
            elevation: 0,
          ),
          body: SingleChildScrollView(
            child: Column(
              children: [
                // Master controls
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: _SettingSection(
                    title: 'マスターコントロール',
                    children: [
                      _SwitchSetting(
                        icon: Icons.notifications_active,
                        label: 'サウンド効果',
                        value: settings.soundEnabled,
                        onChanged: (value) {
                          ref
                              .read(soundSettingsProvider.notifier)
                              .toggleSound(value);
                        },
                      ),
                      _SwitchSetting(
                        icon: Icons.music_note,
                        label: 'BGM',
                        value: settings.musicEnabled,
                        onChanged: (value) {
                          ref
                              .read(soundSettingsProvider.notifier)
                              .toggleMusic(value);
                        },
                      ),
                      _SwitchSetting(
                        icon: Icons.vibration,
                        label: 'バイブレーション',
                        value: settings.vibrationEnabled,
                        onChanged: (value) {
                          ref
                              .read(soundSettingsProvider.notifier)
                              .toggleVibration(value);
                        },
                      ),
                    ],
                  ),
                ),
                const Divider(),

                // Volume control
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'ボリューム',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      _VolumeSlider(
                        icon: Icons.notifications_active,
                        label: 'サウンド効果音量',
                        value: settings.soundVolume,
                        onChanged: (value) {
                          ref
                              .read(soundSettingsProvider.notifier)
                              .setSoundVolume(value);
                        },
                      ),
                      const SizedBox(height: 16),
                      _VolumeSlider(
                        icon: Icons.music_note,
                        label: 'BGM音量',
                        value: settings.musicVolume,
                        onChanged: (value) {
                          ref
                              .read(soundSettingsProvider.notifier)
                              .setMusicVolume(value);
                        },
                      ),
                    ],
                  ),
                ),
                const Divider(),

                // Additional settings
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: _SettingSection(
                    title: 'その他の設定',
                    children: [
                      _SwitchSetting(
                        icon: Icons.phone_in_talk,
                        label: '通話中にミュート',
                        value: settings.muteDuringCalls,
                        onChanged: (value) {
                          ref
                              .read(soundSettingsProvider.notifier)
                              .toggleMuteDuringCalls(value);
                        },
                      ),
                      _SwitchSetting(
                        icon: Icons.vibration,
                        label: 'サイレントモード時にミュート',
                        value: settings.muteWhenSilent,
                        onChanged: (value) {
                          ref
                              .read(soundSettingsProvider.notifier)
                              .toggleMuteWhenSilent(value);
                        },
                      ),
                    ],
                  ),
                ),
                const Divider(),

                // Sound effects control
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'サウンド効果',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      ..._buildSoundEffectToggles(
                        settings,
                        ref,
                        theme,
                      ),
                    ],
                  ),
                ),
                const Divider(),

                // Music tracks control
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'BGM',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      ..._buildMusicTrackToggles(
                        settings,
                        ref,
                        theme,
                      ),
                    ],
                  ),
                ),

                // Reset button
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: ElevatedButton.icon(
                    onPressed: () {
                      ref
                          .read(soundSettingsProvider.notifier)
                          .resetToDefaults();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('デフォルト設定にリセット'),
                          duration: Duration(seconds: 2),
                        ),
                      );
                    },
                    icon: const Icon(Icons.refresh),
                    label: const Text('デフォルト設定にリセット'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey.shade600,
                      minimumSize: const Size.fromHeight(48),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        );
      },
      loading: () => Scaffold(
        appBar: AppBar(title: const Text('音声設定')),
        body: const Center(child: CircularProgressIndicator()),
      ),
      error: (error, stack) => Scaffold(
        appBar: AppBar(title: const Text('音声設定')),
        body: Center(child: Text('エラー: $error')),
      ),
    );
  }

  List<Widget> _buildSoundEffectToggles(
    AudioSettings settings,
    WidgetRef ref,
    ThemeData theme,
  ) {
    return SoundEffect.values.map((effect) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: _SwitchSetting(
          icon: Icons.volume_up,
          label: effect.label,
          value: settings.enabledSounds[effect] ?? true,
          onChanged: (value) {
            ref
                .read(soundSettingsProvider.notifier)
                .toggleSoundEffect(effect, value);
          },
          compact: true,
        ),
      );
    }).toList();
  }

  List<Widget> _buildMusicTrackToggles(
    AudioSettings settings,
    WidgetRef ref,
    ThemeData theme,
  ) {
    return MusicTrack.values.map((track) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: _SwitchSetting(
          icon: Icons.music_note,
          label: track.label,
          value: settings.enabledMusic[track] ?? true,
          onChanged: (value) {
            ref
                .read(soundSettingsProvider.notifier)
                .toggleMusicTrack(track, value);
          },
          compact: true,
        ),
      );
    }).toList();
  }
}

/// Setting section container
class _SettingSection extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _SettingSection({
    required this.title,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        ...children,
      ],
    );
  }
}

/// Switch setting widget
class _SwitchSetting extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;
  final bool compact;

  const _SwitchSetting({
    required this.icon,
    required this.label,
    required this.value,
    required this.onChanged,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 12 : 16,
        vertical: compact ? 8 : 12,
      ),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Colors.grey.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(icon, size: compact ? 20 : 24),
              const SizedBox(width: 12),
              Text(
                label,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: compact ? FontWeight.normal : FontWeight.w500,
                ),
              ),
            ],
          ),
          Switch(
            value: value,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}

/// Volume slider widget
class _VolumeSlider extends StatelessWidget {
  final IconData icon;
  final String label;
  final double value;
  final ValueChanged<double> onChanged;

  const _VolumeSlider({
    required this.icon,
    required this.label,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Colors.grey.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon),
              const SizedBox(width: 8),
              Text(
                label,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
              const Spacer(),
              Text(
                '${(value * 100).toInt()}%',
                style: theme.textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Slider(
            value: value,
            onChanged: onChanged,
            min: 0.0,
            max: 1.0,
            divisions: 10,
            label: '${(value * 100).toInt()}%',
          ),
        ],
      ),
    );
  }
}
