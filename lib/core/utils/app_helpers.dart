import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';

class AppHelpers {
  static String debugLog(String message) {
    if (kDebugMode) {
      debugPrint(message);
      return message;
    }
    return '';
  }

  static void backNTimes(int n) {
    if (n <= 0) {
      return;
    }

    int count = 0;
    Get.until((route) {
      return count++ == n;
    });
  }

  static Future<void> launchInBrowser(Uri url) async {
    if (!await launchUrl(
      url,
      mode: LaunchMode.externalApplication,
    )) {
      throw Exception('Could not launch $url');
    }
  }
}
