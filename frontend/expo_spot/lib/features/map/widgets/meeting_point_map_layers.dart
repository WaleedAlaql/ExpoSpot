import 'package:expo_spot/features/group/application/active_group_controller.dart';
import 'package:expo_spot/features/map/data/expo_dubai_graph.dart';
import 'package:expo_spot/features/map/widgets/member_map_marker.dart';
import 'package:expo_spot/features/navigation/application/navigation_state.dart';
import 'package:expo_spot/features/navigation/domain/navigation_models.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

/// Lightweight meeting point for map rendering.
class MapMeetingPointView {
  const MapMeetingPointView({
    required this.id,
    required this.name,
    required this.latLng,
  });

  final String id;
  final String name;
  final LatLng latLng;
}

class SelectedFairMeetingPoint {
  const SelectedFairMeetingPoint({
    required this.id,
    required this.name,
    required this.latLng,
  });

  final String id;
  final String name;
  final LatLng latLng;
}

abstract final class MeetingPointMapLayers {
  static const _coordEpsilon = 0.000015;

  static List<MapMeetingPointView> resolveAllPoints({
    GraphResponseModel? navGraph,
    ExpoDubaiGraph? venueGraph,
  }) {
    if (navGraph != null && navGraph.meetingPoints.isNotEmpty) {
      return navGraph.meetingPoints
          .map(
            (p) => MapMeetingPointView(
              id: p.id,
              name: p.name,
              latLng: p.latLng,
            ),
          )
          .toList(growable: false);
    }
    if (venueGraph != null && venueGraph.meetingPoints.isNotEmpty) {
      return venueGraph.meetingPoints
          .map(
            (p) => MapMeetingPointView(
              id: p.id,
              name: p.name,
              latLng: p.latLng,
            ),
          )
          .toList(growable: false);
    }
    return const [];
  }

  static SelectedFairMeetingPoint? resolveFairPoint({
    required NavigationState nav,
    required ActiveGroupState group,
    required List<MapMeetingPointView> allPoints,
  }) {
    final demoMp = nav.demoState?.meetingPoint;
    if (demoMp != null) {
      return SelectedFairMeetingPoint(
        id: demoMp.id,
        name: demoMp.name,
        latLng: demoMp.latLng,
      );
    }

    final recMp = nav.recommendation?.meetingPoint;
    if (recMp != null) {
      return SelectedFairMeetingPoint(
        id: recMp.id,
        name: recMp.name,
        latLng: recMp.latLng,
      );
    }

    final meet = group.meetPoint;
    if (meet == null) return null;

    for (final p in allPoints) {
      if (_sameCoord(p.latLng, meet)) {
        return SelectedFairMeetingPoint(id: p.id, name: p.name, latLng: p.latLng);
      }
    }

    return SelectedFairMeetingPoint(
      id: 'fair-${meet.latitude}-${meet.longitude}',
      name: _englishNameFromLabelKey(group.meetPointLabelKey),
      latLng: meet,
    );
  }

  static String _englishNameFromLabelKey(String key) {
    return switch (key) {
      'meet_point_alt_east' => 'Sea Plaza',
      'meet_point_alt_west' => 'Sun Plaza',
      'meet_point_primary' => 'Earth Plaza',
      _ => 'Earth Plaza',
    };
  }

  static bool _sameCoord(LatLng a, LatLng b) {
    return (a.latitude - b.latitude).abs() < _coordEpsilon &&
        (a.longitude - b.longitude).abs() < _coordEpsilon;
  }

  static bool isSamePoint(MapMeetingPointView point, SelectedFairMeetingPoint fair) {
    if (point.id == fair.id) return true;
    return _sameCoord(point.latLng, fair.latLng);
  }

  static List<Marker> buildMarkers({
    required BuildContext context,
    required List<MapMeetingPointView> allPoints,
    SelectedFairMeetingPoint? fairPoint,
  }) {
    if (allPoints.isEmpty && fairPoint == null) return const [];

    final markers = <Marker>[];

    for (final point in allPoints) {
      if (fairPoint != null && isSamePoint(point, fairPoint)) continue;
      markers.add(
        Marker(
          point: point.latLng,
          width: 92,
          height: 72,
          alignment: Alignment.bottomCenter,
          child: Align(
            alignment: Alignment.bottomCenter,
            child: MeetingPointCandidateMarker(name: point.name),
          ),
        ),
      );
    }

    if (fairPoint != null) {
      markers.add(
        Marker(
          point: fairPoint.latLng,
          width: 132,
          height: 112,
          alignment: Alignment.bottomCenter,
          child: Align(
            alignment: Alignment.bottomCenter,
            child: MeetPointMarker(
              labelKey: 'best_meeting_point',
              highlighted: true,
            ),
          ),
        ),
      );
    }

    return markers;
  }
}
