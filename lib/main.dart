import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';
import 'package:suriota_mobile_gateway/constant/theme.dart';
import 'package:suriota_mobile_gateway/global/widgets/loading_overlay.dart';
import 'package:suriota_mobile_gateway/provider/LoadingProvider.dart';
import 'package:suriota_mobile_gateway/screen/splash_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Set orientation potrait only
  SystemChrome.setPreferredOrientations(
      [DeviceOrientation.portraitUp, DeviceOrientation.portraitDown]).then((_) {
    runApp(
      ChangeNotifierProvider(
        create: (_) => LoadingProvider(),
        child: const MyApp(),
      ),
    );
  });
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      designSize: const Size(360, 690),
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (context, child) => GetMaterialApp(
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        title: 'Suriota Mobile Gateway',
        home: const SplashScreen(),
        // home: const LoginPage(),
      ),
    );
  }
}
