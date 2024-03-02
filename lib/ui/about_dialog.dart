import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

void showAbout(BuildContext context) {
  showModalBottomSheet(
      context: context,
      builder: (context) {
        return SingleChildScrollView(
            padding: EdgeInsets.only(left: 10, top: 10, right: 10),
            child: Column(
              children: [
                ListTile(
                  title: const Text("MoeLoaderFlutter"),
                  leading: Icon(
                    Icons.title,
                    color: Theme.of(context).iconTheme.color,
                  ),
                ),
                ListTile(
                  title: const Text("V1.0.0"),
                  leading: Icon(
                    Icons.code,
                    color: Theme.of(context).iconTheme.color,
                  ),
                ),
                ListTile(
                  title: const Text("@2024 by Chihiro23333"),
                  leading: Icon(
                    Icons.timelapse,
                    color: Theme.of(context).iconTheme.color,
                  ),
                ),
                ListTile(
                  title: const Text("https://github.com/Chihiro23333"),
                  leading: Icon(
                    Icons.home,
                    color: Theme.of(context).iconTheme.color,
                  ),
                ),
              ],
            ));
      });
}
