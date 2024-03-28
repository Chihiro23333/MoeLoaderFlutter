import 'package:MoeLoaderFlutter/ui/dialog/info_dialog.dart';
import 'package:MoeLoaderFlutter/ui/page/download_page.dart';
import 'package:clipboard/clipboard.dart';
import 'package:extended_image/extended_image.dart';
import 'package:flutter/material.dart';
import 'package:MoeLoaderFlutter/ui/page/webview2_page.dart';
import 'package:MoeLoaderFlutter/ui/viewmodel/view_model_detail.dart';
import 'package:MoeLoaderFlutter/yamlhtmlparser/yaml_validator.dart';
import 'package:logging/logging.dart';
import '../../yamlhtmlparser/models.dart';
import '../../utils/utils.dart';
import '../../utils/common_function.dart';
import '../../widget/keep_alive_wrapper.dart';

class DetailPage extends StatefulWidget {
  const DetailPage({super.key, required this.commonInfo, required this.href});

  final CommonInfo? commonInfo;
  final String href;

  @override
  State<StatefulWidget> createState() => _DetailState();
}

class _DetailState extends State<DetailPage> {
  final DetailViewModel _detailViewModel = DetailViewModel();
  YamlDetailPage? _yamlDetailPage;
  int _index = 0;
  final PageController _pageController = PageController();
  final _log = Logger('_DetailState');

  void _updateIndex(int page) {
    setState(() {
      _index = page;
    });
  }

  void _requestDetailData() {
    print("widget.href=${widget.href}");
    _detailViewModel.requestDetailData(widget.href,commonInfo: widget.commonInfo);
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
        _buildCopyAction(context),
        _buildDownloadAction(context),
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
                    return WebView2Page(
                      url: widget.href,
                      code: detailState.code,
                    );
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
      _updateCommonInfo(detailState.yamlDetailPage);
      _yamlDetailPage = detailState.yamlDetailPage;
      List<String> urlList = [];
      urlList.add(_yamlDetailPage!.url);
      _log.fine("urlList=$urlList");
      if (_yamlDetailPage!.preview.isNotEmpty) {
        urlList.addAll(_yamlDetailPage!.preview.split(","));
      }
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
          if (loading){
            showToast("数据还没准备好");
            return;
          }
          if(downloading){
            showToast("已经有图片正在下载中，请等待");
            return;
          }
          if (_yamlDetailPage != null) {
            String? url = _yamlDetailPage!.url;
            String? bigUrl = _yamlDetailPage!.commonInfo?.bigUrl;
            String? rawUrl = _yamlDetailPage!.commonInfo?.rawUrl;
            _log.fine("url=$url;rawUrl=$rawUrl;bigUrl=$bigUrl");
            List<Widget> children = [];
            if (isImageUrl(url) && url.isNotEmpty) {
              children.add(buildDownloadItem(context, url, "当前预览图片($url)", () {
                Navigator.of(context).pop();
                _detailViewModel.download(widget.href, url, _yamlDetailPage!.commonInfo);
              }));
            }
            if (bigUrl != null && bigUrl.isNotEmpty) {
              children.add(const Divider(
                height: 10,
              ));
              children.add(buildDownloadItem(context, bigUrl, "大图($bigUrl)", () {
                Navigator.of(context).pop();
                _detailViewModel.download(widget.href, bigUrl, _yamlDetailPage!.commonInfo);
              }));
            }
            if (rawUrl != null && rawUrl.isNotEmpty) {
              children.add(const Divider(
                height: 10,
              ));
              children.add(buildDownloadItem(context, rawUrl, "原图($rawUrl)", () {
                Navigator.of(context).pop();
                _detailViewModel.download(widget.href, rawUrl, _yamlDetailPage!.commonInfo);
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
              FlutterClipboard.copy(url)
                  .then((value) => showToast("链接已复制"));
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
    return StreamBuilder<DetailUriState>(
        stream: _detailViewModel.streamDetailUriController.stream,
        builder: (BuildContext context, AsyncSnapshot asyncSnapshot) {
          if (asyncSnapshot.connectionState == ConnectionState.active) {
            DetailUriState uriState = asyncSnapshot.data;
            List<Widget> children = [];
            children.add(Chip(
              avatar: ClipOval(
                child: Icon(
                  Icons.link,
                  color: Theme.of(context).iconTheme.color,
                ),
              ),
              label: Text(uriState.baseHref),
            ));
            return FittedBox(
              child: Row(
                children: children,
              ),
            );
          } else {
            return const SizedBox();
          }
        });
  }

  //处理部分网页没有详情页的情况
  void _updateCommonInfo(YamlDetailPage yamlDetailPage) {
    if (yamlDetailPage.commonInfo == null && widget.commonInfo != null) {
      yamlDetailPage.commonInfo = widget.commonInfo;
    }
  }

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
    return IconButton(
        onPressed: () {
          if (loading) return;
          showInfoSheet(context, _yamlDetailPage?.commonInfo,
              onTagTap: (yamlTag) {
            Navigator.of(context)
              ..pop()
              ..pop(NaviResult<YamlTag>(yamlTag));
          });
        },
        icon: const Icon(Icons.info));
  }
}
