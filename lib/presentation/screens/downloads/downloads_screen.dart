import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../domain/entities/download_item.dart';
import '../../../domain/services/download_manager.dart';
import '../../providers/anime_provider.dart';

class DownloadsScreen extends ConsumerStatefulWidget {
  const DownloadsScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<DownloadsScreen> createState() => _DownloadsScreenState();
}

class _DownloadsScreenState extends ConsumerState<DownloadsScreen> {
  final DownloadManager _downloadManager = DownloadManager();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Downloads'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => setState(() {}),
          ),
        ],
      ),
      body: StreamBuilder<Map<String, DownloadItem>>(
        stream: _downloadManager.downloadsStream,
        builder: (context, snapshot) {
          final downloads = snapshot.data?.values.toList() ?? [];

          if (downloads.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.download_done, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text('No downloads yet'),
                  SizedBox(height: 8),
                  Text(
                    'Downloads will appear here when you\ndownload videos from the player',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            );
          }

          final active = downloads.where((d) => d.status == DownloadStatus.downloading).toList();
          final completed = downloads.where((d) => d.status == DownloadStatus.completed).toList();
          final failed = downloads.where((d) => d.status == DownloadStatus.failed).toList();
          final paused = downloads.where((d) => d.status == DownloadStatus.paused).toList();

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              if (active.isNotEmpty) ...[
                _buildSectionHeader('Active Downloads', active.length),
                ...active.map((d) => _buildDownloadCard(d)),
              ],
              if (paused.isNotEmpty) ...[
                _buildSectionHeader('Paused', paused.length),
                ...paused.map((d) => _buildDownloadCard(d)),
              ],
              if (failed.isNotEmpty) ...[
                _buildSectionHeader('Failed', failed.length),
                ...failed.map((d) => _buildDownloadCard(d)),
              ],
              if (completed.isNotEmpty) ...[
                _buildSectionHeader('Completed', completed.length),
                ...completed.map((d) => _buildDownloadCard(d)),
              ],
            ],
          );
        },
      ),
    );
  }

  Widget _buildSectionHeader(String title, int count) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, top: 16),
      child: Row(
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.blue.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              count.toString(),
              style: const TextStyle(color: Colors.blue),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDownloadCard(DownloadItem item) {
    final dateFormat = DateFormat('yyyy-MM-dd HH:mm');

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _buildStatusIcon(item.status),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.title,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        item.status.name.toUpperCase(),
                        style: TextStyle(
                          color: _getStatusColor(item.status),
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                _buildActionButton(item),
              ],
            ),
            const SizedBox(height: 12),
            if (item.status == DownloadStatus.downloading) ...[
              LinearProgressIndicator(
                value: item.progress,
                backgroundColor: Colors.grey[200],
              ),
              const SizedBox(height: 8),
            ],
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildInfoRow('Progress', item.formattedProgress),
                      _buildInfoRow('Size', item.formattedSize),
                      _buildInfoRow('Started', dateFormat.format(item.createdAt)),
                      if (item.completedAt != null)
                        _buildInfoRow('Completed', dateFormat.format(item.completedAt!)),
                      if (item.errorMessage != null)
                        _buildInfoRow('Error', item.errorMessage!, isError: true),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Divider(),
            _buildInfoRow('URL', item.url, isSmall: true),
            _buildInfoRow('Save Path', item.savePath, isSmall: true),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, {bool isSmall = false, bool isError = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: isSmall ? 10 : 12,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: isSmall ? 10 : 12,
                color: isError ? Colors.red : null,
              ),
              maxLines: isSmall ? 1 : 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusIcon(DownloadStatus status) {
    IconData icon;
    Color color;

    switch (status) {
      case DownloadStatus.pending:
        icon = Icons.schedule;
        color = Colors.orange;
        break;
      case DownloadStatus.downloading:
        icon = Icons.downloading;
        color = Colors.blue;
        break;
      case DownloadStatus.paused:
        icon = Icons.pause_circle;
        color = Colors.grey;
        break;
      case DownloadStatus.completed:
        icon = Icons.check_circle;
        color = Colors.green;
        break;
      case DownloadStatus.failed:
        icon = Icons.error;
        color = Colors.red;
        break;
    }

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(icon, color: color, size: 24),
    );
  }

  Color _getStatusColor(DownloadStatus status) {
    switch (status) {
      case DownloadStatus.pending:
        return Colors.orange;
      case DownloadStatus.downloading:
        return Colors.blue;
      case DownloadStatus.paused:
        return Colors.grey;
      case DownloadStatus.completed:
        return Colors.green;
      case DownloadStatus.failed:
        return Colors.red;
    }
  }

  Widget _buildActionButton(DownloadItem item) {
    switch (item.status) {
      case DownloadStatus.downloading:
        return IconButton(
          icon: const Icon(Icons.pause),
          onPressed: () => _downloadManager.pauseDownload(item.id),
        );
      case DownloadStatus.paused:
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.play_arrow),
              onPressed: () => _downloadManager.resumeDownload(item.id),
            ),
            IconButton(
              icon: const Icon(Icons.close),
              onPressed: () => _downloadManager.cancelDownload(item.id),
            ),
          ],
        );
      case DownloadStatus.failed:
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: () => _downloadManager.retryDownload(item.id),
            ),
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: () => _downloadManager.cancelDownload(item.id),
            ),
          ],
        );
      case DownloadStatus.completed:
        return IconButton(
          icon: const Icon(Icons.delete_outline),
          onPressed: () => _downloadManager.cancelDownload(item.id),
        );
      default:
        return const SizedBox.shrink();
    }
  }
}