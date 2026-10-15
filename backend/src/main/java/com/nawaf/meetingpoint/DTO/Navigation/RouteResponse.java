
package com.nawaf.meetingpoint.DTO.Navigation;

import java.util.List;

public record RouteResponse(
        Long fromNodeId,
        Long toNodeId,
        Double distanceMeters,
        Long estimatedDurationSeconds,
        List<RoutePointResponse> path
) {}
