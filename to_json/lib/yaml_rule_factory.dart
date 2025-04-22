import 'dart:io';
import 'package:flutter/services.dart';
import 'package:logging/logging.dart';
import 'package:to_json/models.dart';
import 'package:yaml/yaml.dart';
import 'package:moeloaderflutter/init.dart';
import 'package:moeloaderflutter/util/const.dart';

class YamlRuleFactory {
  final _log = Logger("YamlRuleFactory");

  static YamlRuleFactory? _cache;

  YamlRuleFactory._create();

  factory YamlRuleFactory() {
    return _cache ?? (_cache = YamlRuleFactory._create());
  }

  static final List<Rule> _ruleList = [];
  static final Map<Rule, YamlMap> _ruleMap = {};
  static bool _init = false;
  static late YamlMap _configYamlDoc;

  Future<void> init() async {
    if (!_init) {
      String configStr =
          await rootBundle.loadString("assets/${Const.dirRules}/_config.yaml");
      _configYamlDoc = loadYaml(configStr);
      await _updateDefaultRules();
      _init = true;
    }
  }

  Future<YamlMap> create(String fileName) async {
    _log.fine("fileName=$fileName");
    Rule? targetRule;
    for (var element in _ruleList) {
      _log.fine("element=${element.fileName}");
      if (element.fileName == fileName) {
        targetRule = element;
      }
    }
    _log.fine("targetRule=$targetRule");
    if (targetRule == null) throw "yaml source not found!";
    YamlMap? targetWebPage;
    _ruleMap.forEach((key, value) {
      if (key.fileName == fileName) {
        targetWebPage = value;
      }
    });
    if (targetWebPage == null) {
      await _loadRule(targetRule);
    }
    targetWebPage = _ruleMap[targetRule];
    if (targetWebPage == null) throw "yaml source not found!";

    return targetWebPage!;
  }

  addCustomRule(Rule rule) {
    _ruleList.add(rule);
  }

  Future<void> _updateDefaultRules() async {
    _configYamlDoc["rules"].forEach((element) {
      String name = element["name"];
      String path = "assets/${Const.dirRules}/${element["fileName"]}";
      String faviconPath = "assets/${Const.dirIcons}/${element["favicon"]}";
      bool canSearch = element["canSearch"];
      _log.fine(
          "addCustomRules:name=$name;faviconPath=$faviconPath;canSearch=$canSearch");
      _ruleList
          .add(Rule(Const.typeDefault, path, name, faviconPath, canSearch));
    });
  }

  Future<void> _loadRule(Rule rule) async {
    String ruleStr;
    if (rule.type == Const.typeDefault) {
      ruleStr = await rootBundle.loadString("${rule.path}");
    } else {
      ruleStr = await File("${rule.path}").readAsString();
    }
    var doc = loadYaml(ruleStr);
    _ruleMap[rule] = doc;
  }

  List<Rule> webPageList() {
    return _ruleList;
  }
}
