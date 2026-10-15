import 'package:expo_spot/core/json/json_readers.dart';

/// Mirrors `com.nawaf.meetingpoint.DTO.Location.LocationUpdateRequest`.
class LocationUpdateRequestModel {
  const LocationUpdateRequestModel({
    required this.groupId,
    required this.userId,
    required this.latitude,
    required this.longitude,
    this.accuracyMeters,
  });

  final int groupId;
  final int userId;
  final double latitude;
  final double longitude;
  final double? accuracyMeters;

  factory LocationUpdateRequestModel.fromJson(Map<String, dynamic> json) {
    return LocationUpdateRequestModel(
      groupId: JsonReaders.intValue(json['groupId']),
      userId: JsonReaders.intValue(json['userId']),
      latitude: JsonReaders.doubleValue(json['latitude']),
      longitude: JsonReaders.doubleValue(json['longitude']),
      accuracyMeters: JsonReaders.doubleOrNull(json['accuracyMeters']),
    );
  }

  Map<String, dynamic> toJson() => {
        'groupId': groupId,
        'userId': userId,
        'latitude': latitude,
        'longitude': longitude,
        if (accuracyMeters != null) 'accuracyMeters': accuracyMeters,
      };
}
