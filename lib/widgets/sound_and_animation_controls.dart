import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../engine/game_animations.dart';
import '../engine/sound_effects.dart';

/// Control panel for sound and animation settings
class SoundAndAnimationControls extends ConsumerWidget {
  final VoidCallback? onSettingsChanged;

  const SoundAndAnimationControls({
    Key? key,
    this.onSettingsChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.3),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Colors.white10,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Sound & Animation',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Sound toggle
              Expanded(
                child: _ControlButton(
                  icon: Icons.volume_up,
                  label: 'Sound',
                  isEnabled: true, // This would be bound to actual setting
                  onPressed: onSettingsChanged,
                ),
              ),
              const SizedBox(width: 8),
              // Animation toggle
              Expanded(
                child: _ControlButton(
                  icon: Icons.animation,
                  label: 'Animation',
                  isEnabled: true, // This would be bound to actual setting
                  onPressed: onSettingsChanged,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Individual control button
class _ControlButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isEnabled;
  final VoidCallback? onPressed;

  const _ControlButton({
    required this.icon,
    required this.label,
    required this.isEnabled,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: isEnabled ? Colors.blue[900]?.withOpacity(0.5) : Colors.grey[800]?.withOpacity(0.3),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: isEnabled ? Colors.blue[300]! : Colors.grey[700]!,
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: isEnabled ? Colors.blue[300] : Colors.grey[600],
            size: 16,
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: isEnabled ? Colors.white : Colors.white54,
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

/// Sound settings configuration panel
class SoundSettingsPanel extends StatefulWidget {
  final SoundSettings settings;
  final Function(SoundSettings) onSettingsChanged;

  const SoundSettingsPanel({
    Key? key,
    required this.settings,
    required this.onSettingsChanged,
  }) : super(key: key);

  @override
  State<SoundSettingsPanel> createState() => _SoundSettingsPanelState();
}

class _SoundSettingsPanelState extends State<SoundSettingsPanel> {
  late SoundSettings _localSettings;

  @override
  void initState() {
    super.initState();
    _localSettings = widget.settings;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Sound Settings',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Colors.white,
                ),
          ),
          const SizedBox(height: 16),

          // Sound effects toggle
          _SettingRow(
            label: 'Sound Effects',
            value: _localSettings.soundEnabled,
            onChanged: (value) {
              setState(() {
                _localSettings = _localSettings.copyWith(soundEnabled: value);
                widget.onSettingsChanged(_localSettings);
              });
            },
          ),
          const SizedBox(height: 12),

          // Master volume slider
          if (_localSettings.soundEnabled)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Master Volume',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                  ),
                ),
                Slider(
                  value: _localSettings.masterVolume,
                  onChanged: (value) {
                    setState(() {
                      _localSettings = _localSettings.copyWith(masterVolume: value);
                      widget.onSettingsChanged(_localSettings);
                    });
                  },
                ),
              ],
            ),

          const SizedBox(height: 16),

          // Music toggle
          _SettingRow(
            label: 'Background Music',
            value: _localSettings.musicEnabled,
            onChanged: (value) {
              setState(() {
                _localSettings = _localSettings.copyWith(musicEnabled: value);
                widget.onSettingsChanged(_localSettings);
              });
            },
          ),

          // Music volume slider
          if (_localSettings.musicEnabled)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 12),
                Text(
                  'Music Volume',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                  ),
                ),
                Slider(
                  value: _localSettings.musicVolume,
                  onChanged: (value) {
                    setState(() {
                      _localSettings = _localSettings.copyWith(musicVolume: value);
                      widget.onSettingsChanged(_localSettings);
                    });
                  },
                ),
              ],
            ),
        ],
      ),
    );
  }
}

/// Animation settings configuration panel
class AnimationSettingsPanel extends StatefulWidget {
  final AnimationConfig config;
  final Function(AnimationConfig) onConfigChanged;

  const AnimationSettingsPanel({
    Key? key,
    required this.config,
    required this.onConfigChanged,
  }) : super(key: key);

  @override
  State<AnimationSettingsPanel> createState() => _AnimationSettingsPanelState();
}

class _AnimationSettingsPanelState extends State<AnimationSettingsPanel> {
  late AnimationConfig _localConfig;

  @override
  void initState() {
    super.initState();
    _localConfig = widget.config;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Animation Settings',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Colors.white,
                ),
          ),
          const SizedBox(height: 16),

          // Animation toggle
          _SettingRow(
            label: 'Enable Animations',
            value: _localConfig.animationsEnabled,
            onChanged: (value) {
              setState(() {
                _localConfig = _localConfig.copyWith(animationsEnabled: value);
                widget.onConfigChanged(_localConfig);
              });
            },
          ),

          if (_localConfig.animationsEnabled) ...[
            const SizedBox(height: 16),

            // Animation speed control
            Text(
              'Animation Speed',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 12,
              ),
            ),
            Slider(
              value: _localConfig.speedMultiplier,
              min: 0.25,
              max: 2.0,
              divisions: 7,
              label: '${_localConfig.speedMultiplier.toStringAsFixed(2)}x',
              onChanged: (value) {
                setState(() {
                  _localConfig = _localConfig.copyWith(speedMultiplier: value);
                  widget.onConfigChanged(_localConfig);
                });
              },
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '0.25x (Slow)',
                  style: TextStyle(
                    color: Colors.white54,
                    fontSize: 10,
                  ),
                ),
                Text(
                  '2.0x (Fast)',
                  style: TextStyle(
                    color: Colors.white54,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

/// Individual setting row with toggle
class _SettingRow extends StatelessWidget {
  final String label;
  final bool value;
  final Function(bool) onChanged;

  const _SettingRow({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.white70,
            fontSize: 13,
          ),
        ),
        Switch(
          value: value,
          onChanged: onChanged,
          activeColor: Colors.blue[600],
          inactiveThumbColor: Colors.grey[700],
          inactiveTrackColor: Colors.grey[800],
        ),
      ],
    );
  }
}

/// Floating animation indicator for showing active animations
class AnimationIndicator extends StatelessWidget {
  final int activeAnimationCount;

  const AnimationIndicator({
    Key? key,
    required this.activeAnimationCount,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (activeAnimationCount == 0) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.purple[900]?.withOpacity(0.7),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.purple[400]!.withOpacity(0.5),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 8,
            height: 8,
            child: CircularProgressIndicator(
              strokeWidth: 1,
              valueColor: AlwaysStoppedAnimation<Color>(Colors.purple[300]!),
            ),
          ),
          const SizedBox(width: 6),
          Text(
            '$activeAnimationCount',
            style: TextStyle(
              color: Colors.purple[200],
              fontSize: 11,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
