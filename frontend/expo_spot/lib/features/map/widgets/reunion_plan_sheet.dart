import 'dart:ui';

import 'package:easy_localization/easy_localization.dart';
import 'package:expo_spot/core/theme/app_colors.dart';
import 'package:expo_spot/core/theme/app_radii.dart';
import 'package:expo_spot/core/theme/app_typography.dart';
import 'package:expo_spot/features/group/application/active_group_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

Future<void> showReunionPlanSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black.withValues(alpha: 0.35),
    builder: (ctx) => const _ReunionPlanSheet(),
  );
}

class _ReunionPlanSheet extends ConsumerWidget {
  const _ReunionPlanSheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final group = ref.watch(activeGroupProvider);

    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        bottom: MediaQuery.viewPaddingOf(context).bottom + 16,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppRadii.card + 4),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 22, sigmaY: 22),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: AppColors.surface.withValues(alpha: 0.96),
              borderRadius: BorderRadius.circular(AppRadii.card + 4),
              border: Border.all(color: AppColors.border),
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'reunion_plan_title'.tr(),
                    style: AppTypography.display(context).copyWith(fontSize: 20),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'reunion_plan_sub'.tr(),
                    style: AppTypography.subtitle(context),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      borderRadius: BorderRadius.circular(AppRadii.card),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.place_rounded, color: AppColors.keppelGreen),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            group.meetPointLabelKey.tr(),
                            style: AppTypography.body(context).copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  ...group.members.map((member) {
                    final eta = member.etaMinutes ?? 0;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Text(
                        'member_eta'.tr(namedArgs: {
                          'name': member.displayName ?? member.nameKey.tr(),
                          'minutes': '$eta',
                        }),
                        style: AppTypography.body(context).copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    );
                  }),
                  const SizedBox(height: 12),
                  _PrimarySheetButton(
                    label: 'confirm_meeting_point'.tr(),
                    onPressed: () {
                      HapticFeedback.mediumImpact();
                      ref.read(activeGroupProvider.notifier).confirmReunionPoint();
                      Navigator.of(context).pop();
                    },
                  ),
                  const SizedBox(height: 10),
                  TextButton(
                    onPressed: () {
                      HapticFeedback.lightImpact();
                      ref.read(activeGroupProvider.notifier).cycleAlternateMeetPoint();
                    },
                    child: Text(
                      'alternate_meeting_point'.tr(),
                      style: AppTypography.body(context).copyWith(
                        color: AppColors.bottleGreen,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _PrimarySheetButton extends StatelessWidget {
  const _PrimarySheetButton({required this.label, required this.onPressed});

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.bottleGreen,
      borderRadius: BorderRadius.circular(AppRadii.button),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(AppRadii.button),
        child: SizedBox(
          height: 52,
          child: Center(
            child: Text(
              label,
              style: AppTypography.button(context).copyWith(color: Colors.white),
            ),
          ),
        ),
      ),
    );
  }
}
