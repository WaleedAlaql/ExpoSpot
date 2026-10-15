
package com.nawaf.meetingpoint.DTO.Navigation;

import jakarta.validation.constraints.NotNull;

public record RouteRequest(
        @NotNull Long fromNodeId,
        @NotNull Long toNodeId
) {}
