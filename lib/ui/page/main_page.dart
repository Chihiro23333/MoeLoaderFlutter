import 'package:MoeLoaderFlutter/ui/page/settings_page.dart';
import 'package:MoeLoaderFlutter/widget/main_masonry_grid.dart';
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
        actions: <Widget>[
          _buildSettingsAction(context),
        ],
      ),
      body: _buildBody(context),
    );
  }

  Widget _buildBody(BuildContext context) {
    List<jsonModels.Rule> list = _homeViewModel.webPageList();
    return MainMasonryGrid(list: list, columnCount: 3, aspectRatio: 5);
  }

  Widget _buildSettingsAction(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 0, 10, 0),
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
    return const Text(
      "站点",
      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
    );
  }
}
