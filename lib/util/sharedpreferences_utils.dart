// Obtain shared preferences.
import 'package:shared_preferences/shared_preferences.dart';

Future<bool> setProxy(String proxy) async {
  final SharedPreferences prefs = await SharedPreferences.getInstance();
  await prefs.setString("proxy", proxy);
  return true;
}

Future<String?> getProxy() async {
  final SharedPreferences prefs = await SharedPreferences.getInstance();
  String? proxy = prefs.getString("proxy");
  return proxy;
}

Future<bool> setProxyType(String proxyType) async {
  final SharedPreferences prefs = await SharedPreferences.getInstance();
  await prefs.setString("proxyType", proxyType);
  return true;
}

Future<String?> getProxyType() async {
  final SharedPreferences prefs = await SharedPreferences.getInstance();
  String? proxy = prefs.getString("proxyType");
  return proxy;
}

Future<bool> setDownloadFileSize(String fileSizeType) async {
  final SharedPreferences prefs = await SharedPreferences.getInstance();
  await prefs.setString("downloadFileSize", fileSizeType);
  return true;
}

Future<String?> getDownloadFileSize() async {
  final SharedPreferences prefs = await SharedPreferences.getInstance();
  String? proxy = prefs.getString("downloadFileSize");
  return proxy;
}

Future<bool> setDownloadFileNameRule(String rule) async {
  final SharedPreferences prefs = await SharedPreferences.getInstance();
  await prefs.setString("downloadFileNameRule", rule);
  return true;
}

Future<String> getDownloadFileNameRule() async {
  final SharedPreferences prefs = await SharedPreferences.getInstance();
  String? rule = prefs.getString("downloadFileNameRule");
  return rule ?? "";
}

// 浏览历史相关方法
Future<bool> addViewedImage(String url) async {
  final SharedPreferences prefs = await SharedPreferences.getInstance();
  List<String> viewedImages = await getViewedImages();
  if (!viewedImages.contains(url)) {
    viewedImages.add(url);
    await prefs.setStringList("viewedImages", viewedImages);
  }
  return true;
}

Future<List<String>> getViewedImages() async {
  final SharedPreferences prefs = await SharedPreferences.getInstance();
  List<String>? viewedImages = prefs.getStringList("viewedImages");
  return viewedImages ?? [];
}

Future<bool> isImageViewed(String url) async {
  List<String> viewedImages = await getViewedImages();
  return viewedImages.contains(url);
}
