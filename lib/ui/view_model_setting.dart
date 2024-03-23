import 'dart:async';
import 'package:MoeLoaderFlutter/net/download.dart';
import 'package:MoeLoaderFlutter/utils/sharedpreferences_utils.dart';
import 'package:MoeLoaderFlutter/yamlhtmlparser/parser_factory.dart';
import 'package:MoeLoaderFlutter/init.dart';
import 'package:MoeLoaderFlutter/yamlhtmlparser/yaml_reposotory.dart';
import 'package:MoeLoaderFlutter/yamlhtmlparser/yaml_rule_factory.dart';
import 'package:MoeLoaderFlutter/yamlhtmlparser/yaml_validator.dart';
import 'package:logging/logging.dart';
import 'package:yaml/yaml.dart';
import '../utils/utils.dart';
import '../yamlhtmlparser/models.dart';

class SettingViewModel{

  final _log = Logger('SettingViewModel');

  final StreamController<SettingState> streamSettingController = StreamController();
  final SettingState _settingState = SettingState();

  SettingViewModel();

  void getCacheSetting() async {
    changeDetailLoading(true);
    String? proxy = await getProxy();
    String? downloadFileSize = await getDownloadFileSize();
    _settingState.proxy = proxy;
    _settingState.downloadFileSize = downloadFileSize;
    streamSettingController.add(_settingState);
    changeDetailLoading(false);
  }

  void changeDetailLoading(bool loading) {
    _settingState.loading = loading;
    streamSettingController.add(_settingState);
  }

  void download(String id, String url, CommonInfo? commonInfo) {
    DownloadManager().addTask(DownloadTask(id, url, getDownloadName(url, commonInfo)));
  }

  void close(){
    streamSettingController.close();
  }
}

class SettingState {
  bool loading = true;
  String? proxy;
  String? downloadFileSize;

  SettingState();
}
