import 'package:moeloaderflutter/init.dart';
import 'package:moeloaderflutter/multiplatform/bean.dart';
import 'package:moeloaderflutter/ui/page/settings_page.dart';
import 'package:moeloaderflutter/util/common_function.dart';
import 'package:moeloaderflutter/widget/main_masonry_grid.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:logging/logging.dart';
import 'package:to_json/models.dart' as jsonModels;
import '../viewmodel/view_model_home.dart';

class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  State<StatefulWidget> createState() => _MainState();
}

class _MainState extends State<MainPage> {
  final _log = Logger("_MainState");
  final HomeViewModel _homeViewModel = HomeViewModel();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        iconTheme: Theme.of(context).iconTheme,
        //导航栏
        title: _buildAppBatTitle(context),
        leading: IconButton(
          padding: const EdgeInsets.fromLTRB(15, 12, 0, 12),
          icon: Image.asset(
            'assets/images/icon_round.png',
          ),
          onPressed: null,
        ),
        actions: <Widget>[
          _buildSettingsAction(context),
        ],
      ),
      body: _buildBody(context),
    );
  }

  @override
  void initState() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      showDownloadOverlay(context);
    });
    super.initState();
  }

  Widget _buildBody(BuildContext context) {
    List<jsonModels.Rule> list = _homeViewModel.webPageList();
    Grid mainGrid = Global.multiPlatform.mainGrid();
    return MainMasonryGrid(
        list: list,
        columnCount: mainGrid.columnCount,
        aspectRatio: mainGrid.aspectRatio);
  }

  Widget _buildSettingsAction(BuildContext context) {
    return Padding(
      padding: appBarActionPadding(),
      child: IconButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) {
                return const SettingPage();
              }),
            );
          },
          icon: const Icon(Icons.settings)),
    );
  }

  _buildAppBatTitle(BuildContext context) {
    return const Center(
      child: Text(
        "站点",
        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
      ),
    );
  }

}
