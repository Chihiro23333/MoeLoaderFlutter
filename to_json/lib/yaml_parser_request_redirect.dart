import 'package:to_json/validator.dart';
import 'package:to_json/yaml_parser_request.dart';
import 'package:to_json/yaml_parser_request_base.dart';
import 'package:yaml/yaml.dart';
import 'package:logging/logging.dart';

class YamlRedirectParser extends YamlRequestBaseParser {
  final _log = Logger('YamlRedirectParser');

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
      data = await connector()?.redirectNoRequest(url, headers: headers);
    } catch (e) {
      data = "$e";
    }
    try {
      Validator validator = Validator(doc);
      ValidateResult<String> validateResult =
          await validator.validateResult(data ?? "");
      if (validateResult.validateNeedRedirect) {
        data = await connector()?.dioRequestRedirectUrl(url, headers: headers);
        String redirectUrl = data ?? "";
        allParams["redirectUrl"] = redirectUrl;
        String newUrl = getRedirectUrl(onParseResult, allParams);
        _log.fine("newUrl=${newUrl};");
        data = await connector()?.request(newUrl, headers: headers);
      } else {
        return data ?? "";
      }
      return data ?? content;
    } catch (e) {
      return "$e";
    }
  }
}
