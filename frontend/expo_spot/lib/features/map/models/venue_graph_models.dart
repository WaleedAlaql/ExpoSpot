import 'package:expo_spot/core/json/json_readers.dart';
import 'package:latlong2/latlong.dart';

/// Mirrors backend `GraphNode` records in `nodes.json`.
class VenueGraphNode {
  const VenueGraphNode({
    required this.id,
    required this.latitude,
    required this.longitude,
    required this.componentId,
  });

  final int id;
  final double latitude;
  final double longitude;
  final int componentId;

  LatLng get latLng => LatLng(latitude, longitude);

  factory VenueGraphNode.fromJson(Map<String, dynamic> json) {
    return VenueGraphNode(
      id: JsonReaders.intValue(json['id']),
      latitude: JsonReaders.doubleValue(json['latitude']),
      longitude: JsonReaders.doubleValue(json['longitude']),
      componentId: JsonReaders.intValue(json['componentId']),
    );
  }
}

/// Mirrors backend edge inputs in `edges.json`.
class VenueGraphEdge {
  const VenueGraphEdge({
    required this.fromNodeId,
    required this.toNodeId,
    required this.bidirectional,
    required this.componentId,
  });

  final int fromNodeId;
  final int toNodeId;
  final bool bidirectional;
  final int componentId;

  factory VenueGraphEdge.fromJson(Map<String, dynamic> json) {
    return VenueGraphEdge(
      fromNodeId: JsonReaders.intValue(json['fromNodeId']),
      toNodeId: JsonReaders.intValue(json['toNodeId']),
      bidirectional: JsonReaders.boolValue(json['bidirectional'], fallback: true),
      componentId: JsonReaders.intValue(json['componentId']),
    );
  }
}

/// Mirrors backend `meeting-points.json` entries.
class VenueMeetingPoint {
  const VenueMeetingPoint({
    required this.id,
    required this.name,
    required this.nodeId,
    required this.latitude,
    required this.longitude,
    required this.status,
  });

  final String id;
  final String name;
  final int nodeId;
  final double latitude;
  final double longitude;
  final String status;

  LatLng get latLng => LatLng(latitude, longitude);

  factory VenueMeetingPoint.fromJson(Map<String, dynamic> json) {
    return VenueMeetingPoint(
      id: JsonReaders.stringValue(json['id']),
      name: JsonReaders.stringValue(json['name']),
      nodeId: JsonReaders.intValue(json['nodeId']),
      latitude: JsonReaders.doubleValue(json['latitude']),
      longitude: JsonReaders.doubleValue(json['longitude']),
      status: JsonReaders.stringValue(json['status']),
    );
  }
}
