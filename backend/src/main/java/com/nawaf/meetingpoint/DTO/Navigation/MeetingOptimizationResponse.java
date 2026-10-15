package com.nawaf.meetingpoint.DTO.Navigation;

public record MeetingOptimizationResponse(com.nawaf.meetingpoint.DTO.Meeting.MeetingPointResponse meetingPoint, Double maxEtaSeconds, Double totalEtaSeconds, Double totalDistanceMeters, java.util.List<ParticipantRouteResponse> participants) {}
