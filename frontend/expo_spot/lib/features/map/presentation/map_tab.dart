import 'package:expo_spot/core/theme/app_colors.dart';
import 'package:expo_spot/features/group/application/active_group_controller.dart';
import 'package:expo_spot/features/group/domain/group_member.dart';
import 'package:expo_spot/features/map/widgets/map_arrival_overlay.dart';
import 'package:expo_spot/features/map/widgets/map_glass_header.dart';
import 'package:expo_spot/features/map/widgets/map_members_sheet.dart';
import 'package:expo_spot/features/map/widgets/member_map_marker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class MapTab extends ConsumerStatefulWidget {
  const MapTab({super.key});

  @override
  ConsumerState<MapTab> createState() => _MapTabState();
}

class _MapTabState extends ConsumerState<MapTab> with SingleTickerProviderStateMixin {
  late final MapController _mapController;
  late final AnimationController _pulseController;
  late final Animation<double> _pulse;

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);
    _pulse = CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _mapController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final group = ref.watch(activeGroupProvider);

    final polylines = <Polyline>[];
    if (group.showRoutes && group.meetPoint != null) {
      for (final member in group.members) {
        polylines.add(
          Polyline(
            points: [member.position, group.meetPoint!],
            color: AppColors.keppelGreen.withValues(alpha: 0.85),
            strokeWidth: 4,
            borderColor: Colors.white.withValues(alpha: 0.6),
            borderStrokeWidth: 1.5,
          ),
        );
      }
    }

    final markers = <Marker>[
      for (final member in group.members)
        Marker(
          point: member.position,
          width: 88,
          height: 96,
          child: MemberMapMarker(member: member, pulse: _pulse),
        ),
      if (group.meetPoint != null)
        Marker(
          point: group.meetPoint!,
          width: 72,
          height: 88,
          child: const MeetPointMarker(),
        ),
    ];

    return Stack(
      fit: StackFit.expand,
      children: [
        FlutterMap(
          mapController: _mapController,
          options: MapOptions(
            initialCenter: ExpoVenue.center,
            initialZoom: ExpoVenue.zoom,
            interactionOptions: const InteractionOptions(
              flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
            ),
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.expospot.expo_spot',
            ),
            if (polylines.isNotEmpty) PolylineLayer(polylines: polylines),
            MarkerLayer(markers: markers),
          ],
        ),
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
          initialChildSize: 0.26,
          minChildSize: 0.22,
          maxChildSize: 0.58,
          snap: true,
          snapSizes: const [0.26, 0.42, 0.58],
          builder: (context, scrollController) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 88),
              child: MapMembersSheet(scrollController: scrollController),
            );
          },
        ),
      ],
    );
  }
}
