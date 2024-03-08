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
                if(list.isEmpty){
                  return const Center(
                    child: Text("下载列表为空"),
                  );
                }
                return ListView.separated(
                  itemCount: list.length,
                  itemBuilder: (BuildContext context, int index) {
                    DownloadTask downloadTask = list[index];
                    int downloadState = downloadTask.downloadState;
                    Widget subtitle = const LinearProgressIndicator(value: 0);
                    Widget leading = Icon(
                      Icons.file_download,
                      color: Theme.of(context).iconTheme.color,
                    );
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
                      subtitle = const LinearProgressIndicator(value: 100);
                      leading = Icon(
                        Icons.file_download_done,
                        color: Global.defaultColor,
                      );
                    } else if(downloadState == DownloadTask.error){
                      leading = const Icon(
                        Icons.close,
                        color: Colors.red,
                      );
                    }
                    return ListTile(
                      leading: leading,
                      title: Text(downloadTask.name),
                      subtitle: subtitle,
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