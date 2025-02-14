import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:moeloaderflutter/net/request_manager.dart';
import 'package:moeloaderflutter/util/utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:logging/logging.dart';
import 'package:to_json/validator.dart';
import 'dart:async';

class InAppWebViewPage extends StatefulWidget {
  InAppWebViewPage(
      {super.key, required this.url, required this.code, this.userAgent});

  final String? userAgent;
  final String url;
  final int code;

  @override
  State<InAppWebViewPage> createState() => _InAppWebViewState();
}

class _InAppWebViewState extends State<InAppWebViewPage> {
  late InAppWebViewController _webViewController;
  late String _url;
  final _log = Logger('_WebViewAndroidState');

  @override
  void initState() {
    super.initState();
    _url = widget.url;
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
        child: InAppWebView(
          initialUrlRequest: URLRequest(url: WebUri(_url)),
          onWebViewCreated: (controller) {
            _webViewController = controller;
          },
          onLoadStop: (controller, url) async {
          },
        ),
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
            _webViewController.loadUrl(urlRequest: URLRequest(url: WebUri(_url)));
          },
        ),
      ),
      Padding(
        padding:
            const EdgeInsets.only(top: 10, bottom: 10, left: 10, right: 10),
        child: GestureDetector(
          onTap: () {
            _webViewController.goBack();
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
            _webViewController.goForward();
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
    // 获取指定 URL 的 Cookie
    var cookies = await CookieManager.instance().getCookies(url: WebUri(_url));
    String cookiesResult = cookies.map((cookie) => '${cookie.name}=${cookie.value}').join('; ');
    _log.fine("cookiesResult=$cookiesResult");
    if (cookiesResult.isNotEmpty) {
      String origin = Uri.parse(_url).origin;
      await RequestManager().saveCookiesString(origin, cookiesResult);
    }
  }
}
