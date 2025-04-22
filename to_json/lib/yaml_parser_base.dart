import 'package:flutter/widgets.dart';
import 'package:logging/logging.dart';
import 'package:to_json/models.dart';
import 'package:to_json/yaml_global.dart';
import 'package:yaml/yaml.dart';

abstract class Parser {
  final _log = Logger('Parser');

  static const fail = 0;
  static const success = 1;
  static const needChallenge = 2;
  static const needLogin = 3;
  static const interrupt = 4;

  late GlobalParams _globalParams;
  ParseState _parseState = ParseState(Parser.success, "成功");

  String webPageName(YamlMap yamlCustomDoc) {
    return yamlCustomDoc["meta"]?["name"] ?? "";
  }

  String pageType(YamlMap yamlCustomDoc) {
    return yamlCustomDoc["meta"]?["pageType"] ?? "";
  }

  YamlMap customRule(YamlMap yamlCustomDoc){
    return yamlCustomDoc["custom"];
  }

  @protected
  String handleResult(String result, YamlMap yamlMap) {
    //第二步，查找值
    var findRule = yamlMap["find"];
    if (findRule != null) {
      result = _find(result, findRule);
      _log.fine("find=$result");
    }
    //第三步，规整值
    var formatRule = yamlMap["format"];
    if (formatRule != null) {
      result = _format(result, formatRule);
      _log.fine("format=$result");
    }
    _log.fine("_queryOne=$result");
    return result;
  }

  @protected
  String regularString(String text) {
    // text = text.replaceAll("\n", "");
    // text = text.trim();
    return text;
  }

  String _find(String value, YamlList findRule) {
    String result = value;
    for (YamlMap? rule in findRule) {
      if (rule != null) {
        RegExp? linkRegExp;

        YamlMap? regexRule = rule["regex"];
        if (regexRule != null) {
          String? regex = regexRule["regex"];
          if (regex != null) {
            linkRegExp = RegExp(regex);
            int? indexRule = regexRule["index"];
            if (indexRule != null) {
              result = linkRegExp.firstMatch(value)?.group(indexRule) ?? "";
            }
          }
        }
        ;
      }
    }
    result = regularString(result);
    return result;
  }

  String _format(String chooseResult, YamlList formatRule) {
    String result = chooseResult;
    for (YamlMap? rule in formatRule) {
      if (rule != null) {
        YamlMap? concatRule = rule["concat"];
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

        YamlMap? replaceAllRule = rule["replaceAll"];
        if (replaceAllRule != null) {
          String? fromRule = replaceAllRule["from"];
          String? toRule = replaceAllRule["to"];
          if (fromRule != null && toRule != null) {
            result = result.replaceAll(fromRule, toRule);
          }
        }

        YamlMap? splitRule = rule["split"];
        if (splitRule != null) {
          String by = splitRule["by"] ?? " ";
          int index = splitRule["index"] ?? 0;
          List<String> list = result.split(by);
          if(index >= 0){
            if(index > list.length - 1){
              index = 0;
            }
          }else{
            index = list.length + index;
            if(index < 0){
              index = 0;
            }
          }
          result = list[index];
        }
      }
    }
    return result;
  }

  configGlobalParams(GlobalParams globalParams) {
    _globalParams = globalParams;
  }

  Connector? connector(){
    return _globalParams.connector;
  }

  Map<String, String> globalParams(){
    return _globalParams.params ?? {};
  }

  GlobalParser? globalParser(){
    return _globalParams.globalParser;
  }

  ParseState parseState(){
    return _parseState;
  }

  Future<void> onState(int code, String message) async {
    _parseState = ParseState(code, message);
  }

  void reset(){
    _parseState = ParseState(Parser.success, "成功");
  }

  Future<String> parseUseYaml(String content, YamlMap doc, String pageName, {Map<String, String>? headers, Map<String, String>? params});

}

abstract class Connector{

  Future<String> request(String url, {Map<String, String>? headers});

}

class ParseState{
  int code;
  String message;

  ParseState(this.code, this.message);
}
