// Obtain shared preferences.
import 'package:shared_preferences/shared_preferences.dart';

Future<bool> setProxy(String proxy) async{
  final SharedPreferences prefs = await SharedPreferences.getInstance();
  await prefs.setString("proxy", proxy);
  return true;
}

Future<String?> getProxy() async{
  final SharedPreferences prefs = await SharedPreferences.getInstance();
  String? proxy = prefs.getString("proxy");
  return proxy;
}

Future<bool> setProxyType(String proxyType) async{
  final SharedPreferences prefs = await SharedPreferences.getInstance();
  await prefs.setString("proxyType", proxyType);
  return true;
}

Future<String?> getProxyType() async{
  final SharedPreferences prefs = await SharedPreferences.getInstance();
  String? proxy = prefs.getString("proxyType");
  return proxy;
}

Future<bool> setDownloadFileSize(String fileSizeType) async{
  final SharedPreferences prefs = await SharedPreferences.getInstance();
  await prefs.setString("downloadFileSize", fileSizeType);
  return true;
}

Future<String?> getDownloadFileSize() async{
  final SharedPreferences prefs = await SharedPreferences.getInstance();
  String? proxy = prefs.getString("downloadFileSize");
  return proxy;
}

