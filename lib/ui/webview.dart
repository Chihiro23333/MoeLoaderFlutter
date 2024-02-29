// import 'package:flutter/material.dart';
// import 'package:webview_windows/webview_windows.dart';
// import '../net/request_manager.dart';
//
// class WebViewPage extends StatefulWidget {
//
//   WebViewPage({super.key ,required this.url});
//
//   String url;
//
//   @override
//   State<StatefulWidget> createState() => _WebViewState();
//
// }
//
// class _WebViewState extends State<WebViewPage> {
//
//   final _controller = RequestManager().challengeWebViewController;
//
//   @override
//   void initState() {
//     super.initState();
//     loadUrl();
//   }
//
//   @override
//   void dispose() {
//     RequestManager().cancelChallenge();
//     super.dispose();
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text("浏览器"),
//         elevation: 20,
//         actions: [
//           Padding(
//             padding: const EdgeInsets.only(
//                 top: 10, bottom: 10, left: 10, right: 10),
//             child: GestureDetector(
//               child: const Icon(Icons.refresh),
//               onTap: () {
//                 _controller.reload();
//               },
//             ),
//           ),
//           Padding(
//             padding: const EdgeInsets.only(
//                 top: 10, bottom: 10, left: 10, right: 10),
//             child: GestureDetector(
//               child: const Icon(Icons.settings),
//               onTap: () {
//                 _controller.openDevTools();
//               },
//             ),
//           ),
//         ],
//       ),
//       body: Webview(
//         _controller,
//       ),
//     );
//   }
//
//   void loadUrl() {
//     RequestManager().challenge(widget.url, RequestManager.fromChallengePage);
//   }
// }