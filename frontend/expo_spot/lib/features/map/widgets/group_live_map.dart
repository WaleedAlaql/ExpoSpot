import 'package:expo_spot/core/theme/app_colors.dart';
import 'package:expo_spot/features/group/application/active_group_controller.dart';
import 'package:expo_spot/features/group/domain/group_member.dart';
import 'package:expo_spot/features/map/application/expo_dubai_graph_provider.dart';
import 'package:expo_spot/features/map/data/expo_dubai_graph.dart';
import 'package:expo_spot/features/map/domain/expo_dubai_venue.dart';
import 'package:expo_spot/features/map/widgets/meeting_point_map_layers.dart';
import 'package:expo_spot/features/map/widgets/member_map_marker.dart';
import 'package:expo_spot/features/navigation/application/navigation_controller.dart';
import 'package:expo_spot/features/navigation/application/navigation_state.dart';
import 'package:expo_spot/features/navigation/domain/navigation_models.dart';
import 'package:expo_spot/features/navigation/presentation/demo_visitor_live_metrics.dart';
import 'package:expo_spot/features/navigation/presentation/navigation_demo_colors.dart';
import 'package:expo_spot/core/theme/app_typography.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
/// Full interactive OSM map with group members, meet point, and graph-backed routes.
class GroupLiveMap extends ConsumerStatefulWidget {
  const GroupLiveMap({super.key, this.showBackendRoutingDemo = false});

  /// When true (home tab), draw backend demo paths/markers without mock straight lines.
  final bool showBackendRoutingDemo;

  @override
  ConsumerState<GroupLiveMap> createState() => _GroupLiveMapState();
}

class _GroupLiveMapState extends ConsumerState<GroupLiveMap>
    with TickerProviderStateMixin {
  late final MapController _mapController;
  late final AnimationController _pulseController;
  late final Animation<double> _pulse;
  AnimationController? _simulationTick;
  DateTime _demoMetricsAnchor = DateTime.now();
  int _demoMetricsRevision = -1;

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
    _simulationTick?.dispose();
    _pulseController.dispose();
    _mapController.dispose();
    super.dispose();
  }

  void _syncDemoSimulationTick(NavigationState nav) {
    final demo = nav.demoState;
    final running = demo?.status == 'RUNNING';
    if (demo != null && demo.revision != _demoMetricsRevision) {
      _demoMetricsRevision = demo.revision;
      _demoMetricsAnchor = DateTime.now();
    }
    if (running) {
      _simulationTick ??= AnimationController(
        vsync: this,
        duration: const Duration(seconds: 1),
      )..repeat();
    } else {
      _simulationTick?.stop();
    }
  }

  List<Polyline> _buildPolylines(
    ActiveGroupState group,
    ExpoDubaiGraph? graph,
    NavigationState nav,
  ) {
    final demo = nav.demoState;
    final demoHasPaths = demo != null &&
        demo.visitors.any((v) => v.latLngPath.length >= 2);

    if (widget.showBackendRoutingDemo && demoHasPaths) {
      return [
        for (final visitor in demo.visitors)
          if (visitor.latLngPath.length >= 2)
            Polyline(
              points: visitor.latLngPath,
              color: NavigationDemoColors.forVisitorId(visitor.id),
              strokeWidth: 4,
              borderColor: Colors.white.withValues(alpha: 0.6),
              borderStrokeWidth: 1.5,
            ),
      ];
    }

    if (!group.showRoutes || group.meetPoint == null) return const [];

    final recommendation = nav.recommendation;
    if (recommendation != null) {
      return [
        for (final participant in recommendation.participants)
          if (participant.latLngPath.length >= 2)
            Polyline(
              points: participant.latLngPath,
              color: NavigationDemoColors.forVisitorId(participant.userId),
              strokeWidth: 4,
              borderColor: Colors.white.withValues(alpha: 0.6),
              borderStrokeWidth: 1.5,
            ),
      ];
    }

    if (demo != null && demo.meetingPoint != null) {
      return [
        for (final visitor in demo.visitors)
          if (visitor.latLngPath.length >= 2)
            Polyline(
              points: visitor.latLngPath,
              color: NavigationDemoColors.forVisitorId(visitor.id),
              strokeWidth: 4,
              borderColor: Colors.white.withValues(alpha: 0.6),
              borderStrokeWidth: 1.5,
            ),
      ];
    }

    final destination = group.meetPoint!;
    final lines = <Polyline>[];

    for (final member in group.members) {
      if (member.connection == MemberConnection.offline) continue;
      final points = graph != null
          ? graph.shortestPathLatLng(from: member.position, to: destination)
          : [member.position, destination];

      lines.add(
        Polyline(
          points: points,
          color: AppColors.keppelGreen.withValues(alpha: 0.85),
          strokeWidth: 4,
          borderColor: Colors.white.withValues(alpha: 0.6),
          borderStrokeWidth: 1.5,
        ),
      );
    }
    return lines;
  }

  List<Marker> _demoVisitorMarkers(
    List<DemoVisitorModel> visitors, {
    required bool simulationRunning,
    required double speedMps,
  }) {
    return [
      for (final visitor in visitors)
        if (visitor.latLng != null)
          Marker(
            point: visitor.latLng!,
            width: 96,
            height: 72,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 16,
                  height: 16,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: NavigationDemoColors.forVisitorId(visitor.id),
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                ),
                const SizedBox(height: 2),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.surface.withValues(alpha: 0.94),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        visitor.name,
                        style: AppTypography.label(context).copyWith(fontSize: 9),
                      ),
                      if (DemoVisitorLiveMetrics.hasAssignedRoute(visitor) &&
                          visitor.remainingMeters != null) ...[
                        const SizedBox(height: 1),
                        Builder(
                          builder: (context) {
                            final live = DemoVisitorLiveMetrics.values(
                              visitor: visitor,
                              simulationRunning: simulationRunning,
                              speedMps: speedMps,
                              snapshotAnchor: _demoMetricsAnchor,
                            );
                            return Text(
                              '${DemoVisitorLiveMetrics.formatMeters(context, live.remainingMeters)} · ${DemoVisitorLiveMetrics.formatEta(live.etaSeconds)}',
                              style: AppTypography.label(context).copyWith(
                                fontSize: 8,
                                color: AppColors.textMuted,
                              ),
                            );
                          },
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final group = ref.watch(activeGroupProvider);
    final graphAsync = ref.watch(expoDubaiGraphProvider);
    final nav = ref.watch(navigationControllerProvider);
    _syncDemoSimulationTick(nav);

    final graph = graphAsync.valueOrNull;
    final polylines = _buildPolylines(group, graph, nav);

    final members = [...group.members]
      ..sort((a, b) {
        if (a.isCurrentUser) return 1;
        if (b.isCurrentUser) return -1;
        return 0;
      });

    const memberMarkerWidth = 96.0;
    const memberMarkerHeight = 84.0;
    const memberMarkerAnchor = Alignment(0, -0.36);

    final demo = nav.demoState;
    final demoActive = widget.showBackendRoutingDemo &&
        demo != null &&
        demo.visitors.isNotEmpty;

    final allMeetingPoints = MeetingPointMapLayers.resolveAllPoints(
      navGraph: nav.graph,
      venueGraph: graph,
    );
    final fairPoint = MeetingPointMapLayers.resolveFairPoint(
      nav: nav,
      group: group,
      allPoints: allMeetingPoints,
    );
    final meetingPointMarkers = MeetingPointMapLayers.buildMarkers(
      context: context,
      allPoints: allMeetingPoints,
      fairPoint: fairPoint,
    );

    final markers = <Marker>[
      ...meetingPointMarkers,
      if (!demoActive)
        for (final member in members)
          Marker(
            point: member.position,
            width: memberMarkerWidth,
            height: memberMarkerHeight,
            alignment: memberMarkerAnchor,
            child: MemberMapMarker(member: member, pulse: _pulse),
          ),
      if (demoActive)
        ..._demoVisitorMarkers(
          demo.visitors,
          simulationRunning: demo.status == 'RUNNING',
          speedMps: demo.speed,
        ),
    ];

    final mapBody = FlutterMap(
      mapController: _mapController,
      options: MapOptions(
        initialCenter: ExpoDubaiVenue.center,
        initialZoom: ExpoDubaiVenue.initialZoom,
        minZoom: ExpoDubaiVenue.minZoom,
        maxZoom: ExpoDubaiVenue.maxZoom,
        cameraConstraint: CameraConstraint.contain(
          bounds: ExpoDubaiVenue.bounds,
        ),
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
    );

    if (_simulationTick != null && _simulationTick!.isAnimating) {
      return AnimatedBuilder(
        animation: _simulationTick!,
        builder: (context, _) => mapBody,
      );
    }
    return mapBody;
  }
}
