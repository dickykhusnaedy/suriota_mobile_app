// ignore_for_file: prefer_const_literals_to_create_immutables, prefer_const_constructors

import 'package:flutter/material.dart';
import 'package:gateway_config/core/constants/app_color.dart';
import 'package:gateway_config/core/constants/app_gap.dart';
import 'package:gateway_config/core/constants/static_data.dart';
import 'package:gateway_config/core/controllers/ble_controller.dart';
import 'package:gateway_config/core/controllers/server_config_controller.dart';
import 'package:gateway_config/core/utils/app_helpers.dart';
import 'package:gateway_config/core/utils/extensions.dart';
import 'package:gateway_config/core/utils/snackbar_custom.dart';
import 'package:gateway_config/models/device_model.dart';
import 'package:gateway_config/models/dropdown_items.dart';
import 'package:gateway_config/presentation/widgets/common/custom_alert_dialog.dart';
import 'package:gateway_config/presentation/widgets/common/custom_textfield.dart';
import 'package:gateway_config/presentation/widgets/common/dropdown.dart';
import 'package:gateway_config/presentation/widgets/common/loading_overlay.dart';
import 'package:gateway_config/presentation/widgets/common/multi_header_form.dart';
import 'package:gateway_config/presentation/widgets/common/reusable_widgets.dart';
import 'package:gateway_config/presentation/widgets/server_config/custom_topic_card.dart';
import 'package:gateway_config/presentation/widgets/server_config/mqtt_mode_toggle_card.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';

class FormConfigServer extends StatefulWidget {
  const FormConfigServer({super.key, required this.model});
  final DeviceModel model;

  @override
  State<FormConfigServer> createState() => _FormConfigServerState();
}

class _FormConfigServerState extends State<FormConfigServer> {
  final BleController bleController = Get.find<BleController>();
  final ServerConfigController controller = Get.put(ServerConfigController());

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  late Worker _worker;

  bool _passwordVisible = true;

  // State variables
  String communicationSelected = 'ETH';
  String isWifiEnabled = 'true';
  String isEthernetEnabled = 'true';
  String isUseDhcp = 'true';

  String isEnabledMqtt = 'true';
  String isEnabledHttp = 'false';
  String methodRequestSelected = 'POST';
  String bodyFormatRequestSelected = 'json';

  String cleanSessionSelected = 'true';
  String useTlsSelected = 'false';

  // MQTT Mode: 'default' or 'customize'
  String mqttPublishMode = 'default';

  // Custom topics for customize mode
  List<Map<String, dynamic>> customTopics = [];

  // Devices data from API (for customize mode)
  List<Map<String, dynamic>> devicesWithRegisters = [];
  bool isLoadingDevices = false;

  // TextEditingControllers
  final ipAddressController = TextEditingController();
  final gatewayController = TextEditingController();
  final subnetMaskController = TextEditingController();
  final wifiSsidController = TextEditingController();
  final wifiPasswordController = TextEditingController();

  // MQTT Default Mode Interval (v2.2.0)
  final mqttDefaultIntervalController = TextEditingController(text: '5');
  String mqttDefaultIntervalUnit = 's';

  final serverNameController = TextEditingController();
  final portMqttController = TextEditingController(text: '1883');
  final publishTopicController = TextEditingController();
  final subscribeTopicController = TextEditingController();
  final keepAliveController = TextEditingController(text: '60');
  final clientIdController = TextEditingController();

  // HTTP Config (v2.2.0 - interval moved here)
  final urlLinkController = TextEditingController();
  final timeoutController = TextEditingController(text: '5000');
  final retryController = TextEditingController(text: '3');
  final httpIntervalController = TextEditingController(text: '5');
  String httpIntervalUnit = 's';

  final usernameController = TextEditingController();
  final passwordController = TextEditingController();

  late List<HeaderFieldController> headerControllers = [
    HeaderFieldController(key: '', value: ''),
  ];

  @override
  void initState() {
    super.initState();
    // Listen to dataDevice GetX observable, update form when fetch finished
    _worker = ever(controller.dataServer, (dataList) async {
      if (!mounted) return;
      if (dataList.isNotEmpty) {
        updateFormFields(dataList[0]);

        // Fetch devices after server config loaded (always load to ensure availability)
        if (devicesWithRegisters.isEmpty && !isLoadingDevices) {
          await _fetchDevicesWithRegisters();
          // Convert flat registers to grouped format after devices are loaded
          if (customTopics.isNotEmpty && devicesWithRegisters.isNotEmpty) {
            _convertFlatRegistersToGrouped();
          }
        }
      }
    });

    // Fetch data after widget build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      controller.fetchData(widget.model);
    });
  }

  // Method untuk update semua field dari response JSON
  void updateFormFields(Map<String, dynamic> config) {
    // Communication config
    communicationSelected = config['communication']?['mode'];

    // Wifi config
    isWifiEnabled = (config['wifi']?['enabled'] ?? '').toString();
    wifiSsidController.text = config['wifi']?['ssid'] ?? '';
    wifiPasswordController.text = config['wifi']?['password'] ?? '';

    // Ethernet config
    isEthernetEnabled         = (config['ethernet']?['enabled'] ?? '').toString();
    isUseDhcp                 = (config['ethernet']?['use_dhcp'] ?? '').toString();
    ipAddressController.text  = config['ethernet']?['static_ip'] ?? '';
    gatewayController.text    = config['ethernet']?['gateway'] ?? '';
    subnetMaskController.text = config['ethernet']?['subnet'] ?? '';

    // MQTT
    isEnabledMqtt = (config['mqtt_config']?['enabled'] ?? '').toString();
    serverNameController.text = config['mqtt_config']?['broker_address'] ?? '';
    portMqttController.text =
        config['mqtt_config']?['broker_port']?.toString() ?? '';
    clientIdController.text = config['mqtt_config']?['client_id'] ?? '';
    usernameController.text = config['mqtt_config']?['username'] ?? '';
    passwordController.text = config['mqtt_config']?['password'] ?? '';
    keepAliveController.text =
        config['mqtt_config']?['keep_alive']?.toString() ?? '';
    cleanSessionSelected = (config['mqtt_config']?['clean_session'] ?? '')
        .toString();
    useTlsSelected = (config['mqtt_config']?['use_tls'] ?? '').toString();

    // MQTT Publish Mode
    mqttPublishMode = config['mqtt_config']?['publish_mode'] ?? 'default';

    // Load default mode settings
    if (config['mqtt_config']?['default_mode'] != null) {
      publishTopicController.text =
          config['mqtt_config']?['default_mode']?['topic_publish'] ?? '';
      mqttDefaultIntervalController.text =
          config['mqtt_config']?['default_mode']?['interval']?.toString() ??
          '5';
      mqttDefaultIntervalUnit =
          config['mqtt_config']?['default_mode']?['interval_unit'] ?? 's';
    }

    // Load subscribe topic based on active mode (v2.2.0 structure)
    if (mqttPublishMode == 'default') {
      subscribeTopicController.text =
          config['mqtt_config']?['default_mode']?['topic_subscribe'] ?? '';
    } else if (mqttPublishMode == 'customize') {
      subscribeTopicController.text =
          config['mqtt_config']?['customize_mode']?['topic_subscribe'] ?? '';
    }

    // Customize Mode - Load from customize_mode.custom_topics (v2.2.0)
    if (config['mqtt_config']?['customize_mode']?['custom_topics'] != null) {
      final rawTopics = List<Map<String, dynamic>>.from(
        config['mqtt_config']?['customize_mode']?['custom_topics'] ?? [],
      );

      // Convert API format to UI format
      customTopics = rawTopics.map((topic) {
        // API format: 'topic', 'registers' (flat list), 'interval', 'interval_unit'
        final topicName = topic['topic'] ?? topic['topicName'] ?? '';
        final intervalValue = topic['interval'] ?? topic['intervalValue'] ?? 5;
        final intervalUnit =
            topic['interval_unit'] ?? topic['intervalUnit'] ?? 's';

        // Get flat list of register IDs from API
        final flatRegisters = topic['registers'] != null
            ? List<String>.from(topic['registers'] as List? ?? [])
            : [];

        // Store as flat list initially - will be converted to grouped format
        // when CustomTopicCard renders with devicesWithRegisters data
        return {
          'topicName': topicName,
          'selectedRegisters': <String, Set<String>>{},
          'flatRegisters': flatRegisters, // Temporary storage for flat list
          'intervalValue': intervalValue,
          'intervalUnit': intervalUnit,
        };
      }).toList();
    }

    // HTTP (v2.2.0 - interval moved to http_config)
    isEnabledHttp = (config['http_config']?['enabled'] ?? '').toString();
    urlLinkController.text = config['http_config']?['endpoint_url'] ?? '';
    methodRequestSelected = config['http_config']?['method'];
    bodyFormatRequestSelected = config['http_config']?['body_format'];
    timeoutController.text =
        config['http_config']?['timeout']?.toString() ?? '';
    retryController.text = config['http_config']?['retry']?.toString() ?? '';
    httpIntervalController.text =
        config['http_config']?['interval']?.toString() ?? '5';
    httpIntervalUnit = config['http_config']?['interval_unit'] ?? 's';

    for (final controller in headerControllers) {
      controller.dispose();
    }

    headerControllers =
        (config['http_config']?['headers'] as Map<String, dynamic>? ?? {})
            .entries
            .map(
              (entry) => HeaderFieldController(
                key: entry
                    .key, // atau keyController: TextEditingController(text: entry.key)
                value: entry.value
                    .toString(), // sesuaikan dengan class HeaderFieldController lo
              ),
            )
            .toList();

    // Refresh UI
    setState(() {});
  }

  // Convert flat register list to grouped by device
  void _convertFlatRegistersToGrouped() {
    if (devicesWithRegisters.isEmpty || customTopics.isEmpty) return;

    setState(() {
      for (int i = 0; i < customTopics.length; i++) {
        final topic = customTopics[i];
        final flatRegisters = topic['flatRegisters'] as List<dynamic>? ?? [];

        if (flatRegisters.isEmpty) continue;

        // Group registers by device
        final grouped = <String, Set<String>>{};

        for (final registerId in flatRegisters) {
          // Find which device this register belongs to
          for (final device in devicesWithRegisters) {
            final deviceId = device['device_id'] as String?;
            final registers = device['registers'] as List<dynamic>? ?? [];

            // Check if this device has this register
            final hasRegister = registers.any(
              (reg) => reg['register_id'] == registerId,
            );

            if (hasRegister && deviceId != null) {
              grouped.putIfAbsent(deviceId, () => <String>{});
              grouped[deviceId]!.add(registerId as String);
              break; // Found the device, move to next register
            }
          }
        }

        // Update the topic with grouped registers
        customTopics[i]['selectedRegisters'] = grouped;

        AppHelpers.debugLog(
          'Converted topic "${topic['topicName']}": ${flatRegisters.length} registers grouped into ${grouped.length} devices',
        );
      }
    });
  }

  // Fetch devices with registers from API
  Future<void> _fetchDevicesWithRegisters() async {
    if (isLoadingDevices) return;

    setState(() => isLoadingDevices = true);

    try {
      // Try the new endpoint first
      final command = {
        'op': 'read',
        'type': 'devices_with_registers',
        'minimal': true, // Get only register_id + register_name for performance
      };

      final response = await bleController.sendCommand(command);

      AppHelpers.debugLog('Device fetch response status: ${response.status}');
      AppHelpers.debugLog('Device fetch response message: ${response.message}');

      // Check for timeout or error
      if (response.status == 'error') {
        if (response.message?.toLowerCase().contains('timeout') ?? false) {
          AppHelpers.debugLog(
            'Endpoint devices_with_registers timed out - likely not implemented yet',
          );
          return;
        } else {
          AppHelpers.debugLog('Error response: ${response.message}');
          return;
        }
      }

      if (response.status == 'ok' || response.status == 'success') {
        // response.config is now directly a List of devices (thanks to field mapping fix)
        if (response.config != null && response.config is List) {
          final devicesList = List<Map<String, dynamic>>.from(
            response.config as List,
          );

          setState(() {
            devicesWithRegisters = devicesList;
          });

          AppHelpers.debugLog(
            'Successfully fetched ${devicesWithRegisters.length} devices with registers',
          );

          // Convert flat registers to grouped format after devices are loaded
          _convertFlatRegistersToGrouped();
        } else {
          AppHelpers.debugLog(
            'Unexpected response.config format: ${response.config?.runtimeType}',
          );
          setState(() {
            devicesWithRegisters = [];
          });
        }
      } else {
        // Endpoint not supported or error
        AppHelpers.debugLog(
          'devices_with_registers endpoint failed: ${response.message}',
        );
        setState(() {
          devicesWithRegisters = [];
        });
      }
    } catch (e) {
      AppHelpers.debugLog('Error fetching devices with registers: $e');
    } finally {
      setState(() => isLoadingDevices = false);
    }
  }

  void _submit() async {
    if (!_formKey.currentState!.validate()) return;

    // Validate customize mode - check if registers are selected
    if (isEnabledMqtt == 'true' && mqttPublishMode == 'customize') {
      // Check if there are any custom topics
      if (customTopics.isEmpty) {
        SnackbarCustom.showSnackbar(
          'Validation Error',
          'Please add at least one custom topic for customize mode',
          AppColor.redColor,
          AppColor.whiteColor,
        );
        return;
      }

      // Check if each topic has registers selected
      for (int i = 0; i < customTopics.length; i++) {
        final topic = customTopics[i];
        final topicName = topic['topicName'] ?? '';
        final selectedRegisters =
            topic['selectedRegisters'] as Map<String, Set<String>>? ?? {};

        // Check if topic name is empty
        if (topicName.trim().isEmpty) {
          SnackbarCustom.showSnackbar(
            'Validation Error',
            'Topic #${i + 1}: Please enter a topic name',
            AppColor.redColor,
            AppColor.whiteColor,
          );
          return;
        }

        // Count total selected registers across all devices
        int totalRegisters = 0;
        selectedRegisters.forEach((deviceId, registerIds) {
          totalRegisters += registerIds.length;
        });

        // If no registers selected for this topic
        if (totalRegisters == 0) {
          SnackbarCustom.showSnackbar(
            'Incomplete Configuration',
            'Topic "$topicName": Please select at least one register to publish',
            AppColor.redColor,
            AppColor.whiteColor,
          );
          return;
        }
      }
    }

    CustomAlertDialog.show(
      title: "Are you sure?",
      message: "Are you sure you want to save this config?",
      primaryButtonText: 'Yes',
      secondaryButtonText: 'No',
      onPrimaryPressed: () async {
        Get.back();
        controller.isFetching.value = true;

        // Build communication sub-map
        var communication = {"mode": _sanitizeInput(communicationSelected)};

        var wifi = {
          "enabled": isWifiEnabled == 'true',
          "ssid": _sanitizeInput(wifiSsidController.text),
          "password": _sanitizeInput(wifiPasswordController.text),
        };

        var ethernet = {
          "enabled": isEthernetEnabled == 'true',
          "use_dhcp": isUseDhcp == 'true',
          "static_ip": _sanitizeInput(ipAddressController.text),
          "gateway": _sanitizeInput(gatewayController.text),
          "subnet": _sanitizeInput(subnetMaskController.text),
        };

        String fillProtocol;
        if (isEnabledMqtt == 'true' && isEnabledHttp == 'true') {
          fillProtocol = 'both';
        } else if (isEnabledMqtt == 'true') {
          fillProtocol = 'mqtt';
        } else if (isEnabledHttp == 'true') {
          fillProtocol = 'http';
        } else {
          fillProtocol = 'none';
        }

        // MQTT Config with publish mode (v2.2.0 structure)
        var mqttConfig = {
          "enabled": isEnabledMqtt == 'true',
          "broker_address": _sanitizeInput(serverNameController.text),
          "broker_port": portMqttController.intValue ?? 0,
          "client_id": _sanitizeInput(clientIdController.text),
          "username": _sanitizeInput(usernameController.text),
          "password": _sanitizeInput(passwordController.text),
          "keep_alive": keepAliveController.intValue ?? 60,
          "clean_session": cleanSessionSelected == 'true',
          "use_tls": useTlsSelected == 'true',
          "publish_mode": mqttPublishMode,
          "default_mode": {
            "enabled": mqttPublishMode == 'default',
            "topic_publish": _sanitizeInput(publishTopicController.text),
            "topic_subscribe": _sanitizeInput(subscribeTopicController.text),
            "interval": mqttDefaultIntervalController.intValue ?? 5,
            "interval_unit": mqttDefaultIntervalUnit,
          },
          "customize_mode": {
            "enabled": mqttPublishMode == 'customize',
            if (mqttPublishMode == 'customize')
              "topic_subscribe": _sanitizeInput(subscribeTopicController.text),
            if (mqttPublishMode == 'customize')
              "custom_topics": customTopics.map((topic) {
                // Flatten selectedRegisters Map to simple list
                final selectedRegsMap =
                    topic['selectedRegisters'] as Map<String, Set<String>>? ??
                    {};
                final flattenedRegisters = <String>[];
                selectedRegsMap.forEach((deviceId, registerIds) {
                  flattenedRegisters.addAll(registerIds);
                });

                return {
                  "topic": topic['topicName'] ?? '',
                  "registers": flattenedRegisters,
                  "interval": topic['intervalValue'] ?? 5,
                  "interval_unit": topic['intervalUnit'] ?? 's',
                };
              }).toList()
            else
              "custom_topics": [],
          },
        };

        // HTTP Config (v2.2.0 - interval moved here)
        var httpConfig = {
          "enabled": isEnabledHttp == 'true',
          "endpoint_url": _sanitizeInput(urlLinkController.text),
          "method": methodRequestSelected,
          "body_format": bodyFormatRequestSelected,
          "timeout": timeoutController.intValue ?? 0,
          "retry": retryController.intValue ?? 0,
          "interval": httpIntervalController.intValue ?? 5,
          "interval_unit": httpIntervalUnit,
          "headers": {
            for (final c in headerControllers)
              c.keyController.text.trim(): c.valueController.text.trim(),
          },
        };

        // Full command untuk BLE (wrap dengan op dan type)
        var fullConfig = {
          "communication": communication,
          "wifi": wifi,
          "ethernet": ethernet,
          "protocol": fillProtocol,
          "mqtt_config": mqttConfig,
          "http_config": httpConfig,
        };

        try {
          await controller.updateData(widget.model, fullConfig);

          SnackbarCustom.showSnackbar(
            '',
            'Configuration updated, disconnecting in 3 seconds...',
            Colors.green,
            AppColor.whiteColor,
          );

          await Future.delayed(const Duration(seconds: 3));

          try {
            await bleController.disconnectFromDevice(widget.model);

            controller.dataServer.clear();
          } catch (e) {
            AppHelpers.debugLog('Error disconnecting: $e');
            SnackbarCustom.showSnackbar(
              '',
              'Failed to disconnect',
              AppColor.redColor,
              AppColor.whiteColor,
            );
          }

          if (Get.context != null) {
            GoRouter.of(Get.context!).go('/');
          } else {
            AppHelpers.debugLog(
              'Warning: Get.context is null, cannot navigate',
            );
          }
        } catch (e) {
          SnackbarCustom.showSnackbar(
            '',
            'Failed to submit form',
            AppColor.redColor,
            AppColor.whiteColor,
          );
          AppHelpers.debugLog('Error submitting form: $e');
        } finally {
          controller.isFetching.value = false;
        }
      },
      barrierDismissible: false,
    );
  }

  String _sanitizeInput(String input) =>
      input.replaceAll('|', '').replaceAll('#', '');

  List<DropdownItems> typeInterval = [
    DropdownItems(text: 'ms', value: 'ms'),
    DropdownItems(text: 's', value: 's'),
    DropdownItems(text: 'min', value: 'min'),
  ];

  @override
  void dispose() {
    _worker.dispose();

    ipAddressController.dispose();
    gatewayController.dispose();
    subnetMaskController.dispose();
    wifiSsidController.dispose();
    wifiPasswordController.dispose();
    mqttDefaultIntervalController.dispose();
    serverNameController.dispose();
    portMqttController.dispose();
    publishTopicController.dispose();
    subscribeTopicController.dispose();
    clientIdController.dispose();
    urlLinkController.dispose();
    usernameController.dispose();
    passwordController.dispose();
    timeoutController.dispose();
    retryController.dispose();
    httpIntervalController.dispose();
    keepAliveController.dispose();

    for (final controller in headerControllers) {
      controller.dispose();
    }

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Scaffold(
          appBar: _appBar(context),
          backgroundColor: AppColor.backgroundColor,
          body: _body(context),
        ),
        Obx(() {
          return LoadingOverlay(
            isLoading: controller.isFetching.value,
            message: 'Processing request...',
          );
        }),
      ],
    );
  }

  SafeArea _body(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: AppPadding.horizontalMedium,
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppSpacing.md,
              _communicationModeWrapper(context),
              AppSpacing.md,
              _mqttWrapper(),
              AppSpacing.md,
              _httpWrapper(),
              AppSpacing.md,
              GradientButton(
                text: 'Save Server Configuration',
                icon: Icons.save,
                onPressed: _submit,
              ),
              AppSpacing.lg,
            ],
          ),
        ),
      ),
    );
  }

  AppBar _appBar(BuildContext context) {
    return AppBar(
      title: Text(
        'Form Config Server',
        style: context.h5.copyWith(color: AppColor.whiteColor),
      ),
      iconTheme: const IconThemeData(color: AppColor.whiteColor),
      backgroundColor: AppColor.primaryColor,
      centerTitle: true,
    );
  }

  Column _communicationModeWrapper(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionDivider(title: 'Internet settings', icon: Icons.info_outline),
        AppSpacing.md,
        Dropdown(
          items: [
            DropdownItems(text: 'ETH', value: 'ETH'),
            DropdownItems(text: 'WIFI', value: 'WIFI'),
          ],
          label: 'Communication Mode',
          selectedValue: communicationSelected,
          onChanged: (item) {
            setState(() {
              communicationSelected = item!.value;
            });
          },
          isRequired: true,
        ),
        AppSpacing.md,
        Text(
          'Mode: $communicationSelected | Method: Automatic',
          style: context.bodySmall.copyWith(color: AppColor.grey),
        ),
        AppSpacing.md,
        communicationSelected == 'ETH'
            ? _communicationSelectedEthWrapper()
            : _communicationSelectedWifiWrapper(),
      ],
    );
  }

  Column _communicationSelectedEthWrapper() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        Dropdown(
          items: StaticData.booleanOptions,
          label: 'Ethernet Enabled',
          selectedValue: isEthernetEnabled,
          onChanged: (item) {
            setState(() {
              isEthernetEnabled = item!.value;
            });
          },
          isRequired: true,
        ),
        AppSpacing.md,
        Dropdown(
          items: StaticData.booleanOptions,
          label: 'Using DHCP (Automatic IP)',
          selectedValue: isUseDhcp,
          onChanged: (item) {
            setState(() {
              isUseDhcp = item!.value;
            });
          },
          isRequired: true,
        ),
        if (isUseDhcp == 'false') ...[
          AppSpacing.md,
          CustomTextFormField(
            controller: ipAddressController,
            labelTxt: "Static IP",
            hintTxt: "192.168.1.177",
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'IP address is required';
              }
              final ipPattern = RegExp(r'^\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}$');
              if (!ipPattern.hasMatch(value)) return 'Invalid IP format';
              return null;
            },
            isRequired: true,
          ),
          AppSpacing.md,
          CustomTextFormField(
            controller: gatewayController,
            labelTxt: "Gateway",
            hintTxt: "192.168.1.1",
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'IP address is required';
              }
              final ipPattern = RegExp(r'^\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}$');
              if (!ipPattern.hasMatch(value)) return 'Invalid Gateway format';
              return null;
            },
            isRequired: true,
          ),
          AppSpacing.md,
          CustomTextFormField(
            controller: subnetMaskController,
            labelTxt: "Subnet",
            hintTxt: "255.255.255.0",
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'IP address is required';
              }
              final ipPattern = RegExp(r'^\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}$');
              if (!ipPattern.hasMatch(value)) return 'Invalid IP format';
              return null;
            },
            isRequired: true,
          ),
        ],
      ],
    );
  }

  Column _communicationSelectedWifiWrapper() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        Dropdown(
          items: StaticData.booleanOptions,
          label: 'WiFi Enabled',
          selectedValue: isWifiEnabled,
          onChanged: (item) {
            setState(() {
              isWifiEnabled = item!.value;
            });
          },
          isRequired: true,
        ),
        if (isWifiEnabled == 'true') ...[
          AppSpacing.md,
          CustomTextFormField(
            controller: wifiSsidController,
            labelTxt: "WiFi SSID",
            hintTxt: "Enter SSID",
            validator: (value) =>
                value == null || value.isEmpty ? 'SSID is required' : null,
            isRequired: true,
          ),
          AppSpacing.md,
          CustomTextFormField(
            controller: wifiPasswordController,
            labelTxt: "WiFi Password",
            hintTxt: "Enter Password",
            validator: (value) =>
                value == null || value.isEmpty ? 'Password is required' : null,
            obscureText: _passwordVisible,
            isRequired: true,
            suffixIcon: IconButton(
              icon: Icon(
                _passwordVisible ? Icons.visibility : Icons.visibility_off,
                size: 18,
              ),
              onPressed: () {
                setState(() {
                  _passwordVisible = !_passwordVisible;
                });
              },
            ),
          ),
        ],
      ],
    );
  }

  Column _mqttWrapper() {
    return Column(
      children: [
        SectionDivider(
          title: 'MQTT protocol settings',
          icon: Icons.info_outline,
        ),
        AppSpacing.md,
        Dropdown(
          items: StaticData.booleanOptions,
          label: 'Enabled',
          selectedValue: isEnabledMqtt,
          onChanged: (item) {
            setState(() {
              isEnabledMqtt = item!.value;
            });
          },
          isRequired: true,
        ),
        if (isEnabledMqtt == 'true') ...[
          AppSpacing.md,
          CustomTextFormField(
            controller: serverNameController,
            labelTxt: "Broker Address",
            hintTxt: "mqtt.example.com",
            isRequired: true,
          ),
          AppSpacing.md,
          CustomTextFormField(
            controller: portMqttController,
            labelTxt: "Broker Port",
            hintTxt: "1883",
            keyboardType: TextInputType.number,
            isRequired: true,
          ),
          AppSpacing.md,
          CustomTextFormField(
            controller: clientIdController,
            labelTxt: "Client ID",
            hintTxt: "gateway_001",
            isRequired: true,
          ),
          AppSpacing.md,
          CustomTextFormField(
            controller: usernameController,
            labelTxt: "Username",
            hintTxt: "username",
            isRequired: true,
          ),
          AppSpacing.md,
          CustomTextFormField(
            controller: passwordController,
            labelTxt: "Password",
            hintTxt: "password",
            obscureText: _passwordVisible,
            isRequired: true,
            suffixIcon: IconButton(
              icon: Icon(
                _passwordVisible ? Icons.visibility : Icons.visibility_off,
                size: 18,
              ),
              onPressed: () {
                setState(() {
                  _passwordVisible = !_passwordVisible;
                });
              },
            ),
          ),
          AppSpacing.md,
          CustomTextFormField(
            controller: keepAliveController,
            labelTxt: "Keep Alive (s)",
            hintTxt: "60",
            keyboardType: TextInputType.number,
            isRequired: true,
          ),
          AppSpacing.md,
          Dropdown(
            label: 'Clean Session',
            items: StaticData.booleanOptions,
            selectedValue: cleanSessionSelected,
            onChanged: (item) =>
                setState(() => cleanSessionSelected = item!.value),
            isRequired: true,
          ),
          AppSpacing.md,
          Dropdown(
            label: 'Use TLS',
            items: StaticData.booleanOptions,
            selectedValue: useTlsSelected,
            onChanged: (item) => setState(() => useTlsSelected = item!.value),
            isRequired: true,
          ),
          AppSpacing.md,
          // MQTT Publish Mode Selection
          _mqttModeSelectionSection(),
          AppSpacing.sm,
          // Default Mode Fields
          if (mqttPublishMode == 'default') _defaultModeFields(),
          // Customize Mode Fields
          if (mqttPublishMode == 'customize') _customizeModeFields(),
        ],
      ],
    );
  }

  // MQTT Mode Selection - Enhanced with Toggle Cards
  Widget _mqttModeSelectionSection() {
    return Column(
      children: [
        MqttModeToggleCard(
          title: 'Default Mode',
          description: 'Use single topic for all data with standard format',
          icon: Icons.layers_outlined,
          isEnabled: mqttPublishMode == 'default',
          onChanged: (enabled) {
            if (enabled) {
              setState(() => mqttPublishMode = 'default');
            }
          },
        ),
        const SizedBox(height: 8),
        MqttModeToggleCard(
          title: 'Customize Mode',
          description:
              'Create multiple topics with specific devices & registers',
          icon: Icons.tune,
          isEnabled: mqttPublishMode == 'customize',
          onChanged: (enabled) {
            if (enabled) {
              setState(() => mqttPublishMode = 'customize');
              // Lazy load: Only fetch devices when user switches to customize mode
              if (devicesWithRegisters.isEmpty && !isLoadingDevices) {
                _fetchDevicesWithRegisters();
              }
            }
          },
        ),
      ],
    );
  }

  // Default Mode Fields - Redesigned (v2.2.0 with interval)
  Widget _defaultModeFields() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CustomTextFormField(
          controller: publishTopicController,
          labelTxt: "Publish Topic",
          hintTxt: "v1/devices/me/telemetry",
          isRequired: true,
        ),
        AppSpacing.md,
        CustomTextFormField(
          controller: subscribeTopicController,
          labelTxt: "Subscribe Topic",
          hintTxt: "device/control (optional)",
        ),
        AppSpacing.md,
        // Publish Interval for Default Mode (v2.2.0)
        Row(
          children: [
            Expanded(
              flex: 1,
              child: CustomTextFormField(
                controller: mqttDefaultIntervalController,
                labelTxt: "Publish Interval - Value",
                hintTxt: "5",
                keyboardType: TextInputType.number,
                validator: (value) =>
                    value == null || value.isEmpty ? 'Value is required' : null,
              ),
            ),
            AppSpacing.md,
            Expanded(
              flex: 1,
              child: Dropdown(
                label: 'Unit',
                items: typeInterval,
                selectedValue: mqttDefaultIntervalUnit,
                onChanged: (item) =>
                    setState(() => mqttDefaultIntervalUnit = item!.value),
                isRequired: true,
              ),
            ),
          ],
        ),
        AppSpacing.sm,
        Text(
          '💡 ms: milliseconds, s: seconds, min: minutes',
          style: context.bodySmall.copyWith(color: AppColor.grey),
        ),
      ],
    );
  }

  // Customize Mode Fields - Enhanced with Device Selection
  Widget _customizeModeFields() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Custom Topics',
              style: context.body.copyWith(
                fontWeight: FontWeight.bold,
                color: AppColor.blackColor,
              ),
            ),
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: _addCustomTopic,
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppColor.primaryColor,
                        AppColor.primaryColor.withValues(alpha: 0.8),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [
                      BoxShadow(
                        color: AppColor.primaryColor.withValues(alpha: 0.3),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.add_circle_outline,
                        size: 18,
                        color: AppColor.whiteColor,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Add Topic',
                        style: context.bodySmall.copyWith(
                          color: AppColor.whiteColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
        AppSpacing.md,
        // Loading State
        if (isLoadingDevices)
          Container(
            padding: const EdgeInsets.all(24),
            width: double.infinity,
            decoration: BoxDecoration(
              color: AppColor.primaryColor.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppColor.primaryColor.withValues(alpha: 0.2),
                width: 1,
              ),
            ),
            child: Column(
              children: [
                CircularProgressIndicator(
                  color: AppColor.primaryColor,
                  strokeWidth: 2,
                ),
                const SizedBox(height: 16),
                Text(
                  'Loading devices and registers...',
                  style: context.bodySmall.copyWith(
                    color: AppColor.grey,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          )
        // Empty State - No Topics Yet
        else if (customTopics.isEmpty)
          Container(
            padding: const EdgeInsets.all(20),
            width: double.infinity,
            decoration: BoxDecoration(
              color: AppColor.grey.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppColor.grey.withValues(alpha: 0.2),
                width: 1,
              ),
            ),
            child: Column(
              children: [
                Icon(
                  Icons.topic_outlined,
                  size: 48,
                  color: AppColor.grey.withValues(alpha: 0.5),
                ),
                AppSpacing.sm,
                Text(
                  'No custom topics yet',
                  style: context.bodySmall.copyWith(
                    color: AppColor.grey,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                AppSpacing.xs,
                Text(
                  'Tap "Add Topic" to create your first custom topic',
                  style: context.bodySmall.copyWith(
                    color: AppColor.grey,
                    fontSize: 10,
                  ),
                  textAlign: TextAlign.center,
                ),
                // Show retry button if devices fetch failed
                if (devicesWithRegisters.isEmpty) ...[
                  AppSpacing.md,
                  TextButton.icon(
                    onPressed: _fetchDevicesWithRegisters,
                    icon: Icon(
                      Icons.refresh,
                      size: 16,
                      color: AppColor.primaryColor,
                    ),
                    label: Text(
                      'Retry Loading Devices',
                      style: context.bodySmall.copyWith(
                        color: AppColor.primaryColor,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          )
        else ...[
          // Info banner if devices not available
          if (devicesWithRegisters.isEmpty) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: Colors.orange.withValues(alpha: 0.3),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, size: 16, color: Colors.orange),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Device list unavailable',
                          style: context.bodySmall.copyWith(
                            color: Colors.orange.withValues(alpha: 0.9),
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Topics created without device selection. You can retry loading devices.',
                          style: context.bodySmall.copyWith(
                            color: Colors.orange.withValues(alpha: 0.8),
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 4),
                  IconButton(
                    onPressed: _fetchDevicesWithRegisters,
                    icon: Icon(Icons.refresh, size: 18, color: Colors.orange),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    tooltip: 'Retry',
                  ),
                ],
              ),
            ),
            AppSpacing.sm,
          ],
          // Topic Cards
          ...customTopics.asMap().entries.map((entry) {
            final index = entry.key;
            final topic = entry.value;

            return CustomTopicCard(
              index: index,
              topicName: topic['topicName'] ?? '',
              intervalValue: topic['intervalValue'] ?? 5,
              intervalUnit: topic['intervalUnit'] ?? 's',
              selectedRegisters: Map<String, Set<String>>.from(
                (topic['selectedRegisters'] as Map<String, dynamic>? ?? {}).map(
                  (key, value) {
                    // Handle both Set and List types
                    if (value is Set<String>) {
                      return MapEntry(key, value);
                    } else if (value is Set) {
                      return MapEntry(key, Set<String>.from(value));
                    } else {
                      return MapEntry(key, Set<String>.from(value as List));
                    }
                  },
                ),
              ),
              devicesWithRegisters: devicesWithRegisters,
              onTopicChanged: (updatedData) {
                setState(() {
                  customTopics[index] = updatedData;
                });
              },
              onRemove: () => _removeCustomTopic(index),
              canRemove: customTopics.length > 1 || customTopics.isNotEmpty,
            );
          }),
        ],
      ],
    );
  }

  // Add Custom Topic
  void _addCustomTopic() {
    setState(() {
      customTopics.add({
        'topicName': '',
        'selectedRegisters': <String, Set<String>>{},
        'intervalValue': 5,
        'intervalUnit': 's',
      });
    });
  }

  // Remove Custom Topic
  void _removeCustomTopic(int index) {
    setState(() {
      customTopics.removeAt(index);
    });
  }

  Widget _httpWrapper() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionDivider(
          title: 'HTTP protocol settings',
          icon: Icons.info_outline,
        ),
        AppSpacing.md,
        Dropdown(
          items: StaticData.booleanOptions,
          label: 'Enabled',
          selectedValue: isEnabledHttp,
          onChanged: (item) {
            setState(() {
              isEnabledHttp = item!.value;
            });
          },
          isRequired: true,
        ),
        if (isEnabledHttp == 'true') ...[
          AppSpacing.md,
          CustomTextFormField(
            controller: urlLinkController,
            labelTxt: "Endpoint URL",
            hintTxt: "https://api.example.com",
            isRequired: true,
          ),
          AppSpacing.md,
          Dropdown(
            label: 'Method',
            items: [
              DropdownItems(text: 'POST', value: 'POST'),
              DropdownItems(text: 'GET', value: 'GET'),
              DropdownItems(text: 'PUT', value: 'PUT'),
              DropdownItems(text: 'DELETE', value: 'DELETE'),
            ],
            selectedValue: methodRequestSelected,
            onChanged: (item) =>
                setState(() => methodRequestSelected = item!.value),
            isRequired: true,
          ),
          AppSpacing.md,
          Dropdown(
            label: 'Body Format',
            items: [
              DropdownItems(text: 'json', value: 'json'),
              DropdownItems(text: 'form', value: 'form'),
              DropdownItems(text: 'raw', value: 'raw'),
            ],
            selectedValue: bodyFormatRequestSelected,
            onChanged: (item) =>
                setState(() => bodyFormatRequestSelected = item!.value),
            isRequired: true,
          ),
          AppSpacing.md,
          CustomTextFormField(
            controller: timeoutController,
            labelTxt: "Timeout (ms)",
            keyboardType: TextInputType.number,
            hintTxt: "15000",
          ),
          AppSpacing.md,
          CustomTextFormField(
            controller: retryController,
            labelTxt: "Retry Count",
            keyboardType: TextInputType.number,
            hintTxt: "5",
          ),
          AppSpacing.md,
          // HTTP Publish Interval (v2.2.0 - moved from root data_interval)
          Row(
            children: [
              Expanded(
                flex: 1,
                child: CustomTextFormField(
                  controller: httpIntervalController,
                  labelTxt: "Publish Interval - Value",
                  hintTxt: "5",
                  keyboardType: TextInputType.number,
                  validator: (value) => value == null || value.isEmpty
                      ? 'Value is required'
                      : null,
                ),
              ),
              AppSpacing.md,
              Expanded(
                flex: 1,
                child: Dropdown(
                  label: 'Unit',
                  items: typeInterval,
                  selectedValue: httpIntervalUnit,
                  onChanged: (item) =>
                      setState(() => httpIntervalUnit = item!.value),
                  isRequired: true,
                ),
              ),
            ],
          ),
          AppSpacing.sm,
          Text(
            '💡 ms: milliseconds, s: seconds, min: minutes',
            style: context.bodySmall.copyWith(color: AppColor.grey),
          ),
          AppSpacing.md,
          MultiHeaderForm(
            controllers: headerControllers,
            title: 'Custom Headers',
            onChanged: () {
              setState(() {});
            },
          ),
        ],
      ],
    );
  }
}
