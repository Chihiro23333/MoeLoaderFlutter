import 'dart:io';
import 'dart:ui';
import 'package:MoeLoaderFlutter/custom_rule/custom_rule_parser.dart';
import 'package:MoeLoaderFlutter/util/const.dart';
import 'package:MoeLoaderFlutter/util/sharedpreferences_utils.dart';
import 'package:MoeLoaderFlutter/net/request_manager.dart';
import 'package:flutter_socks_proxy/socks_proxy.dart';
import 'package:hive/hive.dart';
import 'package:logging/logging.dart';
import 'package:to_json/models.dart';
import 'package:to_json/parser_factory.dart';
import 'package:to_json/yaml_parser_base.dart';
import 'package:webview_windows/webview_windows.dart';
import 'package:window_manager/window_manager.dart';
import 'package:yaml/yaml.dart';
import 'package:path/path.dart' as path;
import 'package:to_json/yaml_rule_factory.dart';

class Global{
  static Global? _cache;
  Global._create();
  factory Global(){
    return _cache ?? (_cache = Global._create());
  }

  static late WebPage _curWebPage;
  static late bool _supportWebView2 = false;
  bool _proxyInited = false;
  static late CustomRuleParser _customRuleParser;

  Future<void> init() async{
    String? webViewVersion = await WebviewController.getWebViewVersion();
    _supportWebView2 = webViewVersion != null;
    if(_supportWebView2){
      try{
        await WebviewController.initializeEnvironment(userDataPath: browserCacheDirectory.path);
      }catch(e){}
    }
    Logger.root.level = Level.INFO; // defaults to Level.INFO
    Logger.root.onRecord.listen((record) {
      print('${record.loggerName}:${record.level.name}: ${record.time}: ${record.message}');
    });
    _initHive();
    await RequestManager().init();
    await updateProxy();
    await YamlRuleFactory().init(rulesDirectory, imagesDirectory);
    await updateCurWebPage(YamlRuleFactory().webPageList()[0]);
    await windowManager.ensureInitialized();
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

  void _initHive() {
    Hive.init(Global.hiveDirectory.path);
  }

  static CustomRuleParser get customRuleParser => _customRuleParser;
  static get curWebPage => _curWebPage;
  static get curWebPageName => _curWebPage.rule.fileName;
  static get rulesDirectory => Directory(path.join(path.current ,"rules"));
  static get imagesDirectory => Directory(path.join(path.current ,"images"));
  static get browserCacheDirectory => Directory(path.join(path.current ,"browserCache"));
  static get downloadsDirectory => Directory(path.join(path.current ,"downloads"));
  static get hiveDirectory => Directory(path.join(path.current ,"hive"));
  static get supportWebView2 => _supportWebView2;
  static get defaultColor => const Color.fromARGB(255, 46, 176, 242);
  static get defaultColor30 => const Color.fromARGB(30, 46, 176, 242);

}

class WebPage{
  YamlMap webPage;
  Rule rule;


  WebPage(this.webPage, this.rule);
}
