import 'dart:async';

import 'package:expo_spot/core/constants/api_constants.dart';
import 'package:expo_spot/features/navigation/application/navigation_state.dart';
import 'package:expo_spot/features/navigation/data/demo_simulation_api.dart';
import 'package:expo_spot/features/navigation/data/navigation_api.dart';
import 'package:expo_spot/features/navigation/data/navigation_api_exception.dart';
import 'package:expo_spot/features/navigation/data/navigation_realtime.dart';
import 'package:expo_spot/features/navigation/domain/navigation_models.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class NavigationController extends StateNotifier<NavigationState> {
  NavigationController({
    required NavigationApi navigationApi,
    required DemoSimulationApi demoApi,
    required NavigationRealtime realtime,
  })  : _navigationApi = navigationApi,
        _demoApi = demoApi,
        _realtime = realtime,
        super(
          NavigationState(mode: ApiConstants.navigationMode),
        );

  final NavigationApi _navigationApi;
  final DemoSimulationApi _demoApi;
  final NavigationRealtime _realtime;

  Timer? _snapshotTimer;
  int _commandToken = 0;

  Future<void> bootstrapDemo() async {
    if (!state.mode.isDemo) return;
    state = state.copyWith(graphLoading: true, clearError: true);
    try {
      final graph = await _navigationApi.fetchGraph();
      state = state.copyWith(graphLoading: false, graph: graph);
    } on NavigationApiException catch (e) {
      state = state.copyWith(graphLoading: false, errorMessage: e.message);
    } catch (e) {
      state = state.copyWith(
        graphLoading: false,
        errorMessage: 'Cannot load graph: $e',
      );
    }
  }

  /// Home / map one-tap: session → spawn 4 → optimize (backend paths).
  Future<void> runQuickRoutingTest() async {
    await _runCommand(() async {
      var id = state.simulationId;
      if (id == null) {
        final created = await _demoApi.createSession();
        _attachSession(created);
        id = created.simulationId;
      }

      id = state.simulationId ?? id;
      var snapshot = state.demoState ?? await _demoApi.fetchSession(id);

      if (snapshot.visitors.isEmpty) {
        snapshot = await _demoApi.sendCommand(
          simulationId: id,
          action: DemoCommandAction.spawn,
          count: state.visitorCount.clamp(3, 4),
        );
        _applyDemoState(snapshot, eventName: 'SPAWN');
      }

      snapshot = await _demoApi.sendCommand(
        simulationId: id,
        action: DemoCommandAction.optimize,
      );
      _applyDemoState(snapshot, eventName: 'OPTIMIZE');
    });
  }

  Future<void> createDemoSession() async {
    await _runCommand(() async {
      final created = await _demoApi.createSession();
      _attachSession(created);
    });
  }

  Future<void> joinDemoSession(String simulationId) async {
    final trimmed = simulationId.trim();
    if (trimmed.isEmpty) return;
    await _runCommand(() async {
      final snapshot = await _demoApi.fetchSession(trimmed);
      _attachSession(snapshot);
    });
  }

  void _attachSession(DemoStateModel snapshot) {
    _stopSnapshotTimer();
    final generation = state.contextGeneration + 1;
    state = state.copyWith(
      simulationId: snapshot.simulationId,
      demoState: snapshot,
      contextGeneration: generation,
      appliedRevision: snapshot.revision,
      appliedRouteRevision: snapshot.routeRevision,
      connectionStatus: NavigationConnectionStatus.connecting,
      clearError: true,
    );
    _realtime.connectDemo(
      simulationId: snapshot.simulationId,
      onDemoEvent: _onDemoEvent,
      onError: (message) {
        state = state.copyWith(lastSocketError: message);
      },
    );
    state = state.copyWith(connectionStatus: NavigationConnectionStatus.connected);
    _startSnapshotTimer(snapshot.simulationId, generation);
  }

  Future<void> refreshSnapshot() async {
    final id = state.simulationId;
    if (id == null) return;
    final generation = state.contextGeneration;
    try {
      final snapshot = await _demoApi.fetchSession(id);
      if (generation != state.contextGeneration) return;
      _applyDemoState(snapshot, eventName: null);
    } on NavigationApiException catch (e) {
      if (e.statusCode == 404) {
        state = state.copyWith(
          errorMessage: e.message,
          clearDemo: true,
          connectionStatus: NavigationConnectionStatus.disconnected,
        );
        _realtime.deactivate();
        _stopSnapshotTimer();
      }
    }
  }

  Future<void> spawnVisitors() async {
    final id = state.simulationId;
    if (id == null) return;
    await _sendDemoCommand(
      DemoCommandAction.spawn,
      extra: {'count': state.visitorCount.clamp(3, 4)},
    );
  }

  Future<void> optimize() => _sendDemoCommand(DemoCommandAction.optimize);

  /// New random visitor positions on the graph, then minimax meet point + routes.
  Future<void> relocateVisitorsAndRecalculate() async {
    final id = state.simulationId;
    if (id == null) return;
    final count = (state.demoState?.visitors.length ?? state.visitorCount)
        .clamp(3, 4);
    await _runCommand(() async {
      if (state.demoState?.status == 'RUNNING') {
        final paused = await _demoApi.sendCommand(
          simulationId: id,
          action: DemoCommandAction.pause,
        );
        _applyDemoState(paused, eventName: 'PAUSE');
      }
      var snapshot = await _demoApi.sendCommand(
        simulationId: id,
        action: DemoCommandAction.spawn,
        count: count,
      );
      _applyDemoState(snapshot, eventName: 'SPAWN');
      snapshot = await _demoApi.sendCommand(
        simulationId: id,
        action: DemoCommandAction.optimize,
      );
      _applyDemoState(snapshot, eventName: 'OPTIMIZE');
    });
  }

  Future<void> recalculateRoutes() => _sendDemoCommand(DemoCommandAction.routes);
  Future<void> startSimulation() => _sendDemoCommand(DemoCommandAction.start);
  Future<void> pauseSimulation() => _sendDemoCommand(DemoCommandAction.pause);
  Future<void> resetSimulation() => _sendDemoCommand(DemoCommandAction.reset);

  Future<void> setSimulationSpeed(double speed) async {
    state = state.copyWith(simulationSpeed: speed);
    await _sendDemoCommand(
      DemoCommandAction.speed,
      extra: {'speed': speed.clamp(0.2, 100)},
    );
  }

  void setVisitorCount(int count) {
    state = state.copyWith(visitorCount: count.clamp(3, 4));
  }

  void dismissCelebration() {
    state = state.copyWith(showCelebration: false);
  }

  Future<void> requestProductionRecommendation({
    required int groupId,
    required List<int> participantUserIds,
  }) async {
    if (state.mode.isDemo) {
      state = state.copyWith(
        errorMessage: 'Production recommendation is unavailable in demo mode.',
      );
      return;
    }
    state = state.copyWith(commandInFlight: true, clearError: true);
    try {
      final recommendation = await _navigationApi.recommendForGroup(
        groupId: groupId,
        participantUserIds: participantUserIds,
      );
      state = state.copyWith(
        commandInFlight: false,
        recommendation: recommendation,
      );
    } on NavigationApiException catch (e) {
      state = state.copyWith(commandInFlight: false, errorMessage: e.message);
    }
  }

  void connectProductionGroup(int groupId) {
    if (state.mode.isDemo) return;
    _realtime.connectProduction(
      groupId: groupId,
      onEvent: _onProductionEvent,
      onError: (message) => state = state.copyWith(lastSocketError: message),
    );
    state = state.copyWith(connectionStatus: NavigationConnectionStatus.connected);
  }

  Future<void> _sendDemoCommand(
    DemoCommandAction action, {
    Map<String, dynamic>? extra,
  }) async {
    final id = state.simulationId;
    if (id == null) return;
    await _runCommand(() async {
      final snapshot = await _demoApi.sendCommand(
        simulationId: id,
        action: action,
        count: extra?['count'] as int?,
        speed: (extra?['speed'] as num?)?.toDouble(),
      );
      _applyDemoState(snapshot, eventName: action.wireName);
    });
  }

  Future<void> _runCommand(Future<void> Function() action) async {
    if (state.commandInFlight) return;
    final token = ++_commandToken;
    state = state.copyWith(commandInFlight: true, clearError: true);
    try {
      await action();
    } on NavigationApiException catch (e) {
      if (token == _commandToken) {
        state = state.copyWith(errorMessage: e.message);
      }
    } finally {
      if (token == _commandToken) {
        state = state.copyWith(commandInFlight: false);
      }
    }
  }

  void _onDemoEvent(DemoEventEnvelope envelope) {
    final incoming = envelope.data;
    if (state.simulationId != null &&
        incoming.simulationId != state.simulationId) {
      return;
    }

    if (envelope.event == 'MEETING_ARRIVED') {
      _applyDemoState(incoming, eventName: envelope.event);
      _maybeCelebrate(incoming);
      return;
    }

    if (incoming.revision < state.appliedRevision &&
        envelope.event != 'MEETING_ARRIVED') {
      return;
    }

    if (envelope.event == 'LOCATIONS_UPDATED') {
      _applyCompactLocations(incoming);
      return;
    }

    _applyDemoState(incoming, eventName: envelope.event);
    if (incoming.status == 'ARRIVED') {
      _maybeCelebrate(incoming);
    }
  }

  void _applyCompactLocations(DemoStateModel incoming) {
    final current = state.demoState;
    if (current == null) {
      _applyDemoState(incoming, eventName: 'LOCATIONS_UPDATED');
      return;
    }

    if (incoming.routeRevision != current.routeRevision) {
      refreshSnapshot();
      return;
    }

    final mergedVisitors = <DemoVisitorModel>[];
    for (final existing in current.visitors) {
      DemoVisitorModel? updated;
      for (final v in incoming.visitors) {
        if (v.id == existing.id) {
          updated = v;
          break;
        }
      }
      if (updated == null) {
        mergedVisitors.add(existing);
        continue;
      }
      mergedVisitors.add(
        existing.copyWith(
          latitude: updated.latitude ?? existing.latitude,
          longitude: updated.longitude ?? existing.longitude,
          status: updated.status,
          distanceMeters: updated.distanceMeters ?? existing.distanceMeters,
          remainingMeters: updated.remainingMeters ?? existing.remainingMeters,
          etaSeconds: updated.etaSeconds ?? existing.etaSeconds,
          path: updated.path ?? existing.path,
        ),
      );
    }

    final merged = DemoStateModel(
      simulationId: incoming.simulationId,
      revision: incoming.revision,
      routeRevision: incoming.routeRevision,
      status: incoming.status,
      speed: incoming.speed,
      meetingPoint: incoming.meetingPoint ?? current.meetingPoint,
      optimizerMaxEtaSeconds: incoming.optimizerMaxEtaSeconds ??
          current.optimizerMaxEtaSeconds,
      optimizerTotalDistanceMeters: incoming.optimizerTotalDistanceMeters ??
          current.optimizerTotalDistanceMeters,
      visitors: mergedVisitors,
    );

    _applyDemoState(merged, eventName: 'LOCATIONS_UPDATED');
  }

  void _applyDemoState(DemoStateModel incoming, {String? eventName}) {
    final enrich =
        incoming.revision >= state.appliedRevision || eventName == 'MEETING_ARRIVED';

    if (!enrich && incoming.revision < state.appliedRevision) return;

    final prevStatus = state.demoState?.status;
    final simulationId = state.simulationId;
    final generation = state.contextGeneration;

    state = state.copyWith(
      demoState: incoming,
      appliedRevision: incoming.revision > state.appliedRevision
          ? incoming.revision
          : state.appliedRevision,
      appliedRouteRevision: incoming.routeRevision > state.appliedRouteRevision
          ? incoming.routeRevision
          : state.appliedRouteRevision,
      simulationSpeed: incoming.speed,
    );

    if (simulationId != null &&
        prevStatus != incoming.status &&
        (prevStatus == 'RUNNING' || incoming.status == 'RUNNING')) {
      _startSnapshotTimer(simulationId, generation);
    }
  }

  void _maybeCelebrate(DemoStateModel incoming) {
    if (state.celebrationShownForRouteRevision == incoming.routeRevision) {
      return;
    }
    state = state.copyWith(
      showCelebration: true,
      celebrationShownForRouteRevision: incoming.routeRevision,
    );
  }

  void _onProductionEvent(ProductionEventEnvelope envelope) {
    if (envelope.event == 'MEETING_POINT_RECOMMENDED' &&
        envelope.data is Map) {
      final recommendation = MeetingOptimizationResponseModel.fromJson(
        Map<String, dynamic>.from(envelope.data! as Map),
      );
      state = state.copyWith(recommendation: recommendation);
    }
  }

  void _startSnapshotTimer(String simulationId, int generation) {
    _snapshotTimer?.cancel();
    _scheduleSnapshotPoll(simulationId, generation);
  }

  void _scheduleSnapshotPoll(String simulationId, int generation) {
    final running = state.demoState?.status == 'RUNNING';
    final interval =
        running ? const Duration(milliseconds: 800) : const Duration(seconds: 5);
    _snapshotTimer = Timer.periodic(interval, (_) async {
      if (generation != state.contextGeneration) return;
      if (state.simulationId != simulationId) return;
      await refreshSnapshot();
    });
  }

  void _stopSnapshotTimer() {
    _snapshotTimer?.cancel();
    _snapshotTimer = null;
  }

  @override
  void dispose() {
    _stopSnapshotTimer();
    _realtime.deactivate();
    super.dispose();
  }
}

final navigationApiProvider = Provider<NavigationApi>((ref) => NavigationApi());

final demoSimulationApiProvider =
    Provider<DemoSimulationApi>((ref) => DemoSimulationApi());

final navigationRealtimeProvider =
    Provider<NavigationRealtime>((ref) {
  final service = NavigationRealtime();
  ref.onDispose(service.deactivate);
  return service;
});

final navigationControllerProvider =
    StateNotifierProvider<NavigationController, NavigationState>((ref) {
  return NavigationController(
    navigationApi: ref.watch(navigationApiProvider),
    demoApi: ref.watch(demoSimulationApiProvider),
    realtime: ref.watch(navigationRealtimeProvider),
  );
});
