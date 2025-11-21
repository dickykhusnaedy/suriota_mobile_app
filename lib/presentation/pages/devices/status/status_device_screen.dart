import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gateway_config/core/constants/app_color.dart';
import 'package:gateway_config/core/constants/app_gap.dart';
import 'package:gateway_config/core/utils/extensions.dart';
import 'package:gateway_config/models/device_model.dart';
import 'package:gateway_config/presentation/widgets/common/custom_alert_dialog.dart';
import 'package:gateway_config/presentation/widgets/common/menu_section.dart';

class StatusDeviceScreen extends StatelessWidget {
  final DeviceModel model;

  const StatusDeviceScreen({super.key, required this.model});

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
            'Device Status',
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
                      icon: Icons.memory_outlined,
                      title: 'Firmware',
                      onTap: () => _showComingSoonDialog(context),
                      trailing: Text(
                        'v1.0.0',
                        style: context.body.copyWith(
                          color: AppColor.grey,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    MenuItem(
                      icon: Icons.sd_card_outlined,
                      title: 'SD Card Info',
                      onTap: () => _showComingSoonDialog(context),
                    ),
                    MenuItem(
                      icon: Icons.system_update_outlined,
                      title: 'Update Firmware',
                      onTap: () => _showComingSoonDialog(context),
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
