import 'package:dropdown_search/dropdown_search.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gateway_config/core/constants/app_color.dart';
import 'package:gateway_config/core/constants/app_font.dart';
import 'package:gateway_config/core/constants/app_gap.dart';
import 'package:gateway_config/core/utils/extensions.dart';
import 'package:gateway_config/models/dropdown_items.dart';
import 'package:gateway_config/presentation/widgets/spesific/title_tile.dart';

class Dropdown extends StatefulWidget {
  final String? label;
  final List<DropdownItems> items;
  final void Function(DropdownItems?)? onChanged;
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
    _updateSelectedItem();
  }

  @override
  void didUpdateWidget(Dropdown oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Update kalo selectedValue atau items berubah
    if (oldWidget.selectedValue != widget.selectedValue ||
        oldWidget.items != widget.items) {
      _updateSelectedItem();
    }
  }

  void _updateSelectedItem() {
    if (widget.selectedValue != null) {
      initialSelect = widget.items.firstWhere(
        (item) => item.value == widget.selectedValue,
        orElse: () => DropdownItems(text: '', value: ''), // fallback kosong
      );
    } else {
      initialSelect = null;
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
          if (widget.label?.isNotEmpty == true) ...[
            Row(
              children: [
                Text(
                  widget.label!,
                  style: context.h6.copyWith(fontWeight: FontWeightTheme.bold),
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
          DropdownSearch<DropdownItems>(
            items: (filter, _) => widget.items,
            decoratorProps: _dropdownDecoratorProps(context),
            onChanged: widget.onChanged,
            selectedItem: initialSelect,
            popupProps: _popupProps(context),
            validator: (item) => widget.validator?.call(item?.value),
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
            compareFn: (a, b) => a.value == b.value,
          ),
          if (widget.hint?.isNotEmpty == true) ...[
            AppSpacing.sm,
            Text(
              widget.hint!,
              style: context.buttonTextSmall.copyWith(
                color: AppColor.lightGrey,
              ),
            ),
            AppSpacing.sm,
          ],
        ],
      ),
    );
  }

  PopupProps<DropdownItems> _popupProps(BuildContext context) {
    return PopupProps.menu(
      fit: FlexFit.loose,
      showSelectedItems: true,
      showSearchBox: widget.showSearchBox,
      constraints: const BoxConstraints(maxHeight: 300),
      searchFieldProps: _searchFieldProps(context),
      menuProps: MenuProps(
        backgroundColor: AppColor.whiteColor,
        elevation: 0,
        margin: const EdgeInsets.only(top: 5),
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
          child: menuWidget,
        );
      },
      itemBuilder: (context, item, isDisabled, isSelected) {
        final index = widget.items.indexOf(item);
        final previousGroup = index > 0 ? widget.items[index - 1].group : null;
        final showHeader = previousGroup != item.group;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (showHeader && (item.group?.isNotEmpty ?? false))
              Column(
                children: [
                  AppSpacing.sm,
                  TitleTile(title: item.group!),
                  AppSpacing.sm,
                ],
              ),
            Container(
              padding: EdgeInsets.symmetric(
                horizontal: 16.w.clamp(16, 18),
                vertical: 12.w.clamp(12, 14),
              ),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColor.lightPrimaryColor
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(10),
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
          ],
        );
      },
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
          borderSide: const BorderSide(color: AppColor.lightGrey, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: BorderSide(
            color: errorText != null ? Colors.red : AppColor.primaryColor,
            width: 1,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        enabledBorder: OutlineInputBorder(
          borderSide: const BorderSide(color: AppColor.lightGrey, width: 1),
          borderRadius: BorderRadius.circular(12),
        ),
        errorBorder: OutlineInputBorder(
          borderSide: const BorderSide(color: Colors.red, width: 1),
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
        hintText: 'Search here.',
        hintStyle: context.body.copyWith(color: AppColor.lightGrey),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColor.lightGrey, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: const BorderSide(color: AppColor.primaryColor, width: 1),
          borderRadius: BorderRadius.circular(12),
        ),
        enabledBorder: OutlineInputBorder(
          borderSide: const BorderSide(color: AppColor.lightGrey, width: 1),
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }
}
