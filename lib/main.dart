import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:suriota_mobile_gateway/view/home/home_page.dart';

Future<void> main() async {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      designSize: const Size(390, 844), // Design size in Figma
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (context, child) => MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          textTheme: Typography.englishLike2018.apply(fontSizeFactor: 1.sp),
          useMaterial3: true,
        ),
        title: 'Suriota Mobile Gateway',
        home: const HomePage(),
        // home: const LoginPage(),
      ),
    );
  }
}
