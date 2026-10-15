
package com.nawaf.meetingpoint.DTO.Location;

import java.time.LocalDateTime;

public record MemberLocationResponse(
        Long groupId,
        Long userId,
        Double latitude,
        Double longitude,
        Double accuracyMeters,
        String status,
        LocalDateTime updatedAt
) {}
