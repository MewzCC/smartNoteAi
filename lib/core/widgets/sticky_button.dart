import 'package:flutter/material.dart';
import 'package:getwidget/getwidget.dart';

import '../theme/app_colors.dart';
import '../theme/app_radius.dart';

class StickyButton extends StatelessWidget {
  const StickyButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.secondary = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool secondary;

  @override
  Widget build(BuildContext context) {
    return GFButton(
      onPressed: onPressed,
      text: label,
      icon: icon == null ? null : Icon(icon, size: 18),
      color: secondary ? Colors.white : AppColors.primary,
      textColor: AppColors.accentText,
      borderShape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.normal),
        side: BorderSide(
          color: secondary ? AppColors.border : AppColors.primary,
        ),
      ),
      size: GFSize.LARGE,
      fullWidthButton: true,
    );
  }
}
