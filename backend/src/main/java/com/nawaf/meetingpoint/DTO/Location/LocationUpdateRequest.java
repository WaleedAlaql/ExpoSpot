package com.nawaf.meetingpoint.DTO.Location;
import jakarta.validation.constraints.*;
import java.time.Instant;
public record LocationUpdateRequest(
    @NotNull @Positive Integer groupId, @NotNull @Positive Integer userId,
    @NotNull @DecimalMin("-90.0") @DecimalMax("90.0") Double latitude,
    @NotNull @DecimalMin("-180.0") @DecimalMax("180.0") Double longitude,
    @PositiveOrZero Double accuracyMeters, Instant updatedAt
) {}
