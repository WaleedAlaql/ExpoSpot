import 'package:expo_spot/core/json/json_readers.dart';

/// Reunification / meet point — mirrors `MeetingPointResponse` and graph `MeetingPoint`.
class ReunificationPointModel {
  const ReunificationPointModel({
    required this.id,
    required this.name,
    required this.nodeId,
    required this.latitude,
    required this.longitude,
  });

  final String id;
  final String name;
  final int nodeId;
  final double latitude;
  final double longitude;

  factory ReunificationPointModel.fromJson(Map<String, dynamic> json) {
    return ReunificationPointModel(
      id: JsonReaders.stringValue(json['id']),
      name: JsonReaders.stringValue(json['name']),
      nodeId: JsonReaders.intValue(json['nodeId']),
      latitude: JsonReaders.doubleValue(json['latitude']),
      longitude: JsonReaders.doubleValue(json['longitude']),
    );
  }

  /// From `Meeting` entity fields when a full graph point id is unavailable.
  factory ReunificationPointModel.fromMeetingFields({
    required String name,
    required double latitude,
    required double longitude,
    String id = 'meeting-point',
    int nodeId = 0,
  }) {
    return ReunificationPointModel(
      id: id,
      name: name,
      nodeId: nodeId,
      latitude: latitude,
      longitude: longitude,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'nodeId': nodeId,
        'latitude': latitude,
        'longitude': longitude,
      };
}
