import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:suriota_mobile_gateway/provider/LoadingProvider.dart';

class LoadingOverlay extends StatelessWidget {
  final Widget child;

  const LoadingOverlay({Key? key, required this.child}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final loadingProvider = Provider.of<LoadingProvider>(context);

    return Stack(
      children: [
        child,
        if (loadingProvider.isLoading)
          Container(
            color: Colors.black54,
            child: const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                strokeWidth: 2.0,
              ),
            ),
          ),
      ],
    );
  }
}
