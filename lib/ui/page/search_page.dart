import 'dart:io';
import 'package:MoeLoaderFlutter/init.dart';
import 'package:MoeLoaderFlutter/ui/page/result_list_page.dart';
import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import 'package:to_json/models.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({super.key, required this.keyword});

  final String keyword;

  @override
  State<StatefulWidget> createState() {
    return _SearchState();
  }
}

class _SearchState extends State<SearchPage> {
  final _log = Logger("_SearchState");

  late TextEditingController _textEditingControl;
  final String _searchPageName = "searchPage";

  @override
  void initState() {
    super.initState();
    _textEditingControl = TextEditingController();
    _textEditingControl.value = TextEditingValue(text: widget.keyword);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _buildBody(context),
      appBar: _buildAppBar(context),
    );
  }

  AppBar _buildAppBar(BuildContext context) {
    return AppBar(
      title: const Text(
        "搜索",
        style: TextStyle(fontSize: 18),
      ),
      iconTheme: Theme.of(context).iconTheme,
      elevation: 10,
    );
  }

  _buildBody(BuildContext context) {
    Rule rule = Global.curWebPage.rule;
    Widget leading;
    if (rule.faviconPath.isEmpty) {
      leading = Icon(
        Icons.call_to_action,
        color: Theme.of(context).iconTheme.color,
      );
    } else {
      leading = Image.file(
        File(rule.faviconPath),
        fit: BoxFit.cover,
      );
    }
    return Center(
      heightFactor: 4.5,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                height: 35,
                width: 35,
                child: leading,
              ),
              const SizedBox(
                width: 12,
              ),
              Text(
                rule.fileName,
                style:
                    const TextStyle(fontSize: 25, fontWeight: FontWeight.bold),
              )
            ],
          ),
          const SizedBox(
            height: 20,
          ),
          SizedBox(
            width: 450,
            child: TextField(
              controller: _textEditingControl,
              decoration: InputDecoration(
                  suffixIcon: Padding(
                    padding: const EdgeInsets.fromLTRB(0, 0, 8, 0),
                    child: FilledButton(
                      onPressed: () {
                        _submit(context);
                      },
                      child: const Text(
                        "搜索",
                        style: TextStyle(fontSize: 15),
                      ),
                    ),
                  ),
                  border: const OutlineInputBorder(),
                  labelText: "请输入关键词",
                  helperText: "输入后按ENTER/或者点击搜索按钮",
                  labelStyle: const TextStyle(
                    fontSize: 14,
                  ),
                  filled: true),
              onSubmitted: (String value) {
                _submit(context);
              },
            ),
          ),
        ],
      ),
    );
  }

  void _submit(BuildContext context) {
    Navigator.of(context).pop();
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) {
        return ResultListPage(
          pageName: _searchPageName,
          keyword: _textEditingControl.text,
        );
      }),
    );
  }
}
