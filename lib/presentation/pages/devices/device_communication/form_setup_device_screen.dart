import 'package:flutter/material.dart';
import 'package:gateway_config/core/constants/app_color.dart';
import 'package:gateway_config/core/constants/app_gap.dart';
import 'package:gateway_config/core/controllers/ble_controller.dart';
import 'package:gateway_config/core/controllers/devices_controller.dart';
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

class FormSetupDeviceScreen extends StatefulWidget {
  final DeviceModel model;
  final String? deviceId;

  const FormSetupDeviceScreen({super.key, required this.model, this.deviceId});

  @override
  State<FormSetupDeviceScreen> createState() => _FormSetupDeviceScreenState();
}

class _FormSetupDeviceScreenState extends State<FormSetupDeviceScreen> {
  final controller = Get.put(BleController());
  final devicesController = Get.put(DevicesController());

  late Worker _worker;

  Map<String, dynamic> dataDevice = {};
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  String modBusSelected = 'RTU';
  String? selectedBaudRate;
  String? selectedBitData;
  String? selectedParity;
  String? selectedStopBit;
  String? selectedSerialPort;

  final deviceNameController = TextEditingController();
  final slaveIdController = TextEditingController();
  final retryCountController = TextEditingController();
  final refreshRateController = TextEditingController();
  final ipAddressController = TextEditingController();
  final serverPortController = TextEditingController();
  final connectionTimeoutController = TextEditingController();

  final serialData = [
    DropdownItems(text: '1', value: '1'),
    DropdownItems(text: '2', value: '2'),
  ];
  final baudrates = [
    DropdownItems(text: '9600', value: '9600'),
    DropdownItems(text: '19200', value: '19200'),
    DropdownItems(text: '38400', value: '38400'),
    DropdownItems(text: '57600', value: '57600'),
    DropdownItems(text: '115200', value: '115200'),
  ];
  final bitData = [
    DropdownItems(text: '7', value: '7'),
    DropdownItems(text: '8', value: '8'),
  ];
  final parity = [
    DropdownItems(text: 'None', value: 'None'),
    DropdownItems(text: 'Even', value: 'Even'),
    DropdownItems(text: 'Odd', value: 'Odd'),
  ];
  final stopBits = [
    DropdownItems(text: '1', value: '1'),
    DropdownItems(text: '2', value: '2'),
  ];

  @override
  void initState() {
    super.initState();
    // Listen to dataDevice GetX observable, update form when fetch finished
    _worker = ever(devicesController.selectedDevice, (dataList) {
      if (!mounted) return;
      if (dataList.isNotEmpty) {
        _fillFormFromDevice(dataList[0]);
      } else {
        modBusSelected = 'RTU';
      }
    });

    // Fetch data after widget build
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (widget.deviceId != null) {
        await devicesController.getDeviceById(widget.model, widget.deviceId!);
      }
    });
  }

  void _fillFormFromDevice(Map<String, dynamic> device) {
    deviceNameController.text = device['device_name'] ?? '';
    slaveIdController.text = device['slave_id']?.toString() ?? '';
    modBusSelected = device['protocol'] ?? 'RTU';

    if (device['protocol'] == 'RTU') {
      selectedSerialPort = device['serial_port']?.toString();
      selectedBaudRate = device['baud_rate']?.toString();
      selectedBitData = device['data_bits']?.toString();
      selectedParity = device['parity'] ?? 'None';
      selectedStopBit = device['stop_bits']?.toString();
    } else {
      ipAddressController.text = device['ip'] ?? '';
      serverPortController.text = device['port']?.toString() ?? '';
    }

    retryCountController.text = device['retry_count']?.toString() ?? '';
    connectionTimeoutController.text = device['timeout']?.toString() ?? '';
    refreshRateController.text = device['refresh_rate_ms']?.toString() ?? '';

    setState(() {});
  }

  void _submit() async {
    // Validasi form
    if (!_formKey.currentState!.validate()) return;

    // Check BLE Connection
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
      title: "Are you sure?",
      message:
          "Are you sure you want to ${widget.deviceId == null ? 'save' : 'update'} this device?",
      primaryButtonText: 'Yes',
      secondaryButtonText: 'No',
      onPrimaryPressed: () async {
        Get.back();
        controller.isLoading.value = true;

        try {
          var modbusRtu = {
            "serial_port": _tryParseInt(selectedSerialPort, defaultValue: 1),
            "baud_rate": _tryParseInt(selectedBaudRate, defaultValue: 9600),
            "data_bits": _tryParseInt(selectedBitData, defaultValue: 8),
            "stop_bits": _tryParseInt(selectedStopBit, defaultValue: 1),
            "parity": selectedParity ?? "None",
          };

          var modbusTcp = {
            "ip": _sanitizeInput(ipAddressController.text),
            "port": _tryParseInt(serverPortController.text, defaultValue: 502),
          };

          var formData = {
            "op": widget.deviceId != null ? "update" : "create",
            "type": "device",
            if (widget.deviceId != '') "device_id": widget.deviceId,
            "config": {
              "device_name": _sanitizeInput(deviceNameController.text),
              "protocol": modBusSelected,
              "slave_id": _tryParseInt(slaveIdController.text),
              "timeout": _tryParseInt(
                connectionTimeoutController.text,
                defaultValue: 3000,
              ),
              "retry_count": _tryParseInt(
                retryCountController.text,
                defaultValue: 3,
              ),
              "refresh_rate_ms": _tryParseInt(
                refreshRateController.text,
                defaultValue: 5000,
              ),
              ...modBusSelected == 'RTU' ? modbusRtu : modbusTcp,
            },
          };

          await controller.sendCommand(formData);

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
          controller.isLoading.value = false;
        }
      },
      barrierDismissible: false,
    );
  }

  String _sanitizeInput(String input) {
    return input.replaceAll('|', '').replaceAll('#', '');
  }

  int? _tryParseInt(String? value, {int? defaultValue}) {
    if (value == null || value.isEmpty) return defaultValue;
    return int.tryParse(value) ?? defaultValue;
  }

  @override
  void dispose() {
    _worker.dispose();

    deviceNameController.dispose();
    slaveIdController.dispose();
    retryCountController.dispose();
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
        Scaffold(appBar: _appBar(context), body: _body(context)),
        Obx(() {
          final isAnyDeviceLoading =
              controller.commandLoading.value ||
              devicesController.isFetching.value;
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
                readOnly: false,
                isRequired: true,
              ),
              AppSpacing.md,
              CustomTextFormField(
                controller: slaveIdController,
                labelTxt: 'Slave ID',
                hintTxt: 'Enter the slave ID',
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Slave ID is required';
                  }
                  return null;
                },
                readOnly: false,
                isRequired: true,
              ),
              AppSpacing.md,
              SectionDivider(
                title: 'Protocol Selection',
                icon: Icons.settings_input_antenna,
              ),
              AppSpacing.md,
              _buildModbusTypeSelector(),
              AppSpacing.md,
              SectionDivider(
                title: 'Modbus $modBusSelected Configuration',
                icon: Icons.tune,
              ),
              AppSpacing.md,
              modBusSelected == 'RTU'
                  ? _formRS485Wrapper()
                  : _formTCPIPWrapper(),
              AppSpacing.md,
              SectionDivider(
                title: 'Advanced Settings',
                icon: Icons.settings_suggest,
              ),
              AppSpacing.md,
              CustomTextFormField(
                controller: retryCountController,
                labelTxt: 'Retry Count',
                hintTxt: 'ex. 3',
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Retry count is required';
                  }
                  return null;
                },
                isRequired: true,
              ),
              AppSpacing.md,
              CustomTextFormField(
                controller: connectionTimeoutController,
                labelTxt: 'Connect Timeout',
                hintTxt: 'ex. 3000',
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Timeout is required';
                  }

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
              GradientButton(
                text: widget.deviceId != null
                    ? 'Update Device Configuration'
                    : 'Save Device Configuration',
                icon: widget.deviceId != null ? Icons.update : Icons.save,
                onPressed: _submit,
              ),
              AppSpacing.lg,
            ],
          ),
        ),
      ),
    );
  }

  Widget _formRS485Wrapper() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Dropdown(
          label: 'Choose Serial Port',
          items: serialData,
          selectedValue: selectedSerialPort,
          onChanged: (item) {
            setState(() {
              selectedSerialPort = item!.value;
            });
          },
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please select serial port';
            }
            return null;
          },
          showSearchBox: serialData.length > 5,
          isRequired: true,
        ),
        AppSpacing.md,
        Dropdown(
          label: 'Choose Baudrate',
          items: baudrates,
          selectedValue: selectedBaudRate,
          onChanged: (item) {
            setState(() {
              selectedBaudRate = item!.value;
            });
          },
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please select baudrate data';
            }
            return null;
          },
          showSearchBox: baudrates.length > 5,
          isRequired: true,
        ),
        AppSpacing.md,
        Dropdown(
          label: 'Choose Bit Data',
          items: bitData,
          selectedValue: selectedBitData,
          onChanged: (item) {
            setState(() {
              selectedBitData = item!.value;
            });
          },
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please select bit data';
            }
            return null;
          },
          showSearchBox: bitData.length > 5,
          isRequired: true,
        ),
        AppSpacing.md,
        Dropdown(
          label: 'Choose Parity',
          items: parity,
          selectedValue: selectedParity,
          onChanged: (item) {
            setState(() {
              selectedParity = item!.value;
            });
          },
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please select the parity';
            }
            return null;
          },
          showSearchBox: parity.length > 5,
          isRequired: true,
        ),
        AppSpacing.md,
        Dropdown(
          label: 'Choose Stop Bit',
          items: stopBits,
          selectedValue: selectedStopBit,
          onChanged: (item) {
            setState(() {
              selectedStopBit = item!.value;
            });
          },
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please select the stop bit';
            }
            return null;
          },
          showSearchBox: stopBits.length > 5,
          isRequired: true,
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
          isRequired: true,
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
          isRequired: true,
        ),
      ],
    );
  }

  Widget _buildModbusTypeSelector() {
    return Container(
      decoration: BoxDecoration(
        color: AppColor.whiteColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColor.primaryColor.withValues(alpha: 0.15),
          width: 1.5,
        ),
      ),
      padding: const EdgeInsets.all(4),
      child: Column(
        children: [
          _buildModbusOption(
            value: 'RTU',
            title: 'Modbus RTU',
            subtitle: 'Serial communication (RS485)',
            icon: Icons.settings_input_component,
          ),
          const SizedBox(height: 4),
          _buildModbusOption(
            value: 'TCP',
            title: 'Modbus TCP',
            subtitle: 'Ethernet/IP communication',
            icon: Icons.lan,
          ),
        ],
      ),
    );
  }

  Widget _buildModbusOption({
    required String value,
    required String title,
    required String subtitle,
    required IconData icon,
  }) {
    final isSelected = modBusSelected == value;

    return InkWell(
      onTap: () {
        setState(() {
          modBusSelected = value;

          if (value == 'RTU') {
            if (widget.deviceId == null) {
              ipAddressController.clear();
              serverPortController.clear();
            }
          } else {
            // TCP selected
            if (widget.deviceId == null) {
              selectedBaudRate = null;
              selectedBitData = null;
              selectedParity = null;
              selectedStopBit = null;
              selectedSerialPort = null;
            }
          }
        });
      },
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColor.primaryColor.withValues(alpha: 0.1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? AppColor.primaryColor : Colors.transparent,
            width: 2,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColor.primaryColor
                    : AppColor.grey.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                color: isSelected ? AppColor.whiteColor : AppColor.grey,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: context.h6.copyWith(
                      color: isSelected
                          ? AppColor.primaryColor
                          : AppColor.blackColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: context.bodySmall.copyWith(
                      color: AppColor.grey,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              isSelected ? Icons.check_circle : Icons.circle_outlined,
              color: isSelected ? AppColor.primaryColor : AppColor.grey,
              size: 24,
            ),
          ],
        ),
      ),
    );
  }
}
