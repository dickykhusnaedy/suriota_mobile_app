import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:suriota_mobile_gateway/constant/app_color.dart';
import 'package:suriota_mobile_gateway/constant/app_gap.dart';
import 'package:suriota_mobile_gateway/controller/ble_controller.dart';
import 'package:suriota_mobile_gateway/controller/modbus_pagination_controller.dart';
import 'package:suriota_mobile_gateway/global/utils/text_extension.dart';
import 'package:suriota_mobile_gateway/screen/devices/modbus_config/form_modbus_config_screen.dart';

class ModbusScreen extends StatefulWidget {
  const ModbusScreen({super.key});

  @override
  State<ModbusScreen> createState() => _ModbusScreenState();
}

class _ModbusScreenState extends State<ModbusScreen> {
  final BLEController bleController = Get.put(BLEController(), permanent: true);
  final ModbusPaginationController controller =
      Get.put(ModbusPaginationController(), permanent: true);
  bool isLoading = false;
  bool isInitialized = false;

  @override
  void initState() {
    super.initState();
    debugPrint('initState called');
    // Panggil fetchDevices sekali setelah widget dirender
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!isInitialized) {
        _fetchDataModbus();
        isInitialized = true;
      }
    });
  }

  void _fetchDataModbus() async {
    if (isLoading) {
      debugPrint('Fetch devices skipped: already loading');
      return;
    }
    setState(() => isLoading = true);
    debugPrint('Fetching devices: READ|modbus|page:1|pageSize:5');

    try {
      // Periksa koneksi BLE
      if (bleController.isConnected.isEmpty ||
          !bleController.isConnected.values.any((connected) => connected)) {
        Get.snackbar('Error', 'No BLE device connected');
        setState(() => isLoading = false);
        return;
      }

      bleController.sendCommand('READ|modbus|page:1|pageSize:5', 'modbus');
    } catch (e) {
      debugPrint('Error fetching devices: $e');
      Get.snackbar('Error', 'Failed to fetch devices: $e');
    } finally {
      setState(() => isLoading = false);
    }
  }

  Container _loadingProgress(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      alignment: Alignment.center,
      child: const Center(
        child: CircularProgressIndicator(
          color: AppColor.primaryColor,
        ),
      ),
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
              Text(
                'Modbus Config',
                style: context.h5,
                overflow: TextOverflow.ellipsis,
              ),
              AppSpacing.md,
              Obx(() {
                if (isLoading || bleController.isLoading.value) {
                  return _loadingProgress(context);
                }

                if (controller.modbus.isEmpty) {
                  return _emptyView(context);
                }

                return ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: controller.modbus.length,
                    separatorBuilder: (context, index) => AppSpacing.sm,
                    itemBuilder: (context, int index) {
                      final item = controller.modbus[index];

                      return cardDataConfig(item, index);
                    });
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
              Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const FormModbusConfigScreen()));
            },
            icon: const Icon(
              Icons.add_circle,
              size: 22,
            ))
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
            Text(
              modbus['name'],
              style: context.h5,
            ),
            AppSpacing.sm,
            Text(
              'Devices : ${modbus['device_choose']}',
              style: context.bodySmall,
            ),
            AppSpacing.sm,
            Text(
              'Slave ID : ${modbus['id']}',
              style: context.bodySmall,
            ),
            AppSpacing.xs,
            Text(
              'Address : ${modbus['address']}',
              style: context.bodySmall,
            ),
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
          ],
        ),
      ),
    );
  }
}
