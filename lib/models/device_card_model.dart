class DeviceCardModel {
  final String deviceTitle;
  final String deviceAddress;
  bool statusColor;
  DeviceCardModel(
      {required this.deviceAddress,
      required this.deviceTitle,
      this.statusColor = true});
}

List<DeviceCardModel> deviceListDummy = [
  DeviceCardModel(
      deviceTitle: 'Dummy Device 1',
      deviceAddress: 'CC:12:3C:45:A6:7E',
      statusColor: true),
  DeviceCardModel(
      deviceTitle: "Dummy Device 2",
      deviceAddress: 'AA:89:1B:23:B4:5F',
      statusColor: true),
  DeviceCardModel(
      deviceTitle: 'Dummy Device 3',
      deviceAddress: 'CC:11:2B:33:C5:8E',
      statusColor: true),
];

List<DeviceCardModel> devicePairListDummy = [
  DeviceCardModel(
      deviceTitle: 'Dummy Device 4',
      deviceAddress: 'CC:12:3C:45:A6:7E',
      statusColor: true),
  DeviceCardModel(
      deviceTitle: "Dummy Device 5",
      deviceAddress: 'AA:89:1B:23:B4:5F',
      statusColor: true),
  DeviceCardModel(
      deviceTitle: 'Dummy Device 6',
      deviceAddress: 'CC:11:2B:33:C5:8E',
      statusColor: true),
];
