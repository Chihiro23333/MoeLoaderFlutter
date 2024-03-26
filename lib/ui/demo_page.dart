import 'dart:convert';
import 'package:MoeLoaderFlutter/yamlhtmlparser/parser_factory.dart';
import 'package:flutter/material.dart';
import 'package:MoeLoaderFlutter/yamlhtmlparser/yaml_validator.dart';
import 'package:flutter_json_view/flutter_json_view.dart';
import 'package:logging/logging.dart';
import '../utils/sharedpreferences_utils.dart';
import '../yamlhtmlparser/yaml_reposotory.dart';

class DemoPage extends StatefulWidget {
  const DemoPage({super.key});

  @override
  State<StatefulWidget> createState() => _TestState();
}

class _TestState extends State<DemoPage> {
  final _log = Logger("_TestState");
  final YamlRepository repository = YamlRepository();
  String _result = "{}";

  void updateResult(String result) {
    setState(() {
      _result = result;
    });
  }

  @override
  Widget build(BuildContext context) {
    Parser parser = ParserFactory().createParser();
    String sourceName = "yande_common";
    String pageName = "homePage";
    List<Widget> widgets = [];
    widgets.add(const SizedBox(
      height: 10,
    ));
    widgets.add(ActionChip(
        label: const Text("获取并缓存数据"),
        onPressed: () async {
          Map<String, String> params = {};
          params["page"] = "1";
          params["rating"] = "rating%3Asafe+";
          String result = await parser.url(sourceName, pageName, "home", params);
          var jsonResult = jsonDecode(result);
          ValidateResult<String> html =
              await repository.home(jsonResult["data"]);
          String? data = html.data;
          if (html.validateSuccess) {
            _log.info("请求成功");
            await saveHtml(sourceName, data.toString());
            updateResult('{"content":"请求成功"}');
          } else {
            _log.info("请求失败");
            updateResult('{"content":"请求失败"}');
          }
        }));
    widgets.add(const SizedBox(
      height: 10,
    ));
    widgets.add(ActionChip(
        label: const Text("parseHomePage"),
        onPressed: () async {
          String? data = await getHtml(sourceName);
          String json = await parser.parseUseYaml(data!, sourceName, pageName);
          updateResult(json);
        }));
    widgets.add(const SizedBox(
      height: 10,
    ));
    widgets.add(ActionChip(
        label: const Text("getOptions"),
        onPressed: () async {
          String options = await parser.options(sourceName, pageName, "home");
          updateResult(options);
        }));
    widgets.add(const SizedBox(
      height: 10,
    ));
    widgets.add(ActionChip(
        label: const Text("getJsonHeaders"),
        onPressed: () async {
          String jsonHeaders = await parser.headers(sourceName);
          updateResult(jsonHeaders);
        }));
    widgets.add(const SizedBox(
      height: 10,
    ));
    widgets.add(ActionChip(
        label: const Text("searchUrl"),
        onPressed: () async {
          Map<String, String> params = {};
          params["page"] = "1";
          params["rating"] = "rating%3Asafe+";
          String jsonHomeUrl =
              await parser.url(sourceName, pageName, "search", params);
          updateResult(jsonHomeUrl);
        }));
    widgets.add(const SizedBox(
      height: 10,
    ));
    widgets.add(ActionChip(
        label: const Text("homeUrl"),
        onPressed: () async {
          Map<String, String> params = {};
          params["page"] = "1";
          params["rating"] = "rating%3Asafe+";
          String jsonHomeUrl =
          await parser.url(sourceName, pageName, "home", params);
          updateResult(jsonHomeUrl);
        }));
    widgets.add(const SizedBox(
      height: 10,
    ));
    widgets.add(ActionChip(
        label: const Text("getJsonName"),
        onPressed: () async {
          String jsonName = await parser.webPageName(sourceName);
          updateResult(jsonName);
        }));
    widgets.add(const SizedBox(
      height: 10,
    ));
    widgets.add(ActionChip(
        label: const Text("displayInfo"),
        onPressed: () async {
          String jsonName = await parser.displayInfo(sourceName, pageName);
          updateResult(jsonName);
        }));
    widgets.add(const SizedBox(
      height: 10,
    ));
    return Scaffold(
      body: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            color: Colors.purple.shade50,
            width: 160,
            height: double.infinity,
            child: SingleChildScrollView(
              child: Column(
                children: widgets,
              ),
            ),
          ),
          Expanded(
            child: JsonView.string(
              _result,
              theme: const JsonViewTheme(viewType: JsonViewType.base),
            ),
          )
        ],
      ),
    );
  }
}
