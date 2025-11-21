import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gateway_config/core/constants/app_color.dart';
import 'package:gateway_config/core/constants/app_gap.dart';
import 'package:gateway_config/core/utils/extensions.dart';
import 'package:gateway_config/models/device_model.dart';
import 'package:gateway_config/presentation/widgets/common/custom_alert_dialog.dart';
import 'package:gateway_config/presentation/widgets/common/menu_section.dart';

class SettingsDeviceScreen extends StatelessWidget {
  final DeviceModel model;

  const SettingsDeviceScreen({super.key, required this.model});

  void _showComingSoonDialog(BuildContext context) {
    CustomAlertDialog.show(
      title: 'Coming Soon',
      message: 'This feature is coming soon',
      primaryButtonText: 'OK',
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
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
                      onTap: () => _showComingSoonDialog(context),
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
    );
  }
}
