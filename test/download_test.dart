import 'package:flutter_test/flutter_test.dart';
import 'package:moeloaderflutter/model/download/download.dart';

void main() {
  group('DownloadTask Tests', () {
    test('DownloadTask should create with default values', () {
      final task = DownloadTask(
        id: 'test-id',
        url: 'https://example.com/image.jpg',
        name: 'test-image',
      );

      expect(task.id, 'test-id');
      expect(task.url, 'https://example.com/image.jpg');
      expect(task.name, 'test-image');
      expect(task.status, DownloadStatus.idle);
      expect(task.count, 0);
      expect(task.total, 0);
      expect(task.progress, 0.0);
    });

    test('DownloadTask should calculate progress correctly', () {
      final task = DownloadTask(
        id: 'test-id',
        url: 'https://example.com/image.jpg',
        name: 'test-image',
        count: 500,
        total: 1000,
      );

      expect(task.progress, 0.5);
    });

    test('DownloadTask should return 100% progress when completed', () {
      final task = DownloadTask(
        id: 'test-id',
        url: 'https://example.com/image.jpg',
        name: 'test-image',
        status: DownloadStatus.completed,
        count: 1000,
        total: 1000,
      );

      expect(task.progress, 1.0);
    });

    test('DownloadTask copyWith should create new instance with updated values', () {
      final originalTask = DownloadTask(
        id: 'test-id',
        url: 'https://example.com/image.jpg',
        name: 'test-image',
      );

      final updatedTask = originalTask.copyWith(
        status: DownloadStatus.downloading,
        count: 500,
        total: 1000,
      );

      expect(originalTask.status, DownloadStatus.idle);
      expect(updatedTask.status, DownloadStatus.downloading);
      expect(updatedTask.count, 500);
      expect(updatedTask.total, 1000);
      expect(updatedTask.progress, 0.5);
    });

    test('DownloadTask should serialize to JSON', () {
      final task = DownloadTask(
        id: 'test-id',
        url: 'https://example.com/image.jpg',
        name: 'test-image',
        status: DownloadStatus.downloading,
        count: 500,
        total: 1000,
      );

      final json = task.toJson();

      expect(json['id'], 'test-id');
      expect(json['url'], 'https://example.com/image.jpg');
      expect(json['name'], 'test-image');
      expect(json['status'], 2);
      expect(json['count'], 500);
      expect(json['total'], 1000);
    });

    test('DownloadTask should deserialize from JSON', () {
      final json = {
        'id': 'test-id',
        'url': 'https://example.com/image.jpg',
        'name': 'test-image',
        'status': 2,
        'count': 500,
        'total': 1000,
        'createdAt': DateTime.now().toIso8601String(),
      };

      final task = DownloadTask.fromJson(json);

      expect(task.id, 'test-id');
      expect(task.url, 'https://example.com/image.jpg');
      expect(task.name, 'test-image');
      expect(task.status, DownloadStatus.downloading);
      expect(task.count, 500);
      expect(task.total, 1000);
    });
  });

  group('DownloadStatus Tests', () {
    test('DownloadStatus should convert to value correctly', () {
      expect(DownloadStatus.idle.value, 0);
      expect(DownloadStatus.waiting.value, 1);
      expect(DownloadStatus.downloading.value, 2);
      expect(DownloadStatus.completed.value, 3);
      expect(DownloadStatus.failed.value, 4);
      expect(DownloadStatus.paused.value, 5);
    });

    test('DownloadStatus should convert from value correctly', () {
      expect(DownloadStatusExtension.fromValue(0), DownloadStatus.idle);
      expect(DownloadStatusExtension.fromValue(1), DownloadStatus.waiting);
      expect(DownloadStatusExtension.fromValue(2), DownloadStatus.downloading);
      expect(DownloadStatusExtension.fromValue(3), DownloadStatus.completed);
      expect(DownloadStatusExtension.fromValue(4), DownloadStatus.failed);
      expect(DownloadStatusExtension.fromValue(5), DownloadStatus.paused);
    });
  });

  group('DownloadState Tests', () {
    test('DownloadState should filter tasks by status', () {
      final tasks = [
        DownloadTask(
          id: '1',
          url: 'https://example.com/1.jpg',
          name: '1',
          status: DownloadStatus.waiting,
        ),
        DownloadTask(
          id: '2',
          url: 'https://example.com/2.jpg',
          name: '2',
          status: DownloadStatus.downloading,
        ),
        DownloadTask(
          id: '3',
          url: 'https://example.com/3.jpg',
          name: '3',
          status: DownloadStatus.completed,
        ),
      ];

      final state = DownloadState(tasks: tasks);

      expect(state.waitingTasks.length, 1);
      expect(state.downloadingTasks.length, 1);
      expect(state.completedTasks.length, 1);
      expect(state.failedTasks.length, 0);
    });

    test('DownloadState should calculate counts correctly', () {
      final tasks = [
        DownloadTask(
          id: '1',
          url: 'https://example.com/1.jpg',
          name: '1',
          status: DownloadStatus.waiting,
        ),
        DownloadTask(
          id: '2',
          url: 'https://example.com/2.jpg',
          name: '2',
          status: DownloadStatus.waiting,
        ),
        DownloadTask(
          id: '3',
          url: 'https://example.com/3.jpg',
          name: '3',
          status: DownloadStatus.downloading,
        ),
      ];

      final state = DownloadState(tasks: tasks);

      expect(state.waitingCount, 2);
      expect(state.downloadingCount, 1);
      expect(state.completedCount, 0);
      expect(state.failedCount, 0);
      expect(state.hasDownloading, true);
    });

    test('DownloadState should find task by id', () {
      final tasks = [
        DownloadTask(
          id: '1',
          url: 'https://example.com/1.jpg',
          name: '1',
        ),
        DownloadTask(
          id: '2',
          url: 'https://example.com/2.jpg',
          name: '2',
        ),
      ];

      final state = DownloadState(tasks: tasks);

      expect(state.findTask('1')?.id, '1');
      expect(state.findTask('2')?.id, '2');
      expect(state.findTask('3'), isNull);
    });
  });
}
