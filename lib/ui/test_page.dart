import 'package:MoeLoaderFlutter/net/download.dart';
import 'package:MoeLoaderFlutter/ui/radio_choice_chip.dart';
import 'package:MoeLoaderFlutter/ui/url_list_dialog.dart';
import 'package:clipboard/clipboard.dart';
import 'package:extended_image/extended_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:MoeLoaderFlutter/init.dart';
import 'package:MoeLoaderFlutter/ui/about_dialog.dart';
import 'package:MoeLoaderFlutter/ui/common_function.dart';
import 'package:MoeLoaderFlutter/ui/settings_dialog.dart';
import 'package:MoeLoaderFlutter/ui/webview2_page.dart';
import 'package:MoeLoaderFlutter/yamlhtmlparser/models.dart';
import 'package:MoeLoaderFlutter/ui/view_model_home.dart';
import 'package:MoeLoaderFlutter/yamlhtmlparser/yaml_validator.dart';
import 'package:logging/logging.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:yaml/yaml.dart';
import '../utils/const.dart';
import '../utils/sharedpreferences_utils.dart';
import '../utils/utils.dart';
import '../yamlhtmlparser/yaml_parse_html_common.dart';
import '../yamlhtmlparser/yaml_reposotory.dart';
import '../yamlhtmlparser/yaml_rule_factory.dart';
import 'detail_page.dart';
import 'download_tasks_dialog.dart';
import 'info_dialog.dart';

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
    YamlHtmlCommonParser yamlHtmlCommonParser = YamlHtmlCommonParser();
    String sourceName = "yande.re.test";
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
                String json = await yamlHtmlCommonParser.commonParse(
                    data!, sourceName, "homePage");
                _log.fine("json=$json");
              },
            ),
            const Divider(height: 10,),
            ListTile(
              title: const Text("getOptions"),
              onTap: () async {
                String options = await yamlHtmlCommonParser.jsonOptionList(sourceName);
                _log.info("options=$options");
              },
            ),
            const Divider(height: 10,),
            ListTile(
              title: const Text("getJsonHeaders"),
              onTap: () async {
                String jsonHeaders = await yamlHtmlCommonParser.getJsonHeaders(sourceName);
                _log.info("jsonHeaders=$jsonHeaders");
              },
            ),
            const Divider(height: 10,),
            ListTile(
              title: const Text("getJsonHomeUrl"),
              onTap: () async {
                String jsonHomeUrl = await yamlHtmlCommonParser.getJsonHomeUrl(sourceName,"1");
                _log.info("jsonHomeUrl=$jsonHomeUrl");
              },
            ),
            const Divider(height: 10,),
            ListTile(
              title: const Text("getJsonSearchUrl"),
              onTap: () async {
                String jsonSearchUrl = await yamlHtmlCommonParser.getJsonSearchUrl(sourceName, "1", "tag");
                _log.info("jsonSearchUrl=$jsonSearchUrl");
              },
            ),
            const Divider(height: 10,),
            ListTile(
              title: const Text("getJsonName"),
              onTap: () async {
                String jsonName = await yamlHtmlCommonParser.getJsonName(sourceName);
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
        await repository.home("https://yande.re/post?page=1");
    if (result.validateSuccess) {
      _log.info("请求成功");
      await saveHtml(result.data!);
    } else {
      _log.info("请求失败");
    }
  }
}
