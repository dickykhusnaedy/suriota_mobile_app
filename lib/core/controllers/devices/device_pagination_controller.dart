import 'package:get/get.dart';

class DevicePaginationController extends GetxController {
  final devices = <Map<String, dynamic>>[].obs;
  final page = 1.obs;
  final pageSize = 10.obs;
  final totalRecords = 0.obs;
  final totalPages = 1.obs;
  final isLoading = false.obs;

  void setPaginationData(Map<String, dynamic> json) {
    isLoading.value = true;

    // Handle null JSON map
    if (json.isEmpty) {
      devices.value = [];
      page.value = 1;
      pageSize.value = 10;
      totalRecords.value = 0;
      totalPages.value = 1;
      isLoading.value = false;
      return;
    }

    final List<dynamic> rawData = json['data'] ?? [];
    devices.value = rawData.cast<Map<String, dynamic>>();

    page.value = json['page'] ?? 1;
    pageSize.value = json['pageSize'] ?? 10;
    totalRecords.value = json['data'].length ?? 0;
    totalPages.value = json['totalPages'] ?? 1;

    isLoading.value = false;
  }

  void checkDevices() {
    if (devices.isEmpty) {
      Get.snackbar('Error', 'Failed to fetch device data');
      Future.delayed(3.seconds, () => Get.back());
    }
  }

  void clear() {
    devices.clear();
    page.value = 1;
    pageSize.value = 10;
    totalRecords.value = 0;
    totalPages.value = 1;
  }
}
