import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_radius.dart';

class StickyInput extends StatelessWidget {
  const StickyInput({
    super.key,
    String? hint,
    String? hintText,
    this.controller,
    this.onTap,
    this.onChanged,
    this.icon,
    this.suffix,
    this.minLines = 1,
    this.maxLines = 1,
  }) : hint = hint ?? hintText ?? '';

  final String hint;
  final TextEditingController? controller;
  final VoidCallback? onTap;
  final ValueChanged<String>? onChanged;
  final IconData? icon;
  final Widget? suffix;
  final int minLines;
  final int maxLines;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      onTap: onTap,
      onChanged: onChanged,
      minLines: minLines,
      maxLines: maxLines,
      decoration: InputDecoration(
        hintText: hint,
        prefixIcon: icon == null ? null : Icon(icon),
        suffixIcon: suffix,
        filled: true,
        fillColor: AppColors.noteYellow.withValues(alpha: 0.36),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.normal),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}
