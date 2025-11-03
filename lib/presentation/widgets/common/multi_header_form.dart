import 'package:flutter/material.dart';
import 'package:gateway_config/core/constants/app_color.dart';
import 'package:gateway_config/core/constants/app_gap.dart';
import 'package:gateway_config/core/utils/extensions.dart';
import 'package:gateway_config/core/utils/snackbar_custom.dart';
import 'package:gateway_config/presentation/widgets/common/custom_textfield.dart';
import 'package:gateway_config/presentation/widgets/common/reusable_widgets.dart';

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
              style: context.h6.copyWith(fontWeight: FontWeight.w600),
            ),
            CompactIconButton(
              icon: Icons.add,
              color: AppColor.primaryColor,
              onPressed: _addRow,
            ),
          ],
        ),
        AppSpacing.xs,
        // Daftar kolom header
        Column(
          children: [
            for (int i = 0; i < widget.controllers.length; i++) ...[
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Key column
                    Expanded(
                      flex: 4,
                      child: CustomTextFormField(
                        controller: widget.controllers[i].keyController,
                        hintTxt: 'Authorization',
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
                    ),
                    AppSpacing.sm,

                    // Value column
                    Expanded(
                      flex: 5,
                      child: CustomTextFormField(
                        controller: widget.controllers[i].valueController,
                        hintTxt: 'Bearer token',
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
                    ),
                    AppSpacing.sm,

                    // Delete button
                    IconButton.filled(
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.all(12),
                      ),
                      onPressed: widget.controllers.length > 1
                          ? () => _removeRow(i)
                          : null,
                      icon: const Icon(Icons.close, size: 16),
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
