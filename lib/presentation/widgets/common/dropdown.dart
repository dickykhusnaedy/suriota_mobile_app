import 'package:dropdown_search/dropdown_search.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gateway_config/core/constants/app_color.dart';
import 'package:gateway_config/core/constants/app_font.dart';
import 'package:gateway_config/core/constants/app_gap.dart';
import 'package:gateway_config/core/utils/extensions.dart';

class Dropdown extends StatefulWidget {
  final String? label;
  final List<String> items;
  final void Function(String?)? onChanged;
  final void Function(String?)? disabledItemFn;
  final String? Function(String?)? validator;
  final String? hint;
  final String? selectedItem;
  final bool isDisabled;
  final bool showSearchBox;
  final bool isRequired;

  const Dropdown({
    super.key,
    this.label,
    required this.items,
    this.onChanged,
    this.disabledItemFn,
    this.validator,
    this.hint,
    this.selectedItem,
    this.isDisabled = false,
    this.showSearchBox = false,
    this.isRequired = false,
  });

  @override
  State<Dropdown> createState() => _DropdownState();
}

class _DropdownState extends State<Dropdown> {
  String? initialSelect;
  String? errorText;

  @override
  void initState() {
    super.initState();

    if (widget.validator != null && initialSelect != null) {
      errorText = widget.validator!(initialSelect);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AbsorbPointer(
      absorbing: widget.isDisabled,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (widget.label != null && widget.label!.isNotEmpty)
            Column(
              children: [
                Row(
                  children: [
                    Text(
                      widget.label!,
                      style: context.h6.copyWith(
                        fontWeight: FontWeightTheme.bold,
                      ),
                    ),
                    AppSpacing.xs,
                    if (widget.isRequired)
                      Text(
                        '*required',
                        style: context.buttonTextSmallest.copyWith(
                          color: Colors.red,
                        ),
                      ),
                  ],
                ),
                AppSpacing.sm,
              ],
            ),
          DropdownSearch<String>(
            items: (filter, infiniteScrollProps) => widget.items,
            decoratorProps: _dropdownDecoratorProps(context),
            onChanged: widget.onChanged,
            selectedItem: widget.selectedItem,
            popupProps: _popupProps(context),
            validator: widget.validator,
          ),
        ],
      ),
    );
  }

  PopupProps<String> _popupProps(BuildContext context) {
    return PopupProps.menu(
      fit: FlexFit.loose,
      showSelectedItems: true,
      showSearchBox: widget.showSearchBox,
      constraints: BoxConstraints(maxHeight: 300),
      searchFieldProps: _searchFieldProps(context),
      menuProps: MenuProps(
        backgroundColor: AppColor.whiteColor,
        elevation: 0,
        margin: EdgeInsets.only(top: 5),
        borderRadius: BorderRadius.circular(14),
      ),
      containerBuilder: (context, menuWidget) {
        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: AppColor.lightGrey, width: 1),
            borderRadius: BorderRadius.circular(14),
          ),
          padding: AppPadding.smallest,
          child: menuWidget, // wajib! ini isi menu aslinya
        );
      },
      itemBuilder: (context, item, isDisabled, isSelected) => Container(
        padding: EdgeInsets.symmetric(
          horizontal: 16.w.clamp(16, 18),
          vertical: 12.w.clamp(12, 14),
        ),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColor
                    .lightPrimaryColor // background kalau terpilih
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          item,
          style: isDisabled
              ? context.body.copyWith(
                  color: AppColor.lightGrey,
                  fontStyle: FontStyle.italic,
                )
              : isSelected
              ? context.body.copyWith(
                  color: AppColor.primaryColor,
                  fontWeight: FontWeightTheme.bold,
                )
              : context.body,
        ),
      ),
    );
  }

  DropDownDecoratorProps _dropdownDecoratorProps(BuildContext context) {
    return DropDownDecoratorProps(
      decoration: InputDecoration(
        hintText: 'Please select...',
        hintStyle: context.body.copyWith(color: AppColor.lightGrey),
        contentPadding: AppPadding.small,
        filled: true,
        fillColor: widget.isDisabled ? Colors.grey[200] : Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColor.lightGrey, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: BorderSide(
            color: errorText != null ? Colors.red : AppColor.primaryColor,
            width: 1,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        enabledBorder: OutlineInputBorder(
          borderSide: BorderSide(color: AppColor.lightGrey, width: 1),
          borderRadius: BorderRadius.circular(12),
        ),
        errorBorder: OutlineInputBorder(
          borderSide: BorderSide(color: Colors.red, width: 1),
          borderRadius: BorderRadius.circular(12),
        ),
        errorText: errorText,
      ),
    );
  }

  TextFieldProps _searchFieldProps(BuildContext context) {
    return TextFieldProps(
      decoration: InputDecoration(
        contentPadding: AppPadding.small,
        hintText: 'Search here...',
        hintStyle: context.body.copyWith(color: AppColor.lightGrey),
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
      ),
    );
  }
}
