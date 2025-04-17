import 'package:flutter/foundation.dart';

class AppHelpers {
  static String debugLog(String message) {
    if (kDebugMode) {
      debugPrint(message);
      return message;
    }
    return '';
  }
}
