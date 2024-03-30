import 'dart:convert';

String toResult(int code, String message, dynamic data) {
  var object = {};
  object["code"] = code;
  object["message"] = message;
  object["data"] = data;
  return jsonEncode(object);
}