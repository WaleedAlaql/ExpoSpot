import 'dart:math';

import 'package:expo_spot/features/group/data/group_member_ui_mapper.dart';
import 'package:expo_spot/features/group/data/mock_expo_data.dart';
import 'package:expo_spot/features/group/data/mock_group_repository.dart';
import 'package:expo_spot/features/group/domain/group_member.dart';
import 'package:expo_spot/features/group/models/group_model.dart';
import 'package:expo_spot/features/meeting/models/reunification_point_model.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';

class ActiveGroupState {
  const ActiveGroupState({
    required this.groupNameKey,
    required this.inviteCode,
    required this.members,
    this._sessionActive = false,
    this.customGroupName,
    this.meetPoint,
    this.meetPointLabelKey = 'meet_point_primary',
    this.showRoutes = false,
    this.reunionConfirmed = false,
    this.showCelebration = false,
    this.alternateIndex = 0,
    this.backendGroupId,
  });

  final String groupNameKey;
  final String inviteCode;
  final List<GroupMember> members;
  final bool? _sessionActive;
  final String? customGroupName;
  final LatLng? meetPoint;
  final String meetPointLabelKey;
  final bool showRoutes;
  final bool reunionConfirmed;
  final bool showCelebration;
  final int alternateIndex;
  final int? backendGroupId;

  bool get sessionActive => _sessionActive ?? false;

  int get totalMembers => members.length;

  int get onlineCount => members
      .where((m) => m.connection != MemberConnection.offline)
      .length;

  int get arrivedCount =>
      members.where((m) => m.travelStatus == MemberTravelStatus.arrived).length;

  int get activeParticipantCount => members
      .where((m) => m.connection != MemberConnection.offline)
      .length;

  int get activeArrivedCount => members
      .where(
        (m) =>
            m.connection != MemberConnection.offline &&
            m.travelStatus == MemberTravelStatus.arrived,
      )
      .length;

  GroupMember? get currentUser {
    for (final member in members) {
      if (member.isCurrentUser) return member;
    }
    return null;
  }

  String resolveGroupTitle(String Function(String key) translate) {
    final custom = customGroupName?.trim();
    if (custom != null && custom.isNotEmpty) return custom;
    return translate(groupNameKey);
  }

  ActiveGroupState copyWith({
    String? groupNameKey,
    String? inviteCode,
    List<GroupMember>? members,
    bool? sessionActive,
    String? customGroupName,
    bool clearCustomGroupName = false,
    LatLng? meetPoint,
    String? meetPointLabelKey,
    bool? showRoutes,
    bool? reunionConfirmed,
    bool? showCelebration,
    int? alternateIndex,
    bool clearMeetPoint = false,
    int? backendGroupId,
  }) {
    return ActiveGroupState(
      groupNameKey: groupNameKey ?? this.groupNameKey,
      inviteCode: inviteCode ?? this.inviteCode,
      members: members ?? this.members,
      sessionActive: sessionActive ?? this.sessionActive,
      customGroupName:
          clearCustomGroupName ? null : (customGroupName ?? this.customGroupName),
      meetPoint: clearMeetPoint ? null : (meetPoint ?? this.meetPoint),
      meetPointLabelKey: meetPointLabelKey ?? this.meetPointLabelKey,
      showRoutes: showRoutes ?? this.showRoutes,
      reunionConfirmed: reunionConfirmed ?? this.reunionConfirmed,
      showCelebration: showCelebration ?? this.showCelebration,
      alternateIndex: alternateIndex ?? this.alternateIndex,
      backendGroupId: backendGroupId ?? this.backendGroupId,
    );
  }
}

class ActiveGroupController extends StateNotifier<ActiveGroupState> {
  ActiveGroupController(this._repository) : super(_initialState(_repository));

  final MockGroupRepository _repository;
  static const _distance = Distance();
  final _random = Random();
  int _joinSimulationGeneration = 0;

  static ActiveGroupState _initialState(MockGroupRepository repository) {
    repository.loadDemoPreviewGroup();
    return _fromRepository(
      repository,
      sessionActive: true,
      inviteCode: 'EXPO-7K2M',
      customGroupName: 'مجموعة إكسبو دبي',
      showRoutes: false,
      reunionConfirmed: false,
      showCelebration: false,
      alternateIndex: 0,
    );
  }

  static ActiveGroupState _fromRepository(
    MockGroupRepository repository, {
    required bool sessionActive,
    required String inviteCode,
    String? customGroupName,
    required bool showRoutes,
    required bool reunionConfirmed,
    required bool showCelebration,
    required int alternateIndex,
    LatLng? meetPoint,
    String meetPointLabelKey = 'meet_point_primary',
  }) {
    final group = repository.activeGroup;
    final currentUserId = repository.currentUser.id;
    final members = _mapMembers(group, currentUserId);

    final point = meetPoint ??
        _latLngFromReunification(repository.selectedReunificationPoint) ??
        _latLngFromReunification(
          repository.activeMeeting?.reunificationPoint,
        );

    return ActiveGroupState(
      groupNameKey: 'create_group_modal_title',
      inviteCode: inviteCode,
      sessionActive: sessionActive,
      customGroupName: customGroupName ?? group?.name,
      members: members,
      meetPoint: point,
      meetPointLabelKey: meetPointLabelKey,
      showRoutes: showRoutes,
      reunionConfirmed: reunionConfirmed,
      showCelebration: showCelebration,
      alternateIndex: alternateIndex,
      backendGroupId: group?.id,
    );
  }

  static List<GroupMember> _mapMembers(GroupModel? group, int currentUserId) {
    if (group == null || group.members.isEmpty) {
      final solo = MockExpoData.member(
        id: 1,
        groupId: 0,
        userId: currentUserId,
        lat: 24.957803,
        lng: 55.1562148,
      );
      return [
        GroupMemberUiMapper.toPresentation(
          member: solo,
          user: MockExpoData.userById(currentUserId),
          currentUserId: currentUserId,
        ),
      ];
    }

    return group.members
        .map(
          (m) => GroupMemberUiMapper.toPresentation(
            member: m,
            user: m.user ?? MockExpoData.userById(m.userId),
            currentUserId: currentUserId,
          ),
        )
        .toList();
  }

  static LatLng? _latLngFromReunification(ReunificationPointModel? point) {
    if (point == null) return null;
    return LatLng(point.latitude, point.longitude);
  }

  String _generateInviteCode() {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final suffix = List.generate(
      4,
      (_) => chars[_random.nextInt(chars.length)],
    ).join();
    return 'EXPO-$suffix';
  }

  void _publish({
    required bool sessionActive,
    required String inviteCode,
    String? customGroupName,
    bool showRoutes = false,
    bool reunionConfirmed = false,
    bool showCelebration = false,
    int alternateIndex = 0,
    LatLng? meetPoint,
    String meetPointLabelKey = 'meet_point_primary',
  }) {
    state = _fromRepository(
      _repository,
      sessionActive: sessionActive,
      inviteCode: inviteCode,
      customGroupName: customGroupName,
      showRoutes: showRoutes,
      reunionConfirmed: reunionConfirmed,
      showCelebration: showCelebration,
      alternateIndex: alternateIndex,
      meetPoint: meetPoint,
      meetPointLabelKey: meetPointLabelKey,
    );
  }

  void createNewGroup({String? displayName}) {
    _joinSimulationGeneration++;
    final generation = _joinSimulationGeneration;
    final inviteCode = _generateInviteCode();
    final name = displayName?.trim() ?? '';

    _repository.createGroup(name: name, inviteCode: inviteCode);

    _publish(
      sessionActive: true,
      inviteCode: inviteCode,
      customGroupName: name.isEmpty ? null : name,
    );

    _simulateIncomingJoins(generation);
  }

  void _simulateIncomingJoins(int generation) {
    const joinCount = 4;
    for (var i = 0; i < joinCount; i++) {
      Future<void>.delayed(Duration(seconds: 2 + i * 2), () {
        if (generation != _joinSimulationGeneration) return;
        if (!state.sessionActive) return;

        _repository.addMemberFromMock(i);
        _publish(
          sessionActive: true,
          inviteCode: state.inviteCode,
          customGroupName: state.customGroupName,
          showRoutes: state.showRoutes,
          reunionConfirmed: state.reunionConfirmed,
          showCelebration: state.showCelebration,
          alternateIndex: state.alternateIndex,
          meetPoint: state.meetPoint,
          meetPointLabelKey: state.meetPointLabelKey,
        );
      });
    }
  }

  List<GroupMember> _withEtas(LatLng destination) {
    return state.members.map((member) {
      if (member.connection == MemberConnection.offline) {
        return member.copyWith(clearEta: true);
      }
      final meters = _distance(member.position, destination);
      final minutes = (meters / 75).ceil().clamp(1, 15);
      return member.copyWith(etaMinutes: minutes);
    }).toList();
  }

  /// Min-max walking distance: pick venue point that minimizes the longest leg.
  ReunificationPointModel _fairMeetPoint(List<GroupMember> members) {
    final points = _repository.venuePoints;
    if (points.isEmpty) return MockExpoData.reunificationPoints.first;

    final participants = members
        .where((m) => m.connection != MemberConnection.offline)
        .toList();
    if (participants.isEmpty) return points.first;

    ReunificationPointModel best = points.first;
    var bestWorstLeg = double.infinity;

    for (final candidate in points) {
      final dest = LatLng(candidate.latitude, candidate.longitude);
      var worstLeg = 0.0;
      for (final member in participants) {
        final leg = _distance(member.position, dest);
        if (leg > worstLeg) worstLeg = leg;
      }
      if (worstLeg < bestWorstLeg) {
        bestWorstLeg = worstLeg;
        best = candidate;
      }
    }
    return best;
  }

  static String _labelKeyForPoint(ReunificationPointModel point) {
    return switch (point.name) {
      'Earth Plaza' => 'meet_point_primary',
      'Sea Plaza' => 'meet_point_alt_east',
      'Sun Plaza' => 'meet_point_alt_west',
      _ => 'meet_point_primary',
    };
  }

  /// Sync map sheet / meet pin after backend demo optimization.
  void applyBackendRoutingPreview({
    required double latitude,
    required double longitude,
    required String meetingPointName,
    String? meetingPointId,
  }) {
    final points = _repository.venuePoints;
    ReunificationPointModel? resolved;
    if (meetingPointId != null) {
      for (final p in points) {
        if (p.id == meetingPointId) {
          resolved = p;
          break;
        }
      }
    }
    for (final p in points) {
      if (p.name == meetingPointName) {
        resolved ??= p;
        break;
      }
    }
    final point = resolved ??
        ReunificationPointModel(
          id: meetingPointId ?? 'demo-mp',
          name: meetingPointName,
          nodeId: 0,
          latitude: latitude,
          longitude: longitude,
        );

    _repository.applyReunificationPoint(point);
    final latLng = LatLng(latitude, longitude);
    final index = points.indexWhere((p) => p.id == point.id);

    _publish(
      sessionActive: state.sessionActive,
      inviteCode: state.inviteCode,
      customGroupName: state.customGroupName,
      showRoutes: true,
      alternateIndex: index >= 0 ? index : 0,
      meetPoint: latLng,
      meetPointLabelKey: _labelKeyForPoint(point),
    );
    state = state.copyWith(members: _withEtas(latLng));
  }

  void beginSmartReunionPlan() {
    final points = _repository.venuePoints;
    final point = _fairMeetPoint(state.members);
    _repository.applyReunificationPoint(point);

    final latLng = LatLng(point.latitude, point.longitude);
    final index = points.indexWhere((p) => p.id == point.id);
    _publish(
      sessionActive: state.sessionActive,
      inviteCode: state.inviteCode,
      customGroupName: state.customGroupName,
      showRoutes: true,
      alternateIndex: index >= 0 ? index : 0,
      meetPoint: latLng,
      meetPointLabelKey: _labelKeyForPoint(point),
    );
    state = state.copyWith(members: _withEtas(latLng));
  }

  void confirmReunionPoint() {
    state = state.copyWith(reunionConfirmed: true);
  }

  void cycleAlternateMeetPoint() {
    final points = _repository.venuePoints;
    if (points.isEmpty) return;

    final next = (state.alternateIndex + 1) % points.length;
    final point = points[next];
    _repository.applyReunificationPoint(point);

    final latLng = LatLng(point.latitude, point.longitude);
    _publish(
      sessionActive: state.sessionActive,
      inviteCode: state.inviteCode,
      customGroupName: state.customGroupName,
      showRoutes: true,
      reunionConfirmed: state.reunionConfirmed,
      showCelebration: state.showCelebration,
      alternateIndex: next,
      meetPoint: latLng,
      meetPointLabelKey: _labelKeyForPoint(point),
    );
    state = state.copyWith(members: _withEtas(latLng));
  }

  void toggleCurrentUserTravelStatus() {
    final members = [...state.members];
    final index = members.indexWhere((m) => m.isCurrentUser);
    if (index < 0) return;

    final current = members[index];
    final nextStatus = current.travelStatus == MemberTravelStatus.enRoute
        ? MemberTravelStatus.arrived
        : MemberTravelStatus.enRoute;

    members[index] = current.copyWith(
      travelStatus: nextStatus,
      lastUpdateMinutes: 0,
    );

    var showCelebration = state.showCelebration;
    final active = members.where((m) => m.connection != MemberConnection.offline);
    final allActiveArrived = active.isNotEmpty &&
        active.every((m) => m.travelStatus == MemberTravelStatus.arrived);
    if (allActiveArrived) {
      showCelebration = true;
    }

    state = state.copyWith(
      members: members,
      showCelebration: showCelebration,
    );
  }

  void dismissCelebration() {
    state = state.copyWith(showCelebration: false);
  }
}

final activeGroupProvider =
    StateNotifierProvider<ActiveGroupController, ActiveGroupState>((ref) {
  final repository = ref.watch(mockGroupRepositoryProvider);
  return ActiveGroupController(repository);
});

final mainShellIndexProvider = StateProvider<int>((ref) => 0);
