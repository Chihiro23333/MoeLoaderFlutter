import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:gal/gal.dart';
import 'package:moeloaderflutter/init.dart';
import 'package:moeloaderflutter/ui/page/webview2_page.dart';
import 'package:moeloaderflutter/ui/page/webview_android_page.dart';
import 'package:moeloaderflutter/util/const.dart';
import 'package:path_provider/path_provider.dart';
import 'package:to_json/models.dart';
import 'package:webview_windows/webview_windows.dart';
import 'package:path/path.dart' as path;
import 'package:window_manager/window_manager.dart';
import 'package:moeloaderflutter/multiplatform/bean.dart';

class MultiPlatform {
  Future<void> webViewInit(String cachePath) async {}

  Future<Directory> hiveDirectory() async {
    return Future.value(Directory(""));
  }

  Future<Directory> rulesDirectory() async {
    return Future.value(Directory(""));
  }

  Future<Directory> imagesDirectory() async {
    return Future.value(Directory(""));
  }

  Future<Directory> downloadsDirectory() async {
    return Future.value(Directory(""));
  }

  Future<Directory> browserCacheDirectory() async {
    return Future.value(Directory(""));
  }

  Grid mainGrid() {
    return Grid(1, 5);
  }

  Grid homeGrid() {
    return Grid(2, 1.65);
  }

  Size designSize() {
    return const Size(1280, 720);
  }

  Widget favicon(Rule rule) {
    return const SizedBox();
  }

  Future<bool> requestAccess() async {
    return Future.value(false);
  }

  Future<bool> saveToGallery(String imagePath) async {
    return Future.value(false);
  }

  Widget navigateToWebView(BuildContext context, String url, int code,
      {String? userAgent}) {
    return const SizedBox();
  }

  List<String> cookieSeparator(String cookie) {
    return [];
  }
}

class PlatformWindows implements MultiPlatform {
  @override
  Future<void> webViewInit(String cachePath) async {
    String? webViewVersion = await WebviewController.getWebViewVersion();
    bool supportWebView2 = webViewVersion != null;
    if (supportWebView2) {
      try {
        await WebviewController.initializeEnvironment(userDataPath: cachePath);
      } catch (e) {}
    }
    await windowManager.ensureInitialized();
  }

  @override
  Future<Directory> hiveDirectory() async {
    return Future.value(Directory(path.join(path.current, Const.dirHive)));
  }

  @override
  Future<Directory> imagesDirectory() {
    return Future.value(Directory(path.join(path.current, Const.dirIcons)));
  }

  @override
  Future<Directory> rulesDirectory() {
    return Future.value(Directory(path.join(path.current, Const.dirRules)));
  }

  @override
  Future<Directory> downloadsDirectory() {
    return Future.value(Directory(path.join(path.current, Const.dirDownloads)));
  }

  @override
  Future<Directory> browserCacheDirectory() {
    return Future.value(
        Directory(path.join(path.current, Const.dirBrowserCache)));
  }

  @override
  Grid mainGrid() {
    return Grid(3, 5);
  }

  @override
  Grid homeGrid() {
    int columnCount = Global.customRuleParser.columnCount(Const.homePage);
    double aspectRatio = Global.customRuleParser.aspectRatio(Const.homePage);
    return Grid(columnCount, aspectRatio);
  }

  @override
  Size designSize() {
    return const Size(1280, 720);
  }

  @override
  Widget favicon(Rule rule) {
    if (rule.type == Const.typeDefault) {
      return Image.asset(
        "assets/${Const.dirIcons}/${rule.faviconPath}",
        fit: BoxFit.cover,
      );
    } else {
      Directory imagesDirectory = Global.imagesDirectory;
      return Image.file(
        File("${imagesDirectory.path}/${rule.faviconPath}"),
        fit: BoxFit.cover,
      );
    }
  }

  @override
  Future<bool> requestAccess() async {
    return Future.value(true);
  }

  @override
  Future<bool> saveToGallery(String imagePath) {
    return Future.value(true);
  }

  @override
  Widget navigateToWebView(BuildContext context, String url, int code,
      {String? userAgent}) {
    return WebView2Page(
      url: url,
      code: code,
    );
  }

  @override
  List<String> cookieSeparator(String cookie) {
    List<String> list = [];
    List<String> keyValue = cookie.split(":");
    if (keyValue.length == 3) {
      String key = keyValue[1];
      String value = keyValue[2];
      list.add(key);
      list.add(value);
    }
    return list;
  }
}

class PlatformAndroid implements MultiPlatform {
  @override
  Future<void> webViewInit(String cachePath) {
    return Future.value();
  }

  Future<Directory> _cachePath(String name) async {
    var directory = await getExternalStorageDirectory();
    String cacheDirPath = "${directory!.path}/$name";
    Directory cacheDirectory = Directory(cacheDirPath);
    if (!await cacheDirectory.exists()) {
      await cacheDirectory.create();
    }
    return cacheDirectory;
  }

  @override
  Future<Directory> hiveDirectory() async {
    return _cachePath(Const.dirHive);
  }

  @override
  Future<Directory> imagesDirectory() async {
    return _cachePath(Const.dirIcons);
  }

  @override
  Future<Directory> rulesDirectory() async {
    return _cachePath(Const.dirRules);
  }

  @override
  Future<Directory> downloadsDirectory() async {
    return _cachePath(Const.dirDownloads);
  }

  @override
  Future<Directory> browserCacheDirectory() async {
    return _cachePath(Const.dirBrowserCache);
  }

  @override
  Grid mainGrid() {
    return Grid(1, 5);
  }

  @override
  Grid homeGrid() {
    double aspectRatio = Global.customRuleParser.aspectRatio(Const.homePage);
    return Grid(2, aspectRatio);
  }

  @override
  Size designSize() {
    return const Size(360, 690);
  }

  @override
  Widget favicon(Rule rule) {
    if (rule.type == Const.typeDefault) {
      return Image.asset(
        "assets/${Const.dirIcons}/${rule.faviconPath}",
        fit: BoxFit.cover,
      );
    } else {
      Directory imagesDirectory = Global.imagesDirectory;
      return Image.file(
        File("${imagesDirectory.path}/${rule.faviconPath}"),
        fit: BoxFit.cover,
      );
    }
  }

  @override
  Future<bool> requestAccess() async {
    // ... for saving to album
    final hasAccess = await Gal.hasAccess(toAlbum: true);
    bool granted = false;
    if (!hasAccess) {
      granted = await Gal.requestAccess(toAlbum: true);
    }
    return Future.value(hasAccess || (!hasAccess && granted));
  }

  @override
  Future<bool> saveToGallery(String imagePath) async {
    await Gal.putImage(imagePath);
    File(imagePath).delete();
    return Future.value(true);
  }

  @override
  Widget navigateToWebView(BuildContext context, String url, int code,
      {String? userAgent}) {
    return WebViewAndroidPage(
      url: url,
      code: code,
    );
  }

  @override
  List<String> cookieSeparator(String cookie) {
    List<String> keyValue = cookie.split("=");
    return keyValue;
  }
}
