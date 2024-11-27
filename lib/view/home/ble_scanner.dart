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
  BluetoothDevice? connectedDevice;
  BluetoothDeviceState? deviceState;
  bool isScanning = false;

  @override
  void initState() {
    super.initState();
    scanDevices();
  }

  @override
  void dispose() {
    flutterBlue.stopScan();
    super.dispose();
  }

  void scanDevices() {
    setState(() {
      isScanning = true;
      devices.clear(); // Bersihkan daftar perangkat sebelum scanning
    });

    // Memulai scanning
    flutterBlue.startScan(timeout: Duration(seconds: 3)).then((_) {
      setState(() {
        isScanning = false; // Scanning selesai setelah 3 detik
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

  // Menghubungkan ke perangkat
  Future<void> connectToDevice(BluetoothDevice device) async {
    try {
      await device.connect();
      setState(() {
        connectedDevice = device;
      });
      monitorDeviceState(device);
      print('Connected to ${device.name}');
      discoverServices(device);
    } catch (e) {
      print('Connection failed: $e');
    }
  }

  // Memantau status koneksi perangkat
  void monitorDeviceState(BluetoothDevice device) {
    device.state.listen((state) {
      setState(() {
        deviceState = state;
      });

      if (state == BluetoothDeviceState.disconnected) {
        print('Device disconnected. Attempting to reconnect...');
        reconnectDevice(device);
      } else if (state == BluetoothDeviceState.connected) {
        print('Device is connected');
      }
    });
  }

  // Menyambungkan ulang perangkat
  Future<void> reconnectDevice(BluetoothDevice device) async {
    try {
      await device.connect();
      print('Reconnected to ${device.name}');
    } catch (e) {
      print('Failed to reconnect: $e');
    }
  }

  // Menemukan layanan dari perangkat yang terhubung
  Future<void> discoverServices(BluetoothDevice device) async {
    var services = await device.discoverServices();
    services.forEach((service) {
      print('Service UUID: ${service.uuid}');
      service.characteristics.forEach((characteristic) {
        print('Characteristic UUID: ${characteristic.uuid}');
      });
    });
  }

  // Memutuskan koneksi dari perangkat
  Future<void> disconnectDevice() async {
    if (connectedDevice != null) {
      await connectedDevice!.disconnect();
      setState(() {
        connectedDevice = null;
        deviceState = null;
      });
      print('Device disconnected manually');
    }
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
                      onPressed: () => connectToDevice(devices[index]),
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
                        onPressed: scanDevices,
                        child: const Text('Refresh'),
                      ),
                    ],
                  ),
                ),
    );
  }
}
