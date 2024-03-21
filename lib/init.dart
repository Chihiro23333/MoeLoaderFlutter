import 'dart:io';
import 'dart:ui';
import 'package:MoeLoaderFlutter/utils/const.dart';
import 'package:MoeLoaderFlutter/utils/sharedpreferences_utils.dart';
import 'package:MoeLoaderFlutter/yamlhtmlparser/yaml_rule_factory.dart';
import 'package:MoeLoaderFlutter/net/request_manager.dart';
import 'package:flutter_socks_proxy/socks_proxy.dart';
import 'package:hive/hive.dart';
import 'package:logging/logging.dart';
import 'package:webview_windows/webview_windows.dart';
import 'package:window_manager/window_manager.dart';
import 'package:yaml/yaml.dart';
import 'package:path/path.dart' as path;

import '../yamlhtmlparser/models.dart';

class Global{
  static Global? _cache;
  Global._create();
  factory Global(){
    return _cache ?? (_cache = Global._create());
  }

  static late WebPage _curWebPage;
  static late bool _supportWebView2 = false;
  bool _proxyInited = false;

  Future<void> init() async{
    String? webViewVersion = await WebviewController.getWebViewVersion();
    _supportWebView2 = webViewVersion != null;
    if(_supportWebView2){
      try{
        await WebviewController.initializeEnvironment(userDataPath: browserCacheDirectory.path);
      }catch(e){}
    }
    _initHive();
    await updateProxy();
    await RequestManager().init();
    await YamlRuleFactory().init();
    await updateCurWebPage(YamlRuleFactory().webPageList()[0]);
    Logger.root.level = Level.INFO; // defaults to Level.INFO
    Logger.root.onRecord.listen((record) {
      print('${record.loggerName}:${record.level.name}: ${record.time}: ${record.message}');
    });
    await windowManager.ensureInitialized();
  }

  Future<void> updateCurWebPage(Rule rule) async{
    YamlMap webPage = await YamlRuleFactory().create(rule.name);
    _curWebPage = WebPage(webPage, rule);
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
        client.userAgent = "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/122.0.0.0 Safari/537.36";
      });
      _proxyInited = true;
    }else{
      SocksProxy.setProxy(proxy);
    }
  }

  void _initHive() {
    Hive.init(Global.hiveDirectory.path);
  }

  static get curWebPageName => _curWebPage.rule.name;
  static get columnCount => int.parse((_curWebPage.webPage['display']?['columnCount'] ?? 6).toString());
  static get aspectRatio => double.parse((_curWebPage.webPage['display']?['aspectRatio'] ?? 1.78).toString());
  static get rulesDirectory => Directory(path.join(path.current ,"rules"));
  static get browserCacheDirectory => Directory(path.join(path.current ,"browserCache"));
  static get downloadsDirectory => Directory(path.join(path.current ,"downloads"));
  static get hiveDirectory => Directory(path.join(path.current ,"hive"));
  static get supportWebView2 => _supportWebView2;
  static get defaultColor => const Color.fromARGB(255, 46, 176, 242);

}

class WebPage{
  YamlMap webPage;
  Rule rule;

  WebPage(this.webPage, this.rule);
}