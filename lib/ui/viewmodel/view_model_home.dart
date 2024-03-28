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

class HomeViewModel {
  final _log = Logger('HomeViewModel');

  final YamlRepository repository = YamlRepository();

  final StreamController<HomeState> streamHomeController = StreamController();
  final HomeState _homeState = HomeState();
  final StreamController<UriState> streamUriController = StreamController();
  final UriState _uriState = UriState();

  HomeViewModel() {
    DownloadManager().downloadStream().listen((downloadState) {
      List<DownloadTask> list = downloadState.tasks;
      for (YamlHomePageItem item in _homeState.list) {
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
      streamHomeController.add(_homeState);
    });
  }

  void requestData(
      {String? tags,
      String? page,
      bool clearAll = false,
      List<YamlOption>? optionList}) async {
    _log.fine("optionList=$optionList");
    if (clearAll) {
      _clearAll();
    }
    changeLoading(true);

    String realPage = page ?? (_homeState.page + 1).toString();
    YamlMap doc = await YamlRuleFactory().create(Global.curWebPageName);
    bool home = tags == null;
    String url;
    if (home) {
      url = await _parser().getHomeUrl(doc, realPage, optionList: optionList);
    } else {
      url = await _parser()
          .getSearchUrl(doc, page: realPage, tags: tags, optionList: optionList);
    }

    String siteName = await _parser().getName(doc);
    _updateUri(siteName, url, realPage, tags, optionList);

    String listType = await _parser().listType(doc);
    _homeState.listType = listType;

    Map<String, String>? headers = await _parser().getHeaders(doc);
    _homeState.headers = headers;

    bool canSearch = await _parser().canSearch(doc);
    _homeState.canSearch = canSearch;

    ValidateResult<String> result =
        await repository.home(url, headers: headers);
    _homeState.code = result.code;
    _log.info("result.code=${result.code}");
    if (result.validateSuccess) {
      _homeState.error = false;
      List<YamlHomePageItem> list;
      if (home) {
        list = await _parser().parseHome(result.data!, doc);
      } else {
        list = await _parser().parseSearch(result.data!, doc);
      }
      var dataList = _homeState.list;
      dataList.addAll(list);
      _homeState.page = int.parse(realPage);
      streamHomeController.add(_homeState);
    } else {
      _homeState.error = true;
      _homeState.errorMessage = "Error:${result.message}";
      streamHomeController.add(_homeState);
    }
    changeLoading(false);
  }

  void changeLoading(bool loading) {
    _homeState.loading = loading;
    if (loading) {
      _homeState.error = false;
    }
    streamHomeController.add(_homeState);
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

  void _clearAll() {
    _homeState.reset();
  }

  void _updateUri(String siteName, String url, String page, String? tags,
      List<YamlOption>? optionList) {
    Uri uri = Uri.parse(url);
    _uriState.baseHref = "${uri.scheme}://${uri.host}${uri.path}";
    _uriState.page = page;
    _uriState.tag = tags ?? "";
    _uriState.url = url;
    _uriState.siteName = siteName;
    _uriState.optionList = optionList;
    streamUriController.add(_uriState);
  }

  Parser _parser() {
    return ParserFactory().createParser();
  }
}

class HomeState {
  List<YamlHomePageItem> list = [];
  int page = 0;
  bool loading = false;
  bool error = false;
  bool canSearch = true;
  String errorMessage = "";
  String listType = "";
  int code = ValidateResult.success;
  Map<String, String>? headers;

  void reset() {
    list.clear();
    page = 0;
    loading = false;
    error = false;
    canSearch = true;
    errorMessage = "";
    listType = "";
    headers = null;
    code = ValidateResult.success;
  }

  HomeState();
}

class UriState {
  String siteName = "";
  String url = "";
  String baseHref = "";
  String page = "";
  String tag = "";
  List<YamlOption>? optionList;

  UriState();
}
