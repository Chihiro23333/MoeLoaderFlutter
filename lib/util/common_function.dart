import 'package:moeloaderflutter/model/tag_entity.dart';
import 'package:moeloaderflutter/net/download.dart';
import 'package:bot_toast/bot_toast.dart';
import 'package:clipboard/clipboard.dart';
import 'package:flutter/material.dart';
import '../init.dart';
import '../ui/page/download_page.dart';
import 'package:badges/badges.dart' as badges;

CancelFunc? cancel;

void showToast(String toastString) {
  if (cancel != null) {
    cancel!();
  }
  cancel = BotToast.showText(text: toastString);
}

Widget downloadStateIcon(BuildContext context, int downloadState) {
  Widget icon;
  switch (downloadState) {
    case DownloadTask.downloading:
      icon = SizedBox(
        width: 20,
        height: 20,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          color: Global.defaultColor,
        ),
      );
      break;
    case DownloadTask.complete:
      icon = Icon(
        Icons.file_download_done,
        color: Global.defaultColor,
      );
      break;
    case DownloadTask.error:
      icon = const Icon(
        Icons.restart_alt,
        color: Colors.red,
      );
      break;
    case DownloadTask.waiting:
      icon = Icon(
        Icons.watch_later_outlined,
        color: Global.defaultColor,
      );
      break;
    case DownloadTask.idle:
    default:
      icon = const Icon(
        Icons.download,
        color: Colors.black,
      );
  }
  return icon;
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

typedef TagTapCallback = void Function(
    BuildContext context, TagEntity tagEntity);

EdgeInsets appBarActionPadding() {
  return const EdgeInsets.fromLTRB(0, 0, 50, 0);
}

void showDownloadOverlay(BuildContext context) {
  // 创建OverlayEntry
  OverlayEntry overlayEntry = OverlayEntry(
      builder: (context) => StreamBuilder<DownloadState>(
          initialData: DownloadManager().curState(),
          stream: DownloadManager().downloadStream(),
          builder: (BuildContext context, AsyncSnapshot snapshot) {
            bool hasData = snapshot.hasData;
            int count = 0;
            if (hasData) {
              DownloadState downloadState = snapshot.data;
              List<DownloadTask> list = downloadState.tasks;
              for (DownloadTask downloadTask in list) {
                if (downloadTask.downloadState <= DownloadTask.downloading) {
                  count++;
                }
              }
            }
            return SafeArea(
                child: Stack(
              children: [
                Positioned(
                    right: 10,
                    top: 5,
                    child: badges.Badge(
                      showBadge: count > 0,
                      badgeContent: Text("$count",
                          style: const TextStyle(
                              color: Colors.white, fontSize: 12)),
                      position: badges.BadgePosition.topEnd(top: 0, end: 0),
                      child: IconButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) {
                                return const DownloadPage();
                              }),
                            );
                          },
                          icon: const Icon(Icons.download)),
                    ))
              ],
            ));
          }));
  Overlay.of(context).insert(overlayEntry);
}
