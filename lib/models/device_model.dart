class DeviceModel {
  final String deviceTitle;
  final String deviceAddress;
  bool isConnected;
  bool isAvailable;

  DeviceModel({
    required this.deviceTitle,
    required this.deviceAddress,
    required this.isConnected,
    required this.isAvailable,
  });

}
