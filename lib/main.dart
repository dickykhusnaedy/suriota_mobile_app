import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get_storage/get_storage.dart';
import 'package:suriota_mobile_gateway/constant/theme.dart';
import 'package:suriota_mobile_gateway/view/home/home_page.dart';
import 'package:suriota_mobile_gateway/view/login/login_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await GetStorage.init(); // Inisialisasi GetStorage
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      designSize: const Size(375, 812),
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (context, child) => MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Suriota Mobile Gateway',
        theme: themeData(),
        home: const HomePage(),
        // home: const LoginPage(),
      ),
    );
  }
}
