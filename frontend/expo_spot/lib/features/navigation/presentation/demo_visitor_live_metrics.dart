import 'dart:math' as math;

import 'package:easy_localization/easy_localization.dart';
import 'package:expo_spot/core/theme/app_colors.dart';
import 'package:expo_spot/core/theme/app_radii.dart';
import 'package:expo_spot/core/theme/app_typography.dart';
import 'package:expo_spot/features/navigation/domain/navigation_models.dart';
import 'package:expo_spot/features/navigation/presentation/navigation_demo_colors.dart';
import 'package:flutter/material.dart';

abstract final class DemoVisitorLiveMetrics {
  static bool hasAssignedRoute(DemoVisitorModel visitor) {
    return visitor.path != null && visitor.path!.isNotEmpty;
  }

  static ({double remainingMeters, double etaSeconds}) values({
    required DemoVisitorModel visitor,
    required bool simulationRunning,
    required double speedMps,
    required DateTime snapshotAnchor,
  }) {
    final baseRemaining = visitor.remainingMeters;
    final baseEta = visitor.etaSeconds;
    if (!hasAssignedRoute(visitor) || baseRemaining == null) {
      return (remainingMeters: 0, etaSeconds: baseEta ?? 0);
    }
    if (visitor.status == 'ARRIVED' || baseRemaining <= 0) {
      return (remainingMeters: 0, etaSeconds: 0);
    }
    if (!simulationRunning || speedMps <= 0) {
      return (
        remainingMeters: baseRemaining,
        etaSeconds: baseEta ?? baseRemaining / speedMps,
      );
    }

    final elapsedSec =
        DateTime.now().difference(snapshotAnchor).inMicroseconds / 1e6;
    final remaining = math.max(0.0, baseRemaining - speedMps * elapsedSec);
    return (
      remainingMeters: remaining,
      etaSeconds: remaining / speedMps,
    );
  }

  static String formatMeters(BuildContext context, double meters) {
    if (meters >= 1000) {
      return 'demo_visitor_km'.tr(
        namedArgs: {'value': (meters / 1000).toStringAsFixed(1)},
      );
    }
    return 'demo_visitor_m'.tr(namedArgs: {'value': meters.round().toString()});
  }

  static String formatEta(double seconds) {
    if (seconds <= 0) return '0:00';
    final total = seconds.ceil();
    final minutes = total ~/ 60;
    final secs = total % 60;
    if (minutes >= 60) {
      final hours = minutes ~/ 60;
      final mins = minutes % 60;
      return '$hours:${mins.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
    }
    return '$minutes:${secs.toString().padLeft(2, '0')}';
  }
}

/// Per-visitor remaining distance + ETA; ticks locally while simulation runs.
class DemoVisitorsProgressPanel extends StatefulWidget {
  const DemoVisitorsProgressPanel({
    super.key,
    required this.visitors,
    required this.simulationStatus,
    required this.speedMps,
    required this.revision,
  });

  final List<DemoVisitorModel> visitors;
  final String simulationStatus;
  final double speedMps;
  final int revision;

  @override
  State<DemoVisitorsProgressPanel> createState() =>
      _DemoVisitorsProgressPanelState();
}

class _DemoVisitorsProgressPanelState extends State<DemoVisitorsProgressPanel>
    with SingleTickerProviderStateMixin {
  late final AnimationController _tick;
  late DateTime _snapshotAnchor;
  late int _lastRevision;

  @override
  void initState() {
    super.initState();
    _snapshotAnchor = DateTime.now();
    _lastRevision = widget.revision;
    _tick = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    );
    if (widget.simulationStatus == 'RUNNING') {
      _tick.repeat();
    }
  }

  @override
  void didUpdateWidget(DemoVisitorsProgressPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.revision != _lastRevision) {
      _lastRevision = widget.revision;
      _snapshotAnchor = DateTime.now();
    }
    if (widget.simulationStatus == 'RUNNING') {
      if (!_tick.isAnimating) _tick.repeat();
    } else {
      _tick.stop();
    }
  }

  @override
  void dispose() {
    _tick.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final running = widget.simulationStatus == 'RUNNING';
    if (running) {
      return AnimatedBuilder(
        animation: _tick,
        builder: (context, _) => _buildList(context, running: true),
      );
    }
    return _buildList(context, running: false);
  }

  Widget _buildList(BuildContext context, {required bool running}) {
    final routed = widget.visitors
        .where(DemoVisitorLiveMetrics.hasAssignedRoute)
        .toList();
    if (routed.isEmpty) {
      return Padding(
        padding: const EdgeInsets.only(top: 8),
        child: Text(
          'demo_visitor_waiting_route'.tr(),
          style: AppTypography.label(context).copyWith(
            color: AppColors.textMuted,
            fontSize: 11,
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 12),
        Text(
          'demo_visitor_progress_title'.tr(),
          style: AppTypography.label(context).copyWith(
            fontWeight: FontWeight.w700,
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 8),
        for (final visitor in routed) ...[
          _VisitorProgressRow(
            visitor: visitor,
            color: NavigationDemoColors.forVisitorId(visitor.id),
            running: running,
            speedMps: widget.speedMps,
            snapshotAnchor: _snapshotAnchor,
          ),
          const SizedBox(height: 8),
        ],
      ],
    );
  }
}

class _VisitorProgressRow extends StatelessWidget {
  const _VisitorProgressRow({
    required this.visitor,
    required this.color,
    required this.running,
    required this.speedMps,
    required this.snapshotAnchor,
  });

  final DemoVisitorModel visitor;
  final Color color;
  final bool running;
  final double speedMps;
  final DateTime snapshotAnchor;

  @override
  Widget build(BuildContext context) {
    final live = DemoVisitorLiveMetrics.values(
      visitor: visitor,
      simulationRunning: running,
      speedMps: speedMps,
      snapshotAnchor: snapshotAnchor,
    );
    final total = visitor.distanceMeters ?? 0;
    final progress = total <= 0
        ? (visitor.status == 'ARRIVED' ? 1.0 : 0.0)
        : (1 - (live.remainingMeters / total)).clamp(0.0, 1.0);

    final detail = visitor.status == 'ARRIVED'
        ? 'demo_visitor_arrived'.tr()
        : 'demo_visitor_remaining_eta'.tr(
            namedArgs: {
              'meters': DemoVisitorLiveMetrics.formatMeters(
                context,
                live.remainingMeters,
              ),
              'eta': DemoVisitorLiveMetrics.formatEta(live.etaSeconds),
            },
          );

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.background.withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(AppRadii.card),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(shape: BoxShape.circle, color: color),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  visitor.name,
                  style: AppTypography.label(context).copyWith(
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
              ),
              Text(
                DemoVisitorLiveMetrics.formatEta(live.etaSeconds),
                style: AppTypography.label(context).copyWith(
                  fontFeatures: const [FontFeature.tabularFigures()],
                  fontWeight: FontWeight.w700,
                  color: AppColors.bottleGreen,
                  fontSize: 13,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 5,
              backgroundColor: AppColors.border.withValues(alpha: 0.5),
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            detail,
            style: AppTypography.label(context).copyWith(
              color: AppColors.textMuted,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }
}
