
import 'package:MoeLoaderFlutter/yamlhtmlparser/models.dart';
import 'package:MoeLoaderFlutter/yamlhtmlparser/yaml_validator.dart';

String unicodeToUTF16(String str){
  final Pattern unicodePattern = RegExp(r'\\u([0-9A-Fa-f]{4})');
  String newStr = str.replaceAllMapped(unicodePattern, (Match unicodeMatch) {
    var group = unicodeMatch.group(1);
    final int hexCode = int.parse(group!, radix: 16);
    final unicode = String.fromCharCode(hexCode);
    return unicode;
  });
  return newStr;
}

bool requestByDio(String accessWay) {
  return accessWay == "dio";
}

bool requestByWebView(String accessWay) {
  return accessWay == "webView";
}

bool requestByWebViewWait(String accessWay) {
  return accessWay == "webViewWait";
}

bool isImageUrl(String url){
  return url.toLowerCase().contains(".jpg") || url.toLowerCase().contains(".jpeg") || url.toLowerCase().contains(".png");
}

String tipsByCode(int code){
  if(code == ValidateResult.needChallenge){
    return "需要进行安全挑战";
  }
  if(code == ValidateResult.needLogin){
    return "需要登录";
  }
  return "";
}

String validateCompleteTipsByCode(int code){
  if(code == ValidateResult.needChallenge){
    return "已完成安全挑战";
  }
  if(code == ValidateResult.needLogin){
    return "已完成登录";
  }
  return "";
}

String getDownloadName(String url, String id){
  Uri uri = Uri.parse(url);
  String host = uri.host;
  return "${host}_$id";
}
