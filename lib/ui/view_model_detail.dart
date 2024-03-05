import 'dart:async';
import 'package:MoeLoaderFlutter/net/download.dart';
import 'package:MoeLoaderFlutter/yamlhtmlparser/parser_factory.dart';
import 'package:MoeLoaderFlutter/init.dart';
import 'package:MoeLoaderFlutter/yamlhtmlparser/yaml_reposotory.dart';
import 'package:MoeLoaderFlutter/yamlhtmlparser/yaml_rule_factory.dart';
import 'package:MoeLoaderFlutter/net/request_manager.dart';
import 'package:MoeLoaderFlutter/yamlhtmlparser/yaml_validator.dart';
import 'package:yaml/yaml.dart';
import '../utils/utils.dart';
import '../yamlhtmlparser/models.dart';

class DetailViewModel{
  final YamlRepository repository = YamlRepository();

  final StreamController<DetailState> streamDetailController = StreamController();
  final DetailState _detailState = DetailState();
  final StreamController<DetailUriState> streamDetailUriController = StreamController();
  final DetailUriState _detailUriState = DetailUriState();

  DetailViewModel();

  void requestDetailData(String url,{bool isImageUrl = false, CommonInfo? commonInfo}) async {
    changeDetailLoading(true);
    _updateUri(url);
    if(isImageUrl){
      _detailState.yamlDetailPage.url = url;
      _detailState.yamlDetailPage.commonInfo = commonInfo;
      streamDetailController.add(_detailState);
    }else{
      YamlMap doc = await YamlRuleFactory().create(Global.curWebPageName);
      Map<String, String>? headers = await _parser().getHeaders(doc);
      _detailState.headers = headers;
      ValidateResult<String> result = await repository.detail(url, headers: headers);
      if(result.validateSuccess){
        _detailState.error = false;
        YamlDetailPage picDetailPage = await _parser().parseDetail(result.data!, doc);
        _detailState.yamlDetailPage = picDetailPage;
        streamDetailController.add(_detailState);
      }else{
        _detailState.error = true;
        _detailState.errorMessage = "Error:${result.message}";
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

  void download(String url, String id) {
    DownloadManager().addTask(DownloadTask(url, getDownloadName(url, id)));
  }

  void _updateUri(String url) {
    _detailUriState.baseHref = url;
    streamDetailUriController.add(_detailUriState);
  }

  Parser _parser(){
    return ParserFactory().createParser();
  }
}

class DetailState {
  YamlDetailPage yamlDetailPage = YamlDetailPage("", "");
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

class DetailUriState{
  String baseHref = "";

  DetailUriState();
}
