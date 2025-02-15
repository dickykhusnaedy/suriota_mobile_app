// ignore_for_file: prefer_const_literals_to_create_immutables, prefer_const_constructors

import 'package:flutter/material.dart';
import 'package:suriota_mobile_gateway/constant/app_color.dart';
import 'package:suriota_mobile_gateway/constant/app_gap.dart';
import 'package:suriota_mobile_gateway/constant/theme.dart';
import 'package:suriota_mobile_gateway/global/utils/text_extension.dart';
import 'package:suriota_mobile_gateway/global/widgets/custom_button.dart';
import 'package:suriota_mobile_gateway/global/widgets/custom_radiotile.dart';
import 'package:suriota_mobile_gateway/global/widgets/custom_textfield.dart';
import 'package:suriota_mobile_gateway/global/widgets/title_tile.dart';

class FormConfigServer extends StatefulWidget {
  const FormConfigServer({super.key});

  @override
  State<FormConfigServer> createState() => _FormConfigServerState();
}

class _FormConfigServerState extends State<FormConfigServer> {
  String protocolSelected = 'MQTT';
  String communcationSelected = 'Ethernet';
  String methodEthernet = "Automatic";
  String? confirmAuthentication;

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
              Column(
                children: [
                  const TitleTile(title: 'Choose Communication Mode'),
                  AppSpacing.sm,
                  // Ethernet Option
                  CustomRadioTile(
                    value: "Ethernet",
                    grupValue:
                        communcationSelected, // Use dynamic state variable
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
                    grupValue:
                        communcationSelected, // Use dynamic state variable
                    onChanges: () {
                      setState(() {
                        communcationSelected =
                            "WiFi"; // Set WiFi as selected communication
                      });
                    },
                  ),
                ],
              ),
              AppSpacing.md,
              // Show Ethernet Following fields if selected
              if (methodEthernet == "Following") ethernetFollowing(),
              if (communcationSelected == "WiFi") wifiField(),
              Column(
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
              ),
              AppSpacing.md,
              if (protocolSelected == "MQTT") mqttField(),
              if (protocolSelected == "HTTP") httpField(),
            ],
          ),
        ),
      ),
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
