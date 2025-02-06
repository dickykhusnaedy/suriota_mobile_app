import 'package:flutter/material.dart';
import 'package:suriota_mobile_gateway/constant/app_color.dart';
import 'package:suriota_mobile_gateway/constant/font_setup.dart';
import 'package:suriota_mobile_gateway/constant/image_asset.dart';
import 'package:suriota_mobile_gateway/view/sidebar_menu/about_us_page.dart';
import 'package:suriota_mobile_gateway/view/login/login_page.dart';
import 'package:suriota_mobile_gateway/view/sidebar_menu/profile.dart';

class SideBarMenu extends StatelessWidget {
  const SideBarMenu({super.key});

  @override
  Widget build(BuildContext context) {
    double statusBarHeight = MediaQuery.of(context).padding.top;

    return Drawer(
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: ListView(
          children: [
            SizedBox(
              height: statusBarHeight,
            ),
            const Center(
              child: CircleAvatar(
                  radius: 70, backgroundImage: AssetImage(ImageAsset.profile2)),
            ),
            const SizedBox(height: 10),
            Center(
              child: Text('Rudi Soru', style: FontFamily.headlineLarge),
            ),
            const SizedBox(height: 20),
            ListTile(
              leading: const SizedBox(
                width: 30,
                height: 30,
                child: Icon(Icons.home, color: AppColor.primaryColor),
              ),
              title: Text('Home', style: FontFamily.normal),
              onTap: () {
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const SizedBox(
                width: 30,
                height: 30,
                child: Icon(Icons.person, color: AppColor.primaryColor),
              ),
              title: Text('Profile', style: FontFamily.normal),
              onTap: () {
                Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const ProfilePage()));
              },
            ),
            ListTile(
              leading: const SizedBox(
                width: 30,
                height: 30,
                child: Icon(Icons.info, color: AppColor.primaryColor),
              ),
              title: Text('About Us', style: FontFamily.normal),
              onTap: () {
                Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const AboutUsPage()));
              },
            ),
            ListTile(
              leading: const SizedBox(
                width: 30,
                height: 30,
                child: Icon(Icons.logout, color: AppColor.redColor),
              ),
              title: Text('Log Out',
                  style: FontFamily.normal.copyWith(color: AppColor.redColor)),
              onTap: () {
                Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (context) => const LoginPage()),
                    (Route route) => false);
              },
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }
}
