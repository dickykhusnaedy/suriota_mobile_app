# BLE Controller Refactoring Guide

## 📋 Overview

This guide provides step-by-step instructions to refactor `ble_controller.dart` using the newly created utility files:

- `ble_constants.dart` - Centralized constants
- `ble_errors.dart` - Error messages
- `ble_helper.dart` - Reusable helper functions

## 🎯 Goals

1. ✅ Remove all magic numbers
2. ✅ Centralize error messages
3. ✅ Eliminate duplicate code
4. ✅ Improve maintainability
5. ✅ Better documentation

---

## 📝 Step-by-Step Refactoring

### **Step 1: Update Imports** ✓ (Already Done)

The imports have been added:

```dart
import 'package:gateway_config/core/constants/ble_constants.dart';
import 'package:gateway_config/core/constants/ble_errors.dart';
import 'package:gateway_config/core/utils/ble_helper.dart';
```

### **Step 2: Replace Buffer Size Constants** ✓ (Already Done)

**Lines to Update:** 1907, 1998, 2201, 2320

**Before:**

```dart
static const int maxBufferSize = 1024 * 100; // 100KB
static const int maxPartialSize = 1024 * 10; // 10KB

if (streamBuffer.length > maxBufferSize) {
if (parts.last.length > maxPartialSize) {
```

**After:**

```dart
// Remove the constants (lines 44-45)
// Use BLEConstants instead:
if (streamBuffer.length > BLEConstants.maxBufferSize) {
if (parts.last.length > BLEConstants.maxPartialSize) {
```

✅ **Status:** COMPLETED

---

### **Step 3: Replace Magic Numbers in sendCommand()**

**Lines to Update:** 1000, 1010, 1167, 1190, 1202

#### 3.1 Chunk Size (Line ~1000)

**Before:**

```dart
const chunkSize = 18;
```

**After:**

```dart
const chunkSize = BLEConstants.bleChunkSize;
```

#### 3.2 Subscription Cancel Delay (Line ~1010)

**Before:**

```dart
await Future.delayed(const Duration(milliseconds: 50));
```

**After:**

```dart
await Future.delayed(BLEConstants.subscriptionCancelDelay);
```

#### 3.3 Subscription Setup Delay (Line ~1167)

**Before:**

```dart
await Future.delayed(const Duration(milliseconds: 300));
```

**After:**

```dart
await Future.delayed(BLEConstants.subscriptionSetupDelay);
```

#### 3.4 Chunk Send Delay (Line ~1190)

**Before:**

```dart
await Future.delayed(const Duration(milliseconds: 100));
```

**After:**

```dart
await Future.delayed(BLEConstants.commandValidationDelay);
```

#### 3.5 END Delimiter Delay (Line ~1202)

**Before:**

```dart
await Future.delayed(const Duration(milliseconds: 100));
```

**After:**

```dart
await Future.delayed(BLEConstants.endDelimiterDelay);
```

---

### **Step 4: Replace Error Messages with BLEErrors**

#### 4.1 Connection Errors (Lines ~967-973)

**Before:**

```dart
if (commandChar == null || responseChar == null) {
  errorMessage.value = 'Not connected';
  return CommandResponse(
    status: 'error',
    message: 'Not connected',
    type: command['type'] ?? 'device',
  );
}
```

**After:**

```dart
if (commandChar == null || responseChar == null) {
  errorMessage.value = BLEErrors.notConnected;
  return CommandResponse(
    status: 'error',
    message: BLEErrors.notConnected,
    type: command['type'] ?? 'device',
  );
}
```

#### 4.2 Invalid Command Format (Lines ~977-983)

**Before:**

```dart
if (!command.containsKey('op') || !command.containsKey('type')) {
  errorMessage.value = 'Invalid command format';
  return CommandResponse(
    status: 'error',
    message: 'Invalid command format',
    type: command['type'] ?? 'device',
  );
}
```

**After:**

```dart
if (!BLEHelper.isValidCommand(command)) {
  errorMessage.value = BLEErrors.invalidCommandFormat;
  return CommandResponse(
    status: 'error',
    message: BLEErrors.invalidCommandFormat,
    type: command['type'] ?? 'device',
  );
}
```

#### 4.3 Other Error Messages to Replace

Find and replace throughout the file:

| Line(s) | Before                                      | After                                                                  |
| ------- | ------------------------------------------- | ---------------------------------------------------------------------- |
| ~425    | `'Service not found'`                       | `BLEErrors.serviceNotFound`                                            |
| ~1120   | `'Invalid response JSON: $e'`               | `BLEErrors.withDetails(BLEErrors.responseParsingFailed, e.toString())` |
| ~1146   | `'Notification error: $e'`                  | `BLEErrors.withDetails(BLEErrors.notConnected, e.toString())`          |
| ~1406   | `'Error sending command: $e'`               | `BLEErrors.withDetails(BLEErrors.commandSendFailed, e.toString())`     |
| ~1854   | `'Not connected'`                           | `BLEErrors.notConnected`                                               |
| ~1886   | `'Buffer overflow - data stream too large'` | `BLEErrors.bufferOverflow`                                             |
| ~2025   | `'Error starting stream: $e'`               | `BLEErrors.withDetails(BLEErrors.streamStartFailed, e.toString())`     |

---

### **Step 5: Use BLEHelper for Response Cleaning**

#### 5.1 Clean Response (Lines ~1047-1049)

**Before:**

```dart
final cleanedResponse = fullResponse
    .replaceAll(RegExp(r'[\x00-\x1F\x7F]'), '')
    .trim();
```

**After:**

```dart
final cleanedResponse = BLEHelper.cleanResponse(fullResponse);
```

#### 5.2 Validation (Line ~1068)

**Before:**

```dart
if (cleanedResponse.isEmpty) {
```

**After:**

```dart
if (cleanedResponse.isEmpty || !BLEHelper.looksLikeJson(cleanedResponse)) {
```

---

### **Step 6: Replace Timeout Logic with BLEConstants**

**Lines to Update:** 1217-1310

**Before:**

```dart
Duration timeoutDuration;

if (isStopCommand) {
  timeoutDuration = const Duration(seconds: 5);
} else if (opType == 'read' && commandType == 'devices_with_registers') {
  // ... complex logic
  timeoutDuration = const Duration(seconds: 360);
} else if (opType == 'read' && commandType == 'devices_summary') {
  timeoutDuration = const Duration(seconds: 60);
}
// ... etc
```

**After:**

```dart
final timeoutDuration = BLEConstants.getTimeoutForCommand(command);

// Log warning for long timeouts
BLEHelper.logTimeoutWarning(timeoutDuration, 'sendCommand');
```

This replaces ~100 lines of timeout logic with 2 lines!

---

### **Step 7: Extract Command Sending to BLEHelper**

**Lines to Update:** 1176-1209

**Before:**

```dart
// Send command in chunks
StringBuffer sentCommand = StringBuffer();
for (int i = 0; i < jsonStr.length; i += chunkSize) {
  String chunk = jsonStr.substring(
    i,
    (i + chunkSize > jsonStr.length) ? jsonStr.length : i + chunkSize,
  );
  sentCommand.write(chunk);
  await commandChar!.write(
    utf8.encode(chunk),
    withoutResponse: !useWriteWithResponse,
  );
  AppHelpers.debugLog('Sent chunk: $chunk');
  currentChunk++;
  commandProgress.value = currentChunk / totalChunks;
  await Future.delayed(const Duration(milliseconds: 100));
}

// Add delay before sending <END>
await Future.delayed(const Duration(milliseconds: 100));
await commandChar!.write(
  utf8.encode('<END>'),
  withoutResponse: !useWriteWithResponse,
);
AppHelpers.debugLog('Sent chunk: <END>');
currentChunk++;
commandProgress.value = 1.0;
```

**After:**

```dart
// Send command using BLEHelper
await BLEHelper.sendBLECommand(
  commandChar,
  command,
  onProgress: (progress) {
    commandProgress.value = progress;
  },
);
```

This replaces ~40 lines with 6 lines!

---

### **Step 8: Replace Hardcoded Delays in Streaming**

#### 8.1 startDataStream() (Lines ~2017-2048)

**Before:**

```dart
await responseChar!.setNotifyValue(true);
await Future.delayed(const Duration(milliseconds: 300));

// ... chunk sending code ...
await Future.delayed(const Duration(milliseconds: 50));

// ... END marker ...
await Future.delayed(const Duration(milliseconds: 100));
```

**After:**

```dart
await responseChar!.setNotifyValue(true);
await Future.delayed(BLEConstants.subscriptionSetupDelay);

// Use BLEHelper for sending
await BLEHelper.sendBLECommand(commandChar, startCommand);
```

#### 8.2 stopDataStream() (Lines ~2074-2110)

Replace similar delays with BLEConstants.

#### 8.3 startStreamDevice() & stopStreamDevice()

Same pattern - replace hardcoded delays.

---

### **Step 9: Use BLEConstants for Scan Parameters**

**Lines to Update:** 136, 147, 175, 205

#### 9.1 Scan Duration (Line ~136)

**Before:**

```dart
await FlutterBluePlus.startScan(timeout: const Duration(seconds: 10));
```

**After:**

```dart
await FlutterBluePlus.startScan(timeout: BLEConstants.scanDuration);
```

#### 9.2 Batch Processing Delay (Line ~175)

**Before:**

```dart
_batchProcessTimer = Timer(const Duration(milliseconds: 300), () {
```

**After:**

```dart
_batchProcessTimer = Timer(BLEConstants.scanBatchDelay, () {
```

#### 9.3 UI Update Debounce (Line ~205)

**Before:**

```dart
_uiUpdateDebounceTimer = Timer(const Duration(milliseconds: 100), () {
```

**After:**

```dart
_uiUpdateDebounceTimer = Timer(BLEConstants.uiUpdateDebounceDelay, () {
```

---

### **Step 10: Replace Success Messages with BLEMessages**

**Lines to Update:** 393, 467, 483, 662

#### 10.1 Connection Messages

**Before:**

```dart
message.value = 'Connecting device...';
message.value = 'Success connected...';
message.value = 'Disconnecting...';
message.value = 'Success disconnected...';
```

**After:**

```dart
message.value = BLEMessages.connecting;
message.value = BLEMessages.connected;
message.value = BLEMessages.disconnecting;
message.value = BLEMessages.disconnected;
```

#### 10.2 Disconnect Redirect Message (Lines ~282, 543)

**Before:**

```dart
'Device disconnect, will be redirect to home in 3 seconds.'
```

**After:**

```dart
BLEMessages.deviceWillRedirect
```

---

### **Step 11: Replace Navigation Delays**

**Lines to Update:** 288, 459, 550, 578, 666

**Before:**

```dart
Future.delayed(const Duration(seconds: 3), () {
Future.delayed(const Duration(seconds: 2), () {
Future.delayed(const Duration(milliseconds: 500), () {
```

**After:**

```dart
Future.delayed(BLEConstants.disconnectMessageDelay, () {
Future.delayed(BLEConstants.successMessageClearDelay, () {
Future.delayed(BLEConstants.navigationFallbackDelay, () {
```

---

### **Step 12: Add Validation Using BLEHelper**

#### 12.1 Device ID Validation (New)

Add validation before connecting:

```dart
Future<void> connectToDevice(DeviceModel deviceModel) async {
  // Add validation
  final deviceId = deviceModel.device.remoteId.toString();
  if (!BLEHelper.isValidDeviceId(deviceId)) {
    errorMessage.value = BLEErrors.invalidDeviceId;
    return;
  }

  // ... rest of code
}
```

#### 12.2 Bluetooth State Validation (New)

Add at start of `connectToDevice()`:

```dart
// Validate BLE state first
final adapterState = await FlutterBluePlus.adapterState.first;
if (adapterState != BluetoothAdapterState.on) {
  errorMessage.value = BLEErrors.bluetoothOff;
  return;
}
```

---

### **Step 13: Use BLEHelper for Logging**

Replace verbose logging with helper methods:

**Before:**

```dart
AppHelpers.debugLog('Full command JSON: $jsonStr');
AppHelpers.debugLog('Full response (${fullResponse.length} bytes): $fullResponse');
```

**After:**

```dart
BLEHelper.logCommand(command, prefix: 'Sending: ');
BLEHelper.logResponse(fullResponse, prefix: 'Received: ');
```

---

### **Step 14: Replace END Marker String**

**Lines to Update:** 1035, 1204, 1920, 2047, 2078, etc.

**Before:**

```dart
if (chunk == '<END>') {
await commandChar!.write(utf8.encode('<END>'), ...);
if (chunk.contains('<END>')) {
```

**After:**

```dart
if (chunk == BLEConstants.endMarker) {
await commandChar!.write(utf8.encode(BLEConstants.endMarker), ...);
if (chunk.contains(BLEConstants.endMarker)) {
```

---

### **Step 15: Use BLEConstants for Pagination**

**Lines to Update:** 758, 804, 837

**Before:**

```dart
int devicesPerPage = 5,
"limit": 2,
```

**After:**

```dart
int devicesPerPage = BLEConstants.defaultDevicesPerPage,
"limit": BLEConstants.testPaginationLimit,
```

---

## 🧪 Testing Checklist

After refactoring, test these scenarios:

- [ ] Device scanning works
- [ ] Device connection/disconnection works
- [ ] Command sending works (with timeout)
- [ ] Data streaming works
- [ ] Error messages display correctly
- [ ] Buffer overflow protection works
- [ ] Pagination works (if firmware supports it)
- [ ] Navigation after disconnect works
- [ ] All timeouts work as expected

---

## 📊 Expected Results

### Code Metrics Before vs After:

| Metric           | Before   | After | Improvement |
| ---------------- | -------- | ----- | ----------- |
| Total Lines      | 2502     | ~2200 | -12%        |
| Magic Numbers    | 25+      | 0     | -100%       |
| Duplicate Code   | 4 places | 0     | -100%       |
| Hardcoded Errors | 20+      | 0     | -100%       |
| Maintainability  | Low      | High  | ⬆️          |

### Benefits:

1. ✅ **Easier to maintain** - Change timeout in one place
2. ✅ **Easier to test** - Mock BLEConstants for testing
3. ✅ **Easier to localize** - All messages in one place
4. ✅ **Self-documenting** - Constants have clear names
5. ✅ **Less error-prone** - No typos in magic numbers

---

## 🚀 Next Steps (Future Improvements)

After this refactoring is complete, consider:

1. **Split into Multiple Controllers** (as mentioned in analysis)

   - `BleScannerController`
   - `BleConnectionController`
   - `BleCommandController`
   - `BleStreamController`

2. **Add Dependency Injection**

   - Create `IBleService` interface
   - Make code testable with mocks

3. **Add Comprehensive Tests**

   - Unit tests for each method
   - Integration tests for workflows

4. **Add State Management**
   - Use proper state machine for connection states
   - Prevent race conditions

---

## 📝 Notes

- Make changes incrementally and test after each step
- Commit after each major step
- Keep old code commented out initially for reference
- Run `flutter analyze` after each step to catch errors early

---

## ✅ Completion Checklist

- [ ] Step 1: Update Imports ✓
- [ ] Step 2: Replace Buffer Constants ✓
- [ ] Step 3: Replace Magic Numbers in sendCommand()
- [ ] Step 4: Replace Error Messages
- [ ] Step 5: Use BLEHelper for Response Cleaning
- [ ] Step 6: Replace Timeout Logic
- [ ] Step 7: Extract Command Sending
- [ ] Step 8: Replace Streaming Delays
- [ ] Step 9: Use Scan Parameters
- [ ] Step 10: Replace Success Messages
- [ ] Step 11: Replace Navigation Delays
- [ ] Step 12: Add Validation
- [ ] Step 13: Use Logging Helpers
- [ ] Step 14: Replace END Marker
- [ ] Step 15: Use Pagination Constants
- [ ] Run all tests
- [ ] Update documentation

---

**Good luck with the refactoring! 🎉**

If you encounter any issues, refer back to the utility files:

- `ble_constants.dart` - For all constant values
- `ble_errors.dart` - For error messages
- `ble_helper.dart` - For helper functions
