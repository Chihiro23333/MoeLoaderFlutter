import 'package:clipboard/clipboard.dart';
import 'package:extended_image/extended_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:FlutterMoeLoaderDesktop/init.dart';
import 'package:FlutterMoeLoaderDesktop/ui/about_dialog.dart';
import 'package:FlutterMoeLoaderDesktop/ui/common_function.dart';
import 'package:FlutterMoeLoaderDesktop/ui/settings_dialog.dart';
import 'package:FlutterMoeLoaderDesktop/ui/webview2_page.dart';
import 'package:FlutterMoeLoaderDesktop/yamlhtmlparser/models.dart';
import 'package:FlutterMoeLoaderDesktop/ui/view_model_home.dart';
import 'package:FlutterMoeLoaderDesktop/yamlhtmlparser/yaml_validator.dart';
import 'package:logging/logging.dart';
import '../utils/utils.dart';
import 'detail_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<StatefulWidget> createState() => _HomeState();
}

class _HomeState extends State<HomePage> {
  final _log = Logger("_HomeState");

  final HomeViewModel _picHomeViewModel = HomeViewModel();
  final GlobalKey<ScaffoldState> _scaffoldGlobalKey = GlobalKey();
  late TextEditingController _textEditingControl;

  YamlTag? _tag;
  String _url = "";

  void _updateTag(YamlTag? tag) {
    setState(() {
      _tag = tag;
    });
  }

  void _requestData({bool clearAll = false}) {
    _picHomeViewModel.requestData(tags: _tag?.tag, clearAll: clearAll);
  }

  void _requestByTag() {
    _picHomeViewModel.requestData(tags: _tag?.tag, clearAll: true);
  }

  @override
  void initState() {
    super.initState();
    _requestData(clearAll: true);
    _textEditingControl = TextEditingController();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<HomeState>(
      stream: _picHomeViewModel.streamHomeController.stream,
      builder: (BuildContext context, AsyncSnapshot snapshot) {
        return Scaffold(
          key: _scaffoldGlobalKey,
          appBar: AppBar(
              iconTheme: Theme.of(context).iconTheme,
              //导航栏
              title: _buildAppBatTitle(context),
              actions: <Widget>[
                _buildCopyAction(context),
                _buildSearchAction(context),
                _buildSettingsAction(context),
                _buildAboutAction(context)
              ]),
          drawer: _buildDrawer(context),
          body: _buildBody(context, snapshot),
          floatingActionButton: _buildFloatActionButton(context, snapshot),
        );
      },
    );
  }

  Widget _buildSettingsAction(BuildContext context) {
    return IconButton(
        onPressed: () {
          showSettings(context);
        },
        icon: const Icon(Icons.settings));
  }

  Widget _buildAboutAction(BuildContext context) {
    return IconButton(
        onPressed: () {
          showAbout(context);
        },
        icon: const Icon(Icons.grid_view_sharp));
  }

  Widget _buildCopyAction(BuildContext context) {
    return IconButton(
        onPressed: () async {
          FlutterClipboard.copy(_url).then(( value ) => showToast("链接已复制"));
          // var result = await Navigator.push(
          //   context,
          //   MaterialPageRoute(builder: (context) {
          //     return const WebView2Page(
          //       url: "https://www.pixiv.net/",
          //       code: ValidateResult.needLogin,
          //     );
          //   }),
          // );
          // _log.fine("push result=$result");
        },
        icon: const Icon(Icons.copy));
  }

  Widget _buildSearchAction(BuildContext context) {
    return IconButton(
        onPressed: () {
          if (_tag != null) {
            _textEditingControl.value = TextEditingValue(text: _tag!.desc);
          }
          showModalBottomSheet(
              context: context,
              builder: (context) {
                return Padding(
                  padding: const EdgeInsets.only(
                      top: 20, bottom: 20, left: 20, right: 20),
                  child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        TextField(
                            controller: _textEditingControl,
                            decoration: InputDecoration(
                                prefixIcon: Icon(
                                  Icons.label,
                                  color: Theme.of(context).iconTheme.color,
                                ),
                                suffixIcon: GestureDetector(
                                  child: Icon(
                                    Icons.clear,
                                    color: Theme.of(context).iconTheme.color,
                                  ),
                                  onTap: () {
                                    _textEditingControl.clear();
                                  },
                                ),
                                border: const OutlineInputBorder(),
                                labelText: "请输入tag",
                                hintText: "请输入tag",
                                helperText: "按ENTER键开始搜索",
                                filled: true),
                            onSubmitted: (String value) {
                              _updateTag(YamlTag(value, value));
                              _requestByTag();
                              Navigator.of(context).pop();
                            }),
                      ]),
                );
              });
        },
        icon: const Icon(Icons.image_search));
  }

  Widget _buildDrawer(BuildContext context) {
    return Drawer(
      child: MediaQuery.removePadding(
          context: context,
          child: Column(
            children: [
              const ListTile(title: Text(
                  "△FlutterMoeLoaderDesktop△",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              )),
              Expanded(
                child: FutureBuilder<List<WebPageItem>>(
                  future: _picHomeViewModel.webPageList(),
                  builder: (BuildContext context, AsyncSnapshot snapshot) {
                    if (snapshot.hasError) {
                      return Text("Error: ${snapshot.error}");
                    }
                    if (snapshot.connectionState == ConnectionState.done) {
                      List<WebPageItem> list = snapshot.data;
                      return ListView.builder(
                          itemCount: list.length,
                          itemBuilder: (BuildContext context, int index) {
                            return ListTile(
                              leading: Icon(
                                Icons.call_to_action,
                                color: Theme.of(context).iconTheme.color,
                              ),
                              titleTextStyle:
                                  list[index].rule.name == Global.curWebPageName
                                      ? const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: Colors.black)
                                      : const TextStyle(
                                          fontWeight: FontWeight.normal,
                                          color: Colors.black),
                              selected: list[index].rule.name ==
                                  Global.curWebPageName,
                              textColor: Colors.black,
                              title: Text(
                                list[index].rule.name,
                                style: const TextStyle(fontSize: 18),
                              ),
                              onTap: () {
                                _updateTag(null);
                                _picHomeViewModel
                                    .changeGlobalWebPage(list[index]);
                                _scaffoldGlobalKey.currentState?.closeDrawer();
                              },
                            );
                          });
                    } else {
                      return const Center(
                        child: CircularProgressIndicator(),
                      );
                    }
                  },
                ),
              )
            ],
          )),
    );
  }

  Widget _buildBody(BuildContext context, AsyncSnapshot snapshot) {
    debugPrint(snapshot.connectionState.toString());
    if (snapshot.hasError) {
      return Text("Error: ${snapshot.error}");
    }
    if (snapshot.connectionState == ConnectionState.active) {
      HomeState homeState = snapshot.data;
      if (homeState.firstIn && homeState.error) {
        List<Widget> children = [];
        children.add(ElevatedButton(
            onPressed: () {
              _requestData(clearAll: true);
            },
            child: const Text("点击重试")));
        if (homeState.code == ValidateResult.needChallenge ||
            homeState.code == ValidateResult.needLogin) {
          children.add(const SizedBox(height: 20));
          children.add(ElevatedButton(
              onPressed: () async {
                bool? result = await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) {
                    return WebView2Page(
                      url: _url,
                      code: homeState.code,
                    );
                  }),
                );
                _log.fine("push result=${result}");
                if (result != null && result) {
                  _requestData(clearAll: true);
                }
              },
              child: Text(tipsByCode(homeState.code))));
        }
        children.add(const SizedBox(height: 20));
        children.add(Center(
          child: Text(
            homeState.errorMessage,
          ),
        ));
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: children,
          ),
        );
      }
      if (homeState.firstIn) {
        return const Center(
          child: CircularProgressIndicator(),
        );
      }
      return _buildMasonryGrid(homeState);
    } else {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }
  }

  Widget _buildGrid(HomeState homeState) {
    int crossAxisCount = Global.columnCount;
    double aspectRatio = Global.aspectRatio;
    return GridView.builder(
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            mainAxisExtent: 10,
            crossAxisSpacing: 10,
            childAspectRatio: aspectRatio),
        itemBuilder: (BuildContext context, int index) {
          YamlHomePageItem yamlHomePageItem = homeState.list[index];
          return _buildItem(context, yamlHomePageItem, index, crossAxisCount, 0,
              0, homeState.headers);
        });
  }

  Widget _buildMasonryGrid(HomeState homeState) {
    int crossAxisCount = Global.columnCount;
    return MasonryGridView.count(
        crossAxisCount: crossAxisCount,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        itemCount: homeState.list.length,
        itemBuilder: (BuildContext context, int index) {
          MediaQueryData queryData = MediaQuery.of(context);
          double screenWidth = queryData.size.width;
          YamlHomePageItem yamlHomePageItem = homeState.list[index];
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
            color: loadingBackgroundColor,
            width: width,
            height: height,
            child: _buildItem(context, yamlHomePageItem, index, crossAxisCount,
                width, height, homeState.headers),
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
                  headers: headers,
                  width: width,
                  height: height,
                  yamlHomePageItem.url,
                  fit: BoxFit.cover,
                ),
                onTap: () async {
                  NaviResult<YamlTag>? naviResult = await Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) {
                      return DetailPage(
                          href: yamlHomePageItem.href,
                          commonInfo: yamlHomePageItem.commonInfo);
                    }),
                  );
                  print("naviResult=$naviResult");
                  if (naviResult?.data != null) {
                    _updateTag(naviResult?.data);
                    _requestByTag();
                  }
                })),
        Positioned(
          right: 0,
          bottom: 0,
          child: GestureDetector(
            child: const Padding(
              padding:
                  EdgeInsets.only(top: 15, bottom: 15, left: 10, right: 10),
              child: Icon(Icons.info),
            ),
            onTap: () {
              showInfoSheet(context, yamlHomePageItem.commonInfo,
                  onTagTap: (yamlTag) {
                _log.fine("yamlTag:tag=${yamlTag.tag};desc=${yamlTag.desc}");
                _updateTag(yamlTag);
                _requestByTag();
                Navigator.of(context).pop();
              });
            },
          ),
        ),
      ],
    );
  }

  Widget _buildFloatActionButton(BuildContext context, AsyncSnapshot snapshot) {
    if (snapshot.hasError) {
      return Text("Error: ${snapshot.error}");
    }
    if (snapshot.connectionState == ConnectionState.active) {
      HomeState homeState = snapshot.data;
      return FloatingActionButton(
        onPressed: () {
          if (homeState.loading) return;
          _requestData();
        },
        child: Stack(
          children: [
            Visibility(
                visible: homeState.loading,
                child: const Center(
                  child: CircularProgressIndicator(),
                )),
            Visibility(
                visible: !homeState.loading,
                child: Center(
                  child: Icon(
                    Icons.keyboard_double_arrow_down,
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

  Widget _buildAppBatTitle(BuildContext context) {
    return StreamBuilder<UriState>(
        stream: _picHomeViewModel.streamUriController.stream,
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
              label: Text(uriState.baseHref),
            ));
            children.add(
              const SizedBox(
                width: 5,
              ),
            );
            children.add(Chip(
              avatar: ClipOval(
                child: Icon(
                  Icons.insert_page_break,
                  color: Theme.of(context).iconTheme.color,
                ),
              ),
              label: Text(uriState.page),
            ));
            if (uriState.tag.isNotEmpty) {
              children.add(
                const SizedBox(
                  width: 5,
                ),
              );
              children.add(Chip(
                avatar: ClipOval(
                  child: Icon(
                    Icons.label,
                    color: Theme.of(context).iconTheme.color,
                  ),
                ),
                label: Text(_tag?.desc ?? ""),
                deleteIcon: ClipOval(
                  child: Icon(
                    Icons.delete,
                    color: Theme.of(context).iconTheme.color,
                  ),
                ),
                deleteButtonTooltipMessage: "",
                onDeleted: () {
                  _updateTag(null);
                  _requestByTag();
                },
              ));
            }
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
}
