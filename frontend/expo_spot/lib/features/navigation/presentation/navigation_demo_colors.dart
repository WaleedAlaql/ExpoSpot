import 'package:flutter/material.dart';

abstract final class NavigationDemoColors {
  static const palette = <Color>[
    Color(0xFF34B78F),
    Color(0xFF1A73E8),
    Color(0xFFF5A623),
    Color(0xFF8E44AD),
    Color(0xFFE74C3C),
  ];

  static Color forVisitorId(int id) => palette[id.abs() % palette.length];
}
