import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:FlutterMoeLoaderDesktop/net/request_manager.dart';
import 'package:logging/logging.dart';
import 'dart:async';
import 'package:webview_windows/webview_windows.dart';
import 'package:window_manager/window_manager.dart';
import '../utils/utils.dart';

class WebView2Page extends StatefulWidget {
  const WebView2Page({super.key, required this.url, required this.code});

  final String url;
  final int code;

  @override
  State<WebView2Page> createState() => _WebView2State();
}

class _WebView2State extends State<WebView2Page> {
  final _controller = WebviewController();
  final List<StreamSubscription> _subscriptions = [];
  late String _url;
  final _log = Logger('_WebView2State');

  @override
  void initState() {
    super.initState();
    _url = widget.url;
    initPlatformState();
  }

  Future<void> initPlatformState() async {
    try {
      await _controller.initialize();
      _subscriptions
          .add(_controller.containsFullScreenElementChanged.listen((flag) {
        _log.fine('Contains fullscreen element: $flag');
        windowManager.setFullScreen(flag);
      }));
      _subscriptions.add(_controller.loadingState.listen((loadingState) {
        _log.fine("loadingState=$loadingState");
      }));
      _subscriptions
          .add(_controller.securityStateChanged.listen((securityState) {
        _log.fine("securityState=$securityState");
      }));
      _subscriptions.add(_controller.title.listen((title) {
        _log.fine("title=$title");
      }));
      _subscriptions.add(_controller.onLoadError.listen((error) {
        _log.fine("error=$error");
      }));
      _subscriptions.add(_controller.historyChanged.listen((history) {
        _log.fine("history=$history");
      }));
      await _controller.setBackgroundColor(Colors.transparent);
      await _controller.setPopupWindowPolicy(WebviewPopupWindowPolicy.deny);
      await _controller.loadUrl(_url);
      if (!mounted) return;
      setState(() {});
    } on PlatformException catch (e) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        showDialog(
            context: context,
            builder: (_) => AlertDialog(
                  title: const Text('Error'),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Code: ${e.code}'),
                      Text('Message: ${e.message}'),
                    ],
                  ),
                  actions: [
                    TextButton(
                      child: const Text('Continue'),
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                    )
                  ],
                ));
      });
    }
  }

  Widget _buildCompositeView() {
    if (!_controller.value.isInitialized) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    } else {
      return Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          children: [
            Expanded(
                child: Card(
                    color: Colors.transparent,
                    elevation: 0,
                    clipBehavior: Clip.antiAliasWithSaveLayer,
                    child: Stack(
                      children: [
                        Webview(_controller),
                        StreamBuilder<LoadingState>(
                            stream: _controller.loadingState,
                            builder: (context, snapshot) {
                              if (snapshot.hasData &&
                                  snapshot.data == LoadingState.loading) {
                                return const LinearProgressIndicator();
                              } else {
                                return const SizedBox();
                              }
                            }),
                      ],
                    ))),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: _buildFloatActionButton(context),
      appBar: AppBar(
        title: StreamBuilder<String>(
          stream: _controller.url,
          builder: (context, snapshot) {
            return _buildAppBatTitle(context, snapshot);
          },
        ),
        actions: _buildAppbarActions(context),
      ),
      body: Center(
        child: _buildCompositeView(),
      ),
    );
  }

  @override
  void dispose() {
    _dispose();
    super.dispose();
  }

  Future<void> _dispose() async{
    for (var s in _subscriptions) {
      await s.cancel();
    }
    await _controller.dispose();
  }

  Widget _buildAppBatTitle(BuildContext context, AsyncSnapshot snapshot) {
    if(snapshot.hasData){
      _url = snapshot.data;
      List<Widget> children = [];
      children.add(Chip(
        avatar: ClipOval(
          child: Icon(
              Icons.link,
            color: Theme.of(context).iconTheme.color
          ),
        ),
        label: Text(_url),
      ));
      return Row(
        children: children,
      );
    }else{
      return const SizedBox();
    }
  }

  List<Widget> _buildAppbarActions(BuildContext context){
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
            // _cefController.reload();
            _controller.loadUrl(_url);
          },
        ),
      ),
      Padding(
        padding:
        const EdgeInsets.only(top: 10, bottom: 10, left: 10, right: 10),
        child: GestureDetector(
          child: Icon(
              Icons.developer_mode,
            color: Theme.of(context).iconTheme.color,
          ),
          onTap: () {
            _controller.openDevTools();
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
            color: Theme.of(context).iconTheme.color,),
        ),
      ),
    ];
  }

    Widget _buildFloatActionButton(BuildContext context) {
    return FloatingActionButton.extended(
        onPressed: () async{
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
              color: Theme.of(context).iconTheme.color,),
          ],
        ));
  }

  Future<void> _saveCookies(BuildContext context) async{
    String? cookiesResult = await _controller.getCookies(_url);
    if (cookiesResult != null && cookiesResult.isNotEmpty) {
      RegExp exp = RegExp(r'\[(.*?)\]');
      Iterable<RegExpMatch> matches = exp.allMatches(cookiesResult);
      for (RegExpMatch match in matches) {
        String? cookieStr = match.group(1);
        _log.fine("cookieStr=$cookieStr");
        if (cookieStr != null && cookieStr.isNotEmpty) {
          await RequestManager().saveCookiesString(
              Uri.parse(widget.url), cookieStr);
        }
      }
    }
  }
}
