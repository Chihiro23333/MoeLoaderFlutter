import 'package:flutter/material.dart';
import 'package:logging/logging.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<StatefulWidget> createState() {
    return _SearchState();
  }
}

class _SearchState extends State<SearchPage> {
  final _log = Logger("_SearchState");

  late TextEditingController _textEditingControl;

  @override
  void initState() {
    super.initState();
    _textEditingControl = TextEditingController();
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
      title: const Text("搜索"),
      iconTheme: Theme.of(context).iconTheme,
      elevation: 10,
    );
  }

  _buildBody(BuildContext context) {
    return Center(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 300,
            child: TextField(
                controller: _textEditingControl,
                decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    labelText: "请输入关键词",
                    filled: true),
                onSubmitted: (String value) {}),
          ),
          ElevatedButton(onPressed: () {},
              child: Text("搜索"),)
        ],
      ),
    );
  }
}
