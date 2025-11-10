import 'package:flutter/material.dart';
import 'package:gateway_config/core/constants/app_color.dart';
import 'package:gateway_config/core/constants/app_gap.dart';
import 'package:gateway_config/core/utils/extensions.dart';
import 'package:gateway_config/core/utils/snackbar_custom.dart';
import 'package:gateway_config/presentation/widgets/common/custom_textfield.dart';

/// Model controller untuk tiap baris header
class HeaderFieldController {
  final TextEditingController keyController;
  final TextEditingController valueController;

  HeaderFieldController({String? key, String? value})
    : keyController = TextEditingController(text: key ?? ''),
      valueController = TextEditingController(text: value ?? '');

  bool get isValid =>
      keyController.text.trim().isNotEmpty &&
      valueController.text.trim().isNotEmpty;

  /// ambil data dari controller
  Map<String, String> toMap() => {
    'key': keyController.text.trim(),
    'value': valueController.text.trim(),
  };

  void dispose() {
    keyController.dispose();
    valueController.dispose();
  }
}

class MultiHeaderForm extends StatefulWidget {
  /// controller list (bisa diisi dari data existing)
  final List<HeaderFieldController> controllers;

  /// callback kalau ada perubahan data
  final VoidCallback? onChanged;

  /// judul section
  final String title;

  /// aktifkan / matikan validasi inline
  final bool showValidation;

  const MultiHeaderForm({
    super.key,
    required this.controllers,
    this.onChanged,
    this.title = 'Headers',
    this.showValidation = true,
  });

  @override
  State<MultiHeaderForm> createState() => _MultiHeaderFormState();
}

class _MultiHeaderFormState extends State<MultiHeaderForm> {
  /// tambah baris baru
  void _addRow() {
    if (!_validateCurrentRows()) return;

    setState(() {
      widget.controllers.add(HeaderFieldController());
    });
    widget.onChanged?.call();
  }

  /// hapus baris
  void _removeRow(int index) {
    setState(() {
      widget.controllers.removeAt(index);
    });
    widget.onChanged?.call();
  }

  /// validasi kolom sebelum tambah row
  bool _validateCurrentRows() {
    if (!widget.showValidation) return true;

    final invalid = widget.controllers.any((controller) => !controller.isValid);
    if (invalid) {
      SnackbarCustom.showSnackbar(
        '',
        'Complete all columns before adding new rows ⚠️',
        Colors.orange,
        AppColor.whiteColor,
      );
      return false;
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    // support editable data: controller bisa diisi ulang dari data API
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header title & add button
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              widget.title,
              style: context.body.copyWith(fontWeight: FontWeight.w600),
            ),
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: _addRow,
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: AppColor.primaryColor,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.add,
                        size: 16,
                        color: AppColor.whiteColor,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Add',
                        style: context.bodySmall.copyWith(
                          color: AppColor.whiteColor,
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
        AppSpacing.sm,
        // Daftar header cards
        if (widget.controllers.isEmpty)
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColor.grey.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: AppColor.grey.withValues(alpha: 0.2),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline,
                  size: 16,
                  color: AppColor.grey.withValues(alpha: 0.7),
                ),
                const SizedBox(width: 8),
                Text(
                  'No headers added yet. Click Add to create one.',
                  style: context.bodySmall.copyWith(
                    color: AppColor.grey.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ),
          )
        else
          Column(
            children: [
              for (int i = 0; i < widget.controllers.length; i++) ...[
                Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  decoration: BoxDecoration(
                    color: AppColor.whiteColor,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: AppColor.grey.withValues(alpha: 0.25),
                      width: 1,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Card header with badge and delete button
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: AppColor.grey.withValues(alpha: 0.05),
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(8),
                            topRight: Radius.circular(8),
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: AppColor.primaryColor,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                '#${i + 1}',
                                style: context.bodySmall.copyWith(
                                  color: AppColor.whiteColor,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 11,
                                ),
                              ),
                            ),
                            const Spacer(),
                            Material(
                              color: Colors.transparent,
                              child: InkWell(
                                onTap: widget.controllers.length > 1
                                    ? () => _removeRow(i)
                                    : null,
                                borderRadius: BorderRadius.circular(4),
                                child: Container(
                                  padding: const EdgeInsets.all(4),
                                  child: Icon(
                                    Icons.close,
                                    size: 16,
                                    color: widget.controllers.length > 1
                                        ? Colors.red
                                        : AppColor.grey.withValues(alpha: 0.3),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Card content
                      Padding(
                        padding: const EdgeInsets.all(10),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Key field
                            CustomTextFormField(
                              controller: widget.controllers[i].keyController,
                              labelTxt: 'Key',
                              hintTxt: 'Key',
                              errorTxt:
                                  widget.showValidation &&
                                      widget.controllers[i].keyController.text
                                          .trim()
                                          .isEmpty
                                  ? 'Column must not empty'
                                  : null,
                              onChanges: (_) {
                                setState(() {});
                                widget.onChanged?.call();
                              },
                            ),
                            const SizedBox(height: 10),
                            // Value field
                            CustomTextFormField(
                              controller: widget.controllers[i].valueController,
                              labelTxt: 'Value',
                              hintTxt: 'Value',
                              errorTxt:
                                  widget.showValidation &&
                                      widget.controllers[i].valueController.text
                                          .trim()
                                          .isEmpty
                                  ? 'Column must not empty'
                                  : null,
                              onChanges: (_) {
                                setState(() {});
                                widget.onChanged?.call();
                              },
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
      ],
    );
  }

  @override
  void dispose() {
    // bersihin semua controller biar gak leak
    for (final c in widget.controllers) {
      c.dispose();
    }
    super.dispose();
  }
}
