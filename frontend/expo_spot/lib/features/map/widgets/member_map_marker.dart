import 'package:easy_localization/easy_localization.dart';
import 'package:expo_spot/core/theme/app_colors.dart';
import 'package:expo_spot/core/theme/app_typography.dart';
import 'package:expo_spot/features/group/domain/group_member.dart';
import 'package:flutter/material.dart';

class MemberMapMarker extends StatelessWidget {
  const MemberMapMarker({
    super.key,
    required this.member,
    required this.pulse,
  });

  final GroupMember member;
  final Animation<double> pulse;

  Color get _dotColor {
    return switch (member.connection) {
      MemberConnection.online => AppColors.keppelGreen,
      MemberConnection.lowSignal => const Color(0xFFF5A623),
      MemberConnection.offline => AppColors.textMuted,
    };
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ScaleTransition(
          scale: Tween<double>(begin: 0.94, end: 1.06).animate(pulse),
          child: Container(
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: member.isCurrentUser
                    ? AppColors.keppelGreen
                    : Colors.white,
                width: member.isCurrentUser ? 2.5 : 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.bottleGreen.withValues(alpha: 0.25),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                CircleAvatar(
                  radius: 22,
                  backgroundColor: AppColors.background,
                  child: Icon(
                    Icons.person_rounded,
                    color: AppColors.bottleGreen.withValues(alpha: 0.85),
                    size: 26,
                  ),
                ),
                PositionedDirectional(
                  end: -1,
                  bottom: -1,
                  child: Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: _dotColor,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: AppColors.surface.withValues(alpha: 0.94),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.border),
          ),
          child: Text(
            member.nameKey.tr(),
            style: AppTypography.label(context).copyWith(
              fontSize: 10,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}

class MeetPointMarker extends StatelessWidget {
  const MeetPointMarker({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const LinearGradient(
              colors: [AppColors.keppelGreen, AppColors.bottleGreen],
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.keppelGreen.withValues(alpha: 0.45),
                blurRadius: 18,
                spreadRadius: 2,
              ),
            ],
          ),
          child: const Icon(Icons.place_rounded, color: Colors.white, size: 26),
        ),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: AppColors.bottleGreen,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            'meet_point_pin'.tr(),
            style: AppTypography.label(context).copyWith(
              color: Colors.white,
              fontSize: 10,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}
