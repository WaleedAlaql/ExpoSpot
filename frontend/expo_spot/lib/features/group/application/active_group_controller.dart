import 'package:expo_spot/features/group/domain/group_member.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';

class ActiveGroupState {
  const ActiveGroupState({
    required this.groupNameKey,
    required this.inviteCode,
    required this.members,
    this.meetPoint,
    this.meetPointLabelKey = 'meet_point_primary',
    this.showRoutes = false,
    this.reunionConfirmed = false,
    this.showCelebration = false,
    this.alternateIndex = 0,
  });

  final String groupNameKey;
  final String inviteCode;
  final List<GroupMember> members;
  final LatLng? meetPoint;
  final String meetPointLabelKey;
  final bool showRoutes;
  final bool reunionConfirmed;
  final bool showCelebration;
  final int alternateIndex;

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

  ActiveGroupState copyWith({
    String? groupNameKey,
    String? inviteCode,
    List<GroupMember>? members,
    LatLng? meetPoint,
    String? meetPointLabelKey,
    bool? showRoutes,
    bool? reunionConfirmed,
    bool? showCelebration,
    int? alternateIndex,
    bool clearMeetPoint = false,
  }) {
    return ActiveGroupState(
      groupNameKey: groupNameKey ?? this.groupNameKey,
      inviteCode: inviteCode ?? this.inviteCode,
      members: members ?? this.members,
      meetPoint: clearMeetPoint ? null : (meetPoint ?? this.meetPoint),
      meetPointLabelKey: meetPointLabelKey ?? this.meetPointLabelKey,
      showRoutes: showRoutes ?? this.showRoutes,
      reunionConfirmed: reunionConfirmed ?? this.reunionConfirmed,
      showCelebration: showCelebration ?? this.showCelebration,
      alternateIndex: alternateIndex ?? this.alternateIndex,
    );
  }
}

class ActiveGroupController extends StateNotifier<ActiveGroupState> {
  ActiveGroupController() : super(_initial());

  static const _distance = Distance();

  static ActiveGroupState _initial() {
    return ActiveGroupState(
      groupNameKey: 'group_family_name',
      inviteCode: 'EXPO-7K2M',
      members: [
        const GroupMember(
          id: 'self',
          nameKey: 'member_waleed',
          position: LatLng(24.7734, 46.6372),
          connection: MemberConnection.online,
          travelStatus: MemberTravelStatus.enRoute,
          lastUpdateMinutes: 0,
          isCurrentUser: true,
        ),
        const GroupMember(
          id: 'm2',
          nameKey: 'member_mohammed',
          position: LatLng(24.7759, 46.6405),
          connection: MemberConnection.online,
          travelStatus: MemberTravelStatus.arrived,
          lastUpdateMinutes: 0,
        ),
        const GroupMember(
          id: 'm3',
          nameKey: 'member_sara',
          position: LatLng(24.7721, 46.6418),
          connection: MemberConnection.lowSignal,
          travelStatus: MemberTravelStatus.arrived,
          lastUpdateMinutes: 1,
        ),
        const GroupMember(
          id: 'm4',
          nameKey: 'member_noura',
          position: LatLng(24.7768, 46.6369),
          connection: MemberConnection.online,
          travelStatus: MemberTravelStatus.arrived,
          lastUpdateMinutes: 0,
        ),
        const GroupMember(
          id: 'm5',
          nameKey: 'member_ahmed',
          position: LatLng(24.7716, 46.6355),
          connection: MemberConnection.offline,
          travelStatus: MemberTravelStatus.enRoute,
          lastUpdateMinutes: 8,
        ),
      ],
    );
  }

  List<LatLng> get _alternatePoints => [
        ExpoVenue.meetPrimary,
        ExpoVenue.meetAltEast,
        ExpoVenue.meetAltWest,
      ];

  static const _alternateLabelKeys = [
    'meet_point_primary',
    'meet_point_alt_east',
    'meet_point_alt_west',
  ];

  LatLng _optimalPoint() {
    final active = state.members
        .where((m) => m.connection != MemberConnection.offline)
        .toList();
    if (active.isEmpty) return ExpoVenue.meetPrimary;

    var lat = 0.0;
    var lng = 0.0;
    for (final m in active) {
      lat += m.position.latitude;
      lng += m.position.longitude;
    }
    return LatLng(lat / active.length, lng / active.length);
  }

  List<GroupMember> _withEtas(LatLng destination) {
    return state.members.map((member) {
      final meters = _distance(member.position, destination);
      final minutes = (meters / 75).ceil().clamp(1, 15);
      return member.copyWith(etaMinutes: minutes);
    }).toList();
  }

  void beginSmartReunionPlan() {
    final point = _optimalPoint();
    state = state.copyWith(
      meetPoint: point,
      meetPointLabelKey: 'meet_point_primary',
      showRoutes: true,
      alternateIndex: 0,
      members: _withEtas(point),
    );
  }

  void confirmReunionPoint() {
    state = state.copyWith(reunionConfirmed: true);
  }

  void cycleAlternateMeetPoint() {
    final next = (state.alternateIndex + 1) % _alternatePoints.length;
    final point = _alternatePoints[next];
    state = state.copyWith(
      alternateIndex: next,
      meetPoint: point,
      meetPointLabelKey: _alternateLabelKeys[next],
      showRoutes: true,
      members: _withEtas(point),
    );
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
  return ActiveGroupController();
});

final mainShellIndexProvider = StateProvider<int>((ref) => 0);
