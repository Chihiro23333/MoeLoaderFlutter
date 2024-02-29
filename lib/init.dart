import 'dart:io';
import 'package:FlutterMoeLoaderDesktop/utils/sharedpreferences_utils.dart';
import 'package:FlutterMoeLoaderDesktop/yamlhtmlparser/yaml_rule_factory.dart';
import 'package:FlutterMoeLoaderDesktop/net/request_manager.dart';
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
  ProxyHttpOverrides? _proxyHttpOverrides;

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
    if(_proxyHttpOverrides == null){
      _proxyHttpOverrides = ProxyHttpOverrides(proxy);
      HttpOverrides.global = _proxyHttpOverrides;
    }else{
      _proxyHttpOverrides?.setProxy = proxy;
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

}


class WebPage{
  YamlMap webPage;
  Rule rule;

  WebPage(this.webPage, this.rule);
}

class ProxyHttpOverrides extends HttpOverrides {

  String? _proxy;

  ProxyHttpOverrides(this._proxy);

  String? get proxyStr => _proxy;

  set setProxy(String? proxy){
    _proxy = proxy;
  }

  @override
  HttpClient createHttpClient(SecurityContext? context) {
    print("createHttpClient:proxy=$_proxy");
    final client = super.createHttpClient(context);
    client.connectionTimeout = const Duration(seconds: 10);
    client.findProxy = (uri) => (_proxy == null || _proxy!.isEmpty) ? "DIRECT" : "PROXY $_proxy";
    client.badCertificateCallback = (X509Certificate cert, String host, int port){
      final ipv4RegExp = RegExp(
          r'^((25[0-5]|2[0-4]\d|[0-1]?\d?\d)(\.(25[0-5]|2[0-4]\d|[0-1]?\d?\d)){3})$');
      if(ipv4RegExp.hasMatch(host)){
        // 允许ip访问
        return true;
      }
      return false;
    };
    return client;
  }
}