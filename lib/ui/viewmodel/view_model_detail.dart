import 'dart:async';
import 'dart:convert';
import 'package:moeloaderflutter/generated/json/base/json_convert_content.dart';
import 'package:moeloaderflutter/model/detail_page_entity.dart';
import 'package:moeloaderflutter/model/home_page_item_entity.dart';
import 'package:moeloaderflutter/model/tag_entity.dart';
import 'package:moeloaderflutter/net/download.dart';
import 'package:moeloaderflutter/ui/viewmodel/connector_impl.dart';
import 'package:moeloaderflutter/util/utils.dart';
import 'package:moeloaderflutter/init.dart';
import 'package:moeloaderflutter/repo/yaml_reposotory.dart';
import 'package:logging/logging.dart';
import 'package:to_json/request.dart';
import 'package:to_json/request_factory.dart';
import 'package:to_json/validator.dart';
import 'package:to_json/yaml_parser_base.dart';
import 'package:to_json/yaml_global.dart';
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
      var request = _request();
      var globalParser = _globalParser();
      Map<String, String> headers = globalParser.headers();
      _detailState.headers = headers;
      bool success = false;
      String message = "";
      _detailState.error = false;
      String json = await request.requestByUrl(
          url, doc, _detailPageName, ConnectorImpl(repository));
      var decode = jsonDecode(json);
      var code = decode["code"];
      _detailState.code = code;
      if (code == Parser.success) {
        _detailState.detailPageEntity =
            jsonConvert.convert<DetailPageEntity>(decode["data"]) ??
                DetailPageEntity();
        DetailPageEntity detailPageEntity = _detailState.detailPageEntity;
        if (detailPageEntity.tagList.isEmpty &&
            detailPageEntity.tagStr.isNotEmpty) {
          detailPageEntity.tagStr
              .split(detailPageEntity.tagSplit)
              .forEach((element) {
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
      if (!success) {
        _detailState.error = true;
        _detailState.errorMessage = "Error:$message}";
        streamDetailController.add(_detailState);
      }
    }
    changeDetailLoading(false);
  }

  void changeDetailLoading(bool loading) {
    _detailState.loading = loading;
    streamDetailController.add(_detailState);
  }

  void download(
      String href, String url, String id, String author, List<TagEntity> tags,
      {Map<String, String>? headers}) async {
    _log.fine("headers=$headers");
    bool hasAccess = await Global.multiPlatform.requestAccess();
    if (hasAccess) {
      DownloadManager().addTask(DownloadTask(
          href,
          url,
          await getDownloadName(
            url,
            id,
            author,
            tags
          ),
          headers: headers));
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

  Request _request() {
    return RequestFactory().create();
  }

  GlobalParser _globalParser() {
    return Global.globalParser;
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
