import 'package:flutter/material.dart';

import '../../constant/app_color.dart';
import '../../constant/font_setup.dart';

class DetailInformationDevicePage extends StatelessWidget {
  const DetailInformationDevicePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(
          'Detail Device Information',
          style: FontFamily.tittleSmall.copyWith(color: Colors.white),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: 5,
                itemBuilder: (BuildContext context, int index) {
                  return Card(
                    color: AppColor.cardColor,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Generic Attribute',
                            style: FontFamily.headlineMedium,
                          ),
                          Text(
                            'UUID : 0X1801',
                            style: FontFamily.normal,
                          ),
                          Text(
                            'PRIMARY ACCESS',
                            style: FontFamily.normal,
                          ),
                        ],
                      ),
                    ),
                  );
                })
          ],
        ),
      ),
    );
  }
}
