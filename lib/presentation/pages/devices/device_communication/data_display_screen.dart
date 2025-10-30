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

  void _streamData({bool isStopStream = false}) async {
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
      if (isStopStream) {
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
        AppHelpers.debugLog('Stopped enhanced streaming');
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

      // Update values dari dataMap
      final Map<String, String> updatedValues = Map.from(
        existingDevice['values'] ?? {},
      );
      dataMap.forEach((address, value) {
        updatedValues[address] = value;
        AppHelpers.debugLog(
          'Updated device ${widget.deviceId} - $address: $value',
        );
      });
      existingDevice['values'] = updatedValues;

      // Trigger update
      streamingDevicesData[existingDeviceIndex] = existingDevice;
      streamingDevicesData.refresh();
    } else {
      // Tambah device baru
      final newDeviceData = {
        'device_id': widget.deviceId,
        'device_name': dataDevice['device_name'] ?? 'Unknown Device',
        'protocol': dataDevice['protocol'] ?? 'Unknown',
        'serial_port': dataDevice['serial_port']?.toString() ?? 'Unknown',
        'values': Map<String, String>.from(dataMap),
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
        'Display Data',
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
                      onPressed: () => _streamData(isStopStream: true),
                      width: double.infinity,
                      text: 'Stream Data',
                      height: 40,
                    ),
                  ),
                  AppSpacing.sm,
                  Flexible(
                    flex: 1,
                    child: Button(
                      onPressed: () => _streamData(isStopStream: false),
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
                    : ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: streamingDevicesData.length,
                        separatorBuilder: (context, index) => AppSpacing.sm,
                        itemBuilder: (BuildContext context, int index) {
                          return _streamingDeviceCard(
                            context,
                            streamingDevicesData[index],
                          );
                        },
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
    final values = deviceData['values'] as Map<String, String>? ?? {};

    return Card(
      color: AppColor.cardColor,
      margin: EdgeInsets.zero,
      elevation: 2.0,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header dengan info device
          Container(
            width: double.infinity,
            padding: AppPadding.medium,
            decoration: BoxDecoration(
              color: AppColor.primaryColor.withValues(alpha: 0.1),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        deviceData['device_name'] ?? 'Unknown Device',
                        style: context.h6.copyWith(
                          color: AppColor.primaryColor,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.green,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.circle, color: Colors.white, size: 8),
                          const SizedBox(width: 4),
                          Text(
                            'Live',
                            style: context.buttonTextSmallest.copyWith(
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                AppSpacing.xs,
                Row(
                  children: [
                    Badge(
                      label: Text(
                        'Modbus: ${deviceData['protocol'] ?? 'Unknown'}',
                        style: context.buttonTextSmallest.copyWith(
                          color: AppColor.primaryColor,
                        ),
                      ),
                      backgroundColor: AppColor.lightPrimaryColor,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                    ),
                    AppSpacing.xs,
                    Badge(
                      label: Text(
                        'Port: ${deviceData['serial_port'] ?? 'Unknown'}',
                        style: context.buttonTextSmallest.copyWith(
                          color: AppColor.primaryColor,
                        ),
                      ),
                      backgroundColor: AppColor.lightPrimaryColor,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Data values
          Padding(
            padding: AppPadding.medium,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (values.isEmpty)
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text(
                        'Waiting for data...',
                        style: context.bodySmall.copyWith(color: AppColor.grey),
                      ),
                    ),
                  )
                else
                  ...values.entries
                      .map(
                        (entry) => Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('Address ${entry.key}', style: context.body),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColor.lightPrimaryColor,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  entry.value,
                                  style: context.body.copyWith(
                                    color: AppColor.primaryColor,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                      .toList(),
              ],
            ),
          ),

          // Footer dengan timestamp
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: AppColor.labelColor.withValues(alpha: 0.3),
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(12),
                bottomRight: Radius.circular(12),
              ),
            ),
            child: Row(
              children: [
                Icon(Icons.access_time, size: 14, color: AppColor.grey),
                const SizedBox(width: 4),
                Text(
                  'Last update: ${deviceData['last_update'] ?? 'Unknown'}',
                  style: context.buttonTextSmallest.copyWith(
                    color: AppColor.grey,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
