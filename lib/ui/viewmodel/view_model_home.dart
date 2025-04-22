import 'dart:async';
import 'dart:convert';
import 'package:moeloaderflutter/generated/json/base/json_convert_content.dart';
import 'package:moeloaderflutter/init.dart';
import 'package:moeloaderflutter/model/tag_entity.dart';
import 'package:moeloaderflutter/net/download.dart';
import 'package:moeloaderflutter/repo/yaml_reposotory.dart';
import 'package:logging/logging.dart';
import 'package:moeloaderflutter/ui/viewmodel/connector_impl.dart';
import 'package:to_json/models.dart';
import 'package:to_json/request_factory.dart';
import 'package:to_json/request.dart';
import 'package:to_json/validator.dart';
import 'package:to_json/yaml_parser_base.dart';
import 'package:to_json/yaml_global.dart';
import 'package:yaml/yaml.dart';
import 'package:to_json/yaml_rule_factory.dart';
import 'package:moeloaderflutter/model/home_page_item_entity.dart';
import 'package:moeloaderflutter/model/option_entity.dart';

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
      for (HomePageItemEntity item in _homeState.list) {
        bool find = false;
        for (DownloadTask task in list) {
          if (task.id == item.href) {
            item.downloadState = task.downloadState;
            _log.fine("id=${task.id};task.downloadState=${task.downloadState}");
            find = true;
          }
        }
        if (!find) {
          item.downloadState = DownloadTask.idle;
        }
      }
      streamHomeController.add(_homeState);
    });
  }

  void requestData(String pageName,
      {String? page,
      String? keyword,
      TagEntity? tagEntity,
      bool clearAll = false,
      Map<String, String>? options}) async {
    _log.fine("keyword=$keyword");
    _log.fine("options=$options");
    if (clearAll) {
      _clearAll();
    }
    changeLoading(true);
    String realPage = page ?? (_homeState.page + 1).toString();
    _homeState.keyword = keyword ?? tagEntity?.tag ?? "";
    Map<String, String> formatParams = Global.globalParser.fillInDefaultOptionValue(pageName, options) ?? {};
    var request = _request();
    YamlMap doc = await YamlRuleFactory().create(Global.curWebPageName);
    var globalParser = _globalParser();
    formatParams["page"] = realPage;
    formatParams["keyword"] = _homeState.keyword;
    _log.fine("formatParams=$formatParams");
    String siteName = globalParser.webPageName();
    String url = "";
    await _updateUri(pageName, siteName, url, realPage,
        keyword ?? tagEntity?.desc ?? "", options);

    _homeState.url = url;

    Map<String, String> headers = globalParser.headers();
    _homeState.headers = headers;

    String pageType = globalParser.pageType();
    _homeState.pageType = pageType;

    _homeState.canSearch = true;

    bool success = false;
    String message = "";
    String json = await request.request(doc, pageName, connector: ConnectorImpl(repository), params: formatParams);
    var decode = jsonDecode(json);
    var code = decode["code"];
    _homeState.code = code;
    if (code == Parser.success) {
      _homeState.error = false;
      List<HomePageItemEntity> dataList = _homeState.list;
      dataList.addAll(jsonConvert.convertListNotNull(decode["data"]) ?? []);
      for (var item in dataList) {
        if (item.tagList.isEmpty && item.tagStr.isNotEmpty) {
          item.tagStr.split(item.tagSplit).forEach((element) {
            TagEntity tagEntity = TagEntity();
            tagEntity.desc = element;
            tagEntity.tag = element;
            item.tagList.add(tagEntity);
          });
        }
      }
      _homeState.page = int.parse(realPage);
      streamHomeController.add(_homeState);
      success = true;
    } else {
      message = decode["message"];
    }
    if (!success) {
      _homeState.error = true;
      _homeState.errorMessage = "Error:$message";
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

  List<Rule> webPageList() {
    var webPageList = repository.webPageList();
    return webPageList;
  }

  Future<List<OptionEntity>> optionList(
      String pageName, String? keyword) async {
    var options = _globalParser().options(pageName);
    return jsonConvert.convertListNotNull<OptionEntity>(jsonDecode(options)) ??
        [];
  }

  Future<void> changeGlobalWebPage(Rule rule) async {
    await Global().updateCurWebPage(rule);
  }

  void _clearAll() {
    _homeState.reset();
  }

  _updateUri(String pageName, String siteName, String url, String page,
      String searchDesc, Map<String, String>? options) async {
    Uri uri = Uri.parse(url);
    _uriState.baseHref = "${uri.scheme}://${uri.host}${uri.path}";
    _uriState.page = page;
    _uriState.searchDesc = searchDesc;
    _uriState.url = url;
    _uriState.siteName = siteName;
    _uriState.options = await transformOptions(pageName, options, searchDesc);
    streamUriController.add(_uriState);
  }

  Future<Map<String, String>> transformOptions(
      String pageName, Map<String, String>? options, String keyword) async {
    List<OptionEntity> optionEntityList = await optionList(pageName, keyword);
    Map<String, String> newMap = Map.from(options ?? {});
    newMap.forEach((key, value) {
      for (OptionEntity element in optionEntityList) {
        if (element.id == key) {
          for (var item in element.items) {
            if (item.param == value) {
              newMap[key] = item.desc;
            }
          }
        }
      }
    });
    return newMap;
  }

  Request _request() {
    return RequestFactory().create();
  }

  GlobalParser _globalParser() {
    return Global.globalParser;
  }
}

class HomeState {
  List<HomePageItemEntity> list = [];
  String url = "";
  int page = 0;
  String keyword = "";
  bool loading = false;
  bool error = false;
  bool canSearch = true;
  String errorMessage = "";
  String pageType = "";
  int code = ValidateResult.success;
  Map<String, String>? headers;

  void reset() {
    list.clear();
    url = "";
    page = 0;
    keyword = "";
    loading = false;
    error = false;
    canSearch = true;
    errorMessage = "";
    pageType = "";
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
  String searchDesc = "";
  Map<String, String>? options;

  UriState();
}
