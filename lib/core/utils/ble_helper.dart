import 'dart:convert';

import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:gateway_config/core/constants/ble_constants.dart';
import 'package:gateway_config/core/utils/app_helpers.dart';

/// BLE Helper Functions
///
/// This class contains reusable helper functions for BLE operations
/// to avoid code duplication and improve maintainability.
class BLEHelper {
  // ============================================================================
  // Command Sending
  // ============================================================================

  /// Send a BLE command in chunks
  ///
  /// This method handles the chunking and transmission of commands to BLE devices.
  /// It splits the command into chunks of [BLEConstants.bleChunkSize] and sends
  /// them sequentially with appropriate delays.
  ///
  /// **Parameters:**
  /// - [commandChar]: The BLE characteristic to write to
  /// - [command]: The command map to send
  /// - [withEndDelimiter]: Whether to send END marker after command (default: true)
  /// - [onProgress]: Optional callback for progress updates (0.0 to 1.0)
  ///
  /// **Returns:** The complete JSON string that was sent
  ///
  /// **Throws:** Exception if commandChar is null or write fails
  static Future<String> sendBLECommand(
    BluetoothCharacteristic? commandChar,
    Map<String, dynamic> command, {
    bool withEndDelimiter = true,
    Function(double progress)? onProgress,
  }) async {
    if (commandChar == null) {
      throw Exception('Command characteristic is null');
    }

    // Encode command to JSON
    final jsonStr = jsonEncode(command);
    AppHelpers.debugLog('Sending BLE command: $jsonStr');

    // Check if writeWithoutResponse is supported
    final bool useWriteWithResponse =
        !(commandChar.properties.writeWithoutResponse);
    AppHelpers.debugLog('Using write with response: $useWriteWithResponse');

    // Calculate total chunks for progress
    final totalChunks =
        (jsonStr.length / BLEConstants.bleChunkSize).ceil() +
        (withEndDelimiter ? 1 : 0);
    int currentChunk = 0;

    // Send command in chunks
    for (int i = 0; i < jsonStr.length; i += BLEConstants.bleChunkSize) {
      final chunk = jsonStr.substring(
        i,
        (i + BLEConstants.bleChunkSize > jsonStr.length)
            ? jsonStr.length
            : i + BLEConstants.bleChunkSize,
      );

      await commandChar.write(
        utf8.encode(chunk),
        withoutResponse: !useWriteWithResponse,
      );

      AppHelpers.debugLog(
        'Sent chunk ${currentChunk + 1}/$totalChunks: $chunk',
      );
      currentChunk++;

      // Update progress
      onProgress?.call(currentChunk / totalChunks);

      // Delay between chunks
      await Future.delayed(BLEConstants.chunkSendDelay);
    }

    // Send END delimiter if requested
    if (withEndDelimiter) {
      await Future.delayed(BLEConstants.endDelimiterDelay);
      await commandChar.write(
        utf8.encode(BLEConstants.endMarker),
        withoutResponse: !useWriteWithResponse,
      );
      AppHelpers.debugLog('Sent END marker');
      currentChunk++;
      onProgress?.call(1.0);
    }

    // Validate sent command
    try {
      jsonDecode(jsonStr);
      AppHelpers.debugLog('✓ Sent command is valid JSON');
    } catch (e) {
      AppHelpers.debugLog('⚠ Sent command is not valid JSON: $e');
    }

    return jsonStr;
  }

  // ============================================================================
  // Response Processing
  // ============================================================================

  /// Clean response string from control characters
  ///
  /// Removes control characters (0x00-0x1F, 0x7F) that may interfere
  /// with JSON parsing.
  static String cleanResponse(String response) {
    return response.replaceAll(RegExp(r'[\x00-\x1F\x7F]'), '').trim();
  }

  /// Parse response chunks into complete response
  ///
  /// Combines multiple chunks and extracts complete responses separated
  /// by END markers.
  ///
  /// **Returns:** List of complete response strings (without END markers)
  static List<String> parseResponseChunks(String buffer) {
    final parts = buffer.split(BLEConstants.endMarker);
    final endsWithDelimiter = buffer.endsWith(BLEConstants.endMarker);

    // Process only complete segments (those followed by END marker)
    final completeCount = endsWithDelimiter ? parts.length : parts.length - 1;

    final responses = <String>[];
    for (int i = 0; i < completeCount; i++) {
      final segment = parts[i].trim();
      if (segment.isNotEmpty) {
        responses.add(segment);
      }
    }

    return responses;
  }

  /// Get partial data from buffer
  ///
  /// Returns the incomplete segment at the end of buffer if it doesn't
  /// end with END marker.
  static String? getPartialData(String buffer) {
    if (buffer.endsWith(BLEConstants.endMarker)) {
      return null; // No partial data
    }

    final parts = buffer.split(BLEConstants.endMarker);
    if (parts.isEmpty) return null;

    final partial = parts.last.trim();

    // Validate partial data size
    if (partial.length > BLEConstants.maxPartialSize) {
      AppHelpers.debugLog(
        '⚠️ Partial data too large (${partial.length} bytes), discarding',
      );
      return null;
    }

    return partial.isEmpty ? null : partial;
  }

  // ============================================================================
  // Validation
  // ============================================================================

  /// Validate command structure
  ///
  /// Checks if command has required fields: 'op' and 'type'
  static bool isValidCommand(Map<String, dynamic> command) {
    return command.containsKey('op') && command.containsKey('type');
  }

  /// Validate if response is valid JSON
  static bool isValidJson(String response) {
    try {
      jsonDecode(response);
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Check if response looks like JSON structure
  static bool looksLikeJson(String response) {
    final trimmed = response.trim();
    return trimmed.startsWith('{') || trimmed.startsWith('[');
  }

  // ============================================================================
  // Device Helpers
  // ============================================================================

  /// Get device display name
  ///
  /// Returns platformName if available, otherwise remoteId
  static String getDeviceDisplayName(BluetoothDevice device) {
    final name = device.platformName;
    return name.isNotEmpty ? name : device.remoteId.toString();
  }

  /// Check if device ID is valid
  static bool isValidDeviceId(String? deviceId) {
    if (deviceId == null || deviceId.isEmpty) return false;

    // Special case: "stop" is valid for stopping streams
    if (deviceId == 'stop') return true;

    // Check if it's a valid MAC address format or UUID
    // MAC: XX:XX:XX:XX:XX:XX
    // UUID: XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXXX
    final macPattern = RegExp(r'^([0-9A-Fa-f]{2}:){5}[0-9A-Fa-f]{2}$');
    final uuidPattern = RegExp(
      r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$',
    );

    return macPattern.hasMatch(deviceId) || uuidPattern.hasMatch(deviceId);
  }

  // ============================================================================
  // Logging Helpers
  // ============================================================================

  /// Log command details
  static void logCommand(Map<String, dynamic> command, {String prefix = ''}) {
    final op = command['op'] ?? 'unknown';
    final type = command['type'] ?? 'unknown';
    final deviceId = command['device_id'] ?? 'none';

    AppHelpers.debugLog(
      '${prefix}Command: op=$op, type=$type, device_id=$deviceId',
    );
  }

  /// Log response summary
  static void logResponse(String response, {String prefix = ''}) {
    final length = response.length;
    final preview = response.length > 100
        ? '${response.substring(0, 100)}...'
        : response;

    AppHelpers.debugLog('${prefix}Response ($length bytes): $preview');
  }

  /// Log timeout warning
  static void logTimeoutWarning(Duration timeout, String operation) {
    if (timeout.inSeconds > 300) {
      // > 5 minutes
      AppHelpers.debugLog(
        '⚠️⚠️⚠️ LONG TIMEOUT: $operation will wait up to ${timeout.inMinutes} minutes',
      );
      AppHelpers.debugLog(
        '⚠️⚠️⚠️ Consider using pagination or minimal mode for better performance',
      );
    } else if (timeout.inSeconds > 60) {
      // > 1 minute
      AppHelpers.debugLog(
        '⚠️ Extended timeout: $operation will wait up to ${timeout.inSeconds} seconds',
      );
    }
  }

  // ============================================================================
  // Buffer Management
  // ============================================================================

  /// Check if buffer size is safe
  static bool isBufferSizeSafe(int size) {
    return size <= BLEConstants.maxBufferSize;
  }

  /// Get buffer usage percentage
  static double getBufferUsagePercentage(int currentSize) {
    return (currentSize / BLEConstants.maxBufferSize) * 100;
  }

  /// Log buffer status
  static void logBufferStatus(int currentSize, {String context = ''}) {
    final percentage = getBufferUsagePercentage(currentSize);
    final status = percentage > 80
        ? '⚠️ HIGH'
        : percentage > 50
        ? '⚡ MEDIUM'
        : '✓ OK';

    AppHelpers.debugLog(
      '${context}Buffer: $currentSize bytes (${percentage.toStringAsFixed(1)}%) - $status',
    );
  }

  // ============================================================================
  // Timeout Helpers
  // ============================================================================

  /// Get human-readable timeout description
  static String getTimeoutDescription(Duration timeout) {
    if (timeout.inHours > 0) {
      return '${timeout.inHours}h ${timeout.inMinutes % 60}m';
    } else if (timeout.inMinutes > 0) {
      return '${timeout.inMinutes}m ${timeout.inSeconds % 60}s';
    } else {
      return '${timeout.inSeconds}s';
    }
  }
}
