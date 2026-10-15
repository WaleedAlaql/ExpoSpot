import 'dart:ui';

import 'package:easy_localization/easy_localization.dart';
import 'package:expo_spot/core/theme/app_colors.dart';
import 'package:expo_spot/core/theme/app_radii.dart';
import 'package:expo_spot/core/theme/app_typography.dart';
import 'package:expo_spot/features/group/application/active_group_controller.dart';
import 'package:expo_spot/features/group/domain/group_member.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class MapArrivalOverlay extends ConsumerWidget {
  const MapArrivalOverlay({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final group = ref.watch(activeGroupProvider);
    if (!group.reunionConfirmed && !group.showRoutes) {
      return const SizedBox.shrink();
    }

    final user = group.currentUser;
    if (user == null) return const SizedBox.shrink();

    final isArrived = user.travelStatus == MemberTravelStatus.arrived;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(AppRadii.card),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.bottleGreen.withValues(alpha: 0.92),
                borderRadius: BorderRadius.circular(AppRadii.card),
                border: Border.all(
                  color: AppColors.keppelGreen.withValues(alpha: 0.35),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'arrival_progress'.tr(namedArgs: {
                        'arrived': '${group.activeArrivedCount}',
                        'total': '${group.activeParticipantCount}',
                      }),
                      style: AppTypography.body(context).copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  SizedBox(
                    width: 44,
                    height: 44,
                    child: CircularProgressIndicator(
                      value: group.activeParticipantCount == 0
                          ? 0
                          : group.activeArrivedCount / group.activeParticipantCount,
                      strokeWidth: 4,
                      backgroundColor: Colors.white.withValues(alpha: 0.2),
                      color: AppColors.keppelGreen,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 10),
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () {
              HapticFeedback.heavyImpact();
              ref.read(activeGroupProvider.notifier).toggleCurrentUserTravelStatus();
            },
            borderRadius: BorderRadius.circular(AppRadii.button),
            child: Ink(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: AppColors.surface.withValues(alpha: 0.94),
                borderRadius: BorderRadius.circular(AppRadii.button),
                border: Border.all(color: AppColors.border),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.keppelGreen.withValues(alpha: 0.15),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    isArrived ? 'status_arrived_cta'.tr() : 'status_en_route_cta'.tr(),
                    style: AppTypography.button(context).copyWith(
                      color: AppColors.bottleGreen,
                      fontSize: 15,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
