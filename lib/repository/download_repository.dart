import '../model/download/download.dart';

abstract class DownloadRepository {
  Future<void> addTask(DownloadTask task);
  Future<void> updateTask(DownloadTask task);
  Future<void> removeTask(String taskId);
  Future<DownloadTask?> getTask(String taskId);
  Future<List<DownloadTask>> getTasks();
  Stream<List<DownloadTask>> watchTasks();
  Stream<DownloadState> watchState();
  Future<void> clearCompleted();
  Future<void> init();
}
