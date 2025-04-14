import 'package:flutter/material.dart';
import 'package:suriota_mobile_gateway/constant/app_color.dart';
import 'package:suriota_mobile_gateway/constant/app_gap.dart';
import 'package:suriota_mobile_gateway/constant/image_asset.dart';
import 'package:suriota_mobile_gateway/global/utils/text_extension.dart';
import 'package:suriota_mobile_gateway/screen/login/login_page.dart';
import 'package:suriota_mobile_gateway/screen/sidebar_menu/about_us_page.dart';
import 'package:suriota_mobile_gateway/screen/sidebar_menu/profile.dart';

class SideBarMenu extends StatelessWidget {
  const SideBarMenu({super.key});

  @override
  Widget build(BuildContext context) {
    double statusBarHeight = MediaQuery.of(context).padding.top;

    return Drawer(
      child: ListView(
        children: [
          SizedBox(
            height: statusBarHeight,
          ),
          const Center(
            child: CircleAvatar(
              radius: 50, backgroundImage: AssetImage(ImageAsset.profile2)),
          ),
          AppSpacing.md,
          Padding(
            padding: AppPadding.horizontalMedium,
            child: Text(
              'Fulan bin Fulan',
              style: context.h5,
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          AppSpacing.lg,
          Padding(
            padding: AppPadding.horizontalMedium,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ListTile(
                  title: Text('Home', style: context.body),
                  leading: const Icon(
                    Icons.home,
                    color: AppColor.primaryColor,
                    size: 22,
                  ),
                  onTap: () {
                    Navigator.pop(context);
                  },
                ),
                ListTile(
                  leading: const Icon(
                    Icons.person,
                    color: AppColor.primaryColor,
                    size: 22,
                  ),
                  title: Text('Profile', style: context.body),
                  onTap: () {
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => const ProfilePage()));
                  },
                ),
                ListTile(
                  leading: const Icon(
                    Icons.info_sharp,
                    color: AppColor.primaryColor,
                    size: 22,
                  ),
                  title: Text('About Us', style: context.body),
                  onTap: () {
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => const AboutUsPage()));
                  },
                ),
                ListTile(
                  leading: const Icon(
                    Icons.logout,
                    color: AppColor.redColor,
                    size: 22,
                  ),
                  title: Text('Logout',
                      style: context.body.copyWith(color: AppColor.redColor)),
                  onTap: () {
                    Navigator.of(context).pushAndRemoveUntil(
                        MaterialPageRoute(
                            builder: (context) => const LoginPage()),
                        (Route route) => false);
                  },
                ),
              ],
            ),
          ),
          AppSpacing.xl,
        ],
      ),
    );
  }
}
