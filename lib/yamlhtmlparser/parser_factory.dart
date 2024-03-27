import 'package:MoeLoaderFlutter/yamlhtmlparser/utils.dart';
import 'package:MoeLoaderFlutter/yamlhtmlparser/yaml_parse_mix.dart';
import 'package:MoeLoaderFlutter/yamlhtmlparser/yaml_rule_factory.dart';
import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import 'package:yaml/yaml.dart';

class ParserFactory {
  static ParserFactory? _cache;

  ParserFactory._create();

  factory ParserFactory() {
    return _cache ?? (_cache = ParserFactory._create());
  }

  final MixParser _mixParser = MixParser();

  Parser createParser() {
    return _mixParser;
  }
}

abstract class Parser {
  final _log = Logger('Parser');

  static const fail = 0;
  static const success = 1;
  static const needChallenge = 2;
  static const needLogin = 3;

  Future<String> headers(String sourceName) async {
    YamlMap yamlDoc = await YamlRuleFactory().create(sourceName);
    YamlMap meta = yamlDoc['meta'];
    YamlMap? headersRule = meta['headers'];
    _log.fine("getHeaders:result=$headersRule");
    return toResult(success, "解析成功", headersRule ?? {});
  }

  /*
  formatParams格式:{"page":"1","options":"key":[], key:"value"}
   */
  Future<String> url(String sourceName, String pageName,
      Map<String, String> formatParams) async {
    YamlMap yamlDoc = await YamlRuleFactory().create(sourceName);
    YamlMap? urlRule = yamlDoc['url']?[pageName];
    String url = "";
    if(urlRule != null){
      String link = urlRule["link"];
      int pageBase = urlRule["pageBase"] ?? 1;
      String page = formatParams["page"] ?? "1";
      page = (int.parse(page) * pageBase).toString();
      formatParams["page"] = page;
      url = await _commonFormatUrl(link, formatParams);
    }
    _log.fine("getJsonHomeUrl:url=$url");
    return toResult(success, "解析成功", url);
  }

  Future<String> webPageName(String sourceName) async {
    YamlMap yamlDoc = await YamlRuleFactory().create(sourceName);
    return toResult(success, "解析成功", yamlDoc["meta"]?["name"] ?? "");
  }

  Future<String> options(String sourceName, String pageName) async {
    YamlMap yamlDoc = await YamlRuleFactory().create(sourceName);
    var optionsRule = yamlDoc["url"]?[pageName]?["options"];
    _log.fine("optionsRule=$optionsRule");
    return toResult(success, "解析成功", optionsRule ?? []);
  }

  Future<String> displayInfo(String sourceName, String pageName) async {
    YamlMap yamlDoc = await YamlRuleFactory().create(sourceName);
    return toResult(success, "解析成功", yamlDoc["display"]?[pageName] ?? {});
  }

  Future<String> _commonFormatUrl(
      String link, Map<String, String> formatParams) async {
    String pattern = r'\${(.*?)\}';
    // 使用正则表达式匹配被{}包围的内容
    RegExp regExp = RegExp(pattern);
    Iterable iterator = regExp.allMatches(link);
    // 遍历匹配结果并打印
    for (Match match in iterator) {
      String? text = match.group(1);
      _log.fine('找到匹配内容: $text');
      String? value = formatParams[text];
      _log.info('value= $value');
      link = link.replaceAll("\${$text}", value ?? "");
    }
    return link;
  }

  @protected
  String handleResult(String result, YamlMap yamlMap){
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


  String _find(String value, YamlMap yamlMap) {
    String result = value;
    RegExp? linkRegExp;

    String? regexRule = yamlMap["regex"];
    if (regexRule == null) throw "first rule must be regex！";
    linkRegExp = RegExp(regexRule);

    int? indexRule = yamlMap["index"];
    if (indexRule != null) {
      result = linkRegExp.firstMatch(value)?.group(indexRule) ?? "";
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

  Future<String> parseUseYaml(
      String content, String sourceName, String pageName);
}
