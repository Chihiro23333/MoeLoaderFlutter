import 'package:extended_image/extended_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:logging/logging.dart';
import '../init.dart';
import '../net/download.dart';
import '../ui/common_function.dart';
import '../ui/download_tasks_dialog.dart';
import '../ui/info_dialog.dart';
import '../ui/url_list_dialog.dart';
import '../ui/view_model_home.dart';
import '../utils/const.dart';
import '../utils/sharedpreferences_utils.dart';
import '../utils/utils.dart';
import '../yamlhtmlparser/models.dart';
import '../yamlhtmlparser/yaml_validator.dart';

typedef ExceptionActionCallback = void Function(HomeState homeState);
typedef ItemClickCallback = void Function(YamlHomePageItem yamlHomePageItem);

class PoolGrid extends StatefulWidget {
  const PoolGrid({
    super.key,
    required this.list,
    this.headers,
    this.itemOnPressed,
  });

  final List<YamlHomePageItem> list;
  final Map<String, String>? headers;
  final ItemClickCallback? itemOnPressed;

  @override
  State<StatefulWidget> createState() {
    return _PoolGridState();
  }
}

class _PoolGridState extends State<PoolGrid> {
  final _log = Logger("_PoolGridState");

  @override
  Widget build(BuildContext context) {
    return _buildGrid(widget.list, widget.headers);
  }

  Widget _buildGrid(List<YamlHomePageItem> list, Map<String, String>? headers) {
    int crossAxisCount = 1;
    double childAspectRatio = 16;
    double mainAxisSpacing = 10;
    return GridView.builder(
        itemCount: list.length,
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            childAspectRatio: childAspectRatio,
            mainAxisSpacing: mainAxisSpacing),
        itemBuilder: (BuildContext context, int index) {
          YamlHomePageItem yamlHomePageItem = list[index];
          MediaQueryData queryData = MediaQuery.of(context);
          double screenWidth = queryData.size.width;
          double height = screenWidth / childAspectRatio;
          return GestureDetector(
            child: _buildItem(context, yamlHomePageItem, screenWidth, height,
                index, crossAxisCount, headers),
            onTap: () async {
              var itemOnPressed = widget.itemOnPressed;
              if (itemOnPressed != null) {
                itemOnPressed(yamlHomePageItem);
              }
            },
          );
        });
  }

  Widget _buildItem(
      BuildContext context,
      YamlHomePageItem yamlHomePageItem,
      double width,
      double height,
      int index,
      int crossAxisCount,
      Map<String, String>? headers) {
    List<Widget> widgets = [];
    String url = yamlHomePageItem.url;
    double width = height * 16 / 9;
    if (url.isEmpty) {
      widgets.add(Container(
        width: width,
        height: height,
        color: Colors.grey,
        child: const SizedBox(
          child: Center(
            child: Text(
              "图集",
              style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  fontSize: 20),
            ),
          ),
        ),
      ));
    } else {
      widgets.add(ExtendedImage.network(
        shape: BoxShape.rectangle,
        headers: headers,
        width: width,
        height: height,
        yamlHomePageItem.url,
        fit: BoxFit.cover,
      ));
    }
    widgets.add(Expanded(
        child: Padding(
      padding: const EdgeInsets.all(10),
      child: Text(
        yamlHomePageItem.commonInfo?.desc ?? "暂无描述",
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        overflow: TextOverflow.ellipsis,
        maxLines: 2,
      ),
    )));
    return Container(
      color: Global.defaultColor30,
      child: Row(
        mainAxisSize: MainAxisSize.max,
        mainAxisAlignment: MainAxisAlignment.start,
        children: widgets,
      ),
    );
  }
}
