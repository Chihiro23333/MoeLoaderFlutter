// import 'dart:io';
// import 'package:flutter/material.dart';
// import 'package:FlutterMoeLoaderDesktop/net/cef_controller.dart';
// import 'package:FlutterMoeLoaderDesktop/net/dio_http.dart';
// import 'package:webview_cef/webview_cef.dart';
//
// class WebVIewCef extends StatefulWidget {
//   const WebVIewCef({super.key, required this.url});
//
//   final String url;
//
//   @override
//   State<WebVIewCef> createState() => _WebVIewCefState();
// }
//
// class _WebVIewCefState extends State<WebVIewCef> {
//   final CefController _cefController = CefController();
//   String title = "";
//   Map allCookies = {};
//   String _url = "";
//
//   void _updateUrl(String url){
//     setState(() {
//       _url = url;
//     });
//   }
//
//   @override
//   void initState() {
//     super.initState();
//     initPlatformState();
//   }
//
//   // Platform messages are asynchronous, so we initialize in an async method.
//   Future<void> initPlatformState() async {
//     await _cefController.init(webViewEventsListener: WebviewEventsListener(
//       onTitleChanged: (t) {
//         setState(() {
//           title = t;
//         });
//       },
//       onUrlChanged: (url) {
//         _updateUrl(url);
//       },
//     ));
//     String url = widget.url;
//     _updateUrl(url);
//     await _cefController.loadUrl(url);
//     if (!mounted) return;
//     setState(() {});
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: _buildAppBatTitle(context),
//         elevation: 20,
//         actions: _buildAppbarActions(context),
//       ),
//       body: Column(
//         children: [
//           SizedBox(
//             height: 30,
//             child: Text(title),
//           ),
//           _cefController.isCefInit() ?
//           Expanded(child: _cefController.buildWebView())
//               :const Expanded(child: Center(child: Text("not init!!!"),))
//         ],
//       ),
//       floatingActionButton: _buildFloatActionButton(context),
//     );
//   }
//
//   Widget _buildAppBatTitle(BuildContext context) {
//     List<Widget> children = [];
//     children.add(Chip(
//       avatar: const ClipOval(
//         child: Icon(Icons.link),
//       ),
//       label: Text(_url),
//     ));
//     return Row(
//       children: children,
//     );
//   }
//
//   List<Widget> _buildAppbarActions(BuildContext context){
//     return [
//       Padding(
//         padding:
//         const EdgeInsets.only(top: 10, bottom: 10, left: 10, right: 10),
//         child: GestureDetector(
//           child: const Icon(Icons.refresh),
//           onTap: () {
//             // _cefController.reload();
//             _cefController.loadUrl(widget.url);
//           },
//         ),
//       ),
//       Padding(
//         padding:
//         const EdgeInsets.only(top: 10, bottom: 10, left: 10, right: 10),
//         child: GestureDetector(
//           child: const Icon(Icons.developer_mode),
//           onTap: () {
//             _cefController.openDevTools();
//           },
//         ),
//       ),
//       Padding(
//         padding:
//         const EdgeInsets.only(top: 10, bottom: 10, left: 10, right: 10),
//         child: GestureDetector(
//           onTap: () {
//             _cefController.goBack();
//           },
//           child: const Icon(Icons.arrow_back),
//         ),
//       ),
//       Padding(
//         padding:
//         const EdgeInsets.only(top: 10, bottom: 10, left: 10, right: 10),
//         child: GestureDetector(
//           onTap: () {
//             _cefController.goForward();
//           },
//           child: const Icon(Icons.arrow_forward),
//         ),
//       ),
//     ];
//   }
//
//   Widget _buildFloatActionButton(BuildContext context) {
//     return FloatingActionButton.extended(
//         onPressed: () {
//           _visitAllCookies();
//         },
//         extendedTextStyle: const TextStyle(fontWeight: FontWeight.bold),
//         label: const Row(
//           children: [
//             Text("已完成安全验证"),
//             SizedBox(
//               width: 10,
//             ),
//             Icon(Icons.check),
//           ],
//         ));
//   }
//
//   void _visitAllCookies() {
//     _cefController.visitAllCookies().then((value) {
//       allCookies = Map.of(value);
//       List<Cookie> cookies = [];
//       allCookies.forEach((key, value) {
//         print("allCookies:key=$key;value=$value\n");
//         if (key.toString() == ".alphacoders.com") {
//           var cookieMap = Map.of(value);
//           cookieMap.forEach((key, value) {
//             print("cookieMap:key=$key;value=$value\n");
//             cookies.add(Cookie(key, value));
//           });
//         }
//       });
//       print("cookies=${cookies.toString()}");
//       if (cookies.isNotEmpty) {
//         DioHttp.cookieJar.saveFromResponse(Uri.parse(widget.url), cookies);
//       }
//       Navigator.pop(context);
//     });
//   }
// }
