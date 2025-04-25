import 'dart:convert';
import 'package:html/dom.dart';
import 'package:html/parser.dart';
import 'package:logging/logging.dart';
import 'package:to_json/yaml_parser_base.dart';
import 'package:yaml/yaml.dart';

class YamlHtmlParser extends Parser {
  final _log = Logger('YamlHtmlCommonParser');

  static const defaultConnector = ",";

  @override
  Future<String> parseUseYaml(String content, YamlMap doc, String pageName,
      {Map<String, String>? headers, Map<String, String>? params}) async {
    _log.fine("html=$content");
    Document document = parse(content);
    Element? body = document.querySelector("html");
    //解析文本拿到结果
    YamlMap onParseResult = doc["onParseResult"];
    var object = _recursionQuery(body, onParseResult, params: params);
    if(object is String){
      return object;
    }
    String json = jsonEncode(object);
    _log.fine("json=$json");
    return json;
  }

  dynamic _recursionQuery(Element? element, YamlMap rule,
      {Map<String, String>? params}) {
    String? dataType;
    for (var element in rule.keys) {
      if (element.toString() == "list" ||
          element.toString() == "object" ||
          element.toString() == "string") {
        dataType = element.toString();
        break;
      }
    }
    _log.fine("dataType=$dataType");
    switch (dataType) {
      case "string":
        YamlMap contentRule = rule[dataType];
        _log.fine("contentRule=$contentRule");
        String result = _queryOne(element, contentRule);
        return result;
      case "object":
        YamlMap contentRule = rule[dataType];
        _log.fine("contentRule=$contentRule");
        var object = {};
        contentRule.forEach((key, value) {
          dynamic result = _recursionQuery(element, value, params: params);
          _log.fine("propName=$key;propValue=$result");
          object[key] = result;
        });
        return object;
      case "list":
        YamlMap contentRule = rule[dataType];
        _log.fine("contentRule=$contentRule");
        YamlMap foreachRule = contentRule["foreach"];
        List list = [];
        List<Element> listList = _queryN(element, contentRule);
        _log.fine("listList=$listList");
        for (Element element in listList) {
          var item = {};
          foreachRule.forEach((key, value) {
            dynamic result = _recursionQuery(element, value, params: params);
            _log.fine("propName=$key;propValue=$result");
            item[key] = result;
          });
          list.add(item);
        }
        _log.fine("result=${list.toString()}");
        return list;
      default:
        return _queryOne(element, rule);
    }
  }

  /// 查找多个
  List<Element> _queryN(Element? element, YamlMap yamlMap) {
    //第一步，查找
    List<Element> list = [];
    YamlMap getElementsRule = yamlMap["getElements"];
    String? css = getElementsRule["cssSelector"];
    if (css == null) throw "first rule must be cssSelector！";
    list = element?.querySelectorAll(css) ?? [];
    _log.fine("list=$list");
    //第二步，筛选元素
    _filterList(list, yamlMap);
    _log.fine("list=$list");
    return list;
  }

  /// 查找单个
  /// 分为三步，每一步都返回一个字符串
  String _queryOne(Element? element, YamlMap yamlMap) {
    String result = "";
    //第一步，定位元素并获取值
    result = _get(element, yamlMap['get']);
    _log.info("get=$result");
    if (result.isNotEmpty) {
      result = handleResult(result, yamlMap);
    }
    _log.warning("handleResult=$result");
    return result;
  }

  String _get(Element? element, YamlMap yamlMap) {
    List<Element?>? resultElements;
    String result = "";
    //查找获取元素，可以是N
    String? css = yamlMap["cssSelector"];
    String defaultValue = yamlMap['default'] ?? "";
    if (css == null) return defaultValue;
    if (css == "") {
      resultElements = [element];
    } else {
      resultElements = element?.querySelectorAll(css);
    }

    int? index = yamlMap["index"];
    if (index != null &&
        resultElements != null &&
        index <= resultElements.length - 1) {
      resultElements = [resultElements[index]];
    }

    String connector = yamlMap["connector"] ?? defaultConnector;

    //获取特定属性并拼接
    String? attrRule = yamlMap["attr"];
    if (attrRule != null) {
      int length = resultElements?.length ?? 0;
      if (length > 0) {
        resultElements?.forEach((element) {
          String attr = element?.attributes[attrRule] ?? "";
          attr = regularString(attr);
          if (attr.isNotEmpty) {
            result = "$result$attr$connector";
          }
        });
        if (result.isNotEmpty) {
          result = result.substring(0, result.length - 1);
        }
      }
    }
    //获取text并拼接
    String? textRule = yamlMap["text"];
    if (textRule != null) {
      int length = resultElements?.length ?? 0;
      if (length > 0) {
        resultElements?.forEach((element) {
          String text = element?.text ?? "";
          text = regularString(text);
          _log.fine("text=${text.length}");
          if (text.isNotEmpty) {
            result = "$result$text$connector";
          }
        });
        if (result.isNotEmpty) {
          result = result.substring(0, result.length - 1);
        }
      }
    }

    if (result.isEmpty) {
      return defaultValue;
    }
    return result;
  }

  void _filterList(List<Element> list, YamlMap yamlMap) {
    var filterRule = yamlMap["filter"];
    if (filterRule != null) {
      for (YamlMap? yamlMap in filterRule) {
        if (yamlMap != null) {
          YamlMap? hasRule = yamlMap["has"];
          if (hasRule != null) {
            String? cssSelectorRule = hasRule["cssSelector"];
            if (cssSelectorRule != null) {
              list.removeWhere((element) {
                Element? findElement = element.querySelector(cssSelectorRule);
                return findElement == null;
              });
            }
          }
        }
      }
    }
  }
}
