import 'package:flutter/material.dart';

class ToolModel {
  final String titleKey;
  final String descriptionKey;
  final IconData icon;
  final LinearGradient gradient;
  final String route;
  final bool isComingSoon;

  const ToolModel({
    required this.titleKey,
    required this.descriptionKey,
    required this.icon,
    required this.gradient,
    required this.route,
    this.isComingSoon = false,
  });
}
