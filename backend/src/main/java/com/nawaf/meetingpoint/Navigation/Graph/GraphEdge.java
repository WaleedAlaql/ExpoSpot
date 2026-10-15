
package com.nawaf.meetingpoint.Navigation.Graph;

import jakarta.validation.constraints.*;

public record GraphEdge(

        @NotNull
        Long fromNodeId,

        @NotNull
        Long toNodeId,

        @NotNull
        @Positive
        Double distanceMeters,

        @NotNull
        Boolean bidirectional

) {}
