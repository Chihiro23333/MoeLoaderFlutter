import 'package:moeloaderflutter/init.dart';
import 'package:moeloaderflutter/multiplatform/bean.dart';
import 'package:moeloaderflutter/ui/common/common.dart';
import 'package:moeloaderflutter/ui/viewmodel/view_model_pool_list.dart';
import 'package:moeloaderflutter/util/common_function.dart';
import 'package:moeloaderflutter/widget/image_masonry_grid.dart';
import 'package:moeloaderflutter/widget/pool_list_loading_status.dart';
import 'package:clipboard/clipboard.dart';
import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import 'detail_page.dart';

class PoolListPage extends StatefulWidget {
  const PoolListPage({super.key, required this.id});

  final String id;

  @override
  State<StatefulWidget> createState() => _PoolListState();
}

class _PoolListState extends State<PoolListPage> {
  final _log = Logger("_PoolListState");

  final PoolListViewModel _poolListModel = PoolListViewModel();
  String _url = "";

  void _requestData() {
    _poolListModel.requestData(widget.id);
  }

  @override
  void initState() {
    super.initState();
    _requestData();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<PoolListState>(
      stream: _poolListModel.streamPoolListController.stream,
      builder: (BuildContext context, AsyncSnapshot snapshot) {
        return Scaffold(
          appBar: AppBar(
              iconTheme: Theme.of(context).iconTheme,
              //导航栏
              title: _buildNewAppBartTitle(context),
              actions: _buildActions(context, snapshot)),
          body: _buildListBody(snapshot),
          floatingActionButton: _buildFloatActionButton(context, snapshot),
        );
      },
    );
  }

  List<Widget> _buildActions(BuildContext context, AsyncSnapshot snapshot) {
    List<Widget> list = [];
    list.add(_buildOptionsAction(context, snapshot));
    return list;
  }

  Widget _buildOptionsAction(BuildContext context, AsyncSnapshot snapshot) {
    return IconButton(
        onPressed: () async {
          await _filter(context, snapshot);
        },
        icon: const Icon(Icons.filter_alt));
  }

  Widget _buildFloatActionButton(BuildContext context, AsyncSnapshot snapshot) {
    if (snapshot.connectionState == ConnectionState.active) {
      PoolListState poolListState = snapshot.data;
      return FloatingActionButton(
        onPressed: () {
          if (poolListState.loading) return;
          _requestData();
        },
        child: Stack(
          children: [
            Visibility(
                visible: poolListState.loading,
                child: const Center(
                  child: CircularProgressIndicator(),
                )),
            Visibility(
                visible: !poolListState.loading,
                child: Center(
                  child: Icon(
                    poolListState.error
                        ? Icons.refresh
                        : Icons.keyboard_double_arrow_down,
                    color: Theme.of(context).iconTheme.color,
                  ),
                ))
          ],
        ),
      );
    } else {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }
  }

  Future<void> _filter(BuildContext context, AsyncSnapshot snapshot) async {
    PoolListState? poolListState = snapshot.data;
    _showOptionsSheet(context, poolListState);
  }

  void _showOptionsSheet(BuildContext context, PoolListState? poolListState) {
    showModalBottomSheet(
        context: context,
        builder: (context) => StatefulBuilder(builder: (context, setState) {
              List<Widget> widgets = [];

              if (poolListState != null) {
                var url = poolListState.url;
                if (url.isNotEmpty) {
                  widgets.add(const Padding(
                    padding: EdgeInsets.only(top: 10, bottom: 10),
                    child: Text(
                      "网页地址：",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ));
                  widgets.add(Wrap(
                    spacing: 8.0, // 主轴(水平)方向间距
                    runSpacing: 4.0, // 纵轴（垂直）方向间距
                    children: [buildUrlWidget(context, url)],
                  ));
                }
                int page = poolListState.page;
                widgets.add(Padding(
                  padding: const EdgeInsets.only(top: 10, bottom: 10),
                  child: Text(
                    "当前加载页码：$page",
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ));
              }
              return SingleChildScrollView(
                  padding: const EdgeInsets.only(
                      left: 10, top: 10, right: 10, bottom: 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: widgets,
                  ));
            }));
  }

  Widget _buildCopyAction(BuildContext context) {
    return IconButton(
        onPressed: () async {
          FlutterClipboard.copy(_url).then((value) => showToast("链接已复制"));
        },
        icon: const Icon(Icons.copy));
  }

  Widget _buildListBody(AsyncSnapshot snapshot) {
    retryOnPressed() {
      _requestData();
    }

    actionOnPressed(poolListState) async {
      bool? result = await Navigator.push(
        context,
        MaterialPageRoute(builder: (context) {
          return Global.multiPlatform.navigateToWebView(
            context,
            _url,
            poolListState.code,
          );
        }),
      );
      _log.fine("push result=${result}");
      if (result != null && result) {
        _requestData();
      }
    }

    return LoadingStatus(
        snapshot: snapshot,
        retryOnPressed: retryOnPressed,
        actionOnPressed: actionOnPressed,
        builder: (poolListState) {
          Grid homeGrid = Global.multiPlatform.homeGrid();
          int columnCount = homeGrid.columnCount;
          double aspectRatio = homeGrid.aspectRatio;
          return ImageMasonryGrid(
            columnCount:columnCount,
            aspectRatio: aspectRatio,
            list: poolListState.list,
            headers: poolListState.headers,
            itemOnPressed: (homePageItem) async {
              await Navigator.push(
                context,
                MaterialPageRoute(builder: (context) {
                  return DetailPage(
                      href: homePageItem.href, homePageItem: homePageItem);
                }),
              );
            },
          );
        });
  }

  Widget _buildNewAppBartTitle(BuildContext context) {
    return const Text(
      "列表",
      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
    );
  }

  Widget _buildAppBatTitle(BuildContext context) {
    return StreamBuilder<UriState>(
        stream: _poolListModel.streamUriController.stream,
        builder: (BuildContext context, AsyncSnapshot asyncSnapshot) {
          if (asyncSnapshot.connectionState == ConnectionState.active) {
            UriState uriState = asyncSnapshot.data;
            _url = uriState.url;
            List<Widget> children = [];
            children.add(Chip(
              avatar: ClipOval(
                child: Icon(
                  Icons.link,
                  color: Theme.of(context).iconTheme.color,
                ),
              ),
              label: Text(uriState.url),
            ));
            return FittedBox(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: children,
              ),
            );
          } else {
            return const SizedBox();
          }
        });
  }
}
