import 'dart:ui';

import 'package:easy_localization/easy_localization.dart';
import 'package:expo_spot/core/theme/app_colors.dart';
import 'package:expo_spot/core/theme/app_radii.dart';
import 'package:expo_spot/core/theme/app_typography.dart';
import 'package:expo_spot/core/widgets/expo_mesh_background.dart';
import 'package:expo_spot/core/widgets/glass_panel.dart';
import 'package:expo_spot/features/group/application/active_group_controller.dart';
import 'package:expo_spot/features/group/presentation/create_group_sheet.dart';
import 'package:expo_spot/features/group/presentation/join_group_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class HomeDashboardTab extends ConsumerWidget {
  const HomeDashboardTab({super.key, required this.userName});

  final String userName;

  List<_GroupItem> _mockGroups() => const [
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

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final groups = _mockGroups();

    return ExpoMeshBackground(
      child: SafeArea(
        bottom: false,
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(AppRadii.card),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'app_name'.tr(),
                                  style: AppTypography.englishMetric(context).copyWith(
                                    color: AppColors.keppelGreen,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                Text(
                                  'hub_groups_center'.tr(),
                                  style: AppTypography.button(context).copyWith(fontSize: 18),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: AppColors.keppelGreen.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(AppRadii.badge),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 8,
                                  height: 8,
                                  decoration: const BoxDecoration(
                                    color: AppColors.keppelGreen,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  'online'.tr(),
                                  style: AppTypography.label(context).copyWith(
                                    color: Colors.white,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                child: _HeroBanner(userName: userName),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                child: Row(
                  children: [
                    Expanded(
                      child: _ActionCard(
                        title: 'create_group'.tr(),
                        subtitle: 'create_group_sub'.tr(),
                        icon: Icons.qr_code_2_rounded,
                        accent: AppColors.keppelGreen,
                        onTap: () {
                          HapticFeedback.lightImpact();
                          showCreateGroupSheet(context);
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _ActionCard(
                        title: 'join_qr'.tr(),
                        subtitle: 'join_qr_sub'.tr(),
                        icon: Icons.qr_code_scanner_rounded,
                        accent: AppColors.bottleGreen,
                        onTap: () {
                          HapticFeedback.lightImpact();
                          showJoinGroupSheet(context);
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 22, 20, 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'recent_groups'.tr(),
                      style: AppTypography.display(context).copyWith(fontSize: 18),
                    ),
                    Text(
                      'active_groups_count'.tr(namedArgs: {'count': '3'}),
                      style: AppTypography.label(context).copyWith(color: AppColors.keppelGreen),
                    ),
                  ],
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 120),
              sliver: SliverList.separated(
                itemCount: groups.length,
                separatorBuilder: (_, _) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  return _RecentGroupCard(
                    group: groups[index],
                    onOpenMap: () {
                      HapticFeedback.lightImpact();
                      ref.read(mainShellIndexProvider.notifier).state = 1;
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HeroBanner extends StatelessWidget {
  const _HeroBanner({required this.userName});

  final String userName;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadii.card),
        gradient: LinearGradient(
          begin: AlignmentDirectional.topEnd,
          end: AlignmentDirectional.bottomStart,
          colors: [
            AppColors.bottleGreen,
            AppColors.bottleGreen.withValues(alpha: 0.88),
            AppColors.keppelGreen.withValues(alpha: 0.75),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.keppelGreen.withValues(alpha: 0.28),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'hello_user'.tr(namedArgs: {'name': userName}),
            style: AppTypography.display(context).copyWith(
              color: Colors.white,
              fontSize: 24,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'hero_subtitle'.tr(),
            style: AppTypography.subtitle(context).copyWith(
              color: Colors.white.withValues(alpha: 0.88),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _StatChip(label: 'stat_active_groups'.tr()),
              const SizedBox(width: 8),
              _StatChip(label: 'stat_online_members'.tr()),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  const _StatChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(AppRadii.badge),
        border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
      ),
      child: Text(
        label,
        style: AppTypography.label(context).copyWith(
          color: Colors.white,
          fontSize: 11,
        ),
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  const _ActionCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.accent,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Color accent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadii.card),
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadii.card),
            color: AppColors.surface,
            border: Border.all(color: AppColors.border),
            boxShadow: [
              BoxShadow(
                color: accent.withValues(alpha: 0.12),
                blurRadius: 16,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: accent, size: 26),
                ),
                const SizedBox(height: 12),
                Text(
                  title,
                  style: AppTypography.body(context).copyWith(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 4),
                Text(subtitle, style: AppTypography.label(context)),
              ],
            ),
          ),
        ),
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

class _RecentGroupCard extends StatelessWidget {
  const _RecentGroupCard({required this.group, required this.onOpenMap});

  final _GroupItem group;
  final VoidCallback onOpenMap;

  @override
  Widget build(BuildContext context) {
    return GlassPanel(
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
              TextButton.icon(
                onPressed: onOpenMap,
                icon: const Icon(Icons.map_outlined, size: 18, color: AppColors.keppelGreen),
                label: Text(
                  'view_map'.tr(),
                  style: AppTypography.label(context).copyWith(color: AppColors.keppelGreen),
                ),
              ),
            ],
          ),
        ],
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
