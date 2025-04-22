import 'package:to_json/request.dart';

class RequestFactory {
  static RequestFactory? _cache;

  RequestFactory._create();

  factory RequestFactory() {
    return _cache ?? (_cache = RequestFactory._create());
  }

  final Request _request = Request();

  Request create() {
    return _request;
  }
}

