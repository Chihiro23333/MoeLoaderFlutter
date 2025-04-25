import 'dart:convert';
import 'package:to_json/models.dart';
import 'package:to_json/utils.dart';
import 'package:to_json/validator.dart';
import 'package:to_json/yaml_parser_base.dart';
import 'package:to_json/yaml_parser_html.dart';
import 'package:to_json/yaml_parser_json.dart';
import 'package:to_json/yaml_parser_json_transform.dart';
import 'package:to_json/yaml_parser_request.dart';
import 'package:to_json/yaml_parser_request_redirect.dart';
import 'package:yaml/yaml.dart';
import 'package:logging/logging.dart';

class ListParser extends Parser {
  final _log = Logger('ListParser');

  final Parser _yamlHtmlParser = YamlHtmlParser();
  final Parser _yamlJsonParser = YamlJsonParser();
  final Parser _yamlRequestParser = YamlRequestParser();
  final Parser _yamlRedirectParser = YamlRedirectParser();
  final Parser _jsonTransformParser = JsonTransformParser();

  @override
  configGlobalParams(GlobalParams globalParams) {
    _yamlRequestParser.configGlobalParams(globalParams);
    _yamlRedirectParser.configGlobalParams(globalParams);
    _yamlJsonParser.configGlobalParams(globalParams);
  }

  @override
  Future<String> parseUseYaml(String content, YamlMap doc, String pageName,
      {Map<String, String>? headers, Map<String, String>? params}) async {
    try {
      YamlList? pageDocList = doc[pageName]["chain"];
      if (pageDocList == null) {
        throw "pageName或chain找不到";
      }

      List<ParserNode> parserNodes = [];
      for (var parserDoc in pageDocList) {
        YamlMap onParseResult = parserDoc["onParseResult"];
        String contentType = onParseResult["contentType"] ?? "html";
        _log.fine("contentType=${contentType}");
        switch (contentType) {
          case "json":
            parserNodes.add(ParserNode(parserDoc, _yamlJsonParser));
            break;
          case "request":
            parserNodes.add(ParserNode(parserDoc, _yamlRequestParser));
            break;
          case "no_redirect_request":
            parserNodes.add(ParserNode(parserDoc, _yamlRedirectParser));
            break;
          case "json_transform":
            parserNodes.add(ParserNode(parserDoc, _jsonTransformParser));
            break;
          default:
            parserNodes.add(ParserNode(parserDoc, _yamlHtmlParser));
        }
      }

      String data = content;
      Map<String, String> parseParams = {};
      Map<String, String> parseHeaders = {};
      for (var parserNode in parserNodes) {
        parserNode.parser.reset();
        Validator validator = Validator(parserNode.doc);
        ValidateResult<String> validateResult =
            await validator.validateResult(data);
        if (validateResult.validateSuccess) {
          data = await parserNode.parser.parseUseYaml(
              data, parserNode.doc, pageName,
              headers: parseHeaders, params: parseParams);
          switch (parserNode.parser.parseState().code) {
            case Parser.interrupt:
              return toResult(
                  Parser.success, parserNode.parser.parseState().message, null);
            case Parser.success:
              continue;
            default:
              return toResult(validateResult.code, data, "");
          }
        } else {
          return toResult(validateResult.code, data, "");
        }
      }

      return toResult(Parser.success, "解析成功", jsonDecode(data));
    } catch (e) {
      return toResult(Parser.fail, "$e", "");
    }
  }
}

class ParserNode {
  YamlMap doc;
  Parser parser;

  ParserNode(this.doc, this.parser);
}
