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
    String sourceName = "pixiv.net.test";
    List<Widget> widgets = [];
    widgets.add(const Divider(height: 10,));
    widgets.add(ActionChip(
        label: const Text("获取并缓存数据"),
        onPressed: () {
          getAndCacheData();
        }));
    widgets.add(const Divider(height: 10,));
    widgets.add(ActionChip(
        label: const Text("parseHomePage"),
        onPressed: () async {
          String? data = await getHtml();
          String json =
              await parser.parseUseYaml(data!, sourceName, "homePage");
          updateResult(json);
        }));
    widgets.add(const Divider(height: 10,));
    widgets.add(ActionChip(
        label: const Text("getOptions"),
        onPressed: () async {
          String options = await parser.options(sourceName);
          updateResult(options);
        }));
    widgets.add(const Divider(height: 10,));
    widgets.add(ActionChip(
        label: const Text("getJsonHeaders"),
        onPressed: () async {
          String jsonHeaders = await parser.headers(sourceName);
          updateResult(jsonHeaders);
        }));
    widgets.add(const Divider(height: 10,));
    widgets.add(ActionChip(
        label: const Text("getJsonHomeUrl"),
        onPressed: () async {
          String jsonHomeUrl = await parser.homeUrl(sourceName, "1");
          updateResult('{"jsonHomeUrl":"$jsonHomeUrl"}');
        }));
    widgets.add(const Divider(height: 10,));
    widgets.add(ActionChip(
        label: const Text("getJsonSearchUrl"),
        onPressed: () async {
          String jsonSearchUrl = await parser.searchUrl(sourceName, "1", "tag");
          updateResult('{"jsonSearchUrl":"$jsonSearchUrl"}');
        }));
    widgets.add(const Divider(height: 10,));
    widgets.add(ActionChip(
        label: const Text("getJsonName"),
        onPressed: () async {
          String jsonName = await parser.webPageName(sourceName);
          updateResult('{"name":"$jsonName"}');
        }));
    widgets.add(const Divider(height: 10,));
    return Scaffold(
      body: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            color: Colors.amberAccent,
            width: 150,
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
                theme: const JsonViewTheme(viewType: JsonViewType.base),),
          )
        ],
      ),
    );
  }

  getAndCacheData() async {
    ValidateResult<String> result = await repository
        .home("https://www.pixiv.net/ranking.php?p=1&format=json&mode=daily");
    if (result.validateSuccess) {
      _log.info("请求成功");
      await saveHtml(result.data!);
    } else {
      _log.info("请求失败");
    }
  }
}
