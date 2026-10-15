import 'dart:convert';

import 'package:expo_spot/core/constants/api_constants.dart';
import 'package:expo_spot/features/navigation/domain/navigation_models.dart';
import 'package:stomp_dart_client/stomp_dart_client.dart';

typedef DemoEventHandler = void Function(DemoEventEnvelope envelope);
typedef DemoErrorHandler = void Function(String message);
typedef ProductionEventHandler = void Function(ProductionEventEnvelope envelope);

class NavigationRealtime {
  StompClient? _client;
  final List<StompUnsubscribe> _unsubs = [];
  bool get isConnected => _client?.connected ?? false;

  void connectDemo({
    required String simulationId,
    required DemoEventHandler onDemoEvent,
    required DemoErrorHandler onError,
  }) {
    _connect(
      onConnect: () {
        _subscribe('/topic/demo/$simulationId/locations', (body) {
          _dispatchDemo(body, onDemoEvent);
        });
        _subscribe('/topic/demo/$simulationId/navigation', (body) {
          _dispatchDemo(body, onDemoEvent);
        });
        _subscribe('/topic/demo/$simulationId/updates', (body) {
          _dispatchDemo(body, onDemoEvent);
        });
        _subscribe('/user/topic/demo/errors', (body) {
          onError(_readErrorMessage(body));
        });
      },
    );
  }

  void connectProduction({
    required int groupId,
    required ProductionEventHandler onEvent,
    required DemoErrorHandler onError,
  }) {
    _connect(
      onConnect: () {
        _subscribe('/topic/groups/$groupId/locations', (body) {
          _dispatchProduction(body, groupId, onEvent);
        });
        _subscribe('/topic/groups/$groupId/navigation', (body) {
          _dispatchProduction(body, groupId, onEvent);
        });
        _subscribe('/user/topic/errors', (body) {
          onError(_readErrorMessage(body));
        });
      },
    );
  }

  void _connect({required void Function() onConnect}) {
    deactivate();
    _client = StompClient(
      config: StompConfig(
        url: ApiConstants.webSocketUrl,
        onConnect: (frame) => onConnect(),
        onWebSocketError: (error) {},
        onDisconnect: (frame) {},
        onStompError: (frame) {},
        reconnectDelay: const Duration(seconds: 3),
      ),
    );
    _client!.activate();
  }

  void _subscribe(String destination, void Function(String body) handler) {
    final client = _client;
    if (client == null) return;
    final unsub = client.subscribe(
      destination: destination,
      callback: (frame) {
        final body = frame.body;
        if (body == null || body.isEmpty) return;
        handler(body);
      },
    );
    _unsubs.add(unsub);
  }

  void _dispatchDemo(String body, DemoEventHandler handler) {
    try {
      final json = jsonDecode(body);
      if (json is! Map) return;
      handler(DemoEventEnvelope.fromJson(Map<String, dynamic>.from(json)));
    } catch (_) {}
  }

  void _dispatchProduction(
    String body,
    int groupId,
    ProductionEventHandler handler,
  ) {
    try {
      final json = jsonDecode(body);
      if (json is! Map) return;
      handler(ProductionEventEnvelope.fromJson(Map<String, dynamic>.from(json)));
    } catch (_) {}
  }

  String _readErrorMessage(String body) {
    try {
      final json = jsonDecode(body);
      if (json is Map && json['message'] != null) {
        return json['message'].toString();
      }
    } catch (_) {}
    return body;
  }

  void deactivate() {
    for (final u in _unsubs) {
      u();
    }
    _unsubs.clear();
    _client?.deactivate();
    _client = null;
  }
}
