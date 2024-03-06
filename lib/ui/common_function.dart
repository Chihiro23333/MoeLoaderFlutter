import 'package:MoeLoaderFlutter/net/download.dart';
import 'package:MoeLoaderFlutter/ui/view_model_detail.dart';
import 'package:MoeLoaderFlutter/ui/webview2_page.dart';
import 'package:bot_toast/bot_toast.dart';
import 'package:clipboard/clipboard.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:MoeLoaderFlutter/yamlhtmlparser/models.dart';
import 'package:logging/logging.dart';

import '../utils/utils.dart';
import '../yamlhtmlparser/yaml_validator.dart';

final _log = Logger('common_function');

typedef TagTapCallback = void Function(YamlTag yamlTag);

void showInfoSheet(BuildContext context, CommonInfo? commonInfo,
    {TagTapCallback? onTagTap}) {
  List<Widget> children = [];
  List<Widget> infoChildren = [];
  if (commonInfo != null) {
    _fillInfoChip("Id：", commonInfo.id, infoChildren);
    _fillInfoChip("Author：", commonInfo.author, infoChildren);
    _fillInfoChip("Characters：", commonInfo.characters, infoChildren);
    _fillInfoChip("File Size：", commonInfo.fileSize, infoChildren);
    _fillInfoChip("Dimensions：", commonInfo.dimensions, infoChildren);
    _fillInfoChip("Source：", commonInfo.source, infoChildren);
    if (infoChildren.isNotEmpty) {
      children.add(const Padding(
        padding: EdgeInsets.only(top: 10, bottom: 10),
        child: Text(
          "图片详情：",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ));
      children.add(Wrap(
        spacing: 8.0, // 主轴(水平)方向间距
        runSpacing: 4.0, // 纵轴（垂直）方向间距
        children: infoChildren,
      ));
    }
    if (commonInfo.tags.isNotEmpty) {
      children.add(const Padding(
        padding: EdgeInsets.only(top: 10, bottom: 10),
        child: Text(
          "关联标签：",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ));
      children.add(Wrap(
        spacing: 8.0, // 主轴(水平)方向间距
        runSpacing: 4.0, // 纵轴（垂直）方向间距
        children: _buildTags(context, commonInfo, onTagTap: onTagTap),
      ));
    }
  }
  if (children.isEmpty) {
    showToast("未获取到图片相关信息");
    return;
  }
  showModalBottomSheet(
      context: context,
      builder: (context) {
        return SingleChildScrollView(
          child: Padding(
            padding:
                const EdgeInsets.only(left: 10, right: 10, top: 10, bottom: 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: children,
            ),
          ),
        );
      });
}

CancelFunc? cancel;

void showToast(String toastString) {
  if (cancel != null) {
    cancel!();
  }
  cancel = BotToast.showText(text: toastString);
}

void showDownloadTasks(BuildContext context) {
  showModalBottomSheet(
      context: context,
      builder: (context) {
        return StreamBuilder<DownloadState>(
          initialData: DownloadManager().curState(),
          stream: DownloadManager().downloadStream(),
          builder: (BuildContext context, AsyncSnapshot snapshot) {
            bool hasData = snapshot.hasData;
            if (hasData) {
              DownloadState downloadState = snapshot.data;
              List<DownloadTask> list = downloadState.tasks;
              return ListView.separated(
                itemCount: list.length,
                itemBuilder: (BuildContext context, int index) {
                  DownloadTask downloadTask = list[index];
                  int downloadState = downloadTask.downloadState;
                  Widget subtitle = const Text("等待下载");
                  if (downloadState == DownloadTask.downloading) {
                    int count = downloadTask.count;
                    int total = downloadTask.total;
                    print("count=$count;total=$total");
                    double progress = 0;
                    if (total > 0) {
                      progress = count / total;
                    }
                    subtitle = LinearProgressIndicator(value: progress);
                  } else if (downloadState == DownloadTask.complete) {
                    subtitle = const Text("已下载");
                  }
                  return ListTile(
                    leading: Icon(
                      Icons.image,
                      color: Theme.of(context).iconTheme.color,
                    ),
                    title: Text(downloadTask.name),
                    subtitle: subtitle,
                  );
                },
                separatorBuilder: (BuildContext context, int index) {
                  return const Divider(height: 10);
                },
              );
            } else {
              return const CircularProgressIndicator();
            }
          },
        );
      });
}

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

Widget buildDownloadItem(
    BuildContext context, String url, String desc, VoidCallback? callback) {
  return ListTile(
    leading:
        Icon(Icons.image_outlined, color: Theme.of(context).iconTheme.color),
    trailing: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          icon: Icon(Icons.copy, color: Theme.of(context).iconTheme.color),
          onPressed: () {
            FlutterClipboard.copy(url).then((value) => showToast("链接已复制"));
          },
        ),
        IconButton(
          icon: Icon(Icons.download, color: Theme.of(context).iconTheme.color),
          onPressed: callback,
        )
      ],
    ),
    title: Text(
      desc,
      overflow: TextOverflow.ellipsis,
      softWrap: false,
    ),
  );
}

void _fillInfoChip(String prefix, String info, List<Widget> infoChildren) {
  if (info.isNotEmpty) {
    infoChildren.add(Chip(
      avatar: const ClipOval(
        child: Icon(Icons.tag),
      ),
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            prefix,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          Text(info)
        ],
      ),
    ));
  }
}

List<Widget> _buildTags(BuildContext context, CommonInfo commonInfo,
    {TagTapCallback? onTagTap}) {
  List<Widget> result = [];
  for (var yamlTag in commonInfo.tags) {
    result.add(GestureDetector(
      child: Chip(
        avatar: const ClipOval(
          child: Icon(Icons.label),
        ),
        label: Text(yamlTag.desc),
      ),
      onTap: () {
        if (onTagTap != null) {
          onTagTap(yamlTag);
        }
      },
    ));
  }
  return result;
}
