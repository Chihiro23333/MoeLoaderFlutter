import 'dart:async';
import 'dart:convert';
import 'package:MoeLoaderFlutter/generated/json/base/json_convert_content.dart';
import 'package:MoeLoaderFlutter/init.dart';
import 'package:MoeLoaderFlutter/model/tag_entity.dart';
import 'package:MoeLoaderFlutter/net/download.dart';
import 'package:MoeLoaderFlutter/repo/yaml_reposotory.dart';
import 'package:logging/logging.dart';
import 'package:to_json/models.dart';
import 'package:to_json/parser_factory.dart';
import 'package:to_json/validator.dart';
import 'package:to_json/yaml_parser_base.dart';
import 'package:yaml/yaml.dart';
import 'package:to_json/yaml_rule_factory.dart';
import 'package:MoeLoaderFlutter/model/home_page_item_entity.dart';
import 'package:MoeLoaderFlutter/model/option_entity.dart';

class HomeViewModel {
  final _log = Logger('HomeViewModel');

  final String _homePageName = "homePage";
  final String _searchPageName = "searchPage";

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

  void requestData(
      {String? page,
      bool clearAll = false,
      Map<String, String>? options}) async {
    _log.info("options=$options");
    if (clearAll) {
      _clearAll();
    }
    changeLoading(true);
    String realPage = page ?? (_homeState.page + 1).toString();
    YamlMap doc = await YamlRuleFactory().create(Global.curWebPageName);
    String keyword = options?["keyword"] ?? "";
    bool home = keyword.isEmpty;
    String url;
    Map<String, String> formatParams = Map.from(options ?? {});
    _log.info("formatParams=$formatParams");
    if (home) {
      formatParams["page"] = realPage;
      url = await _parser().url(doc, _homePageName, formatParams);
    } else {
      formatParams["page"] = realPage;
      url = await _parser().url(doc, _searchPageName, formatParams);
    }
    _log.info("url=$url");
    String siteName = await _parser().webPageName(doc);
    _updateUri(siteName, url, realPage, options);

    Map<String, String> headers = await _parser().headers(doc);
    _homeState.headers = headers;

    String pageType = await _parser().pageType(doc);
    _homeState.pageType = pageType;

    String searchUrl = await _parser().url(doc, _searchPageName, {});
    _homeState.canSearch = searchUrl.isNotEmpty;

    Validator validator = Validator(doc, _homePageName);
    ValidateResult<String> result = await repository.home(url, validator, headers: headers);
    _homeState.code = result.code;
    _log.fine("result.code=${result.code}");
    bool success = false;
    String message = "";
    if (result.validateSuccess) {
      String json;
      if (home) {
        json = await _parser().parseUseYaml(result.data!, doc, _homePageName);
      } else {
        json = await _parser().parseUseYaml(result.data!, doc, _searchPageName);
      }
      var decode = jsonDecode(json);
      if (decode["code"] == Parser.success) {
        _homeState.error = false;
        List<HomePageItemEntity> dataList = _homeState.list;
        dataList.addAll(jsonConvert.convertListNotNull(decode["data"]) ?? []);
        for (var item in dataList) {
          if(item.tagList.isEmpty && item.tagStr.isNotEmpty){
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

  Future<List<Rule>> webPageList() async {
    return repository.webPageList();
  }

  Future<List<OptionEntity>> optionList() async {
    YamlMap doc = await YamlRuleFactory().create(Global.curWebPageName);
    var options = await _parser().options(doc, _homePageName);
    return jsonConvert.convertListNotNull<OptionEntity>(jsonDecode(options)) ??
        [];
  }

  Future<void> changeGlobalWebPage(Rule rule) async {
    await Global().updateCurWebPage(rule);
  }

  void _clearAll() {
    _homeState.reset();
  }

  void _updateUri(String siteName, String url, String page,
      Map<String, String>? options) {
    Uri uri = Uri.parse(url);
    _uriState.baseHref = "${uri.scheme}://${uri.host}${uri.path}";
    _uriState.page = page;
    _uriState.url = url;
    _uriState.siteName = siteName;
    _uriState.options = options;
    streamUriController.add(_uriState);
  }

  Parser _parser() {
    return ParserFactory().createParser();
  }
}

class HomeState {
  List<HomePageItemEntity> list = [];
  int page = 0;
  bool loading = false;
  bool error = false;
  bool canSearch = true;
  String errorMessage = "";
  String pageType = "";
  int code = ValidateResult.success;
  Map<String, String>? headers;

  void reset() {
    list.clear();
    page = 0;
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
  Map<String, String>? options;

  UriState();
}
