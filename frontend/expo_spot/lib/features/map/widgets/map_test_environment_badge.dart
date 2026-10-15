import 'dart:ui';

import 'package:expo_spot/core/theme/app_colors.dart';
import 'package:expo_spot/core/theme/app_typography.dart';
import 'package:flutter/material.dart';

/// Subtle evaluator-facing label for Expo Dubai reference map testing.
class MapTestEnvironmentBadge extends StatelessWidget {
  const MapTestEnvironmentBadge({super.key});

  static const _label =
      'بيئة الاختبار: خريطة إكسبو دبي التمرسية';

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(999),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: AppColors.bottleGreen.withValues(alpha: 0.82),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: AppColors.keppelGreen.withValues(alpha: 0.45),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 7,
                  height: 7,
                  decoration: const BoxDecoration(
                    color: AppColors.keppelGreen,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  _label,
                  style: AppTypography.label(context).copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
