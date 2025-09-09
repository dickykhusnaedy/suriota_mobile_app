import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gateway_config/core/utils/extensions.dart';

class PermissionDenied extends StatefulWidget {
  const PermissionDenied({super.key});

  @override
  State<PermissionDenied> createState() => _PermissionDeniedState();
}

class _PermissionDeniedState extends State<PermissionDenied> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle(
          statusBarColor: Colors.white, // Latar belakang status bar transparan
          statusBarIconBrightness:
              Brightness.dark, // Warna ikon status bar (misal: putih)
          statusBarBrightness: Brightness.dark, // Kecerahan status bar
          systemNavigationBarColor: Colors.black, // Warna navigasi bar
          systemNavigationBarIconBrightness: Brightness.dark,
        ),
        child: Center(
          child: Text(
            'Bluetooth permission is required to use this app.',
            style: context.bodySmall,
          ),
        ),
      ),
    );
  }
}
