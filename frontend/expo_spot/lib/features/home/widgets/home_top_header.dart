import 'package:easy_localization/easy_localization.dart';
import 'package:expo_spot/core/theme/app_colors.dart';
import 'package:expo_spot/core/theme/app_typography.dart';
import 'package:flutter/material.dart';

/// Greeting row floating over the home map (no background card).
class HomeTopHeader extends StatelessWidget {
  const HomeTopHeader({super.key, required this.userName});

  final String userName;

  static const List<Shadow> _mapTextShadow = [
    Shadow(color: Colors.white, blurRadius: 10),
    Shadow(color: Color(0xCCFFFFFF), blurRadius: 18),
  ];

  String _greeting(BuildContext context) {
    if (context.locale.languageCode == 'ar') {
      return 'hello_user'.tr(namedArgs: {'name': userName});
    }
    final hour = DateTime.now().hour;
    if (hour < 12) return 'home_greeting_morning'.tr();
    if (hour < 17) return 'home_greeting_afternoon'.tr();
    return 'home_greeting_evening'.tr();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.surface,
            border: Border.all(color: Colors.white, width: 2),
            boxShadow: [
              BoxShadow(
                color: AppColors.bottleGreen.withValues(alpha: 0.18),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Icon(
            Icons.person_rounded,
            color: AppColors.bottleGreen.withValues(alpha: 0.85),
            size: 24,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _greeting(context),
                style: AppTypography.body(context).copyWith(
                  fontWeight: FontWeight.w700,
                  fontSize: 17,
                  color: AppColors.bottleGreen,
                  shadows: _mapTextShadow,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(
                    Icons.location_on_rounded,
                    size: 14,
                    color: AppColors.keppelGreen,
                    shadows: _mapTextShadow,
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      'home_venue_location'.tr(),
                      style: AppTypography.label(context).copyWith(
                        color: AppColors.bottleGreen.withValues(alpha: 0.78),
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        shadows: _mapTextShadow,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}
