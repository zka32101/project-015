import 'package:flutter/material.dart';

import '../engine/board_theme.dart';
import '../engine/preferences.dart';
import '../engine/sound_manager.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late bool _soundEnabled;
  late bool _hapticEnabled;
  late bool _threatPreviewEnabled;
  late bool _animationsEnabled;
  late int _aiMoveDelayMs;
  late bool _showPieceCount;
  late bool _autoSaveGames;

  @override
  void initState() {
    super.initState();
    final prefs = AppPreferences();
    _soundEnabled = prefs.isSoundEnabled;
    _hapticEnabled = prefs.isHapticEnabled;
    _threatPreviewEnabled = prefs.isThreatPreviewEnabled;
    _animationsEnabled = prefs.isAnimationsEnabled;
    _aiMoveDelayMs = prefs.aiMoveDelayMs;
    _showPieceCount = prefs.showPieceCount;
    _autoSaveGames = prefs.autoSaveGames;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('設定'),
      ),
      body: ListView(
        children: [
          // Audio Settings
          _SettingsSection(
            title: 'オーディオ',
            children: [
              _SettingsTile(
                title: 'サウンドエフェクト',
                subtitle: _soundEnabled ? 'オン' : 'オフ',
                value: _soundEnabled,
                onChanged: (value) async {
                  setState(() => _soundEnabled = value);
                  await AppPreferences().setSoundEnabled(value);
                  SoundManager().setSoundEnabled(value);
                },
              ),
              _SettingsTile(
                title: 'ハプティクスフィードバック',
                subtitle: _hapticEnabled ? 'オン' : 'オフ',
                value: _hapticEnabled,
                onChanged: (value) async {
                  setState(() => _hapticEnabled = value);
                  await AppPreferences().setHapticEnabled(value);
                },
              ),
            ],
          ),
          const Divider(),
          // Gameplay Settings
          _SettingsSection(
            title: 'ゲームプレイ',
            children: [
              _SettingsTile(
                title: '透け読みモード',
                subtitle: _threatPreviewEnabled
                    ? '相手の次手を表示'
                    : '相手の次手を非表示',
                value: _threatPreviewEnabled,
                onChanged: (value) async {
                  setState(() => _threatPreviewEnabled = value);
                  await AppPreferences().setThreatPreviewEnabled(value);
                },
              ),
              _SettingsTile(
                title: '駒数表示',
                subtitle: _showPieceCount ? '表示' : '非表示',
                value: _showPieceCount,
                onChanged: (value) async {
                  setState(() => _showPieceCount = value);
                  await AppPreferences().setShowPieceCount(value);
                },
              ),
              _SettingsTile(
                title: 'アニメーション',
                subtitle: _animationsEnabled ? 'オン' : 'オフ',
                value: _animationsEnabled,
                onChanged: (value) async {
                  setState(() => _animationsEnabled = value);
                  await AppPreferences().setAnimationsEnabled(value);
                },
              ),
            ],
          ),
          const Divider(),
          // AI Settings
          _SettingsSection(
            title: 'AI設定',
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('AI移動速度'),
                        Text('${_aiMoveDelayMs}ms'),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Slider(
                      value: _aiMoveDelayMs.toDouble(),
                      min: 100,
                      max: 2000,
                      divisions: 19,
                      label: '${_aiMoveDelayMs}ms',
                      onChanged: (value) async {
                        setState(() => _aiMoveDelayMs = value.toInt());
                        await AppPreferences().setAiMoveDelayMs(value.toInt());
                      },
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '低いほど高速、高いほど低速です',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const Divider(),
          // Data Settings
          _SettingsSection(
            title: 'データ',
            children: [
              _SettingsTile(
                title: 'ゲーム自動保存',
                subtitle: _autoSaveGames ? 'オン' : 'オフ',
                value: _autoSaveGames,
                onChanged: (value) async {
                  setState(() => _autoSaveGames = value);
                  await AppPreferences().setAutoSaveGames(value);
                },
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: ElevatedButton.icon(
                  onPressed: _showResetDialog,
                  icon: const Icon(Icons.refresh),
                  label: const Text('設定をリセット'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red.shade700,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showResetDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('設定をリセット'),
        content: const Text('すべての設定をデフォルトにリセットしますか？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('キャンセル'),
          ),
          TextButton(
            onPressed: () async {
              await AppPreferences().resetAll();
              if (mounted) {
                Navigator.pop(context);
                setState(() {
                  _soundEnabled = true;
                  _hapticEnabled = true;
                  _threatPreviewEnabled = false;
                  _animationsEnabled = true;
                  _aiMoveDelayMs = 500;
                  _showPieceCount = true;
                  _autoSaveGames = true;
                });
              }
            },
            child: const Text('リセット'),
          ),
        ],
      ),
    );
  }
}

class _SettingsSection extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _SettingsSection({
    required this.title,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
        ),
        ...children,
      ],
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _SettingsTile({
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: Switch(
        value: value,
        onChanged: onChanged,
      ),
    );
  }
}
