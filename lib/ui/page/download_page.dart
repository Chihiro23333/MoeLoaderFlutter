import 'package:moeloaderflutter/model/download/download.dart';
import 'package:moeloaderflutter/net/download_new.dart';
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
  Future<void>? _initFuture;

  @override
  void dispose() {
    _log.fine("DownloadPage dispose");
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _initFuture = _initAndEnsureReady();
  }

  Future<void> _initAndEnsureReady() async {
    await DownloadManager.ensureInitialized();
    _log.fine("DownloadPage initialization complete");
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<void>(
      future: _initFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            appBar: AppBar(
              toolbarHeight: UIConst.toolbarHeight,
              title: const Text(
                "下载列表",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
            ),
            body: const Center(
              child: CircularProgressIndicator(),
            ),
          );
        }
        
        // 初始化完成后，获取当前状态作为初始数据
        final currentState = DownloadManager().curState();
        _log.fine("DownloadPage initial data: ${currentState.tasks.length} tasks");
        if (currentState.tasks.isNotEmpty) {
          for (var task in currentState.tasks) {
            _log.fine("  Task: ${task.id}, status: ${task.status}, name: ${task.name}");
          }
        }
        
        return StreamBuilder<DownloadState>(
          initialData: currentState,
          stream: DownloadManager().downloadStream(),
          builder: (BuildContext context, AsyncSnapshot snapshot) {
            _log.fine("StreamBuilder builder: hasData=${snapshot.hasData}, connectionState=${snapshot.connectionState}");
            if (snapshot.hasData) {
              _log.fine("StreamBuilder: tasks.length=${snapshot.data!.tasks.length}");
            }
            return Scaffold(
              body: _buildBody(context, snapshot),
              appBar: _buildAppBar(context),
            );
          },
        );
      },
    );
  }

  AppBar _buildAppBar(BuildContext context) {
    return AppBar(
      toolbarHeight: UIConst.toolbarHeight,
      title: const Text(
        "下载列表",
        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
      ),
      iconTheme: Theme.of(context).iconTheme,
      elevation: 10,
      actions: [
        _buildInfoAction(context),
        _buildClearAction(context),
      ],
    );
  }

  Widget _buildInfoAction(BuildContext context) {
    return Padding(
        padding: const EdgeInsets.fromLTRB(0, 0, 0, 0),
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

  Widget _buildClearAction(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 0, 50, 0),
      child: IconButton(
        onPressed: () {
          final currentState = DownloadManager().curState();
          if (currentState.tasks.isEmpty) {
            showToast("下载列表已经为空");
            return;
          }
          
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('确认清空'),
              content: Text('确定要清空所有下载任务吗？\n\n共 ${currentState.tasks.length} 个任务'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('取消'),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                    _clearAllTasks();
                  },
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.red,
                  ),
                  child: const Text('清空'),
                ),
              ],
            ),
          );
        },
        icon: const Icon(Icons.delete_sweep),
        tooltip: '清空下载列表',
      ),
    );
  }

  void _clearAllTasks() {
    final currentState = DownloadManager().curState();
    for (var task in currentState.tasks) {
      DownloadManager().cancelTask(task.id);
    }
    showToast("已清空所有下载任务");
  }

  Widget _buildCopyAction(BuildContext context) {
    return IconButton(
        onPressed: () async {
          FlutterClipboard.copy(Global.downloadsDirectory.path)
              .then((value) => showToast("存储路径已复制"));
        },
        icon: const Icon(Icons.copy));
  }

  Widget _buildBody(BuildContext context, AsyncSnapshot snapshot) {
    bool hasData = snapshot.hasData;
    _log.fine("_buildBody: hasData=$hasData, connectionState=${snapshot.connectionState}");
    if (hasData) {
      DownloadState downloadState = snapshot.data;
      List<DownloadTask> list = downloadState.tasks;
      _log.fine("_buildBody: tasks.length=${list.length}");
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
          int downloadState = downloadTask.status.value;
          double progress = downloadTask.progress;
          return Dismissible(
            key: Key(downloadTask.id),
            direction: DismissDirection.horizontal,
            background: Container(
              color: Colors.green,
              alignment: Alignment.centerLeft,
              padding: const EdgeInsets.only(left: 16),
              child: const Icon(Icons.refresh, color: Colors.white),
            ),
            confirmDismiss: (direction) async {
              if (direction == DismissDirection.startToEnd) {
                // 右滑重试
                await DownloadManager().retryTask(downloadTask.id);
                return false; // 不删除
              }
              return false;
            },
            onDismissed: (direction) {
              if (direction == DismissDirection.endToStart) {
                // 左滑删除（已废弃，不使用）
              }
            },
            child: Card(
              margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        // 状态标签
                        _buildStatusChip(downloadTask.status),
                        const SizedBox(width: 8),
                        // 标题
                        Expanded(
                          child: Text(
                            downloadTask.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        // 更多操作按钮
                        PopupMenuButton<String>(
                          icon: Icon(
                            Icons.more_vert,
                            color: Global.defaultColor,
                          ),
                          tooltip: '更多操作',
                          onSelected: (value) {
                            switch (value) {
                              case 'copy':
                                FlutterClipboard.copy(downloadTask.url);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('已复制图片地址'),
                                    duration: Duration(seconds: 1),
                                  ),
                                );
                                break;
                              case 'retry':
                                DownloadManager().retryTask(downloadTask.id);
                                break;
                              case 'delete':
                                DownloadManager().cancelTask(downloadTask.id);
                                break;
                            }
                          },
                          itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                            const PopupMenuItem<String>(
                              value: 'copy',
                              child: Row(
                                children: [
                                  Icon(Icons.content_copy, size: 20),
                                  SizedBox(width: 8),
                                  Text('复制链接'),
                                ],
                              ),
                            ),
                            const PopupMenuItem<String>(
                              value: 'retry',
                              child: Row(
                                children: [
                                  Icon(Icons.refresh, size: 20),
                                  SizedBox(width: 8),
                                  Text('重试下载'),
                                ],
                              ),
                            ),
                            const PopupMenuItem<String>(
                              value: 'delete',
                              child: Row(
                                children: [
                                  Icon(Icons.delete, size: 20, color: Colors.red),
                                  SizedBox(width: 8),
                                  Text('删除任务', style: TextStyle(color: Colors.red)),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    // 进度条和百分比
                    Row(
                      children: [
                        // 进度条
                        Expanded(
                          child: SizedBox(
                            height: 4,
                            child: LinearProgressIndicator(
                              value: progress,
                              color: Global.defaultColor,
                              backgroundColor: Colors.grey[200],
                              borderRadius: BorderRadius.circular(2),
                              minHeight: 4,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        // 百分比
                        Text(
                          '${(progress * 100).toStringAsFixed(1)}%',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Global.defaultColor,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        },
        separatorBuilder: (BuildContext context, int index) {
          return const SizedBox(height: 0);
        },
      );
    } else {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }
  }

  Widget downloadProgress(double progress) {
    return Row(
      children: [
        Expanded(
            child: Padding(
          padding: const EdgeInsets.fromLTRB(0, 0, 0, 8),
          child: LinearProgressIndicator(
            minHeight: 3,
            value: progress,
            color: Global.defaultColor,
            borderRadius: BorderRadius.circular(3),
          ),
        )),
      ],
    );
  }

  String _getProgressText(double progress, DownloadTask task) {
    final percent = (progress * 100).toStringAsFixed(1);
    if (task.total > 0) {
      final downloaded = task.count;
      final total = task.total;
      return '$percent% ($downloaded/$total)';
    }
    return '$percent%';
  }

  Widget _buildStatusChip(DownloadStatus status) {
    String statusText;

    switch (status) {
      case DownloadStatus.completed:
        statusText = '已完成';
        break;
      case DownloadStatus.downloading:
        statusText = '下载中';
        break;
      case DownloadStatus.waiting:
        statusText = '等待中';
        break;
      case DownloadStatus.failed:
        statusText = '失败';
        break;
      default:
        statusText = '未知';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: Global.defaultColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: Global.defaultColor, width: 1),
      ),
      child: Text(
        statusText,
        style: TextStyle(
          fontSize: 10,
          color: Global.defaultColor,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}

Widget downloadStateIconNew(BuildContext context, DownloadStatus status) {
  Widget icon;
  switch (status) {
    case DownloadStatus.downloading:
      icon = SizedBox(
        width: 20,
        height: 20,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          color: Global.defaultColor,
        ),
      );
      break;
    case DownloadStatus.completed:
      icon = Icon(
        Icons.file_download_done,
        color: Global.defaultColor,
      );
      break;
    case DownloadStatus.failed:
      icon = const Icon(
        Icons.error_outline,
        color: Colors.red,
      );
      break;
    case DownloadStatus.waiting:
      icon = Icon(
        Icons.watch_later_outlined,
        color: Global.defaultColor,
      );
      break;
    case DownloadStatus.idle:
    default:
      icon = const Icon(
        Icons.download,
        color: Colors.black,
      );
  }
  return icon;
}
