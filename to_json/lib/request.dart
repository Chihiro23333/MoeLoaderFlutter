import 'package:to_json/models.dart';
import 'package:to_json/yaml_parser_base.dart';
import 'package:to_json/yaml_global.dart';
import 'package:to_json/yaml_parser_list.dart';
import 'package:yaml/yaml.dart';

class Request{

  final Parser _listParser = ListParser();
  final GlobalParser _globalParser = GlobalParser();

  GlobalParser globalParser(YamlMap doc) {
    _globalParser.updateDoc(doc);
    return _globalParser;
  }

  Future<String> request(YamlMap doc, String pageName, {Connector? connector, Map<String, String>? params}) async{
    _listParser.configGlobalParams(GlobalParams(connector, params, globalParser(doc)));
    String data = await _listParser.parseUseYaml("", doc, pageName);
    return data;
  }

  Future<String> requestByUrl(String url, YamlMap doc, String pageName, Connector connector) async{
    String content;
    try{
      content = await connector.request(url, headers: globalParser(doc).headers());
    }catch(e){
      content =  "$e";
    }
    String data = await _listParser.parseUseYaml(content, doc, pageName);
    return data;
  }

}
