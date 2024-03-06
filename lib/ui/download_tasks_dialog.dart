import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../net/download.dart';

void showDownloadTasks(BuildContext context) {
  showModalBottomSheet(
      context: context,
      builder: (context) {
        return StreamBuilder<DownloadState>(
          initialData: DownloadManager().curState(),
          stream: DownloadManager().downloadStream(),
          builder: (BuildContext context, AsyncSnapshot snapshot) {
            bool hasData = snapshot.hasData;
            if (hasData) {
              DownloadState downloadState = snapshot.data;
              List<DownloadTask> list = downloadState.tasks;
              return ListView.separated(
                itemCount: list.length,
                itemBuilder: (BuildContext context, int index) {
                  DownloadTask downloadTask = list[index];
                  int downloadState = downloadTask.downloadState;
                  Widget subtitle = const Text("等待下载");
                  if (downloadState == DownloadTask.downloading) {
                    int count = downloadTask.count;
                    int total = downloadTask.total;
                    print("count=$count;total=$total");
                    double progress = 0;
                    if (total > 0) {
                      progress = count / total;
                    }
                    subtitle = LinearProgressIndicator(value: progress);
                  } else if (downloadState == DownloadTask.complete) {
                    subtitle = const Text("已下载");
                  }
                  return ListTile(
                    leading: Icon(
                      Icons.image,
                      color: Theme.of(context).iconTheme.color,
                    ),
                    title: Text(downloadTask.name),
                    subtitle: subtitle,
                  );
                },
                separatorBuilder: (BuildContext context, int index) {
                  return const Divider(height: 10);
                },
              );
            } else {
              return const CircularProgressIndicator();
            }
          },
        );
      });
}