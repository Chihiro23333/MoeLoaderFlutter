import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:gal/gal.dart';
import 'package:moeloaderflutter/init.dart';
import 'package:moeloaderflutter/ui/page/webview2_page.dart';
import 'package:moeloaderflutter/ui/page/webview_inappwebview_page.dart';
import 'package:moeloaderflutter/util/const.dart';
import 'package:path_provider/path_provider.dart';
import 'package:to_json/models.dart';
import 'package:path/path.dart' as path;
import 'package:moeloaderflutter/multiplatform/bean.dart';
import 'package:webview_windows/webview_windows.dart';
import 'package:window_manager/window_manager.dart';

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

  Grid homeGrid(String pageName) {
    return Grid(2, 1.65);
  }

  Size designSize() {
    return const Size(1266, 683);
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

  String encodeFileName(String input) {
    return input;
  }

  String decodeFileName(String encoded) {
    return encoded;
  }

  double downloadOverlayTopOffset() {
    return 0;
  }
}

class PlatformWindows implements MultiPlatform {
  @override
  Future<void> webViewInit(String cachePath) async {
    WidgetsFlutterBinding.ensureInitialized();
    // String? webViewVersion = await WebviewController.getWebViewVersion();
    // bool supportWebView2 = webViewVersion != null;
    // if (supportWebView2) {
    //   try {
    //     await WebviewController.initializeEnvironment(userDataPath: cachePath);
    //   } catch (e) {}
    // }
    // await windowManager.ensureInitialized();
    final availableVersion = await WebViewEnvironment.getAvailableVersion();
    assert(availableVersion != null,
        'Failed to find an installed WebView2 runtime or non-stable Microsoft Edge installation.');
    await WebViewEnvironment.create(
        settings: WebViewEnvironmentSettings(userDataFolder: 'custom_path'));
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
  Grid homeGrid(String pageName) {
    int columnCount = Global.globalParser.columnCount(pageName);
    double aspectRatio = Global.globalParser.aspectRatio(pageName);
    return Grid(columnCount, aspectRatio);
  }

  @override
  Size designSize() {
    return const Size(1266, 683);
  }

  @override
  Widget favicon(Rule rule) {
    if (rule.type == Const.typeDefault) {
      return Image.asset(
        "${rule.faviconPath}",
        fit: BoxFit.cover,
      );
    } else {
      return Image.file(
        File("${rule.faviconPath}"),
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
    return InAppWebViewPage(
      url: url,
      code: code,
    );
  }

  @override
  List<String> cookieSeparator(String cookie) {
    // List<String> list = [];
    // List<String> keyValue = cookie.split(":");
    // if (keyValue.length == 3) {
    //   String key = keyValue[1];
    //   String value = keyValue[2];
    //   list.add(key);
    //   list.add(value);
    // }
    // return list;
    List<String> keyValue = cookie.split("=");
    return keyValue;
  }

  @override
  String decodeFileName(String encoded) {
    // 解码百分号编码的字符
    return encoded.replaceAllMapped(RegExp(r'%([0-9A-F]{2})'), (match) {
      final hex = match.group(1)!;
      return String.fromCharCode(int.parse(hex, radix: 16));
    });
  }

  @override
  String encodeFileName(String input) {
    // Windows不允许的字符（<>:"/\|?*和控制字符0x00-0x1F）
    const invalidChars = r'[<>:"/\\|?*\x00-\x1F]';
    // 将非法字符进行URL编码
    var result = input.replaceAllMapped(RegExp(invalidChars), (match) {
      final char = match.group(0)!;
      return '%${char.codeUnitAt(0).toRadixString(16).padLeft(2, '0').toUpperCase()}';
    });
    // 移除开头和结尾的空格和点
    result = result.trim();
    result = result.replaceAll(RegExp(r'^\.+|\.+$'), '');
    // 处理保留文件名
    const reservedNames = [
      'CON',
      'PRN',
      'AUX',
      'NUL',
      'COM1',
      'COM2',
      'COM3',
      'COM4',
      'COM5',
      'COM6',
      'COM7',
      'COM8',
      'COM9',
      'LPT1',
      'LPT2',
      'LPT3',
      'LPT4',
      'LPT5',
      'LPT6',
      'LPT7',
      'LPT8',
      'LPT9'
    ];
    // 检查是否是保留文件名（不区分大小写）
    final upperResult = result.toUpperCase();
    if (reservedNames.any(
        (name) => upperResult == name || upperResult.startsWith('$name.'))) {
      result = '_$result';
    }
    // 确保长度不超过255个字符，还有后缀
    if (result.length > 240) {
      result = result.substring(0, 240);
    }
    // 如果处理后为空字符串，返回默认值
    if (result.isEmpty) {
      return 'unnamed';
    }
    return result;
  }

  @override
  double downloadOverlayTopOffset() {
    return 3;
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
      await cacheDirectory.create(recursive: true);
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
  Grid homeGrid(String pageName) {
    double aspectRatio = Global.globalParser.aspectRatio(pageName);
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
        "${rule.faviconPath}",
        fit: BoxFit.cover,
      );
    } else {
      return Image.file(
        File("${rule.faviconPath}"),
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
    return InAppWebViewPage(
      url: url,
      code: code,
    );
  }

  @override
  List<String> cookieSeparator(String cookie) {
    List<String> keyValue = cookie.split("=");
    return keyValue;
  }

  @override
  String decodeFileName(String encoded) {
    // 解码百分号编码的字符
    return encoded.replaceAllMapped(RegExp(r'%([0-9A-F]{2})'), (match) {
      final hex = match.group(1)!;
      return String.fromCharCode(int.parse(hex, radix: 16));
    });
  }

  @override
  String encodeFileName(String input) {
    // Android/Linux 不允许的字符：/ 和 null 字符
    const invalidChars = r'[/\x00]';
    // 处理方式：编码或替换
    var result = input.replaceAllMapped(RegExp(invalidChars), (match) {
      final char = match.group(0)!;
      return '%${char.codeUnitAt(0).toRadixString(16).padLeft(2, '0').toUpperCase()}';
    });
    // 移除开头和结尾的点（Android 允许隐藏文件，但开头多个点可能有问题）
    result = result.replaceAll(RegExp(r'^\.+|\.+$'), '');
    // 确保长度不超过255字节（UTF-8编码后），还有后缀
    result = _truncateToMaxLength(result, 240);
    // 如果处理后为空字符串，返回默认值
    if (result.isEmpty) {
      return 'unnamed';
    }
    return result;
  }

  String _truncateToMaxLength(String input, int maxBytes) {
    if (input.isEmpty) return input;

    final utf8 = input.runes.map((rune) {
      if (rune <= 0x7F) return 1;
      if (rune <= 0x7FF) return 2;
      if (rune <= 0xFFFF) return 3;
      return 4;
    }).toList();

    int totalBytes = 0;
    int index = 0;

    for (; index < utf8.length; index++) {
      totalBytes += utf8[index];
      if (totalBytes > maxBytes) break;
    }

    return input.substring(0, index);
  }

  @override
  double downloadOverlayTopOffset() {
    return 0;
  }
}
