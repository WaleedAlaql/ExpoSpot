import 'dart:convert';

import 'package:easy_localization/easy_localization.dart';
import 'package:expo_spot/core/constants/api_constants.dart';
import 'package:expo_spot/features/auth/domain/auth_user.dart';
import 'package:http/http.dart' as http;

class AuthApiException implements Exception {
  AuthApiException(this.message);
  final String message;

  @override
  String toString() => message;
}

class AuthApi {
  AuthApi({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  Uri _uri(String path) => Uri.parse('${ApiConstants.baseUrl}$path');

  Future<AuthUser> saveProfile({
    required String username,
    required String password,
  }) async {
    if (ApiConstants.useMockBackend) {
      await Future<void>.delayed(const Duration(milliseconds: 450));
      return AuthUser(
        id: 1,
        name: username.trim(),
        email: _syntheticEmail(username),
      );
    }

    final response = await _client.post(
      _uri('${ApiConstants.userPath}/add'),
      headers: const {'Content-Type': 'application/json'},
      body: jsonEncode({
        'name': username.trim(),
        'password': password,
        'email': _syntheticEmail(username),
      }),
    );

    if (response.statusCode == 201) {
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      return AuthUser.fromJson(json);
    }

    String message = 'error_save_failed'.tr();
    try {
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      message = (json['message'] as String?) ?? message;
    } catch (_) {}

    throw AuthApiException(message);
  }

  String _syntheticEmail(String username) {
    final normalized = username.trim().toLowerCase().replaceAll(RegExp(r'\s+'), '.');
    return '$normalized@expospot.local';
  }
}
