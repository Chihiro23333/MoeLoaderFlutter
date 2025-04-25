import 'package:moeloaderflutter/net/download.dart';
import 'package:moeloaderflutter/ui/common/common.dart';
import 'package:moeloaderflutter/ui/common/ui_const.dart';
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
    children.add(const Text(
      "下载列表",
      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
    ));
    return AppBar(
      toolbarHeight: UIConst.toolbarHeight,
      titleSpacing: 0,
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
    return Padding(
        padding: appBarActionPadding(),
        child: IconButton(
            onPressed: () {
              showModalBottomSheet(
                  context: context,
                  builder: (context) {
                    return SingleChildScrollView(
                      child: Padding(
                        padding: const EdgeInsets.only(
                            left: 10, right: 10, top: 10, bottom: 10),
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
                            buildUrlWidget(
                                context, Global.downloadsDirectory.path)
                          ],
                        ),
                      ),
                    );
                  });
            },
            icon: const Icon(Icons.info)));
  }

  Widget _buildCopyAction(BuildContext context) {
    return IconButton(
        onPressed: () async {
          FlutterClipboard.copy(Global.downloadsDirectory.path)
              .then((value) => showToast("存储路径已复制"));
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
          child: Text(
            "下载列表为空",
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
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
          return SizedBox(
            height: 50,
            child: ListTile(
              visualDensity: const VisualDensity(
                vertical: -3, // 垂直方向紧凑度(-4是最小值)
              ),
              contentPadding: const EdgeInsets.fromLTRB(10, 0, 10, 0),
              minLeadingWidth: 0,
              // 去除 leading 的最小宽度约束
              leading: SizedBox(
                  width: 20,
                  height: 20,
                  child: downloadStateIcon(context, downloadState)),
              trailing: Wrap(
                children: [
                  SizedBox(
                    width: 30,
                    child: IconButton(
                        iconSize: 20,
                        onPressed: () {
                          DownloadManager().retryTask(downloadTask);
                        },
                        icon: Icon(
                          Icons.restart_alt,
                          color: Global.defaultColor,
                        )),
                  ),
                  SizedBox(
                    width: 30,
                    child: IconButton(
                      iconSize: 20,
                      icon: Icon(
                        Icons.delete,
                        color: Global.defaultColor,
                      ),
                      onPressed: () {
                        DownloadManager().cancelTask(downloadTask);
                      },
                    ),
                  ),
                ],
              ),
              subtitle: Padding(
                  padding: const EdgeInsets.only(top: 6), // 调整这个值来控制间距
                  child: downloadProgress(progress)),
              title: Text(
                downloadTask.name,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 10, height: 1.3),
              ),
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
    // return Text(
    //   "${progress.toInt()}%",
    //   style: const TextStyle(fontWeight: FontWeight.bold),
    // );
    return Row(
      children: [
        Expanded(
            child: Padding(
          padding: const EdgeInsets.fromLTRB(0, 0, 0, 8),
          child: LinearProgressIndicator(
            minHeight: 2,
            value: progress,
            color: Global.defaultColor,
            borderRadius: BorderRadius.circular(10),
          ),
        )),
        // Padding(
        //   padding: const EdgeInsets.fromLTRB(10, 0, 0, 0),
        //   child: Text(
        //     "${progress.toInt()}%",
        //     style: TextStyle(fontSize: 12),
        //   ),
        // )
      ],
    );
  }
}
