import 'package:moeloaderflutter/net/request_manager.dart';
import 'package:logging/logging.dart';
import 'package:to_json/models.dart';
import 'package:to_json/validator.dart';
import 'package:to_json/yaml_rule_factory.dart';

class YamlRepository {

  final _log = Logger('YamlRepository');

  final YamlRuleFactory _ruleFactory = YamlRuleFactory();

  Future<String> home(String url, {Map<String, String>? headers}) async {
    String result = await _request(url, headers: headers);
    return result;
  }

  Future<String> detail(String url, {Map<String, String>? headers}) async {
    String result = await _request(url, headers: headers);
    return result;
  }

  Future<String> poolList(String url, {Map<String, String>? headers}) async {
    String result = await _request(url, headers: headers);
    return result;
  }

  Future<String> request(String url, {Map<String, String>? headers}) async {
    String result = await _request(url, headers: headers);
    return result;
  }

  List<Rule> webPageList() {
    List<Rule> list = [];
    _ruleFactory.webPageList().forEach((element) {
        list.add(element);
    });
    return list;
  }

  Future<String> _request(String url, {Map<String, String>? headers}) async{
    _log.fine("url=$url");
    String result = await RequestManager().dioRequest(url, headers: headers);
    return result;
  }
}
