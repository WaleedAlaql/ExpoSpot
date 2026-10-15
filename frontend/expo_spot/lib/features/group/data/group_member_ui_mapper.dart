import 'package:expo_spot/features/group/domain/group_member.dart';
import 'package:expo_spot/features/group/models/group_member_model.dart';
import 'package:expo_spot/features/group/models/member_status.dart';
import 'package:expo_spot/features/user/models/user_model.dart';
import 'package:latlong2/latlong.dart';

/// Maps backend-shaped members to map/home presentation models.
abstract final class GroupMemberUiMapper {
  static const _nameKeys = <int, String>{
    1: 'member_waleed',
    2: 'member_sultan',
    3: 'member_khaled',
    4: 'member_omar',
    5: 'member_faisal',
  };

  static const _statusLabelKeys = <int, String>{
    2: 'status_en_route_cta',
    3: 'status_at_meet_point',
    4: 'status_low_battery',
    5: 'status_en_route_cta',
  };

  static GroupMember toPresentation({
    required GroupMemberModel member,
    required UserModel user,
    required int currentUserId,
    int? etaMinutes,
  }) {
    final lat = member.latitude ?? 24.957803;
    final lng = member.longitude ?? 55.1562148;

    return GroupMember(
      id: member.id.toString(),
      nameKey: _nameKeys[user.id] ?? 'member_waleed',
      displayName: user.name,
      statusLabelKey: _statusLabelKeys[user.id],
      position: LatLng(lat, lng),
      connection: _connection(member, user.id),
      travelStatus: _travelStatus(member.status),
      lastUpdateMinutes: _lastUpdateMinutes(member.lastLocationAt),
      etaMinutes: etaMinutes,
      isCurrentUser: user.id == currentUserId,
      backendUserId: user.id,
      backendMemberId: member.id,
    );
  }

  static MemberConnection _connection(GroupMemberModel member, int userId) {
    if (!member.locationSharingEnabled) return MemberConnection.offline;
    if (userId == 4 ||
        (member.accuracyMeters != null && member.accuracyMeters! > 35)) {
      return MemberConnection.lowSignal;
    }
    return MemberConnection.online;
  }

  static MemberTravelStatus _travelStatus(MemberStatus status) {
    return switch (status) {
      MemberStatus.arrived => MemberTravelStatus.arrived,
      MemberStatus.navigating => MemberTravelStatus.enRoute,
      MemberStatus.idle => MemberTravelStatus.enRoute,
    };
  }

  static int _lastUpdateMinutes(DateTime? lastLocationAt) {
    if (lastLocationAt == null) return 0;
    return DateTime.now().difference(lastLocationAt).inMinutes.clamp(0, 999);
  }
}
