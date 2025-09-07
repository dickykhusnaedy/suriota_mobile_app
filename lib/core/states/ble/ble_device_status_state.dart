import 'package:get/get.dart';
import 'package:gateway_config/core/utils/app_helpers.dart';

class BleDeviceStatusState {
  final RxMap<String, bool> connectionStatus = <String, bool>{}.obs;
  final RxMap<String, bool> loadingStatus = <String, bool>{}.obs;
  final RxMap<String, bool> isConnected = <String, bool>{}.obs;

  // Reset all status maps
  void reset() {
    connectionStatus.clear();
    loadingStatus.clear();
    isConnected.clear();
    AppHelpers.debugLog('Device status reset');
  }
}
