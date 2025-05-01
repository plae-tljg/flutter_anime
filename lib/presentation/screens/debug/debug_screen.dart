import 'package:flutter/material.dart';
import '../../../core/services/log_service.dart';

class DebugScreen extends StatefulWidget {
  const DebugScreen({Key? key}) : super(key: key);

  @override
  State<DebugScreen> createState() => _DebugScreenState();
}

class _DebugScreenState extends State<DebugScreen> {
  final LogService _logService = LogService();
  final ScrollController _scrollController = ScrollController();
  bool _autoScroll = true;

  @override
  void initState() {
    super.initState();
    // 添加一些测试日志
    _logService.info('调试页面已打开');
  }

  void _clearLogs() {
    _logService.clearLogs();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final logs = _logService.getLogHistory();

    return Scaffold(
      appBar: AppBar(
        title: const Text('调试信息'),
        actions: [
          IconButton(
            icon: Icon(
                _autoScroll ? Icons.auto_awesome : Icons.auto_awesome_mosaic),
            onPressed: () {
              setState(() {
                _autoScroll = !_autoScroll;
              });
            },
            tooltip: _autoScroll ? '关闭自动滚动' : '开启自动滚动',
          ),
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: _clearLogs,
            tooltip: '清除日志',
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              itemCount: logs.length,
              itemBuilder: (context, index) {
                final log = logs[index];
                return ListTile(
                  title: Text(
                    log,
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 12,
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }
}
