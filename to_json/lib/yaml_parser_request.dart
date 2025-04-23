import 'package:to_json/yaml_parser_request_base.dart';
import 'package:yaml/yaml.dart';
import 'package:logging/logging.dart';

class YamlRequestParser extends YamlRequestBaseParser {
  final _log = Logger('RequestParser');

  @override
  Future<String> parseUseYaml(String content, YamlMap doc, String pageName,
      {Map<String, String>? headers, Map<String, String>? params}) async {
    YamlMap onParseResult = doc["onParseResult"];
    Map<String, String> headers = getHeaders(onParseResult);
    headers.addAll(globalParser()?.headers() ?? {});

    Map<String, String> allParams = {};
    allParams.addAll(globalParams());
    if (params != null) {
      allParams.addAll(params);
    }
    String url = getUrl(onParseResult, allParams);
    _log.fine("headers=${headers};url=${url};allParams=${allParams}");
    String? data;
    try {
      data = await connector()?.request(url, headers: headers);
    } catch (e) {
      return "$e";
    }
    return data ?? content;
  }
}
