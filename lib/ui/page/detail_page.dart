import 'package:moeloaderflutter/init.dart';
import 'package:moeloaderflutter/model/detail_page_entity.dart';
import 'package:moeloaderflutter/model/home_page_item_entity.dart';
import 'package:moeloaderflutter/ui/dialog/info_dialog.dart';
import 'package:moeloaderflutter/ui/page/download_page.dart';
import 'package:moeloaderflutter/ui/page/home_page.dart';
import 'package:moeloaderflutter/util/common_function.dart';
import 'package:moeloaderflutter/util/utils.dart';
import 'package:clipboard/clipboard.dart';
import 'package:extended_image/extended_image.dart';
import 'package:flutter/material.dart';
import 'package:moeloaderflutter/ui/viewmodel/view_model_detail.dart';
import 'package:logging/logging.dart';
import 'package:to_json/validator.dart';
import '../../widget/keep_alive_wrapper.dart';

class DetailPage extends StatefulWidget {
  const DetailPage({super.key, required this.homePageItem, required this.href});

  final HomePageItemEntity? homePageItem;
  final String href;

  @override
  State<StatefulWidget> createState() => _DetailState();
}

class _DetailState extends State<DetailPage> {
  final _log = Logger('_DetailState');

  final DetailViewModel _detailViewModel = DetailViewModel();
  DetailPageEntity? _detailPageEntity;
  int _index = 0;
  final PageController _pageController = PageController();
  final String _searchPageName = "searchPage";

  void _updateIndex(int page) {
    setState(() {
      _index = page;
    });
  }

  void _requestDetailData() {
    print("widget.href=${widget.href}");
    _detailViewModel.requestDetailData(widget.href,
        homePageItem: widget.homePageItem);
  }

  @override
  void initState() {
    super.initState();
    _requestDetailData();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DetailState>(
        stream: _detailViewModel.streamDetailController.stream,
        builder: (BuildContext context, AsyncSnapshot snapshot) {
          if (snapshot.connectionState != ConnectionState.active) {
            return const SizedBox();
          }
          return Scaffold(
            appBar: _buildAppBar(context, snapshot),
            body: _buildBody(context, snapshot),
            floatingActionButton: _buildFloatActionButton(context, snapshot),
          );
        });
  }

  AppBar _buildAppBar(BuildContext context, AsyncSnapshot snapshot) {
    return AppBar(
      title: _buildAppBatTitle(context),
      iconTheme: Theme.of(context).iconTheme,
      elevation: 10,
      actions: <Widget>[
        // _buildCopyAction(context),
        // _buildDownloadAction(context),
        _buildInfoAction(context, snapshot.data)
      ],
    );
  }

  Widget _buildBody(BuildContext context, AsyncSnapshot snapshot) {
    if (snapshot.connectionState == ConnectionState.active) {
      DetailState detailState = snapshot.data;
      if (detailState.loading) {
        return const Center(
          child: CircularProgressIndicator(),
        );
      }
      if (detailState.error) {
        if (detailState.code == ValidateResult.needChallenge ||
            detailState.code == ValidateResult.needLogin) {
          return Center(
            child: ElevatedButton(
              child: Text(tipsByCode(detailState.code)),
              onPressed: () async {
                bool? result = await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) {
                    return Global.multiPlatform.navigateToWebView(
                      context, widget.href, detailState.code);
                  }),
                );
                _log.fine("push result=${result}");
                if (result != null && result) {
                  _requestDetailData();
                }
              },
            ),
          );
        }
        return Center(
          child: Text(detailState.errorMessage),
        );
      }
      _updateCommonInfo(detailState.detailPageEntity);
      _detailPageEntity = detailState.detailPageEntity;
      List<String> urlList = [];
      urlList.add(_detailPageEntity!.url);
      _log.fine("urlList=$urlList");
      // if (_detailPageEntity!.preview.isNotEmpty) {
      //   urlList.addAll(_detailPageEntity!.preview.split(","));
      // }
      return Stack(
        alignment: Alignment.center,
        children: [
          _buildPageView(context, urlList, detailState.headers),
          _buildNext(context, urlList.length),
          _buildPre(context, urlList.length),
          // _buildDownloadProgress(context, detailState)
        ],
      );
    } else {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }
  }

  _buildFloatActionButton(BuildContext context, AsyncSnapshot snapshot) {
    DetailState detailState = snapshot.data;
    bool loading = detailState.loading;
    bool downloading = detailState.downloading;
    int count = detailState.count;
    int total = detailState.total;
    double? progress = 0;
    if (total != 0) {
      progress = count / total;
    }
    debugPrint("progress=$progress");
    Widget child;
    if (downloading) {
      child = Padding(
        padding: const EdgeInsets.only(top: 0, bottom: 0, left: 0, right: 0),
        child: CircularProgressIndicator(
          value: progress,
          backgroundColor: Colors.white,
          color: Theme.of(context).iconTheme.color,
        ),
      );
    } else {
      child = Padding(
        padding: const EdgeInsets.only(top: 0, bottom: 0, left: 0, right: 0),
        child: Icon(
          Icons.download,
          color: Theme.of(context).iconTheme.color,
        ),
      );
    }
    return FloatingActionButton(
        onPressed: () {
          if (loading) {
            showToast("数据还没准备好");
            return;
          }
          if (downloading) {
            showToast("已经有图片正在下载中，请等待");
            return;
          }
          if (_detailPageEntity != null) {
            String url = _detailPageEntity!.url;
            String bigUrl = _detailPageEntity!.bigUrl;
            String rawUrl = _detailPageEntity!.rawUrl;
            String id = widget.homePageItem?.id ?? "";
            _log.fine("url=$url;rawUrl=$rawUrl;bigUrl=$bigUrl");
            List<Widget> children = [];
            if (isImageUrl(url) && url.isNotEmpty) {
              children.add(buildDownloadItem(context, url, "当前预览图片($url)", () {
                Navigator.of(context).pop();
                _detailViewModel.download(widget.href, url, id,
                    headers: detailState.headers);
              }));
            }
            if (bigUrl.isNotEmpty) {
              children.add(const Divider(
                height: 10,
              ));
              children
                  .add(buildDownloadItem(context, bigUrl, "大图($bigUrl)", () {
                Navigator.of(context).pop();
                _detailViewModel.download(widget.href, bigUrl, id,
                    headers: detailState.headers);
              }));
            }
            if (rawUrl.isNotEmpty) {
              children.add(const Divider(
                height: 10,
              ));
              children
                  .add(buildDownloadItem(context, rawUrl, "原图($rawUrl)", () {
                Navigator.of(context).pop();
                _detailViewModel.download(widget.href, rawUrl, id,
                    headers: detailState.headers);
              }));
            }
            if (children.isEmpty) {
              showToast("下载地址为空");
              return;
            }
            showModalBottomSheet(
                context: context,
                builder: (context) {
                  return SingleChildScrollView(
                    child: Column(
                      children: children,
                    ),
                  );
                });
          } else {
            showToast("数据还没准备好");
          }
        },
        child: child);
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
            icon:
                Icon(Icons.download, color: Theme.of(context).iconTheme.color),
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

  Widget _buildAppBatTitle(BuildContext context) {
    List<Widget> children = [];
    children.add(const Text(
      "图片详情",
      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
    ));
    return FittedBox(
      child: Row(
        children: children,
      ),
    );
  }

  //处理部分网页没有详情页的情况
  void _updateCommonInfo(DetailPageEntity detailPageEntity) {}

  Widget _buildPageView(BuildContext context, List<String> urlList,
      Map<String, String>? headers) {
    var children = <Widget>[];
    for (int i = 0; i < urlList.length; ++i) {
      String url = urlList[i];
      //只需要用 KeepAliveWrapper 包装一下即可
      children.add(KeepAliveWrapper(
        child: ExtendedImage.network(url,
            headers: headers,
            fit: BoxFit.contain,
            mode: ExtendedImageMode.gesture,
            loadStateChanged: (ExtendedImageState state) {
          switch (state.extendedImageLoadState) {
            case LoadState.loading:
              double progress = 0;
              var loadingProgress = state.loadingProgress;
              print("loadingProgress=$loadingProgress");
              if (null == loadingProgress) {
                progress = 1;
              } else {
                var cumulativeBytesLoaded =
                    loadingProgress.cumulativeBytesLoaded;
                var expectedTotalBytes = loadingProgress.expectedTotalBytes;
                print(
                    "expectedTotalBytes=$expectedTotalBytes；cumulativeBytesLoaded=$cumulativeBytesLoaded");
                if (null == expectedTotalBytes || expectedTotalBytes == 0) {
                  progress = 1;
                } else {
                  progress = cumulativeBytesLoaded * 1.0 / expectedTotalBytes;
                }
              }
              print("progress=$progress");
              return const Center(
                child: CircularProgressIndicator(),
              );
            case LoadState.completed:
            case LoadState.failed:
              return null;
          }
        }),
      ));
    }
    print("children.length=${children.length}");
    return PageView(
        onPageChanged: (page) {
          _updateIndex(page);
        },
        controller: _pageController,
        children: children);
  }

  Widget _buildNext(BuildContext context, int pageSize) {
    if (_index >= pageSize - 1) {
      return const SizedBox();
    } else {
      return Positioned(
          right: 15,
          child: ElevatedButton(
              onPressed: () {
                _pageController.nextPage(
                    duration: const Duration(milliseconds: 200),
                    curve: Curves.linear);
              },
              child: const Icon(Icons.skip_next)));
    }
  }

  Widget _buildPre(BuildContext context, int pageSize) {
    if (_index == 0) {
      return const SizedBox();
    } else {
      return Positioned(
          left: 15,
          child: ElevatedButton(
              onPressed: () {
                _pageController.previousPage(
                    duration: const Duration(milliseconds: 200),
                    curve: Curves.linear);
              },
              child: const Icon(Icons.skip_previous)));
    }
  }

  Widget _buildCopyAction(BuildContext context) {
    return IconButton(
        onPressed: () {
          FlutterClipboard.copy(widget.href)
              .then((value) => showToast("链接已复制"));
        },
        icon: const Icon(Icons.copy));
  }

  Widget _buildDownloadAction(BuildContext context) {
    return IconButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) {
              return const DownloadPage();
            }),
          );
        },
        icon: const Icon(Icons.download));
  }

  Widget _buildInfoAction(BuildContext context, DetailState detailState) {
    bool loading = detailState.loading;
    DetailPageEntity detailPageEntity = detailState.detailPageEntity;
    return IconButton(
        onPressed: () {
          if (loading) return;
          showInfoSheet(
              context,
              detailPageEntity.url,
              detailPageEntity.id,
              detailPageEntity.author,
              detailPageEntity.authorId,
              "",
              "",
              detailPageEntity.dimensions,
              "",
              detailPageEntity.tagList, onTagTap: (context, tag) {
            Navigator.of(context).pop();
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) {
                return HomePage(pageName: _searchPageName, tagEntity: tag);
              }),
            );
          });
        },
        icon: const Icon(Icons.info));
  }
}
