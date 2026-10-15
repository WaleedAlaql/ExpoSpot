import 'package:expo_spot/core/json/json_readers.dart';

/// Mirrors `com.nawaf.meetingpoint.DTO.Location.MemberLocationResponse`.
class MemberLocationResponseModel {
  const MemberLocationResponseModel({
    required this.groupId,
    required this.userId,
    required this.latitude,
    required this.longitude,
    this.accuracyMeters,
    required this.status,
    this.updatedAt,
  });

  final int groupId;
  final int userId;
  final double latitude;
  final double longitude;
  final double? accuracyMeters;
  final String status;
  final DateTime? updatedAt;

  factory MemberLocationResponseModel.fromJson(Map<String, dynamic> json) {
    return MemberLocationResponseModel(
      groupId: JsonReaders.intValue(json['groupId']),
      userId: JsonReaders.intValue(json['userId']),
      latitude: JsonReaders.doubleValue(json['latitude']),
      longitude: JsonReaders.doubleValue(json['longitude']),
      accuracyMeters: JsonReaders.doubleOrNull(json['accuracyMeters']),
      status: JsonReaders.stringValue(json['status']),
      updatedAt: JsonReaders.dateTimeOrNull(json['updatedAt']),
    );
  }

  Map<String, dynamic> toJson() => {
        'groupId': groupId,
        'userId': userId,
        'latitude': latitude,
        'longitude': longitude,
        if (accuracyMeters != null) 'accuracyMeters': accuracyMeters,
        'status': status,
        if (updatedAt != null) 'updatedAt': updatedAt!.toIso8601String(),
      };
}
