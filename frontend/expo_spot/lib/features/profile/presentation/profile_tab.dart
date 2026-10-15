import 'package:easy_localization/easy_localization.dart' hide TextDirection;
import 'package:expo_spot/core/localization/language_switcher.dart';
import 'package:expo_spot/core/routing/fade_scale_route.dart';
import 'package:expo_spot/core/theme/app_colors.dart';
import 'package:expo_spot/core/theme/app_radii.dart';
import 'package:expo_spot/core/theme/app_typography.dart';
import 'package:expo_spot/core/widgets/expo_mesh_background.dart';
import 'package:expo_spot/core/widgets/glass_panel.dart';
import 'package:expo_spot/features/auth/application/auth_controller.dart';
import 'package:expo_spot/features/auth/presentation/login_screen.dart';
import 'package:expo_spot/features/group/data/mock_group_repository.dart';
import 'package:expo_spot/features/group/widgets/past_groups_section.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ProfileTab extends ConsumerWidget {
  const ProfileTab({super.key, required this.userName});

  final String userName;

  Future<void> _confirmLogout(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: AppColors.surface,
          surfaceTintColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadii.card),
            side: const BorderSide(color: AppColors.border),
          ),
          title: Text(
            'logout_confirm_title'.tr(),
            style: AppTypography.body(context).copyWith(
              fontWeight: FontWeight.w700,
              fontSize: 18,
            ),
          ),
          content: Text(
            'logout_confirm_message'.tr(),
            style: AppTypography.body(context).copyWith(color: AppColors.textMuted),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: Text('cancel'.tr()),
            ),
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              child: Text(
                'logout'.tr(),
                style: const TextStyle(color: AppColors.error),
              ),
            ),
          ],
        );
      },
    );

    if (confirmed != true || !context.mounted) return;

    HapticFeedback.mediumImpact();
    await ref.read(authControllerProvider.notifier).logout();

    if (!context.mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      FadeScaleRoute(page: const LoginScreen()),
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final backendUser = ref.watch(currentUserModelProvider);
    final displayName = backendUser.name.isNotEmpty ? backendUser.name : userName;
    final languageLabel = context.locale.languageCode == 'ar'
        ? 'language_ar'.tr()
        : 'language_en'.tr();

    return ExpoMeshBackground(
      child: SafeArea(
        bottom: false,
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'profile_title'.tr(),
                      style: AppTypography.display(context).copyWith(fontSize: 26),
                    ),
                    const SizedBox(height: 16),
                    const LanguageSwitcher(),
                    const SizedBox(height: 16),
                    GlassPanel(
                      child: Row(
                        children: [
                          Container(
                            width: 56,
                            height: 56,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: LinearGradient(
                                colors: [
                                  AppColors.keppelGreen.withValues(alpha: 0.9),
                                  AppColors.bottleGreen,
                                ],
                              ),
                            ),
                            child: const Icon(Icons.person, color: Colors.white, size: 28),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  displayName,
                                  style: AppTypography.body(context).copyWith(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 18,
                                  ),
                                ),
                                if (backendUser.email != null)
                                  Text(
                                    backendUser.email!,
                                    style: AppTypography.label(context).copyWith(
                                      color: AppColors.textMuted,
                                      fontSize: 12,
                                    ),
                                  ),
                                Text(
                                  'profile_expo_tag'.tr(),
                                  style: AppTypography.englishMetric(context),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    _ProfileRow(icon: Icons.notifications_outlined, label: 'notifications'.tr()),
                    const SizedBox(height: 10),
                    _ProfileRow(
                      icon: Icons.language_rounded,
                      label: '${'language_setting'.tr()} · $languageLabel',
                    ),
                    const SizedBox(height: 10),
                    _ProfileRow(icon: Icons.shield_outlined, label: 'privacy'.tr()),
                    const SizedBox(height: 24),
                    const PastGroupsSection(),
                    const SizedBox(height: 24),
                    _LogoutButton(onPressed: () => _confirmLogout(context, ref)),
                    const SizedBox(height: 120),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LogoutButton extends StatelessWidget {
  const _LogoutButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          HapticFeedback.lightImpact();
          onPressed();
        },
        borderRadius: BorderRadius.circular(AppRadii.button),
        child: Ink(
          height: 52,
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppRadii.button),
            border: Border.all(color: AppColors.error.withValues(alpha: 0.35)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.logout_rounded,
                size: 20,
                color: AppColors.error.withValues(alpha: 0.9),
              ),
              const SizedBox(width: 8),
              Text(
                'logout'.tr(),
                style: AppTypography.button(context).copyWith(
                  color: AppColors.error,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProfileRow extends StatelessWidget {
  const _ProfileRow({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final isRtl = Directionality.of(context) == TextDirection.rtl;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => HapticFeedback.lightImpact(),
        borderRadius: BorderRadius.circular(AppRadii.card),
        child: Ink(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppRadii.card),
            border: Border.all(color: AppColors.border),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                Icon(icon, color: AppColors.bottleGreen),
                const SizedBox(width: 12),
                Expanded(child: Text(label, style: AppTypography.body(context))),
                Icon(
                  isRtl ? Icons.chevron_left : Icons.chevron_right,
                  color: AppColors.textMuted,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
