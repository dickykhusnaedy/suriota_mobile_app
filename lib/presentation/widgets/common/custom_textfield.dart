import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gateway_config/core/constants/app_color.dart';
import 'package:gateway_config/core/constants/app_gap.dart';
import 'package:gateway_config/core/constants/app_font.dart';
import 'package:gateway_config/core/utils/extensions.dart';
import 'package:intl/intl.dart';

class CustomTextFormField extends StatefulWidget {
  final TextEditingController? controller;
  final String? Function(String?)? validator;
  final void Function()? onTap;
  final void Function(String)? onChanges;
  final bool readOnly;
  final String? labelTxt;
  final String hintTxt;
  final String? errorTxt;
  final TextStyle? labelTxtStyle;
  final TextStyle? hintTxtStyle;
  final Widget? suffixIcon;
  final Widget? prefixIcon;
  final EdgeInsetsGeometry padding;
  final TextInputType? keyboardType;
  final bool? obscureText;
  final bool isRequired;

  const CustomTextFormField({
    super.key,
    this.labelTxt,
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
    this.obscureText,
    this.isRequired = false,
  });

  @override
  State<CustomTextFormField> createState() => _CustomTextFormFieldState();
}

class _CustomTextFormFieldState extends State<CustomTextFormField> {
  late TextEditingController _internalController;
  TextEditingController get _effectiveController =>
      widget.controller ?? _internalController;

  @override
  void initState() {
    super.initState();
    _internalController = TextEditingController();

    // If controller already has value and keyboardType is number, format it
    if (widget.controller != null &&
        widget.keyboardType == TextInputType.number &&
        widget.controller!.text.isNotEmpty) {
      _formatInitialValue();
    }
  }

  void _formatInitialValue() {
    final currentText = widget.controller!.text;
    // Check if already formatted (contains dot)
    if (!currentText.contains('.')) {
      final intValue = int.tryParse(currentText);
      if (intValue != null) {
        final formatter = NumberFormat('#,###', 'id_ID');
        widget.controller!.text = formatter.format(intValue).replaceAll(',', '.');
      }
    }
  }

  @override
  void dispose() {
    if (widget.controller == null) {
      _internalController.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (widget.labelTxt != null)
          Column(
            children: [
              Row(
                children: [
                  Text(
                    widget.labelTxt!,
                    style: widget.labelTxtStyle ??
                        context.h6.copyWith(fontWeight: FontWeightTheme.bold),
                  ),
                  AppSpacing.xs,
                  if (widget.isRequired)
                    Text(
                      '*',
                      style: context.buttonTextSmallest.copyWith(
                        color: Colors.red,
                      ),
                    ),
                ],
              ),
              AppSpacing.sm,
            ],
          ),
        TextFormField(
          obscureText: widget.obscureText ?? false,
          keyboardType: widget.keyboardType,
          style: context.body.copyWith(color: AppColor.darkGrey),
          controller: _effectiveController,
          validator: widget.validator,
          onTap: widget.onTap,
          onChanged: widget.onChanges,
          readOnly: widget.readOnly,
          cursorColor: AppColor.darkGrey,
          inputFormatters: widget.keyboardType == TextInputType.number
              ? [ThousandsSeparatorInputFormatter()]
              : null,
          decoration: InputDecoration(
            filled: true,
            fillColor: widget.readOnly ? Colors.grey[200] : Colors.white,
            floatingLabelBehavior: FloatingLabelBehavior.always,
            alignLabelWithHint: false,
            contentPadding: AppPadding.small,
            hintText: widget.hintTxt,
            hintStyle: widget.hintTxtStyle ??
                context.body.copyWith(color: AppColor.grey),
            suffixIcon: widget.suffixIcon,
            prefixIcon: widget.prefixIcon,
            errorText: widget.errorTxt,
            border: _borderStyle,
            enabledBorder: _borderStyle,
            focusedBorder: _focusedBorder,
            focusedErrorBorder: _focusedErrorBorder,
            errorBorder: _errorBorder,
            disabledBorder: _borderStyle,
          ),
        ),
      ],
    );
  }

  OutlineInputBorder get _borderStyle => OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColor.lightGrey, width: 1),
      );

  OutlineInputBorder get _focusedBorder => OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColor.primaryColor, width: 1),
      );

  OutlineInputBorder get _errorBorder => OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.red, width: 1),
      );

  OutlineInputBorder get _focusedErrorBorder => OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.red, width: 1),
      );
}

class ThousandsSeparatorInputFormatter extends TextInputFormatter {
  final NumberFormat _formatter = NumberFormat('#,###', 'id_ID');

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.text.isEmpty) {
      return newValue;
    }

    // Remove all non-digit characters
    String digitsOnly = newValue.text.replaceAll(RegExp(r'[^\d]'), '');

    if (digitsOnly.isEmpty) {
      return const TextEditingValue();
    }

    // Parse the number
    int value = int.parse(digitsOnly);

    // Format with thousands separator
    String formatted = _formatter.format(value).replaceAll(',', '.');

    // Calculate new cursor position
    int cursorPosition = formatted.length;

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: cursorPosition),
    );
  }

  /// Helper method to convert formatted text back to integer value
  /// Example: "1.000" -> 1000, "50.000" -> 50000
  static int? getIntValue(String? formattedText) {
    if (formattedText == null || formattedText.isEmpty) {
      return null;
    }

    // Remove all non-digit characters (dots, spaces, etc)
    String digitsOnly = formattedText.replaceAll(RegExp(r'[^\d]'), '');

    if (digitsOnly.isEmpty) {
      return null;
    }

    return int.tryParse(digitsOnly);
  }

  /// Helper method to set integer value to controller with formatting
  /// Example: 1000 -> "1.000", 50000 -> "50.000"
  static void setIntValue(TextEditingController controller, int? value) {
    if (value == null) {
      controller.text = '';
      return;
    }

    final formatter = NumberFormat('#,###', 'id_ID');
    controller.text = formatter.format(value).replaceAll(',', '.');
  }
}

/// Extension untuk TextEditingController agar mudah get/set integer value
extension TextEditingControllerNumberExtension on TextEditingController {
  /// Get integer value dari text yang terformat
  /// Contoh: controller.text = "1.000" -> controller.intValue = 1000
  int? get intValue {
    return ThousandsSeparatorInputFormatter.getIntValue(text);
  }

  /// Set integer value dengan format otomatis
  /// Contoh: controller.intValue = 1000 -> controller.text = "1.000"
  set intValue(int? value) {
    ThousandsSeparatorInputFormatter.setIntValue(this, value);
  }
}
