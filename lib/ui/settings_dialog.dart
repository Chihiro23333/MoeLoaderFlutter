import 'package:flutter/material.dart';
import 'package:FlutterMoeLoaderDesktop/init.dart';
import 'package:FlutterMoeLoaderDesktop/utils/sharedpreferences_utils.dart';
import 'package:logging/logging.dart';
import 'common_function.dart';

final TextEditingController _textEditingControl = TextEditingController();
final _log = Logger("_SettingsInfo");

Future<void> _setProxy(String text) async {
  await setProxy(text);
  Global().updateProxy();
}

Future<void> _fillLocalProxy() async {
  String localProxy = await getProxy() ?? "";
  _textEditingControl.value = TextEditingValue(
    text: localProxy,
  );
}

void showSettings(BuildContext context) {
  _fillLocalProxy();
  showModalBottomSheet(
      context: context,
      builder: (context) {
        return SingleChildScrollView(
            padding: const EdgeInsets.only(left: 10, top: 10, right: 10),
            child: Column(
              children: [
                _buildProxyInput(context),
                _buildFolderItem(
                    context, "自定义规则存储路径", Global.rulesDirectory.path),
                _buildFolderItem(
                    context, "下载文件保存路径", Global.downloadsDirectory.path),
                _buildFolderItem(
                    context, "数据库缓存路径", Global.hiveDirectory.path),
              ],
            ));
      });
}

Widget _buildProxyInput(BuildContext context) {
  return Padding(
    padding: const EdgeInsets.only(top: 10),
    child: Row(
      children: [
        Expanded(
          child: TextField(
            controller: _textEditingControl,
            decoration: InputDecoration(
                prefixIcon: Icon(
                  Icons.settings,
                  color: Theme.of(context).iconTheme.color,
                ),
                suffixIcon: GestureDetector(
                  child: Icon(
                    Icons.save,
                    color: Theme.of(context).iconTheme.color,
                  ),
                  onTap: () {
                    String text = _textEditingControl.text;
                    _log.fine("text=$text");
                    _setProxy(text);
                    showToast("更新代理成功");
                  },
                ),
                border: const OutlineInputBorder(),
                labelText: "请输入代理地址",
                hintText: "请输入代理地址",
                helperText: "示例:127.0.0.1:7890,输入地址后点击右侧按钮保存",
                filled: true),
            onSubmitted: (String value) {},
          ),
        )
      ],
    ),
  );
}

Widget _buildFolderItem(BuildContext context, String title, String desc) {
  return ListTile(
    title: Text(title),
    subtitle: Text(desc),
    leading: Icon(
      Icons.folder_copy,
      color: Theme.of(context).iconTheme.color,
    ),
  );
}
