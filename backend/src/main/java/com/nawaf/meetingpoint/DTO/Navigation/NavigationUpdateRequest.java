package com.nawaf.meetingpoint.DTO.Navigation;
import jakarta.validation.Valid;
import jakarta.validation.constraints.*;
public record NavigationUpdateRequest(@NotNull @Positive Integer userId, @NotNull @Valid GpsRouteRequest route) {}
