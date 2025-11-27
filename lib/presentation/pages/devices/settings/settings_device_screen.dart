import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gateway_config/core/constants/app_color.dart';
import 'package:gateway_config/core/constants/app_gap.dart';
import 'package:gateway_config/core/utils/extensions.dart';
import 'package:gateway_config/core/utils/snackbar_custom.dart';
import 'package:gateway_config/models/device_model.dart';

import 'package:gateway_config/presentation/widgets/common/custom_alert_dialog.dart';
import 'package:gateway_config/presentation/widgets/common/custom_button.dart';
import 'package:gateway_config/presentation/widgets/common/menu_section.dart';
import 'package:gateway_config/presentation/widgets/common/loading_overlay.dart';
import 'package:gateway_config/core/controllers/ble_controller.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

class SettingsDeviceScreen extends StatefulWidget {
  final DeviceModel model;

  const SettingsDeviceScreen({super.key, required this.model});

  @override
  State<SettingsDeviceScreen> createState() => _SettingsDeviceScreenState();
}

class _SettingsDeviceScreenState extends State<SettingsDeviceScreen> {
  final bleController = Get.find<BleController>();
  bool isLoading = false;

  Future<void> _showPermissionBottomSheet(BuildContext context) async {
    await showModalBottomSheet(
      context: context,
      isDismissible: false,
      enableDrag: false,
      backgroundColor: AppColor.whiteColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) {
        return Container(
          padding: const EdgeInsets.all(20),
          child: Wrap(
            children: [
              Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text("Storage Permission Required", style: sheetContext.h4),
                    AppSpacing.sm,
                    Text(
                      "Storage permission is required to save and access backup files. Please enable it in your settings to continue.",
                      style: sheetContext.bodySmall,
                      textAlign: TextAlign.center,
                    ),
                    AppSpacing.md,
                    Row(
                      children: [
                        Expanded(
                          child: Button(
                            onPressed: () => Navigator.of(sheetContext).pop(),
                            text: "Close",
                            btnColor: AppColor.grey,
                            customStyle: sheetContext.bodySmall.copyWith(
                              color: AppColor.whiteColor,
                            ),
                          ),
                        ),
                        AppSpacing.md,
                        Expanded(
                          child: Button(
                            onPressed: () {
                              openAppSettings();
                              Navigator.of(sheetContext).pop();
                            },
                            text: "Open Settings",
                            customStyle: sheetContext.bodySmall.copyWith(
                              color: AppColor.whiteColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<bool> _requestStoragePermission(BuildContext context) async {
    if (Platform.isAndroid) {
      final androidVersion = await _getAndroidVersion();

      // Android 13+ (API 33+) - No storage permission needed for app-specific directories
      if (androidVersion >= 33) {
        return true;
      }

      // Android 11-12 (API 30-32) - Use scoped storage, no permission needed
      if (androidVersion >= 30) {
        return true;
      }

      // Android 10 and below - Use WRITE_EXTERNAL_STORAGE
      PermissionStatus status = await Permission.storage.status;

      // If already granted, return immediately
      if (status.isGranted) {
        return true;
      }

      // Request permission
      status = await Permission.storage.request();

        // If denied after request, show bottom sheet
      if (!status.isGranted) {
        if (status.isPermanentlyDenied || status.isDenied) {
          if (!mounted) return false;
          // ignore: use_build_context_synchronously
          await _showPermissionBottomSheet(context);
        }
        return false;
      }

      return true;
    }
    return true; // iOS doesn't need permission for app documents
  }

  Future<int> _getAndroidVersion() async {
    if (Platform.isAndroid) {
      final version = Platform.operatingSystemVersion;
      final match = RegExp(r'(\d+)').firstMatch(version);
      if (match != null) {
        return int.tryParse(match.group(1) ?? '0') ?? 0;
      }
    }
    return 0;
  }

  Future<void> downloadAllConfig(BuildContext context) async {
    // Request storage permission
    final hasPermission = await _requestStoragePermission(context);
    if (!hasPermission) {
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      // Send backup command via BLE
      final response = await bleController.sendCommand({
        "op": "read",
        "type": "full_config",
      });

      if (response.status == 'ok' || response.status == 'success') {
        // Create backup object with metadata
        final backup = {
          "created_at": DateTime.now().toIso8601String(),
          "backup_info":
              response.config['backup_info'] ??
              {
                "timestamp": DateTime.now().millisecondsSinceEpoch,
                "device_name": "SURIOTA_GW",
              },
          "config": response.config['config'] ?? response.config,
        };

        // Create filename with timestamp
        final now = DateTime.now();
        final timestamp =
            '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}_${now.hour.toString().padLeft(2, '0')}-${now.minute.toString().padLeft(2, '0')}-${now.second.toString().padLeft(2, '0')}';
        final filename = 'gateway_backup_$timestamp.json';

        // Get directory path - Use app-specific external directory (no permission needed)
        Directory? directory;
        if (Platform.isAndroid) {
          // For Android, use app-specific external storage
          // Path: /storage/emulated/0/Android/data/com.example.app/files/GatewayApp/Backup
          directory = await getExternalStorageDirectory();
          if (directory != null) {
            directory = Directory('${directory.path}/GatewayApp/Backup');
          }
        } else {
          // iOS uses app documents directory
          directory = await getApplicationDocumentsDirectory();
          directory = Directory('${directory.path}/GatewayApp/Backup');
        }

        // Create directory if not exists
        if (!await directory!.exists()) {
          await directory.create(recursive: true);
        }

        // Save file
        final filePath = '${directory.path}/$filename';
        final file = File(filePath);
        await file.writeAsString(jsonEncode(backup));

        setState(() {
          isLoading = false;
        });

        // Show success snackbar with file info
        SnackbarCustom.showSnackbar(
          '',
          'Backup saved successfully!\nFile: $filename\nLocation: ${directory.path}',
          Colors.green,
          AppColor.whiteColor,
        );
      } else {
        setState(() {
          isLoading = false;
        });

        SnackbarCustom.showSnackbar(
          '',
          response.message ?? 'Failed to download configuration',
          AppColor.redColor,
          AppColor.whiteColor,
        );
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });

      SnackbarCustom.showSnackbar(
        '',
        'Failed to download configuration: $e',
        AppColor.redColor,
        AppColor.whiteColor,
      );
    }
  }

  Future<void> importConfig(BuildContext context) async {
    // Request storage permission
    final hasPermission = await _requestStoragePermission(context);
    if (!hasPermission) {
      return;
    }

    try {
      // Pick JSON file
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
      );

      if (result == null) return;

      // Read file content
      final file = File(result.files.single.path!);
      final jsonString = await file.readAsString();
      final backup = jsonDecode(jsonString);

      // Validate backup structure
      if (!backup.containsKey('config')) {
        SnackbarCustom.showSnackbar(
          '',
          'Invalid backup file format',
          AppColor.redColor,
          AppColor.whiteColor,
        );
        return;
      }

      // Extract backup info
      final backupInfo = backup['backup_info'] ?? {};
      final createdAt = backup['created_at'] ?? 'Unknown';
      final firmwareVersion = backupInfo['firmware_version'] ?? 'Unknown';
      final totalDevices = backupInfo['total_devices']?.toString() ?? '0';
      final totalRegisters = backupInfo['total_registers']?.toString() ?? '0';

      // Show confirmation dialog with backup info
      CustomAlertDialog.show(
        title: 'Restore Configuration',
        message:
            'Backup Information:\n'
            'Created: $createdAt\n'
            'Firmware: $firmwareVersion\n'
            'Devices: $totalDevices\n'
            'Registers: $totalRegisters\n\n'
            'This will REPLACE all current configurations!\n\n'
            'Are you sure you want to continue?',
        primaryButtonText: 'Yes',
        secondaryButtonText: 'No',
        barrierDismissible: false,
        onPrimaryPressed: () async {
          Get.back(); // Close dialog

          setState(() {
            isLoading = true;
          });

          try {
            // Send restore command
            final response = await bleController.sendCommand({
              "op": "system",
              "type": "restore_config",
              "config": backup['config'],
            });

            if (response.status == 'ok' || response.status == 'success') {
              setState(() {
                isLoading = false;
              });

              final restoredConfigs = response.config['restored_configs'] ?? [];
              final requiresRestart =
                  response.config['requires_restart'] ?? true;

              // Show success snackbar
              SnackbarCustom.showSnackbar(
                '',
                'Configuration restored successfully!\n'
                    'Restored: ${restoredConfigs.join(', ')}',
                Colors.green,
                AppColor.whiteColor,
              );

              // Show restart dialog if needed
              if (requiresRestart) {
                await Future.delayed(const Duration(seconds: 2));

                CustomAlertDialog.show(
                  title: 'Restart Required',
                  message:
                      'Configuration has been restored successfully.\n\n'
                      'Device restart is recommended to apply all changes.\n\n'
                      'Would you like to restart the device now?',
                  primaryButtonText: 'Restart Now',
                  secondaryButtonText: 'Later',
                  onPrimaryPressed: () {
                    Get.back();
                    // TODO: Implement device restart if API available
                    SnackbarCustom.showSnackbar(
                      '',
                      'Please restart the device manually',
                      AppColor.primaryColor,
                      AppColor.whiteColor,
                    );
                  },
                );
              }
            } else {
              setState(() {
                isLoading = false;
              });

              SnackbarCustom.showSnackbar(
                '',
                response.message ?? 'Failed to restore configuration',
                AppColor.redColor,
                AppColor.whiteColor,
              );
            }
          } catch (e) {
            setState(() {
              isLoading = false;
            });

            SnackbarCustom.showSnackbar(
              '',
              'Failed to restore configuration: $e',
              AppColor.redColor,
              AppColor.whiteColor,
            );
          }
        },
      );
    } catch (e) {
      SnackbarCustom.showSnackbar(
        '',
        'Failed to read backup file: $e',
        AppColor.redColor,
        AppColor.whiteColor,
      );
    }
  }

  Future<void> clearAllConfiguration(BuildContext context) async {
    CustomAlertDialog.show(
      title: 'Clear All Configuration',
      message:
          'All configurations that have been created will be permanently deleted. Are you sure you want to delete everything?',
      primaryButtonText: 'Yes',
      secondaryButtonText: 'No',
      barrierDismissible: false,
      onPrimaryPressed: () async {
        Get.back(); // Close dialog

        setState(() {
          isLoading = true;
        });

        try {
          // Send factory reset command
          final response = await bleController.sendCommand({
            "op": "system",
            "type": "factory_reset",
            "reason": "Clear all configuration via mobile app",
          });

          if (response.status == 'ok' || response.status == 'success') {
            // Wait 3 seconds before showing success snackbar
            await Future.delayed(const Duration(seconds: 3));

            setState(() {
              isLoading = false;
            });

            // Show success snackbar
            SnackbarCustom.showSnackbar(
              '',
              'All configurations have been cleared successfully. The device will restart.',
              Colors.green,
              AppColor.whiteColor,
            );

            // Wait 3 seconds after snackbar before navigating to home
            await Future.delayed(const Duration(seconds: 3));

            // Navigate to home
            if (mounted) {
              if (context.mounted) {
                GoRouter.of(context).go('/');
              } else {
                Get.offAllNamed('/');
              }
            }
          } else {
            setState(() {
              isLoading = false;
            });

            // Show error snackbar
            SnackbarCustom.showSnackbar(
              '',
              response.message ?? 'Failed to clear configuration',
              AppColor.redColor,
              AppColor.whiteColor,
            );
          }
        } catch (e) {
          setState(() {
            isLoading = false;
          });

          // Show error snackbar
          SnackbarCustom.showSnackbar(
            '',
            'Failed to clear configuration: $e',
            AppColor.redColor,
            AppColor.whiteColor,
          );
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        AnnotatedRegion<SystemUiOverlayStyle>(
          value: const SystemUiOverlayStyle(
            statusBarColor: AppColor.primaryColor,
            statusBarIconBrightness: Brightness.light,
            statusBarBrightness: Brightness.dark,
            systemNavigationBarColor: AppColor.whiteColor,
            systemNavigationBarIconBrightness: Brightness.dark,
          ),
          child: Scaffold(
            backgroundColor: AppColor.backgroundColor,
            appBar: AppBar(
              backgroundColor: AppColor.primaryColor,
              iconTheme: const IconThemeData(color: AppColor.whiteColor),
              centerTitle: true,
              title: Text(
                'Device Settings',
                style: context.h5.copyWith(color: AppColor.whiteColor),
              ),
            ),
            body: SafeArea(
              child: SingleChildScrollView(
                padding: AppPadding.screenPadding,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AppSpacing.sm,
                    MenuSection(
                      items: [
                        MenuItem(
                          icon: Icons.upload_file_outlined,
                          title: 'Import Config',
                          onTap: () => importConfig(context),
                        ),
                        MenuItem(
                          icon: Icons.download_outlined,
                          title: 'Download All Config',
                          onTap: () => downloadAllConfig(context),
                        ),
                        MenuItem(
                          icon: Icons.delete_sweep_outlined,
                          title: 'Clear Configuration',
                          onTap: () => clearAllConfiguration(context),
                          iconColor: AppColor.redColor,
                          titleColor: AppColor.redColor,
                        ),
                      ],
                    ),
                    AppSpacing.xl,
                  ],
                ),
              ),
            ),
          ),
        ),
        LoadingOverlay(
          isLoading: isLoading,
          message: isLoading ? 'Processing...' : '',
        ),
      ],
    );
  }
}
