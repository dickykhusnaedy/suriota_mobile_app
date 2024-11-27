import 'package:flutter/material.dart';

import '../../constant/app_color.dart';
import '../../constant/font_setup.dart';

class CustomRadioTile extends StatelessWidget {
  final String value;
  final String grupValue;
  final void Function() onChanges;

  const CustomRadioTile({
    super.key,
    required this.value,
    required this.grupValue,
    required this.onChanges,
  });

  bool get isSelected => value == grupValue;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      visualDensity: VisualDensity.lerp(
        const VisualDensity(horizontal: -4, vertical: -4),
        const VisualDensity(horizontal: -4, vertical: -4),
        0,
      ),
      minVerticalPadding: 0,
      dense: true,
      contentPadding: EdgeInsets.zero,
      title: Text(value),
      titleTextStyle:
          isSelected ? FontFamily.headlineMedium : FontFamily.normal,
      onTap: () {
        onChanges();
      },
      isThreeLine: false,
      horizontalTitleGap: 12,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      leading: Radio(
        // toggleable: false,
        visualDensity: const VisualDensity(horizontal: -4, vertical: -4),
        activeColor: AppColor.primaryColor,
        focusColor: AppColor.primaryColor,

        overlayColor: const WidgetStatePropertyAll(Colors.transparent),
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        value: value,
        groupValue: grupValue,
        onChanged: (value) {
          onChanges();
        },
      ),
    );
  }
}
