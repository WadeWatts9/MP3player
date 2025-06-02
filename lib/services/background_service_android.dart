import 'package:workmanager/workmanager.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import '../models/song.dart';

class BackgroundService {
  static const String downloadTask = 'downloadTask';
  static const String progressTask = 'progressTask';
  final DefaultCacheManager _cacheManager = DefaultCacheManager();

  Future<void> initialize() async {
    await Workmanager().initialize(callbackDispatcher);
    await Workmanager().registerPeriodicTask(
      '1',
      downloadTask,
      frequency: const Duration(minutes: 15),
      constraints: Constraints(
        networkType: NetworkType.connected,
        requiresBatteryNotLow: true,
      ),
    );
  }

  Future<void> scheduleDownload(Song song) async {
    await Workmanager().registerOneOffTask(
      song.url,
      downloadTask,
      initialDelay: const Duration(seconds: 1),
      inputData: {
        'url': song.url,
        'title': song.title,
        'author': song.author,
      },
    );
  }

  Future<void> cancelDownload(String taskId) async {
    await Workmanager().cancelByUniqueName(taskId);
  }
}

@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    switch (task) {
      case BackgroundService.downloadTask:
        try {
          final url = inputData!['url'] as String;
          await DefaultCacheManager().getSingleFile(url);
          return true;
        } catch (e) {
          return false;
        }
      default:
        return false;
    }
  });
} 