import 'package:MoeLoaderFlutter/util/common_function.dart';
import 'package:flutter/material.dart';
import 'package:MoeLoaderFlutter/init.dart';
import 'package:logging/logging.dart';
import '../../net/download.dart';

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
    children.add(Chip(
      avatar: ClipOval(
        child: Icon(
          Icons.title,
          color: Theme.of(context).iconTheme.color,
        ),
      ),
      label: Text("文件存储路径：${Global.downloadsDirectory.path}"),
    ));
    return AppBar(
      title: FittedBox(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: children,
        ),
      ),
      iconTheme: Theme.of(context).iconTheme,
      elevation: 10,
    );
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
