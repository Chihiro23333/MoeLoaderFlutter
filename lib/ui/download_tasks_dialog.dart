import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../init.dart';
import '../net/download.dart';

void showDownloadTasks(BuildContext context) {
  showModalBottomSheet(
      context: context,
      builder: (context) {
        return SizedBox(
          height: 360,
          child: StreamBuilder<DownloadState>(
            initialData: DownloadManager().curState(),
            stream: DownloadManager().downloadStream(),
            builder: (BuildContext context, AsyncSnapshot snapshot) {
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
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: downloadProgress(progress),
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
            },
          ),
        );
      });
}

Widget downloadProgress(double progress) {
  return LinearProgressIndicator(
    value: progress,
    color: Global.defaultColor,
    minHeight: 5,
    borderRadius: BorderRadius.circular(20),
  );
}

Widget downloadStateIcon(BuildContext context, int downloadState) {
  Widget icon;
  switch (downloadState) {
    case DownloadTask.downloading:
      icon = SizedBox(
        width: 20,
        height: 20,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          color: Global.defaultColor,
        ),
      );
      break;
    case DownloadTask.complete:
      icon = Icon(
        Icons.file_download_done,
        color: Global.defaultColor,
      );
      break;
    case DownloadTask.error:
      icon = const Icon(
        Icons.close,
        color: Colors.red,
      );
      break;
    case DownloadTask.waiting:
      icon = Icon(
        Icons.more_time_outlined,
        color: Global.defaultColor,
      );
      break;
    case DownloadTask.idle:
    default:
      icon = Icon(
        Icons.file_download,
        color: Theme.of(context).iconTheme.color,
      );
  }
  return icon;
}
