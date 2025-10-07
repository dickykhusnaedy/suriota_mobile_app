import 'package:flutter/material.dart';
import 'package:gateway_config/core/constants/app_color.dart';
import 'package:gateway_config/core/constants/app_gap.dart';
import 'package:gateway_config/core/controllers/ble_controller.dart';
import 'package:gateway_config/core/controllers/devices_controller.dart';
import 'package:gateway_config/core/utils/extensions.dart';
import 'package:gateway_config/models/device_model.dart';
import 'package:gateway_config/models/dropdown_items.dart';
import 'package:gateway_config/presentation/widgets/common/custom_button.dart';
import 'package:gateway_config/presentation/widgets/common/custom_textfield.dart';
import 'package:gateway_config/presentation/widgets/common/dropdown.dart';
import 'package:gateway_config/presentation/widgets/common/loading_overlay.dart';
import 'package:get/get.dart';

class FormModbusConfigScreen extends StatefulWidget {
  const FormModbusConfigScreen({super.key, required this.model});

  final DeviceModel model;

  @override
  State<FormModbusConfigScreen> createState() => _FormModbusConfigScreenState();
}

class _FormModbusConfigScreenState extends State<FormModbusConfigScreen> {
  final BleController bleController;
  final DevicesController controller;

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
  final refreshRateController = TextEditingController();

  static final List<DropdownItems> modbusReadFunctions = [
    DropdownItems(text: 'Coil Status', value: '1'),
    DropdownItems(text: 'Input Status', value: '2'),
    DropdownItems(text: 'Holding Register', value: '3'),
    DropdownItems(text: 'Input Registers', value: '4'),
  ];

  static const List<Map<String, dynamic>> dataModbusType = [
    {'name': 'INT16', 'text': 'INT16'},
    {'name': 'UINT16', 'text': 'UINT16'},
    {'name': 'INT32', 'text': 'INT32'},
    {'name': 'UINT32', 'text': 'UINT32'},
    {'name': 'FLOAT32', 'text': 'FLOAT32'},
    {'name': 'INT64', 'text': 'INT64'},
    {'name': 'FLOAT64', 'text': 'FLOAT64'},
  ];
  List<DropdownItems> modbusDataTypes = dataModbusType
      .map(
        (data) =>
            DropdownItems(text: data['name'], value: data['id'].toString()),
      )
      .toList();

  String? selectedDevice;
  String? selectedFunction;
  String? selectedTypeData;

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  _FormModbusConfigScreenState()
    : bleController = Get.put(BleController(), permanent: true),
      controller = Get.put(DevicesController(), permanent: true) {
    debugPrint(
      'Initialized BLEController and DevicePaginationController with Get.put',
    );
  }

  @override
  void initState() {
    super.initState();

    // if (widget.id != null) {
    //   dataModbus = controllerModbus.modbus.firstWhere(
    //     (item) => item['id'] == widget.id,
    //     orElse: () => {},
    //   );

    //   // _fillFormFromDevice(dataModbus);
    // }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!isInitialized) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        controller.fetchDevices(widget.model);
        isInitialized = true;
      });
    }
  }

  // Future<void> fetchDataDevices() async {
  //   setState(() {
  //     isLoading = true;
  //     errorMessage = '';
  //   });

  //   try {
  //     final data = await bleController.fetchData(
  //       "READ|devices|names",
  //       'devices',
  //     );

  //     print('data devices aa: $data');

  //     setState(() {
  //       if (data['data'] is List) {
  //         deviceNames = (data['data'] as List).map((device) {
  //           if (device is Map<String, dynamic>) {
  //             return device['name'] as String? ?? 'Unknown';
  //           } else if (device is String) {
  //             return device; // Langsung gunakan string dari array
  //           }
  //           return 'Unknown';
  //         }).toList();
  //       } else {
  //         deviceNames = [];
  //         errorMessage = 'No devices found';
  //       }
  //     });
  //   } catch (e) {
  //     setState(() {
  //       deviceNames = [];
  //       errorMessage = e is TimeoutException
  //           ? 'Timeout: Could not load devices. Please try again.'
  //           : 'Failed to load devices: $e';
  //       isLoading = false;
  //     });
  //   }
  // }

  int? _tryParseInt(String? value, {int? defaultValue}) {
    if (value == null || value.isEmpty) return defaultValue;
    return int.tryParse(value) ?? defaultValue;
  }

  // void _fillFormFromDevice(Map<String, dynamic> modbus) {
  //   deviceNameController.text = modbus['name'];
  //   addressController.text = modbus['address'];
  //   idSlaveController.text = modbus['id'].toString();

  //   setState(() {
  //     selectedDevice = modbus['device_choose'];
  //     selectedFunction = modbus['function_code'];
  //     selectedTypeData = modbus['data_type'];
  //   });
  // }

  // String _formData() {
  //   final device = selectedDevice;
  //   final type = selectedTypeData;
  //   final name = deviceNameController.text;
  //   final address = _tryParseInt(addressController.text);
  //   final function = _tryParseInt(selectedFunction, defaultValue: 1);

  //   if (widget.id != null) {
  //     final id = widget.id;
  //     return 'UPDATE|modbus|id:$id|name:$name|device_choose:$device|data_type:$type|address:$address|function_code:$function';
  //   }
  //   return 'CREATE|modbus|name:$name|device_choose:$device|data_type:$type|address:$address|function_code:$function';
  // }

  void _submit() async {
    // Validasi form
    if (!_formKey.currentState!.validate()) return;

    // // Periksa koneksi BLE
    // if (bleController.isConnected.isEmpty ||
    //     !bleController.isConnected.values.any((connected) => connected)) {
    //   Get.snackbar('Error', 'No BLE device connected');
    //   return;
    // }

    // // Konfirmasi sebelum submit
    // CustomAlertDialog.show(
    //   title: "Are you sure?",
    //   message:
    //       "Are you sure you want to ${widget.id != null ? 'update' : 'save'} this modbus config?",
    //   primaryButtonText: 'Yes',
    //   secondaryButtonText: 'No',
    //   onPrimaryPressed: () async {
    //     Get.back();
    //     await Future.delayed(const Duration(seconds: 1));

    //     try {
    //       final sendDataDelimiter = _formData();
    //       bleController.sendCommand(sendDataDelimiter, 'modbus');
    //     } catch (e) {
    //       debugPrint('Error submitting form: $e');
    //       Get.snackbar('Error', 'Failed to submit form: $e');
    //     } finally {
    //       await Future.delayed(const Duration(seconds: 3));
    //       AppHelpers.backNTimes(1);
    //     }
    //   },
    //   barrierDismissible: false,
    // );
  }

  @override
  void dispose() {
    deviceNameController.dispose();
    idSlaveController.dispose();
    addressController.dispose();
    refreshRateController.dispose();
    isInitialized = false;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Scaffold(appBar: _appBar(context), body: _body(context)),
        Obx(() {
          final isAnyDeviceLoading = controller.isFetching.value;
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
                isRequired: true,
              ),
              AppSpacing.md,
              Dropdown(
                items: deviceItem,
                selectedValue: selectedDevice,
                label: 'Choose Device',
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
                isRequired: true,
              ),
              AppSpacing.md,
              Dropdown(
                items: modbusReadFunctions,
                selectedValue: selectedFunction,
                label: 'Choose Function',
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
                isRequired: true,
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
                isRequired: true,
              ),
              AppSpacing.md,
              Dropdown(
                items: modbusDataTypes,
                selectedValue: selectedTypeData,
                label: 'Choose Data Type',
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
                isRequired: true,
              ),
              AppSpacing.md,
              CustomTextFormField(
                controller: refreshRateController,
                labelTxt: 'Refresh Rate',
                hintTxt: 'ex. 5000',
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Refresh rate is required';
                  }
                  final num = int.tryParse(value);
                  if (num == null || num <= 0) {
                    return 'Enter a valid positive number';
                  }
                  return null;
                },
                suffixIcon: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'm/s',
                      style: context.bodySmall.copyWith(color: AppColor.grey),
                    ),
                  ],
                ),
                isRequired: true,
              ),
              AppSpacing.lg,
              Button(
                width: MediaQuery.of(context).size.width,
                onPressed: _submit,
                text: 'Save',
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
