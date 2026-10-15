import 'package:expo_spot/features/group/models/group_member_model.dart';
import 'package:expo_spot/features/group/models/group_model.dart';
import 'package:expo_spot/features/group/models/member_status.dart';
import 'package:expo_spot/features/meeting/models/meeting_model.dart';
import 'package:expo_spot/features/meeting/models/meeting_status.dart';
import 'package:expo_spot/features/meeting/models/reunification_point_model.dart';
import 'package:expo_spot/features/user/models/user_model.dart';

/// Offline fixtures — Expo Dubai testing cohort (وليد + 4 participants).
abstract final class MockExpoData {
  static final DateTime _seedTime =
      DateTime.parse('2026-10-15T10:00:00.000');

  /// Earth Plaza (leader), Sea Plaza, Sun Plaza, peripheral, pavilion lane.
  static const earthPlazaLat = 24.957803;
  static const earthPlazaLng = 55.1562148;
  static const seaPlazaLat = 24.9566629;
  static const seaPlazaLng = 55.1462239;
  static const sunPlazaLat = 24.9670353;
  static const sunPlazaLng = 55.1530789;
  static const peripheralLat = 24.9538;
  static const peripheralLng = 55.1432;
  static const pavilionLat = 24.9594;
  static const pavilionLng = 55.1582;

  static final List<UserModel> users = [
    UserModel(
      id: 1,
      name: 'وليد',
      email: 'waleed@expospot.local',
      createdAt: _seedTime,
    ),
    UserModel(
      id: 2,
      name: 'سلطان',
      email: 'sultan@expospot.local',
      createdAt: _seedTime,
    ),
    UserModel(
      id: 3,
      name: 'خالد',
      email: 'khaled@expospot.local',
      createdAt: _seedTime,
    ),
    UserModel(
      id: 4,
      name: 'عمر',
      email: 'omar@expospot.local',
      createdAt: _seedTime,
    ),
    UserModel(
      id: 5,
      name: 'فيصل',
      email: 'faisal@expospot.local',
      createdAt: _seedTime,
    ),
  ];

  static UserModel get currentUser => users.first;

  static UserModel userById(int id) =>
      users.firstWhere((u) => u.id == id, orElse: () => currentUser);

  /// From `assets/map-data/meeting-points.json`.
  static const reunificationPoints = [
    ReunificationPointModel(
      id: 'mp-986398789',
      name: 'Earth Plaza',
      nodeId: 3206,
      latitude: earthPlazaLat,
      longitude: earthPlazaLng,
    ),
    ReunificationPointModel(
      id: 'mp-986398790',
      name: 'Sea Plaza',
      nodeId: 1081,
      latitude: seaPlazaLat,
      longitude: seaPlazaLng,
    ),
    ReunificationPointModel(
      id: 'mp-986398791',
      name: 'Sun Plaza',
      nodeId: 2387,
      latitude: sunPlazaLat,
      longitude: sunPlazaLng,
    ),
  ];

  static GroupMemberModel member({
    required int id,
    required int groupId,
    required int userId,
    required double lat,
    required double lng,
    MemberStatus status = MemberStatus.navigating,
    bool sharing = true,
    double? accuracy,
  }) {
    return GroupMemberModel(
      id: id,
      groupId: groupId,
      userId: userId,
      user: userById(userId),
      latitude: lat,
      longitude: lng,
      accuracyMeters: accuracy ?? 12,
      locationSharingEnabled: sharing,
      status: status,
      lastLocationAt: DateTime.now(),
      joinedAt: _seedTime,
    );
  }

  static GroupMemberModel _hostMember(int groupId) => member(
        id: 1,
        groupId: groupId,
        userId: 1,
        lat: earthPlazaLat,
        lng: earthPlazaLng,
        status: MemberStatus.navigating,
      );

  /// Sultan — Sea Plaza, en route.
  static GroupMemberModel _sultan(int groupId) => member(
        id: 2,
        groupId: groupId,
        userId: 2,
        lat: seaPlazaLat,
        lng: seaPlazaLng,
        status: MemberStatus.navigating,
      );

  /// Khaled — Sun Plaza, arrived at meet area.
  static GroupMemberModel _khaled(int groupId) => member(
        id: 3,
        groupId: groupId,
        userId: 3,
        lat: sunPlazaLat,
        lng: sunPlazaLng,
        status: MemberStatus.arrived,
      );

  /// Omar — peripheral node, low battery / weak GPS.
  static GroupMemberModel _omar(int groupId) => member(
        id: 4,
        groupId: groupId,
        userId: 4,
        lat: peripheralLat,
        lng: peripheralLng,
        status: MemberStatus.idle,
        accuracy: 95,
      );

  /// Faisal — pavilion lane, en route.
  static GroupMemberModel _faisal(int groupId) => member(
        id: 5,
        groupId: groupId,
        userId: 5,
        lat: pavilionLat,
        lng: pavilionLng,
        status: MemberStatus.navigating,
      );

  static List<GroupMemberModel> testingCohort(int groupId) => [
        _hostMember(groupId),
        _sultan(groupId),
        _khaled(groupId),
        _omar(groupId),
        _faisal(groupId),
      ];

  static GroupModel soloHostGroup({required String inviteCode}) {
    return GroupModel(
      id: 0,
      name: 'مجموعة إكسبو',
      inviteCode: inviteCode,
      ownerId: currentUser.id,
      owner: currentUser,
      members: [_hostMember(0)],
      meetings: const [],
      createdAt: DateTime.now(),
    );
  }

  static GroupModel demoGroup({required String inviteCode}) {
    return GroupModel(
      id: 1,
      name: 'مجموعة إكسبو دبي',
      inviteCode: inviteCode,
      ownerId: currentUser.id,
      owner: currentUser,
      members: testingCohort(1),
      meetings: [
        MeetingModel(
          id: 1,
          groupId: 1,
          createdById: currentUser.id,
          status: MeetingStatus.created,
          createdAt: DateTime.now(),
        ),
      ],
      createdAt: _seedTime,
    );
  }

  static List<GroupMemberModel> stagedJoins(int groupId) => [
        _sultan(groupId),
        _khaled(groupId),
        _omar(groupId),
        _faisal(groupId),
      ];
}
