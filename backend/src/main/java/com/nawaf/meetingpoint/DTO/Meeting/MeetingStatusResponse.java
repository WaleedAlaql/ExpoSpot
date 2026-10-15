
package com.nawaf.meetingpoint.DTO.Meeting;

public record MeetingStatusResponse(
        Integer meetingId,
        String status,
        MeetingPointResponse meetingPoint,
        Long maxEtaSeconds
) {}
