import 'package:clipboard/clipboard.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:moeloaderflutter/util/common_function.dart';

Widget buildUrlWidget(BuildContext context, String url) {
  return Chip(
    avatar: ClipOval(
      child: Icon(
        Icons.label,
        color: Theme.of(context).iconTheme.color,
      ),
    ),
    label: Text(
      url,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    ),
    deleteButtonTooltipMessage: "复制",
    deleteIcon: ClipOval(
      clipBehavior: Clip.antiAlias,
      child: Icon(
        Icons.copy,
        color: Theme.of(context).iconTheme.color,
      ),
    ),
    onDeleted: () {
      FlutterClipboard.copy(url).then((value) => showToast("链接已复制"));
    },
  );
}
