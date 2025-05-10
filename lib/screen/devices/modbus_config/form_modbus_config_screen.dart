import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:suriota_mobile_gateway/constant/app_color.dart';
import 'package:suriota_mobile_gateway/constant/app_gap.dart';
import 'package:suriota_mobile_gateway/constant/font_setup.dart';
import 'package:suriota_mobile_gateway/controller/ble_controller.dart';
import 'package:suriota_mobile_gateway/controller/device_pagination_controller.dart';
import 'package:suriota_mobile_gateway/global/utils/text_extension.dart';
import 'package:suriota_mobile_gateway/global/widgets/custom_button.dart';
import 'package:suriota_mobile_gateway/global/widgets/custom_dropdown.dart';
import 'package:suriota_mobile_gateway/global/widgets/custom_textfield.dart';
import 'package:suriota_mobile_gateway/global/widgets/loading_overlay.dart';
import 'package:suriota_mobile_gateway/screen/devices/modbus_config/modbus_screen.dart';

class FormModbusConfigScreen extends StatefulWidget {
  final int? id;

  const FormModbusConfigScreen({super.key, this.id});

  @override
  State<FormModbusConfigScreen> createState() => _FormModbusConfigScreenState();
}

class _FormModbusConfigScreenState extends State<FormModbusConfigScreen> {
  final BLEController bleController = Get.put(BLEController(), permanent: true);
  final DevicePaginationController controller =
      Get.put(DevicePaginationController(), permanent: true);
  bool isLoading = false;
  bool isInitialized = false;

  final deviceNameController = TextEditingController();
  final idSlaveController = TextEditingController();
  final addressController = TextEditingController();
  final serverPortController = TextEditingController();
  final connectionTimeoutController = TextEditingController();

  List<String> functions = ['1', '2', '3', '4'];
  List<String> typeData = [
    'INT16',
    'UINT16',
    'INT32',
    'UINT32',
    'FLOAT32',
    'INT64',
    'FLOAT64',
  ];

  String? selectedDevice;
  String? selectedFunction;
  String? selectedTypeData;

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
  }

  int? _tryParseInt(String? value, {int? defaultValue}) {
    if (value == null || value.isEmpty) return defaultValue;
    return int.tryParse(value) ?? defaultValue;
  }

  String _formData() {
    final device = selectedDevice;
    final type = selectedTypeData;
    final name = deviceNameController.text;
    final address = _tryParseInt(addressController.text);
    final function = _tryParseInt(selectedFunction, defaultValue: 1);

    if (widget.id != null) {
      final id = widget.id;
      return 'UPDATE|modbus|id:$id|name:$name|device_choose:$device|data_type:$type|address:$address|function_code:$function';
    }
    return 'CREATE|modbus|name:$name|device_choose:$device|data_type:$type|address:$address|function_code:$function';
  }

  void _submit() async {
    // Validasi form
    if (!_formKey.currentState!.validate()) return;

    // Periksa koneksi BLE
    if (bleController.isConnected.isEmpty ||
        !bleController.isConnected.values.any((connected) => connected)) {
      Get.snackbar('Error', 'No BLE device connected');
      return;
    }

    // Konfirmasi sebelum submit
    Get.bottomSheet(
      Container(
        padding: AppPadding.medium,
        decoration: const BoxDecoration(
          color: AppColor.whiteColor,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Wrap(
          children: [
            Center(
              child: Column(
                children: [
                  Text(
                    "Are you sure?",
                    style: FontFamily.headlineLarge,
                  ),
                  AppSpacing.sm,
                  Text("Are you sure you want to save this modbus config?",
                      style: FontFamily.normal),
                  AppSpacing.md,
                  Row(
                    children: [
                      Expanded(
                        child: Button(
                            onPressed: () =>
                                Navigator.of(Get.overlayContext!).pop(),
                            text: "No",
                            btnColor: AppColor.grey),
                      ),
                      AppSpacing.md,
                      Expanded(
                        child: Button(
                          onPressed: () async {
                            Get.back();
                            try {
                              final sendDataDelimiter = _formData();
                              debugPrint('Sending command: $sendDataDelimiter');
                              bleController.sendCommand(
                                  sendDataDelimiter, 'modbus');

                              await Future.delayed(const Duration(seconds: 3));
                              Get.to(() => const ModbusScreen());
                            } catch (e) {
                              debugPrint('Error submitting form: $e');
                              Get.snackbar(
                                  'Error', 'Failed to submit form: $e');
                            }
                          },
                          text: "Yes",
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      isDismissible: false,
      enableDrag: false,
    );
  }

  @override
  void dispose() {
    deviceNameController.dispose();
    idSlaveController.dispose();
    addressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    List<String> getDeviceNames() {
      // ignore: invalid_use_of_protected_member
      return controller.devices.value
          .map((device) => device['name'] as String)
          .toList();
    }

    return Stack(
      children: [
        Scaffold(
          appBar: _appBar(context),
          body: _body(context, getDeviceNames),
        ),
        Obx(() {
          final isAnyDeviceLoading = bleController.isLoading.value;
          return LoadingOverlay(
            isLoading: isAnyDeviceLoading,
            message: 'Processing request...',
          );
        }),
      ],
    );
  }

  SafeArea _body(BuildContext context, List<String> Function() getDeviceNames) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: AppPadding.horizontalMedium,
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AppSpacing.md,
              CustomTextFormField(
                controller: deviceNameController,
                labelTxt: "Data Name",
                hintTxt: "Enter the Data Name",
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Data Name is required';
                  }
                  return null;
                },
              ),
              AppSpacing.md,
              CustomTextFormField(
                controller: idSlaveController,
                labelTxt: "ID Slave",
                hintTxt: "1",
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Data Name is required';
                  }
                  return null;
                },
              ),
              AppSpacing.md,
              Text(
                'Choose Device',
                style: context.h6,
              ),
              AppSpacing.sm,
              CustomDropdown(
                listItem: getDeviceNames(),
                hintText: 'Choose device',
                selectedItem: selectedDevice,
                onChanged: (value) {
                  setState(() {
                    selectedDevice = value;
                  });
                },
              ),
              AppSpacing.md,
              Text(
                'Choose Function',
                style: context.h6,
              ),
              AppSpacing.sm,
              CustomDropdown(
                listItem: functions,
                hintText: 'Choose the function',
                selectedItem: selectedFunction,
                onChanged: (value) {
                  setState(() {
                    selectedFunction = value;
                  });
                },
              ),
              AppSpacing.md,
              CustomTextFormField(
                controller: addressController,
                labelTxt: "Address",
                hintTxt: "1",
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Address is required';
                  }
                  if (_tryParseInt(value) == null) {
                    return 'Address must be a valid number';
                  }
                  return null;
                },
              ),
              AppSpacing.md,
              Text(
                'Choose Data Type',
                style: context.h6,
              ),
              AppSpacing.sm,
              CustomDropdown(
                listItem: typeData,
                hintText: 'Choose data type',
                selectedItem: selectedTypeData,
                onChanged: (value) {
                  setState(() {
                    selectedTypeData = value;
                  });
                },
              ),
              AppSpacing.lg,
              Button(
                width: MediaQuery.of(context).size.width,
                onPressed: _submit,
                text: widget.id != null ? 'Update' : 'Save',
                height: 50,
              ),
              AppSpacing.lg,
            ],
          ),
        ),
      ),
    );
  }

  AppBar _appBar(BuildContext context) {
    return AppBar(
      title: Text(
        widget.id == null ? 'Setup Modbus' : 'Update Modbus',
        style: context.h5.copyWith(color: AppColor.whiteColor),
      ),
      centerTitle: true,
      iconTheme: const IconThemeData(color: Colors.white),
      backgroundColor: AppColor.primaryColor,
    );
  }
}
