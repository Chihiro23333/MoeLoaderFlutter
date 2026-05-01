import 'dart:io';
import 'package:dio/dio.dart';
import 'package:logging/logging.dart';
import 'package:moeloaderflutter/init.dart';
import 'package:moeloaderflutter/model/download/download.dart';
import 'package:moeloaderflutter/net/request_manager.dart';

typedef DownloadProgressCallback = void Function(int count, int total);

class DownloadResult {
  final bool success;
  final String? error;

  DownloadResult({required this.success, this.error});
}

class Downloader {
  final _log = Logger('Downloader');

  Future<DownloadResult> download(
    DownloadTask task, {
    required DownloadProgressCallback onProgress,
    required CancelToken cancelToken,
  }) async {
    try {
      String downloadUrl = task.downloadUrl ?? task.url;

      const redirectPlaceholder = r'${redirect}';
      if (downloadUrl.contains(redirectPlaceholder)) {
        downloadUrl = downloadUrl.replaceAll(redirectPlaceholder, '');
        downloadUrl = await RequestManager()
            .dioRequestRedirectUrl(downloadUrl, headers: task.headers);
      }

      int index = downloadUrl.lastIndexOf(".");
      String suffix = downloadUrl.substring(index, downloadUrl.length);
      Directory directory = Global.downloadsDirectory;
      String savePath = "${directory.path}/${task.name}$suffix";

      _log.fine("Downloading: $downloadUrl to $savePath");

      bool success = await RequestManager().download(
        downloadUrl,
        savePath,
        onReceiveProgress: onProgress,
        cancelToken: cancelToken,
        headers: task.headers,
      );

      if (success) {
        Global.multiPlatform.saveToGallery(savePath);
        return DownloadResult(success: true);
      } else {
        return DownloadResult(success: false, error: 'Download failed');
      }
    } on DioException catch (e) {
      // 如果是 307 重定向，手动获取重定向 URL
      if (e.response?.statusCode == 307) {
        final location = e.response?.headers.value('location');
        if (location != null && location.isNotEmpty) {
          _log.info('307 redirect detected, fetching redirect URL manually: $location');
          
          // 使用重定向后的 URL 重新下载
          int index = location.lastIndexOf(".");
          String suffix = location.substring(index, location.length);
          Directory directory = Global.downloadsDirectory;
          String savePath = "${directory.path}/${task.name}$suffix";
          
          _log.fine("Re-downloading with redirect URL: $location to $savePath");
          
          bool success = await RequestManager().download(
            location,
            savePath,
            onReceiveProgress: onProgress,
            cancelToken: cancelToken,
            headers: task.headers,
          );
          
          if (success) {
            Global.multiPlatform.saveToGallery(savePath);
            return DownloadResult(success: true);
          }
        }
      }
      
      _log.fine("Download error: $e");
      return DownloadResult(success: false, error: e.toString());
    } catch (e) {
      _log.fine("Download error: $e");
      return DownloadResult(success: false, error: e.toString());
    }
  }
}
