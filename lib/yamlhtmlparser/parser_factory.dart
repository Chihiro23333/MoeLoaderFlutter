import 'dart:convert';

import 'package:MoeLoaderFlutter/yamlhtmlparser/utils.dart';
import 'package:MoeLoaderFlutter/yamlhtmlparser/yaml_parse_mix.dart';
import 'package:MoeLoaderFlutter/yamlhtmlparser/yaml_rule_factory.dart';
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
    return toResult(success, "解析成功", headersRule);
  }

  /*
  formatParams格式:{"page":"1","options":"key":[], key:"value"}
   */
  Future<String> url(String sourceName, String urlName,
      Map<String, String> formatParams) async {
    YamlMap yamlDoc = await YamlRuleFactory().create(sourceName);
    YamlMap urlRule = yamlDoc['url'];
    YamlMap homeRule = urlRule[urlName];

    String url = "";
    String link = homeRule["link"];
    int pageBase = homeRule["pageBase"] ?? 1;
    String page = formatParams["page"] ?? "1";
    page = (int.parse(page) * pageBase).toString();
    formatParams["page"] = page;
    url = await _commonFormatUrl(yamlDoc, link, formatParams);
    _log.fine("getJsonHomeUrl:url=$url");
    return toResult(success, "解析成功", url);
  }

  Future<String> homeUrl(String sourceName, String page,
      {List<Option>? chooseOption}) async {
    YamlMap yamlDoc = await YamlRuleFactory().create(sourceName);
    YamlMap urlRule = yamlDoc['url'];
    YamlMap homeRule = urlRule['home'];

    String url = "";
    String link = homeRule["link"];
    int pageBase = homeRule["pageBase"] ?? 1;
    page = (int.parse(page) * pageBase).toString();
    _log.fine("chooseOption=$chooseOption");
    url = await _formatUrl(yamlDoc, link, page, chooseOption: chooseOption);
    _log.fine("getJsonHomeUrl:url=$url");
    return toResult(success, "解析成功", url);
  }

  Future<String> searchUrl(String sourceName, String page, String searchKey,
      {List<Option>? chooseOption}) async {
    YamlMap yamlDoc = await YamlRuleFactory().create(sourceName);
    YamlMap urlRule = yamlDoc['url'];
    YamlMap searchRule = urlRule['search'];

    String url = "";
    String? connectorRule = searchRule["tagConnector"];
    if (connectorRule != null) {
      //记得去掉首尾不必要的空格，避免tags添加连接符的时候多加了
      searchKey = searchKey.trim().replaceAll(" ", connectorRule);
    }
    String link = searchRule["link"];
    int pageBase = searchRule["pageBase"] ?? 1;
    page = (int.parse(page) * pageBase).toString();
    url = await _formatUrl(yamlDoc, link, page,
        searchKey: searchKey, chooseOption: chooseOption);
    _log.fine("getJsonSearchUrl:url=$url");
    return toResult(success, "解析成功", url);
  }

  Future<String> webPageName(String sourceName) async {
    YamlMap yamlDoc = await YamlRuleFactory().create(sourceName);
    return toResult(success, "解析成功", yamlDoc["meta"]?["name"] ?? "");
  }

  Future<String> options(String sourceName) async {
    YamlMap yamlDoc = await YamlRuleFactory().create(sourceName);
    var optionsRule = yamlDoc["url"]["options"];
    _log.fine("optionsRule=$optionsRule");
    return toResult(success, "解析成功", optionsRule);
  }

  Future<String> displayInfo(String sourceName) async {
    YamlMap yamlDoc = await YamlRuleFactory().create(sourceName);
    return toResult(success, "解析成功", yamlDoc["display"] ?? "");
  }

  String _findOptionParam(YamlMap yamlDoc, dynamic option) {
    var optionsRule = yamlDoc["url"]["options"];
    String result = "";
    if (optionsRule != null) {
      for (var item in optionsRule) {
        if (option.id == item["id"]) {
          return item["items"][option.index]["param"];
        }
      }
    }
    return result;
  }

  String _findCommonOptionParam(YamlMap yamlDoc, Map<String, dynamic> option) {
    var optionsRule = yamlDoc["url"]["options"];
    String result = "";
    if (optionsRule != null) {
      for (var item in optionsRule) {
        return item["items"][option["index"]]["param"];
      }
    }
    return result;
  }

  Future<String> _commonFormatUrl(
      YamlMap yamlDoc, String url, Map<String, String> formatParams) async {
    String pattern = r'\${(.*?)\}';
    // 使用正则表达式匹配被{}包围的内容
    RegExp regExp = RegExp(pattern);
    Iterable iterator = regExp.allMatches(url);
    // 遍历匹配结果并打印
    for (Match match in iterator) {
      String? text = match.group(1);
      _log.fine('找到匹配内容: $text');
      String? value = formatParams[text];
      _log.info('value= $value');
      url = url.replaceAll("\${$text}", value ?? "");
    }
    return url;
  }

  Future<String> _formatUrl(YamlMap yamlDoc, String url, String page,
      {String? searchKey, List<Option>? chooseOption}) async {
    String pattern = r'\${(.*?)\}';
    // 使用正则表达式匹配被{}包围的内容
    RegExp regExp = RegExp(pattern);
    Iterable iterator = regExp.allMatches(url);
    // 遍历匹配结果并打印
    for (Match match in iterator) {
      String? text = match.group(1);
      _log.fine('找到匹配内容: $text');
      if ("page" == text) {
        url = url.replaceAll("\${$text}", page ?? "");
        continue;
      }
      if ("tag" == text) {
        url = url.replaceAll("\${$text}", searchKey ?? "");
        continue;
      }
      _log.fine("chooseOption=$chooseOption");
      Option? option;
      if (chooseOption != null) {
        for (var item in chooseOption) {
          if (item.id == text) {
            option = item;
            break;
          }
        }
      }
      if (option != null) {
        url = url.replaceAll("\${$text}", _findOptionParam(yamlDoc, option));
      } else {
        url = url.replaceAll(
            "\${$text}", _findOptionParam(yamlDoc, Option(text ?? "", 0)));
      }
    }
    return url;
  }

  Future<String> parseUseYaml(
      String content, String sourceName, String pageName);
}

class Option {
  String id = "";
  int index = 0;

  Option(this.id, this.index);
}
