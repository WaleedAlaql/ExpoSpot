import 'package:expo_spot/core/theme/app_colors.dart';
import 'package:expo_spot/features/group/application/active_group_controller.dart';
import 'package:expo_spot/features/home/presentation/home_dashboard_tab.dart';
import 'package:expo_spot/features/map/presentation/map_tab.dart';
import 'package:expo_spot/features/map/widgets/reunion_celebration_dialog.dart';
import 'package:expo_spot/features/profile/presentation/profile_tab.dart';
import 'package:expo_spot/features/shell/widgets/glass_bottom_nav.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class MainShell extends ConsumerWidget {
  const MainShell({super.key, required this.userName});

  final String userName;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final index = ref.watch(mainShellIndexProvider);

    return ReunionCelebrationListener(
      child: Scaffold(
        backgroundColor: AppColors.background,
        extendBody: true,
        body: IndexedStack(
          index: index,
          children: [
            const HomeDashboardTab(),
            const MapTab(),
            ProfileTab(userName: userName),
          ],
        ),
        bottomNavigationBar: GlassBottomNav(
          currentIndex: index,
          onChanged: (i) => ref.read(mainShellIndexProvider.notifier).state = i,
        ),
      ),
    );
  }
}
