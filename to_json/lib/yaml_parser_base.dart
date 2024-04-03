import 'dart:convert';

import 'package:flutter/widgets.dart';
import 'package:logging/logging.dart';
import 'package:to_json/utils.dart';
import 'package:yaml/yaml.dart';

abstract class Parser {
  final _log = Logger('Parser');

  static const fail = 0;
  static const success = 1;
  static const needChallenge = 2;
  static const needLogin = 3;

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
    //第二步，筛选值
    var filterRule = yamlMap["filter"];
    if (filterRule != null) {
      result = _find(result, filterRule);
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
    text = text.replaceAll("\n", "");
    text = text.trim();
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
      }
    }
    return result;
  }

  Future<String> preprocess(String content, YamlMap preprocessNode);

  Future<String> parseUseYaml(String content, YamlMap doc, String pageName);
}
