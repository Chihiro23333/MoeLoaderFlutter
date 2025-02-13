import 'package:moeloaderflutter/net/request_manager.dart';
import 'package:moeloaderflutter/util/utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:logging/logging.dart';
import 'package:to_json/validator.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'dart:async';
import 'package:webview_flutter_android/webview_flutter_android.dart'; // 仅 Android 需要

class WebViewAndroidPage extends StatefulWidget {
  WebViewAndroidPage(
      {super.key, required this.url, required this.code, this.userAgent});

  final String? userAgent;
  final String url;
  final int code;

  @override
  State<WebViewAndroidPage> createState() => _WebViewAndroidState();
}

class _WebViewAndroidState extends State<WebViewAndroidPage> {
  late final WebViewController _controller;
  late String _url;
  final _log = Logger('_WebViewAndroidState');

  @override
  void initState() {
    super.initState();
    _url = widget.url;
    // 初始化 WebViewController
    final WebViewController controller = WebViewController();

    controller
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..loadRequest(Uri.parse(_url)) // 加载网页
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageFinished: (String url) async {
            _log.info("onPageFinished");
          },
        ),
      );
    // 启用 Android WebView 调试
    if (controller.platform is AndroidWebViewController) {
      AndroidWebViewController.enableDebugging(true);
      (controller.platform as AndroidWebViewController)
          .setMediaPlaybackRequiresUserGesture(false);
    }
    _controller = controller;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: _buildFloatActionButton(context),
      appBar: AppBar(
        title: const Text(
          "网页访问",
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
        ),
        actions: _buildAppbarActions(context),
      ),
      body: Center(
        child: WebViewWidget(controller: _controller),
      ),
    );
  }

  List<Widget> _buildAppbarActions(BuildContext context) {
    return [
      Padding(
        padding:
            const EdgeInsets.only(top: 10, bottom: 10, left: 10, right: 10),
        child: GestureDetector(
          child: Icon(
            Icons.refresh,
            color: Theme.of(context).iconTheme.color,
          ),
          onTap: () {
            _controller.loadRequest(Uri.parse(_url));
          },
        ),
      ),
      Padding(
        padding:
            const EdgeInsets.only(top: 10, bottom: 10, left: 10, right: 10),
        child: GestureDetector(
          onTap: () {
            _controller.goBack();
          },
          child: Icon(
            Icons.arrow_back,
            color: Theme.of(context).iconTheme.color,
          ),
        ),
      ),
      Padding(
        padding:
            const EdgeInsets.only(top: 10, bottom: 10, left: 10, right: 10),
        child: GestureDetector(
          onTap: () {
            _controller.goForward();
          },
          child: Icon(
            Icons.arrow_forward,
            color: Theme.of(context).iconTheme.color,
          ),
        ),
      ),
    ];
  }

  Widget _buildFloatActionButton(BuildContext context) {
    if(widget.code == ValidateResult.success){
      return const SizedBox();
    }
    return FloatingActionButton.extended(
        onPressed: () async {
          await _saveCookies(context);
          Navigator.of(context).pop(true);
        },
        extendedTextStyle: const TextStyle(fontWeight: FontWeight.bold),
        label: Row(
          children: [
            Text(validateCompleteTipsByCode(widget.code)),
            const SizedBox(
              width: 10,
            ),
            Icon(
              Icons.check,
              color: Theme.of(context).iconTheme.color,
            ),
          ],
        ));
  }

  Future<void> _saveCookies(BuildContext context) async {
    // 页面加载完成后获取 Cookies
    final String? cookiesResult = await _controller
        .runJavaScriptReturningResult('document.cookie') as String?;
    _log.info("cookiesResult=$cookiesResult");
    if (cookiesResult != null && cookiesResult.isNotEmpty) {
      String origin = Uri.parse(_url).origin;
      await RequestManager().saveCookiesString(origin, cookiesResult);
    }
  }
}
