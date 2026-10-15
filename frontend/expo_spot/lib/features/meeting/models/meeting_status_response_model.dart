import 'package:expo_spot/core/json/json_readers.dart';
import 'package:expo_spot/features/meeting/models/reunification_point_model.dart';

/// Mirrors `com.nawaf.meetingpoint.DTO.Meeting.MeetingStatusResponse`.
class MeetingStatusResponseModel {
  const MeetingStatusResponseModel({
    required this.meetingId,
    required this.status,
    this.meetingPoint,
    this.maxEtaSeconds,
  });

  final int meetingId;
  final String status;
  final ReunificationPointModel? meetingPoint;
  final int? maxEtaSeconds;

  factory MeetingStatusResponseModel.fromJson(Map<String, dynamic> json) {
    final pointJson = json['meetingPoint'];
    return MeetingStatusResponseModel(
      meetingId: JsonReaders.intValue(json['meetingId']),
      status: JsonReaders.stringValue(json['status']),
      meetingPoint: pointJson is Map<String, dynamic>
          ? ReunificationPointModel.fromJson(pointJson)
          : null,
      maxEtaSeconds: JsonReaders.intOrNull(json['maxEtaSeconds']),
    );
  }

  Map<String, dynamic> toJson() => {
        'meetingId': meetingId,
        'status': status,
        if (meetingPoint != null) 'meetingPoint': meetingPoint!.toJson(),
        if (maxEtaSeconds != null) 'maxEtaSeconds': maxEtaSeconds,
      };
}
