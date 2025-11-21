import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gateway_config/core/constants/app_color.dart';
import 'package:gateway_config/core/constants/app_gap.dart';
import 'package:gateway_config/core/utils/extensions.dart';
import 'package:gateway_config/presentation/widgets/common/custom_alert_dialog.dart';
import 'package:gateway_config/presentation/widgets/common/menu_section.dart';
import 'package:go_router/go_router.dart';

class AboutAppScreen extends StatelessWidget {
  const AboutAppScreen({super.key});

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
            'About App',
            style: context.h5.copyWith(color: AppColor.whiteColor),
          ),
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: AppPadding.screenPadding,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppSpacing.md,
                MenuSection(
                  title: 'App Information',
                  items: [
                    MenuItem(
                      icon: Icons.info_outline,
                      title: 'App Version',
                      onTap: () {},
                      trailing: Text(
                        'v1.0.0',
                        style: context.body.copyWith(
                          color: AppColor.grey,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    MenuItem(
                      icon: Icons.person_outline,
                      title: 'Author',
                      onTap: () => context.pushNamed('author-screen'),
                    ),
                    MenuItem(
                      icon: Icons.menu_book_outlined,
                      title: 'User Guide',
                      onTap: () => _showComingSoonDialog(context),
                    ),
                    MenuItem(
                      icon: Icons.description_outlined,
                      title: 'License',
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
