import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _defaultVideoOnlyMode = false;
  bool _usePublicDownloadDirectory = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _defaultVideoOnlyMode = prefs.getBool('default_video_only_mode') ?? false;
      _usePublicDownloadDirectory =
          prefs.getBool('use_public_download_directory') ?? true;
    });
  }

  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('default_video_only_mode', _defaultVideoOnlyMode);
    await prefs.setBool(
        'use_public_download_directory', _usePublicDownloadDirectory);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('设置')),
      body: ListView(
        children: [
          SwitchListTile(
            title: const Text('默认视频模式'),
            subtitle: const Text('打开后，视频播放页面将默认只显示视频元素'),
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
            subtitle: const Text('打开后，视频将下载到设备的"下载"文件夹中，关闭则下载到应用私有目录'),
            value: _usePublicDownloadDirectory,
            onChanged: (bool value) {
              setState(() {
                _usePublicDownloadDirectory = value;
              });
              _saveSettings();
            },
          ),
        ],
      ),
    );
  }
}
