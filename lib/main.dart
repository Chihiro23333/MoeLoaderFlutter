import 'dart:io';
import 'package:moeloaderflutter/ui/page/main_page.dart';
import 'package:bot_toast/bot_toast.dart';
import 'package:flutter/material.dart';
import 'package:moeloaderflutter/init.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:moeloaderflutter/util/common_function.dart';

void main(List<String> args) {
  WidgetsFlutterBinding.ensureInitialized();
  Global().init().then((value) => runApp(const MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
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
            platform: TargetPlatform.iOS
          ),
          home: child,
        );
      },
      child: const MainPage(),
    );
  }
}