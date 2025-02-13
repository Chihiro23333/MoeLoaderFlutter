import 'dart:io';
import 'package:flutter_screenutil/flutter_screenutil.dart';
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
            padding: const EdgeInsets.fromLTRB(8, 0, 8, 16),
            child: Container(
              width: width,
              height: height,
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
    List<Widget> actions = [];
    if (rule.canSearch) {
      actions.add(IconButton(
          onPressed: () async {
            await _updateCurWebPage(rule);
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) {
                return const SearchPage(
                  keyword: "",
                );
              }),
            );
          },
          icon: const Icon(Icons.image_search)));
    }
    actions.add(IconButton(
        onPressed: () async {
          await _updateCurWebPage(rule);
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) {
              return const HomePage();
            }),
          );
        },
        icon: const Icon(
          Icons.arrow_circle_right,
        )));
    return Stack(
      fit: StackFit.expand,
      children: [
        Align(
          alignment: Alignment.center,
          child: Row(
            children: [
              SizedBox(
                height: 35,
                width: 65,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(10, 0, 10, 0),
                  child: Global.multiPlatform.favicon(rule),
                ),
              ),
              Text(
                rule.fileName,
                style:
                    const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              )
            ],
          ),
        ),
        Positioned(
          right: 20,
          bottom: 10,
          child: Container(
            decoration: const BoxDecoration(
                borderRadius: BorderRadius.all(Radius.circular(20)),
                color: Colors.white70,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12,
                    spreadRadius: 5,
                    blurRadius: 20,
                    offset: Offset(0, 3), // 阴影的偏移量
                  )
                ]),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: actions,
            ),
          ),
        ),
      ],
    );
  }

  _updateCurWebPage(Rule rule) async {
    await Global().updateCurWebPage(rule);
  }
}
