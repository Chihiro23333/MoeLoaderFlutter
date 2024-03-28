import 'package:MoeLoaderFlutter/ui/viewmodel/view_model_pool_list.dart';
import 'package:MoeLoaderFlutter/ui/page/webview2_page.dart';
import 'package:MoeLoaderFlutter/widget/pool_list_loading_status.dart';
import 'package:clipboard/clipboard.dart';
import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import '../../widget/image_masonry_grid.dart';
import '../../utils/common_function.dart';
import 'detail_page.dart';

class PoolListPage extends StatefulWidget {
  const PoolListPage({super.key, required this.href});

  final String href;

  @override
  State<StatefulWidget> createState() => _PoolListState();
}

class _PoolListState extends State<PoolListPage> {
  final _log = Logger("_PoolListState");

  final PoolListViewModel _poolListModel = PoolListViewModel();
  String _url = "";

  void _requestData() {
    _poolListModel.requestData(widget.href);
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
              title: _buildAppBatTitle(context),
              actions: <Widget>[
                _buildCopyAction(context),
              ]),
          body: _buildListBody(snapshot),
        );
      },
    );
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
          return WebView2Page(
            url: _url,
            code: poolListState.code,
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
          return ImageMasonryGrid(
            list: poolListState.list,
            headers: poolListState.headers,
            itemOnPressed: (yamlHomePageItem) async {
              await Navigator.push(
                context,
                MaterialPageRoute(builder: (context) {
                  return DetailPage(
                      href: yamlHomePageItem.href,
                      commonInfo: yamlHomePageItem.commonInfo);
                }),
              );
            },
          );
        });
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
