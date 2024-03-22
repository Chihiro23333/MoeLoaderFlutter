import 'dart:async';
import 'package:MoeLoaderFlutter/net/request_manager.dart';
import 'package:MoeLoaderFlutter/utils/sharedpreferences_utils.dart';
import 'package:MoeLoaderFlutter/yamlhtmlparser/models.dart';
import 'package:dio/dio.dart';
import 'package:logging/logging.dart';
import 'package:yaml/yaml.dart';

import '../init.dart';
import '../utils/const.dart';
import '../utils/utils.dart';
import '../yamlhtmlparser/parser_factory.dart';
import '../yamlhtmlparser/yaml_reposotory.dart';
import '../yamlhtmlparser/yaml_rule_factory.dart';
import '../yamlhtmlparser/yaml_validator.dart';

class DownloadManager {

  final _log = Logger("DownloadManager");

  static DownloadManager? _cache;

  DownloadManager._create();

  factory DownloadManager() {
    return _cache ?? (_cache = DownloadManager._create());
  }

  final StreamController<DownloadState> _streamDownloadController =
      StreamController.broadcast();
  final DownloadState _downloadState = DownloadState();

  final YamlRepository repository = YamlRepository();

  CancelToken? _curCancelToken;

  void addTask(DownloadTask downloadTask) {
    _tasks().add(downloadTask);
    downloadTask.downloadState = DownloadTask.waiting;
    _update();
    _downloadNext();
  }

  void cancelTask(DownloadTask task){
    _curCancelToken?.cancel();
    _tasks().removeWhere((element) => task.url == element.url);
    _update();
    _downloadNext();
  }

  List<DownloadTask> _tasks() {
    return _downloadState.tasks;
  }

  void _update() {
    _streamDownloadController.add(_downloadState);
  }

  Stream<DownloadState> downloadStream() {
    return _streamDownloadController.stream;
  }

  DownloadState curState() {
    return _downloadState;
  }

  void _downloadNext() async {
    bool hasDownloading = _hasDownloading();
    if (hasDownloading) return;
    DownloadTask? downloadTask = _findFirstUnDownload();
    if (downloadTask != null) {
      YamlMap doc = await YamlRuleFactory().create(Global.curWebPageName);
      Map<String, String>? headers = await _parser().getHeaders(doc);
      if (isImageUrl(downloadTask.url)) {
        downloadTask.downloadUrl = downloadTask.url;
        _download(downloadTask);
      } else {
        ValidateResult<String> result =
            await repository.detail(downloadTask.url, headers: headers);
        print("result=${result}");
        if (result.validateSuccess) {
          YamlDetailPage picDetailPage =
              await _parser().parseDetail(result.data!, doc);
          String downloadUrl = "";
          String previewUrl = picDetailPage.url;
          String? rawUrl = picDetailPage.commonInfo?.rawUrl;
          String? bigUrl = picDetailPage.commonInfo?.bigUrl;
          String? downloadFileSize = await getDownloadFileSize();
          _log.fine("downloadFileSize=$downloadFileSize");
          switch (downloadFileSize) {
            case Const.preview:
              if (downloadUrl.isEmpty) {
                downloadUrl = previewUrl;
              }
              if (downloadUrl.isEmpty) {
                downloadUrl = bigUrl ?? "";
              }
              if (downloadUrl.isEmpty) {
                downloadUrl = rawUrl ?? "";
              }
              break;
            case Const.big:
              if (downloadUrl.isEmpty) {
                downloadUrl = bigUrl ?? "";
              }
              if (downloadUrl.isEmpty) {
                downloadUrl = rawUrl ?? "";
              }
              if (downloadUrl.isEmpty) {
                downloadUrl = previewUrl;
              }
              break;
            case Const.raw:
            default:
              if (downloadUrl.isEmpty) {
                downloadUrl = rawUrl ?? "";
              }
              if (downloadUrl.isEmpty) {
                downloadUrl = bigUrl ?? "";
              }
              if (downloadUrl.isEmpty) {
                downloadUrl = previewUrl;
              }
              break;
          }
          downloadTask.downloadUrl = downloadUrl;
          _download(downloadTask);
        } else {
          downloadTask.downloadState = DownloadTask.error;
          _update();
          _downloadNext();
        }
      }
    }
  }

  Parser _parser() {
    return ParserFactory().createParser();
  }

  void _download(DownloadTask downloadTask) {
    if (downloadTask.downloadUrl.isEmpty) {
      _downloadNext();
    } else {
      _curCancelToken = CancelToken();
      RequestManager().download(downloadTask.downloadUrl, downloadTask.name,
          onReceiveProgress: (int count, int total) {
        downloadTask.count = count;
        downloadTask.total = total;
        bool complete = count == total;
        downloadTask.downloadState =
            complete ? DownloadTask.complete : DownloadTask.downloading;
        _update();
        if (complete) {
          _downloadNext();
        }
      },
      cancelToken:_curCancelToken);
    }
  }

  DownloadTask? _findFirstUnDownload() {
    DownloadTask? task;
    Iterator<DownloadTask> iterator = _tasks().iterator;
    while (iterator.moveNext()) {
      var current = iterator.current;
      if (current.downloadState == DownloadTask.waiting) {
        task = current;
        break;
      }
    }
    return task;
  }

  bool _hasDownloading() {
    bool hasDownloading = false;
    Iterator<DownloadTask> iterator = _tasks().iterator;
    while (iterator.moveNext()) {
      var current = iterator.current;
      if (current.downloadState == DownloadTask.downloading) {
        hasDownloading = true;
        break;
      }
    }
    return hasDownloading;
  }
}

class DownloadState {
  List<DownloadTask> tasks = [];
}

class DownloadTask {
  static const int idle = 0;
  static const int waiting = 1;
  static const int downloading = 2;
  static const int complete = 3;
  static const int error = 4;

  String id;
  String url;
  String name;
  String downloadUrl = "";
  int count = 0;
  int total = 0;
  int downloadState = idle;

  DownloadTask(this.id, this.url, this.name);
}
