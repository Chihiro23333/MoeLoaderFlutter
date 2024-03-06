import 'package:bot_toast/bot_toast.dart';
import 'package:clipboard/clipboard.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

CancelFunc? cancel;

void showToast(String toastString) {
  if (cancel != null) {
    cancel!();
  }
  cancel = BotToast.showText(text: toastString);
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