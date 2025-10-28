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

  // Ganti valueData jadi RxList
  final RxList<String> valueData = [
    "142",
    "920",
    "821",
    "710",
    "180",
    "170",
  ].obs;
  final List<String> addressData = [
    "0x3042",
    "0x2042",
    "0x8219",
    "0x8163",
    "0x6661",
    "0x6763",
  ];

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

    // Listener untuk streamedData dari BLE
    ever(controller.streamedData, (dataMap) {
      if (!mounted) return;
      for (int i = 0; i < addressData.length; i++) {
        final address = addressData[i];
        if (dataMap.containsKey(address)) {
          valueData[i] = dataMap[address]!; // Update value jika address match
          AppHelpers.debugLog(
            'Updated valueData[$i]: ${valueData[i]} for address $address',
          );
        }
      }
      valueData.refresh(); // Pastikan RxList memicu update
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
        await controller.startDataStream(
          "data",
          widget.deviceId,
        ); // Start stream
      } else {
        await controller.stopDataStream("data"); // Stop stream
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

  @override
  void dispose() {
    _worker.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _appBar(context),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: AppPadding.horizontalMedium,
          child: _bodyContent(context, addressData, valueData),
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

  Widget _bodyContent(
    BuildContext context,
    List<String> addressData,
    RxList<String> valueData,
  ) {
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
              // ListView tanpa Obx di sini, pindah ke _card
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: addressData.length,
                separatorBuilder: (context, index) => AppSpacing.sm,
                itemBuilder: (BuildContext context, int index) {
                  return _card(context, addressData, index, valueData);
                },
              ),
              AppSpacing.md,
            ],
          );
        }),
      ],
    );
  }

  Widget _card(
    BuildContext context,
    List<String> addressData,
    int index,
    RxList<String> valueData,
  ) {
    return Stack(
      alignment: AlignmentDirectional.topEnd,
      children: [
        SizedBox(
          width: double.infinity,
          child: Card(
            color: AppColor.cardColor,
            margin: EdgeInsets.zero,
            elevation: 0.0,
            child: Padding(
              padding: AppPadding.medium,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: MediaQuery.of(context).size.width - 200,
                    child: Text(
                      'Address ${addressData[index]}',
                      style: context.h6,
                      overflow: TextOverflow.clip,
                    ),
                  ),
                  AppSpacing.xs,
                  // Obx hanya untuk Text yang menampilkan valueData
                  Obx(
                    () => Text(
                      'Value: ${valueData[index]}',
                      style: context.bodySmall,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        Container(
          height: 30,
          width: 130,
          decoration: const BoxDecoration(
            color: AppColor.labelColor,
            borderRadius: BorderRadius.only(
              topRight: Radius.circular(10.0),
              bottomLeft: Radius.circular(10.0),
            ),
          ),
          child: Center(
            child: Text(
              '25 Aug 2024 13.00', // Data statis contoh
              textAlign: TextAlign.center,
              style: context.buttonTextSmallest,
            ),
          ),
        ),
      ],
    );
  }
}
