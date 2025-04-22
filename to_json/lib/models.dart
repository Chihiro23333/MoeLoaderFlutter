import 'package:to_json/yaml_parser_base.dart';
import 'package:to_json/yaml_global.dart';

class Rule{
  String type;
  String path;
  String fileName;
  String faviconPath;
  bool canSearch;

  Rule(this.type, this.path, this.fileName, this.faviconPath, this.canSearch);
}

class GlobalParams{
  Connector? connector;
  Map<String, String>? params;
  GlobalParser? globalParser;

  GlobalParams(this.connector, this.params, this.globalParser);
}