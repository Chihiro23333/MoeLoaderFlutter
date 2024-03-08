import 'dart:async';
import 'package:MoeLoaderFlutter/init.dart';
import 'package:MoeLoaderFlutter/yamlhtmlparser/yaml_reposotory.dart';
import 'package:MoeLoaderFlutter/yamlhtmlparser/yaml_rule_factory.dart';
import 'package:MoeLoaderFlutter/yamlhtmlparser/yaml_validator.dart';
import 'package:yaml/yaml.dart';
import '../yamlhtmlparser/models.dart';
import '../yamlhtmlparser/parser_factory.dart';

class HomeViewModel {

  final YamlRepository repository = YamlRepository();

  final StreamController<HomeState> streamHomeController = StreamController();
  final HomeState _homeState = HomeState();
  final StreamController<UriState> streamUriController = StreamController();
  final UriState _uriState = UriState();

  HomeViewModel();

  void requestData({String? tags, bool clearAll = false, List<YamlOption>? optionList}) async {
    print("optionList=$optionList");
    changeLoading(true);
    if(clearAll){
      _clearAll();
    }

    String page = _homeState.page.toString();

    YamlMap doc = await YamlRuleFactory().create(Global.curWebPageName);
    bool home = tags == null;
    String url;
    if(home){
      url = await _parser().getHomeUrl(doc, page, optionList: optionList);
    }else{
      url = await _parser().getSearchUrl(doc, page: page, tags: tags, optionList: optionList);
    }

    String siteName = await _parser().getName(doc);
    _updateUri(siteName, url, page, tags, optionList);

    Map<String, String>? headers = await _parser().getHeaders(doc);
    _homeState.headers = headers;
    ValidateResult<String> result = await repository.home(url, headers: headers);
    _homeState.code = result.code;
    if(result.validateSuccess){
      List<YamlHomePageItem> list;
      if(home){
        list = await _parser().parseHome(result.data!, doc);
      }else{
        list = await _parser().parseSearch(result.data!, doc);
      }
      var dataList = _homeState.list;
      if (_homeState.firstIn) {
        _homeState.firstIn = false;
      }
      dataList.addAll(list);
      _homeState.page++;
      streamHomeController.add(_homeState);
    }else{
      _homeState.error = true;
      _homeState.errorMessage = "Error:${result.message}";
      streamHomeController.add(_homeState);
    }
    changeLoading(false);
  }

  void changeLoading(bool loading) {
    _homeState.loading = loading;
    streamHomeController.add(_homeState);
  }

  Future<List<WebPageItem>> webPageList() async {
    return repository.webPageList();
  }

  Future<List<YamlOptionList>> optionList() async {
    YamlMap doc = await YamlRuleFactory().create(Global.curWebPageName);
    return _parser().optionList(doc);
  }

  Future<void> changeGlobalWebPage(WebPageItem webPageItem) async{
    await Global().updateCurWebPage(webPageItem.rule);
  }

  void _clearAll() {
    _homeState.reset();
  }

  void _updateUri(String siteName, String url, String page, String? tags, List<YamlOption>? optionList) {
    Uri uri = Uri.parse(url);
    _uriState.baseHref = "${uri.scheme}://${uri.host}${uri.path}";
    _uriState.page = page;
    _uriState.tag = tags ?? "";
    _uriState.url = url;
    _uriState.siteName = siteName;
    _uriState.optionList = optionList;
    streamUriController.add(_uriState);
  }

  Parser _parser(){
    return ParserFactory().createParser();
  }
}

class HomeState {
  List<YamlHomePageItem> list = [];
  int page = 1;
  bool loading = false;
  bool firstIn = true;
  bool error = false;
  String errorMessage = "";
  int code = ValidateResult.success;
  Map<String, String>? headers;

  void reset() {
    list.clear();
    page = 1;
    loading = false;
    firstIn = true;
    error = false;
    errorMessage = "";
    headers = null;
    code = ValidateResult.success;
  }

  HomeState();
}

class UriState{
  String siteName = "";
  String url = "";
  String baseHref = "";
  String page = "";
  String tag = "";
  List<YamlOption>? optionList;

  UriState();
}
