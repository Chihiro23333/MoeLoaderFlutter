import 'dart:async';
import 'package:moeloaderflutter/util/sharedpreferences_utils.dart';
import 'package:logging/logging.dart';

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
