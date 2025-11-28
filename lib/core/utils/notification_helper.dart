import 'dart:io';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:open_filex/open_filex.dart';

class NotificationHelper {
  static final NotificationHelper _instance = NotificationHelper._internal();
  factory NotificationHelper() => _instance;
  NotificationHelper._internal();

  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized) return;

    // Request notification permission for Android 13+
    await _requestNotificationPermission();

    const androidSettings = AndroidInitializationSettings('@mipmap/launcher_icon');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        // Handle notification tap
        _handleNotificationTap(response);
      },
    );

    _initialized = true;
  }

  Future<void> _handleNotificationTap(NotificationResponse response) async {
    if (response.payload != null && response.payload!.isNotEmpty) {
      final filePath = response.payload!;
      await _openFileManager(filePath);
    }
  }

  Future<void> _openFileManager(String filePath) async {
    try {
      print('Attempting to open file: $filePath');

      // Use OpenFilex to open the file directly
      // This will automatically open the file manager if the file exists
      final result = await OpenFilex.open(filePath);

      print('OpenFilex result: ${result.type}');
      print('OpenFilex message: ${result.message}');

      // If file doesn't exist or can't be opened, result.type will be error
      if (result.type == ResultType.error) {
        print('Failed to open file, trying to open parent directory');
        // Try to open parent directory instead
        final directory = File(filePath).parent;
        if (await directory.exists()) {
          // Open the parent directory
          await OpenFilex.open(directory.path);
        }
      }
    } catch (e) {
      print('Error opening file manager: $e');
    }
  }

  Future<void> _requestNotificationPermission() async {
    final status = await Permission.notification.status;
    if (status.isDenied) {
      await Permission.notification.request();
    }
  }

  Future<void> showNotification({
    required int id,
    required String title,
    required String message,
    String? payload,
  }) async {
    if (!_initialized) {
      await initialize();
    }

    const androidDetails = AndroidNotificationDetails(
      'gateway_config_channel',
      'Gateway Config',
      channelDescription: 'Notifications for Gateway Config operations',
      importance: Importance.high,
      priority: Priority.high,
      showWhen: true,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notifications.show(
      id,
      title,
      message,
      details,
      payload: payload,
    );
  }

  Future<void> showDownloadSuccessNotification({
    required String filePath,
  }) async {
    // Format display path for notification message
    String displayPath = filePath;
    if (Platform.isAndroid && filePath.contains('/storage/emulated/0/')) {
      displayPath = filePath.replaceFirst('/storage/emulated/0/', '');
    }

    await showNotification(
      id: 1,
      title: 'Download All Config Success',
      message: 'File saved at $displayPath\n\nTap to open file location',
      payload: filePath, // Use full path as payload
    );
  }

  Future<void> showImportSuccessNotification({
    required int totalConfigs,
  }) async {
    await showNotification(
      id: 2,
      title: 'Import Config Success',
      message: 'Successfully imported $totalConfigs configuration(s)',
    );
  }
}
