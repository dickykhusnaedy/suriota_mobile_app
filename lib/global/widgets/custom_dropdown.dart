import 'package:dropdown_search/dropdown_search.dart';
import 'package:flutter/material.dart';
import 'package:suriota_mobile_gateway/constant/app_color.dart';
import 'package:suriota_mobile_gateway/constant/app_gap.dart';
import 'package:suriota_mobile_gateway/global/utils/text_extension.dart';

class CustomDropdown extends StatefulWidget {
  const CustomDropdown({
    super.key,
    required this.listItem,
    required this.hintText,
    this.onChanged,
    this.selectedItem,
  });

  final List<String> listItem;
  final String? selectedItem;
  final String? hintText;
  final void Function(String?)? onChanged;

  @override
  State<CustomDropdown> createState() => _CustomDropdownState();
}

class _CustomDropdownState extends State<CustomDropdown> {
  String? initialSelect;

  @override
  void initState() {
    super.initState();
    // Set nilai awal dari initialSelect yang diterima dari widget
    initialSelect = widget.selectedItem;
  }

  @override
  Widget build(BuildContext context) {
    return DropdownSearch<String>(
      items: widget.listItem,
      dropdownDecoratorProps: _buildDropdownDecoratorProps(context),
      onChanged: widget.onChanged,
      selectedItem: initialSelect?.isNotEmpty == true ? initialSelect : null,
      popupProps: _buildPopupProps(context),
    );
  }

  DropDownDecoratorProps _buildDropdownDecoratorProps(BuildContext context) {
    return DropDownDecoratorProps(
      baseStyle: context.h6,
      dropdownSearchDecoration: InputDecoration(
        hintText: widget.hintText,
        hintStyle: context.body.copyWith(color: AppColor.grey),
        filled: true,
        fillColor: Colors.white,
        enabledBorder: _buildOutlineInputBorder(AppColor.primaryColor, 1),
        focusedBorder: _buildOutlineInputBorder(AppColor.primaryColor, 2),
        border: _buildOutlineInputBorder(AppColor.primaryColor, 1),
        contentPadding: AppPadding.horizontalMedium,
      ),
    );
  }

  PopupProps<String> _buildPopupProps(BuildContext context) {
    return widget.listItem.length > 5
        ? PopupProps.dialog(
            fit: FlexFit.loose,
            dialogProps: const DialogProps(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.all(Radius.circular(12))),
            ),
            showSelectedItems: true,
            showSearchBox: true,
            searchFieldProps: _buildSearchFieldProps(context),
            itemBuilder: (context, item, isSelected) =>
                _buildPopupItem(context, item, isSelected),
          )
        : PopupProps.menu(
            fit: FlexFit.loose,
            menuProps: const MenuProps(
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.all(Radius.circular(4)))),
            showSelectedItems: true,
            showSearchBox: false,
            itemBuilder: (context, item, isSelected) =>
                _buildPopupItem(context, item, isSelected),
          );
  }

  TextFieldProps _buildSearchFieldProps(BuildContext context) {
    return TextFieldProps(
      style: context.body,
      textCapitalization: TextCapitalization.characters,
      decoration: InputDecoration(
        contentPadding: AppPadding.medium,
        enabledBorder: _buildOutlineInputBorder(AppColor.primaryColor, 1),
        focusedBorder: _buildOutlineInputBorder(AppColor.primaryColor, 2),
        hintText: "Search",
        hintStyle: context.body,
      ),
    );
  }

  Widget _buildPopupItem(BuildContext context, String item, bool isSelected) {
    return Container(
      padding: AppPadding.medium,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        color: isSelected ? AppColor.primaryColor.withValues(alpha: 0.1) : null,
      ),
      child: Text(
        item,
        style: context.body,
      ),
    );
  }

  OutlineInputBorder _buildOutlineInputBorder(Color color, double width) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(
        color: color,
        width: width,
      ),
    );
  }
}
