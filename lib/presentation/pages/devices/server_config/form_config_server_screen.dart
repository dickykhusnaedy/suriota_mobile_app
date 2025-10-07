// ignore_for_file: prefer_const_literals_to_create_immutables, prefer_const_constructors

import 'package:flutter/material.dart';
import 'package:gateway_config/core/constants/app_color.dart';
import 'package:gateway_config/core/constants/app_font.dart';
import 'package:gateway_config/core/constants/app_gap.dart';
import 'package:gateway_config/core/controllers/ble/ble_controller.dart';
import 'package:gateway_config/core/controllers/ble_controller.dart';
import 'package:gateway_config/core/utils/app_helpers.dart';
import 'package:gateway_config/core/utils/extensions.dart';
import 'package:gateway_config/core/utils/snackbar_custom.dart';
import 'package:gateway_config/models/dropdown_items.dart';
import 'package:gateway_config/presentation/widgets/common/custom_alert_dialog.dart';
import 'package:gateway_config/presentation/widgets/common/custom_button.dart';
import 'package:gateway_config/presentation/widgets/common/custom_radiotile.dart';
import 'package:gateway_config/presentation/widgets/common/custom_textfield.dart';
import 'package:gateway_config/presentation/widgets/common/dropdown.dart';
import 'package:gateway_config/presentation/widgets/common/loading_overlay.dart';
import 'package:gateway_config/presentation/widgets/spesific/title_tile.dart';
import 'package:get/get.dart';
import 'package:multi_dropdown/multi_dropdown.dart';

class FormConfigServer extends StatefulWidget {
  const FormConfigServer({super.key});

  @override
  State<FormConfigServer> createState() => _FormConfigServerState();
}

class LoggingData {
  final String name;
  final int id;

  LoggingData({required this.name, required this.id});

  @override
  String toString() {
    return 'LoggingData(name: $name, id: $id)';
  }
}

class _FormConfigServerState extends State<FormConfigServer> {
  final BLEController bleController = Get.put(BLEController(), permanent: true);
  final BleController controller = Get.put(BleController());

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  String protocolSelected = 'mqtt';
  String communcationSelected = 'ETH';
  String methodEthernet = "Automatic";
  String confirmAuthentication = "Yes";
  String selectedIntervalType = 'ms';
  String cleanSessionSelected = 'true';
  String useTlsSelected = 'true';

  bool isInitialized = false;
  bool isLoading = false;
  String errorMessage = '';

  // TextEditingController controllers for form fields
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
  final qosLevelController = TextEditingController();
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
    // Initialize any necessary state or controllers here
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!isInitialized) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        // fetchData();
        isInitialized = true;
      });
    }
  }

  // void _updateFormWithConfigData(Map<String, dynamic> data) {
  //   // Communication settings
  //   communcationSelected = data['communication']?['type'] ?? 'ETH';
  //   methodEthernet = data['communication']?['mode'] ?? 'Automatic';
  //   ipAddressController.text = data['communication']?['ip'] ?? '';
  //   macAddressController.text = data['communication']?['mac'] ?? '';
  //   wifiSsidController.text = data['communication']?['ssid'] ?? '';
  //   wifiPasswordController.text = data['communication']?['pass'] ?? '';

  //   // Protocol settings
  //   protocolSelected = data['protocol']?['type'] ?? 'MQTT';
  //   serverNameController.text = data['protocol']?['server'] ?? '';
  //   portMqttController.text = data['protocol']?['port']?.toString() ?? '';
  //   publishTopicController.text = data['protocol']?['topic'] ?? '';
  //   clientIdController.text = data['protocol']?['clientid'] ?? '';
  //   qosLevelController.text = data['protocol']?['qos']?.toString() ?? '';
  //   urlLinkController.text = data['protocol']?['url_link'] ?? '';

  //   // Interval settings
  //   selectedIntervalType = data['interval']?['type'] ?? 's';
  //   intervalTimeController.text = data['interval']?['time']?.toString() ?? '';

  //   // Authentication settings
  //   confirmAuthentication = data['auth']?['username']?.isNotEmpty == true
  //       ? 'Yes'
  //       : 'No';
  //   usernameController.text = data['auth']?['username'] ?? '';
  //   passwordController.text = data['auth']?['password'] ?? '';
  // }

  Future<void> fetchData() async {
    setState(() {
      isLoading = true;
      errorMessage = '';
    });

    try {
      // final data = await bleController.fetchData("READ|config", 'config');

      setState(() {
        // _updateFormWithConfigData(data);

        isLoading = false;
      });
    } catch (e) {
      setState(() {
        errorMessage = 'Failed to load config: $e';
        isLoading = false;
      });
    }
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

        var wifiConfig = {
          "ssid": wifiSsidController.text,
          "password": wifiPasswordController.text,
        };

        var communication = {
          "mode": _sanitizeInput(protocolSelected),
          "connection_mode": _sanitizeInput(communcationSelected),
          "ip_address": _sanitizeInput(ipAddressController.text),
          "mac_address": _sanitizeInput(macAddressController.text),
          ...(communcationSelected == 'WIFI' ? wifiConfig : {}),
        };

        var dataInterval = {
          "value": intervalTimeController.text,
          "unit": selectedIntervalType,
        };

        var mqttConfig = {
          "enabled": protocolSelected == 'mqtt' ? true : false,
          "broker_address": _sanitizeInput(serverNameController.text),
          "broker_port": _tryParseInt(portMqttController.text),
          "client_id": _sanitizeInput(clientIdController.text),
          "username": _sanitizeInput(usernameController.text),
          "password": _sanitizeInput(passwordController.text),
          "topic_publish": _sanitizeInput(publishTopicController.text),
          "topic_subscribe": _sanitizeInput(subscribeTopicController.text),
          "keep_alive": _sanitizeInput(keepAliveController.text),
          "clean_session": cleanSessionSelected,
          "use_tls": useTlsSelected,
        };

        var httpConfig = {
          "enabled": protocolSelected == 'http' ? true : false,
          "endpoint_url": _sanitizeInput(urlLinkController.text),
          "method": _sanitizeInput(methodRequestController.text),
          "headers": {
            "Authorization": authorizationController.text,
            "Content-Type": contentTypeController.text,
          },
          "body_format": bodyFormatController.text,
          "timeout": _tryParseInt(timeoutController.text),
          "retry": _tryParseInt(retryController.text),
        };

        var formData = {
          "communication": communication,
          "protocol": protocolSelected,
          "data_interval": dataInterval,
          "mqtt_config": mqttConfig,
          "http_config": httpConfig,
        };

        try {
          controller.sendCommand(formData);
        } catch (e) {
          SnackbarCustom.showSnackbar(
            '',
            'Failed to submit form',
            AppColor.redColor,
            AppColor.whiteColor,
          );
          AppHelpers.debugLog('Error submitting form: $e');
        } finally {
          await Future.delayed(const Duration(seconds: 3));
          AppHelpers.backNTimes(1);
        }
      },
      barrierDismissible: false,
    );
  }

  // String _buildSendDataDelimiter() {
  //   final intervalTime = _tryParseInt(intervalTimeController.text);
  //   final intervalType = selectedIntervalType;
  //   final authUsername = usernameController.text;
  //   final authPassword = passwordController.text;

  //   final communicationData = _communcationModeData();
  //   final protocolData = _protocolData();

  //   final intervalData =
  //       'interval_time:$intervalTime|interval_type:$intervalType';
  //   final authData =
  //       'auth_type:BASIC|auth_username:$authUsername|auth_password:$authPassword';

  //   return 'UPDATE|config|$communicationData|$protocolData|$intervalData|$authData';
  // }

  // String _communcationModeData() {
  //   final communicationType = communcationSelected;
  //   final communicationMethod = methodEthernet;
  //   final communicationIp = _sanitizeInput(ipAddressController.text);
  //   final communicationMac = macAddressController.text;
  //   final wifiSsid = wifiSsidController.text;
  //   final wifiPassword = wifiPasswordController.text;

  //   return 'communication_type:$communicationType|communication_mode:$communicationMethod|communication_ip:$communicationIp|communication_mac:$communicationMac|communication_ssid:$wifiSsid|communication_pass:$wifiPassword';
  // }

  // String? _protocolData() {
  //   final protocolServer = serverNameController.text;
  //   final protocolPort = _tryParseInt(portMqttController.text);
  //   final protocolTopic = publishTopicController.text;
  //   final protocolClientId = clientIdController.text;
  //   final protocolQosLevel = _tryParseInt(qosLevelController.text);

  //   if (protocolSelected == 'mqtt') {
  //     return 'protocol_type:$protocolSelected|protocol_server:$protocolServer|protocol_port:$protocolPort|protocol_topic:$protocolTopic|protocol_clientid:$protocolClientId|protocol_qos:$protocolQosLevel';
  //   } else if (protocolSelected == 'http') {
  //     final urlLink = urlLinkController.text;
  //     return 'protocol_type:HTTP|url_link:$urlLink';
  //   }

  //   return null;
  // }

  String _sanitizeInput(String input) {
    return input.replaceAll('|', '').replaceAll('#', '');
  }

  int? _tryParseInt(String? value, {int? defaultValue}) {
    if (value == null || value.isEmpty) return defaultValue;
    return int.tryParse(value) ?? defaultValue;
  }

  @override
  void dispose() {
    // Dispose of the controllers to free up resources
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
    qosLevelController.dispose();
    urlLinkController.dispose();
    methodRequestController.dispose();
    usernameController.dispose();
    passwordController.dispose();
    authorizationController.dispose();
    xCustomHeaderController.dispose();
    contentTypeController.dispose();
    bodyFormatController.dispose();

    isInitialized = false;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    var items = [
      DropdownItem(
        label: 'Sensor',
        value: LoggingData(name: 'Sensor', id: 1),
      ),
      DropdownItem(
        label: 'Tekanan',
        value: LoggingData(name: 'Tekanan', id: 6),
      ),
      DropdownItem(
        label: 'Suhu',
        value: LoggingData(name: 'Suhu', id: 2),
      ),
    ];

    List<DropdownItems> typeInterval = [
      DropdownItems(text: 's', value: 's'),
      DropdownItems(text: 'm', value: 'm'),
      DropdownItems(text: 'ms', value: 'ms'),
    ];

    return Stack(
      children: [
        Scaffold(
          appBar: _appBar(context),
          body: _body(context, items, typeInterval),
        ),
        Obx(() {
          final isAnyDeviceLoading = bleController.isLoading.value;
          return LoadingOverlay(
            isLoading: isAnyDeviceLoading,
            message: 'Processing request...',
          );
        }),
      ],
    );
  }

  SafeArea _body(
    BuildContext context,
    List<DropdownItem<LoggingData>> items,
    List<DropdownItems> typeInterval,
  ) {
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
              ethernetConfig(),
              if (communcationSelected == 'WIFI') wifiField(),
              _protocolWrapper(),
              AppSpacing.md,
              _intervalWrapper(context, items, typeInterval),
              AppSpacing.md,
              mqttField(),
              httpField(),
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

  Column _intervalWrapper(
    BuildContext context,
    List<DropdownItem<LoggingData>> items,
    List<DropdownItems> typeInterval,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TitleTile(title: 'Data Interval'),
        AppSpacing.sm,
        Text(
          's: seconds, m: minute',
          style: context.bodySmall.copyWith(color: AppColor.grey),
        ),
        AppSpacing.sm,
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Interval Time',
              style: context.h6.copyWith(fontWeight: FontWeightTheme.bold),
            ),
            CustomTextFormField(
              controller: intervalTimeController,
              hintTxt: '5000',
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Interval Time is required';
                }
                return null;
              },
            ),
            AppSpacing.sm,
            Dropdown(
              label: 'Choose Interval Type',
              items: typeInterval,
              selectedValue: selectedIntervalType,
              onChanged: (value) {
                setState(() {
                  selectedIntervalType = value!;
                });
              },
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please select interval type';
                }
                return null;
              },
              isRequired: true,
            ),
          ],
        ),
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
          onChanges: () {
            setState(() {
              protocolSelected = "mqtt";
            });
          },
        ),
        CustomRadioTile(
          value: "http",
          grupValue: protocolSelected,
          onChanges: () {
            setState(() {
              protocolSelected = "http";
            });
          },
        ),
      ],
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
        // Ethernet Option
        CustomRadioTile(
          value: "ETH",
          grupValue: communcationSelected, // Use dynamic state variable
          onChanges: () {
            setState(() {
              communcationSelected = "ETH";
            });
            _chooseEthernetMethod(context);
          },
        ),
        // WiFi Option
        CustomRadioTile(
          value: "WIFI",
          grupValue: communcationSelected, // Use dynamic state variable
          onChanges: () {
            setState(() {
              communcationSelected = "WIFI";
              methodEthernet = "Automatic";
            });
          },
        ),
      ],
    );
  }

  Future<dynamic> _chooseEthernetMethod(BuildContext context) {
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        scrollable: true,
        title: Text("Choose Ethernet Method", style: context.h5),
        content: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'A: Automatic, F: Following',
              style: context.bodySmall.copyWith(color: AppColor.grey),
            ),
            AppSpacing.sm,
            // Automatic Ethernet method
            CustomRadioTile(
              value: "Automatic",
              grupValue: methodEthernet, // Reference dynamic variable
              onChanges: () {
                setState(() {
                  methodEthernet = "Automatic"; // Set to Automatic
                });

                Navigator.pop(context); // Close the dialog
              },
            ),
            // Following Ethernet method
            CustomRadioTile(
              value: "Following",
              grupValue: methodEthernet, // Reference dynamic variable
              onChanges: () {
                setState(() {
                  methodEthernet = "Following"; // Set to Following
                });

                Navigator.pop(context); // Close the dialog
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget ethernetConfig() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Mode: $communcationSelected | Method Selected: $methodEthernet',
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
            if (!ipPattern.hasMatch(value)) return 'Invalid IP address format';

            return null;
          },
          isRequired: true,
        ),
        AppSpacing.md,
        CustomTextFormField(
          controller: macAddressController,
          labelTxt: "MAC Address",
          hintTxt: "20202021",
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'MAC Address is required';
            }
            return null;
          },
          isRequired: true,
        ),
        AppSpacing.md,
      ],
    );
  }

  Widget wifiField() {
    return Column(
      children: [
        CustomTextFormField(
          controller: wifiSsidController,
          labelTxt: "WiFi SSID",
          hintTxt: "Enter the WiFi SSID",
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'WIFI SSID is required';
            }
            return null;
          },
          isRequired: true,
        ),
        AppSpacing.md,
        CustomTextFormField(
          controller: wifiPasswordController,
          labelTxt: "WiFi Password",
          hintTxt: "Enter the WiFi Password",
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'WIFI Password is required';
            }
            return null;
          },
          isRequired: true,
        ),
        AppSpacing.md,
      ],
    );
  }

  Widget mqttField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TitleTile(title: "Setup MQTT Connection"),
        AppSpacing.md,
        CustomTextFormField(
          controller: serverNameController,
          labelTxt: "Address",
          hintTxt: "server.demo.com",
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Address is required';
            }
            return null;
          },
          isRequired: true,
        ),
        AppSpacing.md,
        CustomTextFormField(
          controller: portMqttController,
          labelTxt: "Port MQTT",
          hintTxt: "0000",
          keyboardType: TextInputType.number,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Port MQTT is required';
            }
            return null;
          },
          isRequired: true,
        ),
        AppSpacing.md,
        CustomTextFormField(
          controller: clientIdController,
          labelTxt: "Client ID",
          hintTxt: "Client ID",
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Client ID is required';
            }
            return null;
          },
          isRequired: true,
        ),
        AppSpacing.md,
        authentication(),
        AppSpacing.md,
        CustomTextFormField(
          controller: publishTopicController,
          labelTxt: "Publish Topic",
          hintTxt: "Topic",
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Publish Topic is required';
            }
            return null;
          },
        ),
        AppSpacing.md,
        CustomTextFormField(
          controller: subscribeTopicController,
          labelTxt: "Subscribe Topic",
          hintTxt: "Subscribe",
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Subscribe Topic is required';
            }
            return null;
          },
        ),
        AppSpacing.md,
        CustomTextFormField(
          controller: keepAliveController,
          labelTxt: "Keep Alive",
          hintTxt: "ex. 60",
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Keep Alive is required';
            }
            return null;
          },
        ),
        AppSpacing.md,
        Dropdown(
          label: 'Clean Session',
          items: [
            DropdownItems(text: 'true', value: 'true'),
            DropdownItems(text: 'false', value: 'false'),
          ],
          selectedValue: cleanSessionSelected,
          onChanged: (value) {
            setState(() {
              cleanSessionSelected = value!;
            });
          },
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please select clean session';
            }
            return null;
          },
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
          onChanged: (value) {
            setState(() {
              useTlsSelected = value!;
            });
          },
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please select use tls';
            }
            return null;
          },
          isRequired: true,
        ),
        AppSpacing.lg,
      ],
    );
  }

  Widget httpField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TitleTile(title: "Setup HTTP Connection"),
        AppSpacing.md,
        CustomTextFormField(
          controller: urlLinkController,
          labelTxt: "Endpoint URL",
          hintTxt: "www.demo.com",
        ),
        AppSpacing.md,
        CustomTextFormField(
          controller: methodRequestController,
          labelTxt: "Method Request",
          readOnly: true,
        ),
        AppSpacing.md,
        CustomTextFormField(
          controller: authorizationController,
          labelTxt: "Authorization",
          hintTxt: "Ex. Bearer token",
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
          labelTxt: "Timeout",
          keyboardType: TextInputType.number,
          hintTxt: "ex. 3000",
        ),
        AppSpacing.md,
        CustomTextFormField(
          controller: retryController,
          labelTxt: "Retry",
          keyboardType: TextInputType.number,
          hintTxt: "ex. 3",
        ),
        AppSpacing.lg,
      ],
    );
  }

  Widget authentication() {
    return Column(
      children: [
        AppSpacing.sm,
        CustomTextFormField(
          controller: usernameController,
          labelTxt: 'Username',
          hintTxt: 'Enter the Username',
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Username is required';
            }
            return null;
          },
        ),
        AppSpacing.md,
        CustomTextFormField(
          controller: passwordController,
          labelTxt: 'Password',
          hintTxt: 'Enter the Password',
          obscureText: true,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Password is required';
            }
            return null;
          },
        ),
      ],
    );
  }
}
