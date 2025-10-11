// ignore_for_file: prefer_const_literals_to_create_immutables, prefer_const_constructors

import 'package:flutter/material.dart';
import 'package:gateway_config/core/constants/app_color.dart';
import 'package:gateway_config/core/constants/app_gap.dart';
import 'package:gateway_config/core/controllers/ble_controller.dart';
import 'package:gateway_config/core/controllers/server_config_controller.dart';
import 'package:gateway_config/core/utils/app_helpers.dart';
import 'package:gateway_config/core/utils/extensions.dart';
import 'package:gateway_config/core/utils/snackbar_custom.dart';
import 'package:gateway_config/models/device_model.dart';
import 'package:gateway_config/models/dropdown_items.dart';
import 'package:gateway_config/presentation/widgets/common/custom_alert_dialog.dart';
import 'package:gateway_config/presentation/widgets/common/custom_button.dart';
import 'package:gateway_config/presentation/widgets/common/custom_radiotile.dart';
import 'package:gateway_config/presentation/widgets/common/custom_textfield.dart';
import 'package:gateway_config/presentation/widgets/common/dropdown.dart';
import 'package:gateway_config/presentation/widgets/common/loading_overlay.dart';
import 'package:gateway_config/presentation/widgets/spesific/title_tile.dart';
import 'package:get/get.dart';

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

  // State variables
  String protocolSelected = 'mqtt';
  String communicationSelected = 'ETH'; // ETH or WIFI
  String connectionMethod =
      'Automatic'; // Automatic or Manual, berlaku untuk ETH/WIFI
  String selectedIntervalType = 'ms';
  String cleanSessionSelected = 'true';
  String useTlsSelected = 'true';

  // TextEditingControllers
  final ipAddressController = TextEditingController();
  final macAddressController = TextEditingController();
  final wifiSsidController = TextEditingController();
  final wifiPasswordController = TextEditingController();
  final intervalTimeController = TextEditingController();
  final serverNameController = TextEditingController();
  final portMqttController = TextEditingController();
  final publishTopicController = TextEditingController();
  final subscribeTopicController = TextEditingController();
  final keepAliveController = TextEditingController();
  final clientIdController = TextEditingController();
  final urlLinkController = TextEditingController();
  final methodRequestController = TextEditingController(text: 'POST');
  final timeoutController = TextEditingController();
  final retryController = TextEditingController();
  final usernameController = TextEditingController();
  final passwordController = TextEditingController();
  final authorizationController = TextEditingController();
  final xCustomHeaderController = TextEditingController();
  final contentTypeController = TextEditingController(text: 'application/json');
  final bodyFormatController = TextEditingController(text: 'json');

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
    // Communication
    communicationSelected = config['communication']?['mode'] ?? 'ETH';
    connectionMethod =
        config['communication']?['connection_mode'] ?? 'Automatic';
    ipAddressController.text = config['communication']?['ip_address'] ?? '';
    macAddressController.text = config['communication']?['mac_address'] ?? '';
    wifiSsidController.text = config['communication']?['wifi']?['ssid'] ?? '';
    wifiPasswordController.text =
        config['communication']?['wifi']?['password'] ?? '';

    // Protocol
    protocolSelected = config['protocol'] ?? 'mqtt';

    // Interval
    intervalTimeController.text =
        config['data_interval']?['value']?.toString() ?? '';
    selectedIntervalType = config['data_interval']?['unit'] ?? 'ms';

    // MQTT
    serverNameController.text = config['mqtt_config']?['broker_address'] ?? '';
    portMqttController.text =
        config['mqtt_config']?['broker_port']?.toString() ?? '';
    clientIdController.text = config['mqtt_config']?['client_id'] ?? '';
    usernameController.text = config['mqtt_config']?['username'] ?? '';
    passwordController.text = config['mqtt_config']?['password'] ?? '';
    publishTopicController.text = config['mqtt_config']?['topic_publish'] ?? '';
    subscribeTopicController.text =
        config['mqtt_config']?['topic_subscribe'] ?? '';
    keepAliveController.text =
        config['mqtt_config']?['keep_alive']?.toString() ?? '';
    cleanSessionSelected = (config['mqtt_config']?['clean_session'] ?? '')
        .toString();
    useTlsSelected = (config['mqtt_config']?['use_tls'] ?? '').toString();

    // HTTP
    urlLinkController.text = config['http_config']?['endpoint_url'] ?? '';
    methodRequestController.text = config['http_config']?['method'] ?? 'POST';
    authorizationController.text =
        config['http_config']?['headers']?['Authorization'] ?? '';
    xCustomHeaderController.text =
        config['http_config']?['headers']?['X-Custom-Header'] ?? '';
    contentTypeController.text =
        config['http_config']?['headers']?['Content-Type'] ??
        'application/json';
    bodyFormatController.text = config['http_config']?['body_format'] ?? 'json';
    timeoutController.text =
        config['http_config']?['timeout']?.toString() ?? '';
    retryController.text = config['http_config']?['retry']?.toString() ?? '';

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
        await Future.delayed(const Duration(seconds: 1));

        // Build communication sub-map
        var communication = {
          "mode": _sanitizeInput(communicationSelected),
          "connection_mode": _sanitizeInput(connectionMethod),
          "ip_address": _sanitizeInput(ipAddressController.text),
          "mac_address": _sanitizeInput(macAddressController.text),
          if (communicationSelected == 'WIFI')
            "wifi": {
              "ssid": _sanitizeInput(wifiSsidController.text),
              "password": _sanitizeInput(wifiPasswordController.text),
            },
        };

        // Interval
        var dataInterval = {
          "value": _tryParseInt(intervalTimeController.text) ?? 0,
          "unit": selectedIntervalType,
        };

        // MQTT Config
        var mqttConfig = {
          "enabled": protocolSelected == 'mqtt',
          "broker_address": _sanitizeInput(serverNameController.text),
          "broker_port": _tryParseInt(portMqttController.text) ?? 0,
          "client_id": _sanitizeInput(clientIdController.text),
          "username": _sanitizeInput(usernameController.text),
          "password": _sanitizeInput(passwordController.text),
          "topic_publish": _sanitizeInput(publishTopicController.text),
          "topic_subscribe": _sanitizeInput(subscribeTopicController.text),
          "keep_alive": _tryParseInt(keepAliveController.text) ?? 60,
          "clean_session": cleanSessionSelected == 'true',
          "use_tls": useTlsSelected == 'true',
        };

        // HTTP Config
        var httpHeaders = {
          "Authorization": _sanitizeInput(authorizationController.text),
          "Content-Type": _sanitizeInput(contentTypeController.text),
        };
        if (xCustomHeaderController.text.isNotEmpty) {
          httpHeaders["X-Custom-Header"] = _sanitizeInput(
            xCustomHeaderController.text,
          );
        }
        var httpConfig = {
          "enabled": protocolSelected == 'http',
          "endpoint_url": _sanitizeInput(urlLinkController.text),
          "method": _sanitizeInput(methodRequestController.text),
          "headers": httpHeaders,
          "body_format": _sanitizeInput(bodyFormatController.text),
          "timeout": _tryParseInt(timeoutController.text) ?? 0,
          "retry": _tryParseInt(retryController.text) ?? 0,
        };

        // Full command untuk BLE (wrap dengan op dan type)
        var fullConfig = {
          "communication": communication,
          "protocol": protocolSelected,
          "data_interval": dataInterval,
          "mqtt_config": mqttConfig,
          "http_config": httpConfig,
        };

        try {
          controller.updateData(widget.model, fullConfig);
        } catch (e) {
          SnackbarCustom.showSnackbar(
            '',
            'Failed to submit form',
            AppColor.redColor,
            AppColor.whiteColor,
          );
          AppHelpers.debugLog('Error submitting form: $e');
        } finally {
          await Future.delayed(const Duration(seconds: 8));
          AppHelpers.backNTimes(1);
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

  @override
  void dispose() {
    _worker.dispose();

    ipAddressController.dispose();
    macAddressController.dispose();
    wifiSsidController.dispose();
    wifiPasswordController.dispose();
    intervalTimeController.dispose();
    serverNameController.dispose();
    portMqttController.dispose();
    publishTopicController.dispose();
    subscribeTopicController.dispose();
    clientIdController.dispose();
    urlLinkController.dispose();
    methodRequestController.dispose();
    usernameController.dispose();
    passwordController.dispose();
    authorizationController.dispose();
    xCustomHeaderController.dispose();
    contentTypeController.dispose();
    bodyFormatController.dispose();
    timeoutController.dispose();
    retryController.dispose();
    keepAliveController.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    List<DropdownItems> typeInterval = [
      DropdownItems(text: 's', value: 's'),
      DropdownItems(text: 'm', value: 'm'),
      DropdownItems(text: 'ms', value: 'ms'),
    ];

    return Stack(
      children: [
        Scaffold(appBar: _appBar(context), body: _body(context, typeInterval)),
        Obx(() {
          return LoadingOverlay(
            isLoading: controller.isFetching.value,
            message: 'Processing request...',
          );
        }),
      ],
    );
  }

  SafeArea _body(BuildContext context, List<DropdownItems> typeInterval) {
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
              AppSpacing.sm,
              _connectionFields(),
              AppSpacing.md,
              _protocolWrapper(),
              AppSpacing.md,
              _intervalWrapper(context, typeInterval),
              AppSpacing.md,
              _mqttField(),
              _httpField(),
              AppSpacing.md,
              Button(
                width: MediaQuery.of(context).size.width,
                onPressed: _submit,
                text: 'Save',
                height: 50,
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
        const TitleTile(title: 'Choose Communication Mode'),
        AppSpacing.sm,
        Text(
          'ETH: Ethernet, WIFI: WiFi',
          style: context.bodySmall.copyWith(color: AppColor.grey),
        ),
        CustomRadioTile(
          value: "ETH",
          grupValue: communicationSelected,
          onChanges: () {
            setState(() => communicationSelected = "ETH");
            _chooseConnectionMethod(context);
          },
        ),
        CustomRadioTile(
          value: "WIFI",
          grupValue: communicationSelected,
          onChanges: () {
            setState(() => communicationSelected = "WIFI");
            _chooseConnectionMethod(context);
          },
        ),
      ],
    );
  }

  Future<dynamic> _chooseConnectionMethod(BuildContext context) {
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Choose Connection Method", style: context.h5),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Automatic (DHCP) or Manual (Static IP)',
              style: context.bodySmall.copyWith(color: AppColor.grey),
            ),
            AppSpacing.sm,
            CustomRadioTile(
              value: "Automatic",
              grupValue: connectionMethod,
              onChanges: () {
                setState(() => connectionMethod = "Automatic");
                Navigator.pop(context);
              },
            ),
            CustomRadioTile(
              value: "Manual",
              grupValue: connectionMethod,
              onChanges: () {
                setState(() => connectionMethod = "Manual");
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _connectionFields() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Mode: $communicationSelected | Method: $connectionMethod',
          style: context.bodySmall.copyWith(color: AppColor.grey),
        ),
        AppSpacing.sm,
        CustomTextFormField(
          controller: ipAddressController,
          labelTxt: "IP Address",
          hintTxt: "192.168.0.2",
          validator: (value) {
            if (value == null || value.isEmpty) return 'IP address is required';
            final ipPattern = RegExp(r'^\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}$');
            if (!ipPattern.hasMatch(value)) return 'Invalid IP format';
            return null;
          },
          isRequired: true,
        ),
        AppSpacing.md,
        CustomTextFormField(
          controller: macAddressController,
          labelTxt: "MAC Address",
          hintTxt: "00:1A:2B:3C:4D:5E",
          validator: (value) =>
              value == null || value.isEmpty ? 'MAC Address is required' : null,
          isRequired: true,
        ),
        if (communicationSelected == 'WIFI') ...[
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
            isRequired: true,
          ),
        ],
        AppSpacing.md,
      ],
    );
  }

  Column _protocolWrapper() {
    return Column(
      children: [
        const TitleTile(title: 'Choose Protocol'),
        AppSpacing.sm,
        CustomRadioTile(
          value: "mqtt",
          grupValue: protocolSelected,
          onChanges: () => setState(() => protocolSelected = "mqtt"),
        ),
        CustomRadioTile(
          value: "http",
          grupValue: protocolSelected,
          onChanges: () => setState(() => protocolSelected = "http"),
        ),
      ],
    );
  }

  Column _intervalWrapper(
    BuildContext context,
    List<DropdownItems> typeInterval,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TitleTile(title: 'Data Interval'),
        AppSpacing.sm,
        Text(
          's: seconds, m: minutes, ms: milliseconds',
          style: context.bodySmall.copyWith(color: AppColor.grey),
        ),
        AppSpacing.sm,
        CustomTextFormField(
          controller: intervalTimeController,
          labelTxt: "Interval Value",
          hintTxt: "5000",
          keyboardType: TextInputType.number,
          validator: (value) =>
              value == null || value.isEmpty ? 'Value is required' : null,
        ),
        AppSpacing.sm,
        Dropdown(
          label: 'Unit',
          items: typeInterval,
          selectedValue: selectedIntervalType,
          onChanged: (item) =>
              setState(() => selectedIntervalType = item!.value),
          isRequired: true,
        ),
      ],
    );
  }

  Widget _mqttField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TitleTile(title: "Setup MQTT Connection"),
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
          obscureText: true,
          isRequired: true,
        ),
        AppSpacing.md,
        CustomTextFormField(
          controller: publishTopicController,
          labelTxt: "Publish Topic",
          hintTxt: "data/topic",
          isRequired: true,
        ),
        AppSpacing.md,
        CustomTextFormField(
          controller: subscribeTopicController,
          labelTxt: "Subscribe Topic",
          hintTxt: "control/topic",
          isRequired: true,
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
          items: [
            DropdownItems(text: 'true', value: 'true'),
            DropdownItems(text: 'false', value: 'false'),
          ],
          selectedValue: cleanSessionSelected,
          onChanged: (item) =>
              setState(() => cleanSessionSelected = item!.value),
          isRequired: true,
        ),
        AppSpacing.md,
        Dropdown(
          label: 'Use TLS',
          items: [
            DropdownItems(text: 'true', value: 'true'),
            DropdownItems(text: 'false', value: 'false'),
          ],
          selectedValue: useTlsSelected,
          onChanged: (item) => setState(() => useTlsSelected = item!.value),
          isRequired: true,
        ),
        AppSpacing.lg,
      ],
    );
  }

  Widget _httpField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TitleTile(title: "Setup HTTP Connection"),
        AppSpacing.md,
        CustomTextFormField(
          controller: urlLinkController,
          labelTxt: "Endpoint URL",
          hintTxt: "https://api.example.com",
          isRequired: true,
        ),
        AppSpacing.md,
        CustomTextFormField(
          controller: methodRequestController,
          labelTxt: "Method",
          readOnly: true,
        ),
        AppSpacing.md,
        CustomTextFormField(
          controller: authorizationController,
          labelTxt: "Authorization",
          hintTxt: "Bearer token",
        ),
        AppSpacing.md,
        CustomTextFormField(
          controller: xCustomHeaderController,
          labelTxt: "X-Custom-Header",
          hintTxt: "X-Custom-Header",
        ),
        AppSpacing.md,
        CustomTextFormField(
          controller: contentTypeController,
          labelTxt: "Content-Type",
          readOnly: true,
        ),
        AppSpacing.md,
        CustomTextFormField(
          controller: bodyFormatController,
          labelTxt: "Body Format",
          readOnly: true,
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
        AppSpacing.lg,
      ],
    );
  }
}
