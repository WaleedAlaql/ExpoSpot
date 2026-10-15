import 'package:easy_localization/easy_localization.dart';
import 'package:expo_spot/core/localization/l10n_ext.dart';
import 'package:expo_spot/core/theme/app_colors.dart';
import 'package:expo_spot/core/theme/app_radii.dart';
import 'package:expo_spot/core/theme/app_typography.dart';
import 'package:expo_spot/features/group/domain/group_member.dart';
import 'package:flutter/material.dart';

class GroupMemberTile extends StatelessWidget {
  const GroupMemberTile({
    super.key,
    required this.member,
    this.compact = false,
  });

  final GroupMember member;
  final bool compact;

  Color get _statusColor {
    return switch (member.connection) {
      MemberConnection.online => AppColors.keppelGreen,
      MemberConnection.lowSignal => const Color(0xFFF5A623),
      MemberConnection.offline => AppColors.textMuted,
    };
  }

  @override
  Widget build(BuildContext context) {
    final avatarRadius = compact ? 18.0 : 22.0;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 12 : 14,
        vertical: compact ? 10 : 12,
      ),
      decoration: BoxDecoration(
        color: AppColors.background.withValues(alpha: 0.65),
        borderRadius: BorderRadius.circular(AppRadii.card),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              CircleAvatar(
                radius: avatarRadius,
                backgroundColor: AppColors.keppelGreen.withValues(alpha: 0.15),
                child: Icon(
                  Icons.person_rounded,
                  size: compact ? 18 : 22,
                  color: AppColors.bottleGreen.withValues(alpha: 0.85),
                ),
              ),
              PositionedDirectional(
                end: -2,
                bottom: -2,
                child: Container(
                  width: compact ? 10 : 11,
                  height: compact ? 10 : 11,
                  decoration: BoxDecoration(
                    color: _statusColor,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.surface, width: 2),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        member.displayName ?? member.nameKey.tr(),
                        style: AppTypography.body(context).copyWith(
                          fontWeight: FontWeight.w600,
                          fontSize: compact ? 14 : 15,
                        ),
                      ),
                    ),
                    if (member.isCurrentUser)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppColors.keppelGreen.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(AppRadii.badge),
                        ),
                        child: Text(
                          context.l10n('create_group_host_badge', fallbackKey: 'online'),
                          style: AppTypography.label(context).copyWith(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: AppColors.keppelGreen,
                          ),
                        ),
                      ),
                  ],
                ),
                if (!compact) ...[
                  const SizedBox(height: 2),
                  Text(
                    member.connection == MemberConnection.offline
                        ? context.l10n('status_offline', fallbackKey: 'offline')
                        : context.l10n('status_online', fallbackKey: 'online'),
                    style: AppTypography.label(context).copyWith(
                      color: member.connection == MemberConnection.offline
                          ? AppColors.textMuted
                          : AppColors.keppelGreen,
                      fontSize: 11,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
