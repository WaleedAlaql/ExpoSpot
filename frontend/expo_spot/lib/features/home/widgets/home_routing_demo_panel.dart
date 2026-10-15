import 'package:easy_localization/easy_localization.dart';
import 'package:expo_spot/core/constants/api_constants.dart';
import 'package:expo_spot/core/theme/app_colors.dart';
import 'package:expo_spot/core/theme/app_radii.dart';
import 'package:expo_spot/core/theme/app_typography.dart';
import 'package:expo_spot/features/group/application/active_group_controller.dart';
import 'package:expo_spot/features/navigation/application/navigation_controller.dart';
import 'package:expo_spot/features/navigation/application/navigation_state.dart';
import 'package:expo_spot/features/navigation/presentation/demo_visitor_live_metrics.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Backend routing simulator controls on the home tab (demo mode).
class HomeRoutingDemoPanel extends ConsumerWidget {
  const HomeRoutingDemoPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!ApiConstants.navigationMode.isDemo) {
      return const SizedBox.shrink();
    }

    final nav = ref.watch(navigationControllerProvider);
    final notifier = ref.read(navigationControllerProvider.notifier);
    final groupNotifier = ref.read(activeGroupProvider.notifier);
    final busy = nav.commandInFlight;

    ref.listen<NavigationState>(navigationControllerProvider, (prev, next) {
      final demo = next.demoState;
      final mp = demo?.meetingPoint;
      if (mp == null) return;
      final prevDemo = prev?.demoState;
      if (prevDemo != null &&
          prevDemo.routeRevision == demo!.routeRevision &&
          prevDemo.revision == demo.revision &&
          prevDemo.meetingPoint?.id == mp.id) {
        return;
      }
      groupNotifier.applyBackendRoutingPreview(
        latitude: mp.latitude,
        longitude: mp.longitude,
        meetingPointName: mp.name,
        meetingPointId: mp.id,
      );
    });

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 14),
        Divider(color: AppColors.border.withValues(alpha: 0.8), height: 1),
        const SizedBox(height: 12),
        Row(
          children: [
            Text(
              'home_routing_title'.tr(),
              style: AppTypography.display(context).copyWith(fontSize: 16),
            ),
            const Spacer(),
            Text(
              nav.hasSession
                  ? (nav.demoState?.status ?? '—')
                  : 'home_routing_idle'.tr(),
              style: AppTypography.label(context).copyWith(
                color: AppColors.keppelGreen,
                fontWeight: FontWeight.w600,
                fontSize: 11,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          'home_routing_sub'.tr(),
          style: AppTypography.label(context).copyWith(
            color: AppColors.textMuted,
            fontSize: 11,
          ),
        ),
        if (nav.errorMessage != null) ...[
          const SizedBox(height: 8),
          Text(
            nav.errorMessage!,
            style: AppTypography.label(context).copyWith(
              color: const Color(0xFFB45309),
              fontSize: 11,
            ),
          ),
        ],
        const SizedBox(height: 10),
        FilledButton(
          onPressed: busy
              ? null
              : () async {
                  HapticFeedback.mediumImpact();
                  await notifier.runQuickRoutingTest();
                },
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.bottleGreen,
            minimumSize: const Size.fromHeight(46),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadii.button),
            ),
          ),
          child: Text(
            busy ? 'home_routing_running'.tr() : 'home_routing_run'.tr(),
            style: AppTypography.button(context).copyWith(color: Colors.white),
          ),
        ),
        if (nav.hasSession) ...[
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _MiniChip(
                label: 'nav_demo_start'.tr(),
                onTap: busy || !nav.canStartDemo
                    ? null
                    : () => notifier.startSimulation(),
              ),
              _MiniChip(
                label: 'nav_demo_pause'.tr(),
                onTap: busy || !nav.canPauseDemo
                    ? null
                    : () => notifier.pauseSimulation(),
              ),
              _MiniChip(
                label: 'nav_demo_reset'.tr(),
                onTap: busy ? null : () => notifier.resetSimulation(),
              ),
              _MiniChip(
                label: 'home_routing_speed_10'.tr(),
                onTap: busy || !nav.hasSession
                    ? null
                    : () => notifier.setSimulationSpeed(10),
              ),
            ],
          ),
          if (nav.demoState != null)
            DemoVisitorsProgressPanel(
              visitors: nav.demoState!.visitors,
              simulationStatus: nav.demoState!.status,
              speedMps: nav.demoState!.speed,
              revision: nav.demoState!.revision,
            ),
          if (nav.hasSession &&
              (nav.demoState?.visitors.isNotEmpty ?? false)) ...[
            const SizedBox(height: 10),
            OutlinedButton.icon(
              onPressed: busy
                  ? null
                  : () async {
                      HapticFeedback.mediumImpact();
                      await notifier.relocateVisitorsAndRecalculate();
                      if (!context.mounted) return;
                      final err = ref.read(navigationControllerProvider).errorMessage;
                      if (err != null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(err)),
                        );
                        return;
                      }
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('home_routing_relocate_done'.tr()),
                          duration: const Duration(seconds: 2),
                        ),
                      );
                    },
              style: OutlinedButton.styleFrom(
                minimumSize: const Size.fromHeight(44),
                foregroundColor: AppColors.bottleGreen,
                side: BorderSide(color: AppColors.keppelGreen.withValues(alpha: 0.65)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadii.button),
                ),
              ),
              icon: const Icon(Icons.shuffle_rounded, size: 20),
              label: Text(
                'home_routing_relocate'.tr(),
                style: AppTypography.button(context).copyWith(
                  color: AppColors.bottleGreen,
                  fontSize: 13,
                ),
              ),
            ),
          ],
        ],
        if (nav.commandInFlight)
          const Padding(
            padding: EdgeInsets.only(top: 10),
            child: LinearProgressIndicator(minHeight: 2),
          ),
      ],
    );
  }
}

class _MiniChip extends StatelessWidget {
  const _MiniChip({required this.label, required this.onTap});

  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return ActionChip(
      label: Text(label),
      onPressed: onTap,
      backgroundColor: AppColors.background,
      side: BorderSide(color: AppColors.border),
      labelStyle: AppTypography.label(context).copyWith(fontSize: 11),
    );
  }
}
