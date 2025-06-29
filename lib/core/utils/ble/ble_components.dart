import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:suriota_mobile_gateway/global/utils/helper.dart';

class BLEComponents {
  BluetoothService? _selectedService;
  BluetoothCharacteristic? _selectedCharacteristic;
  BluetoothCharacteristic? _writeCharacteristic;
  BluetoothCharacteristic? _notifyCharacteristic;

  BluetoothService? get selectedService => _selectedService;
  BluetoothCharacteristic? get selectedCharacteristic =>
      _selectedCharacteristic;
  BluetoothCharacteristic? get writeCharacteristic => _writeCharacteristic;
  BluetoothCharacteristic? get notifyCharacteristic => _notifyCharacteristic;

  // Reset all component references
  void reset() {
    _selectedService = null;
    _selectedCharacteristic = null;
    _writeCharacteristic = null;
    _notifyCharacteristic = null;
    AppHelpers.debugLog('BLE components reset');
  }

  // Setters for characteristics
  void setWriteCharacteristic(BluetoothCharacteristic char) =>
      _writeCharacteristic = char;
  void setNotifyCharacteristic(BluetoothCharacteristic char) =>
      _notifyCharacteristic = char;
  void setSelectedService(BluetoothService service) =>
      _selectedService = service;
}
