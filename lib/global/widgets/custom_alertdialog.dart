import 'package:flutter/material.dart';
import 'package:suriota_mobile_gateway/constant/app_color.dart';
import 'package:suriota_mobile_gateway/constant/font_setup.dart';
import 'package:suriota_mobile_gateway/constant/image_asset.dart';
import 'package:suriota_mobile_gateway/global/widgets/custom_button.dart';
import 'package:suriota_mobile_gateway/global/widgets/custom_textfield.dart';

class CustomAlertDialog extends StatelessWidget {
  const CustomAlertDialog({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColor.cardColor,
      scrollable: true,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      title: Center(
        child: Text(
          'Device Initial',
          style: FontFamily.headlineMedium,
        ),
      ),
      content: Column(
        children: [
          SizedBox(
              height: 170, child: Image.asset(ImageAsset.iconDeviceInitial)),
          const SizedBox(
            height: 10,
          ),
          const CustomTextFormField(
            labelTxt: 'Device Name',
            hintTxt: 'Enter the device name',
          ),
          const SizedBox(
            height: 20,
          ),
          Button(
              onPressed: () {
                Navigator.pop(context);
              },
              height: 40,
              width: MediaQuery.of(context).size.width * 1,
              text: 'Save',
              customStyle:
                  FontFamily.normal.copyWith(fontSize: 14, color: Colors.white))
        ],
      ),
    );
  }
}
