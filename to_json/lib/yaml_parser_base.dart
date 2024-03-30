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

  Future<Map<String, String>> headers(YamlMap yamlDoc) async {
    YamlMap meta = yamlDoc['meta'];
    YamlMap? headersRule = meta['headers'];
    _log.fine("getHeaders:result=$headersRule");
    return Map.castFrom(headersRule?.value ?? {});
  }

  /*
  formatParams格式:{"page":"1", key:"value"}
   */
  Future<String> url(YamlMap yamlDoc, String pageName,
      Map<String, String> formatParams) async {
    YamlMap? urlRule = yamlDoc['url']?[pageName];
    String url = "";
    if (urlRule != null) {
      String link = urlRule["link"];
      int pageBase = urlRule["pageBase"] ?? 1;
      String page = formatParams["page"] ?? "1";
      page = (int.parse(page) * pageBase).toString();
      formatParams["page"] = page;
      url = await _commonFormatUrl(yamlDoc["url"]?[pageName], link, formatParams);
    }
    _log.fine("getJsonHomeUrl:url=$url");
    return url;
  }

  Future<String> webPageName(YamlMap yamlDoc) async {
    return yamlDoc["meta"]?["name"] ?? "";
  }

  Future<String> pageType(YamlMap yamlDoc) async {
    return yamlDoc["meta"]?["pageType"] ?? "";
  }

  Future<String> favicon(YamlMap yamlDoc) async {
    return yamlDoc["meta"]?["favicon"] ?? "";
  }

  Future<String> options(YamlMap yamlDoc, String pageName) async {
    var optionsRule = yamlDoc["url"]?[pageName]?["options"];
    _log.fine("optionsRule=$optionsRule");
    return jsonEncode(optionsRule ?? []);
  }

  Future<String> displayInfo(YamlMap yamlDoc, String pageName) async {
    return toResult(success, "解析成功", yamlDoc["display"]?[pageName] ?? {});
  }

  Future<String> _commonFormatUrl(YamlMap? pageUrlRule, String link,
      Map<String, String> formatParams) async {
    String pattern = r'\${(.*?)\}';
    // 使用正则表达式匹配被{}包围的内容
    RegExp regExp = RegExp(pattern);
    Iterable iterator = regExp.allMatches(link);
    // 遍历匹配结果并打印
    for (Match match in iterator) {
      String? text = match.group(1);
      _log.info('找到匹配内容: $text');
      String? value = formatParams[text];
      _log.info('value= $value');
      YamlList? optionsRule = pageUrlRule?["options"];
      //查找默认的值
      if (optionsRule != null && value == null) {
        for (var element in optionsRule) {
          if(element["id"] == text){
            value = element["items"]?[0]?["param"];
          }
        }
      }
      _log.info('value= $value');
      if(value != null && pageUrlRule != null){
        String? connector = pageUrlRule["${text}Connector"];
        if(connector != null){
          value = value.trim().replaceAll(" ", connector);
        }
      }
      link = link.replaceAll("\${$text}", value ?? "");
    }
    return link;
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

  Future<String> parseUseYaml(String content, YamlMap doc, String pageName);
}
