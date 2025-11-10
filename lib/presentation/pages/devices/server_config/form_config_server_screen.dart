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

  String selectedIntervalType = 'ms';
  String cleanSessionSelected = 'true';
  String useTlsSelected = 'false';

  // MQTT Mode: 'default' or 'customize'
  String mqttPublishMode = 'default';

  // Custom topics for customize mode
  List<Map<String, dynamic>> customTopics = [];

  // TextEditingControllers
  final ipAddressController = TextEditingController();
  final gatewayController = TextEditingController();
  final subnetMaskController = TextEditingController();
  final wifiSsidController = TextEditingController();
  final wifiPasswordController = TextEditingController();
  final intervalTimeController = TextEditingController(text: '1000');
  final serverNameController = TextEditingController();
  final portMqttController = TextEditingController(text: '1883');
  final publishTopicController = TextEditingController();
  final subscribeTopicController = TextEditingController();
  final keepAliveController = TextEditingController(text: '60');
  final clientIdController = TextEditingController();
  final urlLinkController = TextEditingController();
  final timeoutController = TextEditingController(text: '5000');
  final retryController = TextEditingController(text: '3');
  final usernameController = TextEditingController();
  final passwordController = TextEditingController();

  late List<HeaderFieldController> headerControllers = [
    HeaderFieldController(key: '', value: ''),
  ];

  @override
  void initState() {
    super.initState();
    // Listen to dataDevice GetX observable, update form when fetch finished
    _worker = ever(controller.dataServer, (dataList) {
      if (!mounted) return;
      if (dataList.isNotEmpty) {
        updateFormFields(dataList[0]);
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
    isEthernetEnabled = (config['ethernet']?['enabled'] ?? '').toString();
    isUseDhcp = (config['ethernet']?['use_dhcp'] ?? '').toString();
    ipAddressController.text = config['ethernet']?['static_ip'] ?? '';
    gatewayController.text = config['ethernet']?['gateway'] ?? '';
    subnetMaskController.text = config['ethernet']?['subnet'] ?? '';

    // Interval
    intervalTimeController.text =
        config['data_interval']?['value']?.toString() ?? '';
    selectedIntervalType = config['data_interval']?['unit'] ?? 'ms';

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
    publishTopicController.text = config['mqtt_config']?['topic_publish'] ?? '';
    subscribeTopicController.text =
        config['mqtt_config']?['topic_subscribe'] ?? '';

    // Customize Mode
    if (config['mqtt_config']?['custom_topics'] != null) {
      customTopics = List<Map<String, dynamic>>.from(
        config['mqtt_config']?['custom_topics'] ?? [],
      );
    }

    // HTTP
    isEnabledHttp = (config['http_config']?['enabled'] ?? '').toString();
    urlLinkController.text = config['http_config']?['endpoint_url'] ?? '';
    methodRequestSelected = config['http_config']?['method'];
    bodyFormatRequestSelected = config['http_config']?['body_format'];
    timeoutController.text =
        config['http_config']?['timeout']?.toString() ?? '';
    retryController.text = config['http_config']?['retry']?.toString() ?? '';
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

  void _submit() async {
    if (!_formKey.currentState!.validate()) return;

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

        // Interval
        var dataInterval = {
          "value": _tryParseInt(intervalTimeController.text) ?? 0,
          "unit": selectedIntervalType,
        };

        // MQTT Config with publish mode
        var mqttConfig = {
          "enabled": isEnabledMqtt == 'true',
          "broker_address": _sanitizeInput(serverNameController.text),
          "broker_port": _tryParseInt(portMqttController.text) ?? 0,
          "client_id": _sanitizeInput(clientIdController.text),
          "username": _sanitizeInput(usernameController.text),
          "password": _sanitizeInput(passwordController.text),
          "keep_alive": _tryParseInt(keepAliveController.text) ?? 60,
          "clean_session": cleanSessionSelected == 'true',
          "use_tls": useTlsSelected == 'true',
          "publish_mode": mqttPublishMode,
          "topic_publish": _sanitizeInput(publishTopicController.text),
          "topic_subscribe": _sanitizeInput(subscribeTopicController.text),
          if (mqttPublishMode == 'customize')
            "custom_topics": customTopics.map((topic) {
              return {
                "topic": topic['topic'] ?? '',
                "registers": topic['registers'] ?? [],
                "interval": topic['interval'] ?? 5,
                "interval_unit": topic['interval_unit'] ?? 's',
              };
            }).toList(),
        };

        var httpConfig = {
          "enabled": isEnabledHttp == 'true',
          "endpoint_url": _sanitizeInput(urlLinkController.text),
          "method": methodRequestSelected,
          "body_format": bodyFormatRequestSelected,
          "timeout": _tryParseInt(timeoutController.text) ?? 0,
          "retry": _tryParseInt(retryController.text) ?? 0,
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
          "data_interval": dataInterval,
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

  int? _tryParseInt(String? value, {int? defaultValue}) {
    if (value == null || value.isEmpty) return defaultValue;
    return int.tryParse(value) ?? defaultValue;
  }

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
    intervalTimeController.dispose();
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
    keepAliveController.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Scaffold(appBar: _appBar(context), body: _body(context)),
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
              _dataInterval(context),
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

  Column _dataInterval(BuildContext context) {
    return Column(
      children: [
        SectionDivider(title: 'Data Interval Config', icon: Icons.info_outline),
        AppSpacing.md,
        CustomTextFormField(
          controller: intervalTimeController,
          labelTxt: "Data Interval - Value",
          hintTxt: "5000",
          keyboardType: TextInputType.number,
          validator: (value) =>
              value == null || value.isEmpty ? 'Value is required' : null,
        ),
        AppSpacing.md,
        Dropdown(
          label: 'Data Interval - Unit',
          items: typeInterval,
          selectedValue: selectedIntervalType,
          onChanged: (item) =>
              setState(() => selectedIntervalType = item!.value),
          isRequired: true,
        ),
        AppSpacing.sm,
        Text(
          's: seconds, m: minutes, ms: milliseconds',
          style: context.bodySmall.copyWith(color: AppColor.grey),
        ),
      ],
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

  // MQTT Mode Selection - Compact Tab Style
  Widget _mqttModeSelectionSection() {
    return Container(
      decoration: BoxDecoration(
        color: AppColor.grey.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      padding: const EdgeInsets.all(4),
      child: Row(
        children: [
          Expanded(
            child: _compactModeTab(
              label: 'Default',
              icon: Icons.layers_outlined,
              isSelected: mqttPublishMode == 'default',
              onTap: () => setState(() => mqttPublishMode = 'default'),
            ),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: _compactModeTab(
              label: 'Custom',
              icon: Icons.tune,
              isSelected: mqttPublishMode == 'customize',
              onTap: () => setState(() => mqttPublishMode = 'customize'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _compactModeTab({
    required String label,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
        decoration: BoxDecoration(
          color: isSelected ? AppColor.primaryColor : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 18,
              color: isSelected ? AppColor.whiteColor : AppColor.grey,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: context.bodySmall.copyWith(
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: isSelected ? AppColor.whiteColor : AppColor.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Default Mode Fields - Redesigned
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
      ],
    );
  }

  // Customize Mode Fields - Compact
  Widget _customizeModeFields() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Topics',
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
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: AppColor.primaryColor,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.add,
                        size: 16,
                        color: AppColor.whiteColor,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Add',
                        style: context.bodySmall.copyWith(
                          color: AppColor.whiteColor,
                          fontWeight: FontWeight.w600,
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
        if (customTopics.isEmpty) ...[
          AppSpacing.sm,
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColor.grey.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: AppColor.grey.withValues(alpha: 0.2),
                style: BorderStyle.solid,
              ),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, size: 16, color: AppColor.grey),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'No topics yet. Tap "Add" to create one.',
                    style: context.bodySmall.copyWith(
                      color: AppColor.grey,
                      fontSize: 11,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
        if (customTopics.isNotEmpty) ...[
          AppSpacing.sm,
          ...customTopics.asMap().entries.map((entry) {
            final index = entry.key;
            final topic = entry.value;
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _customTopicCard(index, topic),
            );
          }),
        ],
      ],
    );
  }

  // Custom Topic Card - Compact
  Widget _customTopicCard(int index, Map<String, dynamic> topic) {
    final topicController = TextEditingController(text: topic['topic'] ?? '');
    final selectedRegisters = List<int>.from(topic['registers'] ?? []);

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColor.whiteColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColor.grey.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Compact Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColor.primaryColor,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  '#${index + 1}',
                  style: context.bodySmall.copyWith(
                    color: AppColor.whiteColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 11,
                  ),
                ),
              ),
              const Spacer(),
              InkWell(
                onTap: () => _removeCustomTopic(index),
                borderRadius: BorderRadius.circular(4),
                child: Padding(
                  padding: const EdgeInsets.all(4),
                  child: Icon(Icons.close, size: 16, color: AppColor.grey),
                ),
              ),
            ],
          ),
          AppSpacing.sm,
          // Compact Topic Field
          CustomTextFormField(
            controller: topicController,
            labelTxt: "Topic",
            hintTxt: "e.g., sensor/temp",
            onChanges: (value) {
              topic['topic'] = value;
            },
          ),
          AppSpacing.sm,
          // Compact Register Selection
          Text(
            'Registers',
            style: context.bodySmall.copyWith(
              fontWeight: FontWeight.w600,
              fontSize: 11,
            ),
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 4,
            runSpacing: 4,
            children: List.generate(10, (regIndex) {
              final regNumber = regIndex + 1;
              final isSelected = selectedRegisters.contains(regNumber);
              return InkWell(
                onTap: () {
                  setState(() {
                    if (isSelected) {
                      selectedRegisters.remove(regNumber);
                    } else {
                      selectedRegisters.add(regNumber);
                    }
                    topic['registers'] = selectedRegisters;
                  });
                },
                borderRadius: BorderRadius.circular(6),
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColor.primaryColor
                        : AppColor.grey.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: isSelected
                          ? AppColor.primaryColor
                          : AppColor.grey.withValues(alpha: 0.25),
                      width: isSelected ? 1.5 : 1,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      '$regNumber',
                      style: context.bodySmall.copyWith(
                        color: isSelected
                            ? AppColor.whiteColor
                            : AppColor.blackColor,
                        fontWeight: FontWeight.w600,
                        fontSize: 11,
                      ),
                    ),
                  ),
                ),
              );
            }),
          ),
          if (selectedRegisters.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              '${selectedRegisters.length} selected',
              style: context.bodySmall.copyWith(
                color: AppColor.primaryColor,
                fontWeight: FontWeight.w600,
                fontSize: 10,
              ),
            ),
          ],
        ],
      ),
    );
  }

  // Add Custom Topic
  void _addCustomTopic() {
    setState(() {
      customTopics.add({
        'topic': '',
        'registers': <int>[],
        'interval': 5,
        'interval_unit': 's',
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
        AppSpacing.md,
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
