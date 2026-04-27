import 'package:flutter/material.dart';

class AchievementModel {
  const AchievementModel({
    required this.title,
    required this.desc,
    required this.icon,
    required this.color,
  });

  final String title;
  final String desc;
  final IconData icon;
  final Color color;
}
