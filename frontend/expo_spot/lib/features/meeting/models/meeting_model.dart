import 'package:expo_spot/core/json/json_readers.dart';
import 'package:expo_spot/features/meeting/models/meeting_status.dart';
import 'package:expo_spot/features/meeting/models/reunification_point_model.dart';

/// Mirrors `com.nawaf.meetingpoint.Model.Meeting`.
class MeetingModel {
  const MeetingModel({
    required this.id,
    required this.groupId,
    required this.createdById,
    this.status = MeetingStatus.created,
    this.meetingPointName,
    this.meetingLatitude,
    this.meetingLongitude,
    this.maxEtaSeconds,
    required this.createdAt,
    this.completedAt,
  });

  final int id;
  final int groupId;
  final int createdById;
  final MeetingStatus status;
  final String? meetingPointName;
  final double? meetingLatitude;
  final double? meetingLongitude;
  final double? maxEtaSeconds;
  final DateTime createdAt;
  final DateTime? completedAt;

  ReunificationPointModel? get reunificationPoint {
    if (meetingLatitude == null ||
        meetingLongitude == null ||
        meetingPointName == null) {
      return null;
    }
    return ReunificationPointModel.fromMeetingFields(
      id: 'meeting-$id',
      name: meetingPointName!,
      latitude: meetingLatitude!,
      longitude: meetingLongitude!,
    );
  }

  factory MeetingModel.fromJson(Map<String, dynamic> json) {
    return MeetingModel(
      id: JsonReaders.intValue(json['id']),
      groupId: JsonReaders.intValue(json['groupId'] ?? json['group']?['id']),
      createdById:
          JsonReaders.intValue(json['createdById'] ?? json['createdBy']?['id']),
      status: MeetingStatus.fromJson(json['status'] ?? 'CREATED'),
      meetingPointName: JsonReaders.stringOrNull(json['meetingPointName']),
      meetingLatitude: JsonReaders.doubleOrNull(json['meetingLatitude']),
      meetingLongitude: JsonReaders.doubleOrNull(json['meetingLongitude']),
      maxEtaSeconds: JsonReaders.doubleOrNull(json['maxEtaSeconds']),
      createdAt: JsonReaders.dateTimeOrNull(json['createdAt']) ?? DateTime.now(),
      completedAt: JsonReaders.dateTimeOrNull(json['completedAt']),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'groupId': groupId,
        'createdById': createdById,
        'status': status.toJson(),
        if (meetingPointName != null) 'meetingPointName': meetingPointName,
        if (meetingLatitude != null) 'meetingLatitude': meetingLatitude,
        if (meetingLongitude != null) 'meetingLongitude': meetingLongitude,
        if (maxEtaSeconds != null) 'maxEtaSeconds': maxEtaSeconds,
        'createdAt': createdAt.toIso8601String(),
        if (completedAt != null) 'completedAt': completedAt!.toIso8601String(),
      };

  MeetingModel copyWith({
    int? id,
    int? groupId,
    int? createdById,
    MeetingStatus? status,
    String? meetingPointName,
    double? meetingLatitude,
    double? meetingLongitude,
    double? maxEtaSeconds,
    DateTime? createdAt,
    DateTime? completedAt,
  }) {
    return MeetingModel(
      id: id ?? this.id,
      groupId: groupId ?? this.groupId,
      createdById: createdById ?? this.createdById,
      status: status ?? this.status,
      meetingPointName: meetingPointName ?? this.meetingPointName,
      meetingLatitude: meetingLatitude ?? this.meetingLatitude,
      meetingLongitude: meetingLongitude ?? this.meetingLongitude,
      maxEtaSeconds: maxEtaSeconds ?? this.maxEtaSeconds,
      createdAt: createdAt ?? this.createdAt,
      completedAt: completedAt ?? this.completedAt,
    );
  }
}
