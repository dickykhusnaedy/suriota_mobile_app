import 'package:flutter/material.dart';
import 'package:suriota_mobile_gateway/constant/app_color.dart';
import 'package:suriota_mobile_gateway/constant/app_gap.dart';
import 'package:suriota_mobile_gateway/constant/font_setup.dart';
import 'package:suriota_mobile_gateway/global/utils/text_extension.dart';

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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          labelTxt,
          style: labelTxtStyle ??
              context.h6.copyWith(fontWeight: FontWeightTheme.bold),
        ),
        AppSpacing.sm,
        TextFormField(
          obscureText: obscureText ?? false,
          keyboardType: keyboardType,
          style: context.body.copyWith(color: AppColor.darkGrey),
          controller: controller,
          validator: validator,
          onTap: onTap,
          onChanged: onChanges,
          readOnly: readOnly,
          cursorColor: AppColor.darkGrey,
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.white,
            floatingLabelBehavior: FloatingLabelBehavior.always,
            alignLabelWithHint: false,
            contentPadding: AppPadding.horizontalMedium,
            hintText: hintTxt,
            hintStyle:
                hintTxtStyle ?? context.body.copyWith(color: AppColor.grey),
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
