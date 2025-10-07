import 'package:flutter/material.dart';
import 'package:gateway_config/core/constants/app_color.dart';
import 'package:gateway_config/core/constants/app_gap.dart';
import 'package:gateway_config/core/controllers/ble/ble_controller.dart';
import 'package:gateway_config/core/controllers/modbus/modbus_pagination_controller.dart';
import 'package:gateway_config/core/utils/extensions.dart';
import 'package:gateway_config/models/device_model.dart';
import 'package:gateway_config/presentation/widgets/common/custom_alert_dialog.dart';
import 'package:gateway_config/presentation/widgets/common/custom_button.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';

class ModbusScreen extends StatefulWidget {
  const ModbusScreen({super.key, required this.model});
  final DeviceModel model;

  @override
  State<ModbusScreen> createState() => _ModbusScreenState();
}

class _ModbusScreenState extends State<ModbusScreen> {
  final BLEController bleController = Get.put(BLEController(), permanent: true);
  final ModbusPaginationController controller = Get.put(
    ModbusPaginationController(),
    permanent: true,
  );

  bool isLoading = false;
  bool isInitialized = false;

  @override
  void initState() {
    super.initState();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!isInitialized) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _fetchDataModbus();
        isInitialized = true;
      });
    }
  }

  @override
  void dispose() {
    isInitialized = false;
    super.dispose();
  }

  void _fetchDataModbus() async {
    if (isLoading) {
      debugPrint('Fetch devices skipped: already loading');
      return;
    }

    setState(() => isLoading = true);

    try {
      // Periksa koneksi BLE
      if (bleController.isConnected.isEmpty ||
          !bleController.isConnected.values.any((connected) => connected)) {
        Get.snackbar('Error', 'No BLE device connected');
        setState(() => isLoading = false);
        return;
      }

      bleController.sendCommand('READ|modbus|page:1|pageSize:2', 'modbus');
    } catch (e) {
      debugPrint('Error fetching devices: $e');
      Get.snackbar('Error', 'Failed to fetch devices: $e');
    } finally {
      setState(() => isLoading = false);
    }
  }

  void _deleteConfigModbus(int modbusId) async {
    if (bleController.isConnected.isEmpty ||
        !bleController.isConnected.values.any((connected) => connected)) {
      Get.snackbar('Error', 'No BLE device connected');
      return;
    }

    CustomAlertDialog.show(
      title: "Are you sure?",
      message: "Are you sure you want to delete this config?",
      primaryButtonText: 'Yes',
      secondaryButtonText: 'No',
      onPrimaryPressed: () async {
        setState(() => isLoading = true);

        Get.back();
        await Future.delayed(const Duration(seconds: 1));

        try {
          bleController.sendCommand('DELETE|modbus|id:$modbusId', 'modbus');
        } catch (e) {
          debugPrint('Error deleting config modbus: $e');

          Get.snackbar('Error', 'Failed to delete device: $e');
        } finally {
          await Future.delayed(const Duration(milliseconds: 3000));
          bleController.sendCommand('READ|modbus|page:1|pageSize:2', 'modbus');

          setState(() => isLoading = false);
        }
      },
      barrierDismissible: false,
    );
  }

  Container _emptyView(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.70,
      alignment: Alignment.center,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'No modbus found.',
              textAlign: TextAlign.center,
              style: context.body.copyWith(color: AppColor.grey),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _appBar(context),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: AppPadding.horizontalMedium,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AppSpacing.md,
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Data Modbus',
                    style: context.h5,
                    overflow: TextOverflow.ellipsis,
                  ),
                  TextButton.icon(
                    onPressed: _fetchDataModbus,
                    label: const Icon(Icons.rotate_left, size: 20),
                    style: TextButton.styleFrom(
                      iconColor: AppColor.primaryColor,
                      padding: EdgeInsets.zero,
                      minimumSize: const Size(50, 30),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  ),
                ],
              ),
              AppSpacing.sm,
              Obx(() {
                // if (isLoading || bleController.isLoading.value) {
                //   return LoadingProgress(
                //     receivedPackets: bleController.receivedPackets,
                //     expectedPackets: bleController.expectedPackets,
                //   );
                // }

                if (controller.modbus.isEmpty) {
                  return _emptyView(context);
                }

                return ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: controller.modbus.length,
                  separatorBuilder: (context, index) => AppSpacing.md,
                  itemBuilder: (context, int index) {
                    final item = controller.modbus[index];

                    return cardDataConfig(item, index);
                  },
                );
              }),
              AppSpacing.md,
              Obx(() {
                if (controller.modbus.isNotEmpty &&
                    !bleController.isLoading.value) {
                  return Center(
                    child: Text(
                      'Showing ${controller.totalRecords.value} entries',
                      style: context.bodySmall,
                    ),
                  );
                }
                return const SizedBox.shrink();
              }),
              AppSpacing.md,
            ],
          ),
        ),
      ),
    );
  }

  AppBar _appBar(BuildContext context) {
    return AppBar(
      title: Text(
        'Modbus Configuration',
        style: context.h5.copyWith(color: AppColor.whiteColor),
      ),
      backgroundColor: AppColor.primaryColor,
      centerTitle: true,
      iconTheme: const IconThemeData(color: Colors.white),
      actions: [
        IconButton(
          onPressed: () {
            context.push(
              '/devices/modbus-config/add?d=${widget.model.device.remoteId}',
            );
          },
          icon: const Icon(Icons.add_circle, size: 22),
        ),
      ],
    );
  }

  Card cardDataConfig(Map<String, dynamic> modbus, int index) {
    return Card(
      color: AppColor.cardColor,
      elevation: 0.0,
      margin: EdgeInsets.zero,
      child: Padding(
        padding: AppPadding.medium,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(modbus['name'], style: context.h5),
            AppSpacing.sm,
            Text(
              'Devices : ${modbus['device_choose']}',
              style: context.bodySmall,
            ),
            AppSpacing.sm,
            Text('Slave ID : ${modbus['id']}', style: context.bodySmall),
            AppSpacing.xs,
            Text('Address : ${modbus['address']}', style: context.bodySmall),
            AppSpacing.xs,
            Text(
              'Function : ${modbus['function_code']}',
              style: context.bodySmall,
            ),
            AppSpacing.xs,
            Text(
              'Data Type : ${modbus['data_type']}',
              style: context.bodySmall,
            ),
            AppSpacing.sm,
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              mainAxisSize: MainAxisSize.min,
              children: [
                Flexible(
                  flex: 1,
                  child: Button(
                    width: double.infinity,
                    height: 32,
                    onPressed: () => _deleteConfigModbus(modbus['id']),
                    icons: const Icon(
                      Icons.delete,
                      size: 18,
                      color: AppColor.whiteColor,
                    ),
                    btnColor: const Color.fromARGB(255, 254, 179, 188),
                  ),
                ),
                AppSpacing.md,
                Flexible(
                  flex: 1,
                  child: Button(
                    width: double.infinity,
                    height: 32,
                    onPressed: () {
                      context.push(
                        '/devices/modbus-config/add/edit?d=${widget.model.device.remoteId}&id=${modbus['id']}',
                      );
                    },
                    icons: const Icon(
                      Icons.edit,
                      size: 18,
                      color: AppColor.whiteColor,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
