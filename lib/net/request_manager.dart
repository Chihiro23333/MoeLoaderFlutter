import 'dart:async';
import 'package:dio/dio.dart';
import 'package:moeloaderflutter/net/dio_http.dart';
import 'package:to_json/validator.dart';

class RequestManager{

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

  Future<ValidateResult<String>> dioRequest(String url, Validator validator, {Map<String, String>? headers}) async {
    try {
      var response = await _dioHttp.get(url, headers: headers);
      var result = response.toString();
      ValidateResult<String> validateResult = await validator.validateResult(result);
      return validateResult;
    }catch(e){
      return await validator.validateException(e);
    }
  }

  Future<void> saveCookiesString(String origin, String cookiesString) async{
    await _dioHttp.saveCookiesString(origin, cookiesString);
  }

  Future<Response> download(String url, String savePath, {ProgressCallback? onReceiveProgress, CancelToken? cancelToken, Map<String, String>? headers}) async {
   return await _dioHttp.download(url, savePath, onReceiveProgress: onReceiveProgress, cancelToken: cancelToken, headers: headers);
  }

}