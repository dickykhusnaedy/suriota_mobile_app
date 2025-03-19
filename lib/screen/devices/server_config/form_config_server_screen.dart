// ignore_for_file: prefer_const_literals_to_create_immutables, prefer_const_constructors

import 'package:flutter/material.dart';
import 'package:multi_dropdown/multi_dropdown.dart';
import 'package:suriota_mobile_gateway/constant/app_color.dart';
import 'package:suriota_mobile_gateway/constant/app_gap.dart';
import 'package:suriota_mobile_gateway/constant/font_setup.dart';
import 'package:suriota_mobile_gateway/constant/theme.dart';
import 'package:suriota_mobile_gateway/global/utils/text_extension.dart';
import 'package:suriota_mobile_gateway/global/widgets/custom_button.dart';
import 'package:suriota_mobile_gateway/global/widgets/custom_dropdown.dart';
import 'package:suriota_mobile_gateway/global/widgets/custom_radiotile.dart';
import 'package:suriota_mobile_gateway/global/widgets/custom_textfield.dart';
import 'package:suriota_mobile_gateway/global/widgets/title_tile.dart';

class FormConfigServer extends StatefulWidget {
  const FormConfigServer({super.key});

  @override
  State<FormConfigServer> createState() => _FormConfigServerState();
}

class LoggingData {
  final String name;
  final int id;

  LoggingData({required this.name, required this.id});

  @override
  String toString() {
    return 'LoggingData(name: $name, id: $id)';
  }
}

class _FormConfigServerState extends State<FormConfigServer> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  String protocolSelected = 'MQTT';
  String communcationSelected = 'Ethernet';
  String methodEthernet = "Automatic";
  String loggingIntervalSelected = "30 seconds";

  String? confirmAuthentication;

  @override
  Widget build(BuildContext context) {
    var items = [
      DropdownItem(label: 'Sensor', value: LoggingData(name: 'Sensor', id: 1)),
      DropdownItem(
          label: 'Tekanan', value: LoggingData(name: 'Tekanan', id: 6)),
      DropdownItem(label: 'Suhu', value: LoggingData(name: 'Suhu', id: 2)),
    ];

    List<String> typeInterval = [
      'Seconds',
      'Minutes',
    ];

    return Scaffold(
      appBar: _appBar(context),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: AppPadding.horizontalMedium,
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppSpacing.md,
                _communicationModeWrapper(context),
                AppSpacing.md,
                // Show Ethernet Following fields if selected
                if (methodEthernet == "Following") ethernetFollowing(),
                if (communcationSelected == "WiFi") wifiField(),
                _protocolWrapper(),
                AppSpacing.md,
                _intervalWrapper(context, items, typeInterval),
                AppSpacing.md,
                if (protocolSelected == "MQTT") mqttField(),
                if (protocolSelected == "HTTP") httpField(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Column _intervalWrapper(BuildContext context,
      List<DropdownItem<LoggingData>> items, List<String> typeInterval) {
    return Column(children: [
      TitleTile(title: 'Data Interval'),
      AppSpacing.sm,
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Data Interval',
              style: context.h6.copyWith(fontWeight: FontWeightTheme.bold)),
          AppSpacing.sm,
          MultiDropdown<LoggingData>(
            items: items,
            enabled: true,
            chipDecoration: ChipDecoration(
                labelStyle: context.buttonTextSmall
                    .copyWith(color: AppColor.whiteColor),
                backgroundColor: AppColor.primaryColor,
                padding: AppPadding.small,
                wrap: true,
                runSpacing: 10,
                spacing: 5,
                deleteIcon: const Icon(
                  Icons.cancel,
                  size: 17,
                  color: AppColor.whiteColor,
                )),
            fieldDecoration: FieldDecoration(
              hintText: 'Choose Data Interval',
              hintStyle: context.body,
              showClearIcon: false,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide:
                    const BorderSide(color: AppColor.primaryColor, width: 1),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide:
                    const BorderSide(color: AppColor.primaryColor, width: 2),
              ),
            ),
            dropdownItemDecoration: const DropdownItemDecoration(
              textColor: AppColor.grey,
              selectedTextColor: AppColor.primaryColor,
              selectedIcon: Icon(Icons.check_box, color: AppColor.primaryColor),
              disabledIcon: Icon(Icons.lock, color: Colors.grey),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please select a data interval';
              }
              return null;
            },
            onSelectionChange: (selectedItems) {
              debugPrint("OnSelectionChange: $selectedItems");
            },
          ),
        ],
      ),
      AppSpacing.md,
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Interval Time',
              style: context.h6.copyWith(fontWeight: FontWeightTheme.bold)),
          CustomTextFormField(
              hintTxt: 'Set Interval Time', keyboardType: TextInputType.number),
          AppSpacing.sm,
          CustomDropdown(
              listItem: typeInterval, hintText: 'Choose Interval Type'),
        ],
      )
    ]);
  }

  Column _protocolWrapper() {
    return Column(
      children: [
        const TitleTile(title: 'Choose Protocol'),
        AppSpacing.sm,
        CustomRadioTile(
          value: "MQTT",
          grupValue: protocolSelected,
          onChanges: () {
            if (protocolSelected != "MQTT") {
              setState(() {
                protocolSelected = "MQTT";
              });
            }
          },
        ),
        CustomRadioTile(
          value: "HTTP",
          grupValue: protocolSelected,
          onChanges: () {
            if (protocolSelected != "HTTP") {
              setState(() {
                protocolSelected = "HTTP";
              });
            }
          },
        ),
      ],
    );
  }

  Column _communicationModeWrapper(BuildContext context) {
    return Column(
      children: [
        const TitleTile(title: 'Choose Communication Mode'),
        AppSpacing.sm,
        // Ethernet Option
        CustomRadioTile(
          value: "Ethernet",
          grupValue: communcationSelected, // Use dynamic state variable
          onChanges: () {
            setState(() {
              communcationSelected =
                  "Ethernet"; // Set Ethernet as selected communication
            });
            _chooseEthernetMethod(context);
          },
        ),
        // WiFi Option
        CustomRadioTile(
          value: "WiFi",
          grupValue: communcationSelected, // Use dynamic state variable
          onChanges: () {
            setState(() {
              communcationSelected =
                  "WiFi"; // Set WiFi as selected communication
            });
          },
        ),
      ],
    );
  }

  Future<dynamic> _chooseEthernetMethod(BuildContext context) {
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        scrollable: true,
        title: Text(
          "Choose Ethernet Method",
          style: context.h5,
        ),
        content: Column(
          children: [
            // Automatic Ethernet method
            CustomRadioTile(
              value: "Automatic",
              grupValue: methodEthernet, // Reference dynamic variable
              onChanges: () {
                if (methodEthernet != "Automatic") {
                  setState(() {
                    methodEthernet = "Automatic"; // Set to Automatic
                  });
                }
                Navigator.pop(context); // Close the dialog
              },
            ),
            // Following Ethernet method
            CustomRadioTile(
              value: "Following",
              grupValue: methodEthernet, // Reference dynamic variable
              onChanges: () {
                if (methodEthernet != "Following") {
                  setState(() {
                    methodEthernet = "Following"; // Set to Following
                  });
                }
                Navigator.pop(context); // Close the dialog
              },
            ),
          ],
        ),
      ),
    );
  }

  AppBar _appBar(BuildContext context) {
    return AppBar(
      title: Text(
        'Form Config Server',
        style: context.h5.copyWith(color: AppColor.whiteColor),
      ),
      iconTheme: const IconThemeData(color: AppColor.whiteColor),
      backgroundColor: AppColor.primaryColor,
      centerTitle: true,
    );
  }

  Widget ethernetFollowing() {
    return Column(
      children: [
        CustomTextFormField(
          labelTxt: "IP Address",
          hintTxt: "Enter the IP Address",
        ),
        AppSpacing.md,
        CustomTextFormField(
          labelTxt: "MAC Address",
          hintTxt: "Enter the MAC Address",
        ),
        AppSpacing.md,
      ],
    );
  }

  Widget wifiField() {
    return Column(
      children: [
        CustomTextFormField(
          labelTxt: "WiFi SSID",
          hintTxt: "Enter the WiFi SSID",
        ),
        AppSpacing.md,
        CustomTextFormField(
          labelTxt: "WiFi Password",
          hintTxt: "Enter the WiFi Password",
        ),
        AppSpacing.md,
      ],
    );
  }

  Widget mqttField() {
    confirmAuthentication == "Yes";

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TitleTile(title: "Setup MQTT Connection"),
        AppSpacing.md,
        CustomTextFormField(
          labelTxt: "Server Name",
          hintTxt: "Enter the Server Name",
        ),
        AppSpacing.md,
        CustomTextFormField(
          labelTxt: "Port MQTT",
          hintTxt: "Enter the Port MQTT",
        ),
        AppSpacing.md,
        CustomTextFormField(
          labelTxt: "Publish Topic",
          hintTxt: "Enter the Publish Topic",
        ),
        AppSpacing.md,
        CustomTextFormField(
          labelTxt: "Client ID",
          hintTxt: "Enter the Client ID",
        ),
        AppSpacing.md,
        CustomTextFormField(
          labelTxt: "QoS Level",
          hintTxt: "Enter the QoS Level",
        ),
        AppSpacing.md,
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Does the broker need an authentication?',
              style: context.h6,
            ),
            AppSpacing.sm,
            CustomRadioTile(
              value: "Yes",
              grupValue: confirmAuthentication ?? '',
              onChanges: () {
                setState(() {
                  confirmAuthentication = "Yes";
                });
              },
            ),
            CustomRadioTile(
              value: "No",
              grupValue: confirmAuthentication ?? '',
              onChanges: () {
                setState(() {
                  confirmAuthentication = "No";
                });
              },
            ),
          ],
        ),
        AppSpacing.sm,
        if (confirmAuthentication == "Yes") authentication(),
        AppSpacing.lg,
        Button(
          width: MediaQuery.of(context).size.width,
          onPressed: () {
            ShowMessage.showCustomSnackBar(
                context, "Feature for save data is coming soon!");
          },
          text: 'Save',
          height: 50,
        ),
        AppSpacing.lg,
      ],
    );
  }

  Widget httpField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TitleTile(title: "Setup HTTP Connection"),
        AppSpacing.md,
        CustomTextFormField(
          labelTxt: "URL Link",
          hintTxt: "Enter the URL Link",
        ),
        AppSpacing.md,
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Does the server need an authentication?', style: context.h6),
            AppSpacing.sm,
            CustomRadioTile(
              value: "Yes",
              grupValue: confirmAuthentication ?? '',
              onChanges: () {
                if (confirmAuthentication != "Yes") {
                  setState(() {
                    confirmAuthentication = "Yes";
                  });
                }
              },
            ),
            CustomRadioTile(
              value: "No",
              grupValue: confirmAuthentication ?? "",
              onChanges: () {
                if (confirmAuthentication != "No") {
                  setState(() {
                    confirmAuthentication = "No";
                  });
                }
              },
            ),
          ],
        ),
        if (confirmAuthentication == "Yes") authentication(),
        AppSpacing.lg,
        Button(
          width: MediaQuery.of(context).size.width,
          onPressed: () {
            ShowMessage.showCustomSnackBar(
                context, "Feature for save data is coming soon!");
          },
          text: 'Save',
          height: 50,
        ),
        AppSpacing.lg,
      ],
    );
  }

  Widget authentication() {
    return Column(
      children: [
        AppSpacing.sm,
        CustomTextFormField(
          labelTxt: 'Username',
          hintTxt: 'Enter the Username',
        ),
        AppSpacing.md,
        CustomTextFormField(
          labelTxt: 'Password',
          hintTxt: 'Enter the Password',
        ),
      ],
    );
  }
}
