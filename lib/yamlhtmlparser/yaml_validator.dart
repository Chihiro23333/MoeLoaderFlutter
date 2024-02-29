import 'package:dio/dio.dart';
import 'package:FlutterMoeLoaderDesktop/yamlhtmlparser/yaml_rule_factory.dart';
import 'package:yaml/yaml.dart';
import '../init.dart';

abstract class Validator{

  Future<ValidateResult<String>> validateResult(String result);

  Future<ValidateResult<String>> validateException(Object exception) async{
    if(exception is DioException){
      String? message = exception.message;
      YamlMap doc = await YamlRuleFactory().create(Global.curWebPageName);
      YamlMap? validatorRule = doc["detailPage"]?["onValidateResult"];
      if(message != null && validatorRule != null){
        YamlMap? exceptionRule = validatorRule["exception"];
        if(exceptionRule != null){
          String action = exceptionRule["action"];
          String msgCode = exceptionRule["code"];
          if(message.contains(msgCode)){
            int code;
            if(action == "login"){
              code = ValidateResult.needLogin;
            }else{
              code = ValidateResult.needChallenge;
            }
            return ValidateResult(code, message: message);
          }
        }
      }
      return ValidateResult(ValidateResult.fail, message: message);
    }
    return ValidateResult(ValidateResult.fail, message: exception.toString());
  }

}

Future<ValidateResult<String>> _validateResult(String result) async{
  YamlMap doc = await YamlRuleFactory().create(Global.curWebPageName);
  YamlList? resultRule = doc["detailPage"]?["onValidateResult"]?["result"];
  if(resultRule != null){
    Iterator iterator = resultRule.iterator;
    while(iterator.moveNext()){
      YamlMap item = iterator.current;
      RegExp regExp = RegExp(item["regex"]);
      if(regExp.hasMatch(result)){
        String action = item["action"];
        int code;
        if(action == "login"){
          code = ValidateResult.needLogin;
        }else{
          code = ValidateResult.needChallenge;
        }
        return ValidateResult(code, data: result);
      }
    }
  }
  return ValidateResult(ValidateResult.success, data: result);
}

class HomeValidator extends Validator{

  @override
  Future<ValidateResult<String>> validateResult(String result) async{
    return _validateResult(result);
  }

}

class DetailValidator extends Validator{
  @override
  Future<ValidateResult<String>> validateResult(String result) async{
    return _validateResult(result);
  }
}

class ValidateResult<T>{

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