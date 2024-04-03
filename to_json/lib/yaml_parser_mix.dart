import 'dart:convert';
import 'package:to_json/utils.dart';
import 'package:to_json/yaml_parser_base.dart';
import 'package:to_json/yaml_parser_html.dart';
import 'package:to_json/yaml_parser_json.dart';
import 'package:yaml/yaml.dart';

class MixParser extends Parser {
  final Parser _yamlHtmlParser = YamlHtmlParser();
  final Parser _yamlJsonParser = YamlJsonParser();

  @override
  Future<String> parseUseYaml(
      String content, YamlMap doc, String pageName) async {
    YamlMap? page = doc[pageName];
    if (page == null) {
      throw "pageName不存在";
    }

    //预处理文本，拿到需要解析的信息
    YamlMap? preprocessNode = page["onPreprocessResult"];
    if (preprocessNode != null) {
      content = await preprocess(content, preprocessNode);
    }

    //解析文本，拿到json结果
    YamlMap onParseResult = page["onParseResult"];
    String contentType = onParseResult["contentType"] ?? "html";
    String data = "";
    if (contentType == "json") {
      data = await _yamlJsonParser.parseUseYaml(content, doc, pageName);
    } else {
      data = await _yamlHtmlParser.parseUseYaml(content, doc, pageName);
    }
    return toResult(Parser.success, "解析成功", jsonDecode(data));
  }

  @override
  Future<String> preprocess(String content, YamlMap preprocessNode) async {
    String? preprocessContentType = preprocessNode["contentType"] ?? "html";
    if (preprocessContentType == "html") {
      content = await _yamlHtmlParser.preprocess(content, preprocessNode);
    } else if (preprocessContentType == "json") {
      content = await _yamlJsonParser.preprocess(content, preprocessNode);
    }
    return content;
  }
}
