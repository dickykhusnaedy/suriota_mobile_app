import 'package:flutter/material.dart';
import 'package:gateway_config/core/constants/app_color.dart';
import 'package:gateway_config/core/controllers/ble_controller.dart';
import 'package:gateway_config/core/utils/extensions.dart';
import 'package:gateway_config/presentation/pages/devices/add_device_screen.dart';
import 'package:gateway_config/presentation/pages/devices/detail_device_screen.dart';
import 'package:gateway_config/presentation/pages/home/home_screen.dart';
import 'package:gateway_config/presentation/pages/login/login_page.dart';
import 'package:gateway_config/presentation/pages/permission_denied.dart';
import 'package:gateway_config/presentation/pages/sidebar_menu/about_app.dart';
import 'package:gateway_config/presentation/pages/sidebar_menu/about_us_page.dart';
import 'package:gateway_config/presentation/pages/sidebar_menu/profile.dart';
import 'package:gateway_config/presentation/pages/splash_screen.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';

class AppRouter {
  static final GoRouter router = GoRouter(
    navigatorKey: Get.key,
    debugLogDiagnostics: true,
    initialLocation: '/splash',
    errorBuilder: (context, state) =>
        Scaffold(body: Center(child: Text(state.error.toString()))),
    routes: [
      // Authentication routes
      GoRoute(
        path: '/login',
        name: 'login',
        builder: (context, state) => const LoginPage(),
      ),

      // Homepage route
      GoRoute(
        path: '/',
        name: 'home',
        builder: (context, state) => const HomeScreen(),
      ),

      // Sidebar menu routes
      GoRoute(
        path: '/profiles',
        name: 'profiles',
        builder: (context, state) => const ProfilePage(),
      ),

      GoRoute(
        path: '/about-product',
        name: 'about-product',
        builder: (context, state) => const AboutUsPage(),
      ),

      GoRoute(
        path: '/about-app',
        name: 'about-app',
        builder: (context, state) => const AboutApp(),
      ),

      GoRoute(
        path: '/devices',
        name: 'devices',
        builder: (BuildContext context, GoRouterState state) {
          final deviceId = state.uri.queryParameters['deviceId'];
          final BleController bleController = Get.find<BleController>();

          if (deviceId == null) {
            return _deviceNotFound(context);
          }

          final model = bleController.findDeviceByRemoteId(deviceId);

          if (model == null) {
            return _deviceNotFound(context);
          }

          return DetailDeviceScreen(device: model.device);
        },
        routes: [
          GoRoute(
            path: '/add',
            name: 'add-device',
            builder: (context, state) => const AddDeviceScreen(),
          ),
        ],
        // builder: (context, state) => const AddDeviceScreen(),
      ),

      // GoRoute(path: '/device', name: 'device', builder: (context, state) => const Dei)
      GoRoute(
        path: '/permission-denied',
        name: 'permission-denied',
        builder: (context, state) => const PermissionDenied(),
      ),

      // Splash/Loading Route
      GoRoute(
        path: '/splash',
        name: 'splash',
        builder: (context, state) => SplashScreen(),
      ),
    ],
  );

  static Scaffold _deviceNotFound(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Detail Device',
          style: context.h5.copyWith(color: AppColor.whiteColor),
        ),
        backgroundColor: AppColor.primaryColor,
        iconTheme: const IconThemeData(color: AppColor.whiteColor),
        centerTitle: true,
      ),
      body: const Center(
        child: Text('Device not found. Please connect the device first.'),
      ),
    );
  }
}
