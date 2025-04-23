import 'package:to_json/yaml_parser_base.dart';
import 'package:yaml/yaml.dart';
import 'package:logging/logging.dart';

abstract class YamlRequestBaseParser extends Parser {
  final _log = Logger('RequestParser');

  Future<String> parseUseYaml(String content, YamlMap doc, String pageName,
      {Map<String, String>? headers, Map<String, String>? params});

  Map<String, String> getHeaders(YamlMap doc) {
    YamlMap? headersRule = doc['headers'];
    _log.fine("getHeaders:result=$headersRule");
    return Map.castFrom(headersRule?.value ?? {});
  }

  /*
  formatParams格式:{"page":"1", key:"value"}
   */
  String getUrl(YamlMap doc, Map<String, String>? formatParams) {
    String url = "";
    String link = doc["link"];
    if (formatParams == null) return link;
    int pageBase = doc["pageBase"] ?? 1;
    int pageOffset = doc["pageOffset"] ?? 0;
    String page = formatParams["page"] ?? "1";
    page = (int.parse(page) * pageBase + pageOffset).toString();
    formatParams["page"] = page;
    url = _formatUrl(doc, link, formatParams);
    _log.fine("getUrl:url=$url");
    return url;
  }

  /*
  formatParams格式:{"page":"1", key:"value"}
   */
  String getRedirectUrl(YamlMap doc, Map<String, String>? formatParams) {
    String url = "";
    String redirectLink = doc["redirectLink"];
    if (formatParams == null) return redirectLink;
    int pageBase = doc["pageBase"] ?? 1;
    int pageOffset = doc["pageOffset"] ?? 0;
    String page = formatParams["page"] ?? "1";
    page = (int.parse(page) * pageBase + pageOffset).toString();
    formatParams["page"] = page;
    url = _formatUrl(doc, redirectLink, formatParams);
    _log.fine("getUrl:url=$url");
    return url;
  }

  String _formatUrl(
      YamlMap? pageUrlRule, String link, Map<String, String> formatParams) {
    String pattern = r'\${(.*?)\}';
    // 使用正则表达式匹配被{}包围的内容
    RegExp regExp = RegExp(pattern);
    Iterable iterator = regExp.allMatches(link);
    // 遍历匹配结果并打印
    for (Match match in iterator) {
      String? text = match.group(1);
      _log.fine('找到匹配内容: $text');
      String? value = formatParams[text]?.toLowerCase();
      _log.fine('value= $value');
      YamlList? optionsRule = pageUrlRule?["options"];
      //查找默认的值
      if (optionsRule != null && value == null) {
        for (var element in optionsRule) {
          if (element["id"] == text) {
            value = element["items"]?[0]?["param"];
          }
        }
      }
      _log.fine('value= $value');
      if (value != null && pageUrlRule != null) {
        String? connector = pageUrlRule["${text}Connector"];
        if (connector != null) {
          value = value.trim().replaceAll(" ", connector);
        }
      }
      link = link.replaceAll("\${$text}", value ?? "");
    }
    return link;
  }
}
