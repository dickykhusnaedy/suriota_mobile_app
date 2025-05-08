import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:suriota_mobile_gateway/constant/app_color.dart';
import 'package:suriota_mobile_gateway/constant/app_gap.dart';
import 'package:suriota_mobile_gateway/controller/ble_controller.dart';
import 'package:suriota_mobile_gateway/controller/device_data_controller.dart';
import 'package:suriota_mobile_gateway/global/utils/text_extension.dart';
import 'package:suriota_mobile_gateway/global/widgets/custom_button.dart';
import 'package:suriota_mobile_gateway/global/widgets/custom_dropdown.dart';
import 'package:suriota_mobile_gateway/global/widgets/custom_radiotile.dart';
import 'package:suriota_mobile_gateway/global/widgets/custom_textfield.dart';
import 'package:suriota_mobile_gateway/global/widgets/loading_overlay.dart';
import 'package:suriota_mobile_gateway/global/widgets/title_tile.dart';

class FormSetupDeviceScreen extends StatefulWidget {
  final int? id;

  const FormSetupDeviceScreen({super.key, this.id});

  @override
  State<FormSetupDeviceScreen> createState() => _FormSetupDeviceScreenState();
}

class _FormSetupDeviceScreenState extends State<FormSetupDeviceScreen> {
  final BLEController bleController = Get.put(BLEController());
  final dataDevice = Get.put(DeviceDataController());
  late final Function _deviceEver;

  String modBusSelected = "RTU";

  String? selectedBaudRate;
  String? selectedBiddata;
  String? selectedParity;
  String? selectedStopbit;

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  final deviceNameController = TextEditingController();
  final refreshRateController = TextEditingController();
  final modbusTypeController = TextEditingController();
  final baudrateController = TextEditingController();
  final bidDataController = TextEditingController();
  final parityController = TextEditingController();
  final stopBitController = TextEditingController();
  final ipAddressController = TextEditingController();
  final serverPortController = TextEditingController();
  final connectionTimeoutController = TextEditingController();

  @override
  void initState() {
    super.initState();

    if (widget.id != null) {
      dataDevice.clearDevice();

      Future.microtask(() async {
        bleController.sendCommand('READ|devices|id:${widget.id}');

        // Setelah selesai, pantau perubahan singleDevice
        _deviceEver = ever(dataDevice.singleDevice, (device) {
          if (!mounted || device.isEmpty) return;

          _fillFormFromDevice(device);
        });
      });
    } else {
      // Mode CREATE
      modBusSelected = "RTU";
      modbusTypeController.text = modBusSelected;
    }
  }

  void _fillFormFromDevice(Map<String, dynamic> device) {
    if (!mounted) return;

    modBusSelected = device['modbus_type'];

    modbusTypeController.text = device['modbus_type'];
    deviceNameController.text = device['name'] ?? '';
    refreshRateController.text = device['refresh_rate']?.toString() ?? '';

    if (device['modbus_type'] == 'TCP') {
      ipAddressController.text = device['ip_address'] ?? '';
      serverPortController.text = device['port']?.toString() ?? '';
      connectionTimeoutController.text =
          device['connection_timeout']?.toString() ?? '';
    } else {
      selectedBaudRate = device['baudrate']?.toString();
      selectedBiddata = device['data_bits']?.toString();
      selectedParity = device['parity'];
      selectedStopbit = device['stop_bits']?.toString();

      baudrateController.text = selectedBaudRate ?? '';
      bidDataController.text = selectedBiddata ?? '';
      parityController.text = selectedParity ?? '';
      stopBitController.text = selectedStopbit ?? '';
    }
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
      int? tryParseInt(String value) {
        return int.tryParse(value);
      }

      String buildDataRtu() {
        return 'baudrate:${tryParseInt(baudrateController.text)}|'
            'parity:${parityController.text}|'
            'data_bits:${tryParseInt(bidDataController.text)}|'
            'stop_bits:${tryParseInt(stopBitController.text)}';
      }

      String buildDataTcp() {
        return 'ip_address:${ipAddressController.text}|'
            'port:${tryParseInt(serverPortController.text)}|'
            'connection_timeout:${tryParseInt(connectionTimeoutController.text)}';
      }

      String buildSendDataDelimiter() {
        final modbusData = modbusTypeController.text == 'RTU'
            ? buildDataRtu()
            : buildDataTcp();

        final formData = widget.id != null
            ? 'UPDATE|devices|id:${widget.id}'
            : 'CREATE|devices';

        return '$formData|name:${deviceNameController.text}|'
            'modbus_type:${modbusTypeController.text}|'
            'refresh_rate:${tryParseInt(refreshRateController.text)}|$modbusData';
      }

      final sendDataDelimiter = buildSendDataDelimiter();

      bleController.sendCommand(sendDataDelimiter);
    }
  }

  @override
  void dispose() {
    dataDevice.clearDevice();
    if (widget.id != null) {
      _deviceEver(); // Hapus listener ever()
    }
    deviceNameController.dispose();
    refreshRateController.dispose();
    modbusTypeController.dispose();
    baudrateController.dispose();
    bidDataController.dispose();
    parityController.dispose();
    stopBitController.dispose();
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
                labelTxt: "Device Name",
                hintTxt: "Enter the device name",
              ),
              Column(
                children: [
                  AppSpacing.md,
                  CustomTextFormField(
                    controller: refreshRateController,
                    labelTxt: "Refresh Rate",
                    hintTxt: "5000",
                    keyboardType: TextInputType.number,
                    suffixIcon: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            "m/s",
                            style: context.bodySmall
                                .copyWith(color: AppColor.grey),
                          )
                        ]),
                  ),
                ],
              ),
              AppSpacing.md,
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Choose Modbus", style: context.h6),
                  AppSpacing.sm,
                  CustomRadioTile(
                    value: "RTU",
                    grupValue: modBusSelected,
                    onChanges: () {
                      setState(() {
                        modBusSelected = "RTU";
                        modbusTypeController.text = "RTU";

                        ipAddressController.clear();
                        serverPortController.clear();
                        connectionTimeoutController.clear();
                      });
                    },
                  ),
                  CustomRadioTile(
                    value: "TCP",
                    grupValue: modBusSelected,
                    onChanges: () {
                      setState(() {
                        modBusSelected = "TCP";
                        modbusTypeController.text = "TCP";

                        // Reset RS-485 field
                        baudrateController.clear();
                        bidDataController.clear();
                        parityController.clear();
                        stopBitController.clear();

                        // Reset selected value (untuk UI dropdown)
                        selectedBaudRate = null;
                        selectedBiddata = null;
                        selectedParity = null;
                        selectedStopbit = null;
                      });
                    },
                  ),
                ],
              ),
              AppSpacing.md,
              TitleTile(title: "Modbus Setup $modBusSelected"),
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
              AppSpacing.lg
            ],
          ),
        ),
      ),
    );
  }

  Widget _formRS485Wrapper() {
    List<String> baudrates = ['9600', '19200', '38400', '57600', '115200'];
    List<String> bitData = ['7', '8'];
    List<String> parity = ['none', 'even', 'odd'];
    List<String> stopBits = ['1', '2'];

    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Choose Baudrate',
          style: context.h6,
        ),
        AppSpacing.sm,
        CustomDropdown(
          listItem: baudrates,
          hintText: 'Choose the baudrate',
          selectedItem: selectedBaudRate,
          onChanged: (value) {
            setState(() {
              selectedBaudRate = value;
              baudrateController.text = value!;
            });
          },
        ),
        AppSpacing.md,
        Text(
          'Choose Bit Data',
          style: context.h6,
        ),
        AppSpacing.sm,
        CustomDropdown(
            listItem: bitData,
            hintText: 'Choose bit data',
            selectedItem: selectedBiddata,
            onChanged: (value) {
              setState(() {
                selectedBiddata = value;
                bidDataController.text = value!;
              });
            }),
        AppSpacing.md,
        Text(
          'Choose Parity',
          style: context.h6,
        ),
        AppSpacing.sm,
        CustomDropdown(
            listItem: parity,
            hintText: 'Choose the parity',
            selectedItem: selectedParity,
            onChanged: (value) {
              setState(() {
                selectedParity = value;
                parityController.text = value!;
              });
            }),
        AppSpacing.md,
        Text(
          'Choose Stop Bit',
          style: context.h6,
        ),
        AppSpacing.sm,
        CustomDropdown(
          listItem: stopBits,
          hintText: 'Choose the stop bit',
          selectedItem: selectedStopbit,
          onChanged: (value) {
            setState(() {
              selectedStopbit = value;
              stopBitController.text = value!;
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
          labelTxt: "IP Address",
          hintTxt: "127.0.0.1",
        ),
        AppSpacing.md,
        CustomTextFormField(
          controller: serverPortController,
          labelTxt: "Server Port",
          hintTxt: "502",
          keyboardType: TextInputType.number,
        ),
        AppSpacing.md,
        CustomTextFormField(
          controller: connectionTimeoutController,
          labelTxt: "Connect Timeout",
          hintTxt: "3000",
          keyboardType: TextInputType.number,
          suffixIcon:
              Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            Text(
              "m/s",
              style: context.bodySmall.copyWith(color: AppColor.grey),
            )
          ]),
        ),
        AppSpacing.md,
      ],
    );
  }
}
