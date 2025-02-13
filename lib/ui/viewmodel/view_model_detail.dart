import 'dart:async';
import 'dart:convert';
import 'package:gal/gal.dart';
import 'package:moeloaderflutter/custom_rule/custom_rule_parser.dart';
import 'package:moeloaderflutter/generated/json/base/json_convert_content.dart';
import 'package:moeloaderflutter/model/detail_page_entity.dart';
import 'package:moeloaderflutter/model/home_page_item_entity.dart';
import 'package:moeloaderflutter/model/tag_entity.dart';
import 'package:moeloaderflutter/net/download.dart';
import 'package:moeloaderflutter/util/utils.dart';
import 'package:moeloaderflutter/init.dart';
import 'package:moeloaderflutter/repo/yaml_reposotory.dart';
import 'package:logging/logging.dart';
import 'package:to_json/parser_factory.dart';
import 'package:to_json/validator.dart';
import 'package:to_json/yaml_parser_base.dart';
import 'package:to_json/yaml_rule_factory.dart';
import 'package:yaml/yaml.dart';

class DetailViewModel {
  final _log = Logger('DetailViewModel');

  final String _detailPageName = "detailPage";

  final YamlRepository repository = YamlRepository();

  final StreamController<DetailState> streamDetailController =
      StreamController();
  final DetailState _detailState = DetailState();
  final StreamController<DetailUriState> streamDetailUriController =
      StreamController();
  final DetailUriState _detailUriState = DetailUriState();

  DetailViewModel();

  void requestDetailData(String url, {HomePageItemEntity? homePageItem}) async {
    changeDetailLoading(true);
    _updateUri(url);
    bool imageUrl = isImageUrl(url);
    if (imageUrl) {
      _detailState.detailPageEntity.url = url;
      streamDetailController.add(_detailState);
    } else {
      YamlMap doc = await YamlRuleFactory().create(Global.curWebPageName);
      var parser = _parser();
      var customRuleParser = _customRuleParser();
      Map<String, String> headers = customRuleParser.headers();
      _detailState.headers = headers;
      Validator validator = Validator(doc, _detailPageName);
      ValidateResult<String> result =
          await repository.detail(url, validator, headers: headers);
      bool success = false;
      String message = "";
      if (result.validateSuccess) {
        _detailState.error = false;
        String json =
            await _parser().parseUseYaml(result.data!, doc, _detailPageName);
        var decode = jsonDecode(json);
        if (decode["code"] == Parser.success) {
          _detailState.detailPageEntity =
              jsonConvert.convert<DetailPageEntity>(decode["data"]) ??
                  DetailPageEntity();
          DetailPageEntity detailPageEntity = _detailState.detailPageEntity;
          if (detailPageEntity.tagList.isEmpty && detailPageEntity.tagStr.isNotEmpty) {
            detailPageEntity.tagStr.split(detailPageEntity.tagSplit).forEach((element) {
              TagEntity tagEntity = TagEntity();
              tagEntity.desc = element;
              tagEntity.tag = element;
              detailPageEntity.tagList.add(tagEntity);
            });
          }
          streamDetailController.add(_detailState);
          success = true;
        } else {
          message = decode["message"];
        }
      }
      if (!success) {
        _detailState.error = true;
        _detailState.errorMessage = "Error:$message}";
        _detailState.code = result.code;
        streamDetailController.add(_detailState);
      }
    }
    changeDetailLoading(false);
  }

  void changeDetailLoading(bool loading) {
    _detailState.loading = loading;
    streamDetailController.add(_detailState);
  }

  void download(String href, String url, String id, {Map<String, String>? headers}) async {
    _log.fine("headers=$headers");
    bool hasAccess = await Global.multiPlatform.requestAccess();
    if(hasAccess){
      DownloadManager().addTask(DownloadTask(href, url, getDownloadName(url, id), headers: headers));
    }
  }

  void close() {
    streamDetailController.close();
    streamDetailUriController.close();
  }

  void _updateUri(String url) {
    _detailUriState.baseHref = url;
    streamDetailUriController.add(_detailUriState);
  }

  Parser _parser() {
    return ParserFactory().createParser();
  }

  CustomRuleParser _customRuleParser() {
    return Global.customRuleParser;
  }
}

class DetailState {
  DetailPageEntity detailPageEntity = DetailPageEntity();
  bool loading = false;
  bool downloading = false;
  int downloadProgress = 0;
  int count = 0;
  int total = 0;
  bool error = false;
  String errorMessage = "";
  int code = ValidateResult.success;
  Map<String, String>? headers;

  DetailState();
}

class DetailUriState {
  String baseHref = "";

  DetailUriState();
}
