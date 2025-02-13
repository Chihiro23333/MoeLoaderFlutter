import 'dart:io';
import 'dart:ui';
import 'package:moeloaderflutter/custom_rule/custom_rule_parser.dart';
import 'package:moeloaderflutter/multiplatform/multi_platform.dart';
import 'package:moeloaderflutter/util/const.dart';
import 'package:moeloaderflutter/util/sharedpreferences_utils.dart';
import 'package:moeloaderflutter/net/request_manager.dart';
import 'package:flutter_socks_proxy/socks_proxy.dart';
import 'package:hive/hive.dart';
import 'package:logging/logging.dart';
import 'package:to_json/models.dart';
import 'package:to_json/parser_factory.dart';
import 'package:to_json/yaml_parser_base.dart';
import 'package:yaml/yaml.dart';
import 'package:to_json/yaml_rule_factory.dart';
import 'package:moeloaderflutter/multiplatform/multi_platform_factory.dart';

class Global{
  static Global? _cache;
  Global._create();
  factory Global(){
    return _cache ?? (_cache = Global._create());
  }

  static late WebPage _curWebPage;
  bool _proxyInited = false;
  static late CustomRuleParser _customRuleParser;
  static late MultiPlatform _multiPlatform;

  static late Directory _hiveDirectory;
  static late Directory _rulesDirectory;
  static late Directory _imagesDirectory;
  static late Directory _downloadsDirectory;
  static late Directory _browserCacheDirectory;

  Future<void> init() async{
    initPlatform();
    await initPath();
    _multiPlatform.webViewInit(browserCacheDirectory.path);
    Logger.root.level = Level.OFF; // defaults to Level.INFO
    Logger.root.onRecord.listen((record) {
      print('${record.loggerName}:${record.level.name}: ${record.time}: ${record.message}');
    });
    _initHive();
    await RequestManager().init();
    await updateProxy();
    await YamlRuleFactory().init();
    await updateCurWebPage(YamlRuleFactory().webPageList()[0]);
  }

  void initPlatform() {
    _multiPlatform = MultiPlatformFactory().create();
  }

  Future<void> initPath() async{
    _hiveDirectory = await _multiPlatform.hiveDirectory();
    _rulesDirectory = await _multiPlatform.rulesDirectory();
    _imagesDirectory = await _multiPlatform.imagesDirectory();
    _downloadsDirectory = await _multiPlatform.downloadsDirectory();
    _browserCacheDirectory = await _multiPlatform.browserCacheDirectory();
  }

  Future<void> updateCurWebPage(Rule rule) async{
    YamlMap webPage = await YamlRuleFactory().create(rule.fileName);
    _curWebPage = WebPage(webPage, rule);

    Parser parser = ParserFactory().createParser();
    var customRuleDoc = parser.customRule(webPage);
    _customRuleParser = CustomRuleParser(customRuleDoc);
  }

  Future<void> updateProxy() async{
    String? proxy = await getProxy();
    if(proxy == null || proxy.isEmpty){
      proxy = "DIRECT";
    }else{
      String? proxyType = await getProxyType();
      proxyType = proxyType ?? Const.proxyHttp;
      proxy = "$proxyType $proxy";
    }
    print("proxy=$proxy");
    if(!_proxyInited){
      SocksProxy.initProxy(proxy: proxy, onCreate: (client){
        client.userAgent = null;
      });
      _proxyInited = true;
    }else{
      SocksProxy.setProxy(proxy);
    }
  }

  void _initHive() async {
    Hive.init(hiveDirectory.path);
  }

  static CustomRuleParser get customRuleParser => _customRuleParser;
  static get curWebPage => _curWebPage;
  static get curWebPageName => _curWebPage.rule.fileName;
  static get rulesDirectory => _rulesDirectory;
  // static get rulesDirectory => Directory(path.join(path.current ,"testRules"));
  static get imagesDirectory => _imagesDirectory;
  static get browserCacheDirectory => _browserCacheDirectory;
  static get downloadsDirectory => _downloadsDirectory;
  static get hiveDirectory => _hiveDirectory;
  static get defaultColor => const Color.fromARGB(255, 46, 176, 242);
  static get defaultColor30 => const Color.fromARGB(30, 46, 176, 242);
  static MultiPlatform get multiPlatform => _multiPlatform;

}

class WebPage{
  YamlMap webPage;
  Rule rule;


  WebPage(this.webPage, this.rule);
}
