import 'package:flutter/material.dart';
import 'package:MoeLoaderFlutter/init.dart';
import 'package:MoeLoaderFlutter/utils/sharedpreferences_utils.dart';
import 'package:logging/logging.dart';
import '../../utils/const.dart';
import '../../widget/radio_choice_chip.dart';
import '../../utils/common_function.dart';

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
            child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildProxyInput(context),
            const Divider(
              height: 10,
            ),
            _buildFolderItem(context, "自定义规则存储路径", Global.rulesDirectory.path),
            const Divider(
              height: 10,
            ),
            _buildFolderItem(
                context, "下载文件保存路径", Global.downloadsDirectory.path),
            const Divider(
              height: 10,
            ),
            _buildFolderItem(context, "数据库缓存路径", Global.hiveDirectory.path),
            const Divider(
              height: 10,
            ),
            _buildDefaultDownloadSize(context),
          ],
        ));
      });
}

Widget _buildProxyInput(BuildContext context) {
  return FutureBuilder(
      future: getProxyType(),
      builder: (context, snapshot) {
        _log.fine("snapshot=$snapshot");
        ConnectionState connectionState = snapshot.connectionState;
        if (connectionState == ConnectionState.done) {
          List<String> list = [
            Const.proxyHttp,
            Const.proxySocks5,
            Const.proxySocks4
          ];
          String data = snapshot.data ?? "";
          int selectedIndex = 0;
          for (int i = 0; i < list.length; i++) {
            if (list[i] == data) {
              selectedIndex = i;
            }
          }
          return Padding(
            padding: const EdgeInsets.fromLTRB(15, 20, 15, 5),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _textEditingControl,
                        decoration: InputDecoration(
                            suffixIcon: Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Padding(
                                    padding:
                                        const EdgeInsets.fromLTRB(0, 0, 15, 0),
                                    child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.start,
                                        children: [
                                          RadioChoiceChip(
                                              list: list,
                                              index: selectedIndex,
                                              radioSelectCallback:
                                                  (index, desc) async {
                                                _log.fine(
                                                    "index=$index;desc=$desc");
                                                await setProxyType(desc);
                                                await Global().updateProxy();
                                              }),
                                        ])),
                              ],
                            ),
                            border: const OutlineInputBorder(),
                            labelText: "请输入代理地址",
                            hintText: "请输入代理地址",
                            helperText: "示例:127.0.0.1:7890,输入地址后点击右侧按钮保存",
                            filled: true),
                        onSubmitted: (String value) {},
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(10, 0, 10, 20),
                      child: IconButton(
                        onPressed: () {
                          String text = _textEditingControl.text;
                          _log.fine("text=$text");
                          _setProxy(text);
                          showToast("更新代理成功");
                        },
                        icon: const Icon(Icons.save),
                      ),
                    )
                  ],
                ),
              ],
            ),
          );
        } else {
          return const SizedBox();
        }
      });
}

Widget _buildFolderItem(BuildContext context, String title, String desc) {
  return ListTile(
    title: Text(title),
    subtitle: Text(desc),
  );
}

Widget _buildDefaultDownloadSize(BuildContext context) {
  return FutureBuilder(
      future: getDownloadFileSize(),
      builder: (context, snapshot) {
        _log.fine("snapshot=$snapshot");
        ConnectionState connectionState = snapshot.connectionState;
        if (connectionState == ConnectionState.done) {
          List<String> list = [
            Const.choose,
            Const.preview,
            Const.big,
            Const.raw
          ];
          String data = snapshot.data ?? "";
          int selectedIndex = 0;
          for (int i = 0; i < list.length; i++) {
            if (list[i] == data) {
              selectedIndex = i;
            }
          }
          return Padding(
            padding: const EdgeInsets.fromLTRB(15, 10, 15, 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                const Text(
                  "下载方式：",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                RadioChoiceChip(
                    list: list,
                    index: selectedIndex,
                    radioSelectCallback: (index, desc) {
                      _log.fine("index=$index;desc=$desc");
                      setDownloadFileSize(desc);
                    })
              ],
            ),
          );
        } else {
          return const SizedBox();
        }
      });
}
