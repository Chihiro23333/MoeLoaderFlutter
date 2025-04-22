import 'dart:convert';
import 'package:to_json/yaml_parser_base.dart';
import 'package:yaml/yaml.dart';
import 'package:logging/logging.dart';

class JsonTransformParser extends Parser {
  final _log = Logger('YamlJsonParser');

  @override
  Future<String> parseUseYaml(String content, YamlMap doc, String pageName,
      {Map<String, String>? headers, Map<String, String>? params}) async {
    Map<String, dynamic> jsonContent = jsonDecode(content);
    YamlMap onParseResult = doc["onParseResult"];
    String? keyFlatten = onParseResult["keyFlatten"];
    if(keyFlatten != null){
      List<String> list = keyFlatten.split(".");
      Map<String, dynamic> node = jsonContent;
      for(int i = 0; i < list.length - 1; i++){
        node = node[list[i]];
      }
      List<String> keys = node[list.last].keys.toList();
      node[list.last] = keys;
    }

    String? valueFlatten = onParseResult["valueFlatten"];
    if(valueFlatten != null){
      List<String> list = valueFlatten.split(".");
      Map<String, dynamic> node = jsonContent;
      for(int i = 0; i < list.length - 1; i++){
        node = node[list[i]];
      }
      List keys = node[list.last].values.toList();
      node[list.last] = keys;
    }
    return jsonEncode(jsonContent);
  }

}
