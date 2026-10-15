import 'dart:ui';

import 'package:easy_localization/easy_localization.dart';
import 'package:expo_spot/core/theme/app_colors.dart';
import 'package:expo_spot/core/theme/app_radii.dart';
import 'package:expo_spot/core/theme/app_typography.dart';
import 'package:expo_spot/features/group/application/active_group_controller.dart';
import 'package:expo_spot/features/group/domain/group_member.dart';
import 'package:expo_spot/features/map/widgets/reunion_plan_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class MapMembersSheet extends ConsumerWidget {
  const MapMembersSheet({super.key, required this.scrollController});

  final ScrollController scrollController;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final group = ref.watch(activeGroupProvider);

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: AppColors.surface.withValues(alpha: 0.92),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            border: Border.all(color: AppColors.border.withValues(alpha: 0.85)),
            boxShadow: [
              BoxShadow(
                color: AppColors.bottleGreen.withValues(alpha: 0.12),
                blurRadius: 28,
                offset: const Offset(0, -8),
              ),
            ],
          ),
          child: CustomScrollView(
            controller: scrollController,
            slivers: [
              SliverToBoxAdapter(
                child: Column(
                  children: [
                    const SizedBox(height: 10),
                    Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: AppColors.border,
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                      child: Row(
                        children: [
                          Text(
                            'map_members_title'.tr(),
                            style: AppTypography.display(context).copyWith(fontSize: 18),
                          ),
                          const Spacer(),
                          Text(
                            'map_member_count'.tr(namedArgs: {
                              'online': '${group.onlineCount}',
                              'total': '${group.totalMembers}',
                            }),
                            style: AppTypography.label(context).copyWith(
                              color: AppColors.keppelGreen,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                sliver: SliverList.separated(
                  itemCount: group.members.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    return _MemberRow(member: group.members[index]);
                  },
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 18, 20, 28),
                  child: _SmartReunifyButton(
                    onPressed: () async {
                      HapticFeedback.mediumImpact();
                      ref.read(activeGroupProvider.notifier).beginSmartReunionPlan();
                      await showReunionPlanSheet(context);
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MemberRow extends StatelessWidget {
  const _MemberRow({required this.member});

  final GroupMember member;

  Color get _statusColor {
    return switch (member.connection) {
      MemberConnection.online => AppColors.keppelGreen,
      MemberConnection.lowSignal => const Color(0xFFF5A623),
      MemberConnection.offline => AppColors.textMuted,
    };
  }

  String _statusLabel(BuildContext context) {
    if (member.travelStatus == MemberTravelStatus.arrived) {
      return 'status_arrived'.tr();
    }
    return 'status_en_route'.tr();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
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
                radius: 22,
                backgroundColor: AppColors.keppelGreen.withValues(alpha: 0.15),
                child: Icon(Icons.person, color: AppColors.bottleGreen.withValues(alpha: 0.8)),
              ),
              PositionedDirectional(
                end: -2,
                bottom: -2,
                child: Container(
                  width: 11,
                  height: 11,
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
                Text(
                  member.nameKey.tr(),
                  style: AppTypography.body(context).copyWith(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 2),
                Text(
                  _statusLabel(context),
                  style: AppTypography.label(context).copyWith(color: AppColors.keppelGreen),
                ),
                Text(
                  'status_last_update'.tr(
                    namedArgs: {'minutes': '${member.lastUpdateMinutes}'},
                  ),
                  style: AppTypography.label(context).copyWith(
                    color: AppColors.textMuted,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          if (member.etaMinutes != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.bottleGreen.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(AppRadii.badge),
              ),
              child: Text(
                'member_eta_short'.tr(namedArgs: {'minutes': '${member.etaMinutes}'}),
                style: AppTypography.englishMetric(context).copyWith(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _SmartReunifyButton extends StatefulWidget {
  const _SmartReunifyButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  State<_SmartReunifyButton> createState() => _SmartReunifyButtonState();
}

class _SmartReunifyButtonState extends State<_SmartReunifyButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _glow;

  @override
  void initState() {
    super.initState();
    _glow = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _glow.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _glow,
      builder: (context, child) {
        return Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadii.button),
            boxShadow: [
              BoxShadow(
                color: AppColors.keppelGreen.withValues(alpha: 0.25 + _glow.value * 0.2),
                blurRadius: 22 + _glow.value * 8,
                spreadRadius: _glow.value * 2,
              ),
            ],
          ),
          child: child,
        );
      },
      child: Material(
        color: AppColors.bottleGreen,
        borderRadius: BorderRadius.circular(AppRadii.button),
        child: InkWell(
          onTap: widget.onPressed,
          borderRadius: BorderRadius.circular(AppRadii.button),
          child: SizedBox(
            height: 56,
            child: Center(
              child: Text(
                'smart_reunify_cta'.tr(),
                style: AppTypography.button(context).copyWith(
                  color: Colors.white,
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
