import 'dart:convert';
import 'package:MoeLoaderFlutter/yamlhtmlparser/parser_factory.dart';
import 'package:MoeLoaderFlutter/yamlhtmlparser/yaml_rule_factory.dart';
import 'package:html/dom.dart';
import 'package:html/parser.dart';
import 'package:logging/logging.dart';
import 'package:yaml/yaml.dart';

class YamlHtmlParser extends Parser {
  final _log = Logger('YamlHtmlCommonParser');

  static const defaultConnector = ",";
  static const defaultSeparator = ",";

  @override
  Future<String> parseUseYaml(
      String content, String sourceName, String pageName) async {
    _log.fine("html=$content");
    YamlMap doc = await YamlRuleFactory().create(sourceName);
    YamlMap? page = doc[pageName];
    if (page == null) {
      throw "pageName不存在";
    }
    Document document = parse(content);
    Element? body = document.querySelector("html");
    //解析文本拿到结果
    YamlMap onParseResult = page["onParseResult"];
    String json = jsonEncode(_recursionQuery(body, onParseResult));
    _log.fine("json=$json");
    return json;
  }

  dynamic _recursionQuery(Element? element, YamlMap rule) {
    String? dataType;
    for (var element in rule.keys) {
      if (element.toString() == "contentType") continue;
      dataType = element.toString();
    }
    _log.info("dataType=$dataType");
    switch (dataType) {
      case "object":
        YamlMap contentRule = rule[dataType];
        _log.fine("contentRule=$contentRule");
        var object = {};
        contentRule.forEach((key, value) {
          dynamic result = _recursionQuery(element, value);
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
            dynamic result = _recursionQuery(element, value);
            _log.info("propName=$key;propValue=$result");
            item[key] = result;
          });
          list.add(item);
        }
        _log.fine("result=${list.toString()}");
        return list;
      default:
        return _getOne(element, rule);
    }
  }

  Future<String> preprocess(String content, YamlMap preprocessNode) async {
    String? contentType = preprocessNode["contentType"];
    _log.fine("contentType=$contentType,html=$content");
    if (contentType != null && contentType == "html") {
      Document document = parse(content);
      Element? html = document.querySelector("html");
      return _getOne(html, preprocessNode);
    }
    return content;
  }

  String _getOne(Element? element, YamlMap? rule, {String defaultValue = ""}) {
    if (rule == null) {
      return defaultValue;
    } else {
      String result = _queryOne(element, rule);
      _log.fine("_getOne result=$result");
      return result;
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
    return list;
  }

  /// 查找单个
  /// 分为三步，每一步都返回一个字符串
  String _queryOne(Element? element, YamlMap yamlMap) {
    String result = "";
    //第一步，定位元素并获取值
    result = _get(element, yamlMap['get']);
    _log.fine("get=$result");
    //第二步，查找值
    var findRule = yamlMap["find"];
    if (findRule != null) {
      result = _find(result, findRule);
      _log.fine("find=$result");
    }
    //第三步，规整拼接值
    var formatRule = yamlMap["format"];
    if (formatRule != null) {
      for (YamlMap? yamlMap in formatRule) {
        if (yamlMap != null) {
          result = _format(result, yamlMap);
          _log.fine("format=$result");
        }
      }
    }
    _log.fine("_queryOne=$result");
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

    String connector = yamlMap["connector"] ?? defaultConnector;

    //获取特定属性并拼接
    String? attrRule = yamlMap["attr"];
    if (attrRule != null) {
      int length = resultElements?.length ?? 0;
      if (length > 0) {
        resultElements?.forEach((element) {
          String attr = element?.attributes[attrRule] ?? "";
          attr = _regularString(attr);
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
          text = _regularString(text);
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

    if(result.isEmpty){
      return defaultValue;
    }
    return result;
  }

  void _filterList(List<Element> list, YamlMap yamlMap) {
    var filterRule = yamlMap["filter"];
    if (filterRule != null) {
      for (YamlMap? yamlMap in filterRule) {
        if (yamlMap != null) {
          YamlMap? removeRule = yamlMap["remove"];
          if (removeRule != null) {
            String? cssSelectorRule = removeRule["cssSelector"];
            if (cssSelectorRule != null) {
              list.removeWhere((element) {
                Element? findElement = element.querySelector(cssSelectorRule);
                return findElement != null;
              });
            }
          }
        }
      }
    }
  }

  String _find(String value, YamlList yamlList) {
    String result = value;
    for (var item in yamlList) {
      RegExp? linkRegExp;
      YamlMap? regexRule = item["regex"];
      if (regexRule != null) {
        linkRegExp = RegExp(regexRule["regex"]);
        int indexRule = regexRule["index"] ?? 0;
        result = linkRegExp.firstMatch(value)?.group(indexRule) ?? "";
      }
      result = _regularString(result);
    }
    return result;
  }

  String _format(String chooseResult, YamlMap formatRule) {
    String result = chooseResult;

    YamlMap? concatRule = formatRule["concat"];
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

    YamlMap? replaceAllRule = formatRule["replaceAll"];
    if (replaceAllRule != null) {
      String? fromRule = replaceAllRule["from"];
      String? toRule = replaceAllRule["to"];
      if (fromRule != null && toRule != null) {
        result = result.replaceAll(fromRule, toRule);
      }
    }

    return result;
  }

  String _regularString(String text) {
    text = text.replaceAll("\n", "");
    text = text.trim();
    return text;
  }
}
