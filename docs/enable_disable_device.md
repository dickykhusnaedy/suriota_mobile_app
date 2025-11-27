# Enable/Disable Device Feature Documentation

**Version:** 1.0.0
**Last Updated:** November 26, 2025
**Component:** Device Communications Screen
**File:** `lib/presentation/pages/devices/device_communication/device_communications_screen.dart`

---

## 📋 Table of Contents

1. [Overview](#overview)
2. [Features](#features)
3. [Architecture](#architecture)
4. [Implementation Details](#implementation-details)
5. [API Integration](#api-integration)
6. [User Flow](#user-flow)
7. [Code Examples](#code-examples)
8. [Testing Guide](#testing-guide)
9. [Troubleshooting](#troubleshooting)

---

## Overview

The **Enable/Disable Device Feature** allows users to remotely control Modbus devices (both RTU and TCP) through the mobile application. Users can enable or disable devices with a simple toggle switch, with confirmation dialogs and real-time status updates.

### Key Capabilities

✅ **Real-time Status Display**: Shows current device status (Active/Disabled)
✅ **Toggle Control**: Simple switch to enable/disable devices
✅ **Confirmation Dialogs**: Prevents accidental changes
✅ **Auto-refresh**: Status updates automatically after changes
✅ **Visual Feedback**: Color-coded status indicators (green/grey)
✅ **Error Handling**: User-friendly error messages

---

## Features

### 1. Device Status Display

Each device card displays:

- **Status Badge**: Shows "Active" (green) or "Disabled" (grey)
- **Toggle Switch**: Interactive switch to change status
- **Visual Theme**: Background and border colors match status

### 2. Enable Device

**Action**: Change device status from Disabled to Active

**What Happens:**

1. User taps the toggle switch on a disabled device
2. Confirmation dialog appears: "Are you sure you want to enable this device?"
3. User confirms by tapping "Yes"
4. BLE command sent to gateway
5. Device status updated in cache
6. UI refreshes automatically
7. Success message displayed

**API Payload:**

```json
{
  "op": "control",
  "type": "enable_device",
  "device_id": "D7A3F2",
  "clear_metrics": false
}
```

### 3. Disable Device

**Action**: Change device status from Active to Disabled

**What Happens: **

1. User taps the toggle switch on an active device
2. Confirmation dialog appears: "Are you sure you want to disable this device?"
3. User confirms by tapping "Yes"
4. BLE command sent to gateway with reason
5. Device status updated in cache
6. UI refreshes automatically
7. Success message displayed

**API Payload:**

```json
{
  "op": "control",
  "type": "disable_device",
  "device_id": "D7A3F2",
  "reason": "Manual disable via mobile app"
}
```

### 4. Get Device Status

**Purpose**: Fetch current status of a specific device

**When Called:**

- After successful enable/disable operation
- To refresh individual device status

**API Payload:**

```json
{
  "op": "control",
  "type": "get_device_status",
  "device_id": "D7A3F2"
}
```

**Response:**

```json
{
  "status": "ok",
  "device_status": {
    "device_id": "D7A3F2",
    "enabled": true,
    "consecutive_failures": 0,
    "retry_count": 0,
    "disable_reason": "NONE",
    "disable_reason_detail": "",
    "metrics": {
      "total_reads": 1250,
      "successful_reads": 1238,
      "failed_reads": 12,
      "success_rate": 99.04,
      "avg_response_time_ms": 245
    }
  }
}
```

### 5. Get All Device Status

**Purpose**: Fetch status of all devices (RTU and TCP) at once

**When Called:**

- On page initialization (first time opening the screen)
- After pull-to-refresh

**API Payload:**

```json
{
  "op": "control",
  "type": "get_all_device_status"
}
```

**Response:**

```json
{
  "status": "ok",
  "rtu_devices": {
    "devices": [
      {
        "device_id": "D7A3F2",
        "enabled": true,
        "metrics": { ... }
      }
    ],
    "total_devices": 1
  },
  "tcp_devices": {
    "devices": [
      {
        "device_id": "E8F4G5",
        "enabled": false,
        "disable_reason": "MANUAL",
        "metrics": { ... }
      }
    ],
    "total_devices": 1
  }
}
```

---

## Architecture

### State Management

The feature uses **GetX** for reactive state management:

```dart
// Device status cache (deviceId -> enabled status)
final RxMap<String, bool> deviceStatusCache = <String, bool>{}.obs;
```

### Component Structure

```
DeviceCommunicationsScreen (StatefulWidget)
│
├── State Management
│   └── deviceStatusCache (RxMap<String, bool>)
│
├── Lifecycle Methods
│   ├── initState()
│   ├── didChangeDependencies()
│   │   └── _getAllDeviceStatus()
│   └── dispose()
│
├── Core Functions
│   ├── _getAllDeviceStatus()
│   ├── _getDeviceStatus(deviceId)
│   └── _enableDisableDevice(deviceId, currentStatus)
│
└── UI Components
    └── _cardDeviceConnection() [Wrapped with Obx]
        ├── Status Badge
        ├── Toggle Switch
        └── Action Buttons
```

---

## Implementation Details

### 1. State Initialization

```dart
@override
void didChangeDependencies() {
  super.didChangeDependencies();
  if (!isInitialized) {
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      // Fetch devices list
      await controller.fetchDevicesIfNeeded(widget.model);

      // Fetch status for all devices
      await _getAllDeviceStatus();

      isInitialized = true;
    });
  }
}
```

### 2. Get All Device Status

```dart
Future<void> _getAllDeviceStatus() async {
  if (!widget.model.isConnected.value) {
    return;
  }

  try {
    final command = {
      "op": "control",
      "type": "get_all_device_status",
    };

    final response = await bleController.sendCommand(command);

    if (response.status == 'ok') {
      // Parse RTU devices
      if (response.config?['rtu_devices']?['devices'] != null) {
        final rtuDevices =
            response.config!['rtu_devices']['devices'] as List<dynamic>;
        for (var device in rtuDevices) {
          final deviceId = device['device_id'] as String?;
          final enabled = device['enabled'] as bool? ?? true;
          if (deviceId != null) {
            deviceStatusCache[deviceId] = enabled;
          }
        }
      }

      // Parse TCP devices
      if (response.config?['tcp_devices']?['devices'] != null) {
        final tcpDevices =
            response.config!['tcp_devices']['devices'] as List<dynamic>;
        for (var device in tcpDevices) {
          final deviceId = device['device_id'] as String?;
          final enabled = device['enabled'] as bool? ?? true;
          if (deviceId != null) {
            deviceStatusCache[deviceId] = enabled;
          }
        }
      }

      AppHelpers.debugLog(
        'Device status fetched: ${deviceStatusCache.length} devices',
      );
    }
  } catch (e) {
    AppHelpers.debugLog('Error fetching all device status: $e');
  }
}
```

### 3. Get Single Device Status

```dart
Future<bool?> _getDeviceStatus(String deviceId) async {
  if (!widget.model.isConnected.value) {
    return null;
  }

  try {
    final command = {
      "op": "control",
      "type": "get_device_status",
      "device_id": deviceId,
    };

    final response = await bleController.sendCommand(command);

    if (response.status == 'ok' && response.config?['device_status'] != null) {
      final enabled =
          response.config!['device_status']['enabled'] as bool? ?? true;
      deviceStatusCache[deviceId] = enabled;
      AppHelpers.debugLog('Device $deviceId status: $enabled');
      return enabled;
    }
  } catch (e) {
    AppHelpers.debugLog('Error fetching device status for $deviceId: $e');
  }
  return null;
}
```

### 4. Enable/Disable Device

```dart
Future<void> _enableDisableDevice(String deviceId, bool currentStatus) async {
  if (!widget.model.isConnected.value) {
    SnackbarCustom.showSnackbar(
      '',
      'Device not connected',
      AppColor.redColor,
      AppColor.whiteColor,
    );
    return;
  }

  final bool willEnable = !currentStatus;
  final String action = willEnable ? 'enable' : 'disable';
  final String actionCapitalized = willEnable ? 'Enable' : 'Disable';

  CustomAlertDialog.show(
    title: "Are you sure?",
    message: "Are you sure you want to $action this device?",
    primaryButtonText: 'Yes',
    secondaryButtonText: 'No',
    onPrimaryPressed: () async {
      Get.back();
      controller.isFetching.value = true;

      try {
        Map<String, dynamic> command;

        if (willEnable) {
          // Enable device
          command = {
            "op": "control",
            "type": "enable_device",
            "device_id": deviceId,
            "clear_metrics": false,
          };
        } else {
          // Disable device
          command = {
            "op": "control",
            "type": "disable_device",
            "device_id": deviceId,
            "reason": "Manual disable via mobile app",
          };
        }

        final response = await bleController.sendCommand(command);

        if (response.status == 'ok') {
          SnackbarCustom.showSnackbar(
            '',
            'Device ${actionCapitalized.toLowerCase()}d successfully',
            Colors.green,
            AppColor.whiteColor,
          );

          // Update cache
          deviceStatusCache[deviceId] = willEnable;

          // Refresh device status
          await _getDeviceStatus(deviceId);
        } else {
          SnackbarCustom.showSnackbar(
            '',
            'Failed to $action device: ${response.message}',
            AppColor.redColor,
            AppColor.whiteColor,
          );
        }
      } catch (e) {
        SnackbarCustom.showSnackbar(
          '',
          'Failed to $action device',
          AppColor.redColor,
          AppColor.whiteColor,
        );
        AppHelpers.debugLog('Error ${action}ing device: $e');
      } finally {
        controller.isFetching.value = false;
      }
    },
    barrierDismissible: false,
  );
}
```

### 5. Reactive UI Component

```dart
Widget _cardDeviceConnection(
  BuildContext context,
  String deviceId,
  String title,
  String modbusType,
  int registerCount,
) {
  return Obx(() {
    // Get status from cache (default to true if not found)
    final bool isActive = deviceStatusCache[deviceId] ?? true;

    return Container(
      decoration: BoxDecoration(
        color: AppColor.whiteColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColor.primaryColor.withValues(alpha: 0.15),
          width: 1.5,
        ),
      ),
      child: Column(
        children: [
          // Header with status and toggle
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: isActive
                  ? Colors.green.withValues(alpha: 0.05)
                  : AppColor.grey.withValues(alpha: 0.05),
            ),
            child: Row(
              children: [
                // Status Badge
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: isActive
                        ? Colors.green.withValues(alpha: 0.15)
                        : AppColor.grey.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: isActive ? Colors.green : AppColor.grey,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        isActive ? 'Active' : 'Disabled',
                        style: context.bodySmall.copyWith(
                          color: isActive
                              ? Colors.green.shade700
                              : AppColor.grey,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                // Toggle Switch
                Transform.scale(
                  scale: 0.75,
                  child: Switch(
                    value: isActive,
                    onChanged: (value) {
                      _enableDisableDevice(deviceId, isActive);
                    },
                    activeThumbColor: Colors.green,
                    activeTrackColor: Colors.green.withValues(alpha: 0.5),
                    inactiveThumbColor: AppColor.grey,
                    inactiveTrackColor: AppColor.grey.withValues(alpha: 0.3),
                  ),
                ),
              ],
            ),
          ),
          // ... rest of card content
        ],
      ),
    );
  });
}
```

---

## API Integration

### Base Command Structure

All device control commands follow this structure:

```dart
final command = {
  "op": "control",
  "type": "<command_type>",
  // additional fields...
};
```

### Command Types

| Command Type            | Purpose                       | Additional Fields            |
| ----------------------- | ----------------------------- | ---------------------------- |
| `get_all_device_status` | Get status of all devices     | None                         |
| `get_device_status`     | Get status of specific device | `device_id`                  |
| `enable_device`         | Enable a device               | `device_id`, `clear_metrics` |
| `disable_device`        | Disable a device              | `device_id`, `reason`        |

### Response Handling

All responses follow this structure:

```dart
if (response.status == 'ok') {
  // Success - process response.config
} else {
  // Error - show response.message
}
```

---

## User Flow

### Flow Diagram

```
User Opens Screen
       ↓
Fetch Device List
       ↓
Get All Device Status
       ↓
Display Cards with Status
       ↓
User Taps Toggle Switch
       ↓
Show Confirmation Dialog
       ↓
   User Confirms?
       ├─ Yes → Send BLE Command
       │         ↓
       │    Command Success?
       │         ├─ Yes → Update Cache
       │         │         ↓
       │         │    Refresh Status
       │         │         ↓
       │         │    Show Success Message
       │         │         ↓
       │         │    Update UI (Reactive)
       │         │
       │         └─ No → Show Error Message
       │
       └─ No → Cancel (No Action)
```

### User Interactions

#### 1. View Device Status

1. User opens Device Communications screen
2. App fetches device list
3. App fetches status for all devices
4. Device cards display with current status
5. Status badge shows "Active" (green) or "Disabled" (grey)

#### 2. Enable Device

1. User sees a disabled device (grey badge)
2. User taps the toggle switch
3. Confirmation dialog appears: "Are you sure you want to enable this device?"
4. User taps "Yes"
5. Loading indicator appears
6. BLE command sent to gateway
7. Success message appears
8. Device card updates to show "Active" status (green)

#### 3. Disable Device

1. User sees an active device (green badge)
2. User taps the toggle switch
3. Confirmation dialog appears: "Are you sure you want to disable this device?"
4. User taps "Yes"
5. Loading indicator appears
6. BLE command sent to gateway with reason
7. Success message appears
8. Device card updates to show "Disabled" status (grey)

#### 4. Connection Lost

1. User tries to toggle a device
2. BLE connection is lost
3. Error message appears: "Device not connected"
4. No API call is made
5. UI remains unchanged

---

## Code Examples

### Example 1: Check if Device is Active

```dart
bool isDeviceActive(String deviceId) {
  return deviceStatusCache[deviceId] ?? true;
}
```

### Example 2: Manual Status Refresh

```dart
// Refresh single device
await _getDeviceStatus('D7A3F2');

// Refresh all devices
await _getAllDeviceStatus();
```

### Example 3: Enable Device Programmatically

```dart
await _enableDisableDevice('D7A3F2', false); // false = currently disabled, will enable
```

### Example 4: Listen to Status Changes

```dart
// Status changes are automatically reflected in UI via Obx
Obx(() {
  final isActive = deviceStatusCache['D7A3F2'] ?? true;
  return Text(isActive ? 'Device is Active' : 'Device is Disabled');
});
```

---

## Testing Guide

### Manual Testing Checklist

#### Basic Functionality

- [ ] Open Device Communications screen
- [ ] Verify all devices show correct initial status
- [ ] Tap toggle on an active device
- [ ] Confirm disable dialog appears with correct text
- [ ] Tap "Yes" to confirm
- [ ] Verify success message appears
- [ ] Verify device status changes to "Disabled"
- [ ] Verify visual changes (badge color, background)
- [ ] Tap toggle on disabled device
- [ ] Confirm enable dialog appears with correct text
- [ ] Tap "Yes" to confirm
- [ ] Verify success message appears
- [ ] Verify device status changes to "Active"

#### Error Handling

- [ ] Disconnect BLE
- [ ] Try to toggle device
- [ ] Verify "Device not connected" error appears
- [ ] Reconnect BLE
- [ ] Verify toggle works again

#### Pull to Refresh

- [ ] Pull down to refresh
- [ ] Verify status refreshes for all devices
- [ ] Verify loading indicator appears

#### Multiple Devices

- [ ] Test with multiple devices (RTU and TCP)
- [ ] Toggle different devices
- [ ] Verify each device maintains independent status

#### Dialog Cancellation

- [ ] Tap toggle switch
- [ ] In confirmation dialog, tap "No" or tap outside
- [ ] Verify no change occurs
- [ ] Verify UI remains unchanged

### Expected Behaviors

| Scenario         | Expected Behavior                                   |
| ---------------- | --------------------------------------------------- |
| First load       | All device status fetched and cached                |
| Enable device    | Status changes from Disabled to Active, green theme |
| Disable device   | Status changes from Active to Disabled, grey theme  |
| Toggle cancelled | No change, original status maintained               |
| BLE disconnected | Error message, no API call                          |
| API error        | Error message with reason, status unchanged         |
| Pull to refresh  | All status re-fetched from gateway                  |

---

## Troubleshooting

### Common Issues

#### Issue: Status not updating after toggle

**Possible Causes:**

- BLE command failed
- Response not parsed correctly
- Cache not updated

**Solutions:**

1. Check BLE connection status
2. Check debug logs for API response
3. Verify response format matches expected structure
4. Force refresh by pulling down

#### Issue: Wrong status displayed

**Possible Causes:**

- Initial fetch failed
- Cache not populated
- Response parsing error

**Solutions:**

1. Pull to refresh
2. Check `_getAllDeviceStatus()` logs
3. Verify response structure from gateway
4. Check if device exists in cache

#### Issue: Confirmation dialog doesn't appear

**Possible Causes:**

- UI blocking issue
- Dialog widget error

**Solutions:**

1. Check for overlay widgets
2. Verify `CustomAlertDialog.show()` is called
3. Check console for widget errors

#### Issue: "Device not connected" always shown

**Possible Causes:**

- BLE disconnected
- `widget.model.isConnected.value` is false

**Solutions:**

1. Reconnect to gateway via BLE
2. Check connection status in app bar
3. Navigate back and reconnect

### Debug Logging

Enable debug logs to troubleshoot:

```dart
// In _getAllDeviceStatus()
AppHelpers.debugLog('Device status fetched: ${deviceStatusCache.length} devices');

// In _getDeviceStatus()
AppHelpers.debugLog('Device $deviceId status: $enabled');

// In _enableDisableDevice()
AppHelpers.debugLog('Error ${action}ing device: $e');
```

View logs in:

- Android: Android Studio Logcat
- iOS: Xcode Console
- Run: `flutter logs`

### API Response Validation

If status not updating, validate API responses:

```dart
// Expected response for get_device_status
{
  "status": "ok",
  "device_status": {
    "device_id": "D7A3F2",
    "enabled": true,
    ...
  }
}

// Expected response for enable_device
{
  "status": "ok",
  "device_id": "D7A3F2",
  "message": "Device enabled",
  "metrics_cleared": false
}

// Expected response for disable_device
{
  "status": "ok",
  "device_id": "D7A3F2",
  "message": "Device disabled",
  "reason": "Manual disable via mobile app"
}
```

---

## Best Practices

### 1. Status Caching

✅ **Do:**

- Cache status in `RxMap` for reactive updates
- Update cache immediately after successful API calls
- Use cache as source of truth for UI

❌ **Don't:**

- Query API for every UI rebuild
- Store status in local state variables
- Ignore cache updates

### 2. Error Handling

✅ **Do:**

- Check BLE connection before API calls
- Show user-friendly error messages
- Log errors for debugging
- Handle null/undefined gracefully

❌ **Don't:**

- Assume API always succeeds
- Show raw error messages to users
- Ignore error responses

### 3. User Experience

✅ **Do:**

- Show confirmation dialogs for destructive actions
- Provide visual feedback (loading indicators)
- Use color coding for status (green/grey)
- Show success messages

❌ **Don't:**

- Allow toggle without confirmation
- Hide loading states
- Use ambiguous status indicators

### 4. Performance

✅ **Do:**

- Fetch all device status once on page load
- Use reactive state management (Obx)
- Minimize unnecessary API calls

❌ **Don't:**

- Fetch status on every UI rebuild
- Poll API continuously
- Create memory leaks with listeners

---

## Future Enhancements

### Planned Features

1. **Batch Operations**

   - Enable/disable multiple devices at once
   - Bulk status refresh

2. **Advanced Status Display**

   - Show health metrics (success rate, response time)
   - Display disable reason detail
   - Show last update timestamp

3. **Auto-refresh**

   - Optional periodic status polling
   - Real-time status updates via notifications

4. **Status History**

   - Log of enable/disable actions
   - Timeline view of status changes

5. **Filtering**
   - Filter by status (Active/Disabled)
   - Search by device name/ID

---

## API Reference

For complete API documentation, refer to:

📄 **File:** `D:\dicky\project\suriota\arduino\GatewaySuriotaPOC\Documentation\API_Reference\BLE_DEVICE_CONTROL.md`

**Key Sections:**

- Section 1: `enable_device`
- Section 2: `disable_device`
- Section 3: `get_device_status`
- Section 4: `get_all_device_status`

---

## Change Log

| Version | Date       | Changes                                                 |
| ------- | ---------- | ------------------------------------------------------- |
| 1.0.0   | 2025-11-26 | Initial implementation of enable/disable device feature |

---

**Made with ❤️ by SURIOTA Mobile Team**
_Empowering Industrial IoT Solutions_
