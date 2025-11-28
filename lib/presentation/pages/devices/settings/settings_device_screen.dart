import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gateway_config/core/constants/app_color.dart';
import 'package:gateway_config/core/constants/app_gap.dart';
import 'package:gateway_config/core/utils/extensions.dart';
import 'package:gateway_config/core/utils/notification_helper.dart';
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

  Future<void> _showPermissionBottomSheet(
    BuildContext context, {
    bool isPhotos = false,
  }) async {
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
                    Text(
                      isPhotos
                          ? "Photos Permission Required"
                          : "Storage Permission Required",
                      style: sheetContext.h4,
                    ),
                    AppSpacing.sm,
                    Text(
                      isPhotos
                          ? "On Android 13+, we need Photos permission to save backup files to your device. This allows the app to store configuration backups that you can access later.\n\nPlease enable it in your settings to continue."
                          : "Storage permission is required to save and access backup files. Please enable it in your settings to continue.",
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
    if (!Platform.isAndroid) {
      return true; // iOS doesn't need permission for app documents
    }

    print('=== Storage Permission Request ===');

    // Try Android 13+ permissions first (photos/media)
    // If not available, will automatically fall back to storage
    PermissionStatus photosStatus = await Permission.photos.status;
    print('Photos Permission Status: $photosStatus');

    // Check if photos permission is available (Android 13+)
    // On older Android, Permission.photos will return denied/restricted
    if (photosStatus != PermissionStatus.restricted) {
      // Android 13+ detected - use photos permission
      print('Using Photos Permission (Android 13+)');

      if (photosStatus.isGranted) {
        return true;
      }

      // Request photos permission
      photosStatus = await Permission.photos.request();
      print('Photos Permission After Request: $photosStatus');

      if (photosStatus.isGranted) {
        return true;
      }

      // If denied, show explanation
      if (photosStatus.isPermanentlyDenied) {
        if (!mounted) return false;
        // ignore: use_build_context_synchronously
        await _showPermissionBottomSheet(context, isPhotos: true);
        return false;
      }

      // User just denied, don't show bottom sheet yet
      // They might grant it next time
      return false;
    }

    // Fallback to storage permission for Android 12 and below
    print('Using Storage Permission (Android 12 and below)');
    PermissionStatus storageStatus = await Permission.storage.status;
    print('Storage Permission Status: $storageStatus');

    if (storageStatus.isGranted) {
      return true;
    }

    // Request storage permission
    storageStatus = await Permission.storage.request();
    print('Storage Permission After Request: $storageStatus');

    if (storageStatus.isGranted) {
      return true;
    }

    // If permanently denied, show bottom sheet
    if (storageStatus.isPermanentlyDenied) {
      if (!mounted) return false;
      // ignore: use_build_context_synchronously
      await _showPermissionBottomSheet(context, isPhotos: false);
      return false;
    }

    // User just denied, don't show bottom sheet yet
    return false;
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
      }, useGlobalLoading: false);

      if (response.status == 'ok' || response.status == 'success') {
        print('=== BLE Response Received ===');
        print('Response status: ${response.status}');
        print('Response has backup_info: ${response.backupInfo != null}');
        print('Response has config: ${response.config != null}');

        // Extract backup info for display
        final backupInfo = response.backupInfo;

        // Show notification that download is in progress
        SnackbarCustom.showSnackbar(
          '',
          'Downloading in progress...',
          AppColor.lightGrey,
          AppColor.blackColor,
        );

        // Wait for first snackbar to show and start saving
        await Future.delayed(const Duration(milliseconds: 1600));

        // Create backup object with metadata
        // IMPORTANT: Structure matches BLE_BACKUP_RESTORE.md documentation
        // Response format: { status, backup_info, config }
        final backup = {
          "created_at": DateTime.now().toIso8601String(),
          "backup_info":
              response.backupInfo ??
              {
                "timestamp": DateTime.now().millisecondsSinceEpoch,
                "device_name": backupInfo?["device_name"] ?? "SURIOTA_GW",
                "firmware_version":
                    backupInfo?["firmware_version"] ?? "unknown",
                "total_devices": backupInfo?["total_devices"] ?? 0,
                "total_registers": backupInfo?["total_registers"] ?? 0,
              },
          "config": response.config,
        };

        print('Backup info: ${backup["backup_info"]}');

        // Calculate devices count from config
        final configMap = response.config is Map
            ? response.config as Map
            : null;
        final devicesCount = configMap?["devices"]?.length ?? 0;
        print('Config devices count: $devicesCount');

        if (response.backupInfo != null) {
          print(
            'Firmware version: ${response.backupInfo!["firmware_version"]}',
          );
          print('Total devices: ${response.backupInfo!["total_devices"]}');
          print('Total registers: ${response.backupInfo!["total_registers"]}');
          print(
            'Backup size: ${response.backupInfo!["backup_size_bytes"]} bytes',
          );
        }

        // Create filename with timestamp (matches API documentation format)
        final timestamp = DateTime.now().toIso8601String().replaceAll(
          RegExp(r'[:.Z]'),
          '-',
        );
        final filename = 'gateway_backup_$timestamp.json';

        // Get directory path based on platform
        Directory? directory;
        String? filePath;

        if (Platform.isAndroid) {
          // For Android, save to public Documents folder
          // Path: /storage/emulated/0/Documents/GatewayConfig/backup
          // This requires storage/photos permission which we already requested

          // Get external storage directory first
          final externalDir = await getExternalStorageDirectory();
          if (externalDir != null) {
            // Navigate to public Documents folder
            // From: /storage/emulated/0/Android/data/com.app/files
            // To:   /storage/emulated/0/Documents/GatewayConfig/backup
            final publicPath = externalDir.path.split('/Android/data/')[0];
            directory = Directory('$publicPath/Documents/GatewayConfig/backup');

            print('=== Saving Backup File ===');
            print('Target Directory: ${directory.path}');
          }
        } else {
          // iOS uses app documents directory
          directory = await getApplicationDocumentsDirectory();
          directory = Directory('${directory.path}/GatewayConfig/backup');
          print('=== Saving Backup File (iOS) ===');
          print('Target Directory: ${directory.path}');
        }

        if (directory == null) {
          throw Exception('Failed to get storage directory');
        }

        // Create directory if not exists
        if (!await directory.exists()) {
          print('Creating directory: ${directory.path}');
          await directory.create(recursive: true);
          print('✅ Directory created successfully');
        } else {
          print('✅ Directory already exists');
        }

        // Verify directory is writable
        print('Directory path: ${directory.path}');
        print('Directory exists: ${await directory.exists()}');

        // Save file
        filePath = '${directory.path}/$filename';
        final file = File(filePath);

        print('=== Writing Backup File ===');
        print('Full file path: $filePath');
        print('File name: $filename');

        await file.writeAsString(jsonEncode(backup));

        print('✅ File written successfully');

        // Verify file exists
        final fileExists = await file.exists();
        final fileSize = await file.length();
        print('File exists: $fileExists');
        print('File size: $fileSize bytes');

        setState(() {
          setState(() {
            isLoading = false;
          });
        });

        // Prepare user-friendly path display
        String displayPath;
        if (Platform.isAndroid) {
          // Show relative path from storage root
          displayPath = filePath.replaceFirst('/storage/emulated/0/', '');
        } else {
          // iOS - show directory name
          displayPath = 'GatewayConfig/backup/$filename';
        }

        // Show success snackbar
        SnackbarCustom.showSnackbar(
          '',
          'Successfully saved data to your local files',
          Colors.green,
          AppColor.whiteColor,
        );

        // Show push notification with full file path for opening file manager
        await NotificationHelper().showDownloadSuccessNotification(
          filePath: filePath, // Use full path, not displayPath
        );

        print('=== Backup Complete ===');
        print('Full path: $filePath');
        print('Display path: $displayPath');
      } else {
        setState(() {
          setState(() {
            isLoading = false;
          });
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
          Navigator.of(context).pop(); // Close dialog safely

          setState(() {
            setState(() {
              isLoading = true;
            });
          });

          // Show importing in progress message
          SnackbarCustom.showSnackbar(
            '',
            'Importing in progress, check your notification to see result',
            AppColor.lightPrimaryColor,
            AppColor.primaryColor,
          );

          try {
            // Send restore command
            final response = await bleController.sendCommand({
              "op": "system",
              "type": "restore_config",
              "config": backup['config'],
            }, useGlobalLoading: false);

            if (response.status == 'ok' || response.status == 'success') {
              setState(() {
                setState(() {
                  isLoading = false;
                });
              });

              // Calculate total configs imported
              final config = backup['config'] as Map;
              final devicesCount = (config['devices'] as List?)?.length ?? 0;

              // Show success snackbar
              SnackbarCustom.showSnackbar(
                '',
                'Successfully imported configuration to device',
                Colors.green,
                AppColor.whiteColor,
              );

              // Show push notification with total configs
              await NotificationHelper().showImportSuccessNotification(
                totalConfigs: devicesCount,
              );

              // Wait 3 seconds then disconnect from device
              await Future.delayed(const Duration(seconds: 3));
              await bleController.disconnectFromDevice(widget.model);
            } else {
              setState(() {
                setState(() {
                  isLoading = false;
                });
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
              setState(() {
                isLoading = false;
              });
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
        Navigator.of(context).pop(); // Close dialog safely

        setState(() {
          isLoading = true;
        });

        try {
          // Send factory reset command
          final response = await bleController.sendCommand({
            "op": "system",
            "type": "factory_reset",
            "reason": "Clear all configuration via mobile app",
          }, useGlobalLoading: false);

          if (response.status == 'ok' || response.status == 'success') {
            // Wait 3 seconds before showing success snackbar
            await Future.delayed(const Duration(seconds: 3));

            setState(() {
              setState(() {
                isLoading = false;
              });
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
              setState(() {
                isLoading = false;
              });
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
                          description: 'Only support .json file',
                          onTap: () => importConfig(context),
                        ),
                        MenuItem(
                          icon: Icons.download_outlined,
                          title: 'Download All Config',
                          description: Platform.isAndroid
                              ? 'Saved to Documents/GatewayConfig/backup/'
                              : 'Saved to App Documents/GatewayConfig/backup/',
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
