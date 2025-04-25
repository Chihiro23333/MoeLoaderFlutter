import 'package:moeloaderflutter/model/detail_page_entity.dart';
import 'package:moeloaderflutter/model/home_page_item_entity.dart';
import 'package:moeloaderflutter/model/tag_entity.dart';
import 'package:moeloaderflutter/ui/common/common.dart';
import 'package:moeloaderflutter/util/common_function.dart';
import 'package:clipboard/clipboard.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../init.dart';
import '../../util/const.dart';

void showDetailInfoSheet(
    BuildContext context, DetailPageEntity detailPageEntity,
    {TagTapCallback? onTagTap}) {
  _showInfoSheet(
      context,
      detailPageEntity.url,
      detailPageEntity.id,
      detailPageEntity.author,
      detailPageEntity.authorId,
      "",
      "",
      detailPageEntity.dimensions,
      "",
      detailPageEntity.tagList,
      onTagTap: onTagTap);
}

void showHomeInfoSheet(BuildContext context, HomePageItemEntity homePageItem,
    {TagTapCallback? onTagTap}) {
  _showInfoSheet(
      context,
      homePageItem.href,
      homePageItem.id,
      homePageItem.author,
      homePageItem.authorId,
      homePageItem.characters,
      homePageItem.fileSize,
      homePageItem.dimensions,
      homePageItem.source,
      homePageItem.tagList,
      onTagTap: onTagTap);
}

void _showInfoSheet(
    BuildContext context,
    String url,
    String id,
    String author,
    String authorId,
    String characters,
    String fileSize,
    String dimensions,
    String source,
    List<TagEntity> tagList,
    {TagTapCallback? onTagTap}) {
  List<Widget> children = [];
  List<Widget> infoChildren = [];
  _fillInfoChip(context, "Id：", id, infoChildren);
  _fillInfoChip(context, "Author：", author, infoChildren,
      infoId: authorId, tagType: Const.tagTypeAuthor, onTagTap: onTagTap);
  _fillInfoChip(context, "Characters：", characters, infoChildren);
  _fillInfoChip(context, "File Size：", fileSize, infoChildren);
  _fillInfoChip(context, "Dimensions：", dimensions, infoChildren);
  _fillInfoChip(context, "Source：", source, infoChildren);
  if (url.isNotEmpty) {
    children.add(const Padding(
      padding: EdgeInsets.only(top: 10, bottom: 10),
      child: Text(
        "图片地址：",
        style: TextStyle(fontWeight: FontWeight.bold),
      ),
    ));
    children.add(Wrap(
      spacing: 8.0, // 主轴(水平)方向间距
      runSpacing: 8.0, // 纵轴（垂直）方向间距
      children: [buildUrlWidget(context, url)],
    ));
  }
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
      runSpacing: 8.0, // 纵轴（垂直）方向间距
      children: infoChildren,
    ));
  }
  if (tagList.isNotEmpty) {
    children.add(const Padding(
      padding: EdgeInsets.only(top: 10, bottom: 10),
      child: Text(
        "关联标签：",
        style: TextStyle(fontWeight: FontWeight.bold),
      ),
    ));
    children.add(Wrap(
      spacing: 8.0, // 主轴(水平)方向间距
      runSpacing: 8.0, // 纵轴（垂直）方向间距
      children: _buildTags(context, tagList, onTagTap: onTagTap),
    ));
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

void _fillInfoChip(
    BuildContext context, String prefix, String info, List<Widget> infoChildren,
    {TagTapCallback? onTagTap,
    String? infoId,
    String tagType = Const.tagTypeDefault}) {
  BorderSide? borderSide;
  if (onTagTap != null) {
    borderSide = BorderSide(color: Global.defaultColor, width: 2);
  } else {
    borderSide = null;
  }
  if (info.isNotEmpty) {
    infoChildren.add(GestureDetector(
      child: Chip(
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        visualDensity: VisualDensity.compact,
        side: borderSide,
        // avatar: ClipOval(
        //   child: Icon(
        //     Icons.tag,
        //     color: Theme.of(context).iconTheme.color,
        //   ),
        // ),
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
        deleteButtonTooltipMessage: "复制",
        deleteIcon: ClipOval(
          clipBehavior: Clip.antiAlias,
          child: Icon(
            Icons.copy,
            color: Theme.of(context).iconTheme.color,
          ),
        ),
        onDeleted: () {
          FlutterClipboard.copy(info).then((value) => showToast("文字已复制"));
        },
      ),
      onTap: () {
        if (onTagTap != null) {
          TagEntity tagEntity = TagEntity();
          tagEntity.tag = infoId ?? "";
          tagEntity.desc = info;
          tagEntity.type = tagType;
          onTagTap(context, tagEntity);
        }
      },
    ));
  }
}

List<Widget> _buildTags(BuildContext context, List<TagEntity> tagList,
    {TagTapCallback? onTagTap}) {
  BorderSide? borderSide;
  if (onTagTap != null) {
    borderSide = BorderSide(color: Global.defaultColor, width: 1);
  } else {
    borderSide = null;
  }
  List<Widget> result = [];
  for (var tag in tagList) {
    result.add(
      GestureDetector(
        child: Chip(
          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          visualDensity: VisualDensity.compact,
          side: borderSide,
          // avatar: ClipOval(
          //   child: Icon(
          //     Icons.label,
          //     color: Theme.of(context).iconTheme.color,
          //   ),
          // ),
          label: Text(
            tag.desc
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
            FlutterClipboard.copy(tag.desc).then((value) => showToast("文字已复制"));
          },
        ),
        onTap: () {
          if (onTagTap != null) {
            onTagTap(context, tag);
          }
        },
      ),
    );
  }
  return result;
}
