import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gateway_config/core/constants/theme.dart';
import 'package:gateway_config/core/controllers/ble_controller.dart';
import 'package:gateway_config/core/router/app_router.dart';
import 'package:gateway_config/core/utils/notification_helper.dart';
import 'package:gateway_config/presentation/providers/loading_provider.dart';
import 'package:gateway_config/presentation/widgets/common/loading_overlay.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize notification
  await NotificationHelper().initialize();

  // Set orientation potrait only
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]).then((_) {
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
      builder: (context, child) {
        return GlobalLoadingWrapper(
          child: MaterialApp.router(
            title: 'Gateway Config',
            theme: AppTheme.lightTheme,
            debugShowCheckedModeBanner: false,
            routerConfig: AppRouter.router,
          ),
        );
      },
    );
  }
}

/// Global Loading Wrapper that covers entire app including bottom navigation
/// This is a single setup that automatically applies to all screens
class GlobalLoadingWrapper extends StatelessWidget {
  final Widget child;

  const GlobalLoadingWrapper({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return GetBuilder<BleController>(
      init: Get.put(BleController(), permanent: true),
      builder: (controller) {
        return Directionality(
          textDirection: TextDirection.ltr,
          child: Stack(
            children: [
              child,
              Obx(() {
                return LoadingOverlay(
                  isLoading: controller.isLoadingConnectionGlobal.value,
                  message: controller.message.value.isNotEmpty
                      ? controller.message.value
                      : controller.errorMessage.value,
                );
                
              }),
            ],
          ),
        );
      },
    );
  }
}

