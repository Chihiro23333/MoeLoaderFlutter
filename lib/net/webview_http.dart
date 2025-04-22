// Future<String> fetchWebContent(String url) async {
//   final headlessWebView = HeadlessInAppWebView(
//     initialUrlRequest: URLRequest(url: WebUri(url)),
//     onProgressChanged: (controller, progress) async {
//       print('progress: $progress');
//     },
//     onLoadStop: (controller, url) async {
//       final content = await controller.evaluateJavascript(
//         source: "document.documentElement.outerHTML;",
//       );
//       print('网页内容: $content');
//       // 这里可以返回或处理内容
//     },
//   );
//   await headlessWebView.run();
//   return ''; // 实际应该通过回调或Future返回内容
// }
//
