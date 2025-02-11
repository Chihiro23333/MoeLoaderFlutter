import 'dart:io';

import 'package:logging/logging.dart';
import 'package:moeloaderflutter/multiplatform/multi_platform.dart';

class MultiPlatformFactory {

  final _log = Logger("MultiPlatformFactory");

  static MultiPlatformFactory? _cache;

  MultiPlatformFactory._create();

  factory MultiPlatformFactory() {
    return _cache ?? (_cache = MultiPlatformFactory._create());
  }

  MultiPlatform create(){
    if(Platform.isWindows){
      return PlatformWindows();
    }
    if(Platform.isAndroid){
      return PlatformAndroid();
    }
    return PlatformNothing();
  }

}