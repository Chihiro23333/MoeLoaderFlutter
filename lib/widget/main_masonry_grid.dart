import 'package:flutter/cupertino.dart';
import 'package:moeloaderflutter/ui/page/home_page.dart';
import 'package:moeloaderflutter/util/common_function.dart';
import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:logging/logging.dart';
import 'package:to_json/models.dart';
import '../init.dart';
import '../ui/page/search_page.dart';

class MainMasonryGrid extends StatefulWidget {
  const MainMasonryGrid({
    super.key,
    required this.list,
    required this.columnCount,
    required this.aspectRatio,
    this.tagTapCallback,
  });

  final List<Rule> list;
  final TagTapCallback? tagTapCallback;
  final int columnCount;
  final double aspectRatio;

  @override
  State<StatefulWidget> createState() {
    return _MainMasonryGridState();
  }
}

class _MainMasonryGridState extends State<MainMasonryGrid> {
  final _log = Logger("_MainMasonryGridState");

  @override
  Widget build(BuildContext context) {
    return _buildMasonryGrid(widget.list);
  }

  Widget _buildMasonryGrid(List<Rule> list) {
    int crossAxisCount = widget.columnCount;
    return MasonryGridView.count(
        crossAxisCount: crossAxisCount,
        itemCount: list.length,
        itemBuilder: (BuildContext context, int index) {
          MediaQueryData queryData = MediaQuery.of(context);
          double screenWidth = queryData.size.width;
          Rule rule = list[index];
          double width = screenWidth / crossAxisCount;
          double scale = 1 / widget.aspectRatio;
          double maxScale = 2;
          _log.fine("before scale=$scale");
          if (scale > maxScale) scale = maxScale;
          _log.fine("after scale=$scale");
          double height = width * scale;
          Color loadingBackgroundColor = const Color.fromARGB(30, 46, 176, 242);
          return Padding(
            padding: const EdgeInsets.fromLTRB(8, 0, 8, 12),
            child: Container(
              width: width,
              height: 70,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(5),
                color: loadingBackgroundColor,
              ),
              child: _buildItem(
                  context, rule, index, crossAxisCount, width, height),
            ),
          );
        });
  }

  Widget _buildItem(BuildContext context, Rule rule, int index,
      int crossAxisCount, double width, double height) {
    List<Widget> rowList = [];
    rowList.add(SizedBox(
      height: 30,
      width: 50,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(10, 0, 10, 0),
        child: Global.multiPlatform.favicon(rule),
      ),
    ));
    rowList.add(Expanded(
        child: Text(
      rule.fileName,
      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
    )));
    if (rule.canSearch) {
      rowList.add(Padding(
        padding: const EdgeInsets.fromLTRB(0, 0, 8, 0),
        child: IconButton(
            onPressed: () async {
              await _updateCurWebPage(rule);
              Navigator.push(
                context,
                CupertinoPageRoute(builder: (context) {
                  return const SearchPage(
                    keyword: "",
                  );
                }),
              );
            },
            icon: const Icon(Icons.image_search)),
      ));
    }
    ;
    return GestureDetector(
      child: Stack(
        fit: StackFit.expand,
        children: [
          Align(
            alignment: Alignment.center,
            child: Row(
              children: rowList,
            ),
          ),
        ],
      ),
      onTap: () async {
        await _updateCurWebPage(rule);
        Navigator.push(
          context,
          CupertinoPageRoute(builder: (context) {
            return const HomePage();
          }),
        );
      },
    );
  }

  _updateCurWebPage(Rule rule) async {
    await Global().updateCurWebPage(rule);
  }
}
