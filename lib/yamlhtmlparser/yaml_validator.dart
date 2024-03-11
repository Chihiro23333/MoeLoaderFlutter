import 'package:MoeLoaderFlutter/yamlhtmlparser/yaml_rule_factory.dart';
import 'package:yaml/yaml.dart';
import '../init.dart';

abstract class Validator{

  Future<ValidateResult<String>> validateResult(String result);

  Future<ValidateResult<String>> validateException(Object exception) async{
    print("exception=$exception");
    if(exception is Exception){
      String message = exception.toString();
      YamlMap doc = await YamlRuleFactory().create(Global.curWebPageName);
      YamlMap? validatorRule = doc["detailPage"]?["onValidateResult"];
      if(validatorRule != null){
        YamlMap? exceptionRule = validatorRule["exception"];
        if(exceptionRule != null){
          String action = exceptionRule["action"];
          String msgCode = exceptionRule["code"];
          if(message.contains(msgCode)){
            int code;
            String message = "";
            if(Global.supportWebView2){
              if(action == "login"){
                code = ValidateResult.needLogin;
              }else{
                code = ValidateResult.needChallenge;
              }
            }else{
              code = ValidateResult.notSupportWebView2;
              message = "您的设备暂不支持或者未安装WebView2组件";
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

Future<ValidateResult<String>> _validateResult(String result, YamlMap? page) async{
  YamlList? resultRule = page?["onValidateResult"]?["result"];
  if(resultRule != null){
    Iterator iterator = resultRule.iterator;
    while(iterator.moveNext()){
      YamlMap item = iterator.current;
      RegExp regExp = RegExp(item["regex"]);
      if(regExp.hasMatch(result)){
        String action = item["action"];
        int code;
        String message = "";
        if(Global.supportWebView2){
          if(action == "login"){
            code = ValidateResult.needLogin;
          }else{
            code = ValidateResult.needChallenge;
          }
        }else{
          code = ValidateResult.notSupportWebView2;
          message = "您的设备暂不支持或者未安装WebView2组件";
        }
        return ValidateResult(code, data: result, message: message);
      }
    }
  }
  return ValidateResult(ValidateResult.success, data: result);
}

class HomeValidator extends Validator{

  @override
  Future<ValidateResult<String>> validateResult(String result) async{
    YamlMap doc = await YamlRuleFactory().create(Global.curWebPageName);
    return _validateResult(result, doc["homePage"]);
  }

}

class DetailValidator extends Validator{
  @override
  Future<ValidateResult<String>> validateResult(String result) async{
    YamlMap doc = await YamlRuleFactory().create(Global.curWebPageName);
    return _validateResult(result, doc["detailPage"]);
  }
}

class ValidateResult<T>{

  static const fail = 0;
  static const success = 1;
  static const needChallenge = 2;
  static const needLogin = 3;
  static const notSupportWebView2 = 4;

  int code;
  String? message;
  T? data;

  bool get validateSuccess => code == success;
  bool get validateFail => code == fail;
  bool get validateNeedChallenge => code == needChallenge;
  bool get validateNeedLogin => code == needLogin;
  bool get validateNotSupportWebView2 => code == notSupportWebView2;

  ValidateResult(this.code, {this.message, this.data});
}