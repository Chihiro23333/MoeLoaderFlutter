import 'package:MoeLoaderFlutter/yamlhtmlparser/parser_factory.dart';
import 'package:MoeLoaderFlutter/yamlhtmlparser/yaml_parse_html.dart';
import 'package:MoeLoaderFlutter/yamlhtmlparser/yaml_parse_json.dart';
import 'package:yaml/yaml.dart';
import 'models.dart';

class MixParser extends Parser{

  final YamlHtmlParser _yamlHtmlParser = YamlHtmlParser();
  final YamlJsonParser _yamlJsonParser = YamlJsonParser();

  @override
  Future<List<YamlHomePageItem>> parseHome(String content, YamlMap webPage) async {
    YamlMap homePage = webPage["homePage"];
    YamlMap onParseResult = homePage["onParseResult"];
    String contentType = onParseResult["contentType"] ?? "html";
    YamlMap? preprocessNode = homePage["onPreprocessResult"];
    content =  await _preprocess(content, preprocessNode);
    if(contentType == "json"){
      return await _yamlJsonParser.parseHome(content, homePage);
    }else {
      return await _yamlHtmlParser.parseHome(content, homePage);
    }
  }

  @override
  Future<List<YamlHomePageItem>> parseSearch(String content, YamlMap webPage) async{
    YamlMap searchPage = webPage["searchPage"];
    YamlMap onParseResult = searchPage["onParseResult"];
    String contentType = onParseResult["contentType"] ?? "html";
    YamlMap? preprocessNode = searchPage["onPreprocessResult"];
    content =  await _preprocess(content, preprocessNode);
    if(contentType == "json"){
      return await _yamlJsonParser.parseSearch(content, searchPage);
    }else {
      return await _yamlHtmlParser.parseSearch(content, searchPage);
    }
  }

  @override
  Future<YamlDetailPage> parseDetail(String content, YamlMap webPage) async {
    YamlMap detailPage = webPage["detailPage"];
    YamlMap onParseResult = detailPage["onParseResult"];
    String contentType = onParseResult["contentType"] ?? "html";
    YamlMap? preprocessNode = detailPage["onPreprocessResult"];
    content =  await _preprocess(content, preprocessNode);
    if(contentType == "json"){
      return await _yamlJsonParser.parseDetail(content, onParseResult);
    }else {
      return await _yamlHtmlParser.parseDetail(content, onParseResult);
    }
  }

  Future<String> _preprocess(String content, YamlMap? preprocessNode) async {
    if(preprocessNode != null){
      String? preprocessContentType = preprocessNode["contentType"] ?? "html";
      if(preprocessContentType == "html"){
        content = await _yamlHtmlParser.preprocess(content, preprocessNode);
      }else if(preprocessContentType == "json"){
        content = await _yamlJsonParser.preprocess(content, preprocessNode);
      }
    }
    return content;
  }

}
