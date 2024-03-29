import 'package:MoeLoaderFlutter/net/download.dart';
import 'package:MoeLoaderFlutter/ui/dialog/info_dialog.dart';
import 'package:MoeLoaderFlutter/ui/dialog/url_list_dialog.dart';
import 'package:MoeLoaderFlutter/ui/page/download_page.dart';
import 'package:MoeLoaderFlutter/ui/page/pool_list_page.dart';
import 'package:MoeLoaderFlutter/ui/page/settings_page.dart';
import 'package:MoeLoaderFlutter/widget/home_loading_status.dart';
import 'package:MoeLoaderFlutter/widget/image_masonry_grid.dart';
import 'package:MoeLoaderFlutter/widget/poll_grid.dart';
import 'package:clipboard/clipboard.dart';
import 'package:extended_image/extended_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:MoeLoaderFlutter/init.dart';
import 'package:MoeLoaderFlutter/utils/common_function.dart';
import 'package:MoeLoaderFlutter/ui/page/webview2_page.dart';
import 'package:MoeLoaderFlutter/yamlhtmlparser/models.dart';
import 'package:MoeLoaderFlutter/ui/viewmodel/view_model_home.dart';
import 'package:MoeLoaderFlutter/yamlhtmlparser/yaml_validator.dart';
import 'package:logging/logging.dart';
import '../../utils/const.dart';
import '../../utils/sharedpreferences_utils.dart';
import '../../utils/utils.dart';
import '../../widget/radio_choice_chip.dart';
import 'detail_page.dart';

enum MoreItem { copy, download, option, search, setting, about }

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<StatefulWidget> createState() => _HomeState();
}

class _HomeState extends State<HomePage> {
  final _log = Logger("_HomeState");

  final HomeViewModel _homeViewModel = HomeViewModel();
  final GlobalKey<ScaffoldState> _scaffoldGlobalKey = GlobalKey();
  late TextEditingController _textEditingControl;
  MoreItem? _chooseItem;

  YamlTag? _tag;
  final Map<String, YamlOption> _yamlOptionMap = {};
  String _url = "";

  void _updateTag(YamlTag? tag) {
    setState(() {
      _tag = tag;
    });
  }

  void _clearOptions() {
    _yamlOptionMap.clear();
  }

  void _removeOptions(String id) {
    _yamlOptionMap.remove(id);
  }

  void _requestData({bool clearAll = false, String? page}) {
    _homeViewModel.requestData(
        tags: _tag?.tag,
        optionList: _yamlOptionMap.values.toList(),
        clearAll: clearAll,
        page: page);
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
      stream: _homeViewModel.streamHomeController.stream,
      builder: (BuildContext context, AsyncSnapshot snapshot) {
        return Scaffold(
          key: _scaffoldGlobalKey,
          appBar: AppBar(
              iconTheme: Theme.of(context).iconTheme,
              //导航栏
              title: _buildAppBatTitle(context),
              actions: <Widget>[
                _buildCopyAction(context),
                _buildDownloadAction(context),
                _buildOptionsAction(context),
                _buildSearchAction(context, snapshot),
                _buildSettingsAction(context),
              ]),
          drawer: _buildDrawer(context),
          body: _buildListBody(snapshot),
          floatingActionButton: _buildFloatActionButton(context, snapshot),
        );
      },
    );
  }

  void showSearch(BuildContext context, AsyncSnapshot snapshot) {
    if (!snapshot.hasData) {
      showToast("数据没准备好");
      return;
    }
    HomeState? homeState = snapshot.data;
    if (homeState == null) {
      showToast("数据没准备好");
      return;
    }

    if (!homeState.canSearch) {
      showToast("当前源暂不支持搜索");
      return;
    }

    _textEditingControl.value = TextEditingValue(text: _tag?.desc ?? "");
    showModalBottomSheet(
        context: context,
        builder: (context) {
          return Padding(
            padding:
                const EdgeInsets.only(top: 20, bottom: 20, left: 20, right: 20),
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
                        _requestData(clearAll: true);
                        Navigator.of(context).pop();
                      }),
                ]),
          );
        });
  }

  Widget _buildListBody(AsyncSnapshot snapshot) {
    retryOnPressed() {
      _requestData();
    }

    actionOnPressed(homeState) async {
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
    }

    return LoadingStatus(
        snapshot: snapshot,
        retryOnPressed: retryOnPressed,
        actionOnPressed: actionOnPressed,
        builder: (homeState) {
          if (homeState.listType.isNotEmpty) {
            return PoolGrid(
              list: homeState.list,
              headers: homeState.headers,
              itemOnPressed: (yamlHomePageItem) async {
                NaviResult<YamlTag>? naviResult = await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) {
                    return PoolListPage(href: yamlHomePageItem.href);
                  }),
                );
                _log.info("naviResult=$naviResult");
                if (naviResult?.data != null) {
                  _updateTag(naviResult?.data);
                  _requestData(clearAll: true);
                }
              },
            );
          }
          return ImageMasonryGrid(
            list: homeState.list,
            headers: homeState.headers,
            tagTapCallback: (yamlTag) {
              _updateTag(yamlTag);
              _requestData(clearAll: true);
            },
            itemOnPressed: (yamlHomePageItem) async {
              NaviResult<YamlTag>? naviResult = await Navigator.push(
                context,
                MaterialPageRoute(builder: (context) {
                  return DetailPage(
                      href: yamlHomePageItem.href,
                      commonInfo: yamlHomePageItem.commonInfo);
                }),
              );
              _log.info("naviResult=$naviResult");
              if (naviResult?.data != null) {
                _updateTag(naviResult?.data);
                _requestData(clearAll: true);
              }
            },
          );
        });
  }

  Widget _buildSettingsAction(BuildContext context) {
    return IconButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) {
              return const SettingPage();
            }),
          );
        },
        icon: const Icon(Icons.settings));
  }

  Widget _buildOptionsAction(BuildContext context) {
    return IconButton(
        onPressed: () async {
          List<YamlOptionList> list = await _homeViewModel.optionList();
          if (list.isEmpty) {
            showToast("当前站点无筛选条件");
            return;
          }
          _showOptionsSheet(context, list);
        },
        icon: const Icon(Icons.filter_alt));
  }

  void _showOptionsSheet(BuildContext context, List<YamlOptionList> list) {
    showModalBottomSheet(
        context: context,
        builder: (context) => StatefulBuilder(builder: (context, setState) {
              List<Widget> widgets = [];
              for (YamlOptionList yamlOptionList in list) {
                widgets.add(Padding(
                  padding: const EdgeInsets.only(top: 10, bottom: 10),
                  child: Text(
                    yamlOptionList.desc,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ));
                List<YamlOption> options = yamlOptionList.options;
                int selectedIndex = 0;
                List<String> nameList = [];
                for (int i = 0; i < options.length; i++) {
                  YamlOption yamlOption = options[i];
                  nameList.add(yamlOption.desc);
                  YamlOption? chooseOption = _yamlOptionMap[yamlOption.pId];
                  if (chooseOption != null &&
                      chooseOption.desc == yamlOption.desc) {
                    selectedIndex = i;
                  }
                }
                widgets.add(RadioChoiceChip(
                    list: nameList,
                    index: selectedIndex,
                    radioSelectCallback: (index, name) {
                      _log.fine("selected index=$index");
                      YamlOption yamlOption = options[index];
                      _yamlOptionMap[yamlOption.pId] = yamlOption;
                      setState(() {});
                      Navigator.of(context).pop();
                      _requestData(clearAll: true);
                    }));
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

  Widget _buildCopyAction(BuildContext context) {
    return IconButton(
        onPressed: () async {
          FlutterClipboard.copy(_url).then((value) => showToast("链接已复制"));
          // Navigator.push(
          //   context,
          //   MaterialPageRoute(builder: (context) {
          //     return WebView2Page(
          //       url: "https://www.xsnvshen.co/album/?p=2",
          //       code: 1,
          //     );
          //   }),
          // );
        },
        icon: const Icon(Icons.copy));
  }

  Widget _buildSearchAction(BuildContext context, AsyncSnapshot snapshot) {
    return IconButton(
        onPressed: () {
          if (!snapshot.hasData) {
            showToast("数据没准备好");
            return;
          }
          HomeState? homeState = snapshot.data;
          if (homeState == null) {
            showToast("数据没准备好");
            return;
          }

          if (!homeState.canSearch) {
            showToast("当前源暂不支持搜索");
            return;
          }

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
                              _requestData(clearAll: true);
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
              const ListTile(
                  title: Text(
                "MoeLoaderFlutter",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              )),
              Expanded(
                child: FutureBuilder<List<WebPageItem>>(
                  future: _homeViewModel.webPageList(),
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
                              onTap: () async {
                                _updateTag(null);
                                _clearOptions();
                                await _homeViewModel
                                    .changeGlobalWebPage(list[index]);
                                _requestData(clearAll: true);
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
    if (snapshot.connectionState == ConnectionState.active) {
      HomeState homeState = snapshot.data;
      if (homeState.error && homeState.page <= 1) {
        List<Widget> children = [];
        children.add(ElevatedButton(
            onPressed: () {
              _requestData();
            },
            child: const Text("点击重试")));
        if (homeState.code == ValidateResult.needChallenge ||
            homeState.code == ValidateResult.needLogin) {
          children.add(const SizedBox(
            height: 10,
          ));
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
      if (homeState.loading && homeState.list.isEmpty) {
        return const Center(
          child: CircularProgressIndicator(),
        );
      }
      return Padding(
        padding: const EdgeInsets.all(10),
        child: _buildMasonryGrid(homeState),
      );
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
            width: width,
            height: height,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(5),
              color: loadingBackgroundColor,
            ),
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
                  borderRadius: const BorderRadius.all(Radius.circular(5)),
                  shape: BoxShape.rectangle,
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
                  _log.info("naviResult=$naviResult");
                  if (naviResult?.data != null) {
                    _updateTag(naviResult?.data);
                    _requestData(clearAll: true);
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
                        _updateTag(yamlTag);
                        _requestData(clearAll: true);
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
                    homeState.error
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

  Widget _buildAppBatTitle(BuildContext context) {
    return StreamBuilder<UriState>(
        stream: _homeViewModel.streamUriController.stream,
        builder: (BuildContext context, AsyncSnapshot asyncSnapshot) {
          if (asyncSnapshot.connectionState == ConnectionState.active) {
            UriState uriState = asyncSnapshot.data;
            _url = uriState.url;
            List<Widget> children = [];
            children.add(Chip(
              avatar: ClipOval(
                child: Icon(
                  Icons.title,
                  color: Theme.of(context).iconTheme.color,
                ),
              ),
              label: Text(uriState.siteName),
            ));
            children.add(
              const SizedBox(
                width: 5,
              ),
            );
            children.add(Chip(
              avatar: ClipOval(
                child: Icon(
                  Icons.format_list_numbered,
                  color: Theme.of(context).iconTheme.color,
                ),
              ),
              label: Text(uriState.page),
              deleteIcon: const Icon(Icons.near_me),
              onDeleted: () {
                TextEditingController textEditingController =
                    TextEditingController(text: uriState.page);
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
                                  inputFormatters: [
                                    FilteringTextInputFormatter.allow(
                                        RegExp(r'[0-9]')) //设置只允许输入数字
                                  ],
                                  controller: textEditingController,
                                  decoration: InputDecoration(
                                      prefixIcon: Icon(
                                        Icons.format_list_numbered,
                                        color:
                                            Theme.of(context).iconTheme.color,
                                      ),
                                      suffixIcon: GestureDetector(
                                        child: Icon(
                                          Icons.clear,
                                          color:
                                              Theme.of(context).iconTheme.color,
                                        ),
                                        onTap: () {
                                          textEditingController.clear();
                                        },
                                      ),
                                      border: const OutlineInputBorder(),
                                      labelText: "请输入页码",
                                      hintText: "请输入页码",
                                      helperText: "输入后按ENTER加载指定页码",
                                      filled: true),
                                  onSubmitted: (String value) {
                                    if (value.isEmpty) {
                                      showToast("请输入正确的页码");
                                      return;
                                    }
                                    _requestData(page: value);
                                    Navigator.of(context).pop();
                                  }),
                            ]),
                      );
                    });
              },
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
                  _requestData(clearAll: true);
                },
              ));
            }
            final optionList = uriState.optionList;
            if (optionList != null) {
              for (var item in optionList) {
                children.add(
                  const SizedBox(
                    width: 5,
                  ),
                );
                children.add(Chip(
                  avatar: ClipOval(
                    child: Icon(
                      Icons.filter_alt,
                      color: Theme.of(context).iconTheme.color,
                    ),
                  ),
                  label: Text(item.desc),
                  deleteIcon: ClipOval(
                    child: Icon(
                      Icons.delete,
                      color: Theme.of(context).iconTheme.color,
                    ),
                  ),
                  deleteButtonTooltipMessage: "",
                  onDeleted: () {
                    _removeOptions(item.pId);
                    _requestData(clearAll: true);
                  },
                ));
              }
            }
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
