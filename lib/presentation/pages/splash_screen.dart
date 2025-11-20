// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gateway_config/core/constants/app_color.dart';
import 'package:gateway_config/core/constants/app_gap.dart';
import 'package:gateway_config/core/constants/app_image_assets.dart';
import 'package:gateway_config/core/services/bluetooth/bluetooth_permission_service.dart';
import 'package:gateway_config/core/utils/extensions.dart';
import 'package:go_router/go_router.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _handleStartup();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Precache logo image agar langsung muncul
    precacheImage(AssetImage(ImageAsset.logoSuriota), context);
  }

  Future<void> _handleStartup() async {
    await Future.delayed(const Duration(seconds: 3));
    if (!mounted) return;

    bool permissionGranted =
        await BluetoothPermissionService.checkAndRequestPermissions(context);

    if (mounted) {
      if (permissionGranted) {
        context.go('/');
      } else {
        context.go('/permission-denied');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColor.whiteColor,
      body: AnnotatedRegion<SystemUiOverlayStyle>(
        value: const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.dark,
          statusBarBrightness: Brightness.light,
          systemNavigationBarColor: Colors.white,
          systemNavigationBarIconBrightness: Brightness.dark,
        ),
        child: SafeArea(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Spacer(),
                // Logo
                Image.asset(
                  ImageAsset.logoSuriota,
                  width: 200,
                  height: 200,
                  fit: BoxFit.contain,
                  gaplessPlayback: true,
                  cacheWidth: 400, // Cache width untuk performa
                ),
                const Spacer(),
                // Loading indicator
                const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      AppColor.primaryColor,
                    ),
                  ),
                ),
                AppSpacing.xl,
                // Version
                Text(
                  'v1.0.0',
                  style: context.bodySmall.copyWith(
                    color: AppColor.grey.withValues(alpha: 0.6),
                  ),
                ),
                AppSpacing.lg,
              ],
            ),
          ),
        ),
      ),
    );
  }
}
