import 'package:expo_spot/core/json/json_readers.dart';
import 'package:latlong2/latlong.dart';

class RoutePointModel {
  const RoutePointModel({
    this.nodeId,
    required this.latitude,
    required this.longitude,
  });

  final int? nodeId;
  final double latitude;
  final double longitude;

  LatLng get latLng => LatLng(latitude, longitude);

  factory RoutePointModel.fromJson(Map<String, dynamic> json) {
    return RoutePointModel(
      nodeId: JsonReaders.intOrNull(json['nodeId']),
      latitude: JsonReaders.doubleValue(json['latitude']),
      longitude: JsonReaders.doubleValue(json['longitude']),
    );
  }
}

class RouteResponseModel {
  const RouteResponseModel({
    this.fromNodeId,
    this.toNodeId,
    required this.distanceMeters,
    required this.estimatedDurationSeconds,
    required this.path,
  });

  final int? fromNodeId;
  final int? toNodeId;
  final double distanceMeters;
  final int estimatedDurationSeconds;
  final List<RoutePointModel> path;

  List<LatLng> get latLngPath =>
      path.map((p) => p.latLng).toList(growable: false);

  factory RouteResponseModel.fromJson(Map<String, dynamic> json) {
    return RouteResponseModel(
      fromNodeId: JsonReaders.intOrNull(json['fromNodeId']),
      toNodeId: JsonReaders.intOrNull(json['toNodeId']),
      distanceMeters: JsonReaders.doubleValue(json['distanceMeters']),
      estimatedDurationSeconds:
          JsonReaders.intValue(json['estimatedDurationSeconds']),
      path: JsonReaders.listOf(json['path'], RoutePointModel.fromJson),
    );
  }
}

class MapMatchResponseModel {
  const MapMatchResponseModel({
    required this.latitude,
    required this.longitude,
    required this.distanceFromGpsMeters,
    this.fromNodeId,
    this.toNodeId,
    this.fraction,
  });

  final double latitude;
  final double longitude;
  final double distanceFromGpsMeters;
  final int? fromNodeId;
  final int? toNodeId;
  final double? fraction;

  factory MapMatchResponseModel.fromJson(Map<String, dynamic> json) {
    return MapMatchResponseModel(
      latitude: JsonReaders.doubleValue(json['latitude']),
      longitude: JsonReaders.doubleValue(json['longitude']),
      distanceFromGpsMeters:
          JsonReaders.doubleValue(json['distanceFromGpsMeters']),
      fromNodeId: JsonReaders.intOrNull(json['fromNodeId']),
      toNodeId: JsonReaders.intOrNull(json['toNodeId']),
      fraction: JsonReaders.doubleOrNull(json['fraction']),
    );
  }
}

class GpsRouteResponseModel {
  const GpsRouteResponseModel({
    required this.start,
    required this.destination,
    required this.route,
  });

  final MapMatchResponseModel start;
  final MapMatchResponseModel destination;
  final RouteResponseModel route;

  factory GpsRouteResponseModel.fromJson(Map<String, dynamic> json) {
    return GpsRouteResponseModel(
      start: MapMatchResponseModel.fromJson(
        Map<String, dynamic>.from(json['start'] as Map),
      ),
      destination: MapMatchResponseModel.fromJson(
        Map<String, dynamic>.from(json['destination'] as Map),
      ),
      route: RouteResponseModel.fromJson(
        Map<String, dynamic>.from(json['route'] as Map),
      ),
    );
  }
}

class MeetingPointModel {
  const MeetingPointModel({
    required this.id,
    required this.name,
    this.nodeId,
    required this.latitude,
    required this.longitude,
  });

  final String id;
  final String name;
  final int? nodeId;
  final double latitude;
  final double longitude;

  LatLng get latLng => LatLng(latitude, longitude);

  factory MeetingPointModel.fromJson(Map<String, dynamic> json) {
    return MeetingPointModel(
      id: JsonReaders.stringValue(json['id']),
      name: JsonReaders.stringValue(json['name']),
      nodeId: JsonReaders.intOrNull(json['nodeId']),
      latitude: JsonReaders.doubleValue(json['latitude']),
      longitude: JsonReaders.doubleValue(json['longitude']),
    );
  }
}

class ParticipantRouteResponseModel {
  const ParticipantRouteResponseModel({
    required this.userId,
    required this.distanceMeters,
    required this.etaSeconds,
    required this.path,
  });

  final int userId;
  final double distanceMeters;
  final double etaSeconds;
  final List<RoutePointModel> path;

  List<LatLng> get latLngPath =>
      path.map((p) => p.latLng).toList(growable: false);

  factory ParticipantRouteResponseModel.fromJson(Map<String, dynamic> json) {
    return ParticipantRouteResponseModel(
      userId: JsonReaders.intValue(json['userId']),
      distanceMeters: JsonReaders.doubleValue(json['distanceMeters']),
      etaSeconds: JsonReaders.doubleValue(json['etaSeconds']),
      path: JsonReaders.listOf(json['path'], RoutePointModel.fromJson),
    );
  }
}

class MeetingOptimizationResponseModel {
  const MeetingOptimizationResponseModel({
    required this.meetingPoint,
    required this.maxEtaSeconds,
    required this.totalEtaSeconds,
    required this.totalDistanceMeters,
    required this.participants,
  });

  final MeetingPointModel meetingPoint;
  final double maxEtaSeconds;
  final double totalEtaSeconds;
  final double totalDistanceMeters;
  final List<ParticipantRouteResponseModel> participants;

  factory MeetingOptimizationResponseModel.fromJson(Map<String, dynamic> json) {
    return MeetingOptimizationResponseModel(
      meetingPoint: MeetingPointModel.fromJson(
        Map<String, dynamic>.from(json['meetingPoint'] as Map),
      ),
      maxEtaSeconds: JsonReaders.doubleValue(json['maxEtaSeconds']),
      totalEtaSeconds: JsonReaders.doubleValue(json['totalEtaSeconds']),
      totalDistanceMeters:
          JsonReaders.doubleValue(json['totalDistanceMeters']),
      participants: JsonReaders.listOf(
        json['participants'],
        ParticipantRouteResponseModel.fromJson,
      ),
    );
  }
}

class GraphNodeModel {
  const GraphNodeModel({
    required this.id,
    required this.latitude,
    required this.longitude,
  });

  final int id;
  final double latitude;
  final double longitude;

  factory GraphNodeModel.fromJson(Map<String, dynamic> json) {
    return GraphNodeModel(
      id: JsonReaders.intValue(json['id']),
      latitude: JsonReaders.doubleValue(json['latitude']),
      longitude: JsonReaders.doubleValue(json['longitude']),
    );
  }
}

class GraphEdgeModel {
  const GraphEdgeModel({
    required this.fromNodeId,
    required this.toNodeId,
    required this.distanceMeters,
    required this.bidirectional,
  });

  final int fromNodeId;
  final int toNodeId;
  final double distanceMeters;
  final bool bidirectional;

  factory GraphEdgeModel.fromJson(Map<String, dynamic> json) {
    return GraphEdgeModel(
      fromNodeId: JsonReaders.intValue(json['fromNodeId']),
      toNodeId: JsonReaders.intValue(json['toNodeId']),
      distanceMeters: JsonReaders.doubleValue(json['distanceMeters']),
      bidirectional: JsonReaders.boolValue(json['bidirectional'], fallback: true),
    );
  }
}

class GraphResponseModel {
  const GraphResponseModel({
    required this.nodes,
    required this.edges,
    required this.meetingPoints,
  });

  final List<GraphNodeModel> nodes;
  final List<GraphEdgeModel> edges;
  final List<MeetingPointModel> meetingPoints;

  factory GraphResponseModel.fromJson(Map<String, dynamic> json) {
    return GraphResponseModel(
      nodes: JsonReaders.listOf(json['nodes'], GraphNodeModel.fromJson),
      edges: JsonReaders.listOf(json['edges'], GraphEdgeModel.fromJson),
      meetingPoints:
          JsonReaders.listOf(json['meetingPoints'], MeetingPointModel.fromJson),
    );
  }

  NavGraphBounds? get bounds {
    if (nodes.isEmpty) return null;
    var minLat = nodes.first.latitude;
    var maxLat = minLat;
    var minLng = nodes.first.longitude;
    var maxLng = minLng;
    for (final n in nodes) {
      if (n.latitude < minLat) minLat = n.latitude;
      if (n.latitude > maxLat) maxLat = n.latitude;
      if (n.longitude < minLng) minLng = n.longitude;
      if (n.longitude > maxLng) maxLng = n.longitude;
    }
    return NavGraphBounds(
      minLat: minLat,
      maxLat: maxLat,
      minLng: minLng,
      maxLng: maxLng,
    );
  }
}

class NavGraphBounds {
  const NavGraphBounds({
    required this.minLat,
    required this.maxLat,
    required this.minLng,
    required this.maxLng,
  });

  final double minLat;
  final double maxLat;
  final double minLng;
  final double maxLng;

  LatLng get southWest => LatLng(minLat, minLng);
  LatLng get northEast => LatLng(maxLat, maxLng);
}

class MemberLocationResponseModel {
  const MemberLocationResponseModel({
    required this.groupId,
    required this.userId,
    this.latitude,
    this.longitude,
    this.accuracyMeters,
    required this.status,
    this.updatedAt,
  });

  final int groupId;
  final int userId;
  final double? latitude;
  final double? longitude;
  final double? accuracyMeters;
  final String status;
  final DateTime? updatedAt;

  factory MemberLocationResponseModel.fromJson(Map<String, dynamic> json) {
    return MemberLocationResponseModel(
      groupId: JsonReaders.intValue(json['groupId']),
      userId: JsonReaders.intValue(json['userId']),
      latitude: JsonReaders.doubleOrNull(json['latitude']),
      longitude: JsonReaders.doubleOrNull(json['longitude']),
      accuracyMeters: JsonReaders.doubleOrNull(json['accuracyMeters']),
      status: JsonReaders.stringValue(json['status'], fallback: 'MISSING'),
      updatedAt: JsonReaders.dateTimeOrNull(json['updatedAt']),
    );
  }
}

class DemoVisitorModel {
  const DemoVisitorModel({
    required this.id,
    required this.name,
    this.latitude,
    this.longitude,
    this.position,
    required this.status,
    this.distanceMeters,
    this.remainingMeters,
    this.etaSeconds,
    this.path,
  });

  final int id;
  final String name;
  final double? latitude;
  final double? longitude;
  final String? position;
  final String status;
  final double? distanceMeters;
  final double? remainingMeters;
  final double? etaSeconds;
  final List<RoutePointModel>? path;

  LatLng? get latLng {
    if (latitude == null || longitude == null) return null;
    return LatLng(latitude!, longitude!);
  }

  List<LatLng> get latLngPath =>
      path?.map((p) => p.latLng).toList(growable: false) ?? const [];

  DemoVisitorModel copyWith({
    double? latitude,
    double? longitude,
    String? status,
    double? distanceMeters,
    double? remainingMeters,
    double? etaSeconds,
    List<RoutePointModel>? path,
    bool clearPath = false,
  }) {
    return DemoVisitorModel(
      id: id,
      name: name,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      position: position,
      status: status ?? this.status,
      distanceMeters: distanceMeters ?? this.distanceMeters,
      remainingMeters: remainingMeters ?? this.remainingMeters,
      etaSeconds: etaSeconds ?? this.etaSeconds,
      path: clearPath ? null : (path ?? this.path),
    );
  }

  factory DemoVisitorModel.fromJson(Map<String, dynamic> json) {
    List<RoutePointModel>? path;
    final rawPath = json['path'];
    if (rawPath is List) {
      path = JsonReaders.listOf(rawPath, RoutePointModel.fromJson);
    }

    return DemoVisitorModel(
      id: JsonReaders.intValue(json['id']),
      name: JsonReaders.stringValue(json['name']),
      latitude: JsonReaders.doubleOrNull(json['latitude']),
      longitude: JsonReaders.doubleOrNull(json['longitude']),
      position: JsonReaders.stringOrNull(json['position']),
      status: JsonReaders.stringValue(json['status']),
      distanceMeters: JsonReaders.doubleOrNull(json['distanceMeters']),
      remainingMeters: JsonReaders.doubleOrNull(json['remainingMeters']),
      etaSeconds: JsonReaders.doubleOrNull(json['etaSeconds']),
      path: path,
    );
  }
}

class DemoStateModel {
  const DemoStateModel({
    required this.simulationId,
    required this.revision,
    required this.routeRevision,
    required this.status,
    required this.speed,
    this.meetingPoint,
    this.optimizerMaxEtaSeconds,
    this.optimizerTotalDistanceMeters,
    required this.visitors,
  });

  final String simulationId;
  final int revision;
  final int routeRevision;
  final String status;
  final double speed;
  final MeetingPointModel? meetingPoint;
  final double? optimizerMaxEtaSeconds;
  final double? optimizerTotalDistanceMeters;
  final List<DemoVisitorModel> visitors;

  factory DemoStateModel.fromJson(Map<String, dynamic> json) {
    MeetingPointModel? meetingPoint;
    final mp = json['meetingPoint'];
    if (mp is Map) {
      meetingPoint = MeetingPointModel.fromJson(Map<String, dynamic>.from(mp));
    }

    return DemoStateModel(
      simulationId: JsonReaders.stringValue(json['simulationId']),
      revision: JsonReaders.intValue(json['revision']),
      routeRevision: JsonReaders.intValue(json['routeRevision']),
      status: JsonReaders.stringValue(json['status']),
      speed: JsonReaders.doubleValue(json['speed'], fallback: 1.4),
      meetingPoint: meetingPoint,
      optimizerMaxEtaSeconds:
          JsonReaders.doubleOrNull(json['optimizerMaxEtaSeconds']),
      optimizerTotalDistanceMeters:
          JsonReaders.doubleOrNull(json['optimizerTotalDistanceMeters']),
      visitors: JsonReaders.listOf(json['visitors'], DemoVisitorModel.fromJson),
    );
  }
}

class DemoEventEnvelope {
  const DemoEventEnvelope({
    required this.event,
    this.occurredAt,
    required this.data,
  });

  final String event;
  final DateTime? occurredAt;
  final DemoStateModel data;

  factory DemoEventEnvelope.fromJson(Map<String, dynamic> json) {
    return DemoEventEnvelope(
      event: JsonReaders.stringValue(json['event']),
      occurredAt: JsonReaders.dateTimeOrNull(json['occurredAt']),
      data: DemoStateModel.fromJson(
        Map<String, dynamic>.from(json['data'] as Map),
      ),
    );
  }
}

class ProductionEventEnvelope {
  const ProductionEventEnvelope({
    required this.event,
    this.groupId,
    this.meetingId,
    this.occurredAt,
    required this.data,
  });

  final String event;
  final int? groupId;
  final int? meetingId;
  final DateTime? occurredAt;
  final Object? data;

  factory ProductionEventEnvelope.fromJson(Map<String, dynamic> json) {
    return ProductionEventEnvelope(
      event: JsonReaders.stringValue(json['event']),
      groupId: JsonReaders.intOrNull(json['groupId']),
      meetingId: JsonReaders.intOrNull(json['meetingId']),
      occurredAt: JsonReaders.dateTimeOrNull(json['occurredAt']),
      data: json['data'],
    );
  }
}

enum DemoCommandAction {
  spawn,
  optimize,
  routes,
  start,
  pause,
  reset,
  speed;

  String get wireName => switch (this) {
        DemoCommandAction.spawn => 'SPAWN',
        DemoCommandAction.optimize => 'OPTIMIZE',
        DemoCommandAction.routes => 'ROUTES',
        DemoCommandAction.start => 'START',
        DemoCommandAction.pause => 'PAUSE',
        DemoCommandAction.reset => 'RESET',
        DemoCommandAction.speed => 'SPEED',
      };
}
