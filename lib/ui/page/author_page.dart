import 'package:moeloaderflutter/init.dart';
import 'package:moeloaderflutter/multiplatform/bean.dart';
import 'package:moeloaderflutter/ui/common/common.dart';
import 'package:moeloaderflutter/ui/viewmodel/view_model_author.dart';
import 'package:moeloaderflutter/util/common_function.dart';
import 'package:moeloaderflutter/util/const.dart';
import 'package:moeloaderflutter/widget/image_masonry_grid.dart';
import 'package:moeloaderflutter/widget/authot_loading_status.dart';
import 'package:clipboard/clipboard.dart';
import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import '../dialog/number_input_dialog.dart';
import 'detail_page.dart';

class AuthorPage extends StatefulWidget {
  const AuthorPage({super.key, required this.authorId});

  final String authorId;

  @override
  State<StatefulWidget> createState() => _AuthorState();
}

class _AuthorState extends State<AuthorPage> {
  final _log = Logger("_AuthorState");

  final AuthorViewModel _authorModel = AuthorViewModel();
  String _url = "";

  void _requestData({String? page}) {
    _authorModel.requestData(widget.authorId, page: page);
  }

  @override
  void initState() {
    super.initState();
    _requestData();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<AuthorState>(
      stream: _authorModel.streamAuthorController.stream,
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
    return Padding(
        padding: appBarActionPadding(),
        child: IconButton(
            onPressed: () async {
              await _filter(context, snapshot);
            },
            icon: const Icon(Icons.filter_alt)));
  }

  Widget _buildFloatActionButton(BuildContext context, AsyncSnapshot snapshot) {
    if (snapshot.connectionState == ConnectionState.active) {
      AuthorState authorState = snapshot.data;
      bool loading = authorState.loading;
      bool error = authorState.error;
      return InkWell(
        onLongPress: () {
          if (authorState.loading) return;
          showPageInputDialog(context, authorState.page, (value) {
            _requestData(page: value);
          });
        },
        child: FloatingActionButton(
          onPressed: () {
            if (authorState.loading) return;
            _requestData();
          },
          child: Stack(
            children: [
              Visibility(
                  visible: loading,
                  child: const Center(
                    child: CircularProgressIndicator(),
                  )),
              Visibility(
                  visible: !loading,
                  child: Center(
                    child: Icon(
                      error ? Icons.refresh : Icons.keyboard_double_arrow_down,
                      color: Theme.of(context).iconTheme.color,
                    ),
                  ))
            ],
          ),
        ),
      );
    } else {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }
  }

  Future<void> _filter(BuildContext context, AsyncSnapshot snapshot) async {
    AuthorState? authorState = snapshot.data;
    _showOptionsSheet(context, authorState);
  }

  void _showOptionsSheet(BuildContext context, AuthorState? authorState) {
    showModalBottomSheet(
        context: context,
        builder: (context) => StatefulBuilder(builder: (context, setState) {
              List<Widget> widgets = [];

              if (authorState != null) {
                var url = authorState.url;
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
                widgets.add(const Padding(
                  padding: EdgeInsets.only(top: 10, bottom: 10),
                  child: Text(
                    "当前加载页码",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ));
                int page = authorState.page;
                widgets.add(pageChip(context, page));
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

    actionOnPressed(authorState) async {
      bool? result = await Navigator.push(
        context,
        MaterialPageRoute(builder: (context) {
          return Global.multiPlatform.navigateToWebView(
            context,
            _url,
            authorState.code,
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
        builder: (authorState) {
          Grid homeGrid = Global.multiPlatform.homeGrid(Const.authorPage);
          int columnCount = homeGrid.columnCount;
          double aspectRatio = homeGrid.aspectRatio;
          return ImageMasonryGrid(
            columnCount: columnCount,
            aspectRatio: aspectRatio,
            list: authorState.list,
            headers: authorState.headers,
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
        stream: _authorModel.streamUriController.stream,
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
