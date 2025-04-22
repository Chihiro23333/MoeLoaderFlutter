import 'dart:convert';
import 'package:logging/logging.dart';
import 'package:yaml/yaml.dart';

class GlobalParser {
  final _log = Logger('GlobalParser');

  late YamlMap _doc;

  updateDoc(YamlMap doc) {
    _doc = doc;
  }

  Map<String, String> headers() {
    YamlMap? headersRule = _doc['config']?['headers'];
    _log.fine("getHeaders:result=$headersRule");
    return Map.castFrom(headersRule?.value ?? {});
  }

  String webPageName() {
    return _doc['config']?["meta"]?["name"] ?? "";
  }

  String pageType() {
    return _doc['config']?["meta"]?["pageType"] ?? "";
  }

  String validateUrl() {
    String validateUrl = _doc['config']?['validateUrl'] ?? "";
    _log.fine("validateUrl=$validateUrl");
    return validateUrl;
  }

  String options(String pageName) {
    var optionsRule = _doc[pageName]?['config']?["options"];
    _log.fine("optionsRule=$optionsRule");
    return jsonEncode(optionsRule ?? []);
  }

  Map<String, String>? fillInDefaultOptionValue(
      String pageName, Map<String, String>? inOptions) {
    YamlList? optionsRule = _doc[pageName]?['config']?["options"];
    if (optionsRule == null) return null;
    optionsRule.forEach((element) {
      if (inOptions?[element['id']] == null) {
        inOptions?[element['id']] = element['items'][0]['param'];
      }
    });
    return inOptions;
  }

  String displayInfo(String pageName) {
    return jsonEncode(_doc[pageName]?['config']?["display"] ?? {});
  }

  int columnCount(String pageName) {
    return (_doc[pageName]?['config']?["display"]?["columnCount"] ?? 6).toInt();
  }

  double aspectRatio(String pageName) {
    return (_doc[pageName]?['config']?["display"]?["aspectRatio"] ?? 0.65)
        .toDouble();
  }

  bool imageLoadWithHost() {
    return _doc['config']?["imageLoadConfig"]?["withHost"] ?? false;
  }
}
