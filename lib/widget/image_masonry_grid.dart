import 'package:MoeLoaderFlutter/model/home_page_item_entity.dart';
import 'package:MoeLoaderFlutter/ui/dialog/info_dialog.dart';
import 'package:MoeLoaderFlutter/ui/dialog/url_list_dialog.dart';
import 'package:MoeLoaderFlutter/util/common_function.dart';
import 'package:MoeLoaderFlutter/util/const.dart';
import 'package:MoeLoaderFlutter/util/sharedpreferences_utils.dart';
import 'package:MoeLoaderFlutter/util/utils.dart';
import 'package:extended_image/extended_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:logging/logging.dart';
import '../net/download.dart';
import '../ui/viewmodel/view_model_home.dart';

typedef ExceptionActionCallback = void Function(HomeState homeState);
typedef ItemClickCallback = void Function(HomePageItemEntity yamlHomePageItem);

class ImageMasonryGrid extends StatefulWidget {
  const ImageMasonryGrid({
    super.key,
    required this.list,
    required this.columnCount,
    required this.aspectRatio,
    this.headers,
    this.tagTapCallback,
    this.itemOnPressed,
  });

  final List<HomePageItemEntity> list;
  final Map<String, String>? headers;
  final ItemClickCallback? itemOnPressed;
  final TagTapCallback? tagTapCallback;
  final int columnCount;
  final double aspectRatio;

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

  Widget _buildMasonryGrid(
      List<HomePageItemEntity> list, Map<String, String>? headers) {
    int crossAxisCount = widget.columnCount;
    return MasonryGridView.count(
        crossAxisCount: crossAxisCount,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        itemCount: list.length,
        itemBuilder: (BuildContext context, int index) {
          MediaQueryData queryData = MediaQuery.of(context);
          double screenWidth = queryData.size.width;
          HomePageItemEntity homePageItem = list[index];
          double width = screenWidth / crossAxisCount;
          double scale = 1 / widget.aspectRatio;
          double maxScale = 2;
          if (homePageItem.height > 0 && homePageItem.width > 0) {
            scale = homePageItem.height / homePageItem.width;
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
            child: _buildItem(context, homePageItem, index, crossAxisCount,
                width, height, headers),
          );
        });
  }

  Widget _buildItem(
      BuildContext context,
      HomePageItemEntity homePageItem,
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
                  homePageItem.coverUrl,
                  fit: BoxFit.cover,
                ),
                onTap: () async {
                  var itemOnPressed = widget.itemOnPressed;
                  if (itemOnPressed != null) {
                    itemOnPressed(homePageItem);
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
                      if (homePageItem.downloadState != DownloadTask.idle &&
                          homePageItem.downloadState != DownloadTask.error) {
                        return;
                      }
                      String? downloadFileSize = await getDownloadFileSize();
                      if (downloadFileSize == Const.choose ||
                          downloadFileSize == null) {
                        showUrlList(context, homePageItem);
                      } else {
                        DownloadManager().addTask(DownloadTask(
                            homePageItem.href,
                            homePageItem.href,
                            getDownloadName(homePageItem.href, homePageItem.id),
                            headers: headers));
                        showToast("已将图片加入下载列表");
                      }
                    },
                    icon:
                        downloadStateIcon(context, homePageItem.downloadState)),
                IconButton(
                    onPressed: () {
                      showInfoSheet(
                          context,
                          homePageItem.id,
                          homePageItem.author,
                          homePageItem.authorId,
                          homePageItem.characters,
                          homePageItem.fileSize,
                          homePageItem.dimensions,
                          homePageItem.source,
                          homePageItem.tagList, onTagTap: (context, tag) {
                        Navigator.of(context).pop();
                        _log.fine("yamlTag:tag=${tag.tag};desc=${tag.desc}");
                        TagTapCallback? tagTapCallback = widget.tagTapCallback;
                        if (tagTapCallback != null) {
                          tagTapCallback(context, tag);
                        }
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
