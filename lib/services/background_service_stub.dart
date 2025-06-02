class BackgroundService {
  Future<void> initialize() async {}
  Future<void> scheduleDownload(dynamic song) async {}
  Future<void> cancelDownload(String taskId) async {}
} 