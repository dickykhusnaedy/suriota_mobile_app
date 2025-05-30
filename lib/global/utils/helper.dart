import 'package:flutter/foundation.dart';
import 'package:get/get.dart';

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
}
