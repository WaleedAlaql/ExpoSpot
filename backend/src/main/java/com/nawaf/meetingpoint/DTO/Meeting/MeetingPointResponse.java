
package com.nawaf.meetingpoint.DTO.Meeting;

public record MeetingPointResponse(
        String id,
        String name,
        Long nodeId,
        Double latitude,
        Double longitude
) {}
