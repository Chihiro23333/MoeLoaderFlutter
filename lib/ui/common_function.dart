import 'package:MoeLoaderFlutter/net/download.dart';
import 'package:bot_toast/bot_toast.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:MoeLoaderFlutter/yamlhtmlparser/models.dart';

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

void showDownloadTask(BuildContext context) {
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
                    if(downloadState == DownloadTask.downloading){
                      int count = downloadTask.count;
                      int total = downloadTask.total;
                      print("count=$count;total=$total");
                      double progress = 0;
                      if(total > 0){
                        progress = count/total;
                      }
                      subtitle = LinearProgressIndicator(value: progress);
                    }else if(downloadState == DownloadTask.complete){
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
                  }, separatorBuilder: (BuildContext context, int index) {
                    return const Divider(height: 10);
              },);
            } else {
              return const CircularProgressIndicator();
            }
          },
        );
      });
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
