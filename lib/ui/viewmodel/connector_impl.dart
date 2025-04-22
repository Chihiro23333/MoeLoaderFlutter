import 'package:moeloaderflutter/repo/yaml_reposotory.dart';
import 'package:to_json/yaml_parser_base.dart';

class ConnectorImpl extends Connector{

  YamlRepository repository;

  ConnectorImpl(this.repository);

  @override
  Future<String> request(String url, {Map<String, String>? headers}) async{
    return await repository.request(url, headers: headers);
  }

}