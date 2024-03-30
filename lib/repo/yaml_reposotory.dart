import 'package:MoeLoaderFlutter/net/request_manager.dart';
import 'package:logging/logging.dart';
import 'package:to_json/models.dart';
import 'package:to_json/validator.dart';
import 'package:to_json/yaml_rule_factory.dart';

class YamlRepository {

  final _log = Logger('YamlRepository');

  final YamlRuleFactory _ruleFactory = YamlRuleFactory();

  Future<ValidateResult<String>> home(String url, Validator validator, {Map<String, String>? headers}) async {
    ValidateResult<String> result = await _request(url, validator, headers: headers);
    return result;
  }

  Future<ValidateResult<String>> detail(String url, Validator validator, {Map<String, String>? headers}) async {
    ValidateResult<String> result = await _request(url, validator, headers: headers);
    return result;
  }

  Future<ValidateResult<String>> poolList(String url, Validator validator, {Map<String, String>? headers}) async {
    ValidateResult<String> result = await _request(url, validator, headers: headers);
    return result;
  }

  List<Rule> webPageList() {
    List<Rule> list = [];
    _ruleFactory.webPageList().forEach((element) {
        list.add(element);
    });
    return list;
  }

  Future<ValidateResult<String>> _request(String url, Validator validator, {Map<String, String>? headers}) async{
    _log.fine("url=$url");
    ValidateResult<String> result = await RequestManager().dioRequest(url, validator, headers: headers);
    return result;
  }
}
