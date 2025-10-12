import 'package:flutter/material.dart';
import 'package:gateway_config/core/constants/app_color.dart';
import 'package:gateway_config/core/constants/app_gap.dart';
import 'package:gateway_config/core/controllers/logging_controller.dart';
import 'package:gateway_config/core/utils/app_helpers.dart';
import 'package:gateway_config/core/utils/extensions.dart';
import 'package:gateway_config/core/utils/snackbar_custom.dart';
import 'package:gateway_config/models/device_model.dart';
import 'package:gateway_config/presentation/widgets/common/custom_alert_dialog.dart';
import 'package:gateway_config/presentation/widgets/common/custom_button.dart';
import 'package:gateway_config/presentation/widgets/common/custom_radiotile.dart';
import 'package:gateway_config/presentation/widgets/common/loading_overlay.dart';
import 'package:gateway_config/presentation/widgets/spesific/title_tile.dart';
import 'package:get/get.dart';

class FormLoggingConfigScreen extends StatefulWidget {
  const FormLoggingConfigScreen({super.key, required this.model});
  final DeviceModel model;

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
  final LoggingController controller = Get.put(LoggingController());

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  bool isLoading = false;
  bool isInitialized = false;
  String errorMessage = '';

  late Worker _worker;

  String loggingRetentionSelected = "";
  String loggingIntervalSelected = "";

  @override
  void initState() {
    super.initState();
    // Listen to dataDevice GetX observable, update form when fetch finished
    _worker = ever(controller.dataServer, (dataList) {
      if (!mounted) return;
      if (dataList.isNotEmpty) {
        updateFormFields(dataList[0]);
      }
    });

    // Fetch data after widget build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      controller.fetchData(widget.model);
    });
  }

  void updateFormFields(Map<String, dynamic> config) {
    loggingRetentionSelected = config['logging_ret'] ?? '';
    loggingIntervalSelected = config['logging_interval'] ?? '';

    // Refresh UI
    setState(() {});
  }

  void _submit() {
    if (loggingIntervalSelected.isEmpty || loggingRetentionSelected.isEmpty) {
      SnackbarCustom.showSnackbar(
        '',
        'Please select both logging retention and interval',
        AppColor.redColor,
        AppColor.whiteColor,
      );
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

        var formData = {
          "logging_ret": loggingRetentionSelected,
          "logging_interval": loggingIntervalSelected,
        };

        try {
          controller.updateData(widget.model, formData);
        } catch (e) {
          SnackbarCustom.showSnackbar(
            '',
            'Failed to submit form',
            AppColor.redColor,
            AppColor.whiteColor,
          );
          AppHelpers.debugLog('Error submitting form: $e');
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
    _worker.dispose();
    isInitialized = false;

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Scaffold(appBar: _appBar(context), body: _body(context)),
        Obx(() {
          final isAnyDeviceLoading = controller.isFetching.value;
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
        'Form Logging Config',
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
                  // AppSpacing.md,
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const TitleTile(
                        title: 'Choose Logging Retention (w: week, m: month)',
                      ),
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
                        title: 'Choose Logging Interval (m: minute)',
                      ),
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
                    text: 'Update Data',
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
