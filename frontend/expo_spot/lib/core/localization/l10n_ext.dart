import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

extension ExpoL10n on BuildContext {
  /// Resolves [key], then [fallbackKey] if the bundle still returns the raw key.
  String l10n(String key, {String? fallbackKey}) {
    final primary = tr(key);
    if (primary != key) return primary;
    if (fallbackKey != null) {
      final fallback = tr(fallbackKey);
      if (fallback != fallbackKey) return fallback;
    }
    return primary;
  }
}
