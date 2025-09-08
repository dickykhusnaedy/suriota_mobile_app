import 'package:flutter/material.dart';
import 'package:gateway_config/core/constants/app_color.dart';
import 'package:gateway_config/core/constants/app_font.dart';
import 'package:gateway_config/core/constants/app_gap.dart';
import 'package:gateway_config/core/constants/app_image_assets.dart';
import 'package:gateway_config/core/utils/extensions.dart';
import 'package:go_router/go_router.dart';

class SideBarMenu extends StatelessWidget {
  const SideBarMenu({super.key});

  @override
  Widget build(BuildContext context) {
    double statusBarHeight = MediaQuery.of(context).padding.top;

    return Drawer(
      child: ListView(
        children: [
          SizedBox(height: statusBarHeight),
          const Center(
            child: CircleAvatar(
              radius: 50,
              backgroundImage: AssetImage(ImageAsset.profile2),
            ),
          ),
          AppSpacing.md,
          Padding(
            padding: AppPadding.horizontalMedium,
            child: Text(
              'Fulan bin Fulan',
              style: context.h4.copyWith(color: AppColor.blackColor),
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          AppSpacing.md,
          Column(
            children: [
              ListTile(
                title: Text(
                  'Home',
                  style: context.body.copyWith(color: AppColor.blackColor),
                ),
                trailing: const Icon(
                  Icons.chevron_right,
                  size: 22,
                  color: AppColor.blackColor,
                ),
                onTap: () {
                  Navigator.pop(context);
                },
              ),
              Divider(height: 0, color: Colors.grey[300]),
              ListTile(
                title: Text(
                  'Profile',
                  style: context.body.copyWith(color: AppColor.blackColor),
                ),
                trailing: const Icon(
                  Icons.chevron_right,
                  size: 22,
                  color: AppColor.blackColor,
                ),
                onTap: () async {
                  context.push('/profiles');
                },
              ),
              Divider(height: 0, color: Colors.grey[300]),
              ListTile(
                title: Text(
                  'About Product',
                  style: context.body.copyWith(color: AppColor.blackColor),
                ),
                trailing: const Icon(
                  Icons.chevron_right,
                  size: 22,
                  color: AppColor.blackColor,
                ),
                onTap: () {
                  context.push('/about-product');
                },
              ),
              Divider(height: 0, color: Colors.grey[300]),
              ListTile(
                title: Text(
                  'About App',
                  style: context.body.copyWith(color: AppColor.blackColor),
                ),
                trailing: const Icon(
                  Icons.chevron_right,
                  size: 22,
                  color: AppColor.blackColor,
                ),
                onTap: () {
                  context.push('/about-app');
                },
              ),
              Divider(height: 0, color: Colors.grey[300]),
              ListTile(
                leading: const Icon(
                  Icons.logout,
                  color: AppColor.redColor,
                  size: 22,
                ),
                title: Text(
                  'Logout',
                  style: context.body.copyWith(
                    color: AppColor.redColor,
                    fontWeight: FontWeightTheme.extraBold,
                  ),
                ),
                onTap: () async {
                  context.go('/login');
                },
              ),
            ],
          ),
          AppSpacing.xl,
        ],
      ),
    );
  }
}
