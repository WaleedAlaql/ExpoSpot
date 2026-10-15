import 'package:easy_localization/easy_localization.dart' hide TextDirection;
import 'package:expo_spot/core/theme/app_colors.dart';
import 'package:expo_spot/core/theme/app_radii.dart';
import 'package:expo_spot/core/theme/app_typography.dart';
import 'package:expo_spot/core/widgets/glass_panel.dart';
import 'package:expo_spot/features/group/application/active_group_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class PastGroupsSection extends ConsumerStatefulWidget {
  const PastGroupsSection({super.key});

  @override
  ConsumerState<PastGroupsSection> createState() => _PastGroupsSectionState();
}

class _PastGroupsSectionState extends ConsumerState<PastGroupsSection> {
  var _expanded = false;

  static const _groups = [
    _GroupItem(
      nameKey: 'group_family_name',
      statusKey: 'group_family_status',
      members: 5,
      online: 4,
    ),
    _GroupItem(
      nameKey: 'group_team_name',
      statusKey: 'group_team_status',
      members: 8,
      online: 6,
    ),
    _GroupItem(
      nameKey: 'group_visitors_name',
      statusKey: 'group_visitors_status',
      members: 12,
      online: 9,
    ),
  ];

  void _toggle() {
    HapticFeedback.lightImpact();
    setState(() => _expanded = !_expanded);
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedSize(
      duration: const Duration(milliseconds: 320),
      curve: Curves.fastOutSlowIn,
      alignment: Alignment.topCenter,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: _toggle,
              borderRadius: BorderRadius.circular(AppRadii.card),
              child: Ink(
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(AppRadii.card),
                  border: Border.all(color: AppColors.border),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.bottleGreen.withValues(alpha: 0.06),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.keppelGreen.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.history_rounded,
                        color: AppColors.keppelGreen,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'profile_groups_history_card'.tr(),
                            style: AppTypography.body(context).copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'active_groups_count'.tr(
                              namedArgs: {'count': '${_groups.length}'},
                            ),
                            style: AppTypography.label(context).copyWith(
                              color: AppColors.textMuted,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    AnimatedRotation(
                      turns: _expanded ? 0.5 : 0,
                      duration: const Duration(milliseconds: 280),
                      curve: Curves.fastOutSlowIn,
                      child: Icon(
                        Icons.expand_more_rounded,
                        color: AppColors.bottleGreen.withValues(alpha: 0.8),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (_expanded) ...[
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text(
                'profile_past_groups_title'.tr(),
                style: AppTypography.label(context).copyWith(
                  color: AppColors.keppelGreen,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            ...List.generate(_groups.length, (index) {
              final group = _groups[index];
              return Padding(
                padding: EdgeInsets.only(bottom: index == _groups.length - 1 ? 0 : 12),
                child: _PastGroupCard(
                  group: group,
                  onOpenMap: () {
                    HapticFeedback.lightImpact();
                    ref.read(mainShellIndexProvider.notifier).state = 1;
                  },
                ),
              );
            }),
          ],
        ],
      ),
    );
  }
}

class _GroupItem {
  const _GroupItem({
    required this.nameKey,
    required this.statusKey,
    required this.members,
    required this.online,
  });

  final String nameKey;
  final String statusKey;
  final int members;
  final int online;
}

class _PastGroupCard extends StatelessWidget {
  const _PastGroupCard({required this.group, required this.onOpenMap});

  final _GroupItem group;
  final VoidCallback onOpenMap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          HapticFeedback.lightImpact();
          onOpenMap();
        },
        borderRadius: BorderRadius.circular(AppRadii.card),
        child: GlassPanel(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      group.nameKey.tr(),
                      style: AppTypography.body(context).copyWith(fontWeight: FontWeight.w600),
                    ),
                  ),
                  Text(
                    '${group.online}/${group.members}',
                    style: AppTypography.englishMetric(context),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(group.statusKey.tr(), style: AppTypography.subtitle(context)),
              const SizedBox(height: 14),
              Row(
                children: [
                  _AvatarStack(count: group.members.clamp(1, 4)),
                  const Spacer(),
                  Text(
                    'view_map'.tr(),
                    style: AppTypography.label(context).copyWith(color: AppColors.keppelGreen),
                  ),
                  const SizedBox(width: 4),
                  Icon(
                    Directionality.of(context) == TextDirection.rtl
                        ? Icons.chevron_left
                        : Icons.chevron_right,
                    size: 18,
                    color: AppColors.keppelGreen,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AvatarStack extends StatelessWidget {
  const _AvatarStack({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 36,
      width: 28.0 * count + 8,
      child: Stack(
        children: List.generate(count, (i) {
          return PositionedDirectional(
            end: i * 22.0,
            child: Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.background,
                border: Border.all(color: AppColors.border),
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  CircleAvatar(
                    radius: 14,
                    backgroundColor: AppColors.keppelGreen.withValues(alpha: 0.15 + i * 0.05),
                    child: Icon(
                      Icons.person,
                      size: 16,
                      color: AppColors.bottleGreen.withValues(alpha: 0.7),
                    ),
                  ),
                  if (i == 0)
                    PositionedDirectional(
                      bottom: 2,
                      start: 2,
                      child: Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: AppColors.keppelGreen,
                          shape: BoxShape.circle,
                          border: Border.all(color: AppColors.surface, width: 1.5),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }
}
