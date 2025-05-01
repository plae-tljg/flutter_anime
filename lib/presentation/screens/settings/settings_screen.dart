import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/services/log_service.dart';
import '../debug/debug_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('设置')),
      body: ListView(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.orange.withOpacity(0.1),
            child: const Row(
              children: [
                Icon(Icons.warning_amber_rounded, color: Colors.orange),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '以下功能为实验性功能，可能不稳定或无法正常工作',
                    style: TextStyle(color: Colors.orange),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          SwitchListTile(
            title: const Text('默认视频模式'),
            subtitle: const Text('打开后，视频播放页面将默认只显示视频元素（实验性功能）'),
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
            title: const Text('使用公共下载目录'),
            subtitle: const Text('打开后，视频将下载到设备的"下载"文件夹中，关闭则下载到应用私有目录（实验性功能）'),
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
            title: const Text('重置为默认设置'),
            subtitle: const Text('将所有设置恢复为默认值'),
            onTap: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('确认重置'),
                  content: const Text('确定要将所有设置恢复为默认值吗？'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('取消'),
                    ),
                    TextButton(
                      onPressed: () {
                        _resetToDefaults();
                        Navigator.pop(context);
                      },
                      child: const Text('确定'),
                    ),
                  ],
                ),
              );
            },
          ),
          ListTile(
            title: const Text('调试信息'),
            subtitle: const Text('查看应用日志和调试信息'),
            trailing: const Icon(Icons.bug_report),
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
