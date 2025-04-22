import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:logging/logging.dart';
import 'package:moeloaderflutter/net/dio_http.dart';
import 'package:to_json/validator.dart';

class RequestManager{

  final _log = Logger('RequestManager');

  static RequestManager? _cache;
  RequestManager._create();
  factory RequestManager(){
    return _cache ?? (_cache = RequestManager._create());
  }

  static const fromHomePage = 0;
  static const fromDetailPage = 1;
  static const fromChallengePage = 2;

  late final DioHttp _dioHttp;

  Future<void> init() async{
    _dioHttp  = DioHttp();
  }

  Future<String> dioRequest(String url, {Map<String, String>? headers}) async {
      var response = await _dioHttp.get(url, headers: headers);
      var result = response.toString();
      return result;
  }

  Future<String> dioRequestRedirectUrl(String url, {Map<String, String>? headers}) async {
    Headers responseHeaders = await _dioHttp.getHeaders(url, headers: headers);
    String result = responseHeaders.value("location") ?? "";
    return result;
  }

  Future<void> saveCookiesString(String origin, String cookiesString) async{
    await _dioHttp.saveCookiesString(origin, cookiesString);
  }

  Future<bool> download(String url, String savePath, {ProgressCallback? onReceiveProgress, CancelToken? cancelToken, Map<String, String>? headers}) async{
    try{
      await _dioHttp.download(url, savePath, onReceiveProgress: onReceiveProgress, cancelToken: cancelToken, headers: headers);
      return Future.value(true);
    }catch(e){
      _log.fine(e);
      return Future.value(false);
    }
  }
}