import 'package:moeloaderflutter/init.dart';
import 'package:moeloaderflutter/model/home_page_item_entity.dart';
import 'package:moeloaderflutter/ui/dialog/info_dialog.dart';
import 'package:moeloaderflutter/ui/dialog/url_list_dialog.dart';
import 'package:moeloaderflutter/util/common_function.dart';
import 'package:moeloaderflutter/util/const.dart';
import 'package:moeloaderflutter/util/sharedpreferences_utils.dart';
import 'package:moeloaderflutter/util/utils.dart';
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
  final CancellationToken _cancelToken = CancellationToken();

  @override
  Widget build(BuildContext context) {
    return _buildMasonryGrid(widget.list, widget.headers);
  }

  @override
  void dispose() {
    _cancelToken.cancel();
    super.dispose();
  }

  Widget _buildMasonryGrid(
      List<HomePageItemEntity> list, Map<String, String>? headers) {
    int crossAxisCount = widget.columnCount;
    return MasonryGridView.builder(
        gridDelegate: SliverSimpleGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: crossAxisCount,
        ),
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        itemCount: list.length,
        itemBuilder: (BuildContext context, int index) {
          MediaQueryData queryData = MediaQuery.of(context);
          double screenWidth = queryData.size.width;
          HomePageItemEntity homePageItem = list[index];
          double width = screenWidth / crossAxisCount;
          double height;
          double scale = 1 / widget.aspectRatio;
          double maxScale = 2;
          if (homePageItem.height > 0 && homePageItem.width > 0) {
            scale = homePageItem.height / homePageItem.width;
          }
          _log.info("before scale=$scale");
          if (scale > maxScale) scale = maxScale;
          _log.info("after scale=$scale");
          height = width * scale;
          Color loadingBackgroundColor = const Color.fromARGB(30, 46, 176, 242);
          return Container(
            width: width,
            height: height,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(0),
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
    Map<String, String> newHeaders = {};
    if (headers != null) {
      newHeaders.addAll(headers);
    }
    if (Global.globalParser.imageLoadWithHost()) {
      Uri uri = Uri.parse(homePageItem.coverUrl);
      String host = uri.host;
      newHeaders["host"] = host;
    }
    return Stack(
      fit: StackFit.expand,
      children: [
        Positioned.fill(
            child: GestureDetector(
                child: ExtendedImage.network(
                  borderRadius: const BorderRadius.all(Radius.circular(5)),
                  shape: BoxShape.rectangle,
                  headers: newHeaders,
                  width: width,
                  height: height,
                  homePageItem.coverUrl,
                  fit: BoxFit.cover,
                  cancelToken: _cancelToken,
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
              borderRadius: BorderRadius.all(Radius.circular(30)),
              color: Colors.white70,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                SizedBox(
                  width: 40,
                  height: 35,
                  child: IconButton(
                    padding: EdgeInsets.zero,
                      iconSize: 20,
                      onPressed: () async {
                        // if (homePageItem.downloadState != DownloadTask.idle &&
                        //     homePageItem.downloadState != DownloadTask.error) {
                        //   return;
                        // }
                        String? downloadFileSize = await getDownloadFileSize();
                        if (downloadFileSize == Const.choose ||
                            downloadFileSize == null) {
                          showUrlList(context, homePageItem);
                        } else {
                          DownloadManager().addTask(DownloadTask(
                              homePageItem.href,
                              homePageItem.href,
                              await getDownloadName(
                                  homePageItem.href,
                                  homePageItem.id,
                                  homePageItem.author,
                                  homePageItem.tagList),
                              headers: headers));
                          showToast("已将图片加入下载列表");
                        }
                      },
                      icon:
                          downloadStateIcon(context, homePageItem.downloadState)),
                ),
                SizedBox(
                  width: 40,
                  height: 35,
                  child: IconButton(
                      iconSize: 20,
                      padding: EdgeInsets.zero,
                      onPressed: () {
                        showHomeInfoSheet(context, homePageItem,
                            onTagTap: (context, tag) {
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
                      )),
                )
              ],
            ),
          ),
        ),
      ],
    );
  }
}
