import 'package:extended_image/extended_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import '../init.dart';
import '../ui/viewmodel/view_model_home.dart';
import '../yamlhtmlparser/models.dart';

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
    int crossAxisCount = Global.poolListColumnCount;
    double childAspectRatio = Global.poolListAspectRatio;
    double mainAxisSpacing = 10;
    double crossAxisSpacing = 10;
    return GridView.builder(
        itemCount: list.length,
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: crossAxisSpacing,
            childAspectRatio: childAspectRatio,
            mainAxisSpacing: mainAxisSpacing),
        itemBuilder: (BuildContext context, int index) {
          YamlHomePageItem yamlHomePageItem = list[index];
          MediaQueryData queryData = MediaQuery.of(context);
          double screenWidth = queryData.size.width -
              20 -
              crossAxisCount * (crossAxisSpacing - 1);
          _log.fine("screenWidth=$screenWidth");
          double width = screenWidth / crossAxisCount;
          _log.fine("width=$width");
          double height = (width / childAspectRatio);
          _log.fine("height=$height");
          return GestureDetector(
            child: _buildItem(context, yamlHomePageItem, width, height, index,
                crossAxisCount, headers),
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
    const double padding = 6;
    double descH = padding * 2 + 62;
    double imageH = height - descH;
    if (url.isEmpty) {
      widgets.add(Container(
        decoration: BoxDecoration(
          borderRadius: const BorderRadius.all(Radius.circular(5)),
          color: Global.defaultColor30,
        ),
        width: width,
        height: imageH,
        child: const SizedBox(
          child: Center(
            child: Text(
              "图集",
              style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                  fontSize: 18),
            ),
          ),
        ),
      ));
    } else {
      widgets.add(ExtendedImage.network(
        borderRadius: const BorderRadius.all(Radius.circular(5)),
        shape: BoxShape.rectangle,
        headers: headers,
        width: width,
        height: imageH,
        yamlHomePageItem.url,
        fit: BoxFit.cover,
      ));
    }
    widgets.add(SizedBox(
      height: descH,
      child: Padding(
        padding: const EdgeInsets.all(padding),
        child: Text(
          yamlHomePageItem.commonInfo?.desc ?? "暂无描述",
          overflow: TextOverflow.ellipsis,
          maxLines: 3,
        ),
      ),
    ));
    return Container(
      decoration: BoxDecoration(
        borderRadius: const BorderRadius.all(Radius.circular(5)),
        color: Global.defaultColor30,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: widgets,
      ),
    );
  }
}
