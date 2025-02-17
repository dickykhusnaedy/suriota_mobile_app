import 'package:flutter/material.dart';
import 'package:multi_dropdown/multi_dropdown.dart';
import 'package:suriota_mobile_gateway/constant/app_color.dart';
import 'package:suriota_mobile_gateway/constant/app_gap.dart';
import 'package:suriota_mobile_gateway/constant/font_setup.dart';
import 'package:suriota_mobile_gateway/constant/theme.dart';
import 'package:suriota_mobile_gateway/global/utils/text_extension.dart';
import 'package:suriota_mobile_gateway/global/widgets/custom_button.dart';
import 'package:suriota_mobile_gateway/global/widgets/custom_radiotile.dart';
import 'package:suriota_mobile_gateway/global/widgets/title_tile.dart';

class FormLoggingConfigScreen extends StatefulWidget {
  const FormLoggingConfigScreen({super.key});

  @override
  State<FormLoggingConfigScreen> createState() =>
      _FormLoggingConfigScreenState();
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

class _FormLoggingConfigScreenState extends State<FormLoggingConfigScreen> {
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
      appBar: _appBar(context),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: AppPadding.horizontalMedium,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppSpacing.md,
              Text(
                'Data Interval',
                style: context.h6,
              ),
              Form(
                key: _formKey, // Mengaitkan GlobalKey ke form
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.max,
                  children: [
                    AppSpacing.sm,
                    MultiDropdown<LoggingData>(
                      items: items,
                      enabled: true,
                      // searchEnabled: true,
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
                        selectedIcon:
                            Icon(Icons.check_box, color: AppColor.primaryColor),
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
                    AppSpacing.md,
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const TitleTile(title: 'Choose Protocol'),
                        AppSpacing.sm,
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
                      ],
                    ),
                    AppSpacing.md,
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const TitleTile(title: 'Choose Logging Retention'),
                        AppSpacing.sm,
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
                      ],
                    ),
                    AppSpacing.md,
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const TitleTile(title: 'Choose Logging Interval'),
                        AppSpacing.sm,
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
                      ],
                    ),
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
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  AppBar _appBar(BuildContext context) {
    return AppBar(
      title: Text('Form Logging Config',
          style: context.h5.copyWith(color: AppColor.whiteColor)),
      iconTheme: const IconThemeData(color: AppColor.whiteColor),
      backgroundColor: AppColor.primaryColor,
      centerTitle: true,
    );
  }
}
