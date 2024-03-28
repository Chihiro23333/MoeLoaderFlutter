import 'dart:io';

import 'package:bot_toast/bot_toast.dart';
import 'package:flutter/material.dart';
import 'package:MoeLoaderFlutter/init.dart';
import 'package:MoeLoaderFlutter/ui/page/home_page.dart';

void main(List<String> args) {
  WidgetsFlutterBinding.ensureInitialized();
  Global().init().then((value) => runApp(const MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {

    return MaterialApp(
      title: 'MoeLoaderFlutter',
      builder: BotToastInit(),
        navigatorObservers: [BotToastNavigatorObserver()],
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Global.defaultColor),
        useMaterial3: true,
        fontFamily: Platform.isWindows ? "微软雅黑" : null,
      ),
      home: const HomePage()
    );
  }
}

