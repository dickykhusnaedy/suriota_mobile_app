import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:suriota_mobile_gateway/constant/app_color.dart';
import 'package:suriota_mobile_gateway/constant/app_gap.dart';
import 'package:suriota_mobile_gateway/controller/ble_controller.dart';
import 'package:suriota_mobile_gateway/controller/device_pagination_controller.dart';
import 'package:suriota_mobile_gateway/controller/modbus_pagination_controller.dart';
import 'package:suriota_mobile_gateway/global/utils/helper.dart';
import 'package:suriota_mobile_gateway/global/utils/text_extension.dart';
import 'package:suriota_mobile_gateway/global/widgets/custom_alert_dialog.dart';
import 'package:suriota_mobile_gateway/global/widgets/custom_button.dart';
import 'package:suriota_mobile_gateway/global/widgets/custom_dropdown.dart';
import 'package:suriota_mobile_gateway/global/widgets/custom_textfield.dart';
import 'package:suriota_mobile_gateway/global/widgets/loading_overlay.dart';

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
  final ModbusPaginationController controllerModbus =
      Get.put(ModbusPaginationController(), permanent: true);

  Map<String, dynamic> dataModbus = {};
  bool isLoading = false;
  bool isInitialized = false;
  List<String>? deviceNames;
  String errorMessage = '';

  final deviceNameController = TextEditingController();
  final idSlaveController = TextEditingController();
  final addressController = TextEditingController();
  final serverPortController = TextEditingController();
  final connectionTimeoutController = TextEditingController();

  static const List<String> modbusReadFunctions = ['1', '2', '3', '4'];

  static const List<String> modbusDataTypes = [
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

    if (widget.id != null) {
      dataModbus = controllerModbus.modbus
          .firstWhere((item) => item['id'] == widget.id, orElse: () => {});

      _fillFormFromDevice(dataModbus);
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!isInitialized) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        fetchDataDevices();
        isInitialized = true;
      });
    }
  }

  Future<void> fetchDataDevices() async {
    setState(() {
      isLoading = true;
      errorMessage = '';
    });

    try {
      final data =
          await bleController.fetchData("READ|devices|names", 'devices');

      print('data devices aa: $data');

      setState(() {
        if (data['data'] is List) {
          deviceNames = (data['data'] as List).map((device) {
            if (device is Map<String, dynamic>) {
              return device['name'] as String? ?? 'Unknown';
            } else if (device is String) {
              return device; // Langsung gunakan string dari array
            }
            return 'Unknown';
          }).toList();
        } else {
          deviceNames = [];
          errorMessage = 'No devices found';
        }
      });
    } catch (e) {
      setState(() {
        deviceNames = [];
        errorMessage = e is TimeoutException
            ? 'Timeout: Could not load devices. Please try again.'
            : 'Failed to load devices: $e';
        isLoading = false;
      });
    }
  }

  int? _tryParseInt(String? value, {int? defaultValue}) {
    if (value == null || value.isEmpty) return defaultValue;
    return int.tryParse(value) ?? defaultValue;
  }

  void _fillFormFromDevice(Map<String, dynamic> modbus) {
    deviceNameController.text = modbus['name'];
    addressController.text = modbus['address'];
    idSlaveController.text = modbus['id'].toString();

    setState(() {
      selectedDevice = modbus['device_choose'];
      selectedFunction = modbus['function_code'];
      selectedTypeData = modbus['data_type'];
    });
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
    CustomAlertDialog.show(
      title: "Are you sure?",
      message:
          "Are you sure you want to ${widget.id != null ? 'update' : 'save'} this modbus config?",
      primaryButtonText: 'Yes',
      secondaryButtonText: 'No',
      onPrimaryPressed: () async {
        Get.back();
        await Future.delayed(const Duration(seconds: 1));

        try {
          final sendDataDelimiter = _formData();
          bleController.sendCommand(sendDataDelimiter, 'modbus');
        } catch (e) {
          debugPrint('Error submitting form: $e');
          Get.snackbar('Error', 'Failed to submit form: $e');
        } finally {
          await Future.delayed(const Duration(seconds: 3));
          AppHelpers.backNTimes(1);
        }
      },
      barrierDismissible: false,
    );
  }

  @override
  void dispose() {
    deviceNameController.dispose();
    idSlaveController.dispose();
    addressController.dispose();
    isInitialized = false;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Scaffold(
          appBar: _appBar(context),
          body: _body(context),
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

  SafeArea _body(BuildContext context) {
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
                    return 'ID Slave is required';
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
                listItem: deviceNames ?? [],
                hintText: 'Choose device',
                selectedItem: selectedDevice,
                onChanged: (value) {
                  setState(() {
                    selectedDevice = value;
                  });
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please select an device';
                  }
                  return null;
                },
              ),
              AppSpacing.md,
              Text(
                'Choose Function',
                style: context.h6,
              ),
              AppSpacing.sm,
              CustomDropdown(
                listItem: modbusReadFunctions,
                hintText: 'Choose the function',
                selectedItem: selectedFunction,
                onChanged: (value) {
                  setState(() {
                    selectedFunction = value;
                  });
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please select modbus function data';
                  }
                  return null;
                },
              ),
              AppSpacing.md,
              CustomTextFormField(
                controller: addressController,
                labelTxt: "Address Modbus",
                hintTxt: "1",
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Address Modbus is required';
                  }
                  if (_tryParseInt(value) == null) {
                    return 'Address Modbus must be a valid number';
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
                listItem: modbusDataTypes,
                hintText: 'Choose data type',
                selectedItem: selectedTypeData,
                onChanged: (value) {
                  setState(() {
                    selectedTypeData = value;
                  });
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please select data type';
                  }
                  return null;
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
}
