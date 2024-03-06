import 'package:MoeLoaderFlutter/ui/view_model_detail.dart';
import 'package:MoeLoaderFlutter/ui/webview2_page.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import '../utils/utils.dart';
import '../yamlhtmlparser/models.dart';
import '../yamlhtmlparser/yaml_validator.dart';
import 'common_function.dart';

final _log = Logger('url_list_dialog');

void showUrlList(BuildContext context, String href, CommonInfo? commonInfo) {
  DetailViewModel detailViewModel = DetailViewModel();
  showModalBottomSheet(
      context: context,
      builder: (context) {
        return SizedBox(
          height: 170,
          child: StreamBuilder<DetailState>(
              stream: detailViewModel.streamDetailController.stream,
              builder: (BuildContext context, AsyncSnapshot snapshot) {
                if (snapshot.connectionState != ConnectionState.active) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    detailViewModel.requestDetailData(href,
                        commonInfo: commonInfo);
                  }
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                }
                DetailState detailState = snapshot.data;
                if (detailState.loading) {
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                }
                if (detailState.error) {
                  if (detailState.code == ValidateResult.needChallenge ||
                      detailState.code == ValidateResult.needLogin) {
                    return Center(
                      child: ElevatedButton(
                        child: Text(tipsByCode(detailState.code)),
                        onPressed: () async {
                          bool? result = await Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) {
                              return WebView2Page(
                                url: href,
                                code: detailState.code,
                              );
                            }),
                          );
                          _log.fine("push result=${result}");
                          if (result != null && result) {
                            // _requestDetailData();
                          }
                        },
                      ),
                    );
                  }
                  return Center(
                    child: Text(detailState.errorMessage),
                  );
                } else {
                  YamlDetailPage yamlDetailPage = detailState.yamlDetailPage;
                  String? url = yamlDetailPage.url;
                  String? bigUrl = yamlDetailPage.commonInfo?.bigUrl;
                  String? rawUrl = yamlDetailPage.commonInfo?.rawUrl;
                  _log.fine("url=$url;rawUrl=$rawUrl;bigUrl=$bigUrl");
                  List<Widget> children = [];
                  if (isImageUrl(url) && url.isNotEmpty) {
                    children.add(buildDownloadItem(context, url, "当前预览图片($url)", () {
                      Navigator.of(context).pop();
                      detailViewModel.download(url, yamlDetailPage.commonInfo!.id ?? "");
                    }));
                  }
                  if (bigUrl != null && bigUrl.isNotEmpty) {
                    children.add(const Divider(
                      height: 10,
                    ));
                    children.add(buildDownloadItem(context, bigUrl, "大图($bigUrl)", () {
                      Navigator.of(context).pop();
                      detailViewModel.download(bigUrl, yamlDetailPage.commonInfo!.id ?? "");
                    }));
                  }
                  if (rawUrl != null && rawUrl.isNotEmpty) {
                    children.add(const Divider(
                      height: 10,
                    ));
                    children.add(buildDownloadItem(context, rawUrl, "原图($rawUrl)", () {
                      Navigator.of(context).pop();
                      detailViewModel.download(rawUrl, yamlDetailPage.commonInfo!.id ?? "");
                    }));
                  }
                  if (children.isEmpty) {
                    showToast("下载地址为空");
                  }
                  return SingleChildScrollView(
                    child: Column(
                      children: children,
                    ),
                  );
                }
              }),
        );
      });
}