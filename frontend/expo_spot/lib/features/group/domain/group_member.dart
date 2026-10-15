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
    this.etaMinutes,
    this.isCurrentUser = false,
  });

  final String id;
  final String nameKey;
  final LatLng position;
  final MemberConnection connection;
  final MemberTravelStatus travelStatus;
  final int lastUpdateMinutes;
  final int? etaMinutes;
  final bool isCurrentUser;

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
      position: position ?? this.position,
      connection: connection ?? this.connection,
      travelStatus: travelStatus ?? this.travelStatus,
      lastUpdateMinutes: lastUpdateMinutes ?? this.lastUpdateMinutes,
      etaMinutes: clearEta ? null : (etaMinutes ?? this.etaMinutes),
      isCurrentUser: isCurrentUser,
    );
  }
}

abstract final class ExpoVenue {
  static const center = LatLng(24.7742, 46.6385);
  static const zoom = 16.5;

  static const meetPrimary = LatLng(24.7754, 46.6398);
  static const meetAltEast = LatLng(24.7761, 46.6421);
  static const meetAltWest = LatLng(24.7731, 46.6364);
}
