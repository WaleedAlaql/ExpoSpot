import 'dart:async';
import 'dart:convert';
import 'package:expo_spot/core/constants/api_constants.dart';
import 'package:expo_spot/core/models/api_response_model.dart';
import 'package:expo_spot/features/navigation/data/navigation_api_exception.dart';
import 'package:http/http.dart' as http;

class NavigationHttp {
  NavigationHttp({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;
  static const _timeout = Duration(seconds: 12);

  Uri uri(String path) => Uri.parse('${ApiConstants.baseUrl}$path');

  Future<T> _guard<T>(Future<T> Function() run) async {
    try {
      return await run();
    } on NavigationApiException {
      rethrow;
    } on TimeoutException {
      throw NavigationApiException(_reachabilityHint('Request timed out'));
    } catch (e) {
      throw NavigationApiException(_reachabilityHint('$e'));
    }
  }

  String _reachabilityHint(String detail) {
    return 'Cannot reach backend at ${ApiConstants.baseUrl}. '
        '$detail — use the same Wi‑Fi as your Mac (not cellular only). '
        'If the Mac uses iPhone Personal Hotspot, the phone often cannot reach the Mac; '
        'join a shared Wi‑Fi instead. '
        'flutter run --dart-define=API_BASE_URL=http://MAC_LAN_IP:8081';
  }

  Future<dynamic> getBody(String path) async {
    return _guard(() async {
      final response = await _client.get(uri(path)).timeout(_timeout);
      return _decodeBody(response);
    });
  }

  Future<Map<String, dynamic>> getJson(String path) async {
    final body = await getBody(path);
    if (body is Map<String, dynamic>) return body;
    if (body is Map) return Map<String, dynamic>.from(body);
    throw NavigationApiException('Expected JSON object', statusCode: 200);
  }

  Future<Map<String, dynamic>> postJson(
    String path, {
    Map<String, dynamic>? body,
  }) async {
    return _guard(() async {
      final response = await _client
          .post(
            uri(path),
            headers: const {'Content-Type': 'application/json'},
            body: body == null ? '{}' : jsonEncode(body),
          )
          .timeout(_timeout);
      return _decodeObject(response);
    });
  }

  dynamic _decodeBody(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return jsonDecode(response.body);
    }

    var message = 'HTTP ${response.statusCode}';
    try {
      final json = jsonDecode(response.body);
      if (json is Map<String, dynamic>) {
        message = ApiResponseModel.fromJson(json).message;
      }
    } catch (_) {}

    throw NavigationApiException(message, statusCode: response.statusCode);
  }

  Future<Map<String, dynamic>> putJson(
    String path, {
    required Map<String, dynamic> body,
  }) async {
    return _guard(() async {
      final response = await _client
          .put(
            uri(path),
            headers: const {'Content-Type': 'application/json'},
            body: jsonEncode(body),
          )
          .timeout(_timeout);
      return _decodeObject(response);
    });
  }

  Map<String, dynamic> _decodeObject(http.Response response) {
    final decoded = _decodeBody(response);
    if (decoded is Map<String, dynamic>) return decoded;
    if (decoded is Map) return Map<String, dynamic>.from(decoded);
    throw NavigationApiException('Unexpected response shape', statusCode: response.statusCode);
  }
}
