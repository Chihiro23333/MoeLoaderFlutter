import 'package:to_json/yaml_parser_base.dart';
import 'package:yaml/yaml.dart';
import 'package:logging/logging.dart';

class Validator {
  final _log = Logger('Validator');

  late YamlMap _pageDoc;

  Validator(YamlMap yamlDoc, String pageName) {
    _pageDoc = yamlDoc[pageName];
  }

  Future<ValidateResult<String>> validateResult(String content) async {
    YamlList? onValidateRule = _pageDoc["onValidateResult"];
    if (onValidateRule != null) {
      Iterator iterator = onValidateRule.iterator;
      while (iterator.moveNext()) {
        YamlMap item = iterator.current;
        _log.info("item=$item");
        YamlMap? regexRule = item["regex"];
        if (regexRule != null) {
          RegExp regExp = RegExp(regexRule["regex"]);
          if (regExp.hasMatch(content)) {
            String action = regexRule["action"];
            int code;
            String message = "";
            if (action == "login") {
              code = Parser.needLogin;
              message = "需要登录";
            } else {
              code = Parser.needChallenge;
              message = "需要安全挑战";
            }
            return ValidateResult(code, message: message, data: content);
          }
        }
      }
    }
    return ValidateResult(Parser.success, data: content);
  }

  Future<ValidateResult<String>> validateException(Object exception) async {
    print("exception=$exception");
    if (exception is Exception) {
      String message = exception.toString();
      YamlList? onValidateRule = _pageDoc["onValidateResult"];
      if (onValidateRule != null) {
        Iterator iterator = onValidateRule.iterator;
        while (iterator.moveNext()) {
          YamlMap item = iterator.current;
          YamlMap? exceptionRule = item["exception"];
          if (exceptionRule != null) {
            String action = exceptionRule["action"];
            String msgCode = exceptionRule["code"];
            if (message.contains(msgCode)) {
              int code;
              String message = "";
              if (action == "login") {
                code = ValidateResult.needLogin;
              } else {
                code = ValidateResult.needChallenge;
              }
              return ValidateResult(code, message: message);
            }
          }
        }
      }
    }
    return ValidateResult(ValidateResult.fail, message: exception.toString());
  }
}

class ValidateResult<T> {
  static const fail = 0;
  static const success = 1;
  static const needChallenge = 2;
  static const needLogin = 3;

  int code;
  String? message;
  T? data;

  bool get validateSuccess => code == success;

  bool get validateFail => code == fail;

  bool get validateNeedChallenge => code == needChallenge;

  bool get validateNeedLogin => code == needLogin;

  ValidateResult(this.code, {this.message, this.data});
}
