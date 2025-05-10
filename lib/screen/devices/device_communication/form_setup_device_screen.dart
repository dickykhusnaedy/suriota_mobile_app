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
import 'package:suriota_mobile_gateway/global/widgets/custom_radiotile.dart';
import 'package:suriota_mobile_gateway/global/widgets/custom_textfield.dart';
import 'package:suriota_mobile_gateway/global/widgets/loading_overlay.dart';
import 'package:suriota_mobile_gateway/global/widgets/title_tile.dart';
import 'package:suriota_mobile_gateway/screen/devices/device_communication/device_communications_screen.dart';

class FormSetupDeviceScreen extends StatefulWidget {
  final int? id;

  const FormSetupDeviceScreen({super.key, this.id});

  @override
  State<FormSetupDeviceScreen> createState() => _FormSetupDeviceScreenState();
}

class _FormSetupDeviceScreenState extends State<FormSetupDeviceScreen> {
  late final BLEController bleController;
  final controller = Get.put(DevicePaginationController());

  Map<String, dynamic> dataDevice = {};

  String modBusSelected = 'RTU';
  String? selectedBaudRate;
  String? selectedBitData;
  String? selectedParity;
  String? selectedStopBit;
  bool isFetching = false;

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  final deviceNameController = TextEditingController();
  final refreshRateController = TextEditingController();
  final ipAddressController = TextEditingController();
  final serverPortController = TextEditingController();
  final connectionTimeoutController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Inisialisasi controller dengan pengecekan untuk mencegah error Get.find
    bleController = Get.put(BLEController());

    if (widget.id != null) {
      dataDevice = controller.devices
          .firstWhere((item) => item['id'] == widget.id, orElse: () => {});

      _fillFormFromDevice(dataDevice);
    } else {
      modBusSelected = 'RTU';
    }
  }

  void _fillFormFromDevice(Map<String, dynamic> device) {
    setState(() {
      modBusSelected = device['modbus_type'] ?? 'RTU';
      deviceNameController.text = device['name'] ?? '';
      refreshRateController.text = device['refresh_rate']?.toString() ?? '';

      if (device['modbus_type'] == 'TCP') {
        ipAddressController.text = device['ip_address'] ?? '';
        serverPortController.text = device['port']?.toString() ?? '';
        connectionTimeoutController.text =
            device['connection_timeout']?.toString() ?? '';
      } else {
        selectedBaudRate = device['baudrate']?.toString();
        selectedBitData = device['data_bits']?.toString();
        selectedParity = device['parity'];
        selectedStopBit = device['stop_bits']?.toString();
      }
      isFetching = false;
    });
  }

  String? _validateRTUFields() {
    if (modBusSelected == 'RTU') {
      if (selectedBaudRate == null) return 'Baudrate is required';
      if (selectedBitData == null) return 'Bit data is required';
      if (selectedParity == null) return 'Parity is required';
      if (selectedStopBit == null) return 'Stop bit is required';
    }
    return null;
  }

  void _submit() async {
    // Validasi field RTU
    final rtuError = _validateRTUFields();
    if (rtuError != null) {
      Get.snackbar('Error', rtuError);
      return;
    }

    // Validasi form
    if (!_formKey.currentState!.validate()) return;

    // Periksa koneksi BLE
    if (bleController.isConnected.isEmpty ||
        !bleController.isConnected.values.any((connected) => connected)) {
      Get.snackbar('Error', 'No BLE device connected');
      return;
    }

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
                  Text(
                      "Are you sure you want to ${widget.id != null ? 'update' : 'save'} this device?",
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
                              final sendDataDelimiter =
                                  _buildSendDataDelimiter();
                              debugPrint('Sending command: $sendDataDelimiter');
                              bleController.sendCommand(
                                  sendDataDelimiter, 'devices');

                              await Future.delayed(const Duration(seconds: 3));
                              Get.to(() => const DeviceCommunicationsScreen());
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

  String _sanitizeInput(String input) {
    return input.replaceAll('|', '').replaceAll('#', '');
  }

  int? _tryParseInt(String? value, {int? defaultValue}) {
    if (value == null || value.isEmpty) return defaultValue;
    return int.tryParse(value) ?? defaultValue;
  }

  String _buildDataRtu() {
    final baudrate = _tryParseInt(selectedBaudRate, defaultValue: 9600);
    final dataBits = _tryParseInt(selectedBitData, defaultValue: 8);
    final stopBits = _tryParseInt(selectedStopBit, defaultValue: 1);
    final parityValue = selectedParity ?? 'none';

    return 'baudrate:$baudrate|parity:$parityValue|data_bits:$dataBits|stop_bits:$stopBits';
  }

  String _buildDataTcp() {
    final ip = _sanitizeInput(ipAddressController.text);
    final port = _tryParseInt(serverPortController.text, defaultValue: 502);
    final timeout =
        _tryParseInt(connectionTimeoutController.text, defaultValue: 3000);

    return 'ip_address:$ip|port:$port|connection_timeout:$timeout';
  }

  String _buildSendDataDelimiter() {
    final modbusData =
        modBusSelected == 'RTU' ? _buildDataRtu() : _buildDataTcp();
    final formData =
        widget.id != null ? 'UPDATE|devices|id:${widget.id}' : 'CREATE|devices';
    final name = _sanitizeInput(deviceNameController.text);
    final refreshRate =
        _tryParseInt(refreshRateController.text, defaultValue: 5000);

    return '$formData|name:$name|modbus_type:$modBusSelected|refresh_rate:$refreshRate|$modbusData';
  }

  @override
  void dispose() {
    deviceNameController.dispose();
    refreshRateController.dispose();
    ipAddressController.dispose();
    serverPortController.dispose();
    connectionTimeoutController.dispose();
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
        'Form Setup Device',
        style: context.h5.copyWith(color: AppColor.whiteColor),
      ),
      iconTheme: const IconThemeData(color: AppColor.whiteColor),
      backgroundColor: AppColor.primaryColor,
      centerTitle: true,
    );
  }

  SafeArea _body(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: AppPadding.horizontalMedium,
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppSpacing.md,
              CustomTextFormField(
                controller: deviceNameController,
                labelTxt: 'Device Name',
                hintTxt: 'Enter the device name',
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Device name is required';
                  }
                  if (value.length > 50) {
                    return 'Device name too long (max 50 characters)';
                  }
                  return null;
                },
              ),
              AppSpacing.md,
              CustomTextFormField(
                controller: refreshRateController,
                labelTxt: 'Refresh Rate',
                hintTxt: '5000',
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
              ),
              AppSpacing.md,
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Choose Modbus', style: context.h6),
                  AppSpacing.sm,
                  CustomRadioTile(
                    value: 'RTU',
                    grupValue: modBusSelected,
                    onChanges: () {
                      setState(() {
                        modBusSelected = 'RTU';
                        ipAddressController.clear();
                        serverPortController.clear();
                        connectionTimeoutController.clear();
                      });
                    },
                  ),
                  CustomRadioTile(
                    value: 'TCP',
                    grupValue: modBusSelected,
                    onChanges: () {
                      setState(() {
                        modBusSelected = 'TCP';
                        selectedBaudRate = null;
                        selectedBitData = null;
                        selectedParity = null;
                        selectedStopBit = null;
                      });
                    },
                  ),
                ],
              ),
              AppSpacing.md,
              TitleTile(title: 'Modbus Setup $modBusSelected'),
              AppSpacing.md,
              modBusSelected == 'RTU'
                  ? _formRS485Wrapper()
                  : _formTCPIPWrapper(),
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

  Widget _formRS485Wrapper() {
    final baudrates = ['9600', '19200', '38400', '57600', '115200'];
    final bitData = ['7', '8'];
    final parity = ['none', 'even', 'odd'];
    final stopBits = ['1', '2'];

    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Choose Baudrate', style: context.h6),
        AppSpacing.sm,
        CustomDropdown(
          listItem: baudrates,
          hintText: 'Choose the baudrate',
          selectedItem: selectedBaudRate,
          onChanged: (value) {
            setState(() {
              selectedBaudRate = value;
            });
          },
        ),
        AppSpacing.md,
        Text('Choose Bit Data', style: context.h6),
        AppSpacing.sm,
        CustomDropdown(
          listItem: bitData,
          hintText: 'Choose bit data',
          selectedItem: selectedBitData,
          onChanged: (value) {
            setState(() {
              selectedBitData = value;
            });
          },
        ),
        AppSpacing.md,
        Text('Choose Parity', style: context.h6),
        AppSpacing.sm,
        CustomDropdown(
          listItem: parity,
          hintText: 'Choose the parity',
          selectedItem: selectedParity,
          onChanged: (value) {
            setState(() {
              selectedParity = value;
            });
          },
        ),
        AppSpacing.md,
        Text('Choose Stop Bit', style: context.h6),
        AppSpacing.sm,
        CustomDropdown(
          listItem: stopBits,
          hintText: 'Choose the stop bit',
          selectedItem: selectedStopBit,
          onChanged: (value) {
            setState(() {
              selectedStopBit = value;
            });
          },
        ),
      ],
    );
  }

  Widget _formTCPIPWrapper() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        CustomTextFormField(
          controller: ipAddressController,
          labelTxt: 'IP Address',
          hintTxt: '127.0.0.1',
          validator: (value) {
            if (value == null || value.isEmpty) return 'IP address is required';
            final ipPattern = RegExp(r'^\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}$');
            if (!ipPattern.hasMatch(value)) return 'Invalid IP address format';
            return null;
          },
        ),
        AppSpacing.md,
        CustomTextFormField(
          controller: serverPortController,
          labelTxt: 'Server Port',
          hintTxt: '502',
          keyboardType: TextInputType.number,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Server port is required';
            }
            final port = int.tryParse(value);
            if (port == null || port < 1 || port > 65535) {
              return 'Enter a valid port (1-65535)';
            }
            return null;
          },
        ),
        AppSpacing.md,
        CustomTextFormField(
          controller: connectionTimeoutController,
          labelTxt: 'Connect Timeout',
          hintTxt: '3000',
          keyboardType: TextInputType.number,
          validator: (value) {
            if (value == null || value.isEmpty) return 'Timeout is required';
            final timeout = int.tryParse(value);
            if (timeout == null || timeout <= 0) {
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
        ),
      ],
    );
  }
}
