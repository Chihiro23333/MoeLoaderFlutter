import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:webview_windows/webview_windows.dart';
import 'package:path/path.dart' as path;
import 'package:window_manager/window_manager.dart';

class MultiPlatform {
  Future<void> webViewInit(String cachePath) async {}

  Future<Directory> hiveDirectory() async{return Future.value(Directory(""));}

  Future<Directory> rulesDirectory() async{return Future.value(Directory(""));}

  Future<Directory> imagesDirectory() async{return Future.value(Directory(""));}

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

}

class PlatformNothing implements MultiPlatform{

  @override
  Future<void> webViewInit(String cachePath) {
    return Future.value();
  }

  @override
  Future<Directory> hiveDirectory() async{return Future.value(Directory(""));}

  @override
  Future<Directory> rulesDirectory() async{return Future.value(Directory(""));}

  @override
  Future<Directory> imagesDirectory() async{return Future.value(Directory(""));}

}