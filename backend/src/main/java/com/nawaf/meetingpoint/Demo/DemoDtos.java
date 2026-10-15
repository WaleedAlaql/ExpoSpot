package com.nawaf.meetingpoint.Demo;

import com.nawaf.meetingpoint.DTO.Meeting.MeetingPointResponse;
import com.nawaf.meetingpoint.DTO.Navigation.RoutePointResponse;
import jakarta.validation.constraints.NotNull;
import java.time.Instant;
import java.util.List;

public final class DemoDtos {
    private DemoDtos() {}
    public enum Action { SPAWN, OPTIMIZE, ROUTES, START, PAUSE, RESET, SPEED }
    public record Command(@NotNull Action action, Integer count, Double speed) {}
    public record Visitor(Integer id, String name, Double latitude, Double longitude,
                          String position, String status, Double distanceMeters,
                          Double remainingMeters, Double etaSeconds, List<RoutePointResponse> path) {}
    public record State(String simulationId, long revision, long routeRevision, String status,
                        double speed, MeetingPointResponse meetingPoint, Double optimizerMaxEtaSeconds,
                        Double optimizerTotalDistanceMeters, List<Visitor> visitors) {}
    public record Event(String event, Instant occurredAt, State data) {}
}
