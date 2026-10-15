package com.nawaf.meetingpoint.DTO.Navigation;

public record ParticipantRouteResponse(Integer userId, Double distanceMeters, Double etaSeconds, java.util.List<RoutePointResponse> path) {}
