import 'dart:async';
import 'package:dio/dio.dart';
import 'package:logging/logging.dart';
import 'package:moeloaderflutter/downloader/downloader.dart';
import 'package:moeloaderflutter/model/download/download.dart';
import 'package:moeloaderflutter/repository/download_repository.dart';

abstract class DownloadEvent {
  final String taskId;
  DownloadEvent({required this.taskId});
}

class DownloadProgressEvent extends DownloadEvent {
  final int count;
  final int total;
  DownloadProgressEvent({
    required String taskId,
    required this.count,
    required this.total,
  }) : super(taskId: taskId);
}

class DownloadCompletedEvent extends DownloadEvent {
  DownloadCompletedEvent({required String taskId}) : super(taskId: taskId);
}

class DownloadFailedEvent extends DownloadEvent {
  final String error;
  DownloadFailedEvent({
    required String taskId,
    required this.error,
  }) : super(taskId: taskId);
}

class DownloadScheduler {
  final _log = Logger('DownloadScheduler');

  final DownloadRepository _repository;
  final Downloader _downloader;
  final int _maxConcurrentTasks;

  final Map<String, CancelToken> _activeTokens = {};
  final StreamController<DownloadEvent> _eventController =
      StreamController.broadcast();

  DownloadScheduler({
    required DownloadRepository repository,
    required Downloader downloader,
    int maxConcurrentTasks = 1,
  })  : _repository = repository,
        _downloader = downloader,
        _maxConcurrentTasks = maxConcurrentTasks {
    _init();
  }

  void _init() {
    _repository.watchTasks().listen((tasks) {
      _processQueue(tasks);
    });
  }

  void _processQueue(List<DownloadTask> tasks) {
    final activeCount = _activeTokens.length;
    final waitingTasks = tasks
        .where((t) => t.status == DownloadStatus.waiting)
        .toList();

    _log.fine(
        "Processing queue: active=$activeCount, waiting=${waitingTasks.length}, max=$_maxConcurrentTasks");

    while (activeCount < _maxConcurrentTasks && waitingTasks.isNotEmpty) {
      final task = waitingTasks.removeAt(0);
      _executeTask(task);
    }
  }

  Future<void> _executeTask(DownloadTask task) async {
    _log.fine("Executing task: ${task.id}");

    final cancelToken = CancelToken();
    _activeTokens[task.id] = cancelToken;

    try {
      await _repository.updateTask(task.copyWith(
        status: DownloadStatus.downloading,
        startedAt: DateTime.now(),
      ));

      final result = await _downloader.download(
        task,
        onProgress: (int count, int total) {
          _eventController.add(DownloadProgressEvent(
            taskId: task.id,
            count: count,
            total: total,
          ));

          _repository.updateTask(task.copyWith(
            count: count,
            total: total,
            status: count == total
                ? DownloadStatus.completed
                : DownloadStatus.downloading,
          ));
        },
        cancelToken: cancelToken,
      );

      if (result.success) {
        await _repository.updateTask(task.copyWith(
          status: DownloadStatus.completed,
          completedAt: DateTime.now(),
          count: task.total,
        ));

        _eventController.add(DownloadCompletedEvent(taskId: task.id));
      } else {
        await _repository.updateTask(task.copyWith(
          status: DownloadStatus.failed,
          errorMessage: result.error,
        ));

        _eventController.add(DownloadFailedEvent(
          taskId: task.id,
          error: result.error ?? 'Unknown error',
        ));
      }
    } catch (e) {
      _log.fine("Task execution error: $e");

      await _repository.updateTask(task.copyWith(
        status: DownloadStatus.failed,
        errorMessage: e.toString(),
      ));

      _eventController.add(DownloadFailedEvent(
        taskId: task.id,
        error: e.toString(),
      ));
    } finally {
      _activeTokens.remove(task.id);
    }
  }

  Stream<DownloadEvent> watchEvents() => _eventController.stream;

  void cancelTask(String taskId) {
    final token = _activeTokens[taskId];
    if (token != null && !token.isCancelled) {
      token.cancel();
      _log.fine("Cancelled task: $taskId");
    }
  }

  void dispose() {
    _eventController.close();
    for (var token in _activeTokens.values) {
      token.cancel();
    }
    _activeTokens.clear();
  }
}
