import 'dart:io';
import 'package:logging/logging.dart';
import 'package:moeloaderflutter/ui/page/main_page.dart';
import 'package:bot_toast/bot_toast.dart';
import 'package:flutter/material.dart';
import 'package:moeloaderflutter/init.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

void main(List<String> args) {
  WidgetsFlutterBinding.ensureInitialized();
  Global().init().then((value) => runApp(MyApp()));
}

class MyApp extends StatelessWidget {

  final _log = Logger("MyApp");

  MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    _printInfo(context);
    return ScreenUtilInit(
      designSize: Global.multiPlatform.designSize(),
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (context, child) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'MoeLoader',
          builder: BotToastInit(),
          navigatorObservers: [BotToastNavigatorObserver()],
          // You can use the library anywhere in the app even in theme
          theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(seedColor: Global.defaultColor),
            useMaterial3: true,
            fontFamily: Platform.isWindows ? "微软雅黑" : null,
          ),
          home: child,
        );
      },
      child: const MainPage(),
    );
  }

  void _printInfo(BuildContext context) {
    double width = MediaQuery.of(context).size.width;
    double height = MediaQuery.of(context).size.height;
    _log.fine("width=${width};height=${height}");
  }
}