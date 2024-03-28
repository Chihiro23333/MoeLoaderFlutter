import 'dart:async';
import 'package:MoeLoaderFlutter/init.dart';
import 'package:MoeLoaderFlutter/net/download.dart';
import 'package:MoeLoaderFlutter/yamlhtmlparser/yaml_reposotory.dart';
import 'package:MoeLoaderFlutter/yamlhtmlparser/yaml_rule_factory.dart';
import 'package:MoeLoaderFlutter/yamlhtmlparser/yaml_validator.dart';
import 'package:logging/logging.dart';
import 'package:yaml/yaml.dart';
import '../../yamlhtmlparser/models.dart';
import '../../yamlhtmlparser/parser_factory.dart';

class PoolListViewModel {
  final _log = Logger('HomeViewModel');

  final YamlRepository repository = YamlRepository();

  final StreamController<PoolListState> streamPoolListController = StreamController();
  final PoolListState _poolListState = PoolListState();
  final StreamController<UriState> streamUriController = StreamController();
  final UriState _uriState = UriState();

  PoolListViewModel() {
    DownloadManager().downloadStream().listen((downloadState) {
      List<DownloadTask> list = downloadState.tasks;
      for (YamlHomePageItem item in _poolListState.list) {
        bool find = false;
        for (DownloadTask task in list) {
          if (task.id == item.href) {
            item.downloadState = task.downloadState;
            _log.fine("id=${task.id};task.downloadState=${task.downloadState}");
            find = true;
          }
        }
        if(!find){
          item.downloadState = DownloadTask.idle;
        }
      }
      streamPoolListController.add(_poolListState);
    });
  }

  void requestData(String url) async {
    _log.fine("optionList=$optionList");
    changeLoading(true);

    YamlMap doc = await YamlRuleFactory().create(Global.curWebPageName);
    _updateUri(url);

    Map<String, String>? headers = await _parser().getHeaders(doc);
    _poolListState.headers = headers;

    ValidateResult<String> result = await repository.poolList(url, headers: headers);
    _poolListState.code = result.code;
    _log.info("result.code=${result.code}");
    if (result.validateSuccess) {
      _poolListState.error = false;
      List<YamlHomePageItem> list = await _parser().parsePoolList(result.data!, doc);
      var dataList = _poolListState.list;
      dataList.addAll(list);
      streamPoolListController.add(_poolListState);
    } else {
      _poolListState.error = true;
      _poolListState.errorMessage = "Error:${result.message}";
      streamPoolListController.add(_poolListState);
    }
    changeLoading(false);
  }

  void changeLoading(bool loading) {
    _poolListState.loading = loading;
    if (loading) {
      _poolListState.error = false;
    }
    streamPoolListController.add(_poolListState);
  }

  Future<List<WebPageItem>> webPageList() async {
    return repository.webPageList();
  }

  Future<List<YamlOptionList>> optionList() async {
    YamlMap doc = await YamlRuleFactory().create(Global.curWebPageName);
    return _parser().optionList(doc);
  }

  Future<void> changeGlobalWebPage(WebPageItem webPageItem) async {
    await Global().updateCurWebPage(webPageItem.rule);
  }

  void _updateUri(String url) {
    _uriState.url = url;
    streamUriController.add(_uriState);
  }

  Parser _parser() {
    return ParserFactory().createParser();
  }
}

class PoolListState {
  List<YamlHomePageItem> list = [];
  bool loading = false;
  bool error = false;
  String errorMessage = "";
  int code = ValidateResult.success;
  Map<String, String>? headers;

  void reset() {
    list.clear();
    loading = false;
    error = false;
    errorMessage = "";
    headers = null;
    code = ValidateResult.success;
  }

  PoolListState();
}

class UriState {
  String url = "";

  UriState();
}
