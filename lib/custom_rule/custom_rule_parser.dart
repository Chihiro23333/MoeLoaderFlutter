import 'dart:convert';
import 'package:logging/logging.dart';
import 'package:yaml/yaml.dart';

class CustomRuleParser{

  final _log = Logger('CustomRuleParser');

  YamlMap _customDoc;

  CustomRuleParser(this._customDoc);

  Map<String, String> headers() {
    YamlMap? headersRule = _customDoc['headers'];
    _log.fine("getHeaders:result=$headersRule");
    return Map.castFrom(headersRule?.value ?? {});
  }

  /*
  formatParams格式:{"page":"1", key:"value"}
   */
  String url(String pageName, Map<String, String> formatParams) {
    YamlMap? urlRule = _customDoc['url']?[pageName];
    String url = "";
    if (urlRule != null) {
      String link = urlRule["link"];
      int pageBase = urlRule["pageBase"] ?? 1;
      String page = formatParams["page"] ?? "1";
      page = (int.parse(page) * pageBase).toString();
      formatParams["page"] = page;
      url = _commonFormatUrl(_customDoc["url"]?[pageName], link, formatParams);
    }
    _log.fine("getUrl:url=$url");
    return url;
  }

  String options(String pageName) {
    var optionsRule = _customDoc["url"]?[pageName]?["options"];
    _log.fine("optionsRule=$optionsRule");
    return jsonEncode(optionsRule ?? []);
  }

  String displayInfo(String pageName) {
    return jsonEncode(_customDoc["display"]?[pageName] ?? {});
  }

  int columnCount(String pageName){
    return _customDoc["display"]?[pageName]?["columnCount"] ?? 6.toInt();
  }

  double aspectRatio(String pageName){
    return _customDoc["display"]?[pageName]?["aspectRatio"] ?? 0.65.toDouble();
  }

  String _commonFormatUrl(YamlMap? pageUrlRule, String link,
      Map<String, String> formatParams) {
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
          if(element["id"] == text){
            value = element["items"]?[0]?["param"];
          }
        }
      }
      _log.fine('value= $value');
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
}