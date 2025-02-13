import 'package:moeloaderflutter/model/tag_entity.dart';
import 'package:moeloaderflutter/net/download.dart';
import 'package:bot_toast/bot_toast.dart';
import 'package:clipboard/clipboard.dart';
import 'package:flutter/material.dart';
import '../init.dart';

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

typedef TagTapCallback = void Function(BuildContext context, TagEntity tagEntity);