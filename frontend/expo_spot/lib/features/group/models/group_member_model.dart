import 'package:expo_spot/core/json/json_readers.dart';
import 'package:expo_spot/features/group/models/member_status.dart';
import 'package:expo_spot/features/user/models/user_model.dart';

/// Mirrors `com.nawaf.meetingpoint.Model.GroupMember`.
class GroupMemberModel {
  const GroupMemberModel({
    required this.id,
    required this.groupId,
    required this.userId,
    this.user,
    this.latitude,
    this.longitude,
    this.accuracyMeters,
    this.locationSharingEnabled = false,
    this.status = MemberStatus.idle,
    this.lastLocationAt,
    required this.joinedAt,
  });

  final int id;
  final int groupId;
  final int userId;
  final UserModel? user;
  final double? latitude;
  final double? longitude;
  final double? accuracyMeters;
  final bool locationSharingEnabled;
  final MemberStatus status;
  final DateTime? lastLocationAt;
  final DateTime joinedAt;

  factory GroupMemberModel.fromJson(Map<String, dynamic> json) {
    final nestedUser = json['user'];
    return GroupMemberModel(
      id: JsonReaders.intValue(json['id']),
      groupId: JsonReaders.intValue(json['groupId'] ?? json['group']?['id']),
      userId: JsonReaders.intValue(json['userId'] ?? json['user']?['id']),
      user: nestedUser is Map<String, dynamic>
          ? UserModel.fromJson(nestedUser)
          : null,
      latitude: JsonReaders.doubleOrNull(json['latitude']),
      longitude: JsonReaders.doubleOrNull(json['longitude']),
      accuracyMeters: JsonReaders.doubleOrNull(json['accuracyMeters']),
      locationSharingEnabled: JsonReaders.boolValue(
        json['locationSharingEnabled'],
      ),
      status: MemberStatus.fromJson(json['status'] ?? 'IDLE'),
      lastLocationAt: JsonReaders.dateTimeOrNull(json['lastLocationAt']),
      joinedAt: JsonReaders.dateTimeOrNull(json['joinedAt']) ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'groupId': groupId,
        'userId': userId,
        if (user != null) 'user': user!.toJson(),
        if (latitude != null) 'latitude': latitude,
        if (longitude != null) 'longitude': longitude,
        if (accuracyMeters != null) 'accuracyMeters': accuracyMeters,
        'locationSharingEnabled': locationSharingEnabled,
        'status': status.toJson(),
        if (lastLocationAt != null)
          'lastLocationAt': lastLocationAt!.toIso8601String(),
        'joinedAt': joinedAt.toIso8601String(),
      };

  GroupMemberModel copyWith({
    int? id,
    int? groupId,
    int? userId,
    UserModel? user,
    double? latitude,
    double? longitude,
    double? accuracyMeters,
    bool? locationSharingEnabled,
    MemberStatus? status,
    DateTime? lastLocationAt,
    DateTime? joinedAt,
  }) {
    return GroupMemberModel(
      id: id ?? this.id,
      groupId: groupId ?? this.groupId,
      userId: userId ?? this.userId,
      user: user ?? this.user,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      accuracyMeters: accuracyMeters ?? this.accuracyMeters,
      locationSharingEnabled:
          locationSharingEnabled ?? this.locationSharingEnabled,
      status: status ?? this.status,
      lastLocationAt: lastLocationAt ?? this.lastLocationAt,
      joinedAt: joinedAt ?? this.joinedAt,
    );
  }
}
