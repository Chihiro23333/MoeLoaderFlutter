enum DownloadStatus {
  idle,
  waiting,
  downloading,
  completed,
  failed,
  paused,
}

extension DownloadStatusExtension on DownloadStatus {
  int get value {
    switch (this) {
      case DownloadStatus.idle:
        return 0;
      case DownloadStatus.waiting:
        return 1;
      case DownloadStatus.downloading:
        return 2;
      case DownloadStatus.completed:
        return 3;
      case DownloadStatus.failed:
        return 4;
      case DownloadStatus.paused:
        return 5;
    }
  }

  static DownloadStatus fromValue(int value) {
    switch (value) {
      case 0:
        return DownloadStatus.idle;
      case 1:
        return DownloadStatus.waiting;
      case 2:
        return DownloadStatus.downloading;
      case 3:
        return DownloadStatus.completed;
      case 4:
        return DownloadStatus.failed;
      case 5:
        return DownloadStatus.paused;
      default:
        return DownloadStatus.idle;
    }
  }
}
