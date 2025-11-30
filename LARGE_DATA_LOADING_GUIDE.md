# 📚 Large Data Loading Guide - 70 Devices × 70 Registers

## 🎯 Overview

Panduan ini menjelaskan cara optimal untuk load data besar (70 devices × 70 registers) melalui BLE menggunakan **Smart Loading Strategy** yang auto-detect firmware capabilities.

---

## 🚀 Quick Start - Recommended Usage

### **Option 1: Smart Auto-Detection (RECOMMENDED)** ✅

Controller akan **otomatis detect** apakah firmware support pagination, lalu pilih strategy terbaik:

```dart
// In your UI controller/service
final bleController = Get.find<BleController>();

// Smart loading dengan auto-detection
final devices = await bleController.loadDevicesWithRegisters(
  minimal: true,           // Use minimal mode for faster loading
  devicesPerPage: 5,       // Load 5 devices per page (if pagination supported)
  onProgress: (current, total) {
    // Update UI progress
    print('Loading page $current/$total');
    updateProgressBar(current / total);
  },
);

print('Loaded ${devices.length} devices!');
```

**Behavior:**
- ✅ **Jika firmware SUPPORT pagination:** Load 5 devices per page (~6 min per page)
- ✅ **Jika firmware BELUM support:** Load summary dulu, lalu device-by-device
- ✅ **Auto fallback:** Tidak perlu ubah code saat firmware upgrade!

---

### **Option 2: Manual Control**

Jika mau kontrol manual strategy yang dipakai:

```dart
// Check firmware capability first
final supportsPagination = await bleController.checkFirmwarePaginationSupport();

if (supportsPagination) {
  print('✅ Firmware supports pagination');
  // Use paginated loading
  await loadWithPagination();
} else {
  print('⚠️ Firmware does not support pagination yet');
  // Use fallback strategy
  await loadWithFallback();
}
```

---

## 📊 Performance Comparison

| Strategy | Firmware Requirement | Time (70 devices) | Progress Updates | Recommended |
|----------|---------------------|-------------------|------------------|-------------|
| **Smart Auto** | Auto-detect | 21 min (paginated) or 106 min (fallback) | ✅ Yes | 🎯 **BEST** |
| **Manual Pagination** | Requires pagination | 21 min | ✅ Yes | ✅ Good |
| **Manual Fallback** | None | 106 min | ✅ Yes | ⚠️ Slow |
| **Load All at Once** | None | 25 min (risky timeout) | ❌ No | ❌ Avoid |

---

## 🔄 Transition Timeline

### **Phase 1: Current (Firmware BELUM ada pagination)**

**Smart Loader behavior:**
```
1. Check pagination support → ❌ Not supported
2. Use fallback strategy:
   - Load summary (60s)
   - Load device 1 (90s)
   - Load device 2 (90s)
   - ...
   - Load device 70 (90s)
3. Total: ~106 menit
```

**Your code:**
```dart
// No changes needed! Just use smart loader
final devices = await bleController.loadDevicesWithRegisters(
  minimal: true,
  onProgress: (current, total) {
    showProgress('Loading device $current/$total');
  },
);
```

**Debug log akan show:**
```
[BLE] === SMART DEVICE LOADER ===
[BLE] Checking firmware pagination support...
[BLE] ❌ Firmware does NOT support pagination
[BLE] Using FALLBACK strategy (on-demand loading)
[BLE] Step 1: Loading devices summary...
[BLE] Found 70 devices
[BLE] ⚠️  Large dataset detected (70 devices)
[BLE] ⚠️  Estimated time: 105 minutes
[BLE] Loading device 1/70: device_1
...
```

---

### **Phase 2: Future (Firmware SUDAH ada pagination)**

**Smart Loader behavior:**
```
1. Check pagination support → ✅ Supported!
2. Use pagination strategy:
   - Load page 1 (5 devices, 6 min)
   - Load page 2 (5 devices, 6 min)
   - ...
   - Load page 14 (5 devices, 6 min)
3. Total: ~21 menit (5x faster!)
```

**Your code:**
```dart
// EXACT SAME CODE! No changes needed
final devices = await bleController.loadDevicesWithRegisters(
  minimal: true,
  onProgress: (current, total) {
    showProgress('Loading page $current/$total'); // Auto updates to "page"
  },
);
```

**Debug log akan show:**
```
[BLE] === SMART DEVICE LOADER ===
[BLE] Checking firmware pagination support...
[BLE] ✅ Firmware SUPPORTS pagination!
[BLE] Using PAGINATION strategy (optimal)
[BLE] Loading page 1...
[BLE] Page 1/14 loaded (Total devices: 70)
[BLE] Loading page 2...
...
[BLE] ✅ Pagination complete: 70 devices loaded
```

---

## 🎨 UI Implementation Examples

### **Example 1: Full Screen Loading with Progress**

```dart
class DeviceListPage extends StatelessWidget {
  final bleController = Get.find<BleController>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Devices')),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: bleController.loadDevicesWithRegisters(
          minimal: true,
          onProgress: (current, total) {
            // Update reactive progress
            bleController.commandProgress.value = current / total;
          },
        ),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Obx(() => LinearProgressIndicator(
                    value: bleController.commandProgress.value,
                  )),
                  SizedBox(height: 8),
                  Obx(() => Text(
                    'Loading devices...\n'
                    '${(bleController.commandProgress.value * 100).toInt()}% complete',
                    textAlign: TextAlign.center,
                  )),
                  if (!bleController.firmwareSupportsPagination.value)
                    Padding(
                      padding: EdgeInsets.all(16),
                      child: Text(
                        'Note: Firmware does not support pagination yet.\n'
                        'Loading may take 90+ minutes for 70 devices.\n'
                        'Consider upgrading firmware for 5x faster loading.',
                        style: TextStyle(fontSize: 12, color: Colors.orange),
                        textAlign: TextAlign.center,
                      ),
                    ),
                ],
              ),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Text('Error: ${snapshot.error}'),
            );
          }

          final devices = snapshot.data ?? [];
          return ListView.builder(
            itemCount: devices.length,
            itemBuilder: (context, index) {
              final device = devices[index];
              return ListTile(
                title: Text(device['device_name'] ?? 'Unknown'),
                subtitle: Text('${device['registers']?.length ?? 0} registers'),
                onTap: () => showDeviceDetail(device),
              );
            },
          );
        },
      ),
    );
  }
}
```

---

### **Example 2: Background Loading with Notifications**

```dart
class BackgroundDeviceLoader {
  final bleController = Get.find<BleController>();

  Future<void> syncDevicesInBackground() async {
    // Show notification
    showNotification('Syncing devices in background...');

    try {
      final devices = await bleController.loadDevicesWithRegisters(
        minimal: true,
        onProgress: (current, total) {
          // Update notification
          updateNotification(
            'Syncing devices',
            'Progress: $current/$total',
          );
        },
      );

      // Save to local database
      await localDB.saveDevices(devices);

      // Show completion notification
      showNotification(
        'Sync complete!',
        '${devices.length} devices synced successfully',
      );

    } catch (e) {
      showNotification(
        'Sync failed',
        'Error: $e',
        error: true,
      );
    }
  }
}
```

---

### **Example 3: Cached Loading with Refresh**

```dart
class CachedDeviceLoader {
  final bleController = Get.find<BleController>();
  List<Map<String, dynamic>>? cachedDevices;
  DateTime? lastSync;

  Future<List<Map<String, dynamic>>> getDevices({
    bool forceRefresh = false,
  }) async {
    // Use cache if fresh (< 1 hour)
    if (!forceRefresh &&
        cachedDevices != null &&
        lastSync != null &&
        DateTime.now().difference(lastSync!) < Duration(hours: 1)) {

      print('Using cached devices (${cachedDevices!.length} devices)');
      return cachedDevices!;
    }

    // Show warning for large data
    final shouldContinue = await showConfirmDialog(
      'Refresh Device Data',
      'This will reload all devices and may take 20-100 minutes.\n\n'
      'Continue?',
    );

    if (!shouldContinue) {
      return cachedDevices ?? [];
    }

    // Fetch fresh data
    print('Fetching fresh devices...');
    cachedDevices = await bleController.loadDevicesWithRegisters(
      minimal: true,
      onProgress: (current, total) {
        print('Progress: $current/$total');
      },
    );

    lastSync = DateTime.now();
    return cachedDevices!;
  }
}
```

---

## 🔍 Debug & Monitoring

### **Check Firmware Capability**

```dart
// Manually check if firmware supports pagination
final supports = await bleController.checkFirmwarePaginationSupport();

if (supports) {
  print('✅ Firmware version supports pagination');
  print('   Loading will use optimal paginated strategy');
} else {
  print('⚠️ Firmware version does not support pagination');
  print('   Loading will use fallback strategy (slower)');
  print('   Recommend: Upgrade firmware for 5x faster loading');
}
```

### **Monitor Loading Performance**

```dart
final stopwatch = Stopwatch()..start();

final devices = await bleController.loadDevicesWithRegisters(
  minimal: true,
  onProgress: (current, total) {
    final elapsed = stopwatch.elapsed.inSeconds;
    final avgPerPage = current > 0 ? elapsed / current : 0;
    final estimatedTotal = avgPerPage * total;
    final remaining = estimatedTotal - elapsed;

    print('Progress: $current/$total');
    print('Elapsed: ${elapsed}s');
    print('Est. remaining: ${remaining.toInt()}s');
  },
);

stopwatch.stop();
print('Total loading time: ${stopwatch.elapsed.inMinutes} minutes');
```

---

## ⚙️ Configuration Options

### **Adjust Devices Per Page**

```dart
// Load more devices per page (faster total time, but longer per request)
final devices = await bleController.loadDevicesWithRegisters(
  minimal: true,
  devicesPerPage: 10,  // 10 devices per page instead of 5
  // Trade-off: ~12 min per page, but only 7 pages instead of 14
);
```

### **Use Full Mode (Not Recommended)**

```dart
// Load full device data (much slower!)
final devices = await bleController.loadDevicesWithRegisters(
  minimal: false,  // ⚠️ WARNING: Very slow for large datasets
  devicesPerPage: 3,  // Reduce page size for full mode
);
// Time: ~80 minutes for 70 devices (not recommended)
```

---

## 🎓 Best Practices

### ✅ **DO:**

1. **Always use minimal mode for bulk loading**
   ```dart
   loadDevicesWithRegisters(minimal: true)  // ✅
   ```

2. **Show progress to user**
   ```dart
   onProgress: (current, total) {
     showProgressIndicator(current / total);
   }
   ```

3. **Cache results**
   ```dart
   // Load once, use multiple times
   cachedDevices ??= await loadDevicesWithRegisters(...);
   ```

4. **Warn user about long operations**
   ```dart
   if (totalDevices > 20) {
     await showWarning('This may take ${estimatedMinutes} minutes');
   }
   ```

5. **Use Smart Loader (auto-detection)**
   ```dart
   loadDevicesWithRegisters()  // Auto-detects firmware capability
   ```

### ❌ **DON'T:**

1. **Don't load all devices at once without pagination**
   ```dart
   // ❌ AVOID
   sendCommand({"op": "read", "type": "devices_with_registers"})
   ```

2. **Don't use full mode for large datasets**
   ```dart
   // ❌ AVOID
   loadDevicesWithRegisters(minimal: false)  // Too slow!
   ```

3. **Don't fetch on every screen open**
   ```dart
   // ❌ AVOID
   @override
   void initState() {
     loadDevicesWithRegisters();  // Every time? Bad!
   }
   ```

4. **Don't ignore firmware capability**
   ```dart
   // ❌ AVOID hardcoding strategy
   // Use smart loader instead
   ```

---

## 🚨 Troubleshooting

### **Problem: Timeout errors**

**Cause:** Data too large for current timeout

**Solution:**
```dart
// Timeout sudah auto-adjusted based on pagination support
// Jika masih timeout:
// 1. Ensure firmware supports pagination
// 2. Reduce devicesPerPage to 3-5
// 3. Check BLE connection stability
```

### **Problem: Very slow loading (>2 hours)**

**Cause:** Firmware tidak support pagination

**Solution:**
```dart
// Check firmware capability
final supports = await checkFirmwarePaginationSupport();
if (!supports) {
  print('⚠️ Firmware needs update for pagination support');
  // Contact firmware team untuk upgrade
}
```

### **Problem: Memory issues on large datasets**

**Solution:**
```dart
// Save progressively to database instead of keeping in memory
onProgress: (current, total) {
  // Save each page/device immediately
  await localDB.saveCurrentBatch();
}
```

---

## 📞 Support

**Firmware Team Coordination:**
- Firmware pagination expected: Q1 2025 (check with team)
- Flutter app already prepared for pagination
- No app changes needed when firmware upgraded!

**Questions?**
- Check debug logs for detailed execution flow
- Use `AppHelpers.debugLog()` output untuk troubleshooting
- Monitor `bleController.firmwareSupportsPagination.value` untuk check capability

---

## 🎯 Summary

✅ **Smart Loader handles both scenarios automatically**
✅ **No code changes needed when firmware upgrades**
✅ **Optimal performance for current & future firmware**
✅ **Progress tracking built-in**
✅ **Production-ready for 70×70 scenario**

**Recommended usage:**
```dart
final devices = await bleController.loadDevicesWithRegisters(
  minimal: true,
  onProgress: (current, total) {
    updateUI(current, total);
  },
);
```

**That's it!** 🎉
