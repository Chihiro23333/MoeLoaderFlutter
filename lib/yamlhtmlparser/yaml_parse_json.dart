import 'dart:convert';

import 'package:MoeLoaderFlutter/yamlhtmlparser/parser_factory.dart';
import 'package:MoeLoaderFlutter/yamlhtmlparser/yaml_rule_factory.dart';
import 'package:json_path/json_path.dart';
import 'package:logging/logging.dart';
import 'package:yaml/yaml.dart';
import 'models.dart';

class YamlJsonParser extends Parser{

  final _log = Logger('YamlJsonParser');

  static const defaultConnector = ",";
  static const defaultSeparator = ",";

  @override
  Future<String> parseUseYaml(String content, String sourceName, String pageName) async {
    _log.fine("jsonStr=$content");
    YamlMap doc = await YamlRuleFactory().create(sourceName);
    YamlMap? page = doc[pageName];
    if (page == null) {
      throw "pageName不存在";
    }
    var jsonContent = jsonDecode(content);
    //解析文本拿到结果
    YamlMap onParseResult = page["onParseResult"];
    String json = _recursionQuery(jsonContent, "", onParseResult);
    _log.fine("json=$json");
    return json;
  }

  String _recursionQuery(Map<String, dynamic> json, String pJPath, YamlMap rule, {int? index, String defaultValue = ""}) {
    String? dataType;
    for (var element in rule.keys) {
      if(element.toString() == "contentType")continue;
      dataType = element.toString();
      break;
    }
    _log.fine("dataType=$dataType");
    YamlMap contentRule = rule[dataType];
    _log.fine("contentRule=$contentRule");
    switch (dataType) {
      case "object":
        var object = {};
        contentRule.forEach((key, value) {
          String result = _recursionQuery(json, pJPath, value);
          _log.fine("propName=$key;propValue=$result");
          object[key] = result;
        });
        return jsonEncode(object);
      case "list":
        YamlMap getNodesRule = contentRule["getNodes"];
        String listJpath = _getJsonPath(getNodesRule);
        _log.fine("listJpath=$listJpath");
        List<dynamic> jsonList = _jsonPathN(json, listJpath);

        YamlMap foreachRule = contentRule["foreach"];
        var list = [];
        _log.fine("listList=$jsonList");
        for (int i = 0; i < jsonList.length; i++) {
          var item = {};
          foreachRule.forEach((key, value) {
            String result = _recursionQuery(json, listJpath, value, index: i, defaultValue: value["default"] ?? "");
            _log.fine("propName=$key;propValue=$result");
            item[key] = result;
          });
          list.add(item);
        }
        _log.fine("result=${list.toString()}");
        return jsonEncode(list);
      default:
        return _getOne(json, pJPath, rule, index: index, defaultValue: defaultValue);
    }
  }

  @override
  Future<List<YamlHomePageItem>> parseHome(String content, YamlMap webPage) async {
    _log.fine("jsonStr=$content");
    List<YamlHomePageItem> dataList = _listHomeLit(content, webPage);
    return dataList;
  }

  @override
  Future<List<YamlHomePageItem>> parseSearch(String content, YamlMap webPage) {
    return parseHome(content, webPage);
  }

  @override
  Future<YamlDetailPage> parseDetail(String jsonStr, YamlMap webPage) async {
    _log.fine("jsonStr=$jsonStr");
    var json = jsonDecode(jsonStr);
    YamlMap object = webPage['object'];
    YamlMap urlRule = object['url'];
    YamlMap? previewRule = object['preview'];

    String url = _getOne(json, "", urlRule);
    _log.fine("url=$url");
    String preview = _getOne(json, "", previewRule);
    _log.fine("preview=$preview");
    CommonInfo commonInfo = _getCommonInfo(json, object, "");
    _log.fine("commonInfo=${commonInfo.id}");
    YamlDetailPage yamlDetailPage =
        YamlDetailPage(url, preview, commonInfo: commonInfo);
    return yamlDetailPage;
  }

  Future<String> preprocess(String content, YamlMap preprocessNode) async {
    String? contentType  = preprocessNode["contentType"];
    _log.fine("contentType=$contentType,jsonStr=$content");
    if(contentType != null && contentType == "json"){
      var json = jsonDecode(content);
      return _getOne(json, "", preprocessNode);
    }
    return content;
  }

  List<YamlHomePageItem> _listHomeLit(String jsonStr, YamlMap webPage) {
    var json = jsonDecode(jsonStr);
    YamlMap list = webPage["onParseResult"]["list"];
    YamlMap getNodesRule = list["getNodes"];

    YamlMap foreach = list["foreach"];

    YamlMap coverUrlRule = foreach["coverUrl"];

    YamlMap hrefRule = foreach["href"];
    YamlMap? widthRule = foreach['width'];
    YamlMap? heightRule = foreach['height'];

    List<YamlHomePageItem> dataList = [];
    String listJpath = _getJsonPath(getNodesRule);
    _log.fine("listJpath=$listJpath");
    List<dynamic> jsonList = _jsonPathN(json, listJpath);
    for (int i = 0; i < jsonList.length; i++) {
      String coverUrl = _getOne(json, listJpath, coverUrlRule, index: i);
      _log.fine("coverUrl=$coverUrl");
      String href = _getOne(json, listJpath, hrefRule, index: i);
      _log.fine("href=$href");
      String width = _getOne(json, listJpath, widthRule, index: i, defaultValue: "0");
      _log.fine("width=$width");
      String height =
          _getOne(json, listJpath, heightRule, index: i, defaultValue: "0");
      _log.fine("height=$height");
      CommonInfo commonInfo = _getCommonInfo(json, foreach, listJpath, index: i);
      _log.fine("commonInfo=$commonInfo");
      dataList.add(YamlHomePageItem(
          coverUrl, href, double.parse(width), double.parse(height),
          commonInfo: commonInfo));
    }
    return dataList;
  }

  String _getJsonPath(YamlMap rule) {
    _log.fine("getJPath:rule=$rule");
    String? jpath = rule["jsonpath"];
    if (jpath == null) throw "first rule must be jsonpath！";
    return jpath;
  }

  List<dynamic> _jsonPathN(Map<String, dynamic> json, String jpath) {
    JsonPath jsonPath = JsonPath(jpath);
    _log.fine("jsonPath.read(json)=${jsonPath.read(json)}");
    List<dynamic> jsonList = jsonPath.read(json).elementAt(0).value as List<dynamic>;
    return jsonList;
  }

  String _jsonPathOne(Map<String, dynamic> json, String jpath) {
    JsonPath jsonPath = JsonPath(jpath);
    return jsonPath.read(json).elementAt(0).value.toString();
  }

  String _formatJsonPath(String pJPath, String curJPath, int? index) {
    if(index == null){
      return "$pJPath$curJPath";
    }else{
      return "$pJPath[$index]$curJPath";
    }
  }

  CommonInfo _getCommonInfo(
      Map<String, dynamic> json, YamlMap yamlMap, String pJPath,{int? index}) {
    YamlMap? idRule = yamlMap['id'];
    YamlMap? authorRule = yamlMap['author'];
    YamlMap? charactersRule = yamlMap['characters'];
    YamlMap? fileSizeRule = yamlMap['fileSize'];
    YamlMap? dimensionsRule = yamlMap['dimensions'];
    YamlMap? sourceRule = yamlMap['source'];
    YamlMap? bigUrlRule = yamlMap['bigUrl'];
    YamlMap? rawUrlRule = yamlMap['rawUrl'];
    YamlMap? tagsRule = yamlMap['tags'];

    String id = _getOne(json, pJPath, idRule, index: index);
    _log.fine("id=$id");
    String author = _getOne(json, pJPath, authorRule, index: index);
    _log.fine("author=$author");
    String characters = _getOne(json, pJPath, charactersRule, index: index);
    _log.fine("characters=$characters");
    String fileSize = _getOne(json, pJPath, fileSizeRule, index: index);
    _log.fine("fileSize=$fileSize");
    String dimensions = _getOne(json, pJPath, dimensionsRule, index: index);
    _log.fine("dimensions=$dimensions");
    String source = _getOne(json, pJPath, sourceRule, index: index);
    _log.fine("source=$source");
    String rawUrl = _getOne(json, pJPath, rawUrlRule, index: index);
    _log.fine("rawUrl=$rawUrl");
    String bigUrl = _getOne(json, pJPath, bigUrlRule, index: index);
    _log.fine("bigUrl=$bigUrl");
    List<YamlTag> tagsList = _listTags(json, tagsRule, pJPath, index);
    _log.fine("tagsList=${tagsList.length}");
    CommonInfo commonInfo = CommonInfo(
        id, author, characters, fileSize, dimensions, source, bigUrl, rawUrl, tagsList);
    return commonInfo;
  }

  String _getOne(Map<String, dynamic> json, String pJPath, YamlMap? rule,
      {int? index, String defaultValue = ""}) {
    if (rule == null) {
      return defaultValue;
    } else {
      String queryJPath = _formatJsonPath(pJPath, _getJsonPath(rule["get"]), index);
      String result = _queryOne(json, queryJPath, rule);
      _log.fine("_getOne result=$result");
      return result;
    }
  }

  List<YamlTag> _listTags(
      Map<String, dynamic> json,
      YamlMap? tagsRule,
      String pJPath,
      int? index
      ) {
    List<YamlTag> tagsList = [];
    if (tagsRule != null) {
      YamlMap listRule = tagsRule["list"];
      YamlMap? getNodesRule = listRule["getNodes"];
      if(getNodesRule != null){
        YamlMap? foreach = listRule["foreach"];
        _log.fine("foreach=$foreach");
        String queryJPath = _formatJsonPath(pJPath, _getJsonPath(getNodesRule), index);
        List<dynamic> listList = _jsonPathN(json, queryJPath);
        if(foreach == null){
          for (int i = 0; i < listList.length; i++ ) {
            String tagStr = listList[i];
            tagsList.add(YamlTag(tagStr, tagStr));
          }
        }else{
          YamlMap descRule = foreach["desc"];
          YamlMap tagRule = foreach["tag"];
          for (int i = 0; i < listList.length; i++ ) {
            String desc = _getOne(json,queryJPath, descRule, index: index);
            _log.fine("desc=$desc");
            String tag = _getOne(json,queryJPath, tagRule, index: index);
            _log.fine("tags=$desc");
            tagsList.add(YamlTag(desc, tag));
          }
        }
      }

      YamlMap? getRule = listRule["get"];
      YamlMap? toListRule = listRule["toList"];
      if(getRule != null){
        String separator = toListRule?["separator"] ?? defaultSeparator;
        String queryJPath = _formatJsonPath(pJPath, _getJsonPath(getRule), index);
        String tagStr = _jsonPathOne(json, queryJPath);
        _log.fine("tagStr=$tagStr");
        if(tagStr.isNotEmpty){
          tagStr.split(separator).forEach((element) {
            tagsList.add(YamlTag(element, element));
          });
        }
      }
    }
    return tagsList;
  }

  Future<String> homeRequestBy(YamlMap webPage) async {
    YamlMap homePage = webPage['homePage'];
    String requestBy = homePage['meta']?['requestBy'] ??= "dio";
    return requestBy;
  }

  /// 查找单个
  /// 分为三步，每一步都返回一个字符串
  String _queryOne(Map<String, dynamic> json, String queryJPath, YamlMap yamlMap) {
    _log.fine("queryJPath=$queryJPath");
    String result = "";
    //第一步，定位元素并获取值
    result = _get(json, queryJPath, yamlMap['get']);
    _log.fine("get=$result");
    //第二步，查找值并选择选择值
    var filterRule = yamlMap["filter"];
    if (filterRule != null) {
      result = _filter(result, filterRule);
      _log.fine("filter=$result");
    }
    //第三步，规整拼接值
    var formatRule = yamlMap["format"];
    if (formatRule != null) {
      for (YamlMap? yamlMap in formatRule) {
        if (yamlMap != null) {
          result = _format(result, yamlMap);
          _log.fine("format=$result");
        }
      }
    }
    return result;
  }

  //todo 方法抽出？
  String _get(Map<String, dynamic> json, String queryJPath, YamlMap yamlMap) {
    return _jsonPathOne(json, queryJPath);
  }

  String _filter(String value, YamlMap yamlMap) {
    String result = value;
    RegExp? linkRegExp;

    String? regexRule = yamlMap["regex"];
    if (regexRule == null) throw "first rule must be regex！";
    linkRegExp = RegExp(regexRule);

    int? indexRule = yamlMap["index"];
    if (indexRule != null) {
      result = linkRegExp.firstMatch(value)?.group(indexRule) ?? "";
    }

    result = _regularString(result);
    return result;
  }

  String _format(String chooseResult, YamlMap formatRule) {
    String result = chooseResult;

    YamlMap? concatRule = formatRule["concat"];
    if (concatRule != null) {
      String? startRule = concatRule["start"];
      String? endRule = concatRule["end"];
      if (startRule != null && !chooseResult.startsWith(startRule)) {
        result = "$startRule$result";
      }
      if (endRule != null && !chooseResult.endsWith(endRule)) {
        result = "$result$endRule";
      }
    }

    YamlMap? replaceAllRule = formatRule["replaceAll"];
    if (replaceAllRule != null) {
      String? fromRule = replaceAllRule["from"];
      String? toRule = replaceAllRule["to"];
      if (fromRule != null && toRule != null) {
        result = result.replaceAll(fromRule, toRule);
      }
    }

    return result;
  }

  String _regularString(String text) {
    text = text.replaceAll("\n", "");
    text = text.trim();
    return text;
  }
}
