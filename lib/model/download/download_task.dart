import 'download_status.dart';

class DownloadTask {
  final String id;
  final String url;
  final String name;
  final String? downloadUrl;
  final Map<String, String>? headers;
  final DownloadStatus status;
  final int count;
  final int total;
  final String? errorMessage;
  final DateTime createdAt;
  final DateTime? startedAt;
  final DateTime? completedAt;

  DownloadTask({
    required this.id,
    required this.url,
    required this.name,
    this.downloadUrl,
    this.headers,
    this.status = DownloadStatus.idle,
    this.count = 0,
    this.total = 0,
    this.errorMessage,
    DateTime? createdAt,
    this.startedAt,
    this.completedAt,
  }) : createdAt = createdAt ?? DateTime.now();

  double get progress {
    if (status == DownloadStatus.completed) return 1.0;
    if (total <= 0) return 0.0;
    return count / total;
  }

  DownloadTask copyWith({
    String? id,
    String? url,
    String? name,
    String? downloadUrl,
    Map<String, String>? headers,
    DownloadStatus? status,
    int? count,
    int? total,
    String? errorMessage,
    DateTime? createdAt,
    DateTime? startedAt,
    DateTime? completedAt,
  }) {
    return DownloadTask(
      id: id ?? this.id,
      url: url ?? this.url,
      name: name ?? this.name,
      downloadUrl: downloadUrl ?? this.downloadUrl,
      headers: headers ?? this.headers,
      status: status ?? this.status,
      count: count ?? this.count,
      total: total ?? this.total,
      errorMessage: errorMessage ?? this.errorMessage,
      createdAt: createdAt ?? this.createdAt,
      startedAt: startedAt ?? this.startedAt,
      completedAt: completedAt ?? this.completedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'url': url,
      'name': name,
      'downloadUrl': downloadUrl,
      'headers': headers,
      'status': status.value,
      'count': count,
      'total': total,
      'errorMessage': errorMessage,
      'createdAt': createdAt.toIso8601String(),
      'startedAt': startedAt?.toIso8601String(),
      'completedAt': completedAt?.toIso8601String(),
    };
  }

  factory DownloadTask.fromJson(Map<String, dynamic> json) {
    return DownloadTask(
      id: json['id'] as String,
      url: json['url'] as String,
      name: json['name'] as String,
      downloadUrl: json['downloadUrl'] as String?,
      headers: _convertHeaders(json['headers']),
      status: DownloadStatusExtension.fromValue(json['status'] as int),
      count: json['count'] as int? ?? 0,
      total: json['total'] as int? ?? 0,
      errorMessage: json['errorMessage'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      startedAt: json['startedAt'] != null
          ? DateTime.parse(json['startedAt'] as String)
          : null,
      completedAt: json['completedAt'] != null
          ? DateTime.parse(json['completedAt'] as String)
          : null,
    );
  }

  static Map<String, String>? _convertHeaders(dynamic headers) {
    if (headers == null) return null;
    if (headers is Map<String, String>) return headers;
    if (headers is Map) {
      return headers.map((key, value) => MapEntry(key.toString(), value.toString()));
    }
    return null;
  }

  static const int idle = 0;
  static const int waiting = 1;
  static const int downloading = 2;
  static const int complete = 3;
  static const int error = 4;
}
