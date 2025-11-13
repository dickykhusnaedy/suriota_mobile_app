import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:gateway_config/core/constants/app_color.dart';
import 'package:gateway_config/core/constants/app_gap.dart';
import 'package:gateway_config/core/controllers/ble_controller.dart';
import 'package:gateway_config/core/utils/app_helpers.dart';
import 'package:gateway_config/core/utils/extensions.dart';
import 'package:gateway_config/core/utils/snackbar_custom.dart';
import 'package:gateway_config/models/device_model.dart';
import 'package:gateway_config/presentation/pages/devices/widgets/device_list_widget.dart';
import 'package:gateway_config/presentation/widgets/common/custom_alert_dialog.dart';
import 'package:gateway_config/presentation/widgets/common/custom_textfield.dart';
import 'package:gateway_config/presentation/widgets/common/loading_overlay.dart';
import 'package:gateway_config/presentation/widgets/common/reusable_widgets.dart';
import 'package:get/get.dart';

class AddDeviceScreen extends StatefulWidget {
  const AddDeviceScreen({super.key});

  @override
  State<AddDeviceScreen> createState() => _AddDeviceScreenState();
}

class _AddDeviceScreenState extends State<AddDeviceScreen> {
  final controller = Get.put(BleController());
  bool isBluetoothOn = false;

  // Search functionality
  final TextEditingController searchController = TextEditingController();
  Timer? _searchDebounceTimer;

  @override
  void initState() {
    super.initState();
    _checkBluetoothStatus();

    // IMPORTANT: Clear search state dan scanned devices saat page dibuka
    // Ini mencegah search sebelumnya masih tersimpan
    // connectedHistory TIDAK akan terhapus (list terpisah)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _clearSearch();
      controller.scannedDevices.clear();
    });
  }

  @override
  void dispose() {
    // Clear search state di controller saat leaving page
    _clearSearch();

    searchController.dispose();
    _searchDebounceTimer?.cancel();
    super.dispose();
  }

  // Debounced search dengan delay 300ms untuk performance
  void _onSearchChanged(String query) {
    // Cancel timer sebelumnya jika ada
    _searchDebounceTimer?.cancel();

    // Buat timer baru dengan delay 300ms
    _searchDebounceTimer = Timer(const Duration(milliseconds: 300), () {
      // Jalankan filter setelah delay
      controller.filterDevices(query);
      AppHelpers.debugLog('Search executed: "$query"');
    });
  }

  // Clear search field dan reset filter
  void _clearSearch() {
    // Cancel any pending search debounce
    _searchDebounceTimer?.cancel();

    // Clear UI controller
    searchController.clear();

    // Clear BleController search state
    controller.clearSearch();

    AppHelpers.debugLog('Search cleared');
  }

  Future<void> _checkBluetoothStatus() async {
    FlutterBluePlus.adapterState.listen((state) {
      setState(() {
        isBluetoothOn = state == BluetoothAdapterState.on;
      });
    });
  }

  Future<void> _checkBluetoothDevice() async {
    if (isBluetoothOn) {
      // Clear search saat scan baru dimulai
      _clearSearch();
      controller.startScan();
    } else {
      SnackbarCustom.showSnackbar(
        'Bluetooth is off',
        'Please enable Bluetooth to scan devices.',
        AppColor.redColor,
        AppColor.whiteColor,
      );
    }
  }

  void disconnect(DeviceModel deviceModel) async {
    CustomAlertDialog.show(
      title: "Disconnect Device",
      message:
          "Are you sure you want to disconnect from ${deviceModel.device.platformName}?",
      primaryButtonText: 'Yes',
      secondaryButtonText: 'No',
      onPrimaryPressed: () async {
        Get.back();
        await Future.delayed(Duration.zero);

        try {
          await controller.disconnectFromDevice(deviceModel);
        } catch (e) {
          AppHelpers.debugLog('Error disconnecting from device: $e');
          SnackbarCustom.showSnackbar(
            'Error',
            'Failed to disconnect from device',
            AppColor.redColor,
            AppColor.whiteColor,
          );
        }
      },
      barrierDismissible: false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Scaffold(
          appBar: _buildAppBar(),
          body: SafeArea(child: SingleChildScrollView(child: _buildBody())),
        ),
        Obx(() {
          return LoadingOverlay(
            isLoading: controller.isLoadingConnectionGlobal.value,
            message: controller.message.value.isNotEmpty
                ? controller.message.value
                : controller.errorMessage.value,
          );
        }),
      ],
    );
  }

  AppBar _buildAppBar() {
    return AppBar(
      centerTitle: true,
      iconTheme: const IconThemeData(color: AppColor.whiteColor),
      backgroundColor: AppColor.primaryColor,
      title: Text(
        'Add Device',
        style: context.h5.copyWith(color: AppColor.whiteColor),
      ),
      actions: [
        Obx(() {
          if (controller.scannedDevices.isNotEmpty &&
              !controller.isLoading.value) {
            return IconButton(
              onPressed: _checkBluetoothDevice,
              icon: const Icon(Icons.search, size: 24),
            );
          }
          return const SizedBox.shrink();
        }),
      ],
    );
  }

  Widget _buildBody() {
    return Obx(() {
      if (controller.isLoading.value) {
        return _buildScanningProgress();
      } else if (controller.scannedDevices.isEmpty) {
        return _buildFindDevice();
      } else {
        return _buildDeviceList();
      }
    });
  }

  Widget _buildFindDevice() {
    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      alignment: Alignment.center,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('Find device', style: context.h2),
          AppSpacing.sm,
          Text(
            'Finding nearby devices with\nBluetooth connectivity...',
            textAlign: TextAlign.center,
            style: context.body.copyWith(color: AppColor.grey),
          ),
          AppSpacing.xxxl,
          GradientButton(
            text: 'Scan Devices',
            icon: Icons.search,
            width: MediaQuery.of(context).size.width * 0.4,
            onPressed: _checkBluetoothDevice,
          ),
        ],
      ),
    );
  }

  Widget _buildScanningProgress() {
    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      alignment: Alignment.center,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Obx(() {
            if (controller.isLoading.value) {
              return const CircularProgressIndicator(
                color: AppColor.primaryColor,
              );
            }
            return const SizedBox.shrink();
          }),
          AppSpacing.md,
          Text(
            "Scanning device...",
            style: context.body.copyWith(color: AppColor.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildDeviceList() {
    return Padding(
      padding: AppPadding.medium,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppSpacing.sm,
          Text('Device List', style: context.h4),
          AppSpacing.md,
          // Search field dengan debouncing
          CustomTextFormField(
            controller: searchController,
            hintTxt: 'Search device by name...',
            prefixIcon: const Icon(Icons.search, color: AppColor.primaryColor),
            suffixIcon: Obx(() {
              // Tampilkan clear button jika ada input
              if (controller.searchQuery.value.isNotEmpty) {
                return IconButton(
                  icon: const Icon(Icons.clear, color: AppColor.grey),
                  onPressed: _clearSearch,
                );
              }
              return const SizedBox.shrink();
            }),
            onChanges: _onSearchChanged,
          ),
          AppSpacing.md,
          Obx(() {
            if (controller.scannedDevices.isEmpty) {
              return Container(
                height: MediaQuery.of(context).size.height * 0.55,
                alignment: Alignment.center,
                child: Text(
                  'No device found.\nFind device near you.',
                  textAlign: TextAlign.center,
                  style: context.body.copyWith(color: AppColor.grey),
                ),
              );
            }

            // Gunakan filteredDevices jika ada search query, otherwise gunakan scannedDevices
            final devicesToShow = controller.searchQuery.value.isEmpty
                ? controller.scannedDevices
                : controller.filteredDevices;

            // Tampilkan pesan jika hasil search kosong
            if (devicesToShow.isEmpty &&
                controller.searchQuery.value.isNotEmpty) {
              return Container(
                height: MediaQuery.of(context).size.height * 0.55,
                alignment: Alignment.center,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.search_off,
                      size: 64,
                      color: AppColor.grey,
                    ),
                    AppSpacing.md,
                    Text(
                      'No device found for "${controller.searchQuery.value}"',
                      textAlign: TextAlign.center,
                      style: context.body.copyWith(color: AppColor.grey),
                    ),
                  ],
                ),
              );
            }

            return ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: devicesToShow.length,
              itemBuilder: (context, index) {
                final deviceModel = devicesToShow[index];

                return Obx(() {
                  return DeviceListWidget(
                    device: deviceModel.device,
                    isConnected: deviceModel.isConnected.value,
                    isLoadingConnection: deviceModel.isLoadingConnection.value,
                    onConnect: () async {
                      if (!deviceModel.isConnected.value) {
                        await controller.connectToDevice(deviceModel);
                      }
                    },
                    onDisconnect: () async {
                      if (deviceModel.isConnected.value) {
                        disconnect(deviceModel);
                      }
                    },
                  );
                });
              },
            );
          }),
          AppSpacing.md,
          Obx(() {
            final totalDevices = controller.scannedDevices.length;
            final filteredCount = controller.filteredDevices.length;
            final hasSearchQuery = controller.searchQuery.value.isNotEmpty;

            String message;
            if (hasSearchQuery && filteredCount > 0) {
              message = 'Showing $filteredCount of $totalDevices devices';
            } else if (hasSearchQuery && filteredCount == 0) {
              message = 'No matches found from $totalDevices devices';
            } else {
              message =
                  'A total of $totalDevices devices were successfully discovered.';
            }

            return Center(
              child: Text(
                message,
                style: context.bodySmall.copyWith(color: AppColor.grey),
              ),
            );
          }),
        ],
      ),
    );
  }
}
