import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:suriota_mobile_gateway/constant/app_color.dart';
import 'package:suriota_mobile_gateway/constant/app_gap.dart';
import 'package:suriota_mobile_gateway/controller/ble_controller.dart';
import 'package:suriota_mobile_gateway/global/utils/text_extension.dart';
import 'package:suriota_mobile_gateway/global/widgets/custom_button.dart';
import 'package:suriota_mobile_gateway/global/widgets/custom_dropdown.dart';
import 'package:suriota_mobile_gateway/global/widgets/custom_radiotile.dart';
import 'package:suriota_mobile_gateway/global/widgets/custom_textfield.dart';
import 'package:suriota_mobile_gateway/global/widgets/loading_overlay.dart';
import 'package:suriota_mobile_gateway/global/widgets/title_tile.dart';

class FormSetupDeviceScreen extends StatefulWidget {
  const FormSetupDeviceScreen({super.key});

  @override
  State<FormSetupDeviceScreen> createState() => _FormSetupDeviceScreenState();
}

class _FormSetupDeviceScreenState extends State<FormSetupDeviceScreen> {
  final BLEController bleController = Get.put(BLEController());

  String modBusSelected = "RS-4851";
  String protocolSelected = "IPv4";

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

  @override
  void initState() {
    super.initState();
    modbusTypeController.text = modBusSelected;
  }

  @override
  void dispose() {
    deviceNameController.dispose();
    refreshRateController.dispose();
    modbusTypeController.dispose();
    baudrateController.dispose();
    bidDataController.dispose();
    parityController.dispose();
    stopBitController.dispose();
    ipAddressController.dispose();
    serverPortController.dispose();
    super.dispose();
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
      final sendData = {
        "action": "CREATE",
        "dataset": "devices",
        "data": {
          "id": 105,
          "name": deviceNameController.text,
          "timestamp": DateTime.now().millisecondsSinceEpoch ~/ 1000,
          "modbus_type": modbusTypeController.text,
          "refresh_rate": refreshRateController.text.isNotEmpty
              ? int.parse(refreshRateController.text)
              : null,
          "baudrate": baudrateController.text.isNotEmpty
              ? int.parse(baudrateController.text)
              : null,
          "data_bits": bidDataController.text.isNotEmpty
              ? int.parse(bidDataController.text)
              : null,
          "parity": parityController.text.isNotEmpty
              ? int.parse(parityController.text)
              : null,
          "stop_bits": stopBitController.text.isNotEmpty
              ? int.parse(stopBitController.text)
              : null,
          "ip_address": ipAddressController.text,
          "port": serverPortController.text.isNotEmpty
              ? int.parse(serverPortController.text)
              : null
        }
      };

      bleController.sendCommand(sendData);
    }
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
            message: "Sending data...",
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
                    hintTxt: "Enter the Refresh Rate",
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
                    value: "RS-4851",
                    grupValue: modBusSelected,
                    onChanges: () {
                      setState(() {
                        modBusSelected = "RS-4851";
                        modbusTypeController.text = "RS-4851";
                      });
                    },
                  ),
                  CustomRadioTile(
                    value: "RS-4852",
                    grupValue: modBusSelected,
                    onChanges: () {
                      setState(() {
                        modBusSelected = "RS-4852";
                        modbusTypeController.text = "RS-4852";
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
              modBusSelected == 'RS-4851' || modBusSelected == 'RS-4852'
                  ? _formRS485Wrapper()
                  : _formTCPIPWrapper(),
              AppSpacing.lg,
              Button(
                width: MediaQuery.of(context).size.width,
                onPressed: _submit,
                text: "Save",
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
    List<String> parity = ['0', '1', '2'];
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
        AppSpacing.md
        // CustomTextFormField(
        //   controller: connectTimeoutController,
        //   labelTxt: "Connect Timeout",
        //   hintTxt: "3000 m/s",
        // ),
        // AppSpacing.md,
        // Text("Choose Internet Protocol", style: context.h6),
        // AppSpacing.sm,
        // CustomRadioTile(
        //   value: "IPv4",
        //   grupValue: protocolSelected,
        //   onChanges: () {
        //     setState(() {
        //       protocolSelected = "IPv4";
        //       internetProtocolController.text = "IPv4";
        //     });
        //   },
        // ),
        // CustomRadioTile(
        //   value: "IPv6",
        //   grupValue: protocolSelected,
        //   onChanges: () {
        //     setState(() {
        //       protocolSelected = "IPv6";
        //       internetProtocolController.text = "IPv6";
        //     });
        //   },
        // ),
      ],
    );
  }
}
