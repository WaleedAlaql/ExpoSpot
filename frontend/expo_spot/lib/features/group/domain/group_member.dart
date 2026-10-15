import 'package:latlong2/latlong.dart';

enum MemberConnection { online, lowSignal, offline }

enum MemberTravelStatus { enRoute, arrived }

class GroupMember {
  const GroupMember({
    required this.id,
    required this.nameKey,
    required this.position,
    required this.connection,
    required this.travelStatus,
    required this.lastUpdateMinutes,
    this.displayName,
    this.etaMinutes,
    this.isCurrentUser = false,
    this.backendUserId,
    this.backendMemberId,
    this.statusLabelKey,
  });

  final String id;
  final String nameKey;
  final String? displayName;
  final String? statusLabelKey;
  final LatLng position;
  final MemberConnection connection;
  final MemberTravelStatus travelStatus;
  final int lastUpdateMinutes;
  final int? etaMinutes;
  final bool isCurrentUser;
  final int? backendUserId;
  final int? backendMemberId;

  String label(String Function(String key) translate) =>
      displayName ?? translate(nameKey);

  GroupMember copyWith({
    LatLng? position,
    MemberConnection? connection,
    MemberTravelStatus? travelStatus,
    int? lastUpdateMinutes,
    int? etaMinutes,
    bool clearEta = false,
  }) {
    return GroupMember(
      id: id,
      nameKey: nameKey,
      displayName: displayName,
      position: position ?? this.position,
      connection: connection ?? this.connection,
      travelStatus: travelStatus ?? this.travelStatus,
      lastUpdateMinutes: lastUpdateMinutes ?? this.lastUpdateMinutes,
      etaMinutes: clearEta ? null : (etaMinutes ?? this.etaMinutes),
      isCurrentUser: isCurrentUser,
      backendUserId: backendUserId,
      backendMemberId: backendMemberId,
      statusLabelKey: statusLabelKey,
    );
  }
}

/// Legacy alias — Expo Dubai reference venue (Earth Plaza).
abstract final class ExpoVenue {
  static const center = LatLng(24.957803, 55.1562148);
  static const zoom = 16.2;

  static const meetPrimary = LatLng(24.957803, 55.1562148);
  static const meetAltEast = LatLng(24.9566629, 55.1462239);
  static const meetAltWest = LatLng(24.9670353, 55.1530789);
}
