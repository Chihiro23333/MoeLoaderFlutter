
import 'package:hive/hive.dart';

const _cookiesDb = "cookies";

Future<bool> saveCookieString(String domain, String cookiesString) async{
  var box = await Hive.openBox(_cookiesDb);
  box.put(domain, cookiesString);
  box.close();
  return true;
}

Future<Map<String, String>> getAllCookieString() async{
  var box = await Hive.openBox(_cookiesDb);
  var result = <String, String>{};
  box.toMap().forEach((key, value) {
    result[key.toString()] = value.toString();
  });
  box.close();
  return result;
}