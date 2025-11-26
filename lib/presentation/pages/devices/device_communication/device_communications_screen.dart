import 'dart:async';

import 'package:flutter/material.dart';
import 'package:gateway_config/core/constants/app_color.dart';
import 'package:gateway_config/core/constants/app_gap.dart';
import 'package:gateway_config/core/controllers/ble_controller.dart';
import 'package:gateway_config/core/controllers/devices_controller.dart';
import 'package:gateway_config/core/utils/app_helpers.dart';
import 'package:gateway_config/core/utils/extensions.dart';
import 'package:gateway_config/core/utils/loading_progress.dart';
import 'package:gateway_config/core/utils/snackbar_custom.dart';
import 'package:gateway_config/models/device_model.dart';
import 'package:gateway_config/presentation/widgets/common/custom_alert_dialog.dart';
import 'package:gateway_config/presentation/widgets/common/custom_textfield.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';

class DeviceCommunicationsScreen extends StatefulWidget {
  const DeviceCommunicationsScreen({super.key, required this.model});
  final DeviceModel model;

  @override
  State<DeviceCommunicationsScreen> createState() =>
      _DeviceCommunicationsScreenState();
}

class _DeviceCommunicationsScreenState
    extends State<DeviceCommunicationsScreen> {
  final BleController bleController;
  final DevicesController controller;

  Map<String, dynamic>? dataDevice = {};

  bool isLoading = false;
  bool isInitialized = false;

  // Device status cache (deviceId -> enabled status)
  final RxMap<String, bool> deviceStatusCache = <String, bool>{}.obs;

  // Search functionality
  final TextEditingController searchController = TextEditingController();
  Timer? _searchDebounceTimer;

  _DeviceCommunicationsScreenState()
    : bleController = Get.find<BleController>(),
      controller = Get.find<DevicesController>();

  @override
  void initState() {
    super.initState();

    // IMPORTANT: Clear search state saat page dibuka
    // Ini mencegah search sebelumnya masih tersimpan
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _clearSearch();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!isInitialized) {
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        // Use smart cache instead of always fetching
        await controller.fetchDevicesIfNeeded(widget.model);

        // Fetch status for all devices
        await _getAllDeviceStatus();

        isInitialized = true;
      });
    }
  }

  @override
  void dispose() {
    // Clear search state di controller saat leaving page
    _clearSearch();

    searchController.dispose();
    _searchDebounceTimer?.cancel();
    isInitialized = false;
    super.dispose();
  }

  // Format time ago untuk cache status indicator
  String _formatTimeAgo(DateTime? dateTime) {
    if (dateTime == null) return 'Never';

    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inSeconds < 60) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else {
      return '${difference.inDays}d ago';
    }
  }

  // Debounced search dengan delay 300ms untuk performance
  void _onSearchChanged(String query) {
    // Cancel timer sebelumnya jika ada
    _searchDebounceTimer?.cancel();

    // Buat timer baru dengan delay 300ms
    _searchDebounceTimer = Timer(const Duration(milliseconds: 300), () {
      // Jalankan filter setelah delay
      controller.filterDevices(query);
      AppHelpers.debugLog('Device search executed: "$query"');
    });
  }

  // Clear search field dan reset filter
  void _clearSearch() {
    // Cancel any pending search debounce
    _searchDebounceTimer?.cancel();

    // Clear UI controller
    searchController.clear();

    // Clear DevicesController search state
    controller.clearSearch();

    AppHelpers.debugLog('Device search cleared');
  }

  void _deleteDevice(String deviceId) async {
    if (!widget.model.isConnected.value) {
      SnackbarCustom.showSnackbar(
        '',
        'Device not connected',
        AppColor.redColor,
        AppColor.whiteColor,
      );
      return;
    }

    CustomAlertDialog.show(
      title: "Are you sure?",
      message: "Are you sure you want to delete this device?",
      primaryButtonText: 'Yes',
      secondaryButtonText: 'No',
      onPrimaryPressed: () async {
        Get.back();
        controller.isFetching.value = true;

        try {
          await controller.deleteDevice(widget.model, deviceId);

          if (Get.context != null) {
            SnackbarCustom.showSnackbar(
              '',
              'Device deleted successfully, refreshing data...',
              Colors.green,
              AppColor.whiteColor,
            );
          }

          await controller.fetchDevices(widget.model);
        } catch (e) {
          SnackbarCustom.showSnackbar(
            '',
            'Failed to delete device',
            AppColor.redColor,
            AppColor.whiteColor,
          );
        } finally {
          controller.isFetching.value = false;
        }
      },
      barrierDismissible: false,
    );
  }

  // Get status for all devices
  Future<void> _getAllDeviceStatus() async {
    if (!widget.model.isConnected.value) {
      return;
    }

    try {
      final command = {"op": "control", "type": "get_all_device_status"};

      final response = await bleController.sendCommand(command);

      if (response.status == 'ok') {
        // Parse RTU devices
        if (response.config?['rtu_devices']?['devices'] != null) {
          final rtuDevices =
              response.config!['rtu_devices']['devices'] as List<dynamic>;
          for (var device in rtuDevices) {
            final deviceId = device['device_id'] as String?;
            final enabled = device['enabled'] as bool? ?? true;
            if (deviceId != null) {
              deviceStatusCache[deviceId] = enabled;
            }
          }
        }

        // Parse TCP devices
        if (response.config?['tcp_devices']?['devices'] != null) {
          final tcpDevices =
              response.config!['tcp_devices']['devices'] as List<dynamic>;
          for (var device in tcpDevices) {
            final deviceId = device['device_id'] as String?;
            final enabled = device['enabled'] as bool? ?? true;
            if (deviceId != null) {
              deviceStatusCache[deviceId] = enabled;
            }
          }
        }

        AppHelpers.debugLog(
          'Device status fetched: ${deviceStatusCache.length} devices',
        );
      }
    } catch (e) {
      AppHelpers.debugLog('Error fetching all device status: $e');
    }
  }

  // Get status for a specific device
  Future<bool?> _getDeviceStatus(String deviceId) async {
    if (!widget.model.isConnected.value) {
      return null;
    }

    try {
      final command = {
        "op": "control",
        "type": "get_device_status",
        "device_id": deviceId,
      };

      final response = await bleController.sendCommand(command);

      if (response.status == 'ok' &&
          response.config?['device_status'] != null) {
        final enabled =
            response.config!['device_status']['enabled'] as bool? ?? true;
        deviceStatusCache[deviceId] = enabled;
        AppHelpers.debugLog('Device $deviceId status: $enabled');
        return enabled;
      }
    } catch (e) {
      AppHelpers.debugLog('Error fetching device status for $deviceId: $e');
    }
    return null;
  }

  // Enable or disable device with confirmation dialog
  Future<void> _enableDisableDevice(String deviceId, bool currentStatus) async {
    if (!widget.model.isConnected.value) {
      SnackbarCustom.showSnackbar(
        '',
        'Device not connected',
        AppColor.redColor,
        AppColor.whiteColor,
      );
      return;
    }

    final bool willEnable = !currentStatus;
    final String action = willEnable ? 'enable' : 'disable';
    final String actionCapitalized = willEnable ? 'Enable' : 'Disable';

    CustomAlertDialog.show(
      title: "Are you sure?",
      message: "Are you sure you want to $action this device?",
      primaryButtonText: 'Yes',
      secondaryButtonText: 'No',
      onPrimaryPressed: () async {
        Get.back();
        controller.isFetching.value = true;

        try {
          Map<String, dynamic> command;

          if (willEnable) {
            // Enable device
            command = {
              "op": "control",
              "type": "enable_device",
              "device_id": deviceId,
              "clear_metrics": false,
            };
          } else {
            // Disable device
            command = {
              "op": "control",
              "type": "disable_device",
              "device_id": deviceId,
              "reason": "Manual disable via mobile app",
            };
          }

          final response = await bleController.sendCommand(command);

          if (response.status == 'ok') {
            SnackbarCustom.showSnackbar(
              '',
              'Device ${actionCapitalized.toLowerCase()}d successfully',
              Colors.green,
              AppColor.whiteColor,
            );

            // Update cache
            deviceStatusCache[deviceId] = willEnable;

            // Refresh device status
            await _getDeviceStatus(deviceId);
          } else {
            SnackbarCustom.showSnackbar(
              '',
              'Failed to $action device: ${response.message}',
              AppColor.redColor,
              AppColor.whiteColor,
            );
          }
        } catch (e) {
          SnackbarCustom.showSnackbar(
            '',
            'Failed to $action device',
            AppColor.redColor,
            AppColor.whiteColor,
          );
          AppHelpers.debugLog('Error ${action}ing device: $e');
        } finally {
          controller.isFetching.value = false;
        }
      },
      barrierDismissible: false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _appBar(context),
      backgroundColor: AppColor.backgroundColor,
      body: RefreshIndicator(
        onRefresh: () async {
          // Force fetch fresh data (bypass cache)
          _clearSearch();
          await controller.fetchDevices(widget.model);
        },
        color: AppColor.primaryColor,
        child: SafeArea(
          child: SingleChildScrollView(
            padding: AppPadding.horizontalMedium,
            physics:
                const AlwaysScrollableScrollPhysics(), // Enable pull-to-refresh even when content doesn't scroll
            child: _bodyContent(context),
          ),
        ),
      ),
    );
  }

  AppBar _appBar(BuildContext context) {
    return AppBar(
      centerTitle: true,
      title: Text(
        'Device Communications',
        style: context.h5.copyWith(color: AppColor.whiteColor),
      ),
      iconTheme: const IconThemeData(color: AppColor.whiteColor),
      backgroundColor: AppColor.primaryColor,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: () {
          Get.back();
        },
      ),
      actions: [
        IconButton(
          onPressed: () {
            context.push(
              '/devices/device-communication/add?d=${widget.model.device.remoteId}',
            );
          },
          icon: const Icon(Icons.add_circle, size: 22),
        ),
      ],
    );
  }

  Column _bodyContent(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppSpacing.md,
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Data Devices',
                    style: context.h5,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  // Cache status indicator
                  Obx(() {
                    final lastUpdate = controller.lastFetchTime.value;
                    final timeAgo = _formatTimeAgo(lastUpdate);
                    final isStale =
                        lastUpdate != null &&
                        DateTime.now().difference(lastUpdate) >
                            const Duration(minutes: 5);

                    return Row(
                      children: [
                        Icon(
                          Icons.update,
                          size: 12,
                          color: isStale ? Colors.orange : AppColor.grey,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Updated $timeAgo',
                          style: context.bodySmall.copyWith(
                            color: isStale ? Colors.orange : AppColor.grey,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    );
                  }),
                ],
              ),
            ),
          ],
        ),
        AppSpacing.sm,
        // Search field dan protocol filter
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Search field
            Expanded(
              child: CustomTextFormField(
                controller: searchController,
                hintTxt: 'Search by name, ID...',
                prefixIcon: const Icon(
                  Icons.search,
                  color: AppColor.primaryColor,
                ),
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
            ),
            AppSpacing.sm,
            // Protocol filter dropdown
            _buildProtocolFilter(),
          ],
        ),
        AppSpacing.md,
        Obx(() {
          if (controller.isFetching.value) {
            return LoadingProgress();
          }

          if (controller.dataDevices.isEmpty) {
            return _emptyView(context);
          }

          // Gunakan filteredDataDevices jika ada search query atau protocol filter
          final devicesToShow =
              (controller.searchQuery.value.isEmpty &&
                  controller.selectedProtocol.value == 'All')
              ? controller.dataDevices
              : controller.filteredDataDevices;

          // Tampilkan pesan jika hasil search/filter kosong
          if (devicesToShow.isEmpty &&
              (controller.searchQuery.value.isNotEmpty ||
                  controller.selectedProtocol.value != 'All')) {
            String emptyMessage = 'No device found';
            if (controller.searchQuery.value.isNotEmpty) {
              emptyMessage += ' for "${controller.searchQuery.value}"';
            }
            if (controller.selectedProtocol.value != 'All') {
              emptyMessage +=
                  ' with protocol ${controller.selectedProtocol.value}';
            }

            return Container(
              height: MediaQuery.of(context).size.height * 0.55,
              alignment: Alignment.center,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.search_off, size: 64, color: AppColor.grey),
                  AppSpacing.md,
                  Text(
                    emptyMessage,
                    textAlign: TextAlign.center,
                    style: context.body.copyWith(color: AppColor.grey),
                  ),
                  AppSpacing.sm,
                  TextButton.icon(
                    onPressed: _clearSearch,
                    icon: const Icon(Icons.clear, size: 18),
                    label: const Text('Clear Filters'),
                    style: TextButton.styleFrom(
                      foregroundColor: AppColor.primaryColor,
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: devicesToShow.length,
            separatorBuilder: (context, index) => AppSpacing.sm,
            itemBuilder: (context, index) {
              final device = devicesToShow[index];

              return InkWell(
                onTap: () {
                  context.push(
                    '/devices/device-communication/stream-data?d=${widget.model.device.remoteId}&stream=${device['device_id']}',
                  );
                },
                child: _cardDeviceConnection(
                  context,
                  device['device_id'] ?? 'No ID',
                  device['device_name'] ?? 'Unknown Device',
                  device['protocol'] ?? 'Unknown',
                  device['register_count'] ?? '0',
                ),
              );
            },
          );

          
        }),
        AppSpacing.md,
        Obx(() {
          if (controller.dataDevices.isNotEmpty &&
              !controller.isFetching.value) {
            final totalDevices = controller.dataDevices.length;
            final filteredCount = controller.filteredDataDevices.length;
            final hasSearchQuery = controller.searchQuery.value.isNotEmpty;
            final hasProtocolFilter =
                controller.selectedProtocol.value != 'All';

            String message;
            if ((hasSearchQuery || hasProtocolFilter) && filteredCount > 0) {
              String filterInfo = '';
              if (hasProtocolFilter) {
                filterInfo = ' (${controller.selectedProtocol.value})';
              }
              message =
                  'Showing $filteredCount of $totalDevices entries$filterInfo';
            } else if ((hasSearchQuery || hasProtocolFilter) &&
                filteredCount == 0) {
              message = 'No matches found from $totalDevices entries';
            } else {
              message = 'Showing $totalDevices entries';
            }

            return Center(child: Text(message, style: context.bodySmall));
          }
          return const SizedBox.shrink();
        }),
        AppSpacing.md,
      ],
    );
  }

  Widget _emptyView(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.60,
      alignment: Alignment.center,
      child: Container(
        padding: const EdgeInsets.all(24),
        margin: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: AppColor.whiteColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: AppColor.primaryColor.withValues(alpha: 0.1),
            width: 1.5,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.devices_other,
              size: 64,
              color: AppColor.grey.withValues(alpha: 0.5),
            ),
            AppSpacing.md,
            Text(
              'No Devices Yet',
              textAlign: TextAlign.center,
              style: context.h6.copyWith(
                color: AppColor.blackColor,
                fontWeight: FontWeight.bold,
              ),
            ),
            AppSpacing.sm,
            Text(
              'You haven\'t added any devices yet.\nTap the + button above to add your first device.',
              textAlign: TextAlign.center,
              style: context.bodySmall.copyWith(
                color: AppColor.grey,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _cardDeviceConnection(
    BuildContext context,
    String deviceId,
    String title,
    String modbusType,
    int registerCount,
  ) {
    return Obx(() {
      // Get status from cache (default to true if not found)
      final bool isActive = deviceStatusCache[deviceId] ?? true;

      return Container(
        decoration: BoxDecoration(
          color: AppColor.whiteColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AppColor.primaryColor.withValues(alpha: 0.15),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            // Header dengan status dan toggle
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: isActive
                    ? Colors.green.withValues(alpha: 0.05)
                    : AppColor.grey.withValues(alpha: 0.05),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
              ),
              child: Row(
                children: [
                  // Status Indicator
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: isActive
                          ? Colors.green.withValues(alpha: 0.15)
                          : AppColor.grey.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isActive
                            ? Colors.green.withValues(alpha: 0.3)
                            : AppColor.grey.withValues(alpha: 0.3),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: isActive ? Colors.green : AppColor.grey,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          isActive ? 'Active' : 'Disabled',
                          style: context.bodySmall.copyWith(
                            color: isActive
                                ? Colors.green.shade700
                                : AppColor.grey,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.3,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  // Toggle Switch
                  Transform.scale(
                    scale: 0.75,
                    child: Switch(
                      value: isActive,
                      onChanged: (value) {
                        _enableDisableDevice(deviceId, isActive);
                      },
                      activeThumbColor: Colors.green,
                      activeTrackColor: Colors.green.withValues(alpha: 0.5),
                      inactiveThumbColor: AppColor.grey,
                      inactiveTrackColor: AppColor.grey.withValues(alpha: 0.3),
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  ),
                ],
              ),
            ),
            // Content
            Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Icon
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppColor.primaryColor.withValues(alpha: 0.1),
                          AppColor.lightPrimaryColor.withValues(alpha: 0.2),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppColor.primaryColor.withValues(alpha: 0.2),
                        width: 1,
                      ),
                    ),
                    child: Icon(
                      Icons.devices_outlined,
                      size: 24,
                      color: AppColor.primaryColor,
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Device Info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Device Name
                        Text(
                          title,
                          style: context.h6.copyWith(
                            color: AppColor.blackColor,
                            fontWeight: FontWeight.bold,
                            letterSpacing: -0.3,
                          ),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                        const SizedBox(height: 6),
                        // Protocol & Registers
                        Wrap(
                          spacing: 6,
                          runSpacing: 4,
                          children: [
                            _buildProtocolBadge(context, modbusType),
                            if (registerCount != 0)
                              _buildInfoBadge(
                                context,
                                '$registerCount Registers',
                                Icons.numbers,
                              ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        // Device ID
                        Row(
                          children: [
                            Icon(
                              Icons.fingerprint,
                              size: 12,
                              color: AppColor.grey.withValues(alpha: 0.7),
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                'ID: $deviceId',
                                style: context.bodySmall.copyWith(
                                  color: AppColor.grey,
                                  fontSize: 10,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            // Action Buttons
            Container(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
              child: Row(
                children: [
                  Expanded(
                    child: _buildActionButton(
                      context: context,
                      icon: Icons.remove_red_eye_outlined,
                      label: 'View',
                      color: AppColor.primaryColor,
                      onPressed: () {
                        context.push(
                          '/devices/device-communication/stream-data?d=${widget.model.device.remoteId}&stream=$deviceId',
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildActionButton(
                      context: context,
                      icon: Icons.edit_outlined,
                      label: 'Edit',
                      color: AppColor.primaryColor,
                      onPressed: () {
                        context.push(
                          '/devices/device-communication/edit?d=${widget.model.device.remoteId}&edit=$deviceId',
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  _buildCircularActionButton(
                    icon: Icons.delete_outline,
                    color: AppColor.redColor,
                    onPressed: () => _deleteDevice(deviceId),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    });
  }

  Widget _buildInfoBadge(BuildContext context, String text, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColor.grey.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: AppColor.grey.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: AppColor.grey, size: 10),
          const SizedBox(width: 4),
          Text(
            text,
            style: context.bodySmall.copyWith(
              color: AppColor.grey,
              fontSize: 10,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required BuildContext context,
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return Material(
      color: color.withValues(alpha: 0.08),
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 6),
              Text(
                label,
                style: context.bodySmall.copyWith(
                  color: color,
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCircularActionButton({
    required IconData icon,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return Material(
      color: color.withValues(alpha: 0.1),
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          width: 40,
          height: 40,
          alignment: Alignment.center,
          child: Icon(icon, size: 18, color: color),
        ),
      ),
    );
  }

  Widget _buildProtocolBadge(BuildContext context, String protocol) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColor.primaryColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: AppColor.primaryColor.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.settings_input_component,
            color: AppColor.primaryColor,
            size: 10,
          ),
          AppSpacing.xs,
          Text(
            protocol,
            style: context.bodySmall.copyWith(
              color: AppColor.primaryColor,
              fontSize: 10,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProtocolFilter() {
    return Obx(() {
      final isFiltered = controller.selectedProtocol.value != 'All';

      return Container(
        height: 50,
        decoration: BoxDecoration(
          color: AppColor.whiteColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isFiltered
                ? AppColor.primaryColor.withValues(alpha: 0.4)
                : AppColor.lightGrey,
            width: isFiltered ? 1.5 : 1,
          ),
          boxShadow: isFiltered
              ? [
                  BoxShadow(
                    color: AppColor.primaryColor.withValues(alpha: 0.15),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ]
              : [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 2,
                    offset: const Offset(0, 1),
                  ),
                ],
        ),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<String>(
            value: controller.selectedProtocol.value,
            icon: Icon(
              Icons.filter_list,
              size: 18,
              color: isFiltered ? AppColor.primaryColor : AppColor.grey,
            ),
            padding: const EdgeInsets.symmetric(horizontal: 12),
            borderRadius: BorderRadius.circular(12),
            dropdownColor: AppColor.whiteColor,
            elevation: 8,
            style: context.body.copyWith(
              color: AppColor.blackColor,
              fontWeight: isFiltered ? FontWeight.w600 : FontWeight.normal,
            ),
            items: [
              DropdownMenuItem(
                value: 'All',
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: AppColor.grey.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Icon(
                        Icons.apps,
                        size: 14,
                        color: AppColor.grey,
                      ),
                    ),
                    AppSpacing.xs,
                    Text(
                      'All',
                      style: context.body.copyWith(fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ),
              DropdownMenuItem(
                value: 'RTU',
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: AppColor.primaryColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Icon(
                        Icons.settings_input_component,
                        size: 14,
                        color: AppColor.primaryColor,
                      ),
                    ),
                    AppSpacing.xs,
                    Text(
                      'RTU',
                      style: context.body.copyWith(
                        color: AppColor.primaryColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              DropdownMenuItem(
                value: 'TCP',
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: AppColor.primaryColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Icon(
                        Icons.wifi,
                        size: 14,
                        color: AppColor.primaryColor,
                      ),
                    ),
                    AppSpacing.xs,
                    Text(
                      'TCP',
                      style: context.body.copyWith(
                        color: AppColor.primaryColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
            onChanged: (String? newValue) {
              if (newValue != null) {
                controller.setProtocolFilter(newValue);
                AppHelpers.debugLog('Protocol filter changed to: $newValue');
              }
            },
          ),
        ),
      );
    });
  }
}
