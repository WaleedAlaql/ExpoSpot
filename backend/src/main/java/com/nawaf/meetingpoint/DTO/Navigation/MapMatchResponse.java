package com.nawaf.meetingpoint.DTO.Navigation;

public record MapMatchResponse(Double latitude, Double longitude, Double distanceFromGpsMeters, Long fromNodeId, Long toNodeId, Double fraction, Double edgeDistanceMeters, Boolean bidirectional) {}
