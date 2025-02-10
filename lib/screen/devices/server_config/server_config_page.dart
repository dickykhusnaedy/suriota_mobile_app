// ignore_for_file: prefer_const_literals_to_create_immutables, prefer_const_constructors

import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:suriota_mobile_gateway/global/widgets/custom_appbar.dart';
import 'package:suriota_mobile_gateway/global/widgets/custom_button.dart';
import 'package:suriota_mobile_gateway/global/widgets/title_tile.dart';

import '../../../constant/font_setup.dart';
import '../../../constant/theme.dart';
import '../../../global/widgets/custom_radiotile.dart';
import '../../../global/widgets/custom_textfield.dart';

class ServerConfigPage extends StatefulWidget {
  const ServerConfigPage({super.key});

  @override
  State<ServerConfigPage> createState() => _ServerConfigPageState();
}

class _ServerConfigPageState extends State<ServerConfigPage> {
  String protocolSelected = 'MQTT';
  String communcationSelected = 'Ethernet';
  String methodEthernet = "Automatic";
  String? confirmAuthentication;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(title: 'Server Configuration'),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const TitleTile(title: 'Choose Communication Mode'),
            // Ethernet Option
            CustomRadioTile(
              value: "Ethernet",
              grupValue: communcationSelected, // Use dynamic state variable
              onChanges: () {
                setState(() {
                  communcationSelected =
                      "Ethernet"; // Set Ethernet as selected communication
                });
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    scrollable: true,
                    title: Text(
                      "Choose Ethernet Method",
                      style: FontFamily.headlineMedium,
                    ),
                    content: Column(
                      children: [
                        // Automatic Ethernet method
                        CustomRadioTile(
                          value: "Automatic",
                          grupValue:
                              methodEthernet, // Reference dynamic variable
                          onChanges: () {
                            if (methodEthernet != "Automatic") {
                              setState(() {
                                methodEthernet =
                                    "Automatic"; // Set to Automatic
                              });
                            }
                            Navigator.pop(context); // Close the dialog
                          },
                        ),
                        // Following Ethernet method
                        CustomRadioTile(
                          value: "Following",
                          grupValue:
                              methodEthernet, // Reference dynamic variable
                          onChanges: () {
                            if (methodEthernet != "Following") {
                              setState(() {
                                methodEthernet =
                                    "Following"; // Set to Following
                              });
                            }
                            Navigator.pop(context); // Close the dialog
                          },
                        ),
                      ],
                    ),
                  ),
                );
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
            const Gap(6),
            // Show Ethernet Following fields if selected
            if (methodEthernet == "Following") ethernetFollowing(),

            if (communcationSelected == "WiFi") wifiField(),
            const Gap(8),
            SizedBox(
              width: MediaQuery.of(context).size.width * 1,
              child: const TitleTile(
                title: 'Choose Protocol',
              ),
            ),
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
            const Gap(8),
            if (protocolSelected == "MQTT") mqttField(),
            if (protocolSelected == "HTTP") httpField(),
          ],
        ),
      ),
    );
  }

  Widget ethernetFollowing() {
    return const Column(
      children: [
        CustomTextFormField(
          labelTxt: "IP Address",
          hintTxt: "Enter the IP Address",
        ),
        CustomTextFormField(
          labelTxt: "MAC Address",
          hintTxt: "Enter the MAC Address",
        ),
      ],
    );
  }

  Widget wifiField() {
    return const Column(
      children: [
        CustomTextFormField(
          labelTxt: "WiFi SSID",
          hintTxt: "Enter the WiFi SSID",
        ),
        CustomTextFormField(
          labelTxt: "WiFi Password",
          hintTxt: "Enter the WiFi Password",
        ),
      ],
    );
  }

  Widget mqttField() {
    confirmAuthentication == "Yes";

    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const TitleTile(title: "Setup MQTT Connection "),
        const Gap(6),
        const CustomTextFormField(
          labelTxt: "Server Name",
          hintTxt: "Enter the Server Name",
        ),
        const CustomTextFormField(
          labelTxt: "Port MQTT",
          hintTxt: "Enter the Port MQTT",
        ),
        const CustomTextFormField(
          labelTxt: "Client ID",
          hintTxt: "Enter the Client ID",
        ),
        const CustomTextFormField(
          labelTxt: "QoS Level",
          hintTxt: "Enter the QoS Level",
        ),
        const SizedBox(
          height: 12,
        ),
        Text(
          'Does the broker need an authentication?',
          style: FontFamily.headlineMedium,
        ),
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
          grupValue: confirmAuthentication ?? '',
          onChanges: () {
            if (confirmAuthentication != "No") {
              setState(() {
                confirmAuthentication = "No";
              });
            }
          },
        ),
        if (confirmAuthentication == "Yes") authentication(),
        const SizedBox(
          height: 53,
        ),
        CustomButton(
          onPressed: () {
            dialogSuccess(context);
          },
          titleButton: 'SAVE',
        )
      ],
    );
  }

  Widget httpField() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const TitleTile(title: "Setup HTTP Connection "),
        const Gap(6),
        const CustomTextFormField(
          labelTxt: "URL Link",
          hintTxt: "Enter the URL Link",
        ),
        const SizedBox(
          height: 12,
        ),
        Text(
          'Does the server need an authentication?',
          style: FontFamily.headlineMedium,
        ),
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
        if (confirmAuthentication == "Yes") authentication(),

        const SizedBox(
          height: 50,
        ),
        CustomButton(
          onPressed: () {
            dialogSuccess(context);
          },
          titleButton: 'SAVE',
        )
      ],
    );
  }

  Widget authentication() {
    return Column(
      children: [
        const CustomTextFormField(
          labelTxt: 'Username',
          hintTxt: 'Enter the Username',
        ),
        const CustomTextFormField(
          labelTxt: 'Password',
          hintTxt: 'Enter the Password',
        ),
      ],
    );
  }
}
