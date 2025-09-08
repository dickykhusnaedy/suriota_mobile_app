// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
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
      body: Stack(
        children: [
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Expanded(
                  flex: 1,
                  child: Image.asset(
                    ImageAsset.logoSuriota, // Ganti dengan path logo Anda
                    width: 200,
                    height: 200,
                  ),
                ),
                Text("v1.0.0", style: context.bodySmall),
                AppSpacing.lg,
              ],
            ),
          ),
        ],
      ),
    );
  }
}
