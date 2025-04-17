// ignore_for_file: use_build_context_synchronously

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:suriota_mobile_gateway/constant/app_gap.dart';
import 'package:suriota_mobile_gateway/constant/image_asset.dart';
import 'package:suriota_mobile_gateway/global/utils/text_extension.dart';
import 'package:suriota_mobile_gateway/screen/home/home_screen.dart';
import 'package:suriota_mobile_gateway/services/bluetooth_permission_service.dart';

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

    bool permissionGranted =
        await BluetoothPermissionService.checkAndRequestPermissions(context);

    if (permissionGranted && context.mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const HomeScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(children: [
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
              Text(
                "v1.0.0",
                style: context.bodySmall,
              ),
              AppSpacing.lg,
            ],
          ),
        ),
      ]),
    );
  }
}
