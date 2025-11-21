import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gateway_config/core/constants/app_color.dart';
import 'package:gateway_config/core/constants/app_gap.dart';
import 'package:gateway_config/core/utils/app_helpers.dart';
import 'package:gateway_config/core/utils/extensions.dart';
import 'package:gateway_config/presentation/widgets/common/menu_section.dart';
import 'package:go_router/go_router.dart';

class SettingsScreen extends StatelessWidget {
  final bool showBottomNav;

  const SettingsScreen({super.key, this.showBottomNav = false});

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        statusBarColor: showBottomNav
            ? Colors.transparent
            : AppColor.primaryColor,
        statusBarIconBrightness: showBottomNav
            ? Brightness.dark
            : Brightness.light,
        statusBarBrightness: showBottomNav ? Brightness.light : Brightness.dark,
        systemNavigationBarColor: AppColor.whiteColor,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: AppColor.backgroundColor,
        appBar: showBottomNav
            ? null
            : AppBar(
                backgroundColor: AppColor.primaryColor,
                iconTheme: const IconThemeData(color: AppColor.whiteColor),
                centerTitle: true,
                title: Text(
                  'Settings',
                  style: context.h5.copyWith(color: AppColor.whiteColor),
                ),
              ),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: AppPadding.screenPadding,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (showBottomNav) ...[
                  AppSpacing.sm,
                  Text(
                    'Settings',
                    style: context.h2.copyWith(
                      color: AppColor.blackColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  AppSpacing.sm,
                  Text(
                    'Manage your account and app preferences',
                    style: context.bodySmall.copyWith(color: AppColor.grey),
                  ),
                ],
                AppSpacing.lg,
                MenuSection(
                  title: 'Account',
                  items: [
                    MenuItem(
                      icon: Icons.person_outline,
                      title: 'Profile',
                      onTap: () => context.pushNamed('profiles'),
                    ),
                  ],
                ),
                AppSpacing.lg,
                MenuSection(
                  title: 'About',
                  items: [
                    MenuItem(
                      icon: Icons.info_outline,
                      title: 'About Product',
                      onTap: () => context.pushNamed('about-product'),
                    ),
                    MenuItem(
                      icon: Icons.info_outline,
                      title: 'About App',
                      onTap: () => context.pushNamed('about-app'),
                    ),
                  ],
                ),
                AppSpacing.lg,
                MenuSection(

                  
                  title: 'Other',
                  items: [
                    MenuItem(
                      icon: Icons.chat_bubble_outline,
                      title: 'Contact Us',
                      onTap: () {
                        final Uri whatsappUrl = Uri.parse(
                          'https://wa.me/6285835672476?text=Hello, I need assistance with the app',
                        );
                        AppHelpers.launchInBrowser(whatsappUrl);
                      },
                    ),
                    MenuItem(
                      icon: Icons.logout,
                      title: 'Logout',
                      iconColor: AppColor.redColor,
                      titleColor: AppColor.redColor,
                      onTap: () {
                        // TODO: Implement logout
                      },
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
