import 'package:flutter/material.dart';
import 'package:gateway_config/core/constants/app_color.dart';
import 'package:gateway_config/core/constants/app_gap.dart';
import 'package:gateway_config/core/controllers/ble_controller.dart';
import 'package:gateway_config/core/controllers/logging_controller.dart';
import 'package:gateway_config/core/utils/app_helpers.dart';
import 'package:gateway_config/core/utils/extensions.dart';
import 'package:gateway_config/core/utils/snackbar_custom.dart';
import 'package:gateway_config/models/device_model.dart';
import 'package:gateway_config/presentation/widgets/common/custom_alert_dialog.dart';
import 'package:gateway_config/presentation/widgets/common/loading_overlay.dart';
import 'package:gateway_config/presentation/widgets/common/reusable_widgets.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';

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
  final BleController bleController = Get.find<BleController>();
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
    _worker = ever(controller.dataLogging, (dataList) {
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
        controller.isFetching.value = true;

        var formData = {
          "logging_ret": loggingRetentionSelected,
          "logging_interval": loggingIntervalSelected,
        };

        try {
          await controller.updateData(widget.model, formData);

          SnackbarCustom.showSnackbar(
            '',
            'Configuration updated, disconnecting in 3 seconds...',
            Colors.green,
            AppColor.whiteColor,
          );
          
          await Future.delayed(const Duration(seconds: 3));

          try {
            await bleController.disconnectFromDevice(widget.model);

            controller.dataLogging.clear();
          } catch (e) {
            AppHelpers.debugLog('Error disconnecting: $e');
            SnackbarCustom.showSnackbar(
              '',
              'Failed to disconnect',
              AppColor.redColor,
              AppColor.whiteColor,
            );
          }

          if (Get.context != null) {
            GoRouter.of(Get.context!).go('/');
          } else {
            AppHelpers.debugLog(
              'Warning: Get.context is null, cannot navigate',
            );
          }
        } catch (e) {
          SnackbarCustom.showSnackbar(
            '',
            'Failed to submit form',
            AppColor.redColor,
            AppColor.whiteColor,
          );
          AppHelpers.debugLog('Error submitting form: $e');
        } finally {
          controller.isFetching.value = false;
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
                  SectionDivider(
                    title: 'Logging Retention',
                    icon: Icons.storage,
                  ),
                  AppSpacing.xs,
                  Text(
                    'w: week, m: month',
                    style: context.bodySmall.copyWith(color: AppColor.grey),
                  ),
                  AppSpacing.sm,
                  SelectionCard<String>(
                    items: const [
                      SelectionCardItem(
                        value: '1w',
                        title: '1 Week',
                        subtitle: 'Keep logs for 1 week',
                        icon: Icons.calendar_today,
                      ),
                      SelectionCardItem(
                        value: '1m',
                        title: '1 Month',
                        subtitle: 'Keep logs for 1 month',
                        icon: Icons.calendar_month,
                      ),
                      SelectionCardItem(
                        value: '3m',
                        title: '3 Months',
                        subtitle: 'Keep logs for 3 months',
                        icon: Icons.date_range,
                      ),
                    ],
                    selectedValue: loggingRetentionSelected.isEmpty
                        ? null
                        : loggingRetentionSelected,
                    onChanged: (value) {
                      setState(() {
                        loggingRetentionSelected = value;
                      });
                    },
                  ),
                  AppSpacing.md,
                  SectionDivider(
                    title: 'Logging Interval',
                    icon: Icons.timer,
                  ),
                  AppSpacing.xs,
                  Text(
                    'm: minute',
                    style: context.bodySmall.copyWith(color: AppColor.grey),
                  ),
                  AppSpacing.sm,
                  SelectionCard<String>(
                    items: const [
                      SelectionCardItem(
                        value: '5m',
                        title: '5 Minutes',
                        subtitle: 'Log every 5 minutes',
                        icon: Icons.access_time,
                      ),
                      SelectionCardItem(
                        value: '10m',
                        title: '10 Minutes',
                        subtitle: 'Log every 10 minutes',
                        icon: Icons.schedule,
                      ),
                      SelectionCardItem(
                        value: '30m',
                        title: '30 Minutes',
                        subtitle: 'Log every 30 minutes',
                        icon: Icons.av_timer,
                      ),
                    ],
                    selectedValue: loggingIntervalSelected.isEmpty
                        ? null
                        : loggingIntervalSelected,
                    onChanged: (value) {
                      setState(() {
                        loggingIntervalSelected = value;
                      });
                    },
                  ),
                  AppSpacing.lg,
                  GradientButton(
                    text: 'Update Logging Configuration',
                    icon: Icons.update,
                    onPressed: _submit,
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
