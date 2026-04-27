import 'package:flutter/material.dart';

import 'app_colors.dart';

class AppShadows {
  static const card = [
    BoxShadow(
      color: AppColors.cardShadow,
      blurRadius: 12,
      offset: Offset(0, 6),
    ),
  ];

  static const floating = [
    BoxShadow(color: Color(0x22000000), blurRadius: 18, offset: Offset(0, 9)),
  ];
}
