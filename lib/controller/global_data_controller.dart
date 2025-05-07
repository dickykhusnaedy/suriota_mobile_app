import 'package:get/get.dart';

class GlobalDataController extends GetxController {
  final RxMap<String, Map<String, String>> datasets =
      <String, Map<String, String>>{}.obs;

  void setData(String name, Map<String, String> data) {
    datasets[name] = data;
  }

  Map<String, String>? getData(String name) {
    return datasets[name];
  }

  void clearData() {
    datasets.clear();
  }
}
