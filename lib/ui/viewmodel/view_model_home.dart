import 'dart:async';
import 'dart:convert';
import 'package:moeloaderflutter/custom_rule/custom_rule_parser.dart';
import 'package:moeloaderflutter/generated/json/base/json_convert_content.dart';
import 'package:moeloaderflutter/init.dart';
import 'package:moeloaderflutter/model/tag_entity.dart';
import 'package:moeloaderflutter/net/download.dart';
import 'package:moeloaderflutter/repo/yaml_reposotory.dart';
import 'package:logging/logging.dart';
import 'package:to_json/models.dart';
import 'package:to_json/parser_factory.dart';
import 'package:to_json/validator.dart';
import 'package:to_json/yaml_parser_base.dart';
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
    String url;
    Map<String, String> formatParams = Map.from(options ?? {});
    var parser = _parser();
    YamlMap doc = await YamlRuleFactory().create(Global.curWebPageName);
    var customRuleParser = _customRuleParser();
    formatParams["page"] = realPage;
    formatParams["keyword"] = _homeState.keyword;
    _log.fine("formatParams=$formatParams");
    url = customRuleParser.url(pageName, formatParams);
    _log.fine("url=$url");
    String siteName = parser.webPageName(doc);
    await _updateUri(pageName, siteName, url, realPage,
        keyword ?? tagEntity?.desc ?? "", options);

    _homeState.url = url;

    Map<String, String> headers = customRuleParser.headers();
    _homeState.headers = headers;

    String pageType = parser.pageType(doc);
    _homeState.pageType = pageType;

    String searchUrl = customRuleParser.url(pageName, {});
    _homeState.canSearch = searchUrl.isNotEmpty;

    Validator validator = Validator(doc, pageName);
    ValidateResult<String> result =
        await repository.home(url, validator, headers: headers);
    _homeState.code = result.code;
    _log.fine("result.code=${result.code}");
    bool success = false;
    String message = "";
    if (result.validateSuccess) {
      String json = await parser.parseUseYaml(result.data!, doc, pageName);
      var decode = jsonDecode(json);
      if (decode["code"] == Parser.success) {
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
    } else {
      message = result.message ?? "";
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
    var options = _customRuleParser().options(pageName);
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

  Parser _parser() {
    return ParserFactory().createParser();
  }

  CustomRuleParser _customRuleParser() {
    return Global.customRuleParser;
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
