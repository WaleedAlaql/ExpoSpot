package com.nawaf.meetingpoint.DTO.Navigation;

public record ParticipantLocationDTO(@jakarta.validation.constraints.NotNull @jakarta.validation.constraints.Positive Integer userId, Double latitude, Double longitude, java.time.Instant updatedAt) {}
