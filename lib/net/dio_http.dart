import 'dart:async';
import 'dart:io';
import 'package:moeloaderflutter/init.dart';
import 'package:moeloaderflutter/util/db_util.dart';
import 'package:cookie_jar/cookie_jar.dart';
import 'package:dio/dio.dart';
import 'package:dio_cookie_manager/dio_cookie_manager.dart';
import 'package:logging/logging.dart';

class DioHttp {
  final _log = Logger('DioHttp');

  final _cookieManager = CookieManager(CookieJar());
  late Dio _dio;
  final BaseOptions _baseOptions = BaseOptions(
      receiveDataWhenStatusError: true,
      responseType: ResponseType.plain,
      followRedirects: true,
      validateStatus: (status) {
        return status != null && status < 400;
      }
  );
  late final BaseOptions _downloadOptions = BaseOptions(
      receiveDataWhenStatusError: true,
      responseType: ResponseType.bytes,
      followRedirects: true,
      validateStatus: (status) {
        return status != null && status < 400;
      }
  );
  final BaseOptions _redirectsYesOptions = BaseOptions(
      receiveDataWhenStatusError: true,
      responseType: ResponseType.plain,
      followRedirects: false,
      validateStatus: (status) {
        return status != null &&
            (status < 300 || status == 302 || status == 301);
      }
  );
  final BaseOptions _redirectsNoOptions = BaseOptions(
      receiveDataWhenStatusError: true,
      responseType: ResponseType.plain,
      followRedirects: false
  );

  DioHttp() {
    _dio = _logDio(_baseOptions);
    _loadAllCookies();
  }

  Dio _logDio([BaseOptions? options, bool http2 = false]) {
    var dio = Dio(options)
      ..interceptors.add(_cookieManager)
      ..interceptors.add(LogInterceptor())
      ..interceptors.add(HeaderInterceptor());
    // ..httpClientAdapter = Http2Adapter(
    //   ConnectionManager(
    //     idleTimeout: const Duration(seconds: 10),
    //     onClientCreate: (_, config) => config.onBadCertificate = (_) => true,
    //   ));
    return dio;
  }

  Future<String> get(String url, {Map<String, String>? headers}) async {
    _updateHeaders(headers);
    var response = await _dio.get(url);
    var result = response.toString();
    return result;
  }

  Future<Response> redirectYestGet(String url,
      {Map<String, String>? headers}) async {
    _dio.options = _redirectsYesOptions;
    _updateHeaders(headers);
    Response response = await _dio.get(url);
    _dio.options = _baseOptions;
    return response;
  }

  Future<Response> redirectNotGet(String url,
      {Map<String, String>? headers}) async {
    _dio.options = _redirectsNoOptions;
    _updateHeaders(headers);
    Response response = await _dio.get(url);
    _dio.options = _baseOptions;
    return response;
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
  }

  Future<void> saveCookiesString(String origin, String cookiesString) async {
    await _transformCookies(origin, cookiesString);
  }

  Future<Response> download(String url, String savePath,
      {ProgressCallback? onReceiveProgress,
        CancelToken? cancelToken,
        Map<String, String>? headers}) async {
    _updateHeaders(headers);
    // 创建一个专门用于下载的 Dio 实例，支持重定向
    final downloadDio = Dio(_downloadOptions);
    downloadDio.interceptors.add(_cookieManager);
    
    try {
      return await downloadDio.download(
        url, 
        savePath,
        onReceiveProgress: onReceiveProgress, 
        cancelToken: cancelToken
      );
    } on DioException catch (e) {
      // 如果是 307 重定向错误，手动处理
      if (e.response?.statusCode == 307) {
        final location = e.response?.headers.value('location');
        if (location != null && location.isNotEmpty) {
          _log.info('307 redirect to: $location');
          // 使用重定向后的 URL 重新下载
          return await downloadDio.download(
            location, 
            savePath,
            onReceiveProgress: onReceiveProgress, 
            cancelToken: cancelToken
          );
        }
      }
      rethrow;
    }
  }

  Future<void> _transformCookies(String origin, String cookiesString) async {
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
        final String cleanedValue = value.replaceAll('"', '').trim();
        cookies.add(Cookie(cleanedKey, cleanedValue));
      }
    }
    if (cookies.isNotEmpty) {
      await _cookieManager.cookieJar.saveFromResponse(uri, cookies);
    }
  }

  Future<void> _loadAllCookies() async {
    Map<String, String> cookiesMap = await getAllCookieString();
    cookiesMap.forEach((key, value) async {
      await _updateCookies(Uri.parse(key), value);
    });
  }
}

class HeaderInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    options.headers['X-Platform'] = 'web';
    super.onRequest(options, handler);
  }
}
