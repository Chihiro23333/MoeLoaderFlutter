import 'dart:async';
import 'package:hive/hive.dart';
import 'package:logging/logging.dart';
import 'package:moeloaderflutter/model/download/download.dart';
import 'package:moeloaderflutter/repository/download_repository.dart';

class DownloadRepositoryImpl implements DownloadRepository {
  final _log = Logger('DownloadRepositoryImpl');
  late Box _box;
  final StreamController<List<DownloadTask>> _tasksController =
      StreamController.broadcast();

  @override
  Future<void> init() async {
    _box = await Hive.openBox('download_tasks');
    final tasks = _loadTasks();
    _tasksController.add(tasks);
  }

  List<DownloadTask> _loadTasks() {
    try {
      final result = _box.values
          .where((json) => json != null)
          .map((json) {
            if (json is Map) {
              return DownloadTask.fromJson(_convertMap(json));
            }
            return null;
          })
          .where((task) => task != null)
          .cast<DownloadTask>()
          .toList();
      
      // 按创建时间倒序排序，最新的任务排在前面
      result.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      
      return result;
    } catch (e) {
      _log.severe("Failed to load tasks: $e");
      return [];
    }
  }

  Map<String, dynamic> _convertMap(dynamic json) {
    if (json is Map<String, dynamic>) {
      return json;
    } else if (json is Map) {
      return json.map((key, value) => MapEntry(key.toString(), value));
    }
    return {};
  }

  @override
  Future<void> addTask(DownloadTask task) async {
    _log.info("Repository adding task: id=${task.id}, name=${task.name}");
    await _box.put(task.id, task.toJson());
    _log.info("Task saved to Hive: id=${task.id}");
    final tasks = _loadTasks();
    _log.info("Repository loaded ${tasks.length} tasks");
    _tasksController.add(tasks);
    _log.info("Repository emitted new state with ${tasks.length} tasks");
  }

  @override
  Future<void> updateTask(DownloadTask task) async {
    await _box.put(task.id, task.toJson());
    final tasks = _loadTasks();
    _tasksController.add(tasks);
  }

  @override
  Future<void> removeTask(String taskId) async {
    await _box.delete(taskId);
    final tasks = _loadTasks();
    _tasksController.add(tasks);
  }

  @override
  Future<DownloadTask?> getTask(String taskId) async {
    final json = _box.get(taskId);
    if (json == null) return null;
    if (json is Map) {
      return DownloadTask.fromJson(_convertMap(json));
    }
    return null;
  }

  Future<List<DownloadTask>> getTasks() async {
    return _loadTasks();
  }

  @override
  Stream<List<DownloadTask>> watchTasks() async* {
    yield* _tasksController.stream;
  }

  @override
  Stream<DownloadState> watchState() async* {
    yield* watchTasks().map((tasks) => DownloadState(tasks: tasks));
  }

  @override
  Future<void> clearCompleted() async {
    final completedTasks = _loadTasks()
        .where((t) => t.status == DownloadStatus.completed)
        .toList();

    for (var task in completedTasks) {
      await _box.delete(task.id);
    }
    _tasksController.add(_loadTasks());
  }

  Future<void> dispose() async {
    await _tasksController.close();
    await _box.close();
  }
}
