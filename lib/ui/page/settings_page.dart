import 'package:moeloaderflutter/ui/viewmodel/view_model_setting.dart';
import 'package:moeloaderflutter/util/common_function.dart';
import 'package:moeloaderflutter/util/const.dart';
import 'package:moeloaderflutter/util/sharedpreferences_utils.dart';
import 'package:moeloaderflutter/widget/radio_choice_chip.dart';
import 'package:flutter/material.dart';
import 'package:moeloaderflutter/init.dart';
import 'package:logging/logging.dart';

class SettingPage extends StatefulWidget {
  const SettingPage({super.key});

  @override
  State<StatefulWidget> createState() {
    return _SettingState();
  }
}

class _SettingState extends State<SettingPage> {
  final _log = Logger("_SettingsInfo");

  final TextEditingController _textEditingControl = TextEditingController();
  String _dropdownValue = "";
  SettingViewModel _settingViewModel = SettingViewModel();

  Future<void> _setProxy(String text) async {
    await setProxy(text);
    Global().updateProxy();
  }

  void updateDropDownValue(String value) {
    setState(() {
      _dropdownValue = value;
    });
  }

  @override
  void initState() {
    super.initState();
    _settingViewModel.getCacheSetting();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<SettingState>(
        stream: _settingViewModel.streamSettingController.stream,
        builder: (BuildContext context, AsyncSnapshot snapshot) {
          if (snapshot.connectionState != ConnectionState.active) {
            return const SizedBox();
          }
          return Scaffold(
            body: _buildBody(context, snapshot),
            appBar: _buildAppBar(context),
          );
        });
  }

  AppBar _buildAppBar(BuildContext context) {
    return AppBar(
      title: const Text("设置"),
      iconTheme: Theme.of(context).iconTheme,
      elevation: 10,
    );
  }

  Widget _buildProxyInput(BuildContext context, SettingState settingState) {
    List<String> list = [Const.proxyHttp, Const.proxySocks5, Const.proxySocks4];
    String data = settingState.proxy ?? "";
    for (int i = 0; i < list.length; i++) {
      if (list[i] == data) {
        _dropdownValue = list[i];
      }
    }
    if (_dropdownValue.isEmpty) {
      _dropdownValue = Const.proxyHttp;
    }
    return Padding(
      padding: const EdgeInsets.fromLTRB(15, 15, 15, 5),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "代理设置：",
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10,),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _textEditingControl,
                  decoration: InputDecoration(
                      fillColor: Colors.white,
                      suffixIcon: Padding(
                        padding: const EdgeInsets.fromLTRB(0, 2, 8, 2),
                        child: FilledButton(
                          onPressed: () {
                            String text = _textEditingControl.text;
                            _log.fine("text=$text");
                            _setProxy(text);
                            showToast("更新代理成功");
                          },
                          child: const Text(
                            "保存",
                          ),
                        ),
                      ),
                      prefixIcon: Padding(
                        padding: const EdgeInsets.fromLTRB(10, 0, 0, 0),
                        child: DropdownButton<String>(
                          value: _dropdownValue,
                          icon: const Icon(Icons.arrow_drop_down),
                          onChanged: (String? value) async {
                            if (value != null) {
                              await setProxyType(value);
                              await Global().updateProxy();
                              updateDropDownValue(value);
                            }
                          },
                          iconSize: 20,
                          items: list
                              .map<DropdownMenuItem<String>>((String value) {
                            return DropdownMenuItem<String>(
                              value: value,
                              child: Text(value),
                            );
                          }).toList(),
                          underline: const SizedBox(
                            height: 0,
                          ),
                        ),
                      ),
                      border: const OutlineInputBorder(),
                      labelText: "请输入代理地址",
                      hintText: "请输入代理地址",
                      helperText: "示例:127.0.0.1:7890,输入地址后点击右侧按钮保存",
                      filled: true),
                  onSubmitted: (String value) {},
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFolderItem(BuildContext context, String title, String desc) {
    return ListTile(
      title: Text(title),
      subtitle: Text(desc),
    );
  }

  Widget _buildDefaultDownloadSize(
      BuildContext context, SettingState settingState) {
    List<String> list = [Const.choose, Const.preview, Const.big, Const.raw];
    String data = settingState.downloadFileSize ?? "";
    int selectedIndex = 0;
    for (int i = 0; i < list.length; i++) {
      if (list[i] == data) {
        selectedIndex = i;
      }
    }
    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 10, 15, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "下载选项：",
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10,),
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
  }

  _buildBody(BuildContext context, AsyncSnapshot snapshot) {
    SettingState? settingState = snapshot.data;
    if (settingState != null) {
      _textEditingControl.value = TextEditingValue(
        text: settingState.proxy ?? "",
      );
      return Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
              child: SingleChildScrollView(
                  child: Column(
            children: [
              _buildProxyInput(context, settingState),
              const Divider(
                height: 10,
              ),
              _buildDefaultDownloadSize(context, settingState),
              const Divider(
                height: 10,
              ),
              _buildFolderItem(
                  context, "自定义规则存储路径", Global.rulesDirectory.path),
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
              ListTile(
                title: const Text(
                  "MoeLoaderFlutter",
                  style: TextStyle(fontSize: 15),
                ),
                leading: Icon(
                  Icons.title,
                  color: Theme.of(context).iconTheme.color,
                ),
              ),
              const Divider(
                height: 10,
              ),
              ListTile(
                title: const Text(
                  "V1.0.4",
                  style: TextStyle(fontSize: 15),
                ),
                leading: Icon(
                  Icons.code,
                  color: Theme.of(context).iconTheme.color,
                ),
              ),
              const Divider(
                height: 10,
              ),
              ListTile(
                title: const Text(
                  "@2024 by Chihiro23333",
                  style: TextStyle(fontSize: 15),
                ),
                leading: Icon(
                  Icons.timelapse,
                  color: Theme.of(context).iconTheme.color,
                ),
              ),
              const Divider(
                height: 10,
              ),
              ListTile(
                title: const Text(
                  "https://github.com/Chihiro23333",
                  style: TextStyle(fontSize: 15),
                ),
                leading: Icon(
                  Icons.home,
                  color: Theme.of(context).iconTheme.color,
                ),
              ),
              const Divider(
                height: 10,
              ),
              ListTile(
                title: const Text(
                  "zhu.20081121@gmail.com",
                  style: TextStyle(fontSize: 15),
                ),
                leading: Icon(
                  Icons.mail,
                  color: Theme.of(context).iconTheme.color,
                ),
              ),
              const Divider(
                height: 10,
              ),
            ],
          )))
        ],
      );
    }
  }
}
