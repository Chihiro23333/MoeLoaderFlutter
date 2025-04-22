import 'package:intl/intl.dart';
import 'package:moeloaderflutter/init.dart';
import 'package:moeloaderflutter/model/tag_entity.dart';
import 'package:moeloaderflutter/util/sharedpreferences_utils.dart';
import 'package:to_json/validator.dart';

String unicodeToUTF16(String str) {
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

bool isImageUrl(String url) {
  return url.toLowerCase().contains(".jpg") ||
      url.toLowerCase().contains(".jpeg") ||
      url.toLowerCase().contains(".png") ||
      url.toLowerCase().contains(".gif") ||
      url.toLowerCase().contains(".webp");
}

String tipsByCode(int code) {
  if (code == ValidateResult.needChallenge) {
    return "需要进行安全挑战";
  }
  if (code == ValidateResult.needLogin) {
    return "需要登录";
  }
  return "";
}

String validateCompleteTipsByCode(int code) {
  if (code == ValidateResult.needChallenge) {
    return "已完成安全挑战";
  }
  if (code == ValidateResult.needLogin) {
    return "已完成登录";
  }
  return "";
}

Future<String> getDownloadName(
    String url, String id, String author, List<TagEntity> tags) async {
  Map<String, String> infoMap = {};
  infoMap["site"] = Global.globalParser.webPageName();
  infoMap["id"] = id;
  infoMap["author"] = author;
  DateTime now = DateTime.now();
  String formattedTime = DateFormat('yyyy_MM_dd_HH_mm_ss').format(now);
  infoMap["date"] = formattedTime;
  String tagStr = "";
  tags.asMap().forEach((index, value) {
    if (index == 0) {
      tagStr = value.desc;
    } else {
      tagStr = "${tagStr}_${value.desc}";
    }
  });
  if (tagStr.isNotEmpty) {
    infoMap["tag"] = tagStr;
  }
  String rule = await getDownloadFileNameRule();
  String name = "";
  if (rule.isEmpty) {
    name = "${Global.globalParser.webPageName()}_${author}_${url}_$formattedTime";
  } else {
    List<String> ruleList = rule.split("_");
    ruleList.asMap().forEach((index, value) {
      String info = infoMap[value] ?? "null";
      if (index == 0) {
        name = info;
      } else {
        name = "${name}_$info";
      }
    });
  }
  return Global.multiPlatform.encodeFileName(name);
}
