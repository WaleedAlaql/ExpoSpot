import 'package:expo_spot/core/constants/navigation_config.dart';
import 'package:expo_spot/core/constants/platform_base_url_stub.dart'
    if (dart.library.io) 'package:expo_spot/core/constants/platform_base_url_io.dart';

abstract final class ApiConstants {
  /// UI-only preview for auth/group sheets. Independent of [navigationMode].
  static const bool useMockBackend = true;

  static const String userPath = '/api/v1/user';

  static NavigationMode get navigationMode => NavigationMode.fromEnvironment();

  static const String _apiBaseFromEnv = String.fromEnvironment('API_BASE_URL');

  static String get baseUrl {
    if (_apiBaseFromEnv.isNotEmpty) return _apiBaseFromEnv;
    return platformDefaultBaseUrl();
  }

  /// Native STOMP WebSocket endpoint (not SockJS, not `/app`).
  static String get webSocketUrl {
    final base = Uri.parse(baseUrl);
    final wsScheme = base.scheme == 'https' ? 'wss' : 'ws';
    return base.replace(
      scheme: wsScheme,
      path: '/ws',
      query: '',
      fragment: '',
    ).toString();
  }
}
