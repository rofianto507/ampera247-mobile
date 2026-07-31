import 'package:flutter_foreground_task/flutter_foreground_task.dart';

/// Dipanggil di isolate terpisah oleh flutter_foreground_task.
/// GPS recording tetap jalan di main isolate (PatroliTrackingNotifier).
/// Handler ini hanya menjaga foreground service tetap hidup.
@pragma('vm:entry-point')
void startForegroundCallback() {
  FlutterForegroundTask.setTaskHandler(_PatroliTaskHandler());
}

class _PatroliTaskHandler extends TaskHandler {
  @override
  Future<void> onStart(DateTime timestamp, TaskStarter starter) async {}

  @override
  void onRepeatEvent(DateTime timestamp) {}

  @override
  Future<void> onDestroy(DateTime timestamp) async {}
}

/// Inisialisasi sekali saat app start (panggil dari main.dart).
void initForegroundTask() {
  FlutterForegroundTask.init(
    androidNotificationOptions: AndroidNotificationOptions(
      channelId: 'patroli_tracking_channel',
      channelName: 'Patroli Aktif',
      channelDescription: 'Notifikasi aktif saat patroli sedang berlangsung',
      channelImportance: NotificationChannelImportance.LOW,
      priority: NotificationPriority.LOW,
    ),
    iosNotificationOptions: const IOSNotificationOptions(
      showNotification: false,
    ),
    foregroundTaskOptions: ForegroundTaskOptions(
      eventAction: ForegroundTaskEventAction.nothing(),
      autoRunOnBoot: false,
      allowWakeLock: true,
    ),
  );
}

/// Mulai foreground service dengan notifikasi.
Future<void> startPatroliForegroundService(String kode) async {
  if (await FlutterForegroundTask.isRunningService) return;
  await FlutterForegroundTask.startService(
    serviceId: 1001,
    notificationTitle: 'Patroli Sedang Berlangsung',
    notificationText: kode,
    callback: startForegroundCallback,
  );
}

/// Update teks notifikasi (jumlah titik terekam).
Future<void> updatePatroliForegroundNotification(int titikCount) async {
  await FlutterForegroundTask.updateService(
    notificationTitle: 'Patroli Sedang Berlangsung',
    notificationText: '$titikCount titik terekam',
  );
}

/// Hentikan foreground service.
Future<void> stopPatroliForegroundService() async {
  await FlutterForegroundTask.stopService();
}
