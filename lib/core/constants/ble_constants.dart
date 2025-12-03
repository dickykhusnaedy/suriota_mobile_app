/// BLE (Bluetooth Low Energy) Constants
///
/// This file contains all constants used in BLE operations to avoid magic numbers
/// and improve code maintainability.
class BLEConstants {
  // ============================================================================
  // BLE Communication Parameters
  // ============================================================================

  /// BLE chunk size for data transmission
  ///
  /// Standard BLE MTU (Maximum Transmission Unit) is 20 bytes.
  /// We use 18 bytes to account for protocol overhead (2-3 bytes).
  /// This ensures reliable transmission across all BLE devices.
  static const int bleChunkSize = 18;

  // ============================================================================
  // Timing & Delays
  // ============================================================================

  /// Delay after setting up notification subscription
  ///
  /// This delay ensures the BLE stack is ready to receive notifications
  /// before we start sending commands. Without this, first notifications
  /// might be missed.
  static const Duration subscriptionSetupDelay = Duration(milliseconds: 300);

  /// Delay between sending individual chunks
  ///
  /// This prevents overwhelming the BLE buffer and ensures each chunk
  /// is properly transmitted before the next one.
  static const Duration chunkSendDelay = Duration(milliseconds: 50);

  /// Delay before sending END delimiter
  ///
  /// Extra delay before END marker to ensure all data chunks are
  /// fully transmitted and processed by the device.
  static const Duration endDelimiterDelay = Duration(milliseconds: 100);

  /// Delay for command validation (Python compatibility)
  ///
  /// Matches Python implementation delay for stable transmission.
  static const Duration commandValidationDelay = Duration(milliseconds: 100);

  /// Delay after canceling old subscription
  ///
  /// Ensures old subscription is fully cancelled before creating new one.
  static const Duration subscriptionCancelDelay = Duration(milliseconds: 50);

  // ============================================================================
  // Scan Parameters
  // ============================================================================

  /// Default BLE scan duration
  static const Duration scanDuration = Duration(seconds: 10);

  /// Batch processing delay for scan results
  ///
  /// Collects multiple scan results and processes them together
  /// to reduce UI stuttering.
  static const Duration scanBatchDelay = Duration(milliseconds: 300);

  /// UI update debounce delay
  ///
  /// Prevents excessive UI updates during scanning.
  static const Duration uiUpdateDebounceDelay = Duration(milliseconds: 100);

  // ============================================================================
  // Command Timeouts
  // ============================================================================

  /// Default timeout for standard commands
  static const Duration defaultCommandTimeout = Duration(seconds: 60);

  /// Timeout for stop commands (should be quick)
  static const Duration stopCommandTimeout = Duration(seconds: 5);

  /// Timeout for device summary read (no registers)
  static const Duration devicesSummaryTimeout = Duration(seconds: 60);

  /// Timeout for single device read (may have 70 registers)
  ///
  /// Calculation: ~10KB / 18 bytes per chunk × 100ms = ~56s
  /// We add buffer for safety.
  static const Duration singleDeviceTimeout = Duration(seconds: 90);

  /// Timeout for registers read (may have 70 registers per device)
  static const Duration registersTimeout = Duration(seconds: 90);

  /// Timeout for paginated minimal mode (5-10 devices)
  ///
  /// Realistic: 10 devices × 70 registers = ~33 KB = ~183s
  /// We use 6 minutes for safety margin.
  static const Duration paginatedMinimalTimeout = Duration(
    seconds: 360,
  ); // 6 min

  /// Timeout for paginated full mode (5 devices max recommended)
  static const Duration paginatedFullTimeout = Duration(seconds: 360); // 6 min

  /// EXTREME timeout for all devices minimal mode (NOT RECOMMENDED!)
  ///
  /// Extreme: 70 devices × 70 registers = ~235 KB = ~1,305s
  static const Duration allDevicesMinimalTimeout = Duration(
    seconds: 1500,
  ); // 25 min

  /// ULTRA EXTREME timeout for all devices full mode (AVOID AT ALL COSTS!)
  ///
  /// Ultra extreme: 70 devices × 70 registers × full data = ~735 KB = ~4,083s
  /// This will take over 1 HOUR! Use pagination or minimal mode instead!
  static const Duration allDevicesFullTimeout = Duration(
    seconds: 4800,
  ); // 80 min

  // ============================================================================
  // Stream Parameters
  // ============================================================================

  /// Default stream inactivity timeout
  ///
  /// If no data received within this time, stream is considered inactive.
  static const Duration streamInactivityTimeout = Duration(seconds: 30);

  /// Delay before processing stop command
  ///
  /// Allows device to process stop command before cleanup.
  static const Duration stopCommandProcessDelay = Duration(milliseconds: 500);

  // ============================================================================
  // Buffer Limits (Memory Protection)
  // ============================================================================

  /// Maximum buffer size for streaming data
  ///
  /// Prevents memory overflow from excessive streaming data.
  static const int maxBufferSize = 1024 * 100; // 100KB

  /// Maximum size for partial data segments
  ///
  /// Prevents keeping too much incomplete data in memory.
  static const int maxPartialSize = 1024 * 10; // 10KB

  // ============================================================================
  // Navigation & UI
  // ============================================================================

  /// Delay before showing disconnect message
  static const Duration disconnectMessageDelay = Duration(seconds: 3);

  /// Delay before clearing error messages
  static const Duration errorMessageClearDelay = Duration(seconds: 3);

  /// Delay before clearing success messages
  static const Duration successMessageClearDelay = Duration(seconds: 2);

  /// Delay for navigation fallback check
  ///
  /// Waits for ever() callback to execute before fallback navigation.
  static const Duration navigationFallbackDelay = Duration(milliseconds: 500);

  // ============================================================================
  // Pagination
  // ============================================================================

  /// Default devices per page for pagination
  static const int defaultDevicesPerPage = 5;

  /// Maximum recommended devices per page
  ///
  /// Loading more than this may cause timeout or performance issues.
  static const int maxRecommendedDevicesPerPage = 10;

  /// Test pagination limit (for firmware capability check)
  static const int testPaginationLimit = 2;

  // ============================================================================
  // UUIDs
  // ============================================================================

  /// Service UUID for BLE communication
  static const String serviceUUID = '00001830-0000-1000-8000-00805f9b34fb';

  /// Command characteristic UUID (write)
  static const String commandUUID = '11111111-1111-1111-1111-111111111101';

  /// Response characteristic UUID (notify)
  static const String responseUUID = '11111111-1111-1111-1111-111111111102';

  // ============================================================================
  // Protocol Markers
  // ============================================================================

  /// End of transmission marker
  static const String endMarker = '<END>';

  // ============================================================================
  // Helper Methods
  // ============================================================================

  /// Get timeout duration based on command type
  ///
  /// This centralizes timeout logic for easier maintenance.
  static Duration getTimeoutForCommand(Map<String, dynamic> command) {
    final opType = command['op'] as String?;
    final commandType = command['type'] as String?;
    final isMinimal = command['minimal'] == true;
    final hasLimit = command['limit'] != null;
    final isStopCommand = command['device_id'] == 'stop';

    if (isStopCommand) {
      return stopCommandTimeout;
    }

    if (opType == 'read' && commandType == 'devices_with_registers') {
      if (isMinimal) {
        return hasLimit ? paginatedMinimalTimeout : allDevicesMinimalTimeout;
      } else {
        return hasLimit ? paginatedFullTimeout : allDevicesFullTimeout;
      }
    } else if (opType == 'read' && commandType == 'devices_summary') {
      return devicesSummaryTimeout;
    } else if (opType == 'read' && commandType == 'device') {
      return singleDeviceTimeout;
    } else if (opType == 'read' && commandType == 'registers') {
      return registersTimeout;
    } else if (opType == 'read') {
      return defaultCommandTimeout;
    }

    return defaultCommandTimeout;
  }

  /// Validate if pagination should be enforced
  ///
  /// Returns true if command requires pagination for safety.
  static bool shouldEnforcePagination(Map<String, dynamic> command) {
    final commandType = command['type'] as String?;
    final hasLimit = command['limit'] != null;

    // Enforce pagination for large data operations
    if (commandType == 'devices_with_registers' && !hasLimit) {
      return true; // ALWAYS use pagination for devices with registers
    }

    return false;
  }
}
