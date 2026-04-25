import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../providers/anime_provider.dart';
import '../debug/debug_screen.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  bool _defaultVideoOnlyMode = true;
  bool _usePublicDownloadDirectory = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _defaultVideoOnlyMode = prefs.getBool('default_video_only_mode') ?? true;
      _usePublicDownloadDirectory =
          prefs.getBool('use_public_download_directory') ?? false;
    });
  }

  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('default_video_only_mode', _defaultVideoOnlyMode);
    await prefs.setBool(
        'use_public_download_directory', _usePublicDownloadDirectory);
  }

  Future<void> _resetToDefaults() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('default_video_only_mode', true);
    await prefs.setBool('use_public_download_directory', false);
    await _loadSettings();
  }

  void _showSourceSelector() {
    final sourceOptions = ref.read(availableSourcesProvider);

    showModalBottomSheet(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Padding(
                padding: EdgeInsets.all(16),
                child: Text(
                  'Select Anime Source',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
              ...sourceOptions.map((option) => ListTile(
                leading: Icon(
                  option.type == SourceType.config
                      ? Icons.settings_applications
                      : Icons.public,
                ),
                title: Text(option.name),
                subtitle: Text(
                  option.type == SourceType.config
                      ? 'Config-based (editable JSON)'
                      : 'Dart implementation',
                ),
                onTap: () {
                  ref.read(animeNotifierProvider.notifier).switchSourceByName(option.id);
                  Navigator.pop(context);
                },
              )),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentSource = ref.watch(currentSourceProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.orange.withValues(alpha: 0.1),
            child: const Row(
              children: [
                Icon(Icons.warning_amber_rounded, color: Colors.orange),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Experimental features may be unstable',
                    style: TextStyle(color: Colors.orange),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          ListTile(
            leading: const Icon(Icons.source),
            title: const Text('Anime Source'),
            subtitle: Text('Current: ${currentSource.name}'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: _showSourceSelector,
          ),
          const Divider(),
          SwitchListTile(
            title: const Text('Default Video Mode'),
            subtitle: const Text('Auto-show video-only mode on playback'),
            value: _defaultVideoOnlyMode,
            onChanged: (bool value) {
              setState(() {
                _defaultVideoOnlyMode = value;
              });
              _saveSettings();
            },
          ),
          const Divider(),
          SwitchListTile(
            title: const Text('Use Public Downloads'),
            subtitle: const Text('Save to device Downloads folder'),
            value: _usePublicDownloadDirectory,
            onChanged: (bool value) {
              setState(() {
                _usePublicDownloadDirectory = value;
              });
              _saveSettings();
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.restore),
            title: const Text('Reset to Defaults'),
            onTap: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Confirm Reset'),
                  content: const Text('Reset all settings to defaults?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancel'),
                    ),
                    TextButton(
                      onPressed: () {
                        _resetToDefaults();
                        Navigator.pop(context);
                      },
                      child: const Text('Confirm'),
                    ),
                  ],
                ),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.bug_report),
            title: const Text('Debug Info'),
            subtitle: const Text('View app logs and debug information'),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const DebugScreen(),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}