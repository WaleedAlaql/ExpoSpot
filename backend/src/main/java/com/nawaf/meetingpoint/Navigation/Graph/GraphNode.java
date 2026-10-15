
package com.nawaf.meetingpoint.Navigation.Graph;

import jakarta.validation.constraints.*;

@com.fasterxml.jackson.annotation.JsonIgnoreProperties(ignoreUnknown = true)
public record GraphNode(

        @NotNull
        Long id,

        @NotNull
        @DecimalMin("-90.0")
        @DecimalMax("90.0")
        Double latitude,

        @NotNull
        @DecimalMin("-180.0")
        @DecimalMax("180.0")
        Double longitude

) {}
