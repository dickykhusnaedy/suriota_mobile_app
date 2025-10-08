import 'package:dropdown_search/dropdown_search.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gateway_config/core/constants/app_color.dart';
import 'package:gateway_config/core/constants/app_font.dart';
import 'package:gateway_config/core/constants/app_gap.dart';
import 'package:gateway_config/core/utils/extensions.dart';
import 'package:gateway_config/models/dropdown_items.dart';

class Dropdown extends StatefulWidget {
  final String? label;
  final List<DropdownItems> items;
  final void Function(DropdownItems?)? onChanged;
  final void Function(DropdownItems)? disabledItemFn;
  final String? Function(String?)? validator;
  final String? hint;
  final String? selectedValue;
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
    this.selectedValue,
    this.isDisabled = false,
    this.showSearchBox = false,
    this.isRequired = false,
  });

  @override
  State<Dropdown> createState() => _DropdownState();
}

class _DropdownState extends State<Dropdown> {
  DropdownItems? initialSelect;
  String? errorText;

  @override
  void initState() {
    super.initState();

    if (widget.selectedValue != null) {
      initialSelect = widget.items.firstWhere(
        (item) => item.value == widget.selectedValue,
        orElse: () => DropdownItems(text: '', value: ''),
      );
    }

    if (widget.validator != null && widget.selectedValue != null) {
      errorText = widget.validator!(widget.selectedValue);
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
          DropdownSearch<DropdownItems>(
            items: (filter, infiniteScrollProps) => widget.items,
            decoratorProps: _dropdownDecoratorProps(context),
            onChanged: (item) {
              if (widget.onChanged != null) {
                widget.onChanged!(item); // send text and value
              }
            },
            selectedItem: initialSelect,
            popupProps: _popupProps(context),
            validator: (item) {
              return widget.validator?.call(
                item?.value,
              ); // Validate berdasarkan value
            },
            dropdownBuilder: (context, selectedItem) {
              return Text(
                selectedItem?.text ?? 'Please select...',
                style: context.body.copyWith(
                  color: selectedItem?.text != null
                      ? AppColor.darkGrey
                      : AppColor.lightGrey,
                ),
              );
            },
            compareFn: (item1, item2) => item1.value == item2.value,
          ),
          if (widget.hint != null && widget.hint!.isNotEmpty)
            Column(
              children: [
                AppSpacing.sm,
                Text(
                  widget.hint!,
                  style: context.buttonTextSmall.copyWith(
                    color: AppColor.lightGrey,
                  ),
                ),
                AppSpacing.sm,
              ],
            ),
        ],
      ),
    );
  }

  PopupProps<DropdownItems> _popupProps(BuildContext context) {
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
          item.text,
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
