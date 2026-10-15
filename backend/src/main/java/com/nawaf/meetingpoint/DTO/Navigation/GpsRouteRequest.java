package com.nawaf.meetingpoint.DTO.Navigation;

public record GpsRouteRequest(@jakarta.validation.Valid @jakarta.validation.constraints.NotNull GpsPosition start, @jakarta.validation.Valid @jakarta.validation.constraints.NotNull GpsPosition destination) {}
