import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:gateway_config/core/constants/app_color.dart';
import 'package:gateway_config/core/constants/app_gap.dart';
import 'package:gateway_config/core/controllers/ble_controller.dart';
import 'package:gateway_config/core/controllers/devices_controller.dart';
import 'package:gateway_config/core/utils/app_helpers.dart';
import 'package:gateway_config/core/utils/extensions.dart';
import 'package:gateway_config/core/utils/loading_progress.dart';
import 'package:gateway_config/core/utils/snackbar_custom.dart';
import 'package:gateway_config/models/device_model.dart';
import 'package:gateway_config/presentation/widgets/common/custom_button.dart';
import 'package:get/get.dart';

class DisplayDataPage extends StatefulWidget {
  const DisplayDataPage({
    super.key,
    required this.model,
    required this.deviceId,
  });

  final DeviceModel model;
  final String deviceId;

  @override
  State<DisplayDataPage> createState() => _DisplayDataPageState();
}

class _DisplayDataPageState extends State<DisplayDataPage> {
  final controller = Get.put(BleController());
  final devicesController = Get.put(DevicesController());
  Map<String, dynamic> dataDevice = {};

  late Worker _worker;
  late Worker _streamWorker;

  // Data structure untuk streaming dengan device yang berbeda
  final RxList<Map<String, dynamic>> streamingDevicesData =
      <Map<String, dynamic>>[].obs;

  // Flag untuk tracking streaming status
  final RxBool isStreaming = false.obs;

  // Current device ID untuk tracking device yang sama vs berbeda
  String? currentStreamingDeviceId;

  // Tracking untuk recent updates (address -> timestamp)
  final RxMap<String, DateTime> recentUpdates = <String, DateTime>{}.obs;

  // Timer untuk clear recent updates
  Timer? _updateIndicatorTimer;

  @override
  void initState() {
    super.initState();
    // Listener untuk selectedDevice
    _worker = ever(devicesController.selectedDevice, (dataList) {
      if (!mounted) return;
      if (dataList.isNotEmpty) {
        setState(() {
          dataDevice = dataList[0];
        });
      }
    });

    // Listener untuk streamedData dari BLE dengan logika device tracking
    _streamWorker = ever(controller.streamedData, (dataMap) {
      if (!mounted) return;
      _handleStreamingData(dataMap);
    });

    // Fetch data setelah widget build
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await devicesController.getDeviceById(widget.model, widget.deviceId);
    });
  }

  void _streamData({bool shouldStart = false}) async {
    if (!widget.model.isConnected.value) {
      SnackbarCustom.showSnackbar(
        '',
        'Device not connected',
        AppColor.redColor,
        AppColor.whiteColor,
      );
      return;
    }

    try {
      if (shouldStart) {
        await controller.startStreamDevice("data", widget.deviceId);
        isStreaming.value = true;
        currentStreamingDeviceId = widget.deviceId;
        AppHelpers.debugLog(
          'Started enhanced streaming for device: ${widget.deviceId}',
        );
      } else {
        await controller.stopStreamDevice("data");
        isStreaming.value = false;
        currentStreamingDeviceId = null;
        streamingDevicesData.clear(); // Clear data saat stop stream
        AppHelpers.debugLog('Stopped enhanced streaming and cleared data');
      }
    } catch (e) {
      SnackbarCustom.showSnackbar(
        '',
        'Failed to manage stream',
        AppColor.redColor,
        AppColor.whiteColor,
      );
    }
  }

  void _handleStreamingData(Map<String, String> dataMap) {
    if (dataMap.isEmpty) return;

    final currentTime = DateTime.now();
    final timeString =
        '${currentTime.day.toString().padLeft(2, '0')} ${_getMonthName(currentTime.month)} ${currentTime.year} ${currentTime.hour.toString().padLeft(2, '0')}.${currentTime.minute.toString().padLeft(2, '0')}';

    // Track update untuk setiap address yang di-update
    dataMap.forEach((address, _) {
      recentUpdates[address] = currentTime;
    });

    // Clear indicator setelah 2 detik
    _updateIndicatorTimer?.cancel();
    _updateIndicatorTimer = Timer(const Duration(seconds: 2), () {
      recentUpdates.clear();
    });

    // Cek apakah ada device dengan ID yang sama
    final existingDeviceIndex = streamingDevicesData.indexWhere(
      (device) => device['device_id'] == widget.deviceId,
    );

    if (existingDeviceIndex != -1) {
      // Update data existing device
      final existingDevice = streamingDevicesData[existingDeviceIndex];

      // Update nama device jika berubah
      existingDevice['device_name'] =
          dataDevice['device_name'] ?? 'Unknown Device';

      // Update tanggal
      existingDevice['last_update'] = timeString;

      // Update values dari dataMap (parse JSON string to get name and value)
      final Map<String, Map<String, String>> updatedValues = Map.from(
        existingDevice['values'] ?? {},
      );
      dataMap.forEach((address, jsonString) {
        try {
          final parsed = jsonDecode(jsonString) as Map<String, dynamic>;
          updatedValues[address] = {
            'name': parsed['name']?.toString() ?? 'Unknown Sensor',
            'value': parsed['value']?.toString() ?? '0',
            'address': parsed['address']?.toString() ?? address,
          };
          AppHelpers.debugLog(
            'Updated device ${widget.deviceId} - ${parsed['name']}: ${parsed['value']}',
          );
        } catch (e) {
          AppHelpers.debugLog('Error parsing stream data: $e');
        }
      });
      existingDevice['values'] = updatedValues;

      // Trigger update
      streamingDevicesData[existingDeviceIndex] = existingDevice;
      streamingDevicesData.refresh();
    } else {
      // Tambah device baru (parse JSON string to get name and value)
      final Map<String, Map<String, String>> parsedValues = {};
      dataMap.forEach((address, jsonString) {
        try {
          final parsed = jsonDecode(jsonString) as Map<String, dynamic>;
          parsedValues[address] = {
            'name': parsed['name']?.toString() ?? 'Unknown Sensor',
            'value': parsed['value']?.toString() ?? '0',
            'address': parsed['address']?.toString() ?? address,
          };
        } catch (e) {
          AppHelpers.debugLog('Error parsing stream data: $e');
        }
      });

      final newDeviceData = {
        'device_id': widget.deviceId,
        'device_name': dataDevice['device_name'] ?? 'Unknown Device',
        'protocol': dataDevice['protocol'] ?? 'Unknown',
        'serial_port': dataDevice['serial_port']?.toString() ?? 'Unknown',
        'values': parsedValues,
        'last_update': timeString,
      };

      streamingDevicesData.add(newDeviceData);
      AppHelpers.debugLog('Added new streaming device: ${widget.deviceId}');
    }
  }

  String _getMonthName(int month) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return months[month - 1];
  }

  @override
  void dispose() {
    _worker.dispose();
    _streamWorker.dispose();
    _updateIndicatorTimer?.cancel();
    super.dispose();
  }

  bool _isRecentlyUpdated(String address) {
    final lastUpdate = recentUpdates[address];
    if (lastUpdate == null) return false;

    final now = DateTime.now();
    final difference = now.difference(lastUpdate);
    return difference.inSeconds < 2;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: AppPadding.horizontalMedium,
          child: _buildBodyContent(),
        ),
      ),
    );
  }

  AppBar _buildAppBar() {
    return AppBar(
      title: Text(
        'Streaming Device',
        style: context.h5.copyWith(color: AppColor.whiteColor),
      ),
      iconTheme: const IconThemeData(color: AppColor.whiteColor),
      backgroundColor: AppColor.primaryColor,
      centerTitle: true,
    );
  }

  Widget _buildBodyContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Obx untuk isFetching
        Obx(() {
          if (devicesController.isFetching.value) {
            return const LoadingProgress();
          }
          return Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              AppSpacing.md,
              _buildDeviceInfo(),
              AppSpacing.md,
              _buildControlButtons(),
              AppSpacing.md,
              _buildStreamingStatus(),
              _buildStreamingData(),
              AppSpacing.md,
            ],
          );
        }),
      ],
    );
  }

  Widget _buildDeviceInfo() {
    return Column(
      children: [
        Text(
          'Device name',
          style: context.bodySmall.copyWith(color: AppColor.grey),
        ),
        AppSpacing.xs,
        Text(
          dataDevice['device_name'] ?? '',
          style: context.h3.copyWith(
            fontWeight: FontWeight.bold,
            letterSpacing: -0.5,
          ),
        ),
        AppSpacing.xs,
        Wrap(
          spacing: 8,
          runSpacing: 8,
          alignment: WrapAlignment.center,
          children: [
            _buildInfoBadge(
              icon: Icons.settings_input_component,
              label: 'Modbus: ${dataDevice['protocol'] ?? ''}',
            ),
            _buildInfoBadge(
              icon: Icons.power,
              label:
                  'Serial Port: ${dataDevice['serial_port']?.toString() ?? ''}',
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildInfoBadge({required IconData icon, required String label}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColor.primaryColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: AppColor.primaryColor.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppColor.primaryColor),
          const SizedBox(width: 6),
          Text(
            label,
            style: context.bodySmall.copyWith(
              color: AppColor.primaryColor,
              fontWeight: FontWeight.w600,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildControlButtons() {
    return Row(
      children: [
        Flexible(
          flex: 1,
          child: Button(
            onPressed: () => _streamData(shouldStart: true),
            width: double.infinity,
            text: 'Stream Data',
            height: 42,
            icons: const Icon(
              Icons.play_arrow,
              color: AppColor.whiteColor,
              size: 20,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Flexible(
          flex: 1,
          child: Button(
            onPressed: () => _streamData(shouldStart: false),
            text: 'Stop Stream',
            width: double.infinity,
            height: 42,
            btnColor: AppColor.redColor,
            icons: const Icon(Icons.stop, color: AppColor.whiteColor, size: 20),
          ),
        ),
      ],
    );
  }

  Widget _buildStreamingStatus() {
    return Obx(
      () => isStreaming.value
          ? Column(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.green.withValues(alpha: 0.1),
                        Colors.green.withValues(alpha: 0.15),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: Colors.green.withValues(alpha: 0.4),
                      width: 1.5,
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: Colors.green,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.green.withValues(alpha: 0.5),
                              blurRadius: 4,
                              spreadRadius: 1,
                            ),
                          ],
                        ),
                      ),
                      AppSpacing.sm,
                      Text(
                        'Streaming Active',
                        style: context.bodySmall.copyWith(
                          color: Colors.green.shade800,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                AppSpacing.md,
              ],
            )
          : const SizedBox.shrink(),
    );
  }

  Widget _buildStreamingData() {
    return Obx(
      () => streamingDevicesData.isEmpty
          ? _buildNoDataWidget()
          : Column(
              children: streamingDevicesData
                  .map((deviceData) => _buildStreamingDeviceCard(deviceData))
                  .toList(),
            ),
    );
  }

  Widget _buildNoDataWidget() {
    return Container(
      padding: const EdgeInsets.all(24),
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColor.whiteColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColor.grey.withValues(alpha: 0.2),
          width: 1.5,
        ),
      ),
      child: Column(
        children: [
          Icon(Icons.stream_outlined, size: 48, color: AppColor.grey),
          AppSpacing.sm,
          Text(
            'No Streaming Data',
            style: context.h6.copyWith(
              color: AppColor.blackColor,
              fontWeight: FontWeight.bold,
            ),
          ),
          AppSpacing.xs,
          Text(
            'Start streaming to see real-time data',
            style: context.bodySmall.copyWith(color: AppColor.grey),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildStreamingDeviceCard(Map<String, dynamic> deviceData) {
    final values =
        deviceData['values'] as Map<String, Map<String, String>>? ?? {};
    final lastUpdate = deviceData['last_update'] ?? 'Unknown';

    if (values.isEmpty) {
      return Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColor.whiteColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: AppColor.grey.withValues(alpha: 0.2),
            width: 1.5,
          ),
        ),
        child: Column(
          children: [
            Icon(Icons.sensors_off, size: 40, color: AppColor.grey),
            const SizedBox(height: 8),
            Text(
              'Waiting for sensor data...',
              style: context.bodySmall.copyWith(
                color: AppColor.grey,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      children: values.entries
          .map(
            (entry) => _buildSensorCard(
              sensorData: entry.value,
              sensorAddress: entry.key,
              lastUpdate: lastUpdate,
            ),
          )
          .toList(),
    );
  }

  Widget _buildSensorCard({
    required Map<String, String> sensorData,
    required String sensorAddress,
    required String lastUpdate,
  }) {
    final sensorName = sensorData['name'] ?? 'Unknown Sensor';
    final sensorValue = sensorData['value'] ?? '0';
    final address = sensorData['address'] ?? sensorAddress;

    return Obx(() {
      final isUpdating = _isRecentlyUpdated(address);

      return AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: AppColor.whiteColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isUpdating
                ? Colors.green.withValues(alpha: 0.6)
                : AppColor.primaryColor.withValues(alpha: 0.2),
            width: isUpdating ? 2.0 : 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: isUpdating
                  ? Colors.green.withValues(alpha: 0.2)
                  : Colors.black.withValues(alpha: 0.05),
              blurRadius: isUpdating ? 8 : 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSensorHeader(sensorName, isUpdating),
              const SizedBox(height: 8),
              _buildSensorAddress(address),
              const SizedBox(height: 10),
              _buildSensorValue(sensorValue),
              const SizedBox(height: 8),
              _buildLastUpdate(lastUpdate),
            ],
          ),
        ),
      );
    });
  }

  Widget _buildSensorHeader(String sensorName, bool isUpdating) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Text(
            sensorName,
            style: context.h5.copyWith(
              color: AppColor.primaryColor,
              fontWeight: FontWeight.bold,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isUpdating) ...[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.orange.shade100,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: Colors.orange.shade300, width: 1),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      width: 10,
                      height: 10,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          Colors.orange.shade700,
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Updating',
                      style: context.bodySmall.copyWith(
                        color: Colors.orange.shade700,
                        fontSize: 9,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 4),
            ],
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.green,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.circle, color: Colors.white, size: 5),
                  const SizedBox(width: 3),
                  Text(
                    'Live',
                    style: context.buttonTextSmallest.copyWith(
                      color: Colors.white,
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSensorAddress(String address) {
    return Row(
      children: [
        Icon(Icons.location_on_outlined, size: 14, color: AppColor.grey),
        const SizedBox(width: 3),
        Text(
          'Addr: $address',
          style: context.bodySmall.copyWith(color: AppColor.grey, fontSize: 11),
        ),
      ],
    );
  }

  Widget _buildSensorValue(String value) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
      decoration: BoxDecoration(
        color: AppColor.lightPrimaryColor.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: AppColor.primaryColor.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            'Value:',
            style: context.bodySmall.copyWith(
              color: AppColor.grey,
              fontSize: 12,
            ),
          ),
          Text(value, style: context.h4.copyWith(color: AppColor.blackColor)),
        ],
      ),
    );
  }

  Widget _buildLastUpdate(String lastUpdate) {
    return Row(
      children: [
        Icon(Icons.access_time, size: 12, color: AppColor.grey),
        const SizedBox(width: 4),
        Expanded(
          child: Text(
            lastUpdate,
            style: context.bodySmall.copyWith(
              color: AppColor.grey,
              fontSize: 10,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
