import 'package:dropdown_search/dropdown_search.dart';
import 'package:flutter/material.dart';

import '../../constant/app_color.dart';
import '../../constant/font_setup.dart';

class CustomDropdown extends StatefulWidget {
  const CustomDropdown({
    super.key,
    required this.listItem,
    required this.hintText,
    this.selectedItem,
  });

  final List<String> listItem;
  final String? selectedItem;
  final String? hintText;

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
        baseStyle: FontFamily.normal,
        dropdownSearchDecoration: InputDecoration(
          hintText: widget.hintText,
          hintStyle: FontFamily.labelText,
          filled: true,
          fillColor: Colors.white, // Sama dengan CustomTextFormField
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(
              color: AppColor.primaryColor,
              width: 2,
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
              width: 2,
            ),
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 14),
        ),
      ),
      onChanged: (value) {
        setState(() {
          selectedBaudrate = value; // Mengupdate nilai baudrate yang dipilih
        });
      },
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
                style: FontFamily.normal,
                textCapitalization: TextCapitalization.characters,
                decoration: InputDecoration(
                    contentPadding: const EdgeInsets.all(6),
                    enabledBorder: const OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(8)),
                        borderSide:
                            BorderSide(color: AppColor.primaryColor, width: 2)),
                    focusedBorder: const OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(8)),
                        borderSide:
                            BorderSide(color: AppColor.primaryColor, width: 2)),
                    hintText: "Search",
                    hintStyle: FontFamily.labelText),
              ),
              itemBuilder: (context, item, isSelected) {
                return Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    color: isSelected
                        ? AppColor.primaryColor.withOpacity(0.1)
                        : null,
                  ),
                  child: Text(
                    item,
                    style: FontFamily.normal
                        .copyWith(color: AppColor.primaryColor),
                  ),
                );
              },
            )
          : PopupProps.menu(
              fit: FlexFit.loose,
              menuProps: const MenuProps(
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.all(Radius.circular(12)))),
              showSelectedItems: true,
              showSearchBox: false,
              // searchFieldProps: TextFieldProps(
              //   style: FontFamily.normal,
              //   textCapitalization: TextCapitalization.characters,
              //   decoration: InputDecoration(
              //       contentPadding: const EdgeInsets.all(6),
              //       enabledBorder: const OutlineInputBorder(
              //           borderRadius: BorderRadius.all(Radius.circular(8)),
              //           borderSide:
              //               BorderSide(color: AppColor.primaryColor, width: 2)),
              //       focusedBorder: const OutlineInputBorder(
              //           borderRadius: BorderRadius.all(Radius.circular(8)),
              //           borderSide:
              //               BorderSide(color: AppColor.primaryColor, width: 2)),
              //       hintText: "Search",
              //       hintStyle: FontFamily.labelText),
              // ),
              itemBuilder: (context, item, isSelected) {
                return Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    color: isSelected
                        ? AppColor.primaryColor.withOpacity(0.1)
                        : null,
                  ),
                  child: Text(
                    item,
                    style: FontFamily.normal
                        .copyWith(color: AppColor.primaryColor),
                  ),
                );
              },
            ),
    );
  }
}
