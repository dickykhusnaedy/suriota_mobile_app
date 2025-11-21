import 'package:flutter/material.dart';
import 'package:gateway_config/core/constants/app_color.dart';
import 'package:gateway_config/core/constants/app_font.dart';
import 'package:gateway_config/presentation/pages/settings/about_us_page.dart';
import 'package:gateway_config/presentation/pages/home/home_screen.dart';
import 'package:gateway_config/presentation/pages/login/login_page.dart';
import '../../core/constants/app_image_assets.dart';
import 'settings/profile.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key, required this.title});

  final String title;

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int bottomSelectedIndex = 0;

  void onItemTapped(int index) {
    setState(() {
      bottomSelectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColor.backgroundColor,
      endDrawer: Drawer(
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Center(
                child: CircleAvatar(
                  radius: 100,
                  backgroundImage: AssetImage(ImageAsset.profile2),
                ),
              ),
              const SizedBox(height: 10),
              Center(
                child: Text(
                  'Fulan bin Fulan',
                  style: FontFamily.headlineLarge.copyWith(
                    color: AppColor.blackColor,
                  ),
                ),
              ),
              const SizedBox(height: 100),
              ListTile(
                selected: bottomSelectedIndex == 0,
                leading: const Icon(Icons.home, color: AppColor.primaryColor),
                title: Text('Home', style: FontFamily.normal),
                onTap: () {
                  onItemTapped(0);
                  Navigator.pop(context); // Menutup drawer setelah tap
                },
              ),
              ListTile(
                selected: bottomSelectedIndex == 1,
                leading: const Icon(Icons.person, color: AppColor.primaryColor),
                title: Text('Profile', style: FontFamily.normal),
                onTap: () {
                  onItemTapped(1);
                  Navigator.pop(context); // Menutup drawer setelah tap
                },
              ),
              ListTile(
                selected: bottomSelectedIndex == 2,
                leading: const Icon(Icons.info, color: AppColor.primaryColor),
                title: Text('About Product', style: FontFamily.normal),
                onTap: () {
                  onItemTapped(2);
                  Navigator.pop(context); // Menutup drawer setelah tap
                },
              ),
              ListTile(
                leading: const Icon(Icons.logout, color: AppColor.primaryColor),
                title: Text('Log Out', style: FontFamily.normal),
                onTap: () {
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (context) => const LoginPage()),
                    (Route<dynamic> route) => false,
                  );
                },
              ),
            ],
          ),
        ),
      ),
      body: IndexedStack(
        index: bottomSelectedIndex,
        children: const [HomeScreen(), ProfilePage(), AboutUsPage()],
      ),
    );
  }
}
