// import 'dart:async';
// import 'dart:io';
// import 'package:flutter/material.dart';
// import 'package:flutter/services.dart';
// import 'package:FlutterMoeLoaderDesktop/net/net_models.dart';
// import 'package:FlutterMoeLoaderDesktop/yamlhtmlparser/yaml_validator.dart';
// import 'package:logging/logging.dart';
// import 'package:webview_windows/webview_windows.dart';
// import 'package:window_manager/window_manager.dart';
//
// class WebViewWindowsHttp {
//
//   final log = Logger('WebViewWindowsHttp');
//
//   static const _getHtmlJS =
//       'document.getElementsByTagName("html")[0].innerHTML';
//
//   final _controller = WebviewController();
//   final List<StreamSubscription> _subscriptions = [];
//   WebErrorStatus? _webErrorStatus;
//   String? _title;
//
//   WebViewWindowsHttp();
//
//   WebviewController get webViewController => _controller;
//
//   Future<void> initWebView() async{
//     try {
//       await _controller.initialize();
//       _subscriptions.add(_controller.url.listen((url) {
//         log.fine("url=$url");
//       }));
//       _subscriptions.add(_controller.containsFullScreenElementChanged.listen((flag) {
//         log.fine('Contains fullscreen element: $flag');
//         windowManager.setFullScreen(flag);
//       }));
//       _subscriptions.add(_controller.loadingState.listen((loadingState) {
//         log.fine("loadingState=$loadingState");
//       }));
//       _subscriptions.add(_controller.securityStateChanged.listen((securityState) {
//         log.fine("securityState=$securityState");
//       }));
//       _subscriptions.add(_controller.title.listen((title) {
//         log.fine("title=$title");
//       }));
//       _subscriptions.add(_controller.onLoadError.listen((error) {
//         log.fine("error=$error");
//         _webErrorStatus = error;
//       }));
//       _subscriptions.add(_controller.historyChanged.listen((history) {
//         log.fine("history=$history");
//       }));
//       await _controller.setBackgroundColor(Colors.transparent);
//       await _controller.setPopupWindowPolicy(WebviewPopupWindowPolicy.deny);
//     } on PlatformException catch (e) {
//       log.fine("e=$e");
//     }
//   }
//
//   Future<Result<String>> get(String url, {int timeout = 10, bool waitForNavigationCompleted = false, Validator? validator}) async {
//     _webErrorStatus = null;
//     await _controller.loadUrl(url);
//     if(waitForNavigationCompleted){
//       //收到网页加载完成的状态之后再去取网页数据
//       await _controller.loadingState.firstWhere((element){
//         log.fine("element=${element == LoadingState.navigationCompleted}");
//         return element == LoadingState.navigationCompleted;
//       });
//     }else{
//       //收到开始loading的状态之后再去取网页数据
//       await _controller.loadingState.firstWhere((element){
//         log.fine("element=${element == LoadingState.navigationCompleted}");
//         return element == LoadingState.loading;
//       });
//     }
//     String result = "";
//     try {
//       int time = 0;
//       while (true) {
//         if(_webErrorStatus != null){
//           await _controller.stop();
//           return Result(Result.FAIL, message: _webErrorStatus.toString());
//         }
//         final html = await _controller.executeScript(_getHtmlJS);
//         if(validator != null){
//           ValidateResult validateResult = await validator.validate(html.toString());
//           log.fine("result:${validateResult.message}");
//           if(validateResult.validateFail){
//             await Future.delayed(const Duration(seconds: 1));
//             time++;
//             if (time >= timeout) {
//               await _controller.stop();
//               return Result(Result.FAIL, message: "请求超时");
//             }
//             continue;
//           }
//           if(validateResult.validateNeedChallenge && validateResult.validateTimeOut){
//             await _controller.stop();
//             return Result(Result.NEED_CHALLENGE, message: validateResult.message);
//           }
//         }
//         result = html ?? "";
//         await _controller.stop();
//         return Result(Result.SUCCESS, data: result);
//       }
//     } catch (e) {
//       log.fine('evaluateJavaScript error: $e');
//       await _controller.stop();
//       return Result(Result.FAIL, message: "$e");
//     }
//   }
//
//   Future<Result<String>> challenge(String url) async {
//     await _controller.loadUrl(url);
//     return Result(Result.SUCCESS);
//   }
//
// }
