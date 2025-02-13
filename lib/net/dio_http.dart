import 'dart:async';
import 'dart:io';
import 'package:dio/io.dart';
import 'package:moeloaderflutter/util/db_util.dart';
import 'package:cookie_jar/cookie_jar.dart';
import 'package:dio/dio.dart';
import 'package:dio_cookie_manager/dio_cookie_manager.dart';
import 'package:moeloaderflutter/init.dart';
import 'package:dio_http2_adapter/dio_http2_adapter.dart';
import 'package:logging/logging.dart';

class DioHttp {
  final _log = Logger('DioHttp');

  final _cookieManager = CookieManager(CookieJar());
  late Dio _dio;

  DioHttp() {
    BaseOptions baseOptions = BaseOptions(
      receiveDataWhenStatusError: true,
      responseType: ResponseType.plain,
    );
    _dio = _logDio(baseOptions);
    _loadAllCookies();
  }

  Dio _logDio([BaseOptions? options, bool http2 = false]) {
    var dio = Dio(options)
      ..interceptors.add(_cookieManager)
      ..interceptors.add(LogInterceptor());
      // ..httpClientAdapter = Http2Adapter(
      //   ConnectionManager(
      //     idleTimeout: const Duration(seconds: 10),
      //     onClientCreate: (_, config) => config.onBadCertificate = (_) => true,
      //   ));
    return dio;
  }

  Future<String> get(String url, {Map<String, String>? headers}) async {
    _log.fine("url=${url}");
    _updateHeaders(headers);
    var response = await _dio.get(url);
    var result = response.toString();
    _log.fine("result=$result");
    return result;
  }

  void _updateHeaders(Map<String, String>? headers) {
    BaseOptions baseOptions = _dio.options;
    Map<String, dynamic> nowHeaders = baseOptions.headers;
    nowHeaders.clear();
    if (headers != null) {
      headers.forEach((key, value) {
        nowHeaders[key] = value;
      });
    }
    _log.fine("nowHeaders=${nowHeaders}");
  }

  Future<void> saveCookiesString(String origin, String cookiesString) async {
    await _transformCookies(origin, cookiesString);
  }

  Future<Response> download(String url, String savePath,
      {ProgressCallback? onReceiveProgress,
      CancelToken? cancelToken,
      Map<String, String>? headers}) async {
    _updateHeaders(headers);
    return await _dio.download(url, savePath,
        onReceiveProgress: onReceiveProgress, cancelToken: cancelToken);
  }

  Future<void> _transformCookies(String origin, String cookiesString) async{
    if (cookiesString.isNotEmpty) {
      await saveCookieString(origin, cookiesString);
      await _updateCookies(Uri.parse(origin), cookiesString);
    }
  }

  Future<void> _updateCookies(Uri uri, String cookiesString) async {
    List<Cookie> cookies = [];
    if (cookiesString.isNotEmpty) {
      List<String> cookieList = cookiesString.split(";");
      for (var cookie in cookieList) {
        List<String> keyValue = Global.multiPlatform.cookieSeparator(cookie);
        String key = keyValue[0];
        String value = keyValue[1];
        // 去除键和值中的双引号和两端的空格（如果有）
        final String cleanedKey = key.replaceAll('"', '').trim();
        final String cleanedValue = value.replaceAll('"', '');
        _log.fine("_updateCookies:key=$key;value=$value");
        cookies.add(Cookie(cleanedKey, cleanedValue));
      }
    }
    if (cookies.isNotEmpty) {
      await _cookieManager.cookieJar.saveFromResponse(uri, cookies);
      _log.fine("saveFromResponse,uri=$uri");
    }
  }

  Future<void> _loadAllCookies() async {
    Map<String, String> cookiesMap = await getAllCookieString();
    cookiesMap.forEach((key, value) async {
      _log.fine("cookiesMap:key=$key,value=$value");
      await _updateCookies(Uri.parse(key), value);
    });
  }
}
