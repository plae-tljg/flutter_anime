import 'package:flutter/material.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:permission_handler/permission_handler.dart';
import '../video_player/local_video_player_screen.dart';

class VideoLibraryScreen extends StatefulWidget {
  const VideoLibraryScreen({Key? key}) : super(key: key);

  @override
  State<VideoLibraryScreen> createState() => _VideoLibraryScreenState();
}

class _VideoLibraryScreenState extends State<VideoLibraryScreen> {
  List<FileSystemEntity> _videos = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadVideos();
  }

  Future<void> _loadVideos() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      // 请求存储权限
      final status = await Permission.storage.request();
      if (!status.isGranted) {
        throw Exception('需要存储权限才能访问视频');
      }

      // 获取下载目录
      final prefs = await SharedPreferences.getInstance();
      final usePublicDirectory =
          prefs.getBool('use_public_download_directory') ?? true;

      // 获取所有可能的下载目录
      final List<Directory> directories = [];

      // 添加公共下载目录
      if (usePublicDirectory) {
        directories.add(Directory('/storage/emulated/0/Download'));
      }

      // 添加应用私有目录
      final appDir = await getExternalStorageDirectory();
      if (appDir != null) {
        directories.add(Directory('${appDir.path}/Downloads'));
      }

      debugPrint('正在搜索以下目录:');
      for (var dir in directories) {
        debugPrint('- ${dir.path}');
      }

      // 获取所有视频文件
      List<FileSystemEntity> allFiles = [];
      for (var directory in directories) {
        if (await directory.exists()) {
          try {
            final files = await directory
                .list()
                .where((file) => file.path.toLowerCase().endsWith('.mp4'))
                .toList();
            debugPrint('在 ${directory.path} 中找到 ${files.length} 个视频文件');
            allFiles.addAll(files);
          } catch (e) {
            debugPrint('读取目录 ${directory.path} 失败: $e');
          }
        } else {
          debugPrint('目录不存在: ${directory.path}');
        }
      }

      debugPrint('总共找到 ${allFiles.length} 个视频文件');

      // 按修改时间排序（最新的在前）
      allFiles.sort(
          (a, b) => b.statSync().modified.compareTo(a.statSync().modified));

      setState(() {
        _videos = allFiles;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('加载视频列表失败: $e');
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _playVideo(FileSystemEntity file) async {
    if (!mounted) return;
    final index = _videos.indexOf(file);
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => LocalVideoPlayerScreen(
          videoFiles: _videos,
          initialIndex: index,
        ),
      ),
    );
  }

  Future<void> _deleteVideo(FileSystemEntity file) async {
    try {
      await File(file.path).delete();
      await _loadVideos(); // 重新加载视频列表
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('视频已删除')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('删除失败: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(_error!, style: const TextStyle(color: Colors.red)),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadVideos,
              child: const Text('重试'),
            ),
          ],
        ),
      );
    }

    if (_videos.isEmpty) {
      return const Center(
        child: Text('暂无下载的视频'),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadVideos,
      child: ListView.builder(
        itemCount: _videos.length,
        itemBuilder: (context, index) {
          final video = _videos[index];
          final fileName = video.path.split('/').last;
          final fileSize =
              (video.statSync().size / (1024 * 1024)).toStringAsFixed(1);
          final modifiedTime = video.statSync().modified;

          return ListTile(
            leading: const Icon(Icons.video_file),
            title: Text(fileName),
            subtitle: Text(
              '大小: ${fileSize}MB\n'
              '下载时间: ${modifiedTime.toString().split('.')[0]}',
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.play_arrow),
                  onPressed: () => _playVideo(video),
                ),
                IconButton(
                  icon: const Icon(Icons.delete),
                  onPressed: () => _deleteVideo(video),
                ),
              ],
            ),
            onTap: () => _playVideo(video),
          );
        },
      ),
    );
  }
}
