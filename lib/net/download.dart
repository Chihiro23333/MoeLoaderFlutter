import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:gal/gal.dart';
import 'package:moeloaderflutter/custom_rule/custom_rule_parser.dart';
import 'package:moeloaderflutter/generated/json/base/json_convert_content.dart';
import 'package:moeloaderflutter/model/detail_page_entity.dart';
import 'package:moeloaderflutter/net/request_manager.dart';
import 'package:moeloaderflutter/util/const.dart';
import 'package:moeloaderflutter/util/sharedpreferences_utils.dart';
import 'package:moeloaderflutter/util/utils.dart';
import 'package:dio/dio.dart';
import 'package:logging/logging.dart';
import 'package:to_json/parser_factory.dart';
import 'package:to_json/validator.dart';
import 'package:to_json/yaml_parser_base.dart';
import 'package:to_json/yaml_rule_factory.dart';
import 'package:yaml/yaml.dart';
import '../init.dart';
import '../repo/yaml_reposotory.dart';

class DownloadManager {
  final _log = Logger("DownloadManager");

  final String _detailPageName = "detailPage";

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

  void cancelTask(DownloadTask task) {
    _curCancelToken?.cancel();
    _tasks().removeWhere((element) => task.url == element.url);
    _update();
    _downloadNext();
  }

  void retryTask(DownloadTask task) {
    _curCancelToken?.cancel();
    _tasks().forEach((element) {
      if (task.url == element.url) {
        element.downloadState = DownloadTask.waiting;
      }
    });
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
      var parser = _parser();
      var customRuleDoc = parser.customRule(doc);
      var customRuleParser = _customRuleParser();
      Map<String, String>? headers = customRuleParser.headers();
      if (isImageUrl(downloadTask.url)) {
        downloadTask.downloadUrl = downloadTask.url;
        _download(downloadTask);
      } else {
        Validator validator = Validator(doc, _detailPageName);
        ValidateResult<String> result = await repository
            .detail(downloadTask.url, validator, headers: headers);
        print("result=${result}");
        bool success = false;
        if (result.validateSuccess) {
          String json =
              await parser.parseUseYaml(result.data!, doc, _detailPageName);
          var decode = jsonDecode(json);
          if (decode["code"] == Parser.success) {
            success = true;
            DetailPageEntity detailPageEntity =
                jsonConvert.convert<DetailPageEntity>(decode["data"]) ??
                    DetailPageEntity();
            String downloadUrl = "";
            String previewUrl = detailPageEntity.url;
            String? rawUrl = detailPageEntity.rawUrl;
            String? bigUrl = detailPageEntity.bigUrl;
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
          }
        }
        if (!success) {
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

  CustomRuleParser _customRuleParser() {
    return Global.customRuleParser;
  }

  void _download(DownloadTask downloadTask) {
    if (downloadTask.downloadUrl.isEmpty) {
      _downloadNext();
    } else {
      _curCancelToken = CancelToken();
      var downloadUrl = downloadTask.downloadUrl;
      int index = downloadUrl.lastIndexOf(".");
      String suffix = downloadUrl.substring(index, downloadUrl.length);
      Directory directory = Global.downloadsDirectory;
      _log.fine("suffix=$suffix;path=${directory.path}");
      String savePath = "${directory.path}/${downloadTask.name}$suffix";
      RequestManager().download(downloadUrl, savePath,
          onReceiveProgress: (int count, int total) {
        downloadTask.count = count;
        downloadTask.total = total;
        bool complete = count == total;
        downloadTask.downloadState =
            complete ? DownloadTask.complete : DownloadTask.downloading;
        _update();
        if (complete) {
          Global.multiPlatform.saveToGallery(savePath);
          _downloadNext();
        }
      }, cancelToken: _curCancelToken, headers: downloadTask.headers);
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
  Map<String, String>? headers;

  DownloadTask(this.id, this.url, this.name, {this.headers});
}
