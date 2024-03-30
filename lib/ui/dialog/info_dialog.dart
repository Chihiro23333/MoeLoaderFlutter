import 'package:MoeLoaderFlutter/model/tag_entity.dart';
import 'package:MoeLoaderFlutter/util/common_function.dart';
import 'package:flutter/material.dart';

void showInfoSheet(
    BuildContext context,
    String id,
    String author,
    String characters,
    String fileSize,
    String dimensions,
    String source,
    List<TagEntity> tagList,
    {TagTapCallback? onTagTap}) {
  List<Widget> children = [];
  List<Widget> infoChildren = [];
  _fillInfoChip("Id：", id, infoChildren);
  _fillInfoChip("Author：", author, infoChildren);
  _fillInfoChip("Characters：", characters, infoChildren);
  _fillInfoChip("File Size：", fileSize, infoChildren);
  _fillInfoChip("Dimensions：", dimensions, infoChildren);
  _fillInfoChip("Source：", source, infoChildren);
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
      runSpacing: 4.0, // 纵轴（垂直）方向间距
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

List<Widget> _buildTags(BuildContext context, List<TagEntity> tagList,
    {TagTapCallback? onTagTap}) {
  List<Widget> result = [];
  for (var tag in tagList) {
    result.add(GestureDetector(
      child: Chip(
        avatar: const ClipOval(
          child: Icon(Icons.label),
        ),
        label: Text(tag.desc),
      ),
      onTap: () {
        if (onTagTap != null) {
          onTagTap(tag);
        }
      },
    ));
  }
  return result;
}
