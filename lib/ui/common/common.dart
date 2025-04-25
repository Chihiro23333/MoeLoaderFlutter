import 'package:clipboard/clipboard.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:moeloaderflutter/init.dart';
import 'package:moeloaderflutter/util/common_function.dart';
import 'package:to_json/validator.dart';

Widget buildUrlWidget(BuildContext context, String url) {
  return Chip(
    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    visualDensity: VisualDensity.compact,
    avatar: ClipOval(
      child: Icon(
        Icons.label,
        color: Theme.of(context).iconTheme.color,
      ),
    ),
    label: GestureDetector(
      child: Text(
        url,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      onTap: () {
        Navigator.push(
          context,
          CupertinoPageRoute(builder: (context) {
            return Global.multiPlatform.navigateToWebView(
              context,
              url,
              ValidateResult.success,
            );
          }),
        );
      },
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
