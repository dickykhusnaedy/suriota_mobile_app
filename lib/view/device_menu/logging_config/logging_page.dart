import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:multi_dropdown/multi_dropdown.dart';
import 'package:suriota_mobile_gateway/constant/font_setup.dart';
import 'package:suriota_mobile_gateway/constant/theme.dart';
import 'package:suriota_mobile_gateway/global/widgets/custom_appbar.dart';
import 'package:suriota_mobile_gateway/global/widgets/custom_button.dart';
import 'package:suriota_mobile_gateway/global/widgets/title_tile.dart';

import '../../../constant/app_color.dart';
import '../../../global/widgets/custom_radiotile.dart';

class LoggingConfigurationPage extends StatefulWidget {
  const LoggingConfigurationPage({super.key});

  @override
  State<LoggingConfigurationPage> createState() =>
      _LoggingConfigurationPageState();
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

class _LoggingConfigurationPageState extends State<LoggingConfigurationPage> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  String protocolSelected = 'MQTT';
  String loggingRetentionSelected =
      "1 Week"; // Variabel state baru untuk Retensi
  String loggingIntervalSelected =
      "5 Minutes"; // Variabel state baru untuk Interval

  @override
  Widget build(BuildContext context) {
    var items = [
      DropdownItem(label: 'Sensor', value: LoggingData(name: 'Sensor', id: 1)),
      DropdownItem(
          label: 'Tekanan', value: LoggingData(name: 'Tekanan', id: 6)),
      DropdownItem(label: 'Suhu', value: LoggingData(name: 'Suhu', id: 2)),
    ];

    return Scaffold(
      appBar: const CustomAppBar(title: 'Logging Configuration'),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Data Interval',
              style: FontFamily.headlineMedium,
            ),
            Form(
              key: _formKey, // Mengaitkan GlobalKey ke form
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.max,
                children: [
                  const SizedBox(height: 4),
                  MultiDropdown<LoggingData>(
                    items: items,
                    enabled: true,
                    // searchEnabled: true,
                    chipDecoration: ChipDecoration(
                      labelStyle:
                          FontFamily.labelText.copyWith(color: Colors.black),
                      backgroundColor: Colors.yellow,
                      wrap: true,
                      runSpacing: 2,
                      spacing: 10,
                    ),
                    fieldDecoration: FieldDecoration(
                      hintText: 'Choose Data Interval',
                      hintStyle: FontFamily.labelText,
                      showClearIcon: false,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                            color: AppColor.primaryColor, width: 2),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                            color: AppColor.primaryColor, width: 2),
                      ),
                    ),
                    dropdownItemDecoration: const DropdownItemDecoration(
                      textColor: AppColor.grey,
                      selectedTextColor: AppColor.primaryColor,
                      selectedIcon: Icon(Icons.check_box, color: Colors.green),
                      disabledIcon: Icon(Icons.lock, color: Colors.grey),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please select a daata interval';
                      }
                      return null;
                    },
                    onSelectionChange: (selectedItems) {
                      debugPrint("OnSelectionChange: $selectedItems");
                    },
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: MediaQuery.of(context).size.width,
                    child: const TitleTile(
                      title: 'Choose Protocol',
                    ),
                  ),
                  CustomRadioTile(
                    value: "MQTT",
                    grupValue: protocolSelected,
                    onChanges: () {
                      setState(() {
                        protocolSelected = "MQTT";
                      });
                    },
                  ),
                  CustomRadioTile(
                    value: "HTTP",
                    grupValue: protocolSelected,
                    onChanges: () {
                      setState(() {
                        protocolSelected = "HTTP";
                      });
                    },
                  ),
                  SizedBox(
                    width: MediaQuery.of(context).size.width,
                    child: const TitleTile(
                      title: 'Choose Logging Retention',
                    ),
                  ),
                  CustomRadioTile(
                    value: "1 Week",
                    grupValue: loggingRetentionSelected,
                    onChanges: () {
                      setState(() {
                        loggingRetentionSelected = "1 Week";
                      });
                    },
                  ),
                  CustomRadioTile(
                    value: "1 Month",
                    grupValue: loggingRetentionSelected,
                    onChanges: () {
                      setState(() {
                        loggingRetentionSelected = "1 Month";
                      });
                    },
                  ),
                  CustomRadioTile(
                    value: "3 Month",
                    grupValue: loggingRetentionSelected,
                    onChanges: () {
                      setState(() {
                        loggingRetentionSelected = "3 Month";
                      });
                    },
                  ),
                  SizedBox(
                    width: MediaQuery.of(context).size.width,
                    child: const TitleTile(
                      title: 'Choose Logging Interval',
                    ),
                  ),
                  CustomRadioTile(
                    value: "5 Minutes",
                    grupValue: loggingIntervalSelected,
                    onChanges: () {
                      setState(() {
                        loggingIntervalSelected = "5 Minutes";
                      });
                    },
                  ),
                  CustomRadioTile(
                    value: "10 Minutes",
                    grupValue: loggingIntervalSelected,
                    onChanges: () {
                      setState(() {
                        loggingIntervalSelected = "10 Minutes";
                      });
                    },
                  ),
                  CustomRadioTile(
                    value: "30 Minutes",
                    grupValue: loggingIntervalSelected,
                    onChanges: () {
                      setState(() {
                        loggingIntervalSelected = "30 Minutes";
                      });
                    },
                  ),
                  const Gap(170),
                  CustomButton(
                      titleButton: 'SAVE',
                      onPressed: () {
                        dialogSuccess(context);
                      })
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
