import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gateway_config/core/constants/app_color.dart';
import 'package:gateway_config/core/constants/app_gap.dart';
import 'package:gateway_config/core/utils/extensions.dart';
import 'package:gateway_config/core/utils/snackbar_custom.dart';
import 'package:gateway_config/models/device_model.dart';
import 'package:gateway_config/presentation/widgets/common/custom_alert_dialog.dart';
import 'package:gateway_config/presentation/widgets/common/menu_section.dart';
import 'package:gateway_config/presentation/widgets/common/loading_overlay.dart';
import 'package:gateway_config/core/controllers/ble_controller.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';

class SettingsDeviceScreen extends StatefulWidget {
  final DeviceModel model;

  const SettingsDeviceScreen({super.key, required this.model});

  @override
  State<SettingsDeviceScreen> createState() => _SettingsDeviceScreenState();
}

class _SettingsDeviceScreenState extends State<SettingsDeviceScreen> {
  final bleController = Get.find<BleController>();
  bool isLoading = false;

  void _showComingSoonDialog(BuildContext context) {
    CustomAlertDialog.show(
      title: 'Coming Soon',
      message: 'This feature is coming soon',
      primaryButtonText: 'OK',
    );
  }

  Future<void> clearAllConfiguration(BuildContext context) async {
    CustomAlertDialog.show(
      title: 'Clear All Configuration',
      message:
          'All configurations that have been created will be permanently deleted. Are you sure you want to delete everything?',
      primaryButtonText: 'Yes',
      secondaryButtonText: 'No',
      barrierDismissible: false,
      onPrimaryPressed: () async {
        Get.back(); // Close dialog

        setState(() {
          isLoading = true;
        });

        try {
          // Send factory reset command
          final response = await bleController.sendCommand({
            "op": "system",
            "type": "factory_reset",
            "reason": "Clear all configuration via mobile app",
          });

          if (response.status == 'ok' || response.status == 'success') {
            // Wait 3 seconds before showing success snackbar
            await Future.delayed(const Duration(seconds: 3));

            setState(() {
              isLoading = false;
            });

            // Show success snackbar
            SnackbarCustom.showSnackbar(
              '',
              'All configurations have been cleared successfully. The device will restart.',
              Colors.green,
              AppColor.whiteColor,
            );

            // Wait 3 seconds after snackbar before navigating to home
            await Future.delayed(const Duration(seconds: 3));

            // Navigate to home
            if (mounted) {
              if (context.mounted) {
                GoRouter.of(context).go('/');
              } else {
                Get.offAllNamed('/');
              }
            }
          } else {
            setState(() {
              isLoading = false;
            });

            // Show error snackbar
            SnackbarCustom.showSnackbar(
              '',
              response.message ?? 'Failed to clear configuration',
              AppColor.redColor,
              AppColor.whiteColor,
            );
          }
        } catch (e) {
          setState(() {
            isLoading = false;
          });

          // Show error snackbar
          SnackbarCustom.showSnackbar(
            '',
            'Failed to clear configuration: $e',
            AppColor.redColor,
            AppColor.whiteColor,
          );
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        AnnotatedRegion<SystemUiOverlayStyle>(
          value: const SystemUiOverlayStyle(
            statusBarColor: AppColor.primaryColor,
            statusBarIconBrightness: Brightness.light,
            statusBarBrightness: Brightness.dark,
            systemNavigationBarColor: AppColor.whiteColor,
            systemNavigationBarIconBrightness: Brightness.dark,
          ),
          child: Scaffold(
            backgroundColor: AppColor.backgroundColor,
            appBar: AppBar(
              backgroundColor: AppColor.primaryColor,
              iconTheme: const IconThemeData(color: AppColor.whiteColor),
              centerTitle: true,
              title: Text(
                'Device Settings',
                style: context.h5.copyWith(color: AppColor.whiteColor),
              ),
            ),
            body: SafeArea(
              child: SingleChildScrollView(
                padding: AppPadding.screenPadding,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AppSpacing.sm,
                    MenuSection(
                      items: [
                        MenuItem(
                          icon: Icons.upload_file_outlined,
                          title: 'Import Config',
                          onTap: () => _showComingSoonDialog(context),
                        ),
                        MenuItem(
                          icon: Icons.download_outlined,
                          title: 'Download All Config',
                          onTap: () => _showComingSoonDialog(context),
                        ),
                        MenuItem(
                          icon: Icons.delete_sweep_outlined,
                          title: 'Clear Configuration',
                          onTap: () => clearAllConfiguration(context),
                          iconColor: AppColor.redColor,
                          titleColor: AppColor.redColor,
                        ),
                      ],
                    ),
                    AppSpacing.xl,
                  ],
                ),
              ),
            ),
          ),
        ),
        LoadingOverlay(
          isLoading: isLoading,
          message: 'Clearing all configurations...',
        ),
      ],
    );
  }
}
