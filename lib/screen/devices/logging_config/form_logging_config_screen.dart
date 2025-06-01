import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:suriota_mobile_gateway/constant/app_color.dart';
import 'package:suriota_mobile_gateway/constant/app_gap.dart';
import 'package:suriota_mobile_gateway/controller/ble_controller.dart';
import 'package:suriota_mobile_gateway/global/utils/helper.dart';
import 'package:suriota_mobile_gateway/global/utils/text_extension.dart';
import 'package:suriota_mobile_gateway/global/widgets/custom_alert_dialog.dart';
import 'package:suriota_mobile_gateway/global/widgets/custom_button.dart';
import 'package:suriota_mobile_gateway/global/widgets/custom_radiotile.dart';
import 'package:suriota_mobile_gateway/global/widgets/loading_overlay.dart';
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
  final BLEController bleController = Get.put(BLEController(), permanent: true);

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  bool isLoading = false;
  bool isInitialized = false;
  String errorMessage = '';

  String loggingRetentionSelected = "";
  String loggingIntervalSelected = "";

  @override
  void initState() {
    super.initState();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!isInitialized) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        fetchData();
        isInitialized = true;
      });
    }
  }

  Future<void> fetchData() async {
    setState(() {
      isLoading = true;
      errorMessage = '';
    });

    try {
      final data = await bleController.fetchData(
          "READ|logging_config", 'logging_config');

      setState(() {
        loggingRetentionSelected = data['retention'] ?? '';
        loggingIntervalSelected = data['interval'] ?? '';

        isLoading = false;
      });
    } catch (e) {
      setState(() {
        errorMessage = 'Failed to load config: $e';
        isLoading = false;
      });
    }
  }

  void _submit() {
    if (loggingIntervalSelected.isEmpty || loggingRetentionSelected.isEmpty) {
      Get.snackbar(
        '',
        'Please select both logging retention and interval',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppColor.redColor,
        colorText: AppColor.whiteColor,
        duration: const Duration(seconds: 3),
        margin: const EdgeInsets.all(16),
        titleText: const SizedBox(),
        padding: const EdgeInsets.fromLTRB(16.0, 8.0, 16.0, 16.0),
      );
      return;
    }

    // Periksa koneksi BLE
    if (bleController.isConnected.isEmpty ||
        !bleController.isConnected.values.any((connected) => connected)) {
      Get.snackbar('Error', 'No BLE device connected');
      return;
    }

    CustomAlertDialog.show(
      title: "Are you sure?",
      message: "Are you sure you want to save this logging config?",
      primaryButtonText: 'Yes',
      secondaryButtonText: 'No',
      onPrimaryPressed: () async {
        Get.back();
        await Future.delayed(const Duration(seconds: 1));

        try {
          final sendDataDelimiter =
              'UPDATE|logging_config|retention:$loggingRetentionSelected|interval:$loggingIntervalSelected';
          bleController.sendCommand(sendDataDelimiter, 'logging_config');
        } catch (e) {
          debugPrint('Error submitting form: $e');
          Get.snackbar('Error', 'Failed to submit form: $e');
        } finally {
          await Future.delayed(const Duration(seconds: 3));
          AppHelpers.backNTimes(1);
        }
      },
      barrierDismissible: false,
    );
  }

  @override
  void dispose() {
    isInitialized = false;
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
      title: Text('Form Logging Config',
          style: context.h5.copyWith(color: AppColor.whiteColor)),
      iconTheme: const IconThemeData(color: AppColor.whiteColor),
      backgroundColor: AppColor.primaryColor,
      centerTitle: true,
    );
  }

  SafeArea _body(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: AppPadding.horizontalMedium,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppSpacing.md,
            Form(
              key: _formKey, // Mengaitkan GlobalKey ke form
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.max,
                children: [
                  // Text(
                  //   'Data Interval',
                  //   style: context.h6,
                  // ),
                  // AppSpacing.sm,
                  // MultiDropdown<LoggingData>(
                  //   items: items,
                  //   enabled: true,
                  //   // searchEnabled: true,
                  //   chipDecoration: ChipDecoration(
                  //       labelStyle: context.buttonTextSmall
                  //           .copyWith(color: AppColor.whiteColor),
                  //       backgroundColor: AppColor.primaryColor,
                  //       padding: AppPadding.small,
                  //       wrap: true,
                  //       runSpacing: 10,
                  //       spacing: 5,
                  //       deleteIcon: const Icon(
                  //         Icons.cancel,
                  //         size: 17,
                  //         color: AppColor.whiteColor,
                  //       )),
                  //   fieldDecoration: FieldDecoration(
                  //     hintText: 'Choose Data Interval',
                  //     hintStyle: FontFamily.labelText,
                  //     showClearIcon: false,
                  //     border: OutlineInputBorder(
                  //       borderRadius: BorderRadius.circular(12),
                  //       borderSide: const BorderSide(
                  //           color: AppColor.primaryColor, width: 2),
                  //     ),
                  //     focusedBorder: OutlineInputBorder(
                  //       borderRadius: BorderRadius.circular(12),
                  //       borderSide: const BorderSide(
                  //           color: AppColor.primaryColor, width: 2),
                  //     ),
                  //   ),
                  //   dropdownItemDecoration: const DropdownItemDecoration(
                  //     textColor: AppColor.grey,
                  //     selectedTextColor: AppColor.primaryColor,
                  //     selectedIcon:
                  //         Icon(Icons.check_box, color: AppColor.primaryColor),
                  //     disabledIcon: Icon(Icons.lock, color: Colors.grey),
                  //   ),
                  //   validator: (value) {
                  //     if (value == null || value.isEmpty) {
                  //       return 'Please select a daata interval';
                  //     }
                  //     return null;
                  //   },
                  //   onSelectionChange: (selectedItems) {
                  //     debugPrint("OnSelectionChange: $selectedItems");
                  //   },
                  // ),
                  // AppSpacing.md,
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const TitleTile(
                          title:
                              'Choose Logging Retention (w: week, m: month)'),
                      AppSpacing.sm,
                      CustomRadioTile(
                        value: "1w",
                        grupValue: loggingRetentionSelected,
                        onChanges: () {
                          setState(() {
                            loggingRetentionSelected = "1w";
                          });
                        },
                      ),
                      CustomRadioTile(
                        value: "1m",
                        grupValue: loggingRetentionSelected,
                        onChanges: () {
                          setState(() {
                            loggingRetentionSelected = "1m";
                          });
                        },
                      ),
                      CustomRadioTile(
                        value: "3m",
                        grupValue: loggingRetentionSelected,
                        onChanges: () {
                          setState(() {
                            loggingRetentionSelected = "3m";
                          });
                        },
                      ),
                    ],
                  ),
                  AppSpacing.md,
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const TitleTile(
                          title: 'Choose Logging Interval (m: minute)'),
                      AppSpacing.sm,
                      CustomRadioTile(
                        value: "5m",
                        grupValue: loggingIntervalSelected,
                        onChanges: () {
                          setState(() {
                            loggingIntervalSelected = "5m";
                          });
                        },
                      ),
                      CustomRadioTile(
                        value: "10m",
                        grupValue: loggingIntervalSelected,
                        onChanges: () {
                          setState(() {
                            loggingIntervalSelected = "10m";
                          });
                        },
                      ),
                      CustomRadioTile(
                        value: "30m",
                        grupValue: loggingIntervalSelected,
                        onChanges: () {
                          setState(() {
                            loggingIntervalSelected = "30m";
                          });
                        },
                      ),
                    ],
                  ),
                  AppSpacing.lg,
                  Button(
                    width: MediaQuery.of(context).size.width,
                    onPressed: _submit,
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
    );
  }
}
