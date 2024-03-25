import 'dart:convert';
import 'package:MoeLoaderFlutter/yamlhtmlparser/parser_factory.dart';
import 'package:MoeLoaderFlutter/yamlhtmlparser/yaml_rule_factory.dart';
import 'package:json_path/json_path.dart';
import 'package:logging/logging.dart';
import 'package:yaml/yaml.dart';

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
    String json = jsonEncode(_recursionQuery(jsonContent, "", onParseResult));
    _log.fine("json=$json");
    return json;
  }

  dynamic _recursionQuery(Map<String, dynamic> json, String pJPath, YamlMap rule, {int? index, String defaultValue = ""}) {
    String? dataType;
    for (var element in rule.keys) {
      if(element.toString() == "contentType")continue;
      dataType = element.toString();
      break;
    }
    _log.fine("dataType=$dataType");
    switch (dataType) {
      case "object":
        YamlMap contentRule = rule[dataType];
        _log.fine("contentRule=$contentRule");
        var object = {};
        contentRule.forEach((key, value) {
          dynamic result = _recursionQuery(json, pJPath, value);
          _log.fine("propName=$key;propValue=$result");
          object[key] = result;
        });
        return object;
      case "list":
        YamlMap contentRule = rule[dataType];
        _log.fine("contentRule=$contentRule");

        YamlMap getNodesRule = contentRule["getNodes"];
        String? listJpath = _getJsonPath(getNodesRule);
        _log.fine("listJpath=$listJpath");
        String formatJpath = listJpath ?? "";

        List<dynamic> jsonList = _jsonPathN(json, formatJpath);
        YamlMap foreachRule = contentRule["foreach"];

        var list = [];
        _log.fine("listList=$jsonList");
        for (int i = 0; i < jsonList.length; i++) {
          var item = {};
          foreachRule.forEach((key, value) {
            dynamic result = _recursionQuery(json, formatJpath, value, index: i);
            _log.fine("propName=$key;propValue=$result");
            item[key] = result;
          });
          list.add(item);
        }
        _log.fine("result=${list.toString()}");
        return list;
      default:
        return _getOne(json, pJPath, rule, index: index, defaultValue: defaultValue);
    }
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

  String? _getJsonPath(YamlMap rule) {
    _log.fine("getJPath:rule=$rule");
    String? jpath = rule["jsonpath"];
    return jpath;
  }

  List<dynamic> _jsonPathN(Map<String, dynamic> json, String jpath) {
    JsonPath jsonPath = JsonPath(jpath);
    _log.fine("jsonPath.read(json)=${jsonPath.read(json)}");
    List<dynamic> jsonList = jsonPath.read(json).elementAt(0).value as List<dynamic>;
    return jsonList;
  }

  Object? _jsonPathOne(Map<String, dynamic> json, String jpath) {
    JsonPath jsonPath = JsonPath(jpath);
    return jsonPath.read(json).elementAt(0).value;
  }

  String _formatJsonPath(String pJPath, String curJPath, int? index) {
    if(index == null){
      return "$pJPath$curJPath";
    }else{
      return "$pJPath[$index]$curJPath";
    }
  }

  String _getOne(Map<String, dynamic> json, String pJPath, YamlMap? rule,
      {int? index, String defaultValue = ""}) {
    if (rule == null) {
      return defaultValue;
    } else {
      String result = _queryOne(json, pJPath, rule, index);
      _log.fine("_getOne result=$result");
      return result;
    }
  }

  Future<String> homeRequestBy(YamlMap webPage) async {
    YamlMap homePage = webPage['homePage'];
    String requestBy = homePage['meta']?['requestBy'] ??= "dio";
    return requestBy;
  }

  /// 查找单个
  /// 分为三步，每一步都返回一个字符串
  String _queryOne(Map<String, dynamic> json, String pJPath, YamlMap yamlMap, int? index) {
    _log.fine("pJPath=$pJPath");
    String result = "";
    //第一步，定位元素并获取值
    result = _get(json, pJPath, index, yamlMap['get']);
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
  String _get(Map<String, dynamic> json, String pJPath, int? index, YamlMap yamlMap) {
    String? jsonPath = _getJsonPath(yamlMap["get"]);
    String defaultValue = yamlMap['default'] ?? "";
    if(jsonPath == null) defaultValue;
    String queryJPath = _formatJsonPath(pJPath, jsonPath! , index);
    var result = _jsonPathOne(json, queryJPath);
    //没查找到数据用默认结果
    if(result == null || result.toString().isEmpty){
      return defaultValue;
    }
    return result.toString();
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
