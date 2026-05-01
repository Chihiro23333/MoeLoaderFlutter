import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:logging/logging.dart';
import 'package:moeloaderflutter/downloader/downloader.dart';
import 'package:moeloaderflutter/generated/json/base/json_convert_content.dart';
import 'package:moeloaderflutter/model/detail_page_entity.dart';
import 'package:moeloaderflutter/model/download/download.dart';
import 'package:moeloaderflutter/net/request_manager.dart';
import 'package:moeloaderflutter/repository/download_repository.dart';
import 'package:moeloaderflutter/repository/download_repository_impl.dart';
import 'package:moeloaderflutter/scheduler/download_scheduler.dart';
import 'package:moeloaderflutter/ui/viewmodel/connector_impl.dart';
import 'package:moeloaderflutter/util/const.dart';
import 'package:moeloaderflutter/util/sharedpreferences_utils.dart';
import 'package:moeloaderflutter/util/utils.dart';
import 'package:to_json/request.dart';
import 'package:to_json/request_factory.dart';
import 'package:to_json/yaml_parser_base.dart';
import 'package:to_json/yaml_rule_factory.dart';
import 'package:yaml/yaml.dart';
import '../init.dart';
import '../repo/yaml_reposotory.dart';

class DownloadManager {
  final _log = Logger("DownloadManager");

  static DownloadManager? _cache;
  static Completer<void>? _initCompleter;
  static bool _isInitializing = false;

  late final DownloadRepository _repository;
  late final Downloader _downloader;
  late final DownloadScheduler _scheduler;
  late final StreamSubscription<List<DownloadTask>> _tasksSubscription;
  late final StreamSubscription<DownloadEvent> _eventSubscription;

  final StreamController<DownloadState> _streamDownloadController =
      StreamController.broadcast();
  late DownloadState _downloadState;

  final YamlRepository _yamlRepository = YamlRepository();

  DownloadManager._create() {
    _init();
  }

  factory DownloadManager() {
    return _cache ?? (_cache = DownloadManager._create());
  }

  Future<void> _init() async {
    _repository = DownloadRepositoryImpl();
    await _repository.init();
    
    // 初始化状态
    _downloadState = DownloadState();
    
    // 先加载初始数据
    final initialTasks = await _repository.getTasks();
    _updateState(initialTasks);

    _downloader = Downloader();
    _scheduler = DownloadScheduler(
      repository: _repository,
      downloader: _downloader,
      maxConcurrentTasks: 1,
    );

    _tasksSubscription = _repository.watchTasks().listen((tasks) {
      _updateState(tasks);
    });

    _eventSubscription = _scheduler.watchEvents().listen(_handleEvent);
    
    _initCompleter?.complete();
  }

  static Future<void> ensureInitialized() async {
    if (_cache != null && _initCompleter != null) {
      await _initCompleter!.future;
      return;
    }
    
    if (_isInitializing && _initCompleter != null) {
      await _initCompleter!.future;
      return;
    }
    
    _isInitializing = true;
    _initCompleter = Completer<void>();
    _cache = DownloadManager._create();
    await _initCompleter!.future;
  }

  void _updateState(List<DownloadTask> tasks) {
    _downloadState = DownloadState(tasks: tasks);
    _streamDownloadController.add(_downloadState);
  }

  void _handleEvent(DownloadEvent event) {
    if (event is DownloadCompletedEvent) {
      // 下载完成事件
    } else if (event is DownloadFailedEvent) {
      _log.severe("Download failed: ${event.taskId}, error: ${event.error}");
    }
  }

  Future<void> addTask(DownloadTask task) async {
    await ensureInitialized();
    
    _log.info("Adding task: url=${task.url}, name=${task.name}");

    // 生成唯一 ID：使用时间戳 + URL 的哈希
    final uniqueId = '${DateTime.now().millisecondsSinceEpoch}_${task.url.hashCode}';
    final taskWithUniqueId = task.copyWith(id: uniqueId);
    
    _log.info("Generated unique ID: $uniqueId");

    DownloadTask newTask;
    if (isImageUrl(task.url)) {
      newTask = taskWithUniqueId.copyWith(
        status: DownloadStatus.waiting,
        downloadUrl: task.url,
      );
    } else {
      newTask = taskWithUniqueId.copyWith(status: DownloadStatus.waiting);
      newTask = await _resolveDownloadUrl(newTask);
    }

    await _repository.addTask(newTask);
    _log.info("Task added successfully: id=${newTask.id}");
  }

  Future<DownloadTask> _resolveDownloadUrl(DownloadTask task) async {
    try {
      YamlMap doc = await YamlRuleFactory().create(Global.curWebPageName);
      var request = _request();

      String json = await request.request(doc, "detailPage",
          connector: ConnectorImpl(_yamlRepository));

      var decode = jsonDecode(json);
      if (decode["code"] == Parser.success) {
        DetailPageEntity detailPageEntity =
            jsonConvert.convert<DetailPageEntity>(decode["data"]) ??
                DetailPageEntity();

        String downloadUrl = "";
        String previewUrl = detailPageEntity.url;
        String? rawUrl = detailPageEntity.rawUrl;
        String? bigUrl = detailPageEntity.bigUrl;
        String? downloadFileSize = await getDownloadFileSize();

        switch (downloadFileSize) {
          case Const.preview:
            if (downloadUrl.isEmpty) downloadUrl = previewUrl;
            if (downloadUrl.isEmpty) downloadUrl = bigUrl;
            if (downloadUrl.isEmpty) downloadUrl = rawUrl;
            break;
          case Const.big:
            if (downloadUrl.isEmpty) downloadUrl = bigUrl;
            if (downloadUrl.isEmpty) downloadUrl = rawUrl;
            if (downloadUrl.isEmpty) downloadUrl = previewUrl;
            break;
          case Const.raw:
          default:
            if (downloadUrl.isEmpty) downloadUrl = rawUrl;
            if (downloadUrl.isEmpty) downloadUrl = bigUrl;
            if (downloadUrl.isEmpty) downloadUrl = previewUrl;
            break;
        }

        return task.copyWith(downloadUrl: downloadUrl);
      } else {
        return task.copyWith(
          status: DownloadStatus.failed,
          errorMessage: "Failed to resolve download URL",
        );
      }
    } catch (e) {
      _log.severe("Error resolving download URL: $e");
      return task.copyWith(
        status: DownloadStatus.failed,
        errorMessage: e.toString(),
      );
    }
  }

  Request _request() {
    return RequestFactory().create();
  }

  Future<void> cancelTask(String taskId) async {
    _scheduler.cancelTask(taskId);
    await _repository.removeTask(taskId);
  }

  Future<void> retryTask(String taskId) async {
    final task = await _repository.getTask(taskId);
    if (task != null) {
      await _repository.updateTask(task.copyWith(
        status: DownloadStatus.waiting,
        errorMessage: null,
      ));
    }
  }

  Stream<DownloadState> downloadStream() {
    return _streamDownloadController.stream;
  }

  DownloadState curState() {
    return _downloadState;
  }

  Future<void> clearCompleted() async {
    await _repository.clearCompleted();
  }

  Future<void> dispose() async {
    await _tasksSubscription.cancel();
    await _eventSubscription.cancel();
    _scheduler.dispose();
    await _streamDownloadController.close();
    if (_repository is DownloadRepositoryImpl) {
      await (_repository as DownloadRepositoryImpl).dispose();
    }
  }
}
