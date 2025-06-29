import 'package:flutter/material.dart';
import 'package:suriota_mobile_gateway/core/constants/app_color.dart';
import 'package:suriota_mobile_gateway/core/constants/app_gap.dart';
import 'package:suriota_mobile_gateway/core/constants/app_image_assets.dart';
import 'package:suriota_mobile_gateway/core/utils/app_helpers.dart';
import 'package:suriota_mobile_gateway/core/utils/extensions.dart';
import 'package:suriota_mobile_gateway/global/widgets/custom_button.dart';

class AboutUsPage extends StatelessWidget {
  const AboutUsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'About Product',
          style: context.h5.copyWith(color: AppColor.whiteColor),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        centerTitle: true,
        backgroundColor: AppColor.primaryColor,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: AppPadding.horizontalMedium,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppSpacing.md,
              Text(
                'Suriota Module – Modbus Gateway IIOT (SRT-MGATE 1210)',
                style: context.h3.copyWith(color: AppColor.blackColor),
              ),
              AppSpacing.sm,
              Text(
                'Elevate Your Industrial Connectivity with Suriota Modbus Gateway IIoT',
                style: context.bodySmall.copyWith(color: AppColor.grey),
              ),
              AppSpacing.md,
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Image.asset(
                  ImageAsset.suriotaGatewayBanner,
                  width: double.infinity,
                  fit: BoxFit.contain,
                ),
              ),
              AppSpacing.md,
              Text(
                'Seamless Integration Between Automation Systems and Modern IoT Ecosystems',
                textAlign: TextAlign.left,
                style: context.h5.copyWith(color: AppColor.blackColor),
              ),
              AppSpacing.md,
              Text(
                'The Suriota Modbus Gateway IIoT is an industrial-standard gateway solution designed to efficiently bridge Modbus-based automation systems with Internet of Things (IoT) ecosystems. This device enables the conversion of data from industrial assets such as sensors, PLCs, or machinery into modern IoT protocols like MQTT and HTTP. \n\nWith support for Modbus RTU (RS-485) and Modbus TCP/IP (Wi-Fi/Ethernet), the gateway ensures compatibility between existing industrial infrastructure and IoT cloud platforms (AWS, Azure, etc.) as well as on-premises servers.',
                textAlign: TextAlign.left,
                style: context.body.copyWith(color: AppColor.blackColor),
              ),
              AppSpacing.md,
              Text(
                'Why Choose Suriota Modbus Gateway IIoT?',
                textAlign: TextAlign.left,
                style: context.h5.copyWith(color: AppColor.blackColor),
              ),
              AppSpacing.sm,
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '•',
                        textAlign: TextAlign.left,
                        style:
                            context.body.copyWith(color: AppColor.blackColor),
                      ),
                      AppSpacing.sm,
                      Expanded(
                        child: Text(
                          'Easy No-Code Configuration\nConfigure Modbus register mapping without coding, directly transforming raw data into structured formats like JSON or customized MQTT topics.',
                          textAlign: TextAlign.left,
                          style:
                              context.body.copyWith(color: AppColor.blackColor),
                        ),
                      ),
                    ],
                  ),
                  AppSpacing.sm,
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '•',
                        textAlign: TextAlign.left,
                        style:
                            context.body.copyWith(color: AppColor.blackColor),
                      ),
                      AppSpacing.sm,
                      Expanded(
                        child: Text(
                          'Real-Time Monitoring\nMonitor operational data such as machine RPM, pressure readings, or equipment status directly through intuitive dashboards or IoT platforms.',
                          textAlign: TextAlign.left,
                          style:
                              context.body.copyWith(color: AppColor.blackColor),
                        ),
                      ),
                    ],
                  ),
                  AppSpacing.sm,
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '•',
                        textAlign: TextAlign.left,
                        style:
                            context.body.copyWith(color: AppColor.blackColor),
                      ),
                      AppSpacing.sm,
                      Expanded(
                        child: Text(
                          'Dual & Reliable Connectivity\nEquipped with WiFi (2.4 GHz) and Ethernet (10/100 Mbps) featuring auto-failover for uninterrupted connection.',
                          textAlign: TextAlign.left,
                          style:
                              context.body.copyWith(color: AppColor.blackColor),
                        ),
                      ),
                    ],
                  ),
                  AppSpacing.sm,
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '•',
                        textAlign: TextAlign.left,
                        style:
                            context.body.copyWith(color: AppColor.blackColor),
                      ),
                      AppSpacing.sm,
                      Expanded(
                        child: Text(
                          'Multi-Protocol Support\nConverts between Modbus RTU (RS-485), Modbus TCP/IP, MQTT, and HTTP.',
                          textAlign: TextAlign.left,
                          style:
                              context.body.copyWith(color: AppColor.blackColor),
                        ),
                      ),
                    ],
                  ),
                  AppSpacing.sm,
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '•',
                        textAlign: TextAlign.left,
                        style:
                            context.body.copyWith(color: AppColor.blackColor),
                      ),
                      AppSpacing.sm,
                      Expanded(
                        child: Text(
                          'Designed for Industrial Environments\nWith a wide operating temperature range (-40°C to 75°C) and 2 kV isolation protection on RS-485 ports, this gateway is robust for harsh environments.',
                          textAlign: TextAlign.left,
                          style:
                              context.body.copyWith(color: AppColor.blackColor),
                        ),
                      ),
                    ],
                  ),
                  AppSpacing.sm,
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '•',
                        textAlign: TextAlign.left,
                        style:
                            context.body.copyWith(color: AppColor.blackColor),
                      ),
                      AppSpacing.sm,
                      Expanded(
                        child: Text(
                          'Guaranteed Security\nFeatures TLS/SSL encryption and firewall rules for strong data security.',
                          textAlign: TextAlign.left,
                          style:
                              context.body.copyWith(color: AppColor.blackColor),
                        ),
                      ),
                    ],
                  ),
                  AppSpacing.sm,
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '•',
                        textAlign: TextAlign.left,
                        style:
                            context.body.copyWith(color: AppColor.blackColor),
                      ),
                      AppSpacing.sm,
                      Expanded(
                        child: Text(
                          'Easy Mobile App Configuration\nWirelessly set up and monitor the gateway using the Android/iOS-based Suriota Config app via BLE (Bluetooth Low Energy) connection.',
                          textAlign: TextAlign.left,
                          style:
                              context.body.copyWith(color: AppColor.blackColor),
                        ),
                      ),
                    ],
                  ),
                  AppSpacing.sm,
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '•',
                        textAlign: TextAlign.left,
                        style:
                            context.body.copyWith(color: AppColor.blackColor),
                      ),
                      AppSpacing.sm,
                      Expanded(
                        child: Text(
                          'Local Data Logging\nA MicroSD slot allows local data logging (CSV/JSON) during network outages, ensuring no data is lost.',
                          textAlign: TextAlign.left,
                          style:
                              context.body.copyWith(color: AppColor.blackColor),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              AppSpacing.md,
              Text(
                'Key Specifications:',
                textAlign: TextAlign.left,
                style: context.h5.copyWith(color: AppColor.blackColor),
              ),
              AppSpacing.sm,
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '•',
                        textAlign: TextAlign.left,
                        style:
                            context.body.copyWith(color: AppColor.blackColor),
                      ),
                      AppSpacing.sm,
                      Expanded(
                        child: Text(
                          'CPU\nESPRESSIF',
                          textAlign: TextAlign.left,
                          style:
                              context.body.copyWith(color: AppColor.blackColor),
                        ),
                      ),
                    ],
                  ),
                  AppSpacing.sm,
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '•',
                        textAlign: TextAlign.left,
                        style:
                            context.body.copyWith(color: AppColor.blackColor),
                      ),
                      AppSpacing.sm,
                      Expanded(
                        child: Text(
                          'Wireless Connectivity\nWiFi 2.4 GHz (802.11 b/g/n), Bluetooth 5.0 (BLE) with a range of up to 50m (LOS).',
                          textAlign: TextAlign.left,
                          style:
                              context.body.copyWith(color: AppColor.blackColor),
                        ),
                      ),
                    ],
                  ),
                  AppSpacing.sm,
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '•',
                        textAlign: TextAlign.left,
                        style:
                            context.body.copyWith(color: AppColor.blackColor),
                      ),
                      AppSpacing.sm,
                      Expanded(
                        child: Text(
                          'Ports\n2x Isolated RS-485 (up to 32 devices per port), 1x RJ45 Ethernet 10/100 Mbps.',
                          textAlign: TextAlign.left,
                          style:
                              context.body.copyWith(color: AppColor.blackColor),
                        ),
                      ),
                    ],
                  ),
                  AppSpacing.sm,
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '•',
                        textAlign: TextAlign.left,
                        style:
                            context.body.copyWith(color: AppColor.blackColor),
                      ),
                      AppSpacing.sm,
                      Expanded(
                        child: Text(
                          'Power\nDual DC 12-48VDC inputs for redundancy, PoE option (IEEE 802.3af/at) on specific versions.',
                          textAlign: TextAlign.left,
                          style:
                              context.body.copyWith(color: AppColor.blackColor),
                        ),
                      ),
                    ],
                  ),
                  AppSpacing.sm,
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '•',
                        textAlign: TextAlign.left,
                        style:
                            context.body.copyWith(color: AppColor.blackColor),
                      ),
                      AppSpacing.sm,
                      Expanded(
                        child: Text(
                          'Communication Protocols\nMQTT (ISO/IEC 20922), HTTP/HTTPS, REST API.',
                          textAlign: TextAlign.left,
                          style:
                              context.body.copyWith(color: AppColor.blackColor),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              AppSpacing.md,
              Text(
                'The Suriota Modbus Gateway IIoT is ideal for applications in manufacturing, oil & gas, marine, fabrication, shipyard, and agriculture. Integrate your industrial assets into the IoT world with a flexible, secure, and easy-to-manage gateway solution.',
                textAlign: TextAlign.left,
                style: context.body.copyWith(color: AppColor.blackColor),
              ),
              AppSpacing.md,
              Row(
                children: [
                  Expanded(
                    child: Button(
                      width: double.infinity,
                      onPressed: () {},
                      text: 'Tokopedia',
                      icons: const Icon(
                        Icons.shop,
                        size: 15,
                        color: AppColor.whiteColor,
                      ),
                    ),
                  ),
                  AppSpacing.md,
                  Expanded(
                    child: Button(
                      width: double.infinity,
                      onPressed: () async {
                        final Uri url = Uri.parse(
                            'https://drive.google.com/drive/folders/12XOl4YRrcpPVdAbYFFdjo-ylfev5Z-Lu?usp=sharing');
                        AppHelpers.launchInBrowser(url);
                      },
                      text: 'Datasheet',
                      icons: const Icon(
                        Icons.dataset,
                        size: 15,
                        color: AppColor.whiteColor,
                      ),
                    ),
                  ),
                ],
              ),
              AppSpacing.xxxxl,
              Text(
                'Copyright © 2025 PT Surya Inovasi Prioritas',
                textAlign: TextAlign.center,
                style: context.bodySmall.copyWith(color: AppColor.grey),
              ),
              AppSpacing.lg,
            ],
          ),
        ),
      ),
    );
  }
}
