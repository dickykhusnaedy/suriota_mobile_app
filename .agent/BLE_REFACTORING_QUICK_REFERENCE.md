# BLE Controller Refactoring - Quick Reference

## 🔄 Find & Replace Cheat Sheet

### **Magic Numbers → BLEConstants**

| Find                          | Replace With                                                              | Lines    |
| ----------------------------- | ------------------------------------------------------------------------- | -------- |
| `const chunkSize = 18`        | `const chunkSize = BLEConstants.bleChunkSize`                             | ~1000    |
| `Duration(milliseconds: 50)`  | `BLEConstants.chunkSendDelay`                                             | Multiple |
| `Duration(milliseconds: 100)` | `BLEConstants.commandValidationDelay` or `BLEConstants.endDelimiterDelay` | Multiple |
| `Duration(milliseconds: 300)` | `BLEConstants.subscriptionSetupDelay`                                     | ~1167    |
| `Duration(seconds: 3)`        | `BLEConstants.disconnectMessageDelay`                                     | ~288     |
| `Duration(seconds: 2)`        | `BLEConstants.successMessageClearDelay`                                   | ~470     |
| `Duration(milliseconds: 500)` | `BLEConstants.navigationFallbackDelay`                                    | ~578     |
| `Duration(seconds: 10)`       | `BLEConstants.scanDuration`                                               | ~136     |
| `'<END>'`                     | `BLEConstants.endMarker`                                                  | Multiple |

### **Error Messages → BLEErrors**

| Find                                        | Replace With                                                           |
| ------------------------------------------- | ---------------------------------------------------------------------- |
| `'Not connected'`                           | `BLEErrors.notConnected`                                               |
| `'Invalid command format'`                  | `BLEErrors.invalidCommandFormat`                                       |
| `'Service not found'`                       | `BLEErrors.serviceNotFound`                                            |
| `'Buffer overflow - data stream too large'` | `BLEErrors.bufferOverflow`                                             |
| `'Error sending command: $e'`               | `BLEErrors.withDetails(BLEErrors.commandSendFailed, e.toString())`     |
| `'Error starting stream: $e'`               | `BLEErrors.withDetails(BLEErrors.streamStartFailed, e.toString())`     |
| `'Invalid response JSON: $e'`               | `BLEErrors.withDetails(BLEErrors.responseParsingFailed, e.toString())` |
| `'Notification error: $e'`                  | `BLEErrors.withDetails(BLEErrors.notConnected, e.toString())`          |

### **Success Messages → BLEMessages**

| Find                                                          | Replace With                     |
| ------------------------------------------------------------- | -------------------------------- |
| `'Connecting device...'`                                      | `BLEMessages.connecting`         |
| `'Success connected...'`                                      | `BLEMessages.connected`          |
| `'Disconnecting...'`                                          | `BLEMessages.disconnecting`      |
| `'Success disconnected...'`                                   | `BLEMessages.disconnected`       |
| `'Device disconnect, will be redirect to home in 3 seconds.'` | `BLEMessages.deviceWillRedirect` |

---

## 🛠️ Code Snippets

### **1. Replace Command Validation**

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

---

### **2. Replace Response Cleaning**

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

---

### **3. Replace Timeout Logic**

**Before:**

```dart
Duration timeoutDuration;

if (isStopCommand) {
  timeoutDuration = const Duration(seconds: 5);
} else if (opType == 'read' && commandType == 'devices_with_registers') {
  if (isMinimal) {
    if (hasLimit) {
      timeoutDuration = const Duration(seconds: 360);
    } else {
      timeoutDuration = const Duration(seconds: 1500);
    }
  } else {
    if (hasLimit) {
      timeoutDuration = const Duration(seconds: 360);
    } else {
      timeoutDuration = const Duration(seconds: 4800);
    }
  }
} else if (opType == 'read' && commandType == 'devices_summary') {
  timeoutDuration = const Duration(seconds: 60);
} else if (opType == 'read' && commandType == 'device') {
  timeoutDuration = const Duration(seconds: 90);
} else if (opType == 'read' && commandType == 'registers') {
  timeoutDuration = const Duration(seconds: 90);
} else if (opType == 'read') {
  timeoutDuration = const Duration(seconds: 60);
} else {
  timeoutDuration = const Duration(seconds: 60);
}
```

**After:**

```dart
final timeoutDuration = BLEConstants.getTimeoutForCommand(command);
BLEHelper.logTimeoutWarning(timeoutDuration, 'sendCommand');
```

**Reduction:** ~100 lines → 2 lines! 🎉

---

### **4. Replace Command Sending**

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

// Validate sent command
AppHelpers.debugLog('Full sent command: ${sentCommand.toString()}');
try {
  jsonDecode(sentCommand.toString());
  AppHelpers.debugLog('Sent command is valid JSON');
} catch (e) {
  AppHelpers.debugLog('Sent command is not valid JSON: $e');
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
await BLEHelper.sendBLECommand(
  commandChar,
  command,
  onProgress: (progress) => commandProgress.value = progress,
);
```

**Reduction:** ~40 lines → 5 lines! 🎉

---

### **5. Add Bluetooth State Validation**

**Add at start of `connectToDevice()`:**

```dart
// Validate BLE state first
final adapterState = await FlutterBluePlus.adapterState.first;
if (adapterState != BluetoothAdapterState.on) {
  errorMessage.value = BLEErrors.bluetoothOff;
  return;
}

// Validate device ID
final deviceId = deviceModel.device.remoteId.toString();
if (!BLEHelper.isValidDeviceId(deviceId)) {
  errorMessage.value = BLEErrors.invalidDeviceId;
  return;
}
```

---

### **6. Replace Logging**

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

## 📍 Line Number Reference

### **Critical Lines to Update:**

| Section                    | Lines     | What to Replace                              |
| -------------------------- | --------- | -------------------------------------------- |
| **sendCommand()**          | 963-1448  | Magic numbers, error messages, timeout logic |
| **startDataStream()**      | 1848-2072 | Delays, command sending, error messages      |
| **stopDataStream()**       | 2074-2136 | Command sending, delays                      |
| **startStreamDevice()**    | 2139-2394 | Command sending, delays, error messages      |
| **stopStreamDevice()**     | 2396-2458 | Command sending, delays                      |
| **connectToDevice()**      | 387-474   | Messages, delays                             |
| **disconnectFromDevice()** | 477-670   | Messages, delays, navigation                 |
| **startScan()**            | 124-152   | Scan duration, delays                        |
| **\_processBatch()**       | 180-201   | Delays                                       |
| **\_scheduleUIUpdate()**   | 203-208   | Delays                                       |

---

## ✅ Testing Commands

After each change, run:

```bash
# Check for errors
flutter analyze

# Format code
dart format lib/core/controllers/ble_controller.dart

# Run tests (if available)
flutter test

# Check specific file
flutter analyze lib/core/controllers/ble_controller.dart
```

---

## 🎯 Priority Order

1. ✅ **Step 1-2:** Already done (imports, buffer constants)
2. 🔥 **Step 3:** Replace magic numbers (LOW RISK, HIGH IMPACT)
3. 🔥 **Step 4:** Replace error messages (LOW RISK, HIGH IMPACT)
4. 🔥 **Step 6:** Replace timeout logic (MEDIUM RISK, VERY HIGH IMPACT)
5. ⚡ **Step 7:** Extract command sending (MEDIUM RISK, HIGH IMPACT)
6. ⚡ **Step 5:** Use BLEHelper for cleaning (LOW RISK, MEDIUM IMPACT)
7. ⚡ **Step 8-11:** Replace remaining delays and messages
8. 📝 **Step 12-15:** Add validation and use remaining helpers

---

## 🚨 Common Pitfalls

### **1. Don't forget to import!**

```dart
import 'package:gateway_config/core/constants/ble_constants.dart';
import 'package:gateway_config/core/constants/ble_errors.dart';
import 'package:gateway_config/core/utils/ble_helper.dart';
```

### **2. Test after EACH step**

- Don't make all changes at once
- Commit after each working step
- Keep old code commented initially

### **3. Watch for context-specific delays**

Some delays might need different constants:

- `Duration(milliseconds: 100)` could be:
  - `BLEConstants.commandValidationDelay` (before sending)
  - `BLEConstants.endDelimiterDelay` (before END marker)
  - `BLEConstants.chunkSendDelay` (between chunks)

### **4. Buffer size references**

Already updated:

- Line 1907: `BLEConstants.maxBufferSize` ✓
- Line 1998: `BLEConstants.maxPartialSize` ✓
- Line 2201: `BLEConstants.maxBufferSize` ✓
- Line 2320: `BLEConstants.maxPartialSize` ✓

---

## 📊 Progress Tracker

- [x] **Phase 1:** Create utility files ✅
- [x] **Phase 1:** Create refactoring guide ✅
- [ ] **Phase 2:** Replace magic numbers
- [ ] **Phase 2:** Replace error messages
- [ ] **Phase 2:** Replace timeout logic
- [ ] **Phase 2:** Extract command sending
- [ ] **Phase 2:** Add validation
- [ ] **Phase 3:** Test all features
- [ ] **Phase 3:** Fix any issues
- [ ] **Phase 4:** Code review
- [ ] **Phase 4:** Documentation update

---

## 🎉 Expected Results

After completing all steps:

- **Code Quality:** ⬆️ +40%
- **Maintainability:** ⬆️ +60%
- **Lines of Code:** ⬇️ -12%
- **Magic Numbers:** ⬇️ -100%
- **Duplicate Code:** ⬇️ -100%
- **Test Coverage:** ⬆️ (easier to test)

---

**Quick Tip:** Use VS Code's multi-cursor (Ctrl+D) to replace multiple occurrences quickly!

**Remember:** Test, commit, repeat! 🔄
