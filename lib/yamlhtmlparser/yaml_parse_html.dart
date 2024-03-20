import 'dart:convert';

import 'package:MoeLoaderFlutter/yamlhtmlparser/parser_factory.dart';
import 'package:MoeLoaderFlutter/yamlhtmlparser/yaml_rule_factory.dart';
import 'package:html/dom.dart';
import 'package:html/parser.dart';
import 'package:logging/logging.dart';
import 'package:yaml/yaml.dart';
import 'models.dart';

class YamlHtmlParser extends Parser {
  final _log = Logger('YamlHtmlCommonParser');

  static const defaultConnector = ",";
  static const defaultSeparator = ",";

  @override
  Future<String> parseUseYaml(String content, String sourceName, String pageName) async {
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
    String json = _recursionQuery(body, onParseResult);
    _log.fine("json=$json");
    return json;
  }

  String _recursionQuery(Element? element, YamlMap rule) {
    String? dataType;
    for (var element in rule.keys) {
      if(element.toString() == "contentType")continue;
      dataType = element.toString();
    }
    _log.fine("dataType=$dataType");
    YamlMap contentRule = rule[dataType];
    _log.fine("contentRule=$contentRule");
    switch (dataType) {
      case "object":
        var object = {};
        contentRule.forEach((key, value) {
          String result = _recursionQuery(element, value);
          _log.fine("propName=$key;propValue=$result");
          object[key] = result;
        });
        return jsonEncode(object);
      case "list":
        YamlMap foreachRule = contentRule["foreach"];
        var list = [];
        List<Element> listList = _queryN(element, contentRule);
        _log.fine("listList=$listList");
        for (Element element in listList) {
          var item = {};
          foreachRule.forEach((key, value) {
            String result = _recursionQuery(element, value);
            _log.fine("propName=$key;propValue=$result");
            item[key] = result;
          });
          list.add(item);
        }
        _log.fine("result=${list.toString()}");
        return jsonEncode(list);
      default:
        return _getOne(element, rule);
    }
  }

  @override
  Future<List<YamlHomePageItem>> parseHome(
      String content, YamlMap webPage) async {
    _log.fine("html=$content");
    Document document = parse(content);
    Element? body = document.querySelector("html");
    List<YamlHomePageItem> dataList = _listHomeLit(body, webPage);
    return dataList;
  }

  @override
  Future<List<YamlHomePageItem>> parseSearch(String content, YamlMap webPage) {
    return parseHome(content, webPage);
  }

  @override
  Future<YamlDetailPage> parseDetail(String content, YamlMap webPage) async {
    _log.fine("html=$content");
    Document document = parse(content);

    YamlMap object = webPage['object'];
    YamlMap urlRule = object['url'];
    YamlMap? previewRule = object['preview'];

    Element? body = document.querySelector("html");
    String url = _getOne(body, urlRule);
    _log.fine("url=$url");
    String preview = _getOne(body, previewRule);
    _log.fine("preview=$preview");
    CommonInfo commonInfo = _getCommonInfo(object, body);
    _log.fine("commonInfo=${commonInfo.id}");
    YamlDetailPage yamlDetailPage =
        YamlDetailPage(url, preview, commonInfo: commonInfo);
    return yamlDetailPage;
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

  List<YamlHomePageItem> _listHomeLit(Element? element, YamlMap webPage) {
    YamlMap list = webPage["onParseResult"]["list"];
    YamlMap foreach = list["foreach"];

    YamlMap coverUrlRule = foreach["coverUrl"];
    YamlMap hrefRule = foreach["href"];
    YamlMap? widthRule = foreach['width'];
    YamlMap? heightRule = foreach['height'];

    List<YamlHomePageItem> dataList = [];
    List<Element> listList = _queryN(element, list);
    for (Element element in listList) {
      String coverUrl = _getOne(element, coverUrlRule);
      _log.fine("coverUrl=$coverUrl");
      String href = _getOne(element, hrefRule);
      _log.fine("href=$href");
      String width = _getOne(element, widthRule, defaultValue: "0");
      _log.fine("width=$width");
      String height = _getOne(element, heightRule, defaultValue: "0");
      _log.fine("height=$height");
      CommonInfo commonInfo = _getCommonInfo(foreach, element);
      _log.fine("commonInfo=$commonInfo");
      dataList.add(YamlHomePageItem(
          coverUrl, href, double.parse(width), double.parse(height),
          commonInfo: commonInfo));
    }
    return dataList;
  }

  CommonInfo _getCommonInfo(YamlMap yamlMap, Element? element) {
    YamlMap? idRule = yamlMap['id'];
    YamlMap? authorRule = yamlMap['author'];
    YamlMap? charactersRule = yamlMap['characters'];
    YamlMap? fileSizeRule = yamlMap['fileSize'];
    YamlMap? dimensionsRule = yamlMap['dimensions'];
    YamlMap? sourceRule = yamlMap['source'];
    YamlMap? bigUrlRule = yamlMap['bigUrl'];
    YamlMap? rawUrlRule = yamlMap['rawUrl'];
    YamlMap? tagsRule = yamlMap['tags'];

    String id = _getOne(element, idRule);
    _log.fine("id=$id");
    String author = _getOne(element, authorRule);
    _log.fine("author=$author");
    String characters = _getOne(element, charactersRule);
    _log.fine("characters=$characters");
    String fileSize = _getOne(element, fileSizeRule);
    _log.fine("fileSize=$fileSize");
    String dimensions = _getOne(element, dimensionsRule);
    _log.fine("dimensions=$dimensions");
    String source = _getOne(element, sourceRule);
    _log.fine("source=$source");
    String rawUrl = _getOne(element, rawUrlRule);
    _log.fine("rawUrl=$rawUrl");
    String bigUrl = _getOne(element, bigUrlRule);
    _log.fine("bigUrl=$bigUrl");
    List<YamlTag> tagsList = _listTags(element, tagsRule);
    _log.fine("tagsList=${tagsList.length}");
    CommonInfo commonInfo = CommonInfo(id, author, characters, fileSize,
        dimensions, source, bigUrl, rawUrl, tagsList);
    return commonInfo;
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

  List<YamlTag> _listTags(Element? element, YamlMap? tagsRule) {
    List<YamlTag> tagsList = [];
    if (tagsRule != null) {
      YamlMap listRule = tagsRule["list"];
      YamlMap? foreach = listRule["foreach"];
      _log.fine("foreach=$foreach");
      //字符传转数组
      if (foreach == null) {
        YamlMap? toListRule = listRule["toList"];
        YamlMap? easyGet = listRule["get"];
        if (easyGet != null) {
          String tags = _getOne(element, listRule);
          String separator = toListRule?["separator"] ?? defaultSeparator;
          _log.fine("tags=$tags");
          if (tags.isNotEmpty) {
            tags.split(separator).forEach((element) {
              tagsList.add(YamlTag(element, element));
            });
          }
          return tagsList;
        }
      } else {
        List<Element>? listList = _queryN(element, listRule);
        YamlMap descRule = foreach["desc"];
        YamlMap tagRule = foreach["tag"];
        for (Element element in listList) {
          String desc = _getOne(element, descRule);
          _log.fine("desc=$desc");
          String tag = _getOne(element, tagRule);
          _log.fine("tags=$desc");
          tagsList.add(YamlTag(desc, tag));
        }
      }
    }
    return tagsList;
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
    var filterRule = yamlMap["filter"];
    if (filterRule != null) {
      result = _find(result, filterRule);
      _log.fine("filter=$result");
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
    if (css == null) throw "first rule must be cssSelector！";
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

  String _find(String value, YamlMap yamlMap) {
    String result = value;
    yamlMap.forEach((key, value) {
      RegExp? linkRegExp;
      String? findRule = yamlMap["find"];
      if (findRule == null) throw "first rule must be regex！";
      linkRegExp = RegExp(findRule);
      int? indexRule = yamlMap["index"];
      if (indexRule != null) {
        result = linkRegExp.firstMatch(value)?.group(indexRule) ?? "";
      }
      result = _regularString(result);
    });
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
