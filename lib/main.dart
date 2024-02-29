import 'package:bot_toast/bot_toast.dart';
import 'package:flutter/material.dart';
import 'package:FlutterMoeLoaderDesktop/init.dart';
import 'package:FlutterMoeLoaderDesktop/ui/home_page.dart';

void main(List<String> args) {
  WidgetsFlutterBinding.ensureInitialized();
  Global().init().then((value) => runApp(const MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    Color defaultColor = const Color.fromARGB(255, 46, 176, 242);
    return MaterialApp(
      title: 'FlutterMoeLoaderDesktop',
      builder: BotToastInit(),
        navigatorObservers: [BotToastNavigatorObserver()],
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: defaultColor),
        useMaterial3: true,
      ),
      home: const HomePage()
    );
  }
}

