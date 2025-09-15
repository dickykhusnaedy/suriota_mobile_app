import 'package:dropdown_search/dropdown_search.dart';
import 'package:flutter/material.dart';
import 'package:gateway_config/core/constants/app_color.dart';
import 'package:gateway_config/core/constants/app_gap.dart';
import 'package:gateway_config/core/utils/extensions.dart';

class Dropdown extends StatefulWidget {
  const Dropdown({
    super.key,
    required this.items,
    this.onChanged,
    this.disabledItemFn,
    this.validator,
    this.hint,
    this.selectedItem,
  });

  final List<String> items;
  final void Function(String?)? onChanged;
  final void Function(String?)? disabledItemFn;
  final String? Function(String?)? validator;
  final String? hint;
  final String? selectedItem;

  @override
  State<Dropdown> createState() => _DropdownState();
}

class _DropdownState extends State<Dropdown> {
  String? initialSelect;
  String? errorText;

  @override
  Widget build(BuildContext context) {
    return DropdownSearch<String>(
      items: (f, cs) => widget.items,
      decoratorProps: DropDownDecoratorProps(
        decoration: InputDecoration(
          hintText: 'Please select...',
          hintStyle: context.body,
          contentPadding: AppPadding.small,
          filled: true,
          fillColor: AppColor.whiteColor,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: AppColor.lightGrey, width: 1),
          ),
          focusedBorder: OutlineInputBorder(
            borderSide: BorderSide(color: AppColor.primaryColor, width: 1),
            borderRadius: BorderRadius.circular(12),
          ),
          enabledBorder: OutlineInputBorder(
            borderSide: BorderSide(color: AppColor.lightGrey, width: 1),
            borderRadius: BorderRadius.circular(12),
          ),
          errorBorder: OutlineInputBorder(
            borderSide: BorderSide(color: AppColor.redColor, width: 1),
            borderRadius: BorderRadius.circular(12),
          ),
          errorText: errorText,
        ),
      ),
      popupProps: PopupProps.menu(fit: FlexFit.loose, showSearchBox: true),
      validator: widget.validator,
    );
  }
}
