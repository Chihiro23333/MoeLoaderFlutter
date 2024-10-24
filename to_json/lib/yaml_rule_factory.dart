import 'dart:io';
import 'package:logging/logging.dart';
import 'package:to_json/models.dart';
import 'package:yaml/yaml.dart';
import 'package:path/path.dart' as path;

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

  Future<void> init(Directory rulesDirectory, Directory imagesDirectory) async {
    if (!_init) {
      String configStr =
          await File("${rulesDirectory.path}/_config.yaml").readAsString();
      _configYamlDoc = loadYaml(configStr);
      await addCustomRules(rulesDirectory, imagesDirectory);
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

  Future<void> addCustomRules(
      Directory rulesDirectory, Directory imagesDirectory) async {
    var exist = await rulesDirectory.exists();
    if (exist) {
      _configYamlDoc["rules"].forEach((element) {
        String name = element["name"];
        String fileName = element["fileName"];
        String favicon = element["favicon"];
        bool canSearch = element["canSearch"];
        _log.fine("addCustomRules:name=$name;favicon=$favicon;canSearch=$canSearch");
        _ruleList.add(Rule("custom", "${rulesDirectory.path}/$fileName", name,
            "${imagesDirectory.path}/$favicon", canSearch));
      });
    }
  }

  Future<void> _loadRule(Rule rule) async {
    String ruleStr = await File(rule.path).readAsString();
    var doc = loadYaml(ruleStr);
    _ruleMap[rule] = doc;
  }

  List<Rule> webPageList() {
    return _ruleList;
  }
}
