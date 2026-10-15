import 'package:easy_localization/easy_localization.dart';
import 'package:expo_spot/core/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

abstract final class AppTypography {
  static bool _isArabic(BuildContext? context) {
    if (context == null) return true;
    return context.locale.languageCode == 'ar';
  }

  static TextStyle display([BuildContext? context]) {
    final style = _isArabic(context)
        ? GoogleFonts.ibmPlexSansArabic(
            fontSize: 28,
            fontWeight: FontWeight.w600,
            height: 1.25,
            color: AppColors.textPrimary,
            letterSpacing: -0.5,
          )
        : GoogleFonts.inter(
            fontSize: 28,
            fontWeight: FontWeight.w700,
            height: 1.25,
            color: AppColors.textPrimary,
            letterSpacing: -0.6,
          );
    return style;
  }

  static TextStyle subtitle([BuildContext? context]) {
    return _isArabic(context)
        ? GoogleFonts.ibmPlexSansArabic(
            fontSize: 15,
            fontWeight: FontWeight.w400,
            height: 1.5,
            color: AppColors.textMuted,
          )
        : GoogleFonts.inter(
            fontSize: 15,
            fontWeight: FontWeight.w400,
            height: 1.5,
            color: AppColors.textMuted,
          );
  }

  static TextStyle label([BuildContext? context]) {
    return _isArabic(context)
        ? GoogleFonts.ibmPlexSansArabic(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: AppColors.textMuted,
          )
        : GoogleFonts.inter(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: AppColors.textMuted,
          );
  }

  static TextStyle body([BuildContext? context]) {
    return _isArabic(context)
        ? GoogleFonts.ibmPlexSansArabic(
            fontSize: 16,
            fontWeight: FontWeight.w400,
            color: AppColors.textPrimary,
          )
        : GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w400,
            color: AppColors.textPrimary,
          );
  }

  static TextStyle button([BuildContext? context]) {
    return _isArabic(context)
        ? GoogleFonts.ibmPlexSansArabic(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          )
        : GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          );
  }

  static TextStyle englishMetric([BuildContext? context]) => GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: AppColors.textMuted,
      );

  static TextTheme textTheme(TextTheme base, BuildContext context) {
    return base.copyWith(
      headlineMedium: display(context),
      bodyLarge: body(context),
      bodyMedium: subtitle(context),
      labelLarge: label(context),
    );
  }
}
