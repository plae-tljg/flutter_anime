enum DownloadStatus {
  pending,
  downloading,
  paused,
  completed,
  failed,
}

class DownloadItem {
  final String id;
  final String title;
  final String url;
  final String savePath;
  final double progress;
  final DownloadStatus status;
  final DateTime createdAt;
  final DateTime? completedAt;
  final String? errorMessage;
  final int totalBytes;
  final int receivedBytes;

  DownloadItem({
    required this.id,
    required this.title,
    required this.url,
    required this.savePath,
    this.progress = 0.0,
    this.status = DownloadStatus.pending,
    required this.createdAt,
    this.completedAt,
    this.errorMessage,
    this.totalBytes = 0,
    this.receivedBytes = 0,
  });

  DownloadItem copyWith({
    String? id,
    String? title,
    String? url,
    String? savePath,
    double? progress,
    DownloadStatus? status,
    DateTime? createdAt,
    DateTime? completedAt,
    String? errorMessage,
    int? totalBytes,
    int? receivedBytes,
  }) {
    return DownloadItem(
      id: id ?? this.id,
      title: title ?? this.title,
      url: url ?? this.url,
      savePath: savePath ?? this.savePath,
      progress: progress ?? this.progress,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      completedAt: completedAt ?? this.completedAt,
      errorMessage: errorMessage ?? this.errorMessage,
      totalBytes: totalBytes ?? this.totalBytes,
      receivedBytes: receivedBytes ?? this.receivedBytes,
    );
  }

  String get formattedSize {
    if (totalBytes == 0) return 'Unknown';
    return _formatBytes(totalBytes);
  }

  String get formattedProgress {
    return '${(progress * 100).toStringAsFixed(1)}%';
  }

  String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'url': url,
      'savePath': savePath,
      'progress': progress,
      'status': status.index,
      'createdAt': createdAt.toIso8601String(),
      'completedAt': completedAt?.toIso8601String(),
      'errorMessage': errorMessage,
      'totalBytes': totalBytes,
      'receivedBytes': receivedBytes,
    };
  }

  factory DownloadItem.fromJson(Map<String, dynamic> json) {
    return DownloadItem(
      id: json['id'] as String,
      title: json['title'] as String,
      url: json['url'] as String,
      savePath: json['savePath'] as String,
      progress: (json['progress'] as num).toDouble(),
      status: DownloadStatus.values[json['status'] as int],
      createdAt: DateTime.parse(json['createdAt'] as String),
      completedAt: json['completedAt'] != null
          ? DateTime.parse(json['completedAt'] as String)
          : null,
      errorMessage: json['errorMessage'] as String?,
      totalBytes: json['totalBytes'] as int? ?? 0,
      receivedBytes: json['receivedBytes'] as int? ?? 0,
    );
  }
}