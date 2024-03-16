import 'package:MoeLoaderFlutter/yamlhtmlparser/yaml_parse_mix.dart';
import 'package:MoeLoaderFlutter/yamlhtmlparser/yaml_rule_factory.dart';
import 'package:logging/logging.dart';
import 'package:yaml/yaml.dart';
import 'models.dart';

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

  Future<String> getJsonHeaders(String sourceName) async {
    YamlMap yamlDoc = await YamlRuleFactory().create(sourceName);
    YamlMap meta = yamlDoc['meta'];
    YamlMap? headersRule = meta['headers'];
    _log.fine("getHeaders:result=$headersRule");
    return headersRule.toString();
  }

  Future<Map<String, String>?> getHeaders(YamlMap webPage) async {
    YamlMap meta = webPage['meta'];
    YamlMap? headersRule = meta['headers'];
    if (headersRule == null) return null;
    Map<String, String> result = {};
    headersRule.forEach((key, value) {
      result[key] = value;
    });
    _log.fine("getHeaders:result=$result");
    return result;
  }

  Future<String> getJsonHomeUrl(String sourceName, String page,
      {List<YamlOption>? optionList}) async {
    YamlMap yamlDoc = await YamlRuleFactory().create(sourceName);
    YamlMap urlRule = yamlDoc['url'];
    YamlMap homeRule = urlRule['home'];

    String url = "";
    String link = homeRule["link"];
    int pageBase = homeRule["pageBase"] ?? 1;
    page = (int.parse(page) * pageBase).toString();
    await _defaultOption(yamlDoc, optionList);
    _log.fine("optionList:optionList=$optionList");
    url = await _formatUrl(link, page, optionList: optionList);
    _log.fine("getUrl:url=$url");
    return url;
  }

  Future<String> getHomeUrl(YamlMap webPage, String page,
      {List<YamlOption>? optionList}) async {
    YamlMap urlRule = webPage['url'];
    YamlMap homeRule = urlRule['home'];

    String url = "";
    String link = homeRule["link"];
    int pageBase = homeRule["pageBase"] ?? 1;
    page = (int.parse(page) * pageBase).toString();
    await _defaultOption(webPage, optionList);
    _log.fine("optionList:optionList=$optionList");
    url = await _formatUrl(link, page, optionList: optionList);
    _log.fine("getUrl:url=$url");
    return url;
  }

  Future<String> getJsonSearchUrl(String sourceName,
      {String? page, String? tags, List<YamlOption>? optionList}) async {
    YamlMap yamlDoc = await YamlRuleFactory().create(sourceName);
    YamlMap urlRule = yamlDoc['url'];
    YamlMap searchRule = urlRule['search'];

    String url = "";
    if (tags != null && page != null) {
      String? connectorRule = searchRule["tagConnector"];
      if (connectorRule != null) {
        //记得去掉首尾不必要的空格，避免tags添加连接符的时候多加了
        tags = tags.trim().replaceAll(" ", connectorRule);
      }
      String link = searchRule["link"];
      int pageBase = searchRule["pageBase"] ?? 1;
      page = (int.parse(page) * pageBase).toString();
      await _defaultOption(yamlDoc, optionList);
      url = await _formatUrl(link, page, tags: tags, optionList: optionList);
    }

    _log.fine("getUrl:url=$url");
    return url;
  }

  Future<String> getSearchUrl(YamlMap webPage,
      {String? page, String? tags, List<YamlOption>? optionList}) async {
    YamlMap urlRule = webPage['url'];
    YamlMap searchRule = urlRule['search'];

    String url = "";
    if (tags != null && page != null) {
      String? connectorRule = searchRule["tagConnector"];
      if (connectorRule != null) {
        //记得去掉首尾不必要的空格，避免tags添加连接符的时候多加了
        tags = tags.trim().replaceAll(" ", connectorRule);
      }
      String link = searchRule["link"];
      int pageBase = searchRule["pageBase"] ?? 1;
      page = (int.parse(page) * pageBase).toString();
      await _defaultOption(webPage, optionList);
      url = await _formatUrl(link, page, tags: tags, optionList: optionList);
    }

    _log.fine("getUrl:url=$url");
    return url;
  }

  Future<String> getJsonName(String sourceName) async {
    YamlMap yamlDoc = await YamlRuleFactory().create(sourceName);
    return yamlDoc["meta"]?["name"] ?? "";
  }

  Future<String> getName(YamlMap doc) async {
    return doc["meta"]?["name"] ?? "";
  }

  Future<String> optionList(String sourceName) async {
    YamlMap yamlDoc = await YamlRuleFactory().create(sourceName);
    var optionsRule = yamlDoc["url"]["options"];
    _log.fine("optionsRule=$optionsRule");
    return optionsRule.toString();
  }

  Future<void> _defaultOption(
      YamlMap webPage, List<YamlOption>? inOptionList) async {
    if (inOptionList == null) return;
    // List<YamlOptionList> list = await optionList();
    List<YamlOptionList> list = [];
    if (list.isNotEmpty) {
      for (var item in list) {
        bool find = false;
        for (var inItem in inOptionList) {
          if (inItem.pId == item.id) {
            find = true;
            break;
          }
        }
        if (!find) {
          inOptionList.add(item.options[0]);
        }
      };
    }
  }

  Future<String> _formatUrl(String url, String? page,
      {String? tags, List<YamlOption>? optionList}) async {
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
        url = url.replaceAll("\${$text}", tags ?? "");
        continue;
      }
      _log.fine("optionList=$optionList");
      YamlOption? yamlOption;
      if (optionList != null) {
        for (var item in optionList) {
          if (item.pId == text) {
            yamlOption = item;
            break;
          }
        }
      }
      if (yamlOption != null) {
        url = url.replaceAll("\${$text}", yamlOption.param);
      } else {
        url = url.replaceAll("\${$text}", "");
      }
    }
    return url;
  }

  Future<List<YamlHomePageItem>> parseHome(String content, YamlMap webPage);

  Future<List<YamlHomePageItem>> parseSearch(String content, YamlMap webPage);

  Future<YamlDetailPage> parseDetail(String content, YamlMap webPage);
}
