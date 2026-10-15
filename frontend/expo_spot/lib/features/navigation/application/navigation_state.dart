import 'package:expo_spot/core/constants/navigation_config.dart';
import 'package:expo_spot/features/navigation/domain/navigation_models.dart';

enum NavigationConnectionStatus { disconnected, connecting, connected }

class NavigationState {
  const NavigationState({
    this.mode = NavigationMode.demo,
    this.graphLoading = false,
    this.commandInFlight = false,
    this.errorMessage,
    this.graph,
    this.simulationId,
    this.demoState,
    this.recommendation,
    this.groupLocations = const [],
    this.connectionStatus = NavigationConnectionStatus.disconnected,
    this.showCelebration = false,
    this.lastSocketError,
    this.contextGeneration = 0,
    this.appliedRevision = 0,
    this.appliedRouteRevision = 0,
    this.celebrationShownForRouteRevision = -1,
    this.simulationSpeed = 1.4,
    this.visitorCount = 4,
  });

  final NavigationMode mode;
  final bool graphLoading;
  final bool commandInFlight;
  final String? errorMessage;
  final GraphResponseModel? graph;
  final String? simulationId;
  final DemoStateModel? demoState;
  final MeetingOptimizationResponseModel? recommendation;
  final List<MemberLocationResponseModel> groupLocations;
  final NavigationConnectionStatus connectionStatus;
  final bool showCelebration;
  final String? lastSocketError;
  final int contextGeneration;
  final int appliedRevision;
  final int appliedRouteRevision;
  final int celebrationShownForRouteRevision;
  final double simulationSpeed;
  final int visitorCount;

  bool get hasSession => simulationId != null && demoState != null;

  bool get canStartDemo =>
      demoState != null &&
      demoState!.visitors.any((v) => v.path != null && v.path!.isNotEmpty) &&
      demoState!.status != 'RUNNING' &&
      demoState!.status != 'ARRIVED';

  bool get canPauseDemo => demoState?.status == 'RUNNING';

  NavigationState copyWith({
    NavigationMode? mode,
    bool? graphLoading,
    bool? commandInFlight,
    String? errorMessage,
    bool clearError = false,
    GraphResponseModel? graph,
    String? simulationId,
    DemoStateModel? demoState,
    MeetingOptimizationResponseModel? recommendation,
    List<MemberLocationResponseModel>? groupLocations,
    NavigationConnectionStatus? connectionStatus,
    bool? showCelebration,
    String? lastSocketError,
    int? contextGeneration,
    int? appliedRevision,
    int? appliedRouteRevision,
    int? celebrationShownForRouteRevision,
    double? simulationSpeed,
    int? visitorCount,
    bool clearDemo = false,
    bool clearRecommendation = false,
  }) {
    return NavigationState(
      mode: mode ?? this.mode,
      graphLoading: graphLoading ?? this.graphLoading,
      commandInFlight: commandInFlight ?? this.commandInFlight,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      graph: graph ?? this.graph,
      simulationId: clearDemo ? null : (simulationId ?? this.simulationId),
      demoState: clearDemo ? null : (demoState ?? this.demoState),
      recommendation:
          clearRecommendation ? null : (recommendation ?? this.recommendation),
      groupLocations: groupLocations ?? this.groupLocations,
      connectionStatus: connectionStatus ?? this.connectionStatus,
      showCelebration: showCelebration ?? this.showCelebration,
      lastSocketError: lastSocketError ?? this.lastSocketError,
      contextGeneration: contextGeneration ?? this.contextGeneration,
      appliedRevision: appliedRevision ?? this.appliedRevision,
      appliedRouteRevision: appliedRouteRevision ?? this.appliedRouteRevision,
      celebrationShownForRouteRevision: celebrationShownForRouteRevision ??
          this.celebrationShownForRouteRevision,
      simulationSpeed: simulationSpeed ?? this.simulationSpeed,
      visitorCount: visitorCount ?? this.visitorCount,
    );
  }
}
