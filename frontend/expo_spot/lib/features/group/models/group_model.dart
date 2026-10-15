import 'package:expo_spot/core/json/json_readers.dart';
import 'package:expo_spot/features/group/models/group_member_model.dart';
import 'package:expo_spot/features/meeting/models/meeting_model.dart';
import 'package:expo_spot/features/user/models/user_model.dart';

/// Mirrors `com.nawaf.meetingpoint.Model.Group` (`visitor_groups` table).
class GroupModel {
  const GroupModel({
    required this.id,
    required this.name,
    required this.inviteCode,
    required this.ownerId,
    this.owner,
    this.members = const [],
    this.meetings = const [],
    required this.createdAt,
  });

  final int id;
  final String name;
  final String inviteCode;
  final int ownerId;
  final UserModel? owner;
  final List<GroupMemberModel> members;
  final List<MeetingModel> meetings;
  final DateTime createdAt;

  factory GroupModel.fromJson(Map<String, dynamic> json) {
    final ownerJson = json['owner'];
    return GroupModel(
      id: JsonReaders.intValue(json['id']),
      name: JsonReaders.stringValue(json['name']),
      inviteCode: JsonReaders.stringValue(json['inviteCode']),
      ownerId: JsonReaders.intValue(json['ownerId'] ?? json['owner']?['id']),
      owner: ownerJson is Map<String, dynamic>
          ? UserModel.fromJson(ownerJson)
          : null,
      members: JsonReaders.listOf(json['members'], GroupMemberModel.fromJson),
      meetings: JsonReaders.listOf(json['meetings'], MeetingModel.fromJson),
      createdAt: JsonReaders.dateTimeOrNull(json['createdAt']) ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'inviteCode': inviteCode,
        'ownerId': ownerId,
        if (owner != null) 'owner': owner!.toJson(),
        'members': members.map((m) => m.toJson()).toList(),
        'meetings': meetings.map((m) => m.toJson()).toList(),
        'createdAt': createdAt.toIso8601String(),
      };

  GroupModel copyWith({
    int? id,
    String? name,
    String? inviteCode,
    int? ownerId,
    UserModel? owner,
    List<GroupMemberModel>? members,
    List<MeetingModel>? meetings,
    DateTime? createdAt,
  }) {
    return GroupModel(
      id: id ?? this.id,
      name: name ?? this.name,
      inviteCode: inviteCode ?? this.inviteCode,
      ownerId: ownerId ?? this.ownerId,
      owner: owner ?? this.owner,
      members: members ?? this.members,
      meetings: meetings ?? this.meetings,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
