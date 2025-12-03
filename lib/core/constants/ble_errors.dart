/// BLE Error Messages
///
/// Centralized error messages for BLE operations.
/// This makes it easier to localize errors in the future.
class BLEErrors {
  // ============================================================================
  // Connection Errors
  // ============================================================================

  static const String notConnected = 'Device not connected';
  static const String connectionFailed = 'Failed to connect to device';
  static const String disconnectionFailed = 'Failed to disconnect from device';
  static const String serviceNotFound = 'Required BLE service not found';
  static const String characteristicNotFound =
      'Required BLE characteristic not found';
  static const String alreadyConnected = 'Device is already connected';
  static const String deviceNotFound = 'Device not found';

  // ============================================================================
  // Command Errors
  // ============================================================================

  static const String invalidCommandFormat =
      'Invalid command format: missing required fields (op, type)';
  static const String commandSendFailed = 'Failed to send command to device';
  static const String commandTimeout =
      'Command timeout: device did not respond in time';
  static const String invalidResponse = 'Invalid response received from device';
  static const String responseParsingFailed = 'Failed to parse device response';
  static const String emptyResponse = 'Received empty response from device';

  // ============================================================================
  // Streaming Errors
  // ============================================================================

  static const String streamStartFailed = 'Failed to start data stream';
  static const String streamStopFailed = 'Failed to stop data stream';
  static const String streamTimeout = 'Stream timeout: no data received';
  static const String streamInactive = 'Stream inactive: no new data';
  static const String bufferOverflow = 'Buffer overflow: data stream too large';
  static const String streamAlreadyActive = 'Stream already active';

  // ============================================================================
  // Bluetooth Adapter Errors
  // ============================================================================

  static const String bluetoothOff =
      'Bluetooth is turned off. Please enable it to continue.';
  static const String bluetoothUnavailable =
      'Bluetooth is not available on this device';
  static const String bluetoothUnauthorized =
      'Bluetooth permission not granted';
  static const String bluetoothNotSupported =
      'Bluetooth Low Energy is not supported on this device';

  // ============================================================================
  // Scan Errors
  // ============================================================================

  static const String scanFailed = 'Failed to start device scan';
  static const String scanAlreadyActive = 'Scan is already in progress';
  static const String noDevicesFound = 'No devices found';

  // ============================================================================
  // Pagination Errors
  // ============================================================================

  static const String paginationRequired =
      'Pagination required for large data operations';
  static const String paginationNotSupported =
      'Device firmware does not support pagination';
  static const String invalidPageNumber = 'Invalid page number';

  // ============================================================================
  // Validation Errors
  // ============================================================================

  static const String invalidDeviceId = 'Invalid device ID';
  static const String invalidCommandType = 'Invalid command type';
  static const String invalidOperation = 'Invalid operation';
  static const String missingRequiredParameter = 'Missing required parameter';

  // ============================================================================
  // Helper Methods
  // ============================================================================

  /// Format error message with context
  static String withContext(String error, String context) {
    return '[$context] $error';
  }

  /// Format error message with details
  static String withDetails(String error, String details) {
    return '$error: $details';
  }

  /// Get user-friendly error message from exception
  static String fromException(dynamic exception) {
    if (exception == null) return 'Unknown error occurred';

    final errorStr = exception.toString().toLowerCase();

    // Map common exceptions to user-friendly messages
    if (errorStr.contains('timeout')) {
      return commandTimeout;
    } else if (errorStr.contains('not connected') ||
        errorStr.contains('disconnected')) {
      return notConnected;
    } else if (errorStr.contains('permission')) {
      return bluetoothUnauthorized;
    } else if (errorStr.contains('bluetooth') && errorStr.contains('off')) {
      return bluetoothOff;
    } else if (errorStr.contains('service')) {
      return serviceNotFound;
    } else if (errorStr.contains('characteristic')) {
      return characteristicNotFound;
    }

    // Return original error if no mapping found
    return exception.toString();
  }
}

/// BLE Success Messages
///
/// Centralized success messages for BLE operations.
class BLEMessages {
  static const String connecting = 'Connecting to device...';
  static const String connected = 'Successfully connected to device';
  static const String disconnecting = 'Disconnecting from device...';
  static const String disconnected = 'Successfully disconnected from device';
  static const String scanning = 'Scanning for devices...';
  static const String scanComplete = 'Scan completed';
  static const String commandSent = 'Command sent successfully';
  static const String streamStarted = 'Data stream started';
  static const String streamStopped = 'Data stream stopped';
  static const String deviceWillRedirect =
      'Device disconnected, will redirect to home in 3 seconds';

  /// Format message with device name
  static String withDeviceName(String message, String deviceName) {
    return '$message: $deviceName';
  }
}
