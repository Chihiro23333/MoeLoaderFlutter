import 'package:MoeLoaderFlutter/yamlhtmlparser/yaml_rule_factory.dart';
import 'package:MoeLoaderFlutter/yamlhtmlparser/yaml_validator.dart';
import 'package:MoeLoaderFlutter/net/request_manager.dart';
import 'package:logging/logging.dart';
import 'models.dart';

class YamlRepository {

  final _log = Logger('YamlRepository');

  final YamlRuleFactory _ruleFactory = YamlRuleFactory();

  Future<ValidateResult<String>> home(String url, {Map<String, String>? headers}) async {
    Validator validator = HomeValidator();
    ValidateResult<String> result = await _request(url, validator, headers: headers);
    return result;
  }

  Future<ValidateResult<String>> detail(String url, {Map<String, String>? headers}) async {
    Validator validator = DetailValidator();
    ValidateResult<String> result = await _request(url, validator, headers: headers);
    return result;
  }

  Future<ValidateResult<String>> poolList(String url, {Map<String, String>? headers}) async {
    Validator validator = DetailValidator();
    ValidateResult<String> result = await _request(url, validator, headers: headers);
    return result;
  }

  List<WebPageItem> webPageList() {
    List<WebPageItem> list = [];
    _ruleFactory.webPageList().forEach((element) {
        list.add(WebPageItem(element));
    });
    return list;
  }

  Future<ValidateResult<String>> _request(String url, Validator validator, {Map<String, String>? headers}) async{
    _log.fine("url=$url");
    ValidateResult<String> result = await RequestManager().dioRequest(url, validator, headers: headers);
    return result;
  }
}
