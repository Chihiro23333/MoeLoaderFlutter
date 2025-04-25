import 'package:to_json/yaml_parser_base.dart';
import 'package:yaml/yaml.dart';
import 'package:logging/logging.dart';

class Validator {
  final _log = Logger('Validator');

  late YamlMap _pageDoc;

  Validator(YamlMap yamlDoc) {
    _pageDoc = yamlDoc;
  }

  Future<ValidateResult<String>> validateResult(String content) async {
    YamlList? onValidateRule = _pageDoc["onValidateResult"];
    if (onValidateRule != null) {
      Iterator iterator = onValidateRule.iterator;
      while (iterator.moveNext()) {
        YamlMap item = iterator.current;
        _log.fine("item=$item");
        YamlMap? regexRule = item["regex"];
        if (regexRule != null) {
          RegExp regExp = RegExp(regexRule["regex"]);
          if (regExp.hasMatch(content)) {
            String action = regexRule["action"];
            int code;
            String message = "";
            switch (action) {
              case "login":
                code = Parser.needLogin;
                message = "需要登录";
                break;
              case "redirect":
                code = Parser.needRedirect;
                message = "需要重定向";
                break;
              default:
                code = Parser.needChallenge;
                message = "需要安全挑战";
            }
            return ValidateResult(code, message: message, data: content);
          }
        }
      }
    }

    if(content.contains("DioException")){
      return ValidateResult(Parser.fail, data: content);
    }

    return ValidateResult(Parser.success, data: content);
  }
}

class ValidateResult<T> {
  static const fail = 0;
  static const success = 1;
  static const needChallenge = 2;
  static const needLogin = 3;
  static const needRedirect = 4;

  int code;
  String? message;
  T? data;

  bool get validateSuccess => code == success;

  bool get validateFail => code == fail;

  bool get validateNeedChallenge => code == needChallenge;

  bool get validateNeedLogin => code == needLogin;

  bool get validateNeedRedirect => code == needRedirect;

  ValidateResult(this.code, {this.message, this.data});
}
