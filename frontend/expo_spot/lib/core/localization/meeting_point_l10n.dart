import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

/// Map + sheet copy for venue meeting points (backend names stay English).
abstract final class MeetingPointL10n {
  static String trKey(BuildContext context, String key) =>
      key.tr(context: context);

  static String venueName(BuildContext context, String backendName) {
    final key = _venueKeyForName(backendName);
    if (key != null) return key.tr(context: context);
    return backendName;
  }

  static String? _venueKeyForName(String name) {
    final normalized = name.trim();
    return switch (normalized) {
      'Earth Plaza' => 'venue_name_earth_plaza',
      'Sea Plaza' => 'venue_name_sea_plaza',
      'Sun Plaza' => 'venue_name_sun_plaza',
      _ => null,
    };
  }

  static String labelFromMeetPointKey(BuildContext context, String key) =>
      key.tr(context: context);
}
