import 'dart:io';

abstract final class ApiConstants {
  /// UI-only preview: no HTTP calls. Set to `false` when connecting Spring Boot.
  static const bool useMockBackend = true;

  static const String userPath = '/api/v1/user';

  static String get baseUrl {
    if (Platform.isAndroid) {
      return 'http://10.0.2.2:8080';
    }
    return 'http://127.0.0.1:8080';
  }
}
