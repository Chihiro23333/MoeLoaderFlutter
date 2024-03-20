import 'dart:io';
import 'package:flutter/services.dart';
import 'package:MoeLoaderFlutter/init.dart';
import 'package:MoeLoaderFlutter/yamlhtmlparser/parser_factory.dart';
import 'package:logging/logging.dart';
import 'package:yaml/yaml.dart';
import 'package:path/path.dart' as path;
import 'models.dart';

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

  Future<void> init() async {
    if (!_init) {
      await _addAssets("pixiv_common");
      await _addAssets("yande_common");
      await _addAssets("anim_pictures_common");
      await _addAssets("anim_pictures");
      await _addAssets("danbooru");
      await _addAssets("behoimi");
      await _addAssets("konchan");
      await _addAssets("gelbooru");
      await _addAssets("safebooru");
      await _addAssets("lolibooru");
      await _addAssets("zerochan");
      await _addAssets("shuushuu");
      await _addAssets("yande");
      await _addAssets("pixiv");
      await addCustomRules();
      _init = true;
    }
  }

  Future<YamlMap> create(String fileName) async {
    Rule? targetRule;
    for (var element in _ruleList) {
      if(element.name == fileName){
        targetRule = element;
      }
    }
    if(targetRule == null)throw "yaml source not found!";
    YamlMap? targetWebPage;
    _ruleMap.forEach((key, value) {
      if(key.name == fileName){
        targetWebPage = value;
      }
    });
    if(targetWebPage == null){
     await _loadRule(targetRule);
    }
    targetWebPage = _ruleMap[targetRule];
    if(targetWebPage == null)throw "yaml source not found!";

    return targetWebPage!;
  }

  Future<void> _addAssets(String fileName) async {
    Rule rule = Rule("assets", "sources/$fileName.yaml", fileName);
    await _loadRule(rule);
    YamlMap? doc = _ruleMap[rule];
    if(doc != null){
      rule.name = await ParserFactory().createParser().getName(doc);
    }
    _ruleList.add(rule);
  }

  Future<void> addCustomRules() async {
    var rulesDirectory = Global.rulesDirectory;
    var exist = await rulesDirectory.exists();
    if(exist){
      rulesDirectory.listSync().forEach((element) {
        var basenameWithoutExtension = path.basenameWithoutExtension(element.path);
        // print("basenameWithoutExtension=$basenameWithoutExtension");
        _ruleList.add(Rule("custom", element.path , basenameWithoutExtension));
      });
    }
  }

  Future<void> _loadRule(Rule rule) async {
    if(rule.type == "assets"){
      String ruleStr = await rootBundle.loadString("sources/${rule.name}.yaml");
      var doc = loadYaml(ruleStr);
      _ruleMap[rule] = doc;
    }
    if(rule.type == "custom"){
      String ruleStr = await File(rule.path).readAsString();
      var doc = loadYaml(ruleStr);
      _ruleMap[rule] = doc;
    }
  }

  List<Rule> webPageList() {
    return _ruleList;
  }
}

