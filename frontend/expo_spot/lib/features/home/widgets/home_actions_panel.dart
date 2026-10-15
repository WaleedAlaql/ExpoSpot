import 'package:easy_localization/easy_localization.dart';
import 'package:expo_spot/core/theme/app_colors.dart';
import 'package:expo_spot/core/theme/app_typography.dart';
import 'package:expo_spot/features/group/presentation/create_group_sheet.dart';
import 'package:expo_spot/features/group/presentation/join_group_sheet.dart';
import 'package:expo_spot/features/home/widgets/home_routing_demo_panel.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Draggable home sheet: group actions + backend routing test.
class HomeActionsPanel extends StatelessWidget {
  const HomeActionsPanel({super.key, required this.scrollController});

  final ScrollController scrollController;

  static const double sheetTopRadius = 28;

  static double navClearance(BuildContext context) {
    final safeBottom = MediaQuery.paddingOf(context).bottom;
    return safeBottom + 54;
  }

  @override
  Widget build(BuildContext context) {
    final navClearance = HomeActionsPanel.navClearance(context);

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(sheetTopRadius)),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius:
              const BorderRadius.vertical(top: Radius.circular(sheetTopRadius)),
          border: Border(
            top: BorderSide(color: AppColors.border.withValues(alpha: 0.6)),
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.bottleGreen.withValues(alpha: 0.1),
              blurRadius: 24,
              offset: const Offset(0, -6),
            ),
          ],
        ),
        child: CustomScrollView(
          controller: scrollController,
          slivers: [
            SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 10),
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: AppColors.border,
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                    child: Row(
                      children: [
                        Text(
                          'home_actions_title'.tr(),
                          style:
                              AppTypography.display(context).copyWith(fontSize: 17),
                        ),
                        const Spacer(),
                        Text(
                          'home_actions_hint'.tr(),
                          style: AppTypography.label(context).copyWith(
                            color: AppColors.keppelGreen,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
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
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20),
                    child: HomeRoutingDemoPanel(),
                  ),
                  const SizedBox(height: 12),
                ],
              ),
            ),
            SliverToBoxAdapter(
              child: ColoredBox(
                color: AppColors.surface,
                child: SizedBox(height: navClearance),
              ),
            ),
          ],
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

  static const double _cardRadius = 20;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(_cardRadius),
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(_cardRadius),
            color: AppColors.background,
            border: Border.all(color: AppColors.border),
          ),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: accent, size: 24),
                ),
                const SizedBox(height: 10),
                Text(
                  title,
                  style: AppTypography.body(context).copyWith(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: AppTypography.label(context).copyWith(fontSize: 11),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
