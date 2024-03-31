import 'dart:async';
import 'dart:convert';
import 'package:MoeLoaderFlutter/generated/json/base/json_convert_content.dart';
import 'package:MoeLoaderFlutter/init.dart';
import 'package:MoeLoaderFlutter/model/home_page_item_entity.dart';
import 'package:MoeLoaderFlutter/model/tag_entity.dart';
import 'package:MoeLoaderFlutter/net/download.dart';
import 'package:MoeLoaderFlutter/repo/yaml_reposotory.dart';
import 'package:logging/logging.dart';
import 'package:to_json/models.dart';
import 'package:to_json/parser_factory.dart';
import 'package:to_json/validator.dart';
import 'package:to_json/yaml_parser_base.dart';
import 'package:to_json/yaml_rule_factory.dart';
import 'package:yaml/yaml.dart';

class PoolListViewModel {
  final _log = Logger('HomeViewModel');

  final String _poolListPageName = "poolListPage";

  final YamlRepository repository = YamlRepository();

  final StreamController<PoolListState> streamPoolListController =
      StreamController();
  final PoolListState _poolListState = PoolListState();
  final StreamController<UriState> streamUriController = StreamController();
  final UriState _uriState = UriState();

  PoolListViewModel() {
    DownloadManager().downloadStream().listen((downloadState) {
      List<DownloadTask> list = downloadState.tasks;
      for (HomePageItemEntity item in _poolListState.list) {
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
      streamPoolListController.add(_poolListState);
    });
  }

  void requestData(String url) async {
    changeLoading(true);

    YamlMap doc = await YamlRuleFactory().create(Global.curWebPageName);
    _updateUri(url);

    Map<String, String> headers = await _parser().headers(doc);
    _poolListState.headers = headers;

    Validator validator = Validator(doc, _poolListPageName);
    ValidateResult<String> result =
        await repository.poolList(url, validator, headers: headers);
    _poolListState.code = result.code;
    _log.fine("result.code=${result.code}");
    bool success = false;
    String message = "";
    if (result.validateSuccess) {
      _poolListState.error = false;
      List<HomePageItemEntity>? list;
      String json =
          await _parser().parseUseYaml(result.data!, doc, _poolListPageName);
      var decode = jsonDecode(json);
      if (decode["code"] == Parser.success) {
        list = jsonConvert.convertListNotNull(decode["data"]);
        var dataList = _poolListState.list;
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
        streamPoolListController.add(_poolListState);
        success = true;
      } else {
        message = decode["message"];
      }
    }
    if (!success) {
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

  Future<List<Rule>> webPageList() async {
    return repository.webPageList();
  }

  // Future<List<YamlOptionList>> optionList() async {
  //   YamlMap doc = await YamlRuleFactory().create(Global.curWebPageName);
  //   return _parser().optionList(doc);
  // }

  void _updateUri(String url) {
    _uriState.url = url;
    streamUriController.add(_uriState);
  }

  Parser _parser() {
    return ParserFactory().createParser();
  }
}

class PoolListState {
  List<HomePageItemEntity> list = [];
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
