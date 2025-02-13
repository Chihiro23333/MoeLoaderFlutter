import 'dart:io';
import 'package:moeloaderflutter/net/download.dart';
import 'package:moeloaderflutter/ui/common/common.dart';
import 'package:moeloaderflutter/util/common_function.dart';
import 'package:clipboard/clipboard.dart';
import 'package:flutter/material.dart';
import 'package:moeloaderflutter/init.dart';
import 'package:logging/logging.dart';

class DownloadPage extends StatefulWidget {
  const DownloadPage({super.key});

  @override
  State<StatefulWidget> createState() {
    return _DownloadState();
  }
}

class _DownloadState extends State<DownloadPage> {
  final _log = Logger("_DownloadState");

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DownloadState>(
        initialData: DownloadManager().curState(),
        stream: DownloadManager().downloadStream(),
        builder: (BuildContext context, AsyncSnapshot snapshot) {
          return Scaffold(
            body: _buildBody(context, snapshot),
            appBar: _buildAppBar(context),
          );
        });
  }

  AppBar _buildAppBar(BuildContext context) {
    List<Widget> children = [];
    children.add(const Text("下载列表"));
    return AppBar(
      title: FittedBox(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: children,
        ),
      ),
      iconTheme: Theme.of(context).iconTheme,
      elevation: 10,
      actions: [_buildInfoAction(context)],
    );
  }

  Widget _buildInfoAction(BuildContext context) {
    return IconButton(
        onPressed: () {
          showModalBottomSheet(
              context: context,
              builder: (context) {
                return SingleChildScrollView(
                  child: Padding(
                    padding:
                    const EdgeInsets.only(left: 10, right: 10, top: 10, bottom: 10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Padding(
                          padding: EdgeInsets.only(top: 10, bottom: 10),
                          child: Text(
                            "下载存储路径：",
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                        buildUrlWidget(context, Global.downloadsDirectory.path)
                      ],
                    ),
                  ),
                );
              });
        },
        icon: const Icon(Icons.info));
  }

  Widget _buildCopyAction(BuildContext context) {
    return IconButton(
        onPressed: () async {
          FlutterClipboard.copy(Global.downloadsDirectory.path).then((value) => showToast("存储路径已复制"));
        },
        icon: const Icon(Icons.copy));
  }

  _buildBody(BuildContext context, AsyncSnapshot snapshot) {
    bool hasData = snapshot.hasData;
    if (hasData) {
      DownloadState downloadState = snapshot.data;
      List<DownloadTask> list = downloadState.tasks;
      if (list.isEmpty) {
        return const Center(
          child: Text("下载列表为空"),
        );
      }
      return ListView.separated(
        itemCount: list.length,
        itemBuilder: (BuildContext context, int index) {
          DownloadTask downloadTask = list[index];
          int downloadState = downloadTask.downloadState;
          double progress = 0;
          if (downloadState == DownloadTask.downloading) {
            int count = downloadTask.count;
            int total = downloadTask.total;
            if (total > 0) {
              progress = count / total;
            }
          } else if (downloadState == DownloadTask.complete) {
            progress = 100;
          } else if (downloadState == DownloadTask.error) {}
          return ListTile(
            leading: downloadStateIcon(context, downloadState),
            title: Text(
              downloadTask.name,
            ),
            subtitle: downloadProgress(progress),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                    onPressed: () async {
                      DownloadManager().retryTask(downloadTask);
                    },
                    icon: const Icon(Icons.replay_circle_filled)),
                IconButton(
                    onPressed: () async {
                      DownloadManager().cancelTask(downloadTask);
                    },
                    icon: const Icon(Icons.cancel))
              ],
            ),
          );
        },
        separatorBuilder: (BuildContext context, int index) {
          return const Divider(height: 10);
        },
      );
    } else {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }
  }

  Widget downloadProgress(double progress) {
    return LinearProgressIndicator(
      value: progress,
      color: Global.defaultColor,
      minHeight: 5,
      borderRadius: BorderRadius.circular(20),
    );
  }
}
