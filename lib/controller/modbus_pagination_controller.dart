import 'package:get/get.dart';

class ModbusPaginationController extends GetxController {
  final modbus = <Map<String, dynamic>>[].obs;
  final page = 1.obs;
  final pageSize = 10.obs;
  final totalRecords = 0.obs;
  final totalPages = 1.obs;
  final isLoading = false.obs;

  void setPaginationData(Map<String, dynamic> json) {
    isLoading.value = true;

    final List<dynamic> rawData = json['data'] ?? [];
    modbus.value = rawData.cast<Map<String, dynamic>>();

    page.value = json['page'] ?? 1;
    pageSize.value = json['pageSize'] ?? 10;
    totalRecords.value = json['totalRecords'] ?? 0;
    totalPages.value = json['totalPages'] ?? 1;

    isLoading.value = false;
  }

  void checkModbus() {
    if (modbus.isEmpty) {
      Get.snackbar('Error', 'Failed to fetch device data');
      Future.delayed(3.seconds, () => Get.back());
    }
  }

  void clear() {
    modbus.clear();
    page.value = 1;
    pageSize.value = 10;
    totalRecords.value = 0;
    totalPages.value = 1;
  }
}
