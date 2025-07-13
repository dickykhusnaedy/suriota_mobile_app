import 'package:flutter/material.dart';
import 'package:suriota_mobile_gateway/core/constants/app_color.dart';
import 'package:suriota_mobile_gateway/core/constants/app_font.dart';
import 'package:suriota_mobile_gateway/core/utils/extensions.dart';

class CustomRadioTileController extends ValueNotifier<String?> {
  CustomRadioTileController(String? initialValue) : super(initialValue);

  String? get value => super.value;
  set value(String? newValue) => super.value = newValue;
}

class CustomRadioTile extends StatefulWidget {
  final String value;
  final String grupValue;
  final void Function() onChanges;
  final CustomRadioTileController? controller; // Added controller
  final String? Function(String?)? validator; // Added validator

  const CustomRadioTile({
    super.key,
    required this.value,
    required this.grupValue,
    required this.onChanges,
    this.controller,
    this.validator,
  });

  bool get isSelected => value == grupValue;

  @override
  State<CustomRadioTile> createState() => _CustomRadioTileState();
}

class _CustomRadioTileState extends State<CustomRadioTile> {
  String? errorText;

  @override
  void initState() {
    super.initState();
    // Perform initial validation if validator and grupValue exist
    if (widget.validator != null && widget.grupValue.isNotEmpty) {
      errorText = widget.validator!(widget.grupValue);
    }
    // Update controller with initial grupValue if provided
    if (widget.controller != null) {
      widget.controller!.value = widget.grupValue;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ListTile(
          visualDensity: VisualDensity.lerp(
            const VisualDensity(horizontal: -4, vertical: -4),
            const VisualDensity(horizontal: -4, vertical: -4),
            0,
          ),
          minVerticalPadding: 0,
          dense: true,
          contentPadding: EdgeInsets.zero,
          title: Text(
            widget.value,
            style: widget.isSelected
                ? context.h6.copyWith(fontWeight: FontWeightTheme.extraBold)
                : context.body,
          ),
          onTap: () {
            setState(() {
              // Update controller if provided
              if (widget.controller != null) {
                widget.controller!.value = widget.value;
              }
              // Validate if validator provided
              errorText = widget.validator?.call(widget.value);
            });
            widget.onChanges();
          },
          isThreeLine: false,
          horizontalTitleGap: 12,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: errorText != null
                ? BorderSide(color: AppColor.redColor, width: 1)
                : BorderSide.none,
          ),
          leading: Radio(
            visualDensity: const VisualDensity(horizontal: -4, vertical: -4),
            activeColor: AppColor.primaryColor,
            focusColor: AppColor.primaryColor,
            overlayColor: const WidgetStatePropertyAll(Colors.transparent),
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            value: widget.value,
            groupValue: widget.grupValue,
            onChanged: (value) {
              setState(() {
                // Update controller if provided
                if (widget.controller != null) {
                  widget.controller!.value = widget.value;
                }
                // Validate if validator provided
                errorText = widget.validator?.call(widget.value);
              });
              widget.onChanges();
            },
          ),
        ),
        if (errorText != null)
          Padding(
            padding: const EdgeInsets.only(left: 16.0, top: 4.0),
            child: Text(
              errorText!,
              style: context.body.copyWith(color: AppColor.redColor),
            ),
          ),
      ],
    );
  }
}
