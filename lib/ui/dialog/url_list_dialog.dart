import 'package:flutter/cupertino.dart';
import 'package:moeloaderflutter/init.dart';
import 'package:moeloaderflutter/model/detail_page_entity.dart';
import 'package:moeloaderflutter/model/home_page_item_entity.dart';
import 'package:moeloaderflutter/ui/viewmodel/view_model_detail.dart';
import 'package:moeloaderflutter/util/common_function.dart';
import 'package:moeloaderflutter/util/utils.dart';
import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import 'package:to_json/validator.dart';

final _log = Logger('url_list_dialog');

void showUrlList(BuildContext context, HomePageItemEntity homePageItem) {
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
                      detailViewModel.requestDetailData(homePageItem.href,
                          homePageItem: homePageItem);
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
                              CupertinoPageRoute(builder: (context) {
                                return Global.multiPlatform.navigateToWebView(
                                  context, Global.globalParser.validateUrl(), detailState.code,
                                );
                              }),
                            );
                            _log.fine("push result=${result}");
                            if (result != null && result) {
                              detailViewModel.requestDetailData(homePageItem.href,
                                  homePageItem: homePageItem);
                            }
                          },
                        ),
                      );
                    }
                    return Center(
                      child: Text(detailState.errorMessage),
                    );
                  } else {
                    DetailPageEntity detailPageEntity = detailState.detailPageEntity;
                    String? url = detailPageEntity.url;
                    String? bigUrl = detailPageEntity.bigUrl;
                    String? rawUrl = detailPageEntity.rawUrl;
                    _log.fine("url=$url;rawUrl=$rawUrl;bigUrl=$bigUrl");
                    List<Widget> children = [];
                    if (isImageUrl(url) && url.isNotEmpty) {
                      children
                          .add(buildDownloadItem(context, url, "预览图($url)", () {
                        detailViewModel.download(
                            homePageItem.href, url, detailPageEntity.id, detailPageEntity.author, detailPageEntity.tagList, headers: detailState.headers);
                        showToast("已将图片加入下载列表");
                        // Navigator.of(context).pop();
                      }));
                    }
                    if (bigUrl.isNotEmpty) {
                      children.add(const Divider(
                        height: 10,
                      ));
                      children.add(
                          buildDownloadItem(context, bigUrl, "大图($bigUrl)", () {
                        detailViewModel.download(
                            homePageItem.href, bigUrl, detailPageEntity.id,  detailPageEntity.author, detailPageEntity.tagList, headers: detailState.headers);
                        showToast("已将图片加入下载列表");
                        // Navigator.of(context).pop();
                      }));
                    }
                    if (rawUrl.isNotEmpty) {
                      children.add(const Divider(
                        height: 10,
                      ));
                      children.add(
                          buildDownloadItem(context, rawUrl, "原图($rawUrl)", () {
                        detailViewModel.download(
                            homePageItem.href, rawUrl, detailPageEntity.id,  detailPageEntity.author, detailPageEntity.tagList, headers: detailState.headers);
                        showToast("已将图片加入下载列表");
                        // Navigator.of(context).pop();
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
                }));
      });
}
