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
      debugPrint('Nilai n tidak valid: $n');
      return;
    }

    int count = 0;
    Get.until((route) {
      debugPrint('Route dilewati: ${route.settings.name ?? route.toString()}');
      return count++ == n;
    });
  }
}
