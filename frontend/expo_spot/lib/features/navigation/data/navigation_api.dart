import 'package:expo_spot/features/navigation/data/navigation_http.dart';
import 'package:expo_spot/features/navigation/domain/navigation_models.dart';

class NavigationApi {
  NavigationApi({NavigationHttp? http}) : _http = http ?? NavigationHttp();

  final NavigationHttp _http;

  Future<GraphResponseModel> fetchGraph() async {
    final json = await _http.getJson('/api/v1/navigation/graph');
    return GraphResponseModel.fromJson(json);
  }

  Future<List<MeetingPointModel>> fetchMeetingPoints() async {
    final body = await _http.getBody('/api/v1/navigation/meeting-points');
    if (body is! List) return const [];
    return body
        .whereType<Map>()
        .map((e) => MeetingPointModel.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  Future<RouteResponseModel> routeNodes({
    required int fromNodeId,
    required int toNodeId,
  }) async {
    final json = await _http.postJson(
      '/api/v1/navigation/route',
      body: {'fromNodeId': fromNodeId, 'toNodeId': toNodeId},
    );
    return RouteResponseModel.fromJson(json);
  }

  Future<MeetingOptimizationResponseModel> optimizePreview({
    int? groupId,
    required List<Map<String, dynamic>> participants,
  }) async {
    final body = <String, dynamic>{'participants': participants};
    if (groupId != null) body['groupId'] = groupId;
    final json = await _http.postJson('/api/v1/navigation/optimize', body: body);
    return MeetingOptimizationResponseModel.fromJson(json);
  }

  Future<MeetingOptimizationResponseModel> recommendForGroup({
    required int groupId,
    required List<int> participantUserIds,
  }) async {
    final json = await _http.postJson(
      '/api/v1/navigation/groups/$groupId/recommendation',
      body: {
        'groupId': groupId,
        'participants': [
          for (final id in participantUserIds) {'userId': id},
        ],
      },
    );
    return MeetingOptimizationResponseModel.fromJson(json);
  }

  Future<GpsRouteResponseModel> recalculateGroupRoute({
    required int groupId,
    required int userId,
    required double startLat,
    required double startLng,
    required double destLat,
    required double destLng,
  }) async {
    final json = await _http.postJson(
      '/api/v1/navigation/groups/$groupId/routes',
      body: {
        'userId': userId,
        'route': {
          'start': {'latitude': startLat, 'longitude': startLng},
          'destination': {'latitude': destLat, 'longitude': destLng},
        },
      },
    );
    return GpsRouteResponseModel.fromJson(json);
  }

  Future<MemberLocationResponseModel> putGroupLocation({
    required int groupId,
    required int userId,
    required double latitude,
    required double longitude,
    double? accuracyMeters,
    DateTime? updatedAt,
  }) async {
    final body = <String, dynamic>{
      'groupId': groupId,
      'userId': userId,
      'latitude': latitude,
      'longitude': longitude,
    };
    if (accuracyMeters != null) body['accuracyMeters'] = accuracyMeters;
    if (updatedAt != null) body['updatedAt'] = updatedAt.toUtc().toIso8601String();

    final json = await _http.putJson('/api/v1/group/$groupId/locations', body: body);
    return MemberLocationResponseModel.fromJson(json);
  }

  Future<List<MemberLocationResponseModel>> fetchGroupLocations(int groupId) async {
    final body = await _http.getBody('/api/v1/group/$groupId/locations');
    if (body is! List) return const [];
    return body
        .whereType<Map>()
        .map((e) => MemberLocationResponseModel.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }
}
