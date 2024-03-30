import 'package:to_json/yaml_parser_base.dart';
import 'package:to_json/yaml_parser_mix.dart';

class ParserFactory {
  static ParserFactory? _cache;

  ParserFactory._create();

  factory ParserFactory() {
    return _cache ?? (_cache = ParserFactory._create());
  }

  final MixParser _mixParser = MixParser();

  Parser createParser() {
    return _mixParser;
  }
}

