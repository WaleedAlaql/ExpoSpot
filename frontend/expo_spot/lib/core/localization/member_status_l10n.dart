import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

/// Member row status lines (map sheet). Uses bundle first, then locale fallbacks
/// so new keys never flash as raw IDs before a full app restart.
abstract final class MemberStatusL10n {
  static String label(BuildContext context, String key) {
    final translated = key.tr();
    if (translated != key) return translated;

    final isAr = context.locale.languageCode == 'ar';
    return switch (key) {
      'status_en_route_cta' ||
      'mock_status_en_route' =>
        isAr ? 'في الطريق 🚶‍♂️' : 'En route 🚶‍♂️',
      'status_at_meet_point' ||
      'mock_status_at_point' =>
        isAr ? 'وصل للنقطة 🎯' : 'At the meet point 🎯',
      'status_low_battery' ||
      'mock_status_low_battery' =>
        isAr ? 'بطارية منخفضة 🪫' : 'Low battery 🪫',
      _ => translated,
    };
  }
}
