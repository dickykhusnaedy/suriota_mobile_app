import 'package:flutter/material.dart';
import 'package:suriota_mobile_gateway/constant/app_color.dart';
import 'package:suriota_mobile_gateway/constant/app_gap.dart';
import 'package:suriota_mobile_gateway/constant/theme.dart';
import 'package:suriota_mobile_gateway/global/utils/text_extension.dart';
import 'package:suriota_mobile_gateway/global/widgets/custom_button.dart';
import 'package:suriota_mobile_gateway/global/widgets/custom_dropdown.dart';
import 'package:suriota_mobile_gateway/global/widgets/custom_radiotile.dart';
import 'package:suriota_mobile_gateway/global/widgets/custom_textfield.dart';
import 'package:suriota_mobile_gateway/global/widgets/title_tile.dart';

class FormSetupDeviceScreen extends StatefulWidget {
  const FormSetupDeviceScreen({super.key});

  @override
  State<FormSetupDeviceScreen> createState() => _FormSetupDeviceScreenState();
}

class _FormSetupDeviceScreenState extends State<FormSetupDeviceScreen> {
  String modBusSelected = "RS-485";
  String protocolSelected = "IPv4";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _appBar(context),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: AppPadding.horizontalMedium,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppSpacing.md,
              const CustomTextFormField(
                labelTxt: "Device Name",
                hintTxt: "Enter the device name",
              ),
              if (modBusSelected == "RS-485")
                Column(
                  children: [
                    AppSpacing.md,
                    CustomTextFormField(
                      labelTxt: "Refresh Rate",
                      hintTxt: "Enter the Refresh Rate",
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
                  Text("Choose Moodbus Type", style: context.h6),
                  AppSpacing.sm,
                  CustomRadioTile(
                    value: "RS-485",
                    grupValue: modBusSelected,
                    onChanges: () {
                      setState(() {
                        modBusSelected = "RS-485";
                      });
                    },
                  ),
                  CustomRadioTile(
                    value: "TCP/IP",
                    grupValue: modBusSelected,
                    onChanges: () {
                      setState(() {
                        modBusSelected = "TCP/IP";
                      });
                    },
                  ),
                ],
              ),
              AppSpacing.md,
              TitleTile(title: "Modbus Setup $modBusSelected"),
              AppSpacing.md,
              modBusSelected == 'RS-485'
                  ? _formRS485Wrapper()
                  : _formTCPIPWrapper(),
              AppSpacing.lg,
              Button(
                width: MediaQuery.of(context).size.width,
                onPressed: () {
                  ShowMessage.showCustomSnackBar(
                      context, "Feature for save data is coming soon!");
                },
                text: 'Save',
              ),
              AppSpacing.lg
            ],
          ),
        ),
      ),
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

  Widget _formRS485Wrapper() {
    List<String> baudrates = [
      '9600 Baud',
      '19200 Baud',
      '38400 Baud',
      '57600 Baud',
      '115200 Baud'
    ];
    List<String> bitData = [
      '7 Data Bits',
      '8 Data Bits',
    ];
    List<String> parity = ['None Parity', 'Odd Parity', 'Even Parity'];
    List<String> stopBits = [
      '1 Stop Bit',
      '2 Stop Bits',
    ];
    String? selectedBaudRate;

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
          selectedItem: selectedBaudRate ?? '',
        ),
        AppSpacing.md,
        Text(
          'Choose Bit Data',
          style: context.h6,
        ),
        AppSpacing.sm,
        CustomDropdown(listItem: bitData, hintText: 'Choose bit data'),
        AppSpacing.md,
        Text(
          'Choose Parity',
          style: context.h6,
        ),
        AppSpacing.sm,
        CustomDropdown(listItem: parity, hintText: 'Choose the parity'),
        AppSpacing.md,
        Text(
          'Choose Stop Bit',
          style: context.h6,
        ),
        AppSpacing.sm,
        CustomDropdown(listItem: stopBits, hintText: 'Choose the stop bit'),
      ],
    );
  }

  Widget _formTCPIPWrapper() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        const CustomTextFormField(
          labelTxt: "IP Address",
          hintTxt: "127.0.0.1",
        ),
        AppSpacing.md,
        const CustomTextFormField(
          labelTxt: "Server Port",
          hintTxt: "502",
        ),
        AppSpacing.md,
        const CustomTextFormField(
          labelTxt: "Connect Timeout",
          hintTxt: "3000 m/s",
        ),
        AppSpacing.md,
        Text("Choose Internet Protocol", style: context.h6),
        AppSpacing.sm,
        CustomRadioTile(
          value: "IPv4",
          grupValue: protocolSelected,
          onChanges: () {
            setState(() {
              protocolSelected = "IPv4";
            });
          },
        ),
        CustomRadioTile(
          value: "IPv6",
          grupValue: protocolSelected,
          onChanges: () {
            setState(() {
              protocolSelected = "IPv6";
            });
          },
        ),
      ],
    );
  }
}
