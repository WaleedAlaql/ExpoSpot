import 'package:easy_localization/easy_localization.dart' hide TextDirection;
import 'package:expo_spot/core/constants/api_constants.dart';
import 'package:expo_spot/features/home/widgets/home_actions_panel.dart';
import 'package:expo_spot/features/map/widgets/group_live_map.dart';
import 'package:expo_spot/features/navigation/application/navigation_controller.dart';
import 'package:expo_spot/features/navigation/application/navigation_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class HomeDashboardTab extends ConsumerStatefulWidget {
  const HomeDashboardTab({super.key});

  @override
  ConsumerState<HomeDashboardTab> createState() => _HomeDashboardTabState();
}

class _HomeDashboardTabState extends ConsumerState<HomeDashboardTab> {
  @override
  void initState() {
    super.initState();
    if (ApiConstants.navigationMode.isDemo) {
      Future<void>(() {
        ref.read(navigationControllerProvider.notifier).bootstrapDemo();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<NavigationState>(navigationControllerProvider, (prev, next) {
      if (next.showCelebration && prev?.showCelebration != true) {
        HapticFeedback.mediumImpact();
        showDialog<void>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: Text('celebration_title'.tr()),
            content: Text('celebration_sub'.tr()),
            actions: [
              TextButton(
                onPressed: () {
                  ref
                      .read(navigationControllerProvider.notifier)
                      .dismissCelebration();
                  Navigator.of(ctx).pop();
                },
                child: Text('celebration_dismiss'.tr()),
              ),
            ],
          ),
        );
      }
    });

    return Stack(
      fit: StackFit.expand,
      children: [
        const GroupLiveMap(showBackendRoutingDemo: true),
        DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.42,
          minChildSize: 0.24,
          maxChildSize: 0.78,
          snap: true,
          snapSizes: const [0.24, 0.42, 0.58, 0.78],
          builder: (context, scrollController) {
            return HomeActionsPanel(scrollController: scrollController);
          },
        ),
      ],
    );
  }
}
