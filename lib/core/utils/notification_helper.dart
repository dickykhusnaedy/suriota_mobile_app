import 'dart:io';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:gateway_config/core/utils/app_helpers.dart';
import 'package:permission_handler/permission_handler.dart';

class NotificationHelper {
  static final NotificationHelper _instance = NotificationHelper._internal();
  factory NotificationHelper() => _instance;
  NotificationHelper._internal();

  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  static const MethodChannel _channel = MethodChannel(
    'com.gateway.config/file_manager',
  );

  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized) return;

    // Request notification permission for Android 13+
    await _requestNotificationPermission();

    const androidSettings = AndroidInitializationSettings(
      '@mipmap/launcher_icon',
    );
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
        // Handle notification tap when app is running or in background
        _handleNotificationTap(response);
      },
    );

    _initialized = true;

    // Check if app was launched from notification
    await _checkLaunchNotification();
  }

  /// Check if the app was launched by tapping on a notification
  Future<void> _checkLaunchNotification() async {
    final NotificationAppLaunchDetails? launchDetails = await _notifications
        .getNotificationAppLaunchDetails();

    if (launchDetails != null && launchDetails.didNotificationLaunchApp) {
      // App was launched from notification
      final response = launchDetails.notificationResponse;
      if (response != null) {
        AppHelpers.debugLog(
          'App launched from notification with payload: ${response.payload}',
        );
        // Handle the notification that launched the app
        await _handleNotificationTap(response);
      }
    }
  }

  Future<void> _handleNotificationTap(NotificationResponse response) async {
    if (response.payload != null && response.payload!.isNotEmpty) {
      final filePath = response.payload!;
      await _openFileManager(filePath);
    }
  }

  Future<void> _openFileManager(String filePath) async {
    try {
      AppHelpers.debugLog('=== Opening File Manager ===');
      AppHelpers.debugLog('File path: $filePath');

      if (!Platform.isAndroid) {
        AppHelpers.debugLog('iOS not supported for file manager intent');
        return;
      }

      // Check if file exists
      final file = File(filePath);
      final fileExists = await file.exists();
      AppHelpers.debugLog('File exists: $fileExists');

      // Get the directory path
      final directory = file.parent;
      final directoryPath = directory.path;
      AppHelpers.debugLog('Directory path: $directoryPath');

      // Call native Android code to open file manager
      try {
        await _channel.invokeMethod('openFileManager', {
          'directoryPath': directoryPath,
        });
        AppHelpers.debugLog('=== File Manager Opened Successfully ===');
      } on PlatformException catch (e) {
        AppHelpers.debugLog('Platform exception: ${e.message}');
        AppHelpers.debugLog('Error code: ${e.code}');
      }
    } catch (e) {
      AppHelpers.debugLog('Error opening file manager: $e');
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

    await _notifications.show(id, title, message, details, payload: payload);
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
