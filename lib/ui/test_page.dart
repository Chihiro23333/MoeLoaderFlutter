import 'package:MoeLoaderFlutter/yamlhtmlparser/parser_factory.dart';
import 'package:flutter/material.dart';
import 'package:MoeLoaderFlutter/yamlhtmlparser/yaml_validator.dart';
import 'package:logging/logging.dart';
import '../utils/sharedpreferences_utils.dart';
import '../yamlhtmlparser/yaml_reposotory.dart';

class TestPage extends StatefulWidget {
  const TestPage({super.key});

  @override
  State<StatefulWidget> createState() => _TestState();
}

class _TestState extends State<TestPage> {
  final _log = Logger("_TestState");
  final YamlRepository repository = YamlRepository();

  @override
  Widget build(BuildContext context) {
    Parser parser = ParserFactory().createParser();
    String sourceName = "pixiv.net.test";
    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          children: [
            ListTile(
              title: const Text("获取并缓存数据"),
              onTap: () {
                getAndCacheData();
              },
            ),
            const Divider(height: 10,),
            ListTile(
              title: const Text("parseHomePage"),
              onTap: () async {
                String? data = await getHtml();
                String json = await parser.parseUseYaml(
                    data!, sourceName, "homePage");
                _log.info("json=$json");
              },
            ),
            const Divider(height: 10,),
            ListTile(
              title: const Text("getOptions"),
              onTap: () async {
                String options = await parser.options(sourceName);
                _log.info("options=$options");
              },
            ),
            const Divider(height: 10,),
            ListTile(
              title: const Text("getJsonHeaders"),
              onTap: () async {
                String jsonHeaders = await parser.headers(sourceName);
                _log.info("jsonHeaders=$jsonHeaders");
              },
            ),
            const Divider(height: 10,),
            ListTile(
              title: const Text("getJsonHomeUrl"),
              onTap: () async {
                String jsonHomeUrl = await parser.homeUrl(sourceName,"1");
                _log.info("jsonHomeUrl=$jsonHomeUrl");
              },
            ),
            const Divider(height: 10,),
            ListTile(
              title: const Text("getJsonSearchUrl"),
              onTap: () async {
                String jsonSearchUrl = await parser.searchUrl(sourceName, "1", "tag");
                _log.info("jsonSearchUrl=$jsonSearchUrl");
              },
            ),
            const Divider(height: 10,),
            ListTile(
              title: const Text("getJsonName"),
              onTap: () async {
                String jsonName = await parser.webPageName(sourceName);
                _log.info("jsonName=$jsonName");
              },
            ),
          ],
        ),
      ),
    );
  }

  getAndCacheData() async {
    ValidateResult<String> result =
        await repository.home("https://www.pixiv.net/ranking.php?p=1&format=json&mode=daily");
    if (result.validateSuccess) {
      _log.info("请求成功");
      await saveHtml(result.data!);
    } else {
      _log.info("请求失败");
    }
  }
}
