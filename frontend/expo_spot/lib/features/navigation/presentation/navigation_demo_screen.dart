import 'dart:ui';

import 'package:easy_localization/easy_localization.dart' hide TextDirection;
import 'package:expo_spot/core/constants/api_constants.dart';
import 'package:expo_spot/core/theme/app_colors.dart';
import 'package:expo_spot/core/theme/app_radii.dart';
import 'package:expo_spot/core/theme/app_typography.dart';
import 'package:expo_spot/features/map/widgets/meeting_point_map_layers.dart';
import 'package:expo_spot/features/navigation/application/navigation_controller.dart';
import 'package:expo_spot/features/navigation/application/navigation_state.dart';
import 'package:expo_spot/features/navigation/domain/navigation_models.dart';
import 'package:expo_spot/features/navigation/presentation/navigation_demo_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';

class NavigationDemoScreen extends ConsumerStatefulWidget {
  const NavigationDemoScreen({super.key});

  @override
  ConsumerState<NavigationDemoScreen> createState() =>
      _NavigationDemoScreenState();
}

class _NavigationDemoScreenState extends ConsumerState<NavigationDemoScreen> {
  final _mapController = MapController();
  final _joinController = TextEditingController();
  bool _fitPending = true;

  @override
  void initState() {
    super.initState();
    Future<void>(() => ref.read(navigationControllerProvider.notifier).bootstrapDemo());
  }

  @override
  void dispose() {
    _joinController.dispose();
    _mapController.dispose();
    super.dispose();
  }

  void _maybeFitBounds(GraphResponseModel? graph) {
    if (!_fitPending || graph == null) return;
    final bounds = graph.bounds;
    if (bounds == null) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _mapController.fitCamera(
        CameraFit.bounds(
          bounds: LatLngBounds(bounds.southWest, bounds.northEast),
          padding: const EdgeInsets.all(48),
        ),
      );
      _fitPending = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final nav = ref.watch(navigationControllerProvider);
    final notifier = ref.read(navigationControllerProvider.notifier);

    ref.listen<NavigationState>(navigationControllerProvider, (prev, next) {
      if (next.showCelebration && prev?.showCelebration != true) {
        _showArrivalCelebration(context, notifier);
      }
      _maybeFitBounds(next.graph);
    });

    _maybeFitBounds(nav.graph);

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: AppColors.bottleGreen,
          foregroundColor: Colors.white,
          title: Text('nav_demo_title'.tr()),
          actions: [
            Padding(
              padding: const EdgeInsetsDirectional.only(end: 12),
              child: Center(
                child: Text(
                  ApiConstants.navigationMode.isDemo
                      ? 'nav_mode_demo'.tr()
                      : 'nav_mode_production'.tr(),
                  style: AppTypography.label(context).copyWith(
                    color: Colors.white.withValues(alpha: 0.9),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
        body: Column(
          children: [
            Material(
              color: AppColors.background,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'nav_demo_backend'.tr(namedArgs: {
                        'url': ApiConstants.baseUrl,
                      }),
                      style: AppTypography.label(context).copyWith(
                        color: AppColors.textMuted,
                        fontSize: 11,
                      ),
                    ),
                    if (nav.graphLoading)
                      Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Text(
                          'nav_demo_graph_loading'.tr(),
                          style: AppTypography.label(context).copyWith(
                            color: AppColors.keppelGreen,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            if (nav.errorMessage != null)
              Material(
                color: const Color(0xFFFFF3E0),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        nav.errorMessage!,
                        style: AppTypography.body(context),
                      ),
                      TextButton(
                        onPressed: () => notifier.bootstrapDemo(),
                        child: Text('nav_demo_retry'.tr()),
                      ),
                    ],
                  ),
                ),
              ),
            if (ApiConstants.navigationMode.isProduction)
              Padding(
                padding: const EdgeInsets.all(12),
                child: Text(
                  'nav_production_disabled_hint'.tr(),
                  style: AppTypography.label(context).copyWith(
                    color: AppColors.textMuted,
                  ),
                ),
              ),
            Expanded(child: _DemoMap(nav: nav, mapController: _mapController)),
            _DemoControls(
              nav: nav,
              joinController: _joinController,
              onCreate: notifier.createDemoSession,
              onJoin: () => notifier.joinDemoSession(_joinController.text),
              onSpawn: notifier.spawnVisitors,
              onOptimize: notifier.optimize,
              onRoutes: notifier.recalculateRoutes,
              onStart: notifier.startSimulation,
              onPause: notifier.pauseSimulation,
              onReset: notifier.resetSimulation,
              onSpeed: notifier.setSimulationSpeed,
              onVisitorCount: notifier.setVisitorCount,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showArrivalCelebration(
    BuildContext context,
    NavigationController notifier,
  ) async {
    HapticFeedback.mediumImpact();
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('celebration_title'.tr()),
        content: Text('celebration_sub'.tr()),
        actions: [
          TextButton(
            onPressed: () {
              notifier.dismissCelebration();
              Navigator.of(ctx).pop();
            },
            child: Text('celebration_dismiss'.tr()),
          ),
        ],
      ),
    );
    notifier.dismissCelebration();
  }
}

class _DemoMap extends StatelessWidget {
  const _DemoMap({required this.nav, required this.mapController});

  final NavigationState nav;
  final MapController mapController;

  @override
  Widget build(BuildContext context) {
    final demo = nav.demoState;
    final graph = nav.graph;
    final center = (graph != null && graph.meetingPoints.isNotEmpty)
        ? graph.meetingPoints.first.latLng
        : const LatLng(24.957803, 55.1562148);

    final polylines = <Polyline>[];
    if (demo != null) {
      for (final visitor in demo.visitors) {
        final path = visitor.latLngPath;
        if (path.length < 2) continue;
        polylines.add(
          Polyline(
            points: path,
            color: NavigationDemoColors.forVisitorId(visitor.id),
            strokeWidth: 4,
          ),
        );
      }
    }

    final allMeetingPoints = MeetingPointMapLayers.resolveAllPoints(
      navGraph: graph,
      venueGraph: null,
    );
    final fairPoint = demo?.meetingPoint == null
        ? null
        : SelectedFairMeetingPoint(
            id: demo!.meetingPoint!.id,
            name: demo.meetingPoint!.name,
            latLng: demo.meetingPoint!.latLng,
          );

    final markers = <Marker>[
      ...MeetingPointMapLayers.buildMarkers(
        context: context,
        allPoints: allMeetingPoints,
        fairPoint: fairPoint,
      ),
    ];
    for (final visitor in demo?.visitors ?? const <DemoVisitorModel>[]) {
      final point = visitor.latLng;
      if (point == null) continue;
      markers.add(
        Marker(
          point: point,
          width: 56,
          height: 56,
          child: _VisitorDot(
            color: NavigationDemoColors.forVisitorId(visitor.id),
            label: visitor.name,
          ),
        ),
      );
    }

    return FlutterMap(
      mapController: mapController,
      options: MapOptions(
        initialCenter: center,
        initialZoom: 16,
        minZoom: 14,
        maxZoom: 19,
      ),
      children: [
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'com.expospot.app',
        ),
        if (polylines.isNotEmpty) PolylineLayer(polylines: polylines),
        MarkerLayer(markers: markers),
      ],
    );
  }
}

class _VisitorDot extends StatelessWidget {
  const _VisitorDot({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 18,
          height: 18,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color,
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
          child: Text(
            label,
            style: AppTypography.label(context).copyWith(fontSize: 9),
          ),
        ),
      ],
    );
  }
}

class _DemoControls extends StatelessWidget {
  const _DemoControls({
    required this.nav,
    required this.joinController,
    required this.onCreate,
    required this.onJoin,
    required this.onSpawn,
    required this.onOptimize,
    required this.onRoutes,
    required this.onStart,
    required this.onPause,
    required this.onReset,
    required this.onSpeed,
    required this.onVisitorCount,
  });

  final NavigationState nav;
  final TextEditingController joinController;
  final Future<void> Function() onCreate;
  final VoidCallback onJoin;
  final Future<void> Function() onSpawn;
  final Future<void> Function() onOptimize;
  final Future<void> Function() onRoutes;
  final Future<void> Function() onStart;
  final Future<void> Function() onPause;
  final Future<void> Function() onReset;
  final Future<void> Function(double speed) onSpeed;
  final ValueChanged<int> onVisitorCount;

  @override
  Widget build(BuildContext context) {
    final busy = nav.commandInFlight;
    final hasSession = nav.hasSession;

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: AppColors.surface.withValues(alpha: 0.96),
            border: Border(top: BorderSide(color: AppColors.border)),
          ),
          child: SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (!hasSession) ...[
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: joinController,
                            decoration: InputDecoration(
                              hintText: 'nav_demo_join_hint'.tr(),
                              isDense: true,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        _ChipButton(
                          label: 'nav_demo_join'.tr(),
                          onPressed: busy ? null : onJoin,
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    _PrimaryButton(
                      label: 'nav_demo_create'.tr(),
                      onPressed: busy ? null : () => onCreate(),
                    ),
                  ] else ...[
                    Text(
                      'nav_demo_session'.tr(namedArgs: {
                        'id': nav.simulationId ?? '',
                        'status': nav.demoState?.status ?? '',
                      }),
                      style: AppTypography.label(context).copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _ChipButton(
                          label: 'nav_demo_spawn'.tr(),
                          onPressed: busy ? null : () => onSpawn(),
                        ),
                        _ChipButton(
                          label: 'nav_demo_optimize'.tr(),
                          onPressed: busy ? null : () => onOptimize(),
                        ),
                        _ChipButton(
                          label: 'nav_demo_routes'.tr(),
                          onPressed: busy ? null : () => onRoutes(),
                        ),
                        _ChipButton(
                          label: 'nav_demo_start'.tr(),
                          onPressed: busy || !nav.canStartDemo
                              ? null
                              : () => onStart(),
                        ),
                        _ChipButton(
                          label: 'nav_demo_pause'.tr(),
                          onPressed:
                              busy || !nav.canPauseDemo ? null : () => onPause(),
                        ),
                        _ChipButton(
                          label: 'nav_demo_reset'.tr(),
                          onPressed: busy ? null : () => onReset(),
                        ),
                        _ChipButton(
                          label: '10 m/s',
                          onPressed: busy ? null : () => onSpeed(10),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Text('nav_demo_visitors'.tr()),
                        const SizedBox(width: 8),
                        DropdownButton<int>(
                          value: nav.visitorCount.clamp(3, 4),
                          items: const [
                            DropdownMenuItem(value: 3, child: Text('3')),
                            DropdownMenuItem(value: 4, child: Text('4')),
                          ],
                          onChanged: busy
                              ? null
                              : (v) {
                                  if (v != null) onVisitorCount(v);
                                },
                        ),
                        const Spacer(),
                        Text(
                          nav.connectionStatus.name,
                          style: AppTypography.label(context).copyWith(
                            color: AppColors.keppelGreen,
                          ),
                        ),
                      ],
                    ),
                  ],
                  if (busy)
                    const Padding(
                      padding: EdgeInsets.only(top: 10),
                      child: LinearProgressIndicator(minHeight: 2),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _PrimaryButton extends StatelessWidget {
  const _PrimaryButton({required this.label, required this.onPressed});

  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return FilledButton(
      onPressed: onPressed,
      style: FilledButton.styleFrom(
        backgroundColor: AppColors.bottleGreen,
        minimumSize: const Size.fromHeight(48),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.button),
        ),
      ),
      child: Text(label),
    );
  }
}

class _ChipButton extends StatelessWidget {
  const _ChipButton({required this.label, required this.onPressed});

  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return ActionChip(
      label: Text(label),
      onPressed: onPressed,
      backgroundColor: AppColors.background,
      side: BorderSide(color: AppColors.border),
    );
  }
}
