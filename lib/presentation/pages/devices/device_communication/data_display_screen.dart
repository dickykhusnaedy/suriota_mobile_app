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
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _appBar(context),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: AppPadding.horizontalMedium,
          child: _bodyContent(context),
        ),
      ),
    );
  }

  AppBar _appBar(BuildContext context) {
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

  Widget _bodyContent(BuildContext context) {
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
              Text(
                'Device name',
                style: context.bodySmall.copyWith(color: AppColor.grey),
              ),
              AppSpacing.xs,
              Text(dataDevice['device_name'] ?? '', style: context.h3),
              AppSpacing.xs,
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Badge(
                    label: Text(
                      'Modbus: ${dataDevice['protocol'] ?? ''}',
                      style: context.bodySmall.copyWith(
                        color: AppColor.primaryColor,
                      ),
                    ),
                    textColor: AppColor.primaryColor,
                    padding: const EdgeInsets.only(
                      top: 3,
                      left: 6,
                      right: 6,
                      bottom: 3,
                    ),
                    backgroundColor: AppColor.lightPrimaryColor,
                  ),
                  AppSpacing.xs,
                  Badge(
                    label: Text(
                      'Serial Port: ${dataDevice['serial_port']?.toString() ?? ''}',
                      style: context.bodySmall.copyWith(
                        color: AppColor.primaryColor,
                      ),
                    ),
                    textColor: AppColor.primaryColor,
                    padding: const EdgeInsets.only(
                      top: 3,
                      left: 6,
                      right: 6,
                      bottom: 3,
                    ),
                    backgroundColor: AppColor.lightPrimaryColor,
                  ),
                ],
              ),
              AppSpacing.md,
              Row(
                children: [
                  Flexible(
                    flex: 1,
                    child: Button(
                      onPressed: () => _streamData(shouldStart: true),
                      width: double.infinity,
                      text: 'Stream Data',
                      height: 40,
                    ),
                  ),
                  AppSpacing.sm,
                  Flexible(
                    flex: 1,
                    child: Button(
                      onPressed: () => _streamData(shouldStart: false),
                      text: 'Stop Stream',
                      width: double.infinity,
                      height: 40,
                      btnColor: AppColor.redColor,
                    ),
                  ),
                ],
              ),
              AppSpacing.md,
              // Status streaming indicator
              Obx(
                () => isStreaming.value
                    ? Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.green.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.green, width: 1),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.stream,
                                  color: Colors.green,
                                  size: 16,
                                ),
                                AppSpacing.xs,
                                Text(
                                  'Streaming active',
                                  style: context.bodySmall.copyWith(
                                    color: Colors.green,
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          AppSpacing.md,
                        ],
                      )
                    : const SizedBox.shrink(),
              ),
              // Streaming devices data
              Obx(
                () => streamingDevicesData.isEmpty
                    ? _noDataWidget(context)
                    : Column(
                        children: streamingDevicesData
                            .map(
                              (deviceData) =>
                                  _streamingDeviceCard(context, deviceData),
                            )
                            .toList(),
                      ),
              ),
              AppSpacing.md,
            ],
          );
        }),
      ],
    );
  }

  Widget _noDataWidget(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColor.cardColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(Icons.stream_outlined, size: 48, color: AppColor.blackColor),
          AppSpacing.sm,
          Text(
            'No Streaming Data',
            style: context.h6.copyWith(color: AppColor.blackColor),
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

  Widget _streamingDeviceCard(
    BuildContext context,
    Map<String, dynamic> deviceData,
  ) {
    final values =
        deviceData['values'] as Map<String, Map<String, String>>? ?? {};
    final lastUpdate = deviceData['last_update'] ?? 'Unknown';

    if (values.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColor.cardColor,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Center(
          child: Column(
            children: [
              Icon(Icons.sensors, size: 40, color: AppColor.grey),
              const SizedBox(height: 8),
              Text(
                'Waiting for sensor data...',
                style: context.bodySmall.copyWith(color: AppColor.grey),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      children: values.entries.map((entry) {
        final sensorData = entry.value;
        final sensorName = sensorData['name'] ?? 'Unknown Sensor';
        final sensorValue = sensorData['value'] ?? '0';
        final sensorAddress = sensorData['address'] ?? entry.key;

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: AppColor.whiteColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: AppColor.primaryColor.withValues(alpha: 0.2),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header: Sensor Name & Live
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        sensorName,
                        style: context.h6.copyWith(
                          color: AppColor.primaryColor,
                          fontWeight: FontWeight.bold,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.green,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.circle, color: Colors.white, size: 5),
                          const SizedBox(width: 3),
                          Text(
                            'Live',
                            style: context.buttonTextSmallest.copyWith(
                              color: Colors.white,
                              fontSize: 9,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                // Address
                Row(
                  children: [
                    Icon(
                      Icons.location_on_outlined,
                      size: 14,
                      color: AppColor.grey,
                    ),
                    const SizedBox(width: 3),
                    Text(
                      'Addr: $sensorAddress',
                      style: context.bodySmall.copyWith(
                        color: AppColor.grey,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                // Value
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    vertical: 10,
                    horizontal: 12,
                  ),
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
                      Text(
                        sensorValue,
                        style: context.h5.copyWith(
                          color: AppColor.primaryColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                // Last Update
                Row(
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
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}
