import 'package:FlutterMoeLoaderDesktop/yamlhtmlparser/yaml_parse_mix.dart';
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
  final log = Logger('Parser');

  Future<Map<String, String>?> getHeaders(YamlMap webPage) async {
    YamlMap meta = webPage['meta'];
    YamlMap? headersRule = meta['headers'];
    if (headersRule == null) return null;
    Map<String, String> result = {};
    headersRule.forEach((key, value) {
      result[key] = value;
    });
    log.fine("getHeaders:result=$result");
    return result;
  }

  Future<String> getHomeUrl(YamlMap webPage, String page) async {
    YamlMap urlRule = webPage['url'];
    YamlMap homeRule;
    YamlMap? safeHome = urlRule['safeHome'];
    if(safeHome == null){
      homeRule = urlRule['home'];
    }else{
      homeRule = safeHome;
    }

    String url = "";
    String link = homeRule["link"];
    int pageBase = homeRule["pageBase"] ?? 1;
    page = (int.parse(page) * pageBase).toString();
    url = _formatUrl(link, page);
    log.fine("getUrl:url=$url");
    return url;
  }

  Future<String> getSearchUrl(YamlMap webPage,
      {String? page, String? tags}) async {
    YamlMap urlRule = webPage['url'];
    YamlMap searchRule;
    YamlMap? safeSearch = urlRule['safeSearch'];
    if(safeSearch == null){
      searchRule = urlRule['search'];
    }else{
      searchRule = safeSearch;
    }

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
      url = _formatUrl(link, page, tags: tags);
    }

    log.fine("getUrl:url=$url");
    return url;
  }

  Future<String> getName(YamlMap doc) async {
    return doc["meta"]?["name"] ?? "";
  }

  String _formatUrl(String url, String? page, {String? tags}) {
    String pattern = r'\${(.*?)\}';
    // 使用正则表达式匹配被{}包围的内容
    RegExp regExp = RegExp(pattern);
    Iterable iterator = regExp.allMatches(url);
    // 遍历匹配结果并打印
    for (Match match in iterator) {
      String? text = match.group(1);
      log.fine('找到匹配内容: $text');
      if ("page" == text) {
        url = url.replaceAll("\${$text}", page ?? "");
      }
      if ("tag" == text) {
        url = url.replaceAll("\${$text}", tags ?? "");
      }
    }
    return url;
  }

  Future<List<YamlHomePageItem>> parseHome(String content, YamlMap webPage);

  Future<List<YamlHomePageItem>> parseSearch(String content, YamlMap webPage);

  Future<YamlDetailPage> parseDetail(String content, YamlMap webPage);
}
