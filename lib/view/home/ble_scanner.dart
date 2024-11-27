import 'package:flutter/material.dart';
import 'package:flutter_blue/flutter_blue.dart';
import 'package:suriota_mobile_gateway/constant/app_color.dart';
import 'package:suriota_mobile_gateway/global/widgets/device_card.dart';

class BleScanner extends StatefulWidget {
  @override
  _BleScannerState createState() => _BleScannerState();
}

class _BleScannerState extends State<BleScanner> {
  FlutterBlue flutterBlue = FlutterBlue.instance;
  List<BluetoothDevice> devices = [];
  bool isScanning = false;

  @override
  void initState() {
    super.initState();
    startScanning();
  }

  void startScanning() {
    setState(() {
      isScanning = true;
      devices.clear(); // Bersihkan daftar perangkat sebelum scanning
    });

    // Memulai scanning
    flutterBlue.startScan(timeout: Duration(seconds: 5)).then((_) {
      setState(() {
        isScanning = false; // Scanning selesai setelah 5 detik
      });
    });

    // Mendapatkan hasil scan
    flutterBlue.scanResults.listen((results) {
      for (ScanResult result in results) {
        if (!devices.contains(result.device)) {
          setState(() {
            devices.add(result.device);
          });
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: const Text('Add Device'),
        iconTheme: const IconThemeData(
          color:
              Colors.white, // Mengatur warna ikon tombol "Back" menjadi putih
        ),
      ),
      body: isScanning
          ? const Center(
              child: CircularProgressIndicator(
              color: AppColor.primaryColor,
            )) // Menampilkan loading saat scanning
          : devices.isNotEmpty
              ? ListView.builder(
                  itemCount: devices.length,
                  itemBuilder: (context, index) {
                    return DeviceCard(
                      deviceTitle: devices[index].name.isNotEmpty
                          ? devices[index].name
                          : 'Unknown Device',
                      deviceAddress: devices[index].id.toString(),
                      buttonTitle: 'Pair',
                      colorButton: AppColor.primaryColor,
                      onPressed: () {},
                    );
                  },
                )
              : Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('No devices found'),
                      const SizedBox(height: 10),
                      ElevatedButton(
                        onPressed: startScanning,
                        child: const Text('Refresh'),
                      ),
                    ],
                  ),
                ),
    );
  }

  @override
  void dispose() {
    flutterBlue.stopScan();
    super.dispose();
  }
}

// ListTile(
//                       title: Text(devices[index].name.isNotEmpty
//                           ? devices[index].name
//                           : "Unknown Device"),
//                       subtitle: Text(devices[index].id.toString()),
//                     );