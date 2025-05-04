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
  String? selectedBaudrate;

  @override
  void initState() {
    super.initState();
    // Set nilai awal dari selectedBaudrate yang diterima dari widget
    selectedBaudrate = widget.selectedItem;
  }

  @override
  Widget build(BuildContext context) {
    return DropdownSearch<String>(
      items: widget.listItem,
      dropdownDecoratorProps: DropDownDecoratorProps(
        baseStyle: context.h6,
        dropdownSearchDecoration: InputDecoration(
          hintText: widget.hintText,
          hintStyle: context.body.copyWith(color: AppColor.grey),
          filled: true,
          fillColor: Colors.white, // Sama dengan CustomTextFormField
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(
              color: AppColor.primaryColor,
              width: 1,
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(
              color: AppColor.primaryColor,
              width: 2,
            ),
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(
              color: AppColor.primaryColor,
              width: 1,
            ),
          ),
          contentPadding: AppPadding.horizontalMedium,
        ),
      ),
      onChanged: widget.onChanged,
      selectedItem:
          selectedBaudrate?.isNotEmpty == true ? selectedBaudrate : null,
      // Mengatur props popup berdasarkan jumlah item
      popupProps: widget.listItem.length > 5
          ? PopupProps.dialog(
              fit: FlexFit.loose,
              dialogProps: const DialogProps(
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.all(Radius.circular(12))),
              ),
              showSelectedItems: true,
              showSearchBox: true,
              searchFieldProps: TextFieldProps(
                style: context.body,
                textCapitalization: TextCapitalization.characters,
                decoration: InputDecoration(
                    contentPadding: AppPadding.medium,
                    enabledBorder: const OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(8)),
                        borderSide:
                            BorderSide(color: AppColor.primaryColor, width: 1)),
                    focusedBorder: const OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(8)),
                        borderSide:
                            BorderSide(color: AppColor.primaryColor, width: 2)),
                    hintText: "Search",
                    hintStyle: context.body),
              ),
              itemBuilder: (context, item, isSelected) {
                return Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    color: isSelected
                        ? AppColor.primaryColor.withValues(alpha: 0.1)
                        : null,
                  ),
                  child: Text(
                    item,
                    style: context.body,
                  ),
                );
              },
            )
          : PopupProps.menu(
              fit: FlexFit.loose,
              menuProps: const MenuProps(
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.all(Radius.circular(4)))),
              showSelectedItems: true,
              showSearchBox: false,
              itemBuilder: (context, item, isSelected) {
                return Container(
                  padding: AppPadding.medium,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    color: isSelected
                        ? AppColor.primaryColor.withValues(alpha: 0.1)
                        : null,
                  ),
                  child: Text(
                    item,
                    style: context.body.copyWith(color: AppColor.primaryColor),
                  ),
                );
              },
            ),
    );
  }
}
