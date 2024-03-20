import 'package:MoeLoaderFlutter/yamlhtmlparser/parser_factory.dart';
import 'package:MoeLoaderFlutter/yamlhtmlparser/yaml_parse_html.dart';
import 'package:MoeLoaderFlutter/yamlhtmlparser/yaml_parse_json.dart';
import 'package:MoeLoaderFlutter/yamlhtmlparser/yaml_rule_factory.dart';
import 'package:yaml/yaml.dart';
import 'models.dart';

class MixParser extends Parser {

  final YamlHtmlParser _yamlHtmlParser = YamlHtmlParser();
  final YamlJsonParser _yamlJsonParser = YamlJsonParser();

  Future<List<YamlHomePageItem>> parseHome(
      String content, YamlMap webPage) async {
    YamlMap homePage = webPage["homePage"];
    YamlMap onParseResult = homePage["onParseResult"];
    String contentType = onParseResult["contentType"] ?? "html";
    YamlMap? preprocessNode = homePage["onPreprocessResult"];
    content = await _preprocess(content, preprocessNode);
    if (contentType == "json") {
      return await _yamlJsonParser.parseHome(content, homePage);
    } else {
      return await _yamlHtmlParser.parseHome(content, homePage);
    }
  }

  Future<List<YamlHomePageItem>> parseSearch(
      String content, YamlMap webPage) async {
    YamlMap searchPage = webPage["searchPage"];
    YamlMap onParseResult = searchPage["onParseResult"];
    String contentType = onParseResult["contentType"] ?? "html";
    YamlMap? preprocessNode = searchPage["onPreprocessResult"];
    content = await _preprocess(content, preprocessNode);
    if (contentType == "json") {
      return await _yamlJsonParser.parseSearch(content, searchPage);
    } else {
      return await _yamlHtmlParser.parseSearch(content, searchPage);
    }
  }

  Future<YamlDetailPage> parseDetail(String content, YamlMap webPage) async {
    YamlMap detailPage = webPage["detailPage"];
    YamlMap onParseResult = detailPage["onParseResult"];
    String contentType = onParseResult["contentType"] ?? "html";
    YamlMap? preprocessNode = detailPage["onPreprocessResult"];
    content = await _preprocess(content, preprocessNode);
    if (contentType == "json") {
      return await _yamlJsonParser.parseDetail(content, onParseResult);
    } else {
      return await _yamlHtmlParser.parseDetail(content, onParseResult);
    }
  }

  Future<String> _preprocess(String content, YamlMap? preprocessNode) async {
    if (preprocessNode != null) {
      String? preprocessContentType = preprocessNode["contentType"] ?? "html";
      if (preprocessContentType == "html") {
        content =
            await _yamlHtmlParser.preprocess(content, preprocessNode);
      } else if (preprocessContentType == "json") {
        content =
            await _yamlJsonParser.preprocess(content, preprocessNode);
      }
    }
    return content;
  }

  @override
  Future<String> parseUseYaml(
      String content, String sourceName, String pageName) async {
    YamlMap doc = await YamlRuleFactory().create(sourceName);
    YamlMap? page = doc[pageName];
    if (page == null) {
      throw "pageName不存在";
    }

    //结果验证
    YamlList? resultRule = page["onValidateResult"]?["result"];
    if (resultRule != null) {
      Iterator iterator = resultRule.iterator;
      while (iterator.moveNext()) {
        YamlMap item = iterator.current;
        RegExp regExp = RegExp(item["regex"]);
        if (regExp.hasMatch(content)) {
          String action = item["action"];
          int code;
          String message = "";
          if (action == "login") {
            code = Parser.needLogin;
            message = "需要登录";
          } else {
            code = Parser.needChallenge;
            message = "需要安全挑战";
          }
          return _toResult(code, message, "");
        }
      }
      return _toResult(Parser.fail, "结果验证失败", "");
    }

    //预处理文本，拿到需要解析的信息
    YamlMap? preprocessNode = page["onPreprocessResult"];
    content = await _preprocess(content, preprocessNode);

    //解析文本，拿到json结果
    YamlMap onParseResult = page["onParseResult"];
    String contentType = onParseResult["contentType"] ?? "html";
    String data = "";
    if (contentType == "json") {
      data = await _yamlJsonParser.parseUseYaml(
          content, sourceName, pageName);
    } else {
      data = await _yamlHtmlParser.parseUseYaml(
          content, sourceName, pageName);
    }
    return _toResult(Parser.success, "解析成功", data);
  }

  String _toResult(int code, String message, String data) {
    var object = {};
    object["code"] = code;
    object["message"] = message;
    object["data"] = data;
    return object.toString();
  }

}
