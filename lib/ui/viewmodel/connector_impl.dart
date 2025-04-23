import 'package:moeloaderflutter/repo/yaml_reposotory.dart';
import 'package:to_json/yaml_parser_base.dart';

class ConnectorImpl extends Connector{

  YamlRepository repository;

  ConnectorImpl(this.repository);

  @override
  Future<String> request(String url, {Map<String, String>? headers}) async{
    return await repository.request(url, headers: headers);
  }

  @override
  Future<String> dioRequestRedirectUrl(String url, {Map<String, String>? headers}) async{
    return await repository.dioRequestRedirectUrl(url, headers: headers);
  }

  @override
  Future<String> redirectNoRequest(String url, {Map<String, String>? headers}) async{
    return await repository.dioRequestNoRedirect(url, headers: headers);
  }

}