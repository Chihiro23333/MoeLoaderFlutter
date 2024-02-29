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
