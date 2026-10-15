package com.nawaf.meetingpoint.DTO.Location;
import java.time.Instant;
public record MemberLocationResponse(Integer groupId, Integer userId, Double latitude,
    Double longitude, Double accuracyMeters, String status, Instant updatedAt) {}
