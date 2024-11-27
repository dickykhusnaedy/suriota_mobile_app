import 'package:flutter/material.dart';
import 'package:gap/gap.dart';

import '../../constant/app_color.dart';
import '../../constant/font_setup.dart';

class CustomTextFormField extends StatelessWidget {
  final TextEditingController? controller;
  final String? Function(String?)? validator;
  final void Function()? onTap;
  final void Function(String)? onChanges;
  final bool readOnly;
  final String labelTxt;
  final String hintTxt;
  final String? errorTxt;
  final TextStyle? labelTxtStyle;
  final TextStyle? hintTxtStyle;
  final Widget? suffixIcon;
  final Widget? prefixIcon;
  final EdgeInsetsGeometry padding;
  final TextInputType? keyboardType;
  final bool? obscureText;
  const CustomTextFormField(
      {super.key,
      required this.labelTxt,
      this.hintTxt = "",
      this.labelTxtStyle,
      this.hintTxtStyle,
      this.suffixIcon,
      this.prefixIcon,
      this.errorTxt,
      this.padding = const EdgeInsets.only(top: 4, bottom: 6),
      this.controller,
      this.validator,
      this.readOnly = false,
      this.onTap,
      this.onChanges,
      this.keyboardType,
      this.obscureText});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            labelTxt,
            style: labelTxtStyle ?? FontFamily.headlineMedium,
          ),
          const Gap(4),
          TextFormField(
            obscureText: obscureText ?? false,
            keyboardType: keyboardType,
            style: FontFamily.normalText,
            controller: controller,
            validator: validator,
            onTap: onTap,
            onChanged: onChanges,
            readOnly: readOnly,
            cursorColor: AppColor.primaryColor,
            decoration: InputDecoration(
              filled: true,
              fillColor: Colors.white,
              floatingLabelBehavior: FloatingLabelBehavior.always,
              alignLabelWithHint: false,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 14,
                // vertical: 2,
              ),
              hintText: hintTxt,
              hintStyle: hintTxtStyle ?? FontFamily.labelText,
              suffixIcon: suffixIcon,
              prefixIcon: prefixIcon,
              errorText: errorTxt,
              border: borderStyle,
              enabledBorder: borderStyle,
              focusedBorder: focusedBorder,
              focusedErrorBorder: focusedErrorBorder,
              errorBorder: errorBorder,
              disabledBorder: borderStyle,
            ),
          ),
        ],
      ),
    );
  }

  OutlineInputBorder get borderStyle => OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(
          color: AppColor.primaryColor,
          width: 1,
        ),
      );

  OutlineInputBorder get focusedBorder => OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(
          color: AppColor.primaryColor,
          width: 2,
        ),
      );

  OutlineInputBorder get errorBorder => OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(
          color: Colors.red,
          width: 1,
        ),
      );

  OutlineInputBorder get focusedErrorBorder => OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(
          color: Colors.red,
          width: 2,
        ),
      );
}
