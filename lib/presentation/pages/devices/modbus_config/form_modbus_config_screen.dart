import 'package:flutter/material.dart';
import 'package:gateway_config/core/constants/app_color.dart';
import 'package:gateway_config/core/constants/app_gap.dart';
import 'package:gateway_config/core/constants/static_data.dart';
import 'package:gateway_config/core/controllers/ble_controller.dart';
import 'package:gateway_config/core/controllers/devices_controller.dart';
import 'package:gateway_config/core/controllers/modbus_controller.dart';
import 'package:gateway_config/core/utils/app_helpers.dart';
import 'package:gateway_config/core/utils/extensions.dart';
import 'package:gateway_config/core/utils/snackbar_custom.dart';
import 'package:gateway_config/models/device_model.dart';
import 'package:gateway_config/models/dropdown_items.dart';
import 'package:gateway_config/presentation/widgets/common/custom_alert_dialog.dart';
import 'package:gateway_config/presentation/widgets/common/custom_textfield.dart';
import 'package:gateway_config/presentation/widgets/common/dropdown.dart';
import 'package:gateway_config/presentation/widgets/common/loading_overlay.dart';
import 'package:gateway_config/presentation/widgets/common/reusable_widgets.dart';
import 'package:get/get.dart';

class FormModbusConfigScreen extends StatefulWidget {
  const FormModbusConfigScreen({
    super.key,
    required this.model,
    this.deviceId,
    this.registerId,
  });

  final DeviceModel model;
  final String? deviceId;
  final String? registerId;

  @override
  State<FormModbusConfigScreen> createState() => _FormModbusConfigScreenState();
}

class _FormModbusConfigScreenState extends State<FormModbusConfigScreen> {
  final BleController bleController;
  final DevicesController controller;
  final ModbusController modbusController = Get.find<ModbusController>();

  late Worker _worker;

  Map<String, dynamic> dataModbus = {};
  bool isLoading = false;
  bool isInitialized = false;
  List<String>? deviceNames;
  String errorMessage = '';

  final deviceNameController = TextEditingController();
  final addressController = TextEditingController();
  final serverPortController = TextEditingController();
  final connectionTimeoutController = TextEditingController();
  final descriptionController = TextEditingController();
  final scaleController = TextEditingController(text: '1.0');
  final offsetController = TextEditingController(text: '0.0');
  final unitController = TextEditingController();

  List<DropdownItems> modbusDataTypes = StaticData.dataModbusType
      .map(
        (data) => DropdownItems(
          text: data['text'],
          value: data['value'].toString(),
          group: data['group'],
        ),
      )
      .toList();

  String? selectedDevice;
  String? selectedFunction;
  String? selectedTypeData;

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  _FormModbusConfigScreenState()
    : bleController = Get.find<BleController>(),
      controller = Get.find<DevicesController>();

  @override
  void initState() {
    super.initState();

    _worker = ever(modbusController.selectedModbus, (dataList) {
      if (!mounted) return;
      if (dataList.isNotEmpty) {
        _fillFormFromDevice(dataList[0]);
      }
    });

    // Fetch data after widget build - already using async callback
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      // Use smart cache instead of always fetching
      await controller.fetchDevicesIfNeeded(widget.model);

      if (widget.deviceId != null && widget.registerId != null) {
        await modbusController.getDeviceById(
          widget.model,
          widget.deviceId!,
          widget.registerId!,
        );
      }
    });
  }

  void _fillFormFromDevice(Map<String, dynamic> modbus) {
    selectedDevice = widget.deviceId;
    selectedFunction = modbus['function_code']?.toString() ?? '';
    selectedTypeData = modbus['data_type']?.toString() ?? '';
    deviceNameController.text = modbus['register_name'] ?? '';
    addressController.text = modbus['address']?.toString() ?? '';
    descriptionController.text = modbus['description'] ?? '';
    scaleController.text = modbus['scale']?.toString() ?? '1.0';
    offsetController.text = modbus['offset']?.toString() ?? '0.0';
    unitController.text = modbus['unit'] ?? '';

    setState(() {});
  }

  int? _tryParseInt(String? value, {int? defaultValue}) {
    if (value == null || value.isEmpty) return defaultValue;
    return int.tryParse(value) ?? defaultValue;
  }

  double? _tryParseDouble(String? value, {double? defaultValue}) {
    if (value == null || value.isEmpty) return defaultValue;
    return double.tryParse(value) ?? defaultValue;
  }

  String _sanitizeInput(String input) {
    return input.replaceAll('|', '').replaceAll('#', '');
  }

  void _submit() async {
    // Validasi form
    if (!_formKey.currentState!.validate()) return;

    if (!widget.model.isConnected.value) {
      SnackbarCustom.showSnackbar(
        '',
        'Device not connected',
        AppColor.redColor,
        AppColor.whiteColor,
      );
      return;
    }

    CustomAlertDialog.show(
      title: 'Are you sure?',
      message:
          'Are you sure you want to ${widget.registerId == null ? 'save' : 'update'} this modbus configuration?',
      primaryButtonText: 'Yes',
      secondaryButtonText: 'No',
      onPrimaryPressed: () async {
        Get.back();
        controller.isFetching.value = true;

        try {
          var formData = {
            "op": widget.registerId != null ? "update" : "create",
            "type": "register",
            "device_id": selectedDevice,
            if (widget.registerId != null) "register_id": widget.registerId,
            "config": {
              "address": _tryParseInt(addressController.text),
              "register_name": _sanitizeInput(deviceNameController.text),
              "function_code": _tryParseInt(selectedFunction),
              "data_type": selectedTypeData,
              "description": descriptionController.text,
              "scale": _tryParseDouble(scaleController.text, defaultValue: 1.0),
              "offset": _tryParseDouble(
                offsetController.text,
                defaultValue: 0.0,
              ),
              "unit": unitController.text.isEmpty ? '' : unitController.text,
            },
          };

          await bleController.sendCommand(formData);

          await Future.delayed(const Duration(seconds: 1));

          AppHelpers.backNTimes(2);
        } catch (e) {
          SnackbarCustom.showSnackbar(
            '',
            'Failed to submit form',
            AppColor.redColor,
            AppColor.whiteColor,
          );
          AppHelpers.debugLog('Error submitting form: $e');
        } finally {
          controller.isFetching.value = false;
        }
      },
      barrierDismissible: false,
    );
  }

  @override
  void dispose() {
    _worker.dispose();

    deviceNameController.dispose();
    addressController.dispose();
    descriptionController.dispose();
    scaleController.dispose();
    offsetController.dispose();
    unitController.dispose();
    isInitialized = false;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Scaffold(appBar: _appBar(context), body: _body(context)),
        Obx(() {
          final isAnyDeviceLoading =
              controller.isFetching.value || bleController.commandLoading.value;
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
        'Setup Modbus',
        style: context.h5.copyWith(color: AppColor.whiteColor),
      ),
      centerTitle: true,
      iconTheme: const IconThemeData(color: Colors.white),
      backgroundColor: AppColor.primaryColor,
    );
  }

  SafeArea _body(BuildContext context) {
    List<DropdownItems> deviceItem = controller.dataDevices
        .map(
          (data) => DropdownItems(
            text: data['device_name'],
            value: data['device_id'],
          ),
        )
        .toList();
    return SafeArea(
      child: SingleChildScrollView(
        padding: AppPadding.horizontalMedium,
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AppSpacing.md,
              SectionDivider(
                title: 'Register Information',
                icon: Icons.info_outline,
              ),
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
                isRequired: true,
              ),
              AppSpacing.md,
              Dropdown(
                items: deviceItem,
                selectedValue: selectedDevice,
                label: 'Choose Device',
                onChanged: (item) {
                  setState(() {
                    selectedDevice = item!.value;
                  });
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please select an device';
                  }
                  return null;
                },
                isRequired: true,
                isDisabled: widget.registerId != null,
              ),
              AppSpacing.md,
              CustomTextFormField(
                controller: descriptionController,
                labelTxt: "Description",
                hintTxt: "ex. Main Temperature",
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Description is required';
                  }
                  return null;
                },
              ),
              AppSpacing.md,
              CustomTextFormField(
                controller: unitController,
                labelTxt: "Unit",
                hintTxt: "ex. °C, V, A, kW, %, Bar",
              ),
              AppSpacing.md,
              SectionDivider(
                title: 'Modbus Configuration',
                icon: Icons.settings_input_component,
              ),
              AppSpacing.md,
              Dropdown(
                items: StaticData.modbusReadFunctions,
                selectedValue: selectedFunction,
                label: 'Choose Function',
                onChanged: (item) {
                  setState(() {
                    selectedFunction = item!.value;
                  });
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please select modbus function data';
                  }
                  return null;
                },
                isRequired: true,
              ),
              AppSpacing.md,
              CustomTextFormField(
                controller: addressController,
                labelTxt: "Address Modbus",
                hintTxt: "ex. 1",
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
                isRequired: true,
              ),
              AppSpacing.md,
              Dropdown(
                items: modbusDataTypes,
                selectedValue: selectedTypeData,
                label: 'Choose Data Type',
                onChanged: (item) {
                  setState(() {
                    selectedTypeData = item!.value;
                  });
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please select data type';
                  }
                  return null;
                },
                isRequired: true,
              ),
              AppSpacing.md,
              SectionDivider(title: 'Calibration Settings', icon: Icons.tune),
              AppSpacing.md,
              CustomTextFormField(
                controller: scaleController,
                labelTxt: 'Scale (Multiplier)',
                hintTxt: 'ex. 1.0',
                keyboardType: TextInputType.numberWithOptions(decimal: true),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Scale is required';
                  }
                  final num = double.tryParse(value);
                  if (num == null) {
                    return 'Enter a valid number';
                  }
                  return null;
                },
              ),
              AppSpacing.sm,
              Padding(
                padding: AppPadding.horizontalSmall,
                child: Text(
                  'Multiplier for calibration (default: 1.0)',
                  style: context.bodySmall.copyWith(color: AppColor.grey),
                ),
              ),
              AppSpacing.md,
              CustomTextFormField(
                controller: offsetController,
                labelTxt: 'Offset',
                hintTxt: 'ex. 0.0',
                keyboardType: TextInputType.numberWithOptions(decimal: true),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Offset is required';
                  }
                  final num = double.tryParse(value);
                  if (num == null) {
                    return 'Enter a valid number';
                  }
                  return null;
                },
              ),
              AppSpacing.sm,
              Padding(
                padding: AppPadding.horizontalSmall,
                child: Text(
                  'Offset value after scaling (default: 0.0)',
                  style: context.bodySmall.copyWith(color: AppColor.grey),
                ),
              ),
              AppSpacing.md,
              Container(
                padding: AppPadding.medium,
                decoration: BoxDecoration(
                  color: AppColor.primaryColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppColor.primaryColor.withValues(alpha: 0.3),
                    width: 1,
                  ),
                ),
                child: Text(
                  'final_value = (raw_value × scale) + offset',
                  style: context.bodySmall.copyWith(
                    fontWeight: FontWeight.bold,
                    fontFamily: 'monospace',
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              AppSpacing.lg,
              GradientButton(
                text: widget.deviceId != null && widget.registerId != null
                    ? 'Update Register Configuration'
                    : 'Save Register Configuration',
                icon: widget.deviceId != null && widget.registerId != null
                    ? Icons.update
                    : Icons.save,
                onPressed: _submit,
              ),
              AppSpacing.lg,
            ],
          ),
        ),
      ),
    );
  }
}
