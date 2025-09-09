import 'package:flutter/material.dart';
import 'package:gateway_config/presentation/pages/devices/add_device_screen.dart';
import 'package:gateway_config/presentation/pages/home/home_screen.dart';
import 'package:gateway_config/presentation/pages/login/login_page.dart';
import 'package:gateway_config/presentation/pages/permission_denied.dart';
import 'package:gateway_config/presentation/pages/sidebar_menu/about_app.dart';
import 'package:gateway_config/presentation/pages/sidebar_menu/about_us_page.dart';
import 'package:gateway_config/presentation/pages/sidebar_menu/profile.dart';
import 'package:gateway_config/presentation/pages/splash_screen.dart';
import 'package:get/route_manager.dart';
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
        path: '/scan-devices',
        name: 'scan-devices',
        builder: (context, state) => const AddDeviceScreen(),
      ),

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
}
