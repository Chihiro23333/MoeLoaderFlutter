import 'download_task.dart';
import 'download_status.dart';

class DownloadState {
  final List<DownloadTask> tasks;

  DownloadState({this.tasks = const []});

  List<DownloadTask> get waitingTasks =>
      tasks.where((t) => t.status == DownloadStatus.waiting).toList();

  List<DownloadTask> get downloadingTasks =>
      tasks.where((t) => t.status == DownloadStatus.downloading).toList();

  List<DownloadTask> get completedTasks =>
      tasks.where((t) => t.status == DownloadStatus.completed).toList();

  List<DownloadTask> get failedTasks =>
      tasks.where((t) => t.status == DownloadStatus.failed).toList();

  int get waitingCount => waitingTasks.length;
  int get downloadingCount => downloadingTasks.length;
  int get completedCount => completedTasks.length;
  int get failedCount => failedTasks.length;

  bool get hasDownloading => downloadingCount > 0;

  DownloadTask? findTask(String id) {
    try {
      return tasks.firstWhere((t) => t.id == id);
    } catch (e) {
      return null;
    }
  }

  DownloadState copyWith({List<DownloadTask>? tasks}) {
    return DownloadState(
      tasks: tasks ?? this.tasks,
    );
  }
}
