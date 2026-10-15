import 'package:easy_localization/easy_localization.dart';
import 'package:expo_spot/core/theme/app_colors.dart';
import 'package:expo_spot/core/theme/app_typography.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class LanguageSwitcher extends StatelessWidget {
  const LanguageSwitcher({super.key});

  @override
  Widget build(BuildContext context) {
    final isArabic = context.locale.languageCode == 'ar';

    return Align(
      alignment: AlignmentDirectional.topEnd,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: AppColors.surface.withValues(alpha: 0.92),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: AppColors.border),
        ),
        child: Padding(
          padding: const EdgeInsets.all(4),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _LangChip(
                label: 'language_ar'.tr(),
                selected: isArabic,
                onTap: () => _setLocale(context, const Locale('ar')),
              ),
              _LangChip(
                label: 'language_en'.tr(),
                selected: !isArabic,
                onTap: () => _setLocale(context, const Locale('en')),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _setLocale(BuildContext context, Locale locale) async {
    if (context.locale == locale) return;
    HapticFeedback.lightImpact();
    await context.setLocale(locale);
  }
}

/// Compact pill for toolbars (map header, etc.).
class LanguageSwitcherInline extends StatelessWidget {
  const LanguageSwitcherInline({super.key});

  @override
  Widget build(BuildContext context) {
    final isArabic = context.locale.languageCode == 'ar';

    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.surface.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColors.border),
      ),
      child: Padding(
        padding: const EdgeInsets.all(3),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _LangChip(
              label: 'language_ar'.tr(),
              selected: isArabic,
              onTap: () => _setLocale(context, const Locale('ar')),
            ),
            _LangChip(
              label: 'language_en'.tr(),
              selected: !isArabic,
              onTap: () => _setLocale(context, const Locale('en')),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _setLocale(BuildContext context, Locale locale) async {
    if (context.locale == locale) return;
    HapticFeedback.lightImpact();
    await context.setLocale(locale);
  }
}

class LanguageSwitcherOnDark extends StatelessWidget {
  const LanguageSwitcherOnDark({super.key});

  @override
  Widget build(BuildContext context) {
    final isArabic = context.locale.languageCode == 'ar';

    return Align(
      alignment: AlignmentDirectional.topEnd,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: Colors.white.withValues(alpha: 0.22)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(4),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _LangChip(
                label: 'language_ar'.tr(),
                selected: isArabic,
                onTap: () => _setLocale(context, const Locale('ar')),
                onDark: true,
              ),
              _LangChip(
                label: 'language_en'.tr(),
                selected: !isArabic,
                onTap: () => _setLocale(context, const Locale('en')),
                onDark: true,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _setLocale(BuildContext context, Locale locale) async {
    if (context.locale == locale) return;
    HapticFeedback.lightImpact();
    await context.setLocale(locale);
  }
}

class _LangChip extends StatelessWidget {
  const _LangChip({
    required this.label,
    required this.selected,
    required this.onTap,
    this.onDark = false,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final bool onDark;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: selected
                ? (onDark ? Colors.white : AppColors.bottleGreen)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(999),
          ),
          child: Text(
            label,
            style: AppTypography.label(context).copyWith(
              color: selected
                  ? (onDark ? AppColors.bottleGreen : Colors.white)
                  : (onDark ? Colors.white.withValues(alpha: 0.85) : AppColors.textMuted),
              fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }
}
