import 'dart:async';
import 'dart:convert';
import 'package:moeloaderflutter/generated/json/base/json_convert_content.dart';
import 'package:moeloaderflutter/init.dart';
import 'package:moeloaderflutter/model/home_page_item_entity.dart';
import 'package:moeloaderflutter/model/tag_entity.dart';
import 'package:moeloaderflutter/net/download.dart';
import 'package:moeloaderflutter/repo/yaml_reposotory.dart';
import 'package:logging/logging.dart';
import 'package:moeloaderflutter/ui/viewmodel/connector_impl.dart';
import 'package:to_json/models.dart';
import 'package:to_json/request.dart';
import 'package:to_json/request_factory.dart';
import 'package:to_json/validator.dart';
import 'package:to_json/yaml_parser_base.dart';
import 'package:to_json/yaml_global.dart';
import 'package:to_json/yaml_rule_factory.dart';
import 'package:yaml/yaml.dart';

class AuthorViewModel {
  final _log = Logger('AuthorViewModel');

  final String _authorPageName = "authorPage";

  final YamlRepository repository = YamlRepository();

  final StreamController<AuthorState> streamAuthorController =
      StreamController();
  final AuthorState _authorState = AuthorState();
  final StreamController<UriState> streamUriController = StreamController();
  final UriState _uriState = UriState();

  AuthorViewModel() {
    DownloadManager().downloadStream().listen((downloadState) {
      List<DownloadTask> list = downloadState.tasks;
      for (HomePageItemEntity item in _authorState.list) {
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
      streamAuthorController.add(_authorState);
    });
  }

  void requestData(String id,
      {String? page, Map<String, String>? options}) async {
    changeLoading(true);

    String realPage = page ?? (_authorState.page + 1).toString();

    var globalParser = _globalParser();
    Map<String, String> formatParams = Map.from(options ?? {});
    formatParams["page"] = realPage;
    formatParams["authorId"] = id;
    _log.fine("formatParams=$formatParams");
    String url = "";
    _authorState.url = url;
    _updateUri(url);

    Map<String, String> headers = globalParser.headers();
    _authorState.headers = headers;

    YamlMap doc = await YamlRuleFactory().create(Global.curWebPageName);

    bool success = false;
    String message = "";
    _authorState.error = false;
    List<HomePageItemEntity>? list;
    String json =
        await _request().request(doc, _authorPageName, connector: ConnectorImpl(repository), params: formatParams);
    var decode = jsonDecode(json);
    var code = decode["code"];
    _authorState.code = code;
    if (code == Parser.success) {
      list = jsonConvert.convertListNotNull(decode["data"]);
      var dataList = _authorState.list;
      dataList.addAll(list ?? []);
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
      _authorState.page = int.parse(realPage);
      streamAuthorController.add(_authorState);
      success = true;
    } else {
      message = decode["message"];
    }
    if (!success) {
      _authorState.error = true;
      _authorState.errorMessage = message;
      streamAuthorController.add(_authorState);
    }
    changeLoading(false);
  }

  void changeLoading(bool loading) {
    _authorState.loading = loading;
    if (loading) {
      _authorState.error = false;
    }
    streamAuthorController.add(_authorState);
  }

  Future<List<Rule>> webPageList() async {
    return repository.webPageList();
  }

  void _updateUri(String url) {
    _uriState.url = url;
    streamUriController.add(_uriState);
  }

  Request _request() {
    return RequestFactory().create();
  }

  GlobalParser _globalParser() {
    return Global.globalParser;
  }
}

class AuthorState {
  List<HomePageItemEntity> list = [];
  int page = 0;
  String url = "";
  bool loading = false;
  bool error = false;
  String errorMessage = "";
  int code = ValidateResult.success;
  Map<String, String>? headers;

  void reset() {
    list.clear();
    int page = 0;
    String url = "";
    loading = false;
    error = false;
    errorMessage = "";
    headers = null;
    code = ValidateResult.success;
  }

  AuthorState();
}

class UriState {
  String url = "";

  UriState();
}
