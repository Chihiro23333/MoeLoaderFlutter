import 'dart:io';
import 'package:MoeLoaderFlutter/model/option_entity.dart';
import 'package:MoeLoaderFlutter/model/tag_entity.dart';
import 'package:MoeLoaderFlutter/ui/page/download_page.dart';
import 'package:MoeLoaderFlutter/ui/page/pool_list_page.dart';
import 'package:MoeLoaderFlutter/ui/page/result_list_page.dart';
import 'package:MoeLoaderFlutter/ui/page/search_page.dart';
import 'package:MoeLoaderFlutter/ui/page/settings_page.dart';
import 'package:MoeLoaderFlutter/util/common_function.dart';
import 'package:MoeLoaderFlutter/util/const.dart';
import 'package:MoeLoaderFlutter/util/entity.dart';
import 'package:MoeLoaderFlutter/widget/home_loading_status.dart';
import 'package:MoeLoaderFlutter/widget/image_masonry_grid.dart';
import 'package:MoeLoaderFlutter/widget/poll_grid.dart';
import 'package:MoeLoaderFlutter/widget/radio_choice_chip.dart';
import 'package:clipboard/clipboard.dart';
import 'package:extended_image/extended_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:MoeLoaderFlutter/init.dart';
import 'package:MoeLoaderFlutter/ui/page/webview2_page.dart';
import 'package:MoeLoaderFlutter/ui/viewmodel/view_model_home.dart';
import 'package:logging/logging.dart';
import 'detail_page.dart';
import 'package:to_json/models.dart' as jsonModels;

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

  final String _homePageName = "homePage";
  final String _searchPageName = "searchPage";

  final Map<String, String> _yamlOptionMap = {};
  String _url = "";
  String? _keyword;
  TagEntity? _tagEntity;

  void _updateTag(TagEntity? tagEntity) {
    setState(() {
      _tagEntity = tagEntity;
      _keyword = tagEntity?.desc ?? "";
    });
  }

  void _updateKeyword(String keyword) {
    setState(() {
      _keyword = keyword;
    });
  }

  void _clearOptions() {
    _yamlOptionMap.clear();
  }

  void _removeOptions(String key) {
    _yamlOptionMap.remove(key);
  }

  void _requestData({bool clearAll = false, String? page}) {
    _homeViewModel.requestData(pageName(),
        options: _yamlOptionMap,
        clearAll: clearAll,
        page: page,
        keyword: _keyword,
        tagEntity: _tagEntity);
  }

  String pageName() {
    bool home = (_keyword == null || _keyword!.isEmpty) && _tagEntity == null;
    String pageName = home ? _homePageName : _searchPageName;
    return pageName;
  }

  @override
  void initState() {
    super.initState();
    _requestData(clearAll: true);
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
                // _buildSearchAction(context, snapshot),
                // _buildSettingsAction(context),
              ]),
          body: _buildListBody(context, snapshot),
          floatingActionButton: _buildFloatActionButton(context, snapshot),
        );
      },
    );
  }

  Widget _buildListBody(BuildContext context, AsyncSnapshot snapshot) {
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
            userAgent: homeState.headers?["user-agent"],
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
          int columnCount = Global.customRuleParser.columnCount(Const.homePage);
          double aspectRatio =
              Global.customRuleParser.aspectRatio(Const.homePage);
          if (homeState.pageType.isNotEmpty) {
            return PoolGrid(
              columnCount: columnCount,
              aspectRatio: aspectRatio,
              list: homeState.list,
              headers: homeState.headers,
              itemOnPressed: (yamlHomePageItem) async {
                NaviResult<TagEntity>? naviResult = await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) {
                    return PoolListPage(id: yamlHomePageItem.id);
                  }),
                );
                _log.fine("naviResult=$naviResult");
                if (naviResult?.data != null) {
                  _updateTag(naviResult?.data);
                  _requestData(clearAll: true);
                }
              },
            );
          }
          return ImageMasonryGrid(
            columnCount: columnCount,
            aspectRatio: aspectRatio,
            list: homeState.list,
            headers: homeState.headers,
            tagTapCallback: (context, tag) {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) {
                  return ResultListPage(
                      pageName: _searchPageName, tagEntity: tag);
                }),
              );
            },
            itemOnPressed: (homePageItem) async {
              NaviResult<TagEntity>? naviResult = await Navigator.push(
                context,
                MaterialPageRoute(builder: (context) {
                  return DetailPage(
                      href: homePageItem.href, homePageItem: homePageItem);
                }),
              );
              _log.fine("naviResult=$naviResult");
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
          List<OptionEntity> list =
              await _homeViewModel.optionList(pageName(), _keyword);
          if (list.isEmpty) {
            showToast("当前站点无筛选条件");
            return;
          }
          _showOptionsSheet(context, list);
        },
        icon: const Icon(Icons.filter_alt));
  }

  void _showOptionsSheet(BuildContext context, List<OptionEntity> list) {
    showModalBottomSheet(
        context: context,
        builder: (context) => StatefulBuilder(builder: (context, setState) {
              List<Widget> widgets = [];
              for (OptionEntity optionEntity in list) {
                widgets.add(Padding(
                  padding: const EdgeInsets.only(top: 10, bottom: 10),
                  child: Text(
                    optionEntity.desc,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ));
                List<OptionItems> options = optionEntity.items;
                int selectedIndex = 0;
                List<String> nameList = [];
                for (int i = 0; i < options.length; i++) {
                  OptionItems optionItems = options[i];
                  nameList.add(optionItems.desc);
                  String? chooseOption = _yamlOptionMap[optionEntity.id];
                  if (chooseOption != null &&
                      chooseOption == optionItems.param) {
                    selectedIndex = i;
                  }
                }
                widgets.add(RadioChoiceChip(
                    list: nameList,
                    index: selectedIndex,
                    radioSelectCallback: (index, name) {
                      _log.fine("selected index=$index");
                      _yamlOptionMap[optionEntity.id] = options[index].param;
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
        },
        icon: const Icon(Icons.copy));
  }

  Widget _buildSearchAction(BuildContext context, AsyncSnapshot snapshot) {
    return IconButton(
        onPressed: () async {
          if (snapshot.hasData) {
            HomeState? homeState = snapshot.data;
            if (homeState != null) {
              if (homeState.canSearch) {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) {
                    return SearchPage(keyword: _keyword ?? "");
                  }),
                );
              } else {
                showToast("此源暂不支持搜索");
              }
            }
          }
        },
        icon: const Icon(Icons.image_search));
  }

  Widget _buildDrawer(BuildContext context) {
    List<jsonModels.Rule> list = _homeViewModel.webPageList();
    return Drawer(
      child: MediaQuery.removePadding(
          context: context,
          child: Column(
            children: [
              const ListTile(
                  title: Text(
                "源列表",
                style: TextStyle(fontWeight: FontWeight.normal, fontSize: 17),
              )),
              Expanded(
                  child: ListView.builder(
                      itemCount: list.length,
                      itemBuilder: (BuildContext context, int index) {
                        jsonModels.Rule rule = list[index];
                        _log.fine("rule.faviconPath=${rule.faviconPath}");
                        Widget leading;
                        if (rule.faviconPath.isEmpty) {
                          leading = Icon(
                            Icons.call_to_action,
                            color: Theme.of(context).iconTheme.color,
                          );
                        } else {
                          leading = Image.file(
                            File(rule.faviconPath),
                            fit: BoxFit.cover,
                          );
                        }
                        return ListTile(
                          leading: SizedBox(
                            height: 25,
                            width: 25,
                            child: leading,
                          ),
                          titleTextStyle: list[index].fileName ==
                                  Global.curWebPageName
                              ? const TextStyle(fontWeight: FontWeight.bold)
                              : const TextStyle(fontWeight: FontWeight.normal),
                          selected:
                              list[index].fileName == Global.curWebPageName,
                          selectedColor: Global.defaultColor,
                          textColor: Colors.black,
                          title: Text(
                            list[index].fileName,
                            style: const TextStyle(fontSize: 17),
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
                      }))
            ],
          )),
    );
  }

  Widget _buildFloatActionButton(BuildContext context, AsyncSnapshot snapshot) {
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
            children.add(
              const SizedBox(
                width: 5,
              ),
            );
            String keyword = uriState.searchDesc;
            if (keyword.isNotEmpty) {
              children.add(Chip(
                avatar: ClipOval(
                  child: Icon(
                    Icons.filter_alt,
                    color: Theme.of(context).iconTheme.color,
                  ),
                ),
                label: Text(keyword),
                deleteIcon: ClipOval(
                  child: Icon(
                    Icons.delete,
                    color: Theme.of(context).iconTheme.color,
                  ),
                ),
                deleteButtonTooltipMessage: "",
                onDeleted: () {
                  _updateKeyword("");
                  _requestData(clearAll: true);
                },
              ));
            }
            final options = uriState.options;
            _log.fine("homePage options=$options");
            if (options != null) {
              for (var keyItem in options.keys) {
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
                  label: Text(options[keyItem] ?? ""),
                  deleteIcon: ClipOval(
                    child: Icon(
                      Icons.delete,
                      color: Theme.of(context).iconTheme.color,
                    ),
                  ),
                  deleteButtonTooltipMessage: "",
                  onDeleted: () {
                    _removeOptions(keyItem);
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
