import 'package:expo_spot/core/constants/api_constants.dart';
import 'package:expo_spot/features/group/application/active_group_controller.dart';
import 'package:expo_spot/features/navigation/application/navigation_controller.dart';
import 'package:expo_spot/features/map/widgets/group_live_map.dart';
import 'package:expo_spot/features/map/widgets/map_arrival_overlay.dart';
import 'package:expo_spot/features/map/widgets/map_glass_header.dart';
import 'package:expo_spot/features/map/widgets/map_members_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class MapTab extends ConsumerStatefulWidget {
  const MapTab({super.key});

  @override
  ConsumerState<MapTab> createState() => _MapTabState();
}

class _MapTabState extends ConsumerState<MapTab> {
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
    final group = ref.watch(activeGroupProvider);

    return Stack(
      fit: StackFit.expand,
      children: [
        const GroupLiveMap(),
        SafeArea(
          bottom: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                MapGlassHeader(group: group),
                const SizedBox(height: 10),
                const MapArrivalOverlay(),
              ],
            ),
          ),
        ),
        DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.44,
          minChildSize: 0.28,
          maxChildSize: 0.72,
          snap: true,
          snapSizes: const [0.28, 0.44, 0.62, 0.72],
          builder: (context, scrollController) {
            return MapMembersSheet(scrollController: scrollController);
          },
        ),
      ],
    );
  }
}
