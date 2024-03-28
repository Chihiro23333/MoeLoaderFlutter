import 'package:MoeLoaderFlutter/ui/dialog/info_dialog.dart';
import 'package:MoeLoaderFlutter/ui/dialog/url_list_dialog.dart';
import 'package:extended_image/extended_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:logging/logging.dart';
import '../init.dart';
import '../net/download.dart';
import '../utils/common_function.dart';
import '../ui/viewmodel/view_model_home.dart';
import '../utils/const.dart';
import '../utils/sharedpreferences_utils.dart';
import '../utils/utils.dart';
import '../yamlhtmlparser/models.dart';

typedef ExceptionActionCallback = void Function(HomeState homeState);
typedef ItemClickCallback = void Function(YamlHomePageItem yamlHomePageItem);

class ImageMasonryGrid extends StatefulWidget {
  const ImageMasonryGrid({
    super.key,
    required this.list,
    this.headers,
    this.tagTapCallback,
    this.itemOnPressed,
  });

  final List<YamlHomePageItem> list;
  final Map<String, String>? headers;
  final ItemClickCallback? itemOnPressed;
  final TagTapCallback? tagTapCallback;

  @override
  State<StatefulWidget> createState() {
    return _ImageMasonryGridState();
  }
}

class _ImageMasonryGridState extends State<ImageMasonryGrid> {
  final _log = Logger("_MasonryGridState");

  @override
  Widget build(BuildContext context) {
    return _buildMasonryGrid(widget.list, widget.headers);
  }

  Widget _buildMasonryGrid(List<YamlHomePageItem> list, Map<String, String>? headers) {
    int crossAxisCount = Global.columnCount;
    return MasonryGridView.count(
        crossAxisCount: crossAxisCount,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        itemCount: list.length,
        itemBuilder: (BuildContext context, int index) {
          MediaQueryData queryData = MediaQuery.of(context);
          double screenWidth = queryData.size.width;
          YamlHomePageItem yamlHomePageItem = list[index];
          double width = screenWidth / crossAxisCount;
          double scale = 1 / Global.aspectRatio;
          double maxScale = 2;
          if (yamlHomePageItem.height > 0 && yamlHomePageItem.width > 0) {
            scale = yamlHomePageItem.height / yamlHomePageItem.width;
          }
          _log.fine("before scale=$scale");
          if (scale > maxScale) scale = maxScale;
          _log.fine("after scale=$scale");
          double height = width * scale;
          Color loadingBackgroundColor = const Color.fromARGB(30, 46, 176, 242);
          return Container(
            width: width,
            height: height,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(5),
              color: loadingBackgroundColor,
            ),
            child: _buildItem(context, yamlHomePageItem, index, crossAxisCount,
                width, height, headers),
          );
        });
  }

  Widget _buildItem(
      BuildContext context,
      YamlHomePageItem yamlHomePageItem,
      int index,
      int crossAxisCount,
      double width,
      double height,
      Map<String, String>? headers) {
    return Stack(
      fit: StackFit.expand,
      children: [
        Positioned.fill(
            child: GestureDetector(
                child: ExtendedImage.network(
                  borderRadius: const BorderRadius.all(Radius.circular(5)),
                  shape: BoxShape.rectangle,
                  headers: headers,
                  width: width,
                  height: height,
                  yamlHomePageItem.url,
                  fit: BoxFit.cover,
                ),
                onTap: () async {
                  var itemOnPressed = widget.itemOnPressed;
                  if (itemOnPressed != null) {
                    itemOnPressed(yamlHomePageItem);
                  }
                })),
        Positioned(
          right: 2,
          bottom: 3,
          child: Container(
            decoration: const BoxDecoration(
              borderRadius: BorderRadius.all(Radius.circular(20)),
              color: Colors.white70,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                IconButton(
                    onPressed: () async {
                      if (yamlHomePageItem.downloadState != DownloadTask.idle &&
                          yamlHomePageItem.downloadState !=
                              DownloadTask.error) {
                        return;
                      }
                      String? downloadFileSize = await getDownloadFileSize();
                      if (downloadFileSize == Const.choose ||
                          downloadFileSize == null) {
                        showUrlList(context, yamlHomePageItem.href,
                            yamlHomePageItem.commonInfo);
                      } else {
                        DownloadManager().addTask(DownloadTask(
                            yamlHomePageItem.href,
                            yamlHomePageItem.href,
                            getDownloadName(yamlHomePageItem.href,
                                yamlHomePageItem.commonInfo)));
                        showToast("已将图片加入下载列表");
                      }
                    },
                    icon: downloadStateIcon(
                        context, yamlHomePageItem.downloadState)),
                IconButton(
                    onPressed: () {
                      showInfoSheet(context, yamlHomePageItem.commonInfo,
                          onTagTap: (yamlTag) {
                        _log.fine(
                            "yamlTag:tag=${yamlTag.tag};desc=${yamlTag.desc}");
                        TagTapCallback? tagTapCallback = widget.tagTapCallback;
                        if (tagTapCallback != null) {
                          tagTapCallback(yamlTag);
                        }
                        Navigator.of(context).pop();
                      });
                    },
                    icon: const Icon(
                      Icons.info,
                      color: Colors.black,
                    ))
              ],
            ),
          ),
        ),
      ],
    );
  }
}
