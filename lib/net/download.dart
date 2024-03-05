import 'dart:async';
import 'package:MoeLoaderFlutter/net/request_manager.dart';

class DownloadManager{

  static DownloadManager? _cache;
  DownloadManager._create();
  factory DownloadManager(){
    return _cache ?? (_cache = DownloadManager._create());
  }

  final StreamController<DownloadState> _streamDownloadController = StreamController();
  final DownloadState _downloadState = DownloadState();
  Stream<DownloadState>? _broadcastStream;

  void addTask(DownloadTask downloadTask){
    _tasks().add(downloadTask);
    _update();
    _downloadNext();
  }

  List<DownloadTask> _tasks(){
    return _downloadState.tasks;
  }

  void _update(){
    _streamDownloadController.sink.add(_downloadState);
  }

  Stream<DownloadState> downloadStream(){
    _broadcastStream ??= _streamDownloadController.stream.asBroadcastStream();
    return _broadcastStream!;
  }

  DownloadState curState(){
    return _downloadState;
  }

  void _downloadNext(){
    bool hasDownloading = _hasDownloading();
    if(hasDownloading)return;

    DownloadTask? downloadTask = _findFirstUnDownload();
    if(downloadTask != null){
      downloadTask.downloadState = DownloadTask.downloading;
      RequestManager().download(downloadTask.url, downloadTask.name, onReceiveProgress: (int count, int total) {
        downloadTask.count = count;
        downloadTask.total = total;
        bool complete = count == total;
        downloadTask.downloadState = complete ? DownloadTask.complete : DownloadTask.downloading;
        _update();
        if(complete){
          _downloadNext();
        }
      });
    }
  }

  DownloadTask? _findFirstUnDownload(){
    DownloadTask? task;
    Iterator<DownloadTask> iterator = _tasks().iterator;
    while(iterator.moveNext()){
      var current = iterator.current;
      if(current.downloadState == DownloadTask.idle){
        task = current;
        break;
      }
    }
    return task;
  }

  bool _hasDownloading(){
    bool hasDownloading = false;
    Iterator<DownloadTask> iterator = _tasks().iterator;
    while(iterator.moveNext()){
      var current = iterator.current;
      if(current.downloadState == DownloadTask.downloading){
        hasDownloading = true;
        break;
      }
    }
    return hasDownloading;
  }

}

class DownloadState{
  List<DownloadTask> tasks = [];
}

class DownloadTask{

  static const  int idle = 0;
  static const  int downloading = 1;
  static const  int complete = 2;

  String url;
  String name;
  int count = 0;
  int total = 0;
  int downloadState = idle;

  DownloadTask(this.url, this.name);
}