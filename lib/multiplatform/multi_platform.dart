import 'dart:io';
import 'dart:ui';
import 'package:moeloaderflutter/init.dart';
import 'package:moeloaderflutter/util/const.dart';
import 'package:path_provider/path_provider.dart';
import 'package:webview_windows/webview_windows.dart';
import 'package:path/path.dart' as path;
import 'package:window_manager/window_manager.dart';
import 'package:moeloaderflutter/multiplatform/bean.dart';

class MultiPlatform {
  Future<void> webViewInit(String cachePath) async {}

  Future<Directory> hiveDirectory() async{return Future.value(Directory(""));}

  Future<Directory> rulesDirectory() async{return Future.value(Directory(""));}

  Future<Directory> imagesDirectory() async{return Future.value(Directory(""));}

  Grid mainGrid(){return Grid(1,5);}

  Grid homeGrid(){return Grid(2,1.65);}

  Size designSize(){return const Size(1280, 720);}
}

class PlatformWindows implements MultiPlatform{

  @override
  Future<void> webViewInit(String cachePath) async {
    String? webViewVersion = await WebviewController.getWebViewVersion();
    bool supportWebView2 = webViewVersion != null;
    if(supportWebView2){
      try{
        await WebviewController.initializeEnvironment(userDataPath: cachePath);
      }catch(e){}
    }
    await windowManager.ensureInitialized();
  }

  @override
  Future<Directory> hiveDirectory() async{
    return Future.value(Directory(path.join(path.current ,"hive")));
  }

  @override
  Future<Directory> imagesDirectory() {
    return Future.value(Directory(path.join(path.current ,"images")));
  }

  @override
  Future<Directory> rulesDirectory() {
    return Future.value(Directory(path.join(path.current ,"rules")));
  }

  @override
  Grid mainGrid() {
    return Grid(3,5);
  }

  @override
  Grid homeGrid() {
    int columnCount = Global.customRuleParser.columnCount(Const.homePage);
    double aspectRatio =
    Global.customRuleParser.aspectRatio(Const.homePage);
    return Grid(columnCount,aspectRatio);
  }

  @override
  Size designSize() {
    return const Size(1280, 720);
  }

}

class PlatformAndroid implements MultiPlatform{
  @override
  Future<void> webViewInit(String cachePath) {
    return Future.value();
  }

  @override
  Future<Directory> hiveDirectory() async{
    var directory = await getExternalStorageDirectory();
    return directory!;
  }

  @override
  Future<Directory> imagesDirectory() async{
    var directory = await getExternalStorageDirectory();
    return directory!;
  }

  @override
  Future<Directory> rulesDirectory() async{
    var directory = await getExternalStorageDirectory();
    return directory!;
  }

  @override
  Grid mainGrid() {
    return Grid(1,5);
  }

  @override
  Grid homeGrid() {
    double aspectRatio =
    Global.customRuleParser.aspectRatio(Const.homePage);
    return Grid(2,aspectRatio);
  }

  @override
  Size designSize() {
    return const Size(360, 690);
  }
}