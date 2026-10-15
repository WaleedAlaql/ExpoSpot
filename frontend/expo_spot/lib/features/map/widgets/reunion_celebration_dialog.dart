import 'dart:ui';

import 'package:easy_localization/easy_localization.dart';
import 'package:expo_spot/core/theme/app_colors.dart';
import 'package:expo_spot/core/theme/app_radii.dart';
import 'package:expo_spot/core/theme/app_typography.dart';
import 'package:expo_spot/features/group/application/active_group_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ReunionCelebrationListener extends ConsumerStatefulWidget {
  const ReunionCelebrationListener({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<ReunionCelebrationListener> createState() =>
      _ReunionCelebrationListenerState();
}

class _ReunionCelebrationListenerState extends ConsumerState<ReunionCelebrationListener>
    with SingleTickerProviderStateMixin {
  bool _showing = false;

  @override
  Widget build(BuildContext context) {
    ref.listen<ActiveGroupState>(activeGroupProvider, (prev, next) {
      if (next.showCelebration && !_showing) {
        _showing = true;
        WidgetsBinding.instance.addPostFrameCallback((_) async {
          if (!mounted) return;
          await showGeneralDialog<void>(
            context: context,
            barrierDismissible: true,
            barrierLabel: 'celebration',
            barrierColor: Colors.black.withValues(alpha: 0.4),
            transitionDuration: const Duration(milliseconds: 520),
            pageBuilder: (_, _, _) => const _CelebrationDialog(),
            transitionBuilder: (context, animation, secondary, child) {
              final curved = CurvedAnimation(
                parent: animation,
                curve: Curves.fastOutSlowIn,
              );
              return FadeTransition(
                opacity: curved,
                child: ScaleTransition(
                  scale: Tween<double>(begin: 0.88, end: 1).animate(curved),
                  child: child,
                ),
              );
            },
          );
          if (mounted) {
            ref.read(activeGroupProvider.notifier).dismissCelebration();
            _showing = false;
          }
        });
      }
    });

    return widget.child;
  }
}

class _CelebrationDialog extends StatelessWidget {
  const _CelebrationDialog();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 28),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(AppRadii.card + 4),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    AppColors.keppelGreen.withValues(alpha: 0.95),
                    AppColors.bottleGreen,
                  ],
                ),
                borderRadius: BorderRadius.circular(AppRadii.card + 4),
                border: Border.all(color: Colors.white.withValues(alpha: 0.25)),
              ),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 28, 24, 22),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('🌿', style: TextStyle(fontSize: 42)),
                    const SizedBox(height: 12),
                    Text(
                      'celebration_title'.tr(),
                      textAlign: TextAlign.center,
                      style: AppTypography.display(context).copyWith(
                        color: Colors.white,
                        fontSize: 22,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'celebration_sub'.tr(),
                      textAlign: TextAlign.center,
                      style: AppTypography.subtitle(context).copyWith(
                        color: Colors.white.withValues(alpha: 0.9),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Material(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(AppRadii.button),
                      child: InkWell(
                        onTap: () {
                          HapticFeedback.lightImpact();
                          Navigator.of(context).pop();
                        },
                        borderRadius: BorderRadius.circular(AppRadii.button),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 12,
                          ),
                          child: Text(
                            'celebration_dismiss'.tr(),
                            style: AppTypography.button(context).copyWith(
                              color: AppColors.bottleGreen,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
